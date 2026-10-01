# Mission Control

A controller-only operations room for the [VibeBoy](https://github.com/Strizzo/VibeBoy) service on a 720×720 CartridgeOS handheld. A vermilion, ink and warm-paper graphic system surrounds real pane status, agent replies and terminal output. The app includes its own original geometric station icon.

Mission Control is an evolution of the VibeBoy cartridge: async state polling and command acknowledgements, stable pane selection, project/session grouping, a full output reader and complete saved-server setup.

## Connect a real server

On the computer hosting your tmux sessions, use the current VibeBoy checkout (the one containing `vibeboy/http_api.py`):

```sh
python3 -m venv .venv
.venv/bin/pip install -e .
.venv/bin/vibeboy --host 0.0.0.0 --http-port 8766
```

VibeBoy requires tmux and discovers its panes automatically. Start your agent or build inside tmux on that computer. The default daemon bind address is localhost; the explicit host option above makes it reachable from the handheld. Restrict this unauthenticated service to a trusted private network or VPN. For a daemon kept on localhost, establish a tunnel outside the app and enter its forwarded address; the app never starts blocking SSH work.

1. Open Mission Control and press **A** or **Y** to add a station.
2. Select **Name**, press **A**, and enter a friendly name using the controller keyboard.
3. Select **Address**, press **A**, and enter `computer.local:8766` or `192.168.1.10:8766`.
4. Select **Save**, press **A**, then press **A** on that station to connect.

Addresses accept HTTP/HTTPS, DNS names, IPv4, bare IPv6 (default port) and bracketed IPv6, with ports 1–65535. The default scheme is HTTP and the default port is 8766, including when no explicit port is supplied for HTTPS. No path, credentials or query string is accepted. The last connected station reconnects on launch. Up to eight stations and the polling interval are saved.

## Controls

**Select is reserved for the runtime.** Normal app screens never handle it; it exits to CartridgeOS. While the shared keyboard is visible, follow its on-screen hints (the runtime owns keyboard cancellation).

| Screen | Controls |
|---|---|
| Operations board | Up/Down: pane; Left/Right: All / Agents / Processes / Needs input; L1/R1: project group; A: inspect; X: refresh/reconnect; Start: servers; B: servers |
| Inspector | Up/Down: output history; L1/R1: adjacent pane; Left/Right or L2/R2: command; A: review command or compose; Y: full output; X: refresh; B: board; Start: servers |
| Full terminal | Up/Down: scroll 3 lines; Left/Right: pan 12 columns; A: latest; Y/B: inspector; X: refresh; Start: servers |
| Command review | Left: cancel (default); Right: send; A: confirm choice; B: cancel; Up/Down: page through long command text |
| Server stations | Up/Down: station; A: connect; X: edit; Y: add; L2: remove with confirmation; R2: disconnect; Start: cycle polling 1/2/5/10 seconds; B: board |
| Station editor | Up/Down: name/address/save; A: keyboard or save; B: discard changes |

Every command is reviewed with its target and exact payload. This includes suggestions, detected prompt choices, typed responses, Tab/accept ghost text (Claude panes), Escape, Ctrl+C and Ctrl+Z. Sending a typed response also sends Enter, as defined by VibeBoy. The Cartridge 0.6.0 keyboard supports 48-character server names, 240-character addresses, and 1024-character custom responses. X cycles letters, capitals, and symbols including quotes/brackets; Select cancels editing. Bare IPv6 such as `::1` uses port 8766; bracketed addresses can specify a custom port. Server-provided suggestions can be longer and retain their exact content. Suggestions and detected choices come from the service; the app does not generate them. Repeated A events cannot duplicate a command.

## What the data means

- **Projects** are groups of the API's `session_name` (tmux session names). The service omits working-directory/project-path metadata.
- **Agents** are panes explicitly reported as `claude_code`. **Processes** are the remaining pane types, including shells and builds. Build progress/result is visible only when the terminal itself reports it; there is no CI/build-result API.
- **In progress** counts `thinking` and `running`; **needs input** counts `waiting`. Status is supplied by the server, not inferred from text.
- Output is a recent screen snapshot, not an append-only terminal transcript. The app retains at most 128 panes, 240 lines per pane, 512 Unicode characters per line, and 24 suggestions plus 24 choices per pane. Long terminal lines can be panned; trailing blank tmux rows are hidden. There is no unbounded history/cache or stored terminal output.
- **LIVE** means a recent valid response; **STALE/OFFLINE** disables commands but keeps the last snapshot for reading. Failed polls retry after 2/4/8/16/30 seconds. X requests an immediate retry. Requests never overlap other state polls, including while changing stations.
- Only an exact acknowledgement matching action and session produces “Server acknowledged…”. VibeBoy currently acknowledges even when its executor returns false, and some actions can acknowledge with no executor. An acknowledgement is **not proof of execution**. Inspect the refreshed terminal. Transport failures report delivery as unknown; POST is never automatically retried.
- Disconnect stops scheduling requests and clears pane data. In-flight requests cannot be cancelled by the runtime; old responses are drained and ignored. A command already submitted can still reach its old server.

## Protocol and persistence

See [the protocol and testing guide](docs/mission-control.md). This app uses only async `GET /api/state` and `POST /api/action`. It requires `network` and `storage`, with no SSH permission. The service has no authentication, project/build management, log-stream endpoint, pagination, or terminal resize API.

## Runtime integration checks

Run the commands in this section from a separate **Cartridge checkout**, with
its bundled Mission Control app synchronized to this release. These Rust and
SDL tests belong to Cartridge and are not part of this repository's CI.

```sh
cargo test -p cartridge-lua --test mission_control
python3 lua_cartridges/mission_control/tests/render.py
```

The capture helper uses the shared `app-check` runner and `sim/fixtures/mission-control.json`; it checks 720×720 PNGs in `/tmp/mission-control-captures`. It includes board, inspector, output, command review, acknowledged command, settings/editor/keyboard, first launch, disconnect, offline, empty and loading states. SDL needs a desktop display on macOS (or SDL dummy video on Linux).

Exercise the actual VibeBoy Python HTTP handlers and dispatcher, with recording executor and no live tmux changes:

```sh
VIBEBOY_SOURCE=/path/to/VibeBoy \
VIBEBOY_PYTHON=/path/to/VibeBoy/.venv/bin/python \
CARTRIDGE_HOME=/tmp/mission-control-service-home \
cargo test -p cartridge-lua --test mission_control current_vibeboy_http_service_integration -- --ignored --nocapture --test-threads=1
```

The opt-in service test imports the existing checkout read-only and disables Python bytecode writes. Its real model serialization must match the fixture. Real tmux delivery, RK3326 frame times, physical controls and LAN reliability still require a device/Linux test.

## Install and run

Requires **Cartridge 0.6.0 or newer**. App ID: `dev.cartridge.mission-control`.
The release requires these runtime permissions: `network`, `storage`.

Download [`dev.cartridge.mission-control.tar.gz`](https://github.com/Strizzo/mission-control-cartridge/releases/latest)
and `SHA256SUMS` from the same release. The archive contains `cartridge.json`,
`main.lua`, Lua modules, artwork, and `LICENSE` directly at its root. Verify its
SHA-256 against `SHA256SUMS` (or the Store catalog) before installing through
Cartridge's Store. `release.json` supplies the versioned URL, byte size, hash,
minimum runtime, and permissions for catalog integration.

To run a development checkout with the Cartridge simulator:

```sh
cd /path/to/Cartridge
./sim.sh app /path/to/mission-control-cartridge
```

## Development and releases

Python 3.12+ and Lua 5.4 are sufficient for the independent checks:

```sh
python3 tools/package.py --check
find . -type f -name '*.lua' -not -path './.git/*' -print0 | xargs -0 -n 1 luac -p
lua tests/unit.lua
python3 -m unittest discover -s tests -p 'test_*.py' -v
python3 tools/package.py --tag v1.0.0
```

On Linux, Lua executables may be named `lua5.4` and `luac5.4`.
The Python packager has no third-party dependencies. `package-files.json` is the
reviewable runtime payload inventory; it must include every root Lua module and
all files in `assets/`. Development tools, tests, docs, and this README stay out
of release archives. See [release maintenance](docs/releasing.md).

CI runs syntax checks, focused pure-Lua behavior tests, manifest validation,
and archive integrity/reproducibility tests. Shared runtime, native audio/HTTP,
SDL rendering, and device integration tests remain in
[Cartridge](https://github.com/Strizzo/Cartridge/blob/d17e6f9074eb238d9e604e36e386d79d11f62985/crates/cartridge-lua/tests/mission_control.rs);
see [the integration guide](docs/mission-control.md) for their commands and limits.

## License and origin

GPL-3.0; see [LICENSE](LICENSE), copied verbatim from Cartridge.
Extracted from [Cartridge `d17e6f9074eb`](https://github.com/Strizzo/Cartridge/blob/d17e6f9074eb238d9e604e36e386d79d11f62985/lua_cartridges/mission_control).
Existing author credits and app-specific data/artwork attribution are retained.
