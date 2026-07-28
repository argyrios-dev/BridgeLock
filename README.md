<p align="center">
    <img src="IntroREADME.png" alt="BridgeLock Banner" width="100%">
</p>

<h1 align="center">BridgeLock</h1>

<p align="center">
    <strong>Secure individual macOS virtual desktops with a PIN.</strong>
</p>

<p align="center">
    Bring true access control to macOS virtual desktops. Protect individual workspaces without locking your entire Mac.
</p>

<p align="center">
    <img src="https://img.shields.io/badge/macOS-13+-black?style=for-the-badge&logo=apple">
    <img src="https://img.shields.io/badge/Swift-6-orange?style=for-the-badge&logo=swift">
    <img src="https://img.shields.io/badge/Platform-macOS-blue?style=for-the-badge">
    <img src="https://img.shields.io/github/license/argyrios-dev/BridgeLock?style=for-the-badge">
</p>

---

## Demo

<p align="center">
    <img src="Demo.gif" alt="BridgeLock Demo" width="100%">
</p>

---

## Screenshots

<p align="center">
    <img src="Screenshot-Locked.png" alt="Locked Desktop" width="90%">
</p>

<p align="center">
    <em>Protected desktop requesting a PIN.</em>
</p>

<br>

<p align="center">
    <img src="Screenshot-Unlocked.png" alt="Unlocked Desktop" width="90%">
</p>

<p align="center">
    <em>Desktop after successful authentication.</em>
</p>

---

## Overview

Mission Control allows multiple virtual desktops, but once your Mac is unlocked every desktop is immediately accessible.

BridgeLock adds an additional security layer by allowing individual virtual desktops to be protected with a secure PIN while the rest of the system remains available.

Whether you're working with confidential information, sharing your screen, or separating personal and professional workspaces, BridgeLock keeps sensitive desktops protected without interrupting your workflow.

---

## Features

- Lock individual virtual desktops
- Secure PIN storage using the macOS Keychain
- Native SwiftUI application
- Lightweight menu bar utility
- No cloud services
- No telemetry
- No internet connection required
- Local-first architecture
- Built exclusively for macOS

---

## Installation

Download the latest release from the Releases page.

1. Open the DMG.
2. Drag **BridgeLock.app** into the **Applications** folder.
3. Launch BridgeLock.
4. Grant Accessibility permission.
5. Configure your PIN.

---

## Requirements

- macOS 13 Ventura or later
- Apple Silicon or Intel

---

## Security

BridgeLock stores your PIN securely in the macOS Keychain.

- No analytics
- No tracking
- No cloud synchronization
- No external servers
- All data remains on your Mac

---

## Built With

- Swift 6
- SwiftUI
- AppKit
- Security Framework
- ServiceManagement
- CoreGraphics

---

## Roadmap

- Touch ID support
- Multiple protected desktops
- Keyboard shortcuts
- Auto-lock timers
- Custom lock screen themes
- Multi-monitor improvements
- Localization

---

## Contributing

Contributions are welcome.

If you discover a bug or have an idea for an improvement, please open an Issue or submit a Pull Request.

For major changes, please open an Issue first to discuss the proposal.

---

## License

Copyright © 2025 Argyrios.

See the LICENSE file for licensing information.
