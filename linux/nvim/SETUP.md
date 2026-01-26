# Neovim Configuration Setup Instructions

## 🔧 Fixed Issues

- ✅ Updated LSP configuration to use modern APIs
- ✅ Fixed tsserver → ts_ls deprecation
- ✅ Updated CopilotChat to main branch
- ✅ Fixed auto-session telescope integration
- ✅ Updated which-key to modern API

## 🚀 Setup Steps

### 1. Test the Configuration

```bash
# Start neovim and let lazy.nvim install plugins
nvim

# In neovim, install all plugins
:Lazy install

# Check health after installation
:checkhealth
```

### 2. Install External Dependencies

#### LSP Servers (Mason will handle most)

```bash
# Mason will auto-install these, but you can also install manually:
npm install -g typescript-language-server
pip install python-lsp-server
```

#### Formatters and Linters

```bash
# Python tools
pip install black isort ruff

# JavaScript/TypeScript tools
npm install -g prettier eslint_d

# Go tools
go install mvdan.cc/gofumpt@latest
go install golang.org/x/tools/cmd/goimports@latest

# Lua formatter
cargo install stylua
```

#### Git Tools

```bash
# LazyGit (for git integration)
# Ubuntu/Debian
sudo add-apt-repository ppa:lazygit-team/release
sudo apt update
sudo apt install lazygit

# Or download latest release
curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep browser_download_url | grep Linux_x86_64 | cut -d '"' -f 4 | wget -i - -O lazygit.tar.gz
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
```

#### AI Tools

##### GitHub Copilot (Cloud AI)

```vim
" In Neovim, authenticate with GitHub
:Copilot setup
```

##### Ollama (Local AI) - WSL2 + Windows Setup

Since you're running Ollama on Windows and Neovim in WSL2:

**On Windows:**

1. Make sure Ollama is running
2. Install a model: `ollama pull codellama:7b`
3. Check Windows Firewall allows port 11434

**In WSL2 (this Neovim):**

```vim
" Test Ollama connection
:OllamaStatus

" If connection fails, check the helper guide below
```

**WSL2 → Windows Connection Troubleshooting:**

```bash
# Check if Windows host is reachable
ping $(grep nameserver /etc/resolv.conf | awk '{print $2}')

# Test Ollama port manually
WSL_HOST=$(grep nameserver /etc/resolv.conf | awk '{print $2}')
curl -s "http://$WSL_HOST:11434/api/tags"
```

If Ollama is not accessible:

1. Ensure Ollama is running on Windows
2. Check Windows Firewall (allow port 11434)
3. Try running Ollama with: `ollama serve --host 0.0.0.0`

### 3. First-Time Neovim Commands

```vim
" Install LSP servers via Mason
:Mason

" Check everything is working
:checkhealth

" Test telescope
:Telescope find_files

" Test file explorer
:NvimTreeToggle

" Test Copilot (if you have subscription)
:Copilot setup
```

## 🎯 Key Bindings Quick Reference

### Essential

- `Space + e` - Toggle file explorer
- `Space + ff` - Find files
- `Space + fg` - Live grep search
- `Space + fb` - Browse buffers
- `Tab / Shift+Tab` - Navigate buffers

### AI Assistance

- `Ctrl + J` - Accept Copilot suggestion (insert mode)
- `Space + cc` - Open Copilot chat
- `Space + ai` - Local AI prompt (visual mode)

### Git

- `Space + gg` - LazyGit interface
- `Space + hs` - Stage git hunk
- `Space + hp` - Preview git hunk

### Development

- `gd` - Go to definition
- `gr` - Find references
- `K` - Show hover documentation
- `Space + ca` - Code actions
- `Space + f` - Format code

### Terminal

- `Ctrl + \` - Toggle floating terminal
- `Space + t` - Toggle terminal

### Sessions

- `Space + ss` - Search/switch sessions
- `Space + sr` - Restore session

## 🔍 Troubleshooting

### If plugins fail to install:

```vim
:Lazy clean
:Lazy install
```

### If LSP servers don't work:

```vim
:Mason
" Install servers manually from the UI
```

### If Copilot doesn't work:

```vim
:Copilot setup
" Follow the authentication flow
```

### Check configuration health:

```vim
:checkhealth
:checkhealth telescope
:checkhealth which-key
:checkhealth mason
```

## 📝 Next Steps

1. **Start with basic editing** - Open some files and get familiar
2. **Test LSP features** - Try go-to-definition, hover, code actions
3. **Explore Telescope** - Use fuzzy finding for files and text
4. **Set up Git workflow** - Try LazyGit integration
5. **Configure AI assistants** - Set up Copilot and/or Ollama
6. **Customize as needed** - Add more plugins through your lab work

Your minimal configuration is now ready with modern, compatible plugin versions!
