# Claude Switch

<p align="center">
  <img src="https://img.shields.io/badge/version-1.1.0-blue?style=for-the-badge&logo=none">
  <img src="https://img.shields.io/badge/license-MIT-green?style=for-the-badge&logo=none">
  <img src="https://img.shields.io/badge/bash-4.0+-yellow?style=for-the-badge&logo=gnu-bash">
</p>

<p align="center">
  <b>A beautiful, interactive TUI for managing Claude Model configurations</b>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/m-r-mallick/claude-switch/main/demo.png" alt="TUI Demo" width="600">
</p>

---

## ✨ Features

- **Interactive TUI** - Beautiful keyboard-driven interface
- **Config Persistence** - All configs stored in `~/.claudeswitchrc`
- **Easy Management** - Add, edit, delete configurations via TUI or CLI
- **Import/Export** - Share configurations with others
- **Zero Dependencies** - Only requires `jq`
- **Single Command Install** - `curl -fsSL <url> | bash`

---

## 🚀 Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/m-r-mallick/claude-switch/main/install | bash
```

Or for offline install:

```bash
curl -fsSL https://raw.githubusercontent.com/m-r-mallick/claude-switch/main/install | bash -s -- --local /path/to/claude-switch-tui.sh
```

---

## 📖 Usage

### Interactive TUI

```bash
claude-switch
```

Use arrow keys to navigate, Enter to select, `q` to quit.

### CLI Commands

| Command | Description |
|---------|-------------|
| `claude-switch` | Launch TUI |
| `claude-switch list` | List all configurations |
| `claude-switch current` | Show current configuration |
| `claude-switch switch <name>` | Switch to a configuration |
| `claude-switch add` | Add new configuration (interactive) |
| `claude-switch add myconfig <url> <token> [models...]` | Add via command line |
| `claude-switch edit <name>` | Edit a configuration |
| `claude-switch delete <name>` | Delete a configuration |
| `claude-switch import file.json` | Import configurations |
| `claude-switch export [file]` | Export all configurations |
| `claude-switch install` | Install binary to `/usr/local/bin` |
| `claude-switch uninstall` | Remove the binary |

---

## 📁 Configuration File

All configurations are stored in `~/.claudeswitchrc`:

```json
{
  "mimo": {
    "base_url": "https://api.xiaomimimo.com/anthropic",
    "auth_token": "sk-...",
    "opus_model": "mimo-v2-flash",
    "sonnet_model": "mimo-v2-flash",
    "haiku_model": "mimo-v2-flash"
  },
  "anthropic": {
    "base_url": "https://api.anthropic.com/v1",
    "auth_token": "sk-ant-api03-...",
    "opus_model": "claude-3-opus-20240229",
    "sonnet_model": "claude-3-5-sonnet-20241022",
    "haiku_model": "claude-3-haiku-20240307"
  }
}
```

---

## 🎮 TUI Navigation

```
┌────────────────────────────────────────────────┐
│  Main Menu                                     │
├────────────────────────────────────────────────┤
│    ▶ Switch Config                             │
│      Add Config                                │
│      Edit Config                               │
│      Delete Config                             │
│      View Current                              │
│      List All                                  │
│      About                                     │
│      Exit                                      │
├────────────────────────────────────────────────┤
│  ↑↓ to navigate • Enter to select • q to quit  │
└────────────────────────────────────────────────┘
```

---

## 📦 Default Configurations

The following configurations are included by default:

| Name | Base URL |
|------|----------|
| `mimo` | `https://api.xiaomimimo.com/anthropic` |
| `anthropic` | `https://api.anthropic.com/v1` |
| `minimax` | `https://api.minimax.io/anthropic` |

---

## 🔧 Requirements

- `bash` 4.0+
- `jq` (JSON processor)

Install `jq` on Debian/Ubuntu:
```bash
apt install jq
```

Install `jq` on macOS:
```bash
brew install jq
```

---

## 📝 Examples

### Adding a new configuration via CLI

```bash
claude-switch add custom https://api.custom.com/anthropic sk-custom-token-123
```

### Switching configurations

```bash
claude-switch switch anthropic
```

### Exporting and sharing configurations

```bash
claude-switch export my-configs.json
# Share the file with others...
claude-switch import my-configs.json
```

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Made with ❤️ by Claude Switch Team
</p>
