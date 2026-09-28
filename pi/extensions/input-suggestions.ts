import { uuidv7, type UserMessage } from "@earendil-works/pi-ai";
import { CustomEditor, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth, type EditorTheme, type TUI } from "@earendil-works/pi-tui";
import type { KeybindingsManager } from "@earendil-works/pi-coding-agent";

const DEBOUNCE_MS = 250;
const MIN_DRAFT_CHARS = 4;
const MAX_DRAFT_CHARS = 1200;
const MAX_CONVERSATION_CHARS = 800;
const CURSOR_AT_END = "\x1b[7m \x1b[0m";
const FAST_MODEL_CANDIDATES = [
  "openai/gpt-4.1-mini",
  "openai/gpt-4o-mini",
  "anthropic/claude-3-5-haiku-latest",
  "anthropic/claude-3-haiku-20240307",
];

const SYSTEM_PROMPT = `You are an inline AI autocomplete engine for a terminal coding agent input box.

Predict the exact suffix that should be appended to the user's current partially typed draft.

Rules:
- Return ONLY the suffix text to insert at the cursor.
- Do not repeat any part of the draft.
- Return at least one complete sentence when possible, usually 8-30 words.
- Complete the user's intent, not the assistant's answer.
- Preserve the user's style, casing, and punctuation.
- If no confident/helpful completion exists, return an empty string.
- Do not wrap the result in quotes, markdown, or code fences.`;

class AiSuggestionEditor extends CustomEditor {
  private readonly ctx: ExtensionContext;
  private readonly editorTheme: EditorTheme;
  private readonly keybindingsManager: KeybindingsManager;
  private debounceTimer: ReturnType<typeof setTimeout> | undefined;
  private requestAbort: AbortController | undefined;
  private pendingDraft: string | undefined;
  private requestId = 0;
  private suggestion: { draft: string; suffix: string; fullText: string } | undefined;
  private cachedModel: ReturnType<typeof getCompletionModel> | undefined;
  private readonly completionSessionId = uuidv7();

  constructor(tui: TUI, theme: EditorTheme, keybindings: KeybindingsManager, ctx: ExtensionContext) {
    super(tui, theme, keybindings);
    this.ctx = ctx;
    this.editorTheme = theme;
    this.keybindingsManager = keybindings;
  }

  override handleInput(data: string): void {
    if (this.keybindingsManager.matches(data, "tui.input.tab") && !this.isShowingAutocomplete()) {
      const suffix = this.getCurrentSuggestion();
      if (suffix) {
        this.insertTextAtCursor(suffix);
        this.clearSuggestion();
        return;
      }
    }

    const before = this.getText();
    super.handleInput(data);
    const after = this.getText();

    if (after !== before) {
      if (this.canReuseSuggestionFor(after)) {
        this.cancelPending();
        this.tui.requestRender();
        return;
      }

      if (this.suggestion?.fullText === after) {
        this.clearSuggestion();
        this.cancelPending();
        return;
      }

      this.clearSuggestion();
      this.scheduleCompletion();
    } else if (!this.isCursorAtDraftEnd()) {
      this.clearSuggestion();
    }
  }

  override setText(text: string): void {
    super.setText(text);
    this.clearSuggestion();
    this.scheduleCompletion();
  }

  override render(width: number): string[] {
    const lines = super.render(width);
    const suffix = this.getCurrentSuggestion();
    if (!suffix) return lines;

    const firstSuggestionLine = suffix.split("\n", 1)[0];
    if (!firstSuggestionLine) return lines;

    const ghost = this.editorTheme.selectList.description(firstSuggestionLine);
    const cursorLineIndex = lines.findIndex((line) => line.includes(CURSOR_AT_END));
    if (cursorLineIndex === -1) return lines;

    const withGhost = lines[cursorLineIndex].replace(CURSOR_AT_END, CURSOR_AT_END + ghost);
    lines[cursorLineIndex] = trimLineToWidth(withGhost, width);
    return lines;
  }

  dispose(): void {
    this.cancelPending();
  }

  private scheduleCompletion(): void {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = undefined;
    }

    const draft = this.getText();
    if (!this.shouldComplete(draft)) return;

    if (this.pendingDraft) {
      if (draft.startsWith(this.pendingDraft) || this.pendingDraft.startsWith(draft)) {
        return;
      }
      this.abortInFlightRequest();
    }

    this.debounceTimer = setTimeout(() => {
      void this.requestCompletion(draft);
    }, DEBOUNCE_MS);
  }

  private async requestCompletion(draft: string): Promise<void> {
    const model = this.getModel();
    if (!model) return;
    if (!this.ctx.isIdle()) return;

    const requestId = ++this.requestId;
    const controller = new AbortController();
    this.requestAbort = controller;
    this.pendingDraft = draft;

    try {
      const message: UserMessage = {
        role: "user",
        timestamp: Date.now(),
        content: [{ type: "text", text: buildCompletionPrompt(draft, buildRecentConversation(this.ctx)) }],
      };

      const response = await this.ctx.modelRegistry.complete(
        model,
        { systemPrompt: SYSTEM_PROMPT, messages: [message] },
        {
          signal: controller.signal,
          sessionId: this.completionSessionId,
          reasoningEffort: "none",
          reasoning: "off",
          textVerbosity: "low",
          transport: "websocket-cached",
          maxRetries: 0,
          timeoutMs: 4000,
        } as never,
      );

      if (requestId !== this.requestId || controller.signal.aborted) return;

      const suffix = sanitizeCompletion(
        response.content
          .filter((part): part is { type: "text"; text: string } => part.type === "text")
          .map((part) => part.text)
          .join(""),
        draft,
      );

      const fullText = draft + suffix;
      const currentText = this.getText();
      this.suggestion = suffix && fullText.startsWith(currentText) && fullText !== currentText
        ? { draft, suffix, fullText }
        : undefined;
      this.tui.requestRender();
    } catch {
      if (requestId === this.requestId) {
        this.suggestion = undefined;
        this.tui.requestRender();
      }
    } finally {
      if (requestId === this.requestId) {
        this.requestAbort = undefined;
        this.pendingDraft = undefined;
      }
    }
  }

  private shouldComplete(draft: string): boolean {
    if (!this.getModel()) return false;
    if (draft.trim().length < MIN_DRAFT_CHARS) return false;
    if (draft.length > MAX_DRAFT_CHARS) return false;
    if (this.isShowingAutocomplete()) return false;
    if (!this.isCursorAtDraftEnd()) return false;
    if (!isCompletionTrigger(draft)) return false;
    return true;
  }

  private isCursorAtDraftEnd(): boolean {
    const cursor = this.getCursor();
    const lines = this.getLines();
    const currentLine = lines[cursor.line] ?? "";
    return cursor.line === lines.length - 1 && cursor.col === currentLine.length;
  }

  private getCurrentSuggestion(): string | undefined {
    if (this.isShowingAutocomplete()) return undefined;
    if (!this.isCursorAtDraftEnd()) return undefined;
    if (!this.suggestion) return undefined;

    const text = this.getText();
    if (!this.canReuseSuggestionFor(text)) return undefined;
    return this.suggestion.fullText.slice(text.length);
  }

  private canReuseSuggestionFor(text: string): boolean {
    if (!this.suggestion) return false;
    if (text.length < MIN_DRAFT_CHARS) return false;
    return this.suggestion.fullText.startsWith(text) && text !== this.suggestion.fullText;
  }

  private getModel(): ReturnType<typeof getCompletionModel> {
    this.cachedModel ??= getCompletionModel(this.ctx);
    return this.cachedModel;
  }

  private clearSuggestion(): void {
    if (!this.suggestion) return;
    this.suggestion = undefined;
    this.tui.requestRender();
  }

  private cancelPending(): void {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = undefined;
    }
    this.abortInFlightRequest();
  }

  private abortInFlightRequest(): void {
    this.requestAbort?.abort();
    this.requestAbort = undefined;
    this.pendingDraft = undefined;
    this.requestId++;
  }
}

function isCompletionTrigger(draft: string): boolean {
  return /[\s.,;:!?)]$/.test(draft) || draft.endsWith("/.") || draft.endsWith("-");
}

function getCompletionModel(ctx: ExtensionContext) {
  const configured = process.env.PI_AUTOCOMPLETE_MODEL;
  if (configured) {
    const slash = configured.indexOf("/");
    if (slash > 0) {
      const model = ctx.modelRegistry.find(configured.slice(0, slash), configured.slice(slash + 1));
      if (model && ctx.modelRegistry.hasConfiguredAuth(model)) return model;
    }
  }

  for (const candidate of FAST_MODEL_CANDIDATES) {
    const slash = candidate.indexOf("/");
    const model = ctx.modelRegistry.find(candidate.slice(0, slash), candidate.slice(slash + 1));
    if (model && ctx.modelRegistry.hasConfiguredAuth(model)) return model;
  }

  return ctx.model;
}

function buildCompletionPrompt(draft: string, recentConversation: string): string {
  return [
    "Recent conversation context:",
    recentConversation || "(none)",
    "",
    "Current user draft. Complete this draft by returning only the suffix to append:",
    "<draft>",
    draft,
    "</draft>",
  ].join("\n");
}

function buildRecentConversation(ctx: ExtensionContext): string {
  const sections: string[] = [];

  for (const entry of ctx.sessionManager.getBranch().slice(-6)) {
    if (entry.type !== "message") continue;
    const message = entry.message;
    if (!("role" in message)) continue;
    if (message.role !== "user" && message.role !== "assistant") continue;

    const text = Array.isArray(message.content)
      ? message.content
          .filter((part): part is { type: "text"; text: string } => part?.type === "text")
          .map((part) => part.text)
          .join("\n")
          .trim()
      : "";

    if (text) sections.push(`${message.role}: ${text}`);
  }

  const full = sections.join("\n\n");
  return full.length > MAX_CONVERSATION_CHARS ? full.slice(-MAX_CONVERSATION_CHARS) : full;
}

function sanitizeCompletion(raw: string, draft: string): string {
  let suffix = raw
    .replace(/^```[a-zA-Z0-9_-]*\n?/, "")
    .replace(/```$/, "")
    .replace(/^['"]|['"]$/g, "")
    .replace(/\r/g, "")
    .trimStart();

  if (suffix.startsWith(draft)) {
    suffix = suffix.slice(draft.length);
  }

  suffix = removeOverlap(draft, suffix).replace(/\n{3,}/g, "\n\n");

  if (suffix.length > 320) {
    suffix = suffix.slice(0, 320).replace(/\s+\S*$/, "");
  }

  return suffix;
}

function removeOverlap(prefix: string, suffix: string): string {
  const max = Math.min(prefix.length, suffix.length, 120);
  for (let length = max; length > 0; length--) {
    if (prefix.endsWith(suffix.slice(0, length))) {
      return suffix.slice(length);
    }
  }
  return suffix;
}

function trimLineToWidth(line: string, width: number): string {
  let trimmed = line;
  while (visibleWidth(trimmed) > width && trimmed.endsWith(" ")) {
    trimmed = trimmed.slice(0, -1);
  }
  return visibleWidth(trimmed) > width ? truncateToWidth(trimmed, width, "") : trimmed;
}

export default function(pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") return;

    ctx.ui.setEditorComponent((tui, theme, keybindings) => new AiSuggestionEditor(tui, theme, keybindings, ctx));
  });
}
