-- End-to-end signal tests: a circuit inside a processor must compute the same
-- outputs unpacked, packed, and unpacked again.
local build = require("scripts.build")
local editor = require("scripts.editor")
local input = require("scripts.input")
local H = require("tests.helpers")

local W = defines.wire_connector_id
local SIGNAL_A = { type = "virtual", name = "signal-A", quality = "normal" }

---@param surface LuaSurface
---@param name string
---@param position MapPosition
---@return LuaEntity
local function place(surface, name, position)
    local e = surface.create_entity { name = name, position = position, force = H.force }
    assert(e, "failed to create " .. name)
    return H.track(e) --[[@as LuaEntity]]
end

---@param a LuaEntity
---@param a_id defines.wire_connector_id
---@param b LuaEntity
---@param b_id defines.wire_connector_id
local function wire(a, a_id, b, b_id)
    assert(a.get_wire_connector(a_id, true).connect_to(b.get_wire_connector(b_id, true), false),
        "failed to wire " .. a.name .. " to " .. b.name)
end

---@param cc LuaEntity
---@param value integer
local function set_constant(cc, value)
    local cb = cc.get_or_create_control_behavior() --[[@as LuaConstantCombinatorControlBehavior]]
    local section = cb.get_section(1) or cb.add_section()
    ---@cast section -nil
    section.set_slot(1, { value = SIGNAL_A, min = value })
end

---@param reader LuaEntity
---@return integer
local function read(reader)
    local network = reader.get_circuit_network(W.circuit_red)
    if not network then return 0 end
    return network.get_signal(SIGNAL_A)
end

describe("signals through a processor", function()
    local processor, procinfo, source, reader

    before_each(function()
        local surface
        processor, procinfo, surface = H.create_unpacked_processor({ 300, 0 })

        -- Inside: pole 1 -> arithmetic (each * 2) -> pole 2
        local pole_in = surface.create_entity { name = "microcircuits-internal_iopoint", position = { -4.5, 0.5 }, force = H.force }
        local pole_out = surface.create_entity { name = "microcircuits-internal_iopoint", position = { 4.5, 0.5 }, force = H.force }
        assert(pole_in and pole_out, "failed to create internal iopoints")
        editor.init_internal_point(pole_in, { index = 1, label = "in" }, procinfo)
        editor.init_internal_point(pole_out, { index = 2, label = "out" }, procinfo)

        local ac = surface.create_entity { name = "arithmetic-combinator", position = { 0.5, 0 }, direction = defines.direction.east, force = H.force }
        assert(ac, "failed to create arithmetic combinator")
        local cb = ac.get_or_create_control_behavior() --[[@as LuaArithmeticCombinatorControlBehavior]]
        cb.parameters = {
            first_signal = { type = "virtual", name = "signal-each" },
            second_constant = 2,
            operation = "*",
            output_signal = { type = "virtual", name = "signal-each" },
        }
        wire(pole_in, W.circuit_red, ac, W.combinator_input_red)
        wire(ac, W.combinator_output_red, pole_out, W.circuit_red)

        -- Outside: constant combinator -> processor point 1, point 2 -> reader pole
        local p1, p2 = procinfo.iopoints[1], procinfo.iopoints[2]
        source = place(processor.surface, "constant-combinator", { p1.position.x - 3, p1.position.y })
        reader = place(processor.surface, "small-electric-pole", { p2.position.x + 3, p2.position.y })
        wire(source, W.circuit_red, p1, W.circuit_red)
        wire(reader, W.circuit_red, p2, W.circuit_red)
        set_constant(source, 5)
    end)

    after_each(function()
        H.cleanup()
    end)

    test("unpacked circuit doubles the input", function()
        after_ticks(10, function()
            assert.are_equal(10, read(reader))
        end)
    end)

    test("packed circuit computes the same and follows input changes", function()
        after_ticks(10, function()
            assert.are_equal(10, read(reader))
            -- pack and leave, as the editor does on exit
            editor.set_packed(procinfo, true)
            editor.delete_surface(procinfo)
        end)
    end)
        .step(function()
            after_ticks(10, function()
                assert.is_nil(procinfo.surface)
                assert.are_equal(10, read(reader))
                set_constant(source, 7)
            end)
        end)
        .step(function()
            after_ticks(10, function()
                assert.are_equal(14, read(reader))
            end)
        end)

    test("unpacking a packed processor restores a working circuit", function()
        after_ticks(10, function()
            editor.set_packed(procinfo, true)
            editor.delete_surface(procinfo)
        end)
    end)
        .step(function()
            -- re-enter, as editor.edit_selected does, then switch packed mode off
            editor.get_or_create_surface(procinfo)
            build.restore_packed_circuits(procinfo)
            input.apply_parameters(procinfo)
            editor.set_packed(procinfo, false)
            set_constant(source, 3)
            after_ticks(10, function()
                assert.is_false(procinfo.is_packed)
                assert.are_equal(6, read(reader))
            end)
        end)
end)
