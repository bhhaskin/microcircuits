-- Packing / unpacking regression tests (build.lua, editor.set_packed)
local commons = require("scripts.commons")
local build = require("scripts.build")
local editor = require("scripts.editor")
local H = require("tests.helpers")

local prefix = commons.prefix
local W = defines.wire_connector_id

---@param surface LuaSurface
---@param def table
---@return LuaEntity
local function place(surface, def)
    local e = surface.create_entity {
        name = def.name,
        position = def.position,
        direction = def.direction,
        force = H.force
    }
    assert(e, "failed to create " .. def.name)
    return e
end

---@param a number
---@param b number
local function near(a, b) return math.abs(a - b) < 0.01 end

describe("packing", function()
    after_each(function()
        H.cleanup()
    end)

    test("combinator wired to a non-packable chest packs without error (nil index compare in wiring loop)", function()
        local processor, procinfo, surface = H.create_unpacked_processor({ 200, 0 })
        -- chest first so it is blueprint entity #1 and appears as the lower wire end
        local chest = place(surface, { name = "wooden-chest", position = { -3.5, 0.5 } })
        local cc = place(surface, { name = "constant-combinator", position = { 0.5, 0.5 } })
        local ac = place(surface, { name = "arithmetic-combinator", position = { 3.5, 1 } })
        assert.is_true(chest.get_wire_connector(W.circuit_red, true)
            .connect_to(ac.get_wire_connector(W.combinator_output_red, true), false))
        assert.is_true(cc.get_wire_connector(W.circuit_green, true)
            .connect_to(ac.get_wire_connector(W.combinator_input_green, true), false))
        assert.is_true(chest.get_wire_connector(W.circuit_green, true)
            .connect_to(cc.get_wire_connector(W.circuit_green, true), false))

        editor.set_packed(procinfo, true)
        assert.is_true(procinfo.is_packed)
        assert.is_not_nil(procinfo.blueprint)

        local packed_ac = H.packed_entities(processor, prefix .. "-ac")
        local packed_cc = H.packed_entities(processor, prefix .. "-cc")
        assert.are_equal(1, #packed_ac)
        assert.are_equal(1, #packed_cc)
        -- the combinator-to-combinator wire survives
        local net = packed_ac[1].get_circuit_network(W.combinator_input_green)
        assert.is_not_nil(net)
        assert.are_equal(2, net.connected_circuit_count)

        -- direct call reports the chest as external
        local _, _, externals = build.create_packed_circuit(procinfo)
        assert.is_not_nil(externals)
        ---@cast externals -nil
        assert.is_true(#externals >= 1)
        for _, name in pairs(externals) do assert.are_equal("wooden-chest", name) end
    end)

    test("hand-made blueprint with a chest wired to a decider packs without error", function()
        local processor, procinfo = H.create_processor({ 200, 0 })
        ---@cast procinfo -nil
        procinfo.blueprint = H.make_blueprint {
            { entity_number = 1, name = "wooden-chest", position = { x = 0.5, y = 0.5 },
                wires = { { 1, W.circuit_red, 2, W.combinator_input_red } } },
            { entity_number = 2, name = "decider-combinator", position = { x = 2.5, y = 1 },
                wires = { { 2, W.combinator_input_red, 1, W.circuit_red } } },
        }
        procinfo.is_packed = true
        local _, _, externals = build.create_packed_circuit(procinfo)
        assert.are_same({ "wooden-chest" }, externals)
        assert.are_equal(1, #H.packed_entities(processor, prefix .. "-dc"))
    end)

    test("constant combinator section active=false and multiplier are preserved", function()
        local processor, procinfo, surface = H.create_unpacked_processor({ 200, 0 })
        local cc = place(surface, { name = "constant-combinator", position = { 0.5, 0.5 } })
        local cb = cc.get_or_create_control_behavior() --[[@as LuaConstantCombinatorControlBehavior]]
        local s1 = cb.sections_count > 0 and cb.get_section(1) or cb.add_section()
        ---@cast s1 -nil
        s1.set_slot(1, { value = { type = "virtual", name = "signal-A", quality = "normal" }, min = 10 })
        s1.active = false
        s1.multiplier = 3
        local s2 = cb.add_section()
        ---@cast s2 -nil
        s2.set_slot(1, { value = { type = "virtual", name = "signal-B", quality = "normal" }, min = 4 })
        s2.multiplier = 2

        editor.set_packed(procinfo, true)

        local packed = H.packed_entities(processor, prefix .. "-cc")
        assert.are_equal(1, #packed)
        local pcb = packed[1].get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior]]
        assert.are_equal(2, pcb.sections_count)
        local p1, p2 = pcb.get_section(1), pcb.get_section(2)
        ---@cast p1 -nil
        ---@cast p2 -nil
        assert.are_equal("signal-A", p1.filters[1].value.name)
        assert.are_equal(10, p1.filters[1].min)
        assert.is_false(p1.active)
        assert.are_equal(3, p1.multiplier)
        assert.are_equal("signal-B", p2.filters[1].value.name)
        assert.is_true(p2.active)
        assert.are_equal(2, p2.multiplier)
    end)

    test("decider combinator else_outputs are preserved", function()
        local processor, procinfo, surface = H.create_unpacked_processor({ 200, 0 })
        local dc = place(surface, { name = "decider-combinator", position = { 0.5, 1 } })
        local cb = dc.get_or_create_control_behavior() --[[@as LuaDeciderCombinatorControlBehavior]]
        cb.parameters = {
            conditions = { { first_signal = H.vsignal("signal-A"), comparator = ">", constant = 0 } },
            outputs = { { signal = H.vsignal("signal-B"), copy_count_from_input = false, constant = 5 } },
            else_outputs = { { signal = H.vsignal("signal-C"), copy_count_from_input = false, constant = 7 } },
        }

        editor.set_packed(procinfo, true)

        local packed = H.packed_entities(processor, prefix .. "-dc")
        assert.are_equal(1, #packed)
        local params = (packed[1].get_control_behavior() --[[@as LuaDeciderCombinatorControlBehavior]]).parameters
        assert.are_equal("signal-B", params.outputs[1].signal.name)
        assert.are_equal(5, params.outputs[1].constant)
        assert.is_not_nil(params.else_outputs)
        assert.are_equal(1, #params.else_outputs)
        assert.are_equal("signal-C", params.else_outputs[1].signal.name)
        assert.are_equal(7, params.else_outputs[1].constant)
        assert.is_false(params.else_outputs[1].copy_count_from_input)
    end)

    test("small lamp color and always_on are preserved", function()
        local processor, procinfo, surface = H.create_unpacked_processor({ 200, 0 })
        local lamp = place(surface, { name = "small-lamp", position = { 0.5, 0.5 } })
        lamp.color = { r = 1, g = 0, b = 0, a = 1 }
        lamp.always_on = true
        assert.is_true(lamp.always_on)

        editor.set_packed(procinfo, true)

        local lamp_names = {}
        for i = 1, 8 do table.insert(lamp_names, prefix .. "-lamp" .. i) end
        local packed = H.packed_entities(processor, lamp_names)
        assert.are_equal(1, #packed)
        local color = packed[1].color
        assert.is_not_nil(color)
        ---@cast color -nil
        assert.is_true(near(color.r, 1) and near(color.g, 0) and near(color.b, 0))
        assert.is_true(packed[1].always_on)
    end)

    -- Without ext_name tags (old or hand-made blueprints) a small lamp is packed as a
    -- constant combinator, so the lamp-only properties must not be applied to it.
    test("small lamp without ext_name tags (hand-made blueprint) packs without error", function()
        local processor, procinfo = H.create_processor({ 200, 0 })
        ---@cast procinfo -nil
        procinfo.blueprint = H.make_blueprint {
            { entity_number = 1, name = "small-lamp", position = { x = 0.5, y = 0.5 },
                color = { r = 0, g = 1, b = 0, a = 1 }, always_on = true },
        }
        procinfo.is_packed = true
        build.create_packed_circuit(procinfo)
        assert.are_equal(1, #H.packed_entities(processor))
    end)
end)

describe("unpack(pack(x))", function()
    after_each(function()
        H.cleanup()
    end)

    -- Restore computes the bounding box of the blueprint entities to know where to
    -- build it. Packable entities are all small, so build_blueprint's grid snapping
    -- hides small errors in that math; the old formula (half extents halved again,
    -- first entity's max corner = its centre, north treated as rotated) only produced
    -- a visibly shifted layout with large external entities (verified: the last two
    -- cases fail with the pre-fix formula, the first one passes with both).
    test.each({
        { "rotated 1x2 arithmetic left, lone 1x1 pole far right", {
            { name = "arithmetic-combinator", position = { -12, 3.5 }, direction = defines.direction.east },
            { name = "small-electric-pole",   position = { 13.5, -6.5 } },
            { name = "constant-combinator",   position = { -10.5, -2.5 } },
        } },
        { "north decider top-left, large external steam engine bottom-right", {
            { name = "decider-combinator", position = { -7.5, -5 } },
            { name = "steam-engine",       position = { 7.5, 7.5 } },
        } },
        { "1x1 pole top-left, large external oil refinery bottom-right", {
            { name = "small-electric-pole", position = { -7.5, -5.5 } },
            { name = "oil-refinery",        position = { 8.5, 7.5 } },
        } },
    })("keeps positions and directions: %s (restore bounding-box math)", function(_, layout)
        local _, procinfo, surface = H.create_unpacked_processor({ 200, 0 })
        for _, def in pairs(layout) do place(surface, def) end

        ---@param s LuaSurface
        local function snapshot(s)
            local result = {}
            for _, def in pairs(layout) do
                local found = s.find_entities_filtered { name = def.name }
                assert.are_equal(1, #found, "count of " .. def.name)
                result[def.name] = { x = found[1].position.x, y = found[1].position.y, direction = found[1].direction }
            end
            return result
        end
        local before = snapshot(surface)
        for _, def in pairs(layout) do
            assert.are_same({ x = def.position[1], y = def.position[2], direction = def.direction or defines.direction.north },
                before[def.name])
        end

        editor.set_packed(procinfo, true)

        -- unpack the way editor.edit_selected does (minus the player teleport)
        local surface2 = editor.get_or_create_surface(procinfo)
        assert.are_equal(surface, surface2)
        editor.clean_surface(procinfo)
        assert.are_equal(0, surface.count_entities_filtered { name = "arithmetic-combinator" })
        build.restore_packed_circuits(procinfo)

        local after = snapshot(surface)
        assert.are_same(before, after)
    end)

    test("set_packed(false) after packing removes the hidden entities", function()
        local processor, procinfo, surface = H.create_unpacked_processor({ 200, 0 })
        place(surface, { name = "arithmetic-combinator", position = { 0.5, 1 } })
        editor.set_packed(procinfo, true)
        assert.are_equal(1, #H.packed_entities(processor, prefix .. "-ac"))
        editor.set_packed(procinfo, false)
        assert.are_equal(0, #H.packed_entities(processor))
        assert.is_false(procinfo.is_packed)
    end)
end)

describe("editor surfaces", function()
    after_each(function()
        H.cleanup()
    end)

    test("evacuate_surface is a safe no-op on an empty surface and on nil", function()
        local _, procinfo, surface = H.create_unpacked_processor({ 200, 0 })
        editor.evacuate_surface(surface)
        editor.evacuate_surface(nil)
        assert.is_true(surface.valid)
        assert.are_equal(procinfo, storage.surface_map[surface.name])
    end)

    test("delete_surface removes the surface and clears procinfo/surface_map", function()
        local processor, procinfo, surface = H.create_unpacked_processor({ 200, 0 })
        local name = surface.name
        editor.delete_surface(procinfo)
        assert.is_nil(procinfo.surface)
        assert.is_nil(storage.surface_map[name])
        -- calling again is harmless
        editor.delete_surface(procinfo)
        after_ticks(1, function()
            assert.is_nil(game.get_surface(name))
            -- processor still alive and usable
            assert.is_true(processor.valid)
            assert.are_equal(procinfo, storage.procinfos[processor.unit_number])
        end)
    end)

    test("get_or_create_surface recreates a surface after delete_surface", function()
        local _, procinfo, surface = H.create_unpacked_processor({ 200, 0 })
        local name = surface.name
        editor.delete_surface(procinfo)
        after_ticks(1, function()
            local s = editor.get_or_create_surface(procinfo)
            assert.is_true(s.valid)
            assert.are_equal(name, s.name)
            assert.are_equal(procinfo, storage.surface_map[name])
        end)
    end)
end)
