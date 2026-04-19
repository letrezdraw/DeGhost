# 👻 DeGhost

<p align="center">
  <b>Hardware-aware Windows optimizer</b><br/>
  Fast cleanup • Safe debloat • Performance tuning • One-click restore
</p>

<p align="center">
  <img alt="Windows" src="https://img.shields.io/badge/Platform-Windows-0078D6?logo=windows&logoColor=white"/>
  <img alt="Batch + PowerShell" src="https://img.shields.io/badge/Stack-Batch%20%2B%20PowerShell-5391FE?logo=powershell&logoColor=white"/>
  <img alt="Portable" src="https://img.shields.io/badge/Portable-Yes-2ea44f"/>
  <img alt="Dependencies" src="https://img.shields.io/badge/Dependencies-None-brightgreen"/>
</p>

---

## ✨ What is DeGhost?

**DeGhost** is a portable Windows optimization toolkit that combines a simple Batch launcher with focused PowerShell modules.

It is designed to:
- detect your hardware profile,
- clean common junk/cache locations,
- remove selected built-in apps,
- apply performance/service/startup tweaks,
- and let you restore registry backups quickly.

No installers, no heavy UI, no external dependencies.

---

## 🚀 Core Features

- **Hardware-aware startup detection**
  - Detects RAM class (`8GB`, `16GB`, `32GB+`)
  - Detects CPU vendor (`Intel` / `AMD`)
  - Lists available filesystem drives

- **Multiple optimization modes**
  - **Full Optimize**: profile-based cleanup + debloat + services + startup + disk + memory + gaming tweaks
  - **Cleanup**: interactive cleanup profile + category toggles + before/after reclaim summary
  - **Debloat**: removes selected preinstalled apps
  - **Gaming Mode**: low-latency + game-focused tweaks
  - **Workstation Mode**: stability/performance blend
  - **Custom**: choose what to run
  - **God Mode**: maximum cleanup/debloat flow with explicit destructive confirmation
  - **Restore**: imports saved registry backups

- **Cleanup profiles**
  - **Safe**: low-risk temp/cache cleanup
  - **Aggressive**: deeper cache/update/log cleanup
  - **God Mode profile**: optional deep actions (WinSxS cleanup, hibernation off, shadow copy cleanup, optional feature disable)

- **Disk awareness and reporting**
  - Scans top space consumers before cleanup
  - Reports per-category before/after usage and reclaimed space
  - Writes a cleanup report log to `/backup`

- **Backup-first behavior**
  - Exports `HKLM` and `HKCU` before major operations
  - Stored in `/backup` for quick recovery

- **Portable script architecture**
  - Main entrypoint: `DeGhost.bat`
  - Functional modules in `/modules/*.ps1`

---

## 🧩 Module Breakdown

| Module | Purpose |
|---|---|
| `detect.ps1` | Hardware and drive detection used by the main menu |
| `cleanup.ps1` | Profile-driven cleanup with category toggles, disk-usage scan, deep optional actions, and run reporting |
| `debloat.ps1` | Tier-aware built-in app removal (safe/aggressive/god package sets) |
| `services.ps1` | Stops/disables selected services and adjusts process priority behavior |
| `startup.ps1` | Reduces startup delay |
| `disk.ps1` | Enables TRIM behavior |
| `memory.ps1` | Enables `DisablePagingExecutive` memory tweak |
| `gaming.ps1` | Applies GameDVR/network throttling/power plan-related gaming tweaks |
| `restore.ps1` | Restores registry from backups (`backup/hklm.reg`, `backup/hkcu.reg`) |
| `ui.ps1` | Simple progress/typewriter-style output helpers |

---

## 📦 Repository Structure

```text
DeGhost/
├─ DeGhost.bat
├─ DeGhost.conf
├─ backup/
│  └─ .gitkeep
└─ modules/
   ├─ cleanup.ps1
   ├─ debloat.ps1
   ├─ detect.ps1
   ├─ disk.ps1
   ├─ gaming.ps1
   ├─ memory.ps1
   ├─ restore.ps1
   ├─ services.ps1
   ├─ startup.ps1
   └─ ui.ps1
```

---

## ⚡ Quick Start

1. Open **Command Prompt as Administrator**
2. Go to the repository directory
3. Run:

```bat
DeGhost.bat
```

4. Pick a mode from the menu

> Admin rights are required for service and registry operations.

---

## 🛡️ Safety Notes

- DeGhost touches system settings (services, registry, startup behavior, optional deep cleanup actions).
- Backups are created before major flows, but you should still:
  - close active work,
  - save a system restore point,
  - review scripts in `/modules` before use in production machines.
- God Mode requires an explicit `CONFIRM` prompt before destructive actions.

Use at your own discretion.

---

## 📉 Realistic Space Reclaim Expectations

Windows has a larger baseline footprint than minimal Linux installs due to bundled components, update servicing, and compatibility layers. DeGhost can reclaim meaningful space, but it will not usually reduce Windows down to Linux-like install size.

Typical one-run reclaim ranges (depends heavily on system age and usage):

- **Safe**: ~0.5 GB to 3 GB
- **Aggressive**: ~2 GB to 8 GB
- **God Mode** (with deep options): ~5 GB to 15+ GB

---

## 🔁 Restore

To restore registry backups through the menu:
- Launch `DeGhost.bat`
- Select **Restore**

Or run directly:

```powershell
powershell -ExecutionPolicy Bypass -File modules\restore.ps1
```

---

## 🎯 Who This Is For

- Users who want a **portable, script-based optimizer**
- Gamers seeking quick low-latency tweaks
- Power users who prefer readable scripts over opaque tools
- Anyone who wants a modular base to customize

---

## 🤝 Contributing

Improvements are welcome:
- safer defaults,
- smarter hardware/profile detection,
- better cleanup targets,
- additional restore safeguards,
- UX polish in menu/output.

---

## 🆓 License / Usage

This repository is declared by the author as **free for anything**.

You are free to use, modify, share, fork, and repurpose it for personal or commercial projects.
