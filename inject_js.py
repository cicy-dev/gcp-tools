#!/usr/bin/env python3
"""
Inject auto-run JavaScript into an Electron window when DOM is ready.

This script sends a POST request to the Electron MCP server to inject JavaScript
that will auto-run when the DOM is ready.
"""

import os
import sys
import json
import urllib.request
import urllib.error
from pathlib import Path


def main():
    # Configuration
    win_id = 1
    server_url = "http://localhost:8101/rpc/exec_js"

    # Load auth token from file
    token_path = Path.home() / "electron-mcp-token.txt"
    try:
        auth_token = token_path.read_text().strip()
    except FileNotFoundError:
        print(f"Error: Auth token file not found: {token_path}", file=sys.stderr)
        sys.exit(1)

    # Load JavaScript code to inject
    js_path = Path("/projects/electron-mcp/main/skills/telegram-web/inject.js")
    try:
        js_code = js_path.read_text()
    except FileNotFoundError:
        print(f"Error: JavaScript file not found: {js_path}", file=sys.stderr)
        sys.exit(1)

    # Build request payload
    payload = json.dumps({"win_id": win_id, "code": js_code}).encode("utf-8")

    # Create request
    req = urllib.request.Request(
        url=server_url,
        data=payload,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {auth_token}",
        },
        method="POST",
    )

    # Send request
    try:
        with urllib.request.urlopen(req) as response:
            result = response.read().decode("utf-8")
            print(result)
    except urllib.error.HTTPError as e:
        print(f"Error: HTTP {e.code} - {e.reason}", file=sys.stderr)
        print(e.read().decode("utf-8"), file=sys.stderr)
        sys.exit(1)
    except urllib.error.URLError as e:
        print(f"Error: {e.reason}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
