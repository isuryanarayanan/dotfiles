#!/bin/zsh

# ──────────────────────────────────────────────
# dictate — local voice-to-text for the terminal
#
# Uses whisper.cpp server (via Homebrew) for fast transcription.
# The model loads once into memory and stays hot, giving sub-second
# transcription latency on Apple Silicon.
#
# Modes:
#   --stream   (default) continuous real-time transcription
#   --clip     push-to-talk: record, transcribe, copy to clipboard
#
# A vocabulary prompt biases Whisper toward domain-specific terms.
# Customize via --prompt or ~/.config/dictate/vocab.txt
#
# Dependencies:
#   brew install whisper-cpp       (provides whisper-server)
#   brew install sox               (for microphone recording)
# ──────────────────────────────────────────────

# ── Constants ─────────────────────────────────

MODEL_DIR="$HOME/.local/share/whisper"
CONFIG_DIR="$HOME/.config/dictate"
VOCAB_FILE="$CONFIG_DIR/vocab.txt"
HF_BASE_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main"
DEFAULT_MODEL="small.en"
DEFAULT_LANG="en"
DEFAULT_MODE="stream"
SERVER_PORT=8178
SERVER_URL="http://127.0.0.1:${SERVER_PORT}"
STREAM_CHUNK_SEC=4

# Default vocabulary prompt — used when no vocab file or --prompt is given
DEFAULT_VOCAB="dotfiles, tmux, Neovim, LazyVim, zsh, zinit, Homebrew, Starship, macOS, Linux, GitHub, git, npm, node, Docker, Kubernetes, CLI, API, SSH, YAML, JSON, TypeScript, JavaScript, Python, Rust, Lua, Bash, stdin, stdout, stderr, regex, symlink, config"

# ── Helpers ───────────────────────────────────

info()  { printf "\033[1;34m[info]\033[0m  %s\n" "$1"; }
ok()    { printf "\033[1;32m[ok]\033[0m    %s\n" "$1"; }
warn()  { printf "\033[1;33m[warn]\033[0m  %s\n" "$1"; }
err()   { printf "\033[1;31m[error]\033[0m %s\n" "$1"; exit 1; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

# ── Cleanup ───────────────────────────────────

TEMP_FILES=()
REC_PID=""
SERVER_PID=""

cleanup() {
  # Kill any running recording process
  if [[ -n "$REC_PID" ]] && kill -0 "$REC_PID" 2>/dev/null; then
    kill "$REC_PID" 2>/dev/null
    wait "$REC_PID" 2>/dev/null
  fi
  # Kill the whisper server we started
  if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null
    wait "$SERVER_PID" 2>/dev/null
  fi
  for f in "${TEMP_FILES[@]}"; do
    [[ -f "$f" ]] && rm -f "$f"
  done
  echo ""
  ok "Goodbye!"
  exit 0
}

trap cleanup SIGINT SIGTERM

# ── Usage ─────────────────────────────────────

usage() {
  cat <<EOF
Usage: dictate [OPTIONS]

Local voice-to-text for the terminal using whisper.cpp.

Modes:
  --stream        Continuous real-time transcription (default)
  --clip          Push-to-talk: record → transcribe → copy to clipboard

Options:
  --model <name>  Whisper model to use (default: small.en)
                  Available: tiny.en, base.en, small.en, medium.en, large-v3-turbo
  --lang <code>   Language code (default: en)
  --prompt <text> Vocabulary hint for Whisper (improves accuracy for domain terms)
  --help          Show this help message

Vocabulary file:
  Create ~/.config/dictate/vocab.txt with one term per line to permanently
  bias transcription toward your domain vocabulary. Example:

    tmux
    Neovim
    LazyVim
    zsh
    Kubernetes

Examples:
  dictate                       # stream mode with small.en
  dictate --clip                # push-to-talk mode
  dictate --model base.en       # use a smaller/faster model
  dictate --stream --lang es    # stream in Spanish
  dictate --prompt "React, Next.js, Vercel"
EOF
  exit 0
}

# ── Dependency checks ─────────────────────────

check_deps() {
  if ! command_exists whisper-server; then
    err "whisper-server not found. Install with: brew install whisper-cpp"
  fi
  if ! command_exists rec; then
    err "sox not found (needed for microphone recording). Install with: brew install sox"
  fi
  if ! command_exists curl; then
    err "curl not found."
  fi
}

# ── Model management ─────────────────────────

ensure_model() {
  local model="$1"
  local model_file="$MODEL_DIR/ggml-${model}.bin"

  if [[ -f "$model_file" ]]; then
    ok "Model '$model' found at $model_file"
    return
  fi

  local url="${HF_BASE_URL}/ggml-${model}.bin"

  info "Model '$model' not found locally. Downloading..."
  info "URL: $url"
  mkdir -p "$MODEL_DIR"

  if ! curl -L --progress-bar -o "$model_file" "$url"; then
    rm -f "$model_file"
    err "Failed to download model '$model'. Check model name and network."
  fi

  ok "Model '$model' downloaded to $model_file"
}

# ── Vocabulary prompt ─────────────────────────

build_prompt() {
  local user_prompt="$1"

  # Explicit --prompt takes priority
  if [[ -n "$user_prompt" ]]; then
    printf "%s" "$user_prompt"
    return
  fi

  # Then check for vocab file
  if [[ -f "$VOCAB_FILE" ]]; then
    local terms
    terms="$(grep -v '^#' "$VOCAB_FILE" | grep -v '^$' | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')"
    if [[ -n "$terms" ]]; then
      printf "%s" "$terms"
      return
    fi
  fi

  # Fall back to default vocab
  printf "%s" "$DEFAULT_VOCAB"
}

# ── Server management ────────────────────────

start_server() {
  local model="$1"
  local lang="$2"
  local prompt="$3"
  local model_file="$MODEL_DIR/ggml-${model}.bin"

  # Check if server is already running on our port
  if curl -s "${SERVER_URL}/" >/dev/null 2>&1; then
    ok "Whisper server already running on port $SERVER_PORT"
    return
  fi

  info "Starting whisper server (loading model into memory)..."

  whisper-server \
    -m "$model_file" \
    -l "$lang" \
    --prompt "$prompt" \
    --port "$SERVER_PORT" \
    -t 4 \
    2>/dev/null &
  SERVER_PID=$!

  # Wait for server to be ready (up to 15 seconds)
  local attempts=0
  while ! curl -s "${SERVER_URL}/" >/dev/null 2>&1; do
    sleep 0.5
    attempts=$((attempts + 1))
    if [[ $attempts -ge 30 ]]; then
      err "Whisper server failed to start after 15 seconds."
    fi
    # Check if process died
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
      err "Whisper server process exited unexpectedly."
    fi
  done

  ok "Whisper server ready (PID: $SERVER_PID)"
}

# ── Transcribe via server API ────────────────

transcribe_file() {
  local wav_file="$1"

  local response
  response="$(curl -s -X POST \
    "${SERVER_URL}/inference" \
    -F "file=@${wav_file}" \
    -F "response_format=text" \
    -F "temperature=0.0" \
    2>/dev/null)"

  # Clean up artifacts
  printf "%s" "$response" \
    | sed 's/\[BLANK_AUDIO\]//g; s/(silence)//g; s/\[silence\]//g' \
    | sed 's/^[[:space:]]*//' \
    | sed 's/[[:space:]]*$//' \
    | sed '/^$/d'
}

# ── Stream mode ───────────────────────────────

run_stream() {
  info "Chunk: ${STREAM_CHUNK_SEC}s | Ctrl+C to stop"
  echo ""
  printf "\033[1;33m🎤 Listening...\033[0m\n\n"

  local tmp_wav file_size result

  while true; do
    tmp_wav="$(mktemp /tmp/dictate-XXXXXX).wav"
    TEMP_FILES+=("$tmp_wav")

    # Record a chunk
    rec -q -r 16000 -c 1 -b 16 -t wav "$tmp_wav" \
      trim 0 "$STREAM_CHUNK_SEC" \
      2>/dev/null &
    REC_PID=$!
    wait "$REC_PID" 2>/dev/null
    REC_PID=""

    # Skip if file is too small (no real audio)
    file_size="$(wc -c < "$tmp_wav" | tr -d ' ')"
    if [[ "$file_size" -lt 5000 ]]; then
      rm -f "$tmp_wav"
      continue
    fi

    # Transcribe via server (sub-second)
    result="$(transcribe_file "$tmp_wav")"

    # Clean up
    rm -f "$tmp_wav"

    # Print non-empty results
    if [[ -n "$result" ]]; then
      printf "%s " "$result"
    fi
  done
}

# ── Clip mode ─────────────────────────────────

run_clip() {
  info "Push-to-talk mode | Ctrl+C to quit"
  echo ""

  local tmp_wav result

  while true; do
    echo "────────────────────────────────────────"
    printf "\033[1;33m⏺  Press ENTER to start recording...\033[0m"
    read -r

    tmp_wav="$(mktemp /tmp/dictate-XXXXXX).wav"
    TEMP_FILES+=("$tmp_wav")

    info "Recording... (press ENTER to stop)"

    # Record 16kHz mono 16-bit PCM WAV in background
    rec -q -r 16000 -c 1 -b 16 "$tmp_wav" 2>/dev/null &
    REC_PID=$!

    read -r

    # Stop recording
    kill "$REC_PID" 2>/dev/null
    wait "$REC_PID" 2>/dev/null
    REC_PID=""

    # Check file has content
    if [[ ! -s "$tmp_wav" ]]; then
      warn "Recording is empty, skipping."
      rm -f "$tmp_wav"
      continue
    fi

    info "Transcribing..."

    result="$(transcribe_file "$tmp_wav")"

    # Clean up temp file
    rm -f "$tmp_wav"

    if [[ -z "$result" ]]; then
      warn "No speech detected."
      continue
    fi

    # Print and copy to clipboard
    echo ""
    printf "\033[1;32m📝 %s\033[0m\n" "$result"
    echo ""

    if command_exists pbcopy; then
      printf "%s" "$result" | pbcopy
      ok "Copied to clipboard"
    fi
  done
}

# ── Argument parsing ──────────────────────────

parse_args() {
  MODE="$DEFAULT_MODE"
  MODEL="$DEFAULT_MODEL"
  LANG="$DEFAULT_LANG"
  USER_PROMPT=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --stream)
        MODE="stream"
        shift
        ;;
      --clip)
        MODE="clip"
        shift
        ;;
      --model)
        [[ -z "$2" ]] && err "--model requires a value (e.g., base.en, small.en)"
        MODEL="$2"
        shift 2
        ;;
      --lang)
        [[ -z "$2" ]] && err "--lang requires a value (e.g., en, es, fr)"
        LANG="$2"
        shift 2
        ;;
      --prompt)
        [[ -z "$2" ]] && err "--prompt requires a value"
        USER_PROMPT="$2"
        shift 2
        ;;
      --help|-h)
        usage
        ;;
      *)
        err "Unknown option: $1 (use --help for usage)"
        ;;
    esac
  done
}

# ── Main ──────────────────────────────────────

main() {
  parse_args "$@"

  # 1. Check dependencies
  check_deps

  # 2. Ensure model is downloaded
  ensure_model "$MODEL"

  # 3. Build vocabulary prompt
  local prompt
  prompt="$(build_prompt "$USER_PROMPT")"

  # 4. Start whisper server (model loads once, stays in memory)
  start_server "$MODEL" "$LANG" "$prompt"

  # 5. Run selected mode
  info "Model: $MODEL | Language: $LANG"
  [[ -n "$prompt" ]] && info "Vocab: ${prompt:0:60}..."

  case "$MODE" in
    stream) run_stream ;;
    clip)   run_clip ;;
  esac
}

main "$@"
