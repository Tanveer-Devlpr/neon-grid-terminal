# NEON//GRID · Symbiote Terminal

**A 4K cyberpunk theme for Windows Terminal** with a clean three-pane dashboard and a fully interactive PowerShell console. Beautiful, static artwork means no stuttering animations or heavy telemetry processes.

![NEON GRID dashboard](assets/hud.png)

## Install with one command

Open **Windows PowerShell** and paste:

```powershell
irm https://raw.githubusercontent.com/Tanveer-Devlpr/neon-grid-terminal/main/install.ps1 | iex
```

Windows Terminal will open NEON//GRID automatically. The one-command installer adds only four profiles required for the three-pane layout, backs up current settings, and makes the NEON shell the default. It does not replace unrelated profiles or add global PowerShell startup hooks.

**Requirements:** Windows 10/11, Windows PowerShell 5.1+, and an internet connection. Windows Terminal is installed via `winget` when available and absent. Installation can be restricted by device policies or software availability.

## The three-pane design

| Area | Content |
| --- | --- |
| Upper | Static telemetry-style art, Nexus Core and neon orbital Earth |
| Lower left | Real interactive PowerShell command pane |
| Lower right | Static illustrated watch/hacker artwork |

![PowerShell command pane](assets/shell.png)

![Neon watch artwork](assets/watch.png)

### Customize

Open Windows Terminal settings and locate **NEON GRID SHELL COMMAND**. Its `padding` setting controls the spacing between live command output and the neon frame.

Default padding: `75, 95, 70, 80` (left, top, right, bottom).

All three images are bundled. There is no additional remote-access software, login, or service.

### Update

Run the same one-command installer again. Profiles update without duplication, with settings backed up first. Upgrading from v1.0.0 automatically removes its discontinued optional profiles and shortcut.

### Uninstall

```powershell
& "$env:LOCALAPPDATA\Programs\NeonGridTerminal\scripts\Uninstall.ps1"
```

This removes NEON//GRID community profiles and restores the saved previous default. It leaves backups and files in place for recovery. You can delete `%LOCALAPPDATA%\Programs\NeonGridTerminal` after closing its open Terminal tabs.

### Notes

Images are high-quality upscaled artwork; increasing image dimensions does not invent native resolution detail. All displayed CPU, RAM, node, orbit, and connection/status labels **inside the artwork are decorative**, not readings from your computer.

### Security

Inspect [install.ps1](install.ps1) before using any `irm ... | iex` command. The installer writes to the current user's Windows Terminal configuration and a folder under the current user's `%LOCALAPPDATA%`. It saves backups before writing and does not collect or upload personal data.

### License

MIT. See [LICENSE](LICENSE).
