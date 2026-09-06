# ForceQ

**See what’s using your Mac’s memory. Close what you no longer need.**

ForceQ is a lightweight macOS utility built with SwiftUI. It displays running applications with their icons, monitors memory usage, and lets you force quit a selected app after confirmation.

## Why ForceQ?

When editing films, running local AI models, or working with many apps open, we wanted a quick way to see where memory was going.

The project started as a small Automator script. It became a standalone SwiftUI app when we wanted application icons, a persistent window, and live memory monitoring.

The goal remains simple: **see your apps, compare memory usage, and stay in control.**

## Features

- **Application icons:** Identify running apps at a glance.
- **Live memory monitoring:** Memory readings refresh approximately every three seconds.
- **Memory-first sorting:** The highest memory consumers appear first by default.
- **Optional alphabetical sorting:** Switch to sorting by app name.
- **Helper process support:** Include measurable helper processes within an app’s bundle, or view only its main process.
- **Quick search:** Filter the list to find an application.
- **Confirmed force quit:** Every force quit action requires confirmation.
- **Persistent window:** Continue working after closing an application.

Finder and ForceQ are excluded from the list of applications you can close.

## Installation

1. Download `ForceQ.zip` from this repository’s **Releases** section.
2. Extract the ZIP file.
3. Move `ForceQ.app` to your **Applications** folder.
4. Open the app and add it to your Dock for quick access.

**Requirements:** An Apple Silicon Mac running macOS 13 or later.

> The prebuilt app is locally signed but is not notarized by Apple. macOS may display a security warning when opening it on another Mac.

## Usage

1. Select an application from the list.
2. Click **Zorla Kapat** (“Force Quit”).
3. Confirm the action or cancel.

The list refreshes automatically. You can also refresh it manually using the button in the upper-right corner.

**The current interface is in Turkish.** This English README does not change the application’s interface language.

> Force quitting may cause unsaved changes to be lost. High memory usage alone does not mean an application needs to be closed.

## How memory is measured

ForceQ reads the **physical memory footprint** reported by macOS through `proc_pid_rusage`.

When **Yardımcı süreçler dahil** (“Include helper processes”) is enabled, ForceQ adds up measurable processes whose executables are located inside the application’s bundle. Shared system services and processes outside that bundle are not included.

These readings may therefore differ from an individual process row in Activity Monitor or from system-wide memory totals.

- `—`: The memory reading is unavailable.
- `≥`: Some processes could not be measured; the displayed value is a partial total.
- MB and GB use decimal units.

## Privacy

The current ForceQ code contains no data collection, telemetry, or network requests. Application information and memory readings are processed on your Mac.

ForceQ does not require Stats or another monitoring app. Normal operation does not require an administrator password.

## Build from source

On an Apple Silicon Mac with Xcode installed, run the following from the project directory:

```bash
./build.command
```

The compiled `ForceQ.app` is created in the parent directory. The build script applies a local ad-hoc signature; an Apple Developer membership is not required.

To run the tests:

```bash
./test.command
```

Tests cover process attribution, helper process grouping, unavailable readings, and memory measurements following an actual allocation.

## Project structure

| File | Purpose |
|---|---|
| `ForceQ.swift` | SwiftUI interface, application list, and force quit actions |
| `MemoryMonitor.swift` | Memory sampling and helper process attribution |
| `ForceQ.icns` | Application icon |
| `Info.plist` | Application metadata |
| `build.command` | Build and local signing |
| `test.command` | Run memory monitoring tests |
| `Tests/` | Test source files |

## Project direction

ForceQ’s priority is to remain simple and responsive. Potential improvements include normal quitting, user-selected protected applications, and saved preferences.

ForceQ does not automatically close applications or perform “RAM cleaning.” The decision stays with you.
