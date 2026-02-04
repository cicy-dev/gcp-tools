#!/usr/bin/env python3
"""
OTP Generator - Generate Time-based One-Time Passwords

Usage:
    python3 otp.py <secret_token>

Example:
    python3 otp.py JBSWY3DPEHPK3PXP

The script automatically installs pyotp if needed.
"""
import subprocess
import sys
import time

def install_pyotp():
    try:
        import pyotp
    except ImportError:
        print("Installing pyotp...")
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "pyotp"])
        except subprocess.CalledProcessError:
            print("Pip install failed, trying system package...")
            subprocess.check_call(["sudo", "apt", "install", "-y", "python3-pyotp"])
        import pyotp
    return pyotp

if len(sys.argv) != 2:
    print("Usage: python3 otp.py <token>")
    sys.exit(1)

pyotp = install_pyotp()
secret = sys.argv[1]
totp = pyotp.TOTP(secret)
current_otp = totp.now()

print(f"Current OTP: {current_otp}")
print(f"Valid for: {30 - (int(time.time()) % 30)} seconds")
