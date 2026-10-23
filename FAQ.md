# Frequently asked questions

### What is the difference between packed and unpacked?

An unpacked processor keeps its editor area. You can step back inside at any time and watch the signals while the circuit runs, which makes it the mode for building and debugging.

A packed processor deletes its editor area when you leave and runs the circuit on hidden combinators under the processor. It costs almost nothing to run, and it is the mode for finished circuits. You can still step inside a packed processor to change it; the circuit is rebuilt from its saved copy while you work and packed again when you leave.

Switch between the two with the **Packed mode** checkbox in the editor panel.

### I mined a processor and its circuit is gone. Can I get it back?

Press **Ctrl + Z** straight away: undo restores the processor with its circuit.

By default, a mined processor goes back into your inventory as a plain item, which keeps your inventory free of hundreds of unique items. To keep the circuit in the item instead, turn on the map setting **Mine processor as tag entity**.

Blueprints, copy/paste and cut/paste always keep the circuit.

### I can't see the input/output points on the processor.

They only show in alt mode by default. Press **Alt**, or turn off the startup setting **Show input/output point only with alt**.

### Do processors need power?

Packed circuits don't, by default. The startup setting **Packed circuits don't need energy** controls this.

### Can I put chests, inserters or other machines inside a processor?

Only with the map setting **Allow externals combinator** turned on, and only in unpacked mode. Packed circuits can contain constant, decider, arithmetic and selector combinators, display panels, small lamps, electric poles and other processors. If you pack a processor that has other entities in it, you get a warning.

### How do I update every copy of the same circuit?

Use **models**. Save a processor's circuit as a model, place more processors with that model, and when you change one, apply the model to update all of them at once.

### How can I change a setting of a circuit without going inside?

Add **input components** inside the processor. They become fields in the processor's settings dialog, which opens with **Ctrl + click** on the processor.

### Displays are slow to update, or cost too much UPS.

Two map settings control how displays refresh: **Maximum of entity processed per tick** and **Response time**. Raise the first or lower the second for faster displays; do the opposite to save UPS. To switch displays off entirely, use **Disable display**.

### Can several players edit the same processor?

Yes. Each player returns to the spot where they entered.

### Does it work with Space Age?

Yes. The mod loads with Space Age, and processors can be built and deconstructed on space platforms.

### Can I bring my builds over from Compakt circuits?

No. Microcircuits uses different internal names, so saves and blueprints from Compakt circuits don't carry over. You can install both mods at the same time and rebuild your circuits in Microcircuits.

[Compakt circuits](https://mods.factorio.com/mod/compaktcircuit) is still available. If you have a save full of Compakt circuits processors, staying with it is the simplest choice.

### Can other mods add their own combinators?

Yes, through the `microcircuits` remote interface:

```lua
remote.call("microcircuits", "add_combinator", driver)
```

Mods written for Compakt circuits call the `compaktcircuit` interface, which Microcircuits doesn't provide, so they need to add support for the new name. Until they do, if you rely on one of those mods, use [Compakt circuits](https://mods.factorio.com/mod/compaktcircuit) instead; it is still available.
