# Microcircuits

Build a circuit network once, then shrink it into a single processor. Microcircuits works like Factorissimo, but for signals: each processor holds its own small world where you wire up combinators, and the outside sees just one compact entity.

## How it works

1. Research **Compact circuits** and craft a **Compact processor** (2x2) or a **Mini compact processor** (1x1).
2. Place it and **click** it to step inside its editor.
3. Build your circuit with ordinary combinators. The **Input/Output poles** inside connect to the points on the processor's edge, so wires outside reach the circuit inside.
4. Step out. The processor now behaves like the network you built.
5. Turn on **Packed mode** when the circuit is finished. The editor area is removed and the circuit runs on hidden combinators under the processor, with almost no overhead.

## Features

- **Two sizes:** a 2x2 processor and a 1x1 mini processor.
- **Packed mode:** finished circuits run without their editor area.
- **Nesting:** processors can contain other processors.
- **Models:** save a processor's circuit as a model and update every processor that uses it in one go.
- **Display components:** show numbers, text, signals or sprites on the processor itself.
- **Input components:** add your own settings to a processor and change them with **Ctrl + click**, without going inside.
- **Long range channels:** optional wireless combinators that share signals across the map.
- **Blueprints, copy/paste and undo:** processors carry their circuits with them.

Packed circuits can contain constant, decider, arithmetic and selector combinators, display panels, small lamps, electric poles, and other processors.

## Requirements

- Factorio 2.1
- [flib](https://mods.factorio.com/mod/flib)

## Coming from Compakt circuits?

Microcircuits is a fork of [Compakt circuits](https://mods.factorio.com/mod/compaktcircuit) by Telkine2018, renamed and with a long list of bug fixes. See the changelog for details.

It is **not save-compatible** with Compakt circuits. All internal names have changed, so processors from Compakt circuits will not carry over into Microcircuits. Both mods can be installed side by side.

## Commands

- `/microcircuits_pack`: pack every processor nobody is editing
- `/microcircuits_purge`: clean up orphaned editor areas
- `/microcircuits_stats`: count processors

## Credits

- **Telkine2018:** the original Compakt circuits
- **hgschmie and Gohla:** the Factorio 2.1 port of Compakt circuits

Released under the MIT license.
