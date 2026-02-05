# System Status and Service Management

## Quick Start

Check all services and system status:
```bash
bash ~/Desktop/tools/status.sh
```

## Service Management Scripts

### Chrome (`chrome.sh`)
Manage Google Chrome with remote debugging capabilities.

```bash
bash ~/Desktop/tools/chrome.sh install   # Install Chrome
bash ~/Desktop/tools/chrome.sh start     # Start Chrome with debugging
bash ~/Desktop/tools/chrome.sh stop      # Stop Chrome
bash ~/Desktop/tools/chrome.sh status    # Check Chrome status
```

Features:
- Automatic display detection (VNC or headless)
- Remote debugging on port 9222
- Process management and duplicate prevention

### VNC (`vnc-start.sh`)
Start VNC server and noVNC web interface.

```bash
bash ~/Desktop/tools/vnc-start.sh
```

Access:
- VNC: localhost:5901
- noVNC Web UI: http://localhost:6080/vnc.html

### Cloudflare Tunnel (`cloudflared-tunnel.sh`)
Manage Cloudflare tunnel for external access.

```bash
bash ~/Desktop/tools/cloudflared-tunnel.sh
```

Requires: CF_TUNNEL environment variable

### System Status (`status.sh`)
Comprehensive system and service health check.

```bash
bash ~/Desktop/tools/status.sh
```

Checks:
- System resources (CPU, memory, disk)
- Software installations
- Service processes and ports
- Network connectivity
- Data directories
- Log files

## Port Reference

| Port | Service | Description |
|------|---------|-------------|
| 22 | SSH | Remote shell access |
| 5901 | VNC | TigerVNC server |
| 6080 | noVNC | Web-based VNC client |
| 9222 | Chrome | Remote debugging protocol |

## Quick Diagnostics

If status.sh reports errors, follow the provided recommendations:
- Chrome not running: `bash ~/Desktop/tools/chrome.sh start`
- VNC not running: `bash ~/Desktop/tools/vnc-start.sh`
- Git missing: `sudo apt install -y git`
- Docker missing: `curl -fsSL https://get.docker.com | sh`

## Log Locations

- Chrome: `~/data/browser/chrome/chrome.log`
- Cloudflare Tunnel: `~/logs/tunnel.log`
- System logs: `~/logs/`
