# TrashTrek desktop builds

TrashTrek is currently packaged as a local/demo build. The locked build
target is Godot 4.7.1, Windows x86_64, and universal macOS, version `0.1.0`.
The game is offline-first: gameplay, profile data, and shop data are stored in
the Godot `user://` directory. Leaderboards show an offline status when no
server is configured.

The scenes are authored on a 1152×648 canvas and displayed in the 1280×720
demo window through canvas-item stretching. Keep both values when checking
layout; changing the authoring viewport leaves an unfilled strip around the
artwork.

## Prerequisites

- Godot 4.7.1 with the Windows Desktop and macOS export templates installed.
- macOS is required to produce the macOS DMG.
- Windows builds require the Windows export template and can be produced from
  macOS or Windows.

The scripts accept `GODOT_BIN` when Godot is not discoverable on `PATH`.

## Verify and build

From the repository root:

```bash
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot \
  tools/build_game.sh 0.1.0
```

On Windows PowerShell:

```powershell
$env:GODOT_BIN = 'C:\Path\To\Godot.exe'
tools\build_game.ps1 0.1.0
```

The build script resolves the repository root, runs the project verifier, and
exports the Windows preset. On macOS it also exports the universal macOS
preset. A version directory is never overwritten; choose a new version if
`builds/<version>/` already exists.

The output layout is:

```text
builds/
  0.1.0/
    windows-x86_64/
      TrashTrek.exe
    macos-universal/
      TrashTrek.dmg
```

The existing root-level `builds/TrashTrek.dmg` is a user-owned artifact and is
not replaced by this workflow.

For the individual static gates:

```bash
git diff --check
"$GODOT_BIN" --headless --path . --editor --quit
"$GODOT_BIN" --headless --path . --script res://tools/verify_build.gd
```

The verifier prints `VERIFY OK` only after the main scene, intro, menu,
gameplay scene, active terrain scenes, shop, profile, leaderboard, runtime
resources, and project scripts load successfully. `RiverTerrain.tscn` and the
unreferenced root `tile_map.tres` are intentionally excluded because they are
legacy atlas data, unused by `terrain_manager.gd`, and contain incompatible
coordinates. `RiverTerrain.tscn` is excluded from both desktop export presets
as well.

## Optional editor-only online mode

Create a local `.env` file in the repository root with a `SERVER_URL` value for
editor testing. `.env` is ignored by Git and is excluded from exported builds;
never commit or package its contents. Without it, the API stays disabled and
the game continues in local/demo mode.

## Artifact checks

On Windows, confirm the executable is PE32+ x86-64. On macOS, inspect the
unpacked app and DMG:

```bash
lipo -archs "TrashTrek.app/Contents/MacOS/TrashTrek"
codesign --verify --deep --strict "TrashTrek.app"
hdiutil imageinfo builds/0.1.0/macos-universal/TrashTrek.dmg
```

The macOS preset uses built-in ad-hoc signing and disables notarization for
local/demo distribution. Gatekeeper may warn when opening the unsigned demo.

## Hardware QA

Before sharing a build, test Windows x64, Intel macOS, and Apple Silicon macOS
for launch/quit, offline name entry, gameplay, pause/restart/game over, all
keyboard controls, resize/scaling, local shop/profile persistence, and the
leaderboard offline status. Supply a local `.env` separately when testing the
editor-only online flows.
