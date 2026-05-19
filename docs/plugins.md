# Plugins & Themes

psmux has a full plugin ecosystem — ports of the most popular tmux plugins, reimplemented in PowerShell for Windows.

## Plugin Repository

**Browse available plugins and themes:** [**psmux-plugins**](https://github.com/psmux/psmux-plugins)

**Install & manage plugins with a TUI:** [**Tmux Plugin Panel**](https://github.com/psmux/Tmux-Plugin-Panel) — a terminal UI for browsing, installing, updating, and removing plugins and themes.

## Available Plugins

| Plugin | Description |
|--------|-------------|
| [ppm](https://github.com/psmux/psmux-plugins/tree/main/ppm) | Plugin manager (like tpm) |
| [psmux-sensible](https://github.com/psmux/psmux-plugins/tree/main/psmux-sensible) | Sensible defaults for psmux |
| [psmux-yank](https://github.com/psmux/psmux-plugins/tree/main/psmux-yank) | Windows clipboard integration |
| [psmux-resurrect](https://github.com/psmux/psmux-plugins/tree/main/psmux-resurrect) | Save/restore sessions |
| [psmux-continuum](https://github.com/psmux/psmux-plugins/tree/main/psmux-continuum) | Auto save/restore sessions (works with resurrect) |
| [psmux-pain-control](https://github.com/psmux/psmux-plugins/tree/main/psmux-pain-control) | Better pane navigation |
| [psmux-prefix-highlight](https://github.com/psmux/psmux-plugins/tree/main/psmux-prefix-highlight) | Prefix key indicator |
| [psmux-battery](https://github.com/psmux/psmux-plugins/tree/main/psmux-battery) | Battery status in status bar |
| [psmux-cpu](https://github.com/psmux/psmux-plugins/tree/main/psmux-cpu) | CPU usage in status bar |
| [psmux-net-speed](https://github.com/psmux/psmux-plugins/tree/main/psmux-net-speed) | Network speed in status bar |
| [psmux-git-status](https://github.com/psmux/psmux-plugins/tree/main/psmux-git-status) | Git branch and status in status bar |
| [psmux-sidebar](https://github.com/psmux/psmux-plugins/tree/main/psmux-sidebar) | File tree sidebar |
| [psmux-logging](https://github.com/psmux/psmux-plugins/tree/main/psmux-logging) | Log pane output to files |

## Themes

| Theme | Description |
|-------|-------------|
| [Catppuccin](https://github.com/psmux/psmux-plugins/tree/main/psmux-theme-catppuccin) | Soothing pastel theme (Latte, Frappe, Macchiato, Mocha) |
| [Dracula](https://github.com/psmux/psmux-plugins/tree/main/psmux-theme-dracula) | Dark theme with vibrant colors |
| [Nord](https://github.com/psmux/psmux-plugins/tree/main/psmux-theme-nord) | Arctic, north bluish color palette |
| [Tokyo Night](https://github.com/psmux/psmux-plugins/tree/main/psmux-theme-tokyonight) | Clean dark theme inspired by Tokyo at night |
| [Gruvbox](https://github.com/psmux/psmux-plugins/tree/main/psmux-theme-gruvbox) | Retro groove color scheme |
| [Everforest](https://github.com/psmux/psmux-plugins/tree/main/psmux-theme-everforest) | Comfortable green based color scheme |
| [Kanagawa](https://github.com/psmux/psmux-plugins/tree/main/psmux-theme-kanagawa) | Dark theme inspired by Katsushika Hokusai |
| [One Dark](https://github.com/psmux/psmux-plugins/tree/main/psmux-theme-onedark) | Atom One Dark inspired theme |
| [Rose Pine](https://github.com/psmux/psmux-plugins/tree/main/psmux-theme-rosepine) | Soho vibes for the terminal |

## Quick Start

```powershell
# Install the plugin manager
git clone https://github.com/psmux/psmux-plugins.git "$env:TEMP\psmux-plugins"
Copy-Item "$env:TEMP\psmux-plugins\ppm" "$env:USERPROFILE\.psmux\plugins\ppm" -Recurse
Remove-Item "$env:TEMP\psmux-plugins" -Recurse -Force
```

Then add to your `~/.psmux.conf`:

```tmux
# Enable plugin PowerShell script execution (off by default for safety)
set -g allow-plugin-scripts on

set -g @plugin 'psmux-plugins/ppm'
set -g @plugin 'psmux-plugins/psmux-sensible'
run '~/.psmux/plugins/ppm/ppm.ps1'
```

Press `Prefix + I` inside psmux to install the declared plugins.

## Plugin Script Security

Plugin `.ps1` entry scripts are **disabled by default**. psmux will still read
`plugin.conf` files (static config) without any opt-in.

To allow plugin `.ps1` scripts to run (needed for theme plugins that use
PowerShell variables), add this line to your config **before** any `@plugin`
declarations:

```tmux
set -g allow-plugin-scripts on
```

This is an explicit trust decision: only enable it when you have reviewed
or trust the plugins you have installed.
