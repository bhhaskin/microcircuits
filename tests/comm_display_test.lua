-- comm (channel routers) and display regression tests
local commons = require("scripts.commons")
local comm = require("scripts.comm")
local display = require("scripts.display")
local H = require("tests.helpers")

local comm_surface_prefix = commons.prefix .. "_comm_"

describe("comm", function()
    local saved_contexts
    ---@type table<string, boolean>
    local preexisting

    before_each(function()
        saved_contexts = storage.comm_contexts
        storage.comm_contexts = nil
        preexisting = {}
        for _, s in pairs(game.surfaces) do preexisting[s.name] = true end
    end)

    after_each(function()
        H.cleanup()
        for _, s in pairs(game.surfaces) do
            if not preexisting[s.name] and string.find(s.name, comm_surface_prefix, 1, true) then
                game.delete_surface(s)
            end
        end
        storage.comm_contexts = saved_contexts
    end)

    test("get_context gives each force its own valid surface", function()
        local player_force = game.forces["player"]
        local enemy_force = game.forces["enemy"]
        local c1 = comm.get_context(player_force.index, true)
        local c2 = comm.get_context(enemy_force.index, true)
        assert.is_not_nil(c1)
        assert.is_not_nil(c2)
        ---@cast c1 -nil
        ---@cast c2 -nil
        assert.are_not_equal(c1, c2)
        assert.is_true(c1.surface.valid)
        assert.is_true(c2.surface.valid)
        assert.are_not_equal(c1.surface.index, c2.surface.index)
        assert.are_not_equal(c1.surface.name, c2.surface.name)
        -- second call returns the cached context
        assert.are_equal(c1, comm.get_context(player_force.index, true))
        assert.is_true(c1.surface.valid)
        -- without create, an unknown force gives nil
        assert.is_nil(comm.get_context(game.forces["neutral"].index, false))
    end)

    test("routers of different forces live on different surfaces", function()
        local r1 = comm.get_router(game.forces["player"].index, "chan")
        local r2 = comm.get_router(game.forces["enemy"].index, "chan")
        assert.is_true(r1 ~= nil and r1.valid)
        assert.is_true(r2 ~= nil and r2.valid)
        ---@cast r1 -nil
        ---@cast r2 -nil
        assert.are_not_equal(r1.surface_index, r2.surface_index)
        assert.are_equal("player", r1.force.name)
        assert.are_equal("enemy", r2.force.name)
    end)

    test("router indices freed by purge are reused", function()
        local force_index = game.forces["player"].index
        local ra = comm.get_router(force_index, "a")
        local rb = comm.get_router(force_index, "b")
        ---@cast ra -nil
        ---@cast rb -nil
        local cctx = comm.get_context(force_index, false)
        ---@cast cctx -nil
        assert.are_equal(2, cctx.max_index)
        local ia = cctx.name_channels["a"].index
        local ib = cctx.name_channels["b"].index
        assert.are_not_equal(ia, ib)

        -- unconnected routers are purged and their indices freed
        comm.purge()
        assert.is_false(ra.valid)
        assert.is_false(rb.valid)
        assert.is_nil(cctx.name_channels["a"])
        assert.are_equal(2, #cctx.free_indices)

        local rc = comm.get_router(force_index, "c")
        ---@cast rc -nil
        assert.is_true(rc.valid)
        local ic = cctx.name_channels["c"].index
        assert.is_true(ic == ia or ic == ib)
        assert.are_equal(2, cctx.max_index)
        assert.are_equal(1, #cctx.free_indices)
    end)

    test("purge keeps connected routers and drops them once disconnected", function()
        local force_index = game.forces["player"].index
        local cc = H.track(H.surface().create_entity { name = "constant-combinator", position = { 300.5, 0.5 }, force = H.force })
        ---@cast cc -nil
        comm.connect(cc, "kept", true, false)
        local router = comm.get_router(force_index, "kept")
        ---@cast router -nil
        assert.is_true(router.valid)
        comm.purge()
        assert.is_true(router.valid)
        local cctx = comm.get_context(force_index, false)
        ---@cast cctx -nil
        assert.is_not_nil(cctx.name_channels["kept"])
        comm.disconnect(cc)
        comm.purge()
        assert.is_false(router.valid)
        assert.is_nil(cctx.name_channels["kept"])
    end)

    test("purge and get_chanel_names with no contexts do not error", function()
        comm.purge()
        assert.are_same({}, comm.get_chanel_names(1))
    end)
end)

describe("display", function()
    local saved_infos

    before_each(function()
        saved_infos = storage.display_infos
    end)

    after_each(function()
        storage.display_infos = saved_infos
        H.cleanup()
    end)

    test("restart with storage.display_infos == nil does not error", function()
        storage.display_infos = nil
        local d = H.track(H.surface().create_entity { name = commons.display_name, position = { 310.5, 0.5 }, force = H.force })
        ---@cast d -nil
        display.restart(d)
        assert.is_nil(display.get(d.unit_number))
        storage.display_infos = {}
        display.restart(d)
    end)

    test("settings paste between displays with storage.display_infos == nil does not error", function()
        storage.display_infos = nil
        local surface = H.surface()
        local d1 = H.track(surface.create_entity { name = commons.display_name, position = { 312.5, 0.5 }, force = H.force })
        local d2 = H.track(surface.create_entity { name = commons.display_name, position = { 314.5, 0.5 }, force = H.force })
        ---@cast d1 -nil
        ---@cast d2 -nil
        -- on_entity_settings_pasted can't be raised by script: call the mod's (chained) handler
        local handler = script.get_event_handler(defines.events.on_entity_settings_pasted)
        assert.is_not_nil(handler)
        ---@cast handler -nil
        handler {
            name = defines.events.on_entity_settings_pasted,
            tick = game.tick,
            player_index = 1,
            source = d1,
            destination = d2
        }
        assert.is_nil(storage.display_infos)
    end)
end)
