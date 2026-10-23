# Microcircuits

A Factorio 2.1 mod that packs an entire circuit network into a single compact processor. Think Factorissimo, but for signals.

Microcircuits is a fork of [Compakt circuits](https://github.com/Telkine2018/compaktcircuit) by Telkine2018, with a new name and a round of bug fixes. It is not save-compatible with Compakt circuits.

## Features

- **Two processors:** a 2x2 Compact processor and a 1x1 Mini compact processor.
- **Edit in place:** click a processor to enter its own editor surface and build the circuit inside it with ordinary combinators, then leave to return to where you were.
- **Input/output points:** the processor's edge points connect the circuit inside to wires outside.
- **Packed mode:** once a circuit is finished, pack it. The editor surface is removed and the circuit runs on hidden combinators under the processor, so it costs almost nothing.
- **Models:** save a processor's circuit to a model library, then apply it to every processor of the same model at once.
- **Components:** display components show numbers, text or sprites on the processor. Input components add your own fields to the processor's settings dialog (Ctrl+click).
- **Long range channels:** optional wireless combinators that share signals across the map.
- **Blueprints:** processors keep their circuits in blueprints, copy/paste, and undo/redo.

## Requirements

- Factorio 2.1
- [flib](https://mods.factorio.com/mod/flib) 0.17 or newer

## Controls

| Action | Default |
|---|---|
| Enter a processor's editor | Click the processor |
| Open the processor's settings | Ctrl + click the processor |

## Commands

| Command | What it does |
|---|---|
| `/microcircuits_pack` | Pack every processor that nobody is editing |
| `/microcircuits_purge` | Remove orphaned editor surfaces and data |
| `/microcircuits_stats` | Show processor counts |
| `/microcircuits_regenerate_packed` | Rebuild all packed circuits |
| `/microcircuits_repair_iopoints` | Repair input/output points |

## For mod authors

Other mods can register their own combinators to be allowed inside processors through the `microcircuits` remote interface:

```lua
remote.call("microcircuits", "add_combinator", driver)
remote.call("microcircuits", "remove_combinator", name)
```

## Development

The tests and the release build need Docker, Node.js, `make`, `zip` and `jq`.

```sh
npm install      # test runner
make test        # unit tests (busted) and in-game tests (headless Factorio)
make build       # build/microcircuits_<version>.zip
make clean
```

- **Unit tests** live in `spec/` and run with [busted](https://lunarmodules.github.io/busted/) in Docker.
- **In-game tests** live in `tests/` and run with [FactorioTest](https://github.com/GlassBricks/FactorioTest) in headless Factorio 2.1 in Docker (see `dev/`). The first run downloads flib and factorio-test from the mod portal using the login in `~/.factorio/player-data.json`, or `FACTORIO_USERNAME` and `FACTORIO_TOKEN`.
- **Release zip:** `make build` packages only the mod's own files and strips the test hook from `control.lua`.

## Credits

- Telkine2018, for the original Compakt circuits.
- hgschmie and Gohla, for the Factorio 2.1 port of Compakt circuits.

## License

MIT. See [LICENSE](LICENSE).
