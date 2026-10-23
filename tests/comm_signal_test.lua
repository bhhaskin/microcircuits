-- End-to-end wireless (comm channel) tests: a signal sent on a channel by one
-- processor must arrive at another processor, whether each one is packed or not.
local commons = require("scripts.commons")
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
    return e
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

---A processor whose input/output point 1 is wired, inside, to a comm input on `channel` (red).
---@param x number
---@param channel string
---@return LuaEntity processor
---@return ProcInfo procinfo
local function comm_processor(x, channel)
    local processor, procinfo, surface = H.create_unpacked_processor({ x, 0 })
    local pole = place(surface, commons.internal_iopoint_name, { -4.5, 0.5 })
    editor.init_internal_point(pole, { index = 1, label = "io" }, procinfo)

    local comm_input = place(surface, commons.input_name, { 0.5, 0.5 })
    input.register(comm_input, {
        type = input.types.comm,
        label = "channel",
        channel_name = channel,
        channel_red = true,
        channel_green = false,
    } --[[@as CommInput]])
    wire(pole, W.circuit_red, comm_input, W.circuit_red)
    return processor, procinfo
end

---@param procinfo ProcInfo
local function pack(procinfo)
    -- pack and leave, as the editor does on exit
    editor.set_packed(procinfo, true)
    editor.delete_surface(procinfo)
end

local cases = {
    { "unpacked sender, unpacked receiver", false, false },
    { "packed sender, packed receiver",     true,  true },
    { "packed sender, unpacked receiver",   true,  false },
    { "unpacked sender, packed receiver",   false, true },
}

describe("comm channel between two processors", function()
    after_each(function()
        H.cleanup()
    end)

    for i, case in ipairs(cases) do
        local label, pack_sender, pack_receiver = case[1], case[2], case[3]
        ---@type LuaEntity
        local reader
        test(label, function()
            local channel = "test-" .. i
            local sender, sender_info = comm_processor(400 + i * 40, channel)
            local receiver, receiver_info = comm_processor(400 + i * 40 + 20, channel)

            -- outside: constant combinator -> sender, receiver -> reader pole
            local p1 = sender_info.iopoints[1]
            local p2 = receiver_info.iopoints[1]
            local source = H.track(place(sender.surface, "constant-combinator", { p1.position.x - 3, p1.position.y }))
            reader = place(receiver.surface, "small-electric-pole", { p2.position.x - 3, p2.position.y })
            H.track(reader)
            ---@cast source -nil
            wire(source, W.circuit_red, p1, W.circuit_red)
            wire(reader, W.circuit_red, p2, W.circuit_red)
            set_constant(source, 5)

            if pack_sender then pack(sender_info) end
            if pack_receiver then pack(receiver_info) end

            after_ticks(10, function()
                assert.are_equal(pack_sender, sender_info.is_packed == true)
                assert.are_equal(pack_receiver, receiver_info.is_packed == true)
                assert.are_equal(5, read(reader))
                set_constant(source, 9)
            end)
        end)
            .step(function()
                after_ticks(10, function()
                    assert.are_equal(9, read(reader))
                end)
            end)
    end
end)
