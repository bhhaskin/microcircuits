-- Processor build / destroy / clone regression tests
local commons = require("scripts.commons")
local build = require("scripts.build")
local editor = require("scripts.editor")
local tools = require("scripts.tools")
local H = require("tests.helpers")

local device_name = commons.device_name
local iopoint_name = commons.iopoint_name

---@param processor LuaEntity
---@param name string
local function count_under(processor, name)
    local pos = processor.position
    local proto = processor.prototype
    local rx = proto.tile_width / 2 - 0.01
    local ry = proto.tile_height / 2 - 0.01
    return processor.surface.count_entities_filtered {
        area = { { pos.x - rx, pos.y - ry }, { pos.x + rx, pos.y + ry } },
        name = name
    }
end

local simple_bp_entities = {
    { entity_number = 1, name = "constant-combinator", position = { x = 0.5, y = 0.5 } },
    { entity_number = 2, name = "arithmetic-combinator", position = { x = 2.5, y = 1 },
        wires = { { 2, defines.wire_connector_id.combinator_input_red, 1, defines.wire_connector_id.circuit_red } } },
}
simple_bp_entities[1].wires = { { 1, defines.wire_connector_id.circuit_red, 2, defines.wire_connector_id.combinator_input_red } }

describe("processor lifecycle", function()
    after_each(function()
        H.cleanup()
    end)

    test.each({
        { commons.processor_name },
        { commons.processor_name_1x1 },
    })("placing %s with raise_built creates procinfo, device and iopoints", function(name)
        local processor, procinfo = H.create_processor({ 100, 0 }, { name = name })
        assert.is_not_nil(procinfo)
        ---@cast procinfo -nil
        assert.are_equal(processor, procinfo.processor)
        assert.are_equal(processor.unit_number, procinfo.unit_number)
        assert.is_true(#procinfo.iopoints > 0)
        for _, point in pairs(procinfo.iopoints) do
            assert.is_true(point.valid)
            assert.are_equal(iopoint_name, point.name)
            assert.is_false(point.destructible)
        end
        assert.are_equal(1, count_under(processor, device_name))
        assert.is_false(processor.rotatable)
    end)

    test("script.raise_script_built on an existing processor creates its procinfo", function()
        local processor, procinfo = H.create_processor({ 100, 0 }, { raise = false })
        assert.is_nil(procinfo)
        script.raise_script_built { entity = processor }
        procinfo = storage.procinfos[processor.unit_number]
        assert.is_not_nil(procinfo)
        assert.is_true(#procinfo.iopoints > 0)
    end)

    test("raise_destroy removes procinfo, iopoints and device", function()
        local processor, procinfo = H.create_processor({ 100, 0 })
        ---@cast procinfo -nil
        local unit_number = processor.unit_number
        local iopoints = procinfo.iopoints
        local pos = processor.position
        processor.destroy { raise_destroy = true }
        assert.is_nil(storage.procinfos[unit_number])
        for _, point in pairs(iopoints) do
            assert.is_false(point.valid)
        end
        assert.are_equal(0, H.surface().count_entities_filtered {
            position = pos, radius = 1.5, name = { device_name, iopoint_name }
        })
    end)

    test("raise_destroy of an unpacked processor deletes its editor surface and surface_map entry", function()
        local processor, procinfo, surface = H.create_unpacked_processor({ 100, 0 })
        local surface_name = surface.name
        assert.are_equal(procinfo, storage.surface_map[surface_name])
        processor.destroy { raise_destroy = true }
        assert.is_nil(storage.surface_map[surface_name])
        after_ticks(1, function()
            assert.is_nil(game.get_surface(surface_name))
        end)
    end)

    test("entity death records died_list and cleans up", function()
        local processor, procinfo = H.create_processor({ 100, 0 })
        ---@cast procinfo -nil
        procinfo.blueprint = H.make_blueprint(simple_bp_entities)
        local unit_number = processor.unit_number
        local before = storage.died_list and #storage.died_list or 0
        processor.die()
        assert.is_nil(storage.procinfos[unit_number])
        assert.are_equal(before + 1, #storage.died_list)
        local died = storage.died_list[#storage.died_list]
        assert.are_equal(procinfo.blueprint, died.tags.blueprint)
        table.remove(storage.died_list)
        -- remove ghost if any
        for _, g in pairs(H.surface().find_entities_filtered { position = { 100, 0 }, radius = 2, name = "entity-ghost" }) do
            g.destroy()
        end
    end)

    test("built with blueprint tags is packed and gets hidden combinators", function()
        local processor = H.create_processor({ 100, 0 }, { raise = false })
        local bp = H.make_blueprint(simple_bp_entities)
        script.raise_event(defines.events.script_raised_built, { entity = processor, tags = { blueprint = bp } })
        local procinfo = storage.procinfos[processor.unit_number]
        assert.is_not_nil(procinfo)
        assert.is_true(procinfo.is_packed)
        assert.are_equal(bp, procinfo.blueprint)
        assert.are_equal(1, #H.packed_entities(processor, commons.prefix .. "-ac"))
        assert.are_equal(1, #H.packed_entities(processor, commons.prefix .. "-cc"))
        -- the blueprint wire is reproduced between the hidden combinators
        local ac = H.packed_entities(processor, commons.prefix .. "-ac")[1]
        local network = ac.get_circuit_network(defines.wire_connector_id.combinator_input_red)
        assert.is_not_nil(network)
        assert.are_equal(2, network.connected_circuit_count)
        -- destroying it removes the hidden entities too
        processor.destroy { raise_destroy = true }
        assert.is_false(ac.valid)
    end)
end)

describe("processor cloning (on_entity_cloned)", function()
    after_each(function()
        H.cleanup()
    end)

    test("clone of an unpacked processor without surface copies blueprint and circuits", function()
        local processor, src = H.create_processor({ 100, 0 })
        ---@cast src -nil
        local bp = H.make_blueprint(simple_bp_entities)
        local circuits = { { name = "constant-combinator", position = { x = 0, y = 0 } } }
        src.blueprint = bp
        src.circuits = circuits
        src.model = "m"
        src.label = "lbl"
        src.is_packed = false

        local clone = H.track(processor.clone { position = { 110, 0 }, surface = H.surface(), force = H.force })
        ---@cast clone -nil
        local dst = storage.procinfos[clone.unit_number]
        assert.is_not_nil(dst)
        assert.are_not_equal(src, dst)
        assert.are_equal(bp, dst.blueprint)
        assert.are_same(circuits, dst.circuits)
        assert.are_equal("m", dst.model)
        assert.are_equal("lbl", dst.label)
        assert.is_true(#dst.iopoints > 0)
    end)

    test("clone of a packed processor copies blueprint and rebuilds packed circuit at destination", function()
        local processor = H.create_processor({ 100, 0 }, { raise = false })
        local bp = H.make_blueprint(simple_bp_entities)
        script.raise_event(defines.events.script_raised_built, { entity = processor, tags = { blueprint = bp } })

        local clone = H.track(processor.clone { position = { 110, 0 }, surface = H.surface(), force = H.force })
        ---@cast clone -nil
        local dst = storage.procinfos[clone.unit_number]
        assert.is_not_nil(dst)
        assert.is_true(dst.is_packed)
        assert.are_equal(bp, dst.blueprint)
        assert.are_equal(1, #H.packed_entities(clone, commons.prefix .. "-ac"))
        -- the source keeps its own packed circuit
        assert.are_equal(1, #H.packed_entities(processor, commons.prefix .. "-ac"))
    end)

    test("clone of an unpacked processor moves its editor surface to the clone", function()
        local processor, src, surface = H.create_unpacked_processor({ 100, 0 })
        surface.create_entity { name = "constant-combinator", position = { 0.5, 0.5 }, force = H.force }

        local clone = H.track(processor.clone { position = { 110, 0 }, surface = H.surface(), force = H.force })
        ---@cast clone -nil
        local dst = storage.procinfos[clone.unit_number]
        assert.is_not_nil(dst)
        local new_name = editor.get_surface_name(clone)
        assert.is_true(surface.valid)
        assert.are_equal(new_name, surface.name)
        assert.are_equal(surface, dst.surface)
        assert.are_equal(dst, storage.surface_map[new_name])
        assert.is_nil(storage.surface_map[editor.get_surface_name(processor)])
        assert.is_nil(src.surface)
        assert.are_equal(1, surface.count_entities_filtered { name = "constant-combinator" })
    end)
end)

describe("tools", function()
    local saved_players
    before_each(function()
        saved_players = storage.players
    end)
    after_each(function()
        storage.players = saved_players
        H.cleanup()
    end)

    test("close_ui clears only the requested field of the matching player", function()
        local e1 = H.track(H.surface().create_entity { name = "constant-combinator", position = { 120.5, 0.5 }, force = H.force })
        local e2 = H.track(H.surface().create_entity { name = "constant-combinator", position = { 122.5, 0.5 }, force = H.force })
        ---@cast e1 -nil
        ---@cast e2 -nil
        storage.players = {
            [101] = { selected = e1, display_entity = e1 },
            [102] = { selected = e2, display_entity = e2 },
        }
        local calls = 0
        tools.close_ui(e1.unit_number, function() calls = calls + 1 end, "display_entity")
        assert.are_equal(1, calls)
        assert.is_nil(storage.players[101].display_entity)
        assert.are_equal(e1, storage.players[101].selected)
        assert.are_equal(e2, storage.players[102].display_entity)

        tools.close_ui(e1.unit_number, function() calls = calls + 1 end)
        assert.are_equal(2, calls)
        assert.is_nil(storage.players[101].selected)
        assert.are_equal(e2, storage.players[102].selected)
    end)

    test("close_ui with no storage.players does not error", function()
        storage.players = nil
        tools.close_ui(1, function() error("should not be called") end)
    end)
end)
