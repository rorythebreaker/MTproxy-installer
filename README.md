# Telemt Installer

An interactive TUI installer for [Telemt](https://github.com/telemt/telemt) — a fast MTProxy server for Telegram — on Debian-based Linux systems.

---

## Requirements

| Requirement | Notes |
|---|---|
| **OS** | Debian, Ubuntu, Linux Mint, Kali, MX Linux, or any Debian-based distro |
| **Privileges** | Must be run as `root` or via `sudo` |
| **Internet** | Required to download the binary |
| **Architecture** | Automatically detected (`x86_64`, `aarch64`, etc.) |

The following tools are required and will be installed automatically if missing:

`wget` · `tar` · `openssl` · `useradd` · `systemctl` · `curl` · `jq`

---

## Quick Start

```bash
# Download the script
git clone https://github.com/rorythebreaker/MTproxy-installer.git

# Make it executable
chmod +x install_telemt.sh

# Run as root
sudo ./install_telemt.sh
```

> No command-line arguments are needed. All configuration is done interactively through the TUI.

---

## What the Script Does

The installer guides you through 6 steps:

| Step | Action |
|---|---|
| **1** | Downloads the latest `telemt` binary for your architecture and libc variant (GNU or musl) and places it at `/bin/telemt` |
| **2** | Prompts for configuration: port, TLS masking domain, username, secret, and API listen address |
| **3** | Writes the configuration file to `/etc/telemt/telemt.toml` |
| **4** | Creates a dedicated system user `telemt` with home directory `/opt/telemt` |
| **5** | Creates the systemd service file `/etc/systemd/system/telemt.service` and reloads the daemon |
| **6** | Optionally enables the service for autostart and starts it immediately |

---

## Configuration Parameters

| Parameter | Description | Default |
|---|---|---|
| **Port** | Port the proxy listens on | `443` |
| **TLS domain** | Domain used for TLS masking (camouflage) | `petrovich.ru` |
| **Username** | Name for the proxy user in the config | `admin` |
| **Secret** | 32-character hex secret. Leave blank to auto-generate via `openssl rand -hex 16` | Auto-generated |
| **API listen** | Address and port for the local API endpoint | `127.0.0.1:9091` |

> **Warning:** Changing `tls_domain` after initial setup will invalidate all existing connection links for your users.

---

## Files Created

| Path | Description |
|---|---|
| `/bin/telemt` | Telemt binary |
| `/etc/telemt/telemt.toml` | Main configuration file |
| `/etc/systemd/system/telemt.service` | Systemd service unit |
| `/opt/telemt/` | Home directory for the `telemt` system user |

---

## Post-Installation Commands

```bash
# Check service status
systemctl status telemt

# View live logs
journalctl -u telemt -f

# Retrieve connection links for users
curl -s http://127.0.0.1:9091/v1/users | jq

# Start / Stop / Restart
systemctl start telemt
systemctl stop telemt
systemctl restart telemt

# Enable / Disable autostart
systemctl enable telemt
systemctl disable telemt
```

---

## Example Configuration File

The script generates a `telemt.toml` with the following structure:

```toml
# === General Settings ===
[general]
use_middle_proxy = false

[general.modes]
classic = false
secure  = false
tls     = true

[server]
port = 443

[server.api]
enabled = true
listen  = "127.0.0.1:9091"

# === Anti-Censorship & Masking ===
[censorship]
tls_domain = "example.com"

[access.users]
# format: "username" = "32_hex_chars_secret"
admin = "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"
```

---

## Re-running the Installer

If the script detects an existing binary, config file, or service unit, it will ask before overwriting each one. Config files are automatically backed up before being replaced:

```
/etc/telemt/telemt.toml.bak.20250326153042
```

---

## Troubleshooting

### Service fails to start

Check the journal for errors:

```bash
journalctl -u telemt -n 50 --no-pager
```

Common causes:
- **Port already in use** — check with `netstat -lnp | grep :<port>`
- **Invalid secret** — the secret must be exactly 32 lowercase hex characters
- **Config syntax error** — validate the TOML file manually

### Cannot retrieve connection links

The API endpoint is only available when the service is running. Wait a few seconds after start, then:

```bash
curl -s http://127.0.0.1:9091/v1/users | jq
```

If the service is on a custom API address, replace `127.0.0.1:9091` with your configured value.

### Download fails

Verify internet connectivity and that GitHub is accessible:

```bash
curl -I https://github.com/telemt/telemt/releases/latest
```

---

## Security Notes

- The `telemt` process runs as a dedicated unprivileged system user (`telemt`), not as root.
- `NoNewPrivileges=true` is set in the service unit.
- The binary is granted only `CAP_NET_BIND_SERVICE` to allow binding to privileged ports (< 1024).
- The API endpoint listens only on localhost (`127.0.0.1`) by default.
- Keep your secret private — anyone with it can use your proxy.

---

## Reference

- [Telemt GitHub Repository](https://github.com/telemt/telemt)
- [Telemt Quick Start Guide](https://github.com/telemt/telemt/blob/main/docs/QUICK_START_GUIDE.ru.md)
