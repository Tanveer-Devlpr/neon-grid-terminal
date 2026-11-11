# Security and installation

The one-line command `irm https://raw.githubusercontent.com/Tanveer-Devlpr/neon-grid-terminal/main/install.ps1 | iex` runs a remotely retrieved PowerShell script. **Review the source before executing it.** Prefer the repository's versioned release archive for auditable installs.

The installer modifies only your current-user Windows Terminal settings and creates `%LOCALAPPDATA%\Programs\NeonGridTerminal`. Existing Terminal settings are backed up before modification.

The optional Desktop Commander integration does not embed any authentication credentials, does not auto-approve device access, and does not run until you choose the remote profile. Report security issues privately to the repository maintainer rather than posting secrets in public issues.
