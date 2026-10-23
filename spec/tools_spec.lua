local tools = require("scripts.tools")

describe("tools string helpers", function()
    it("starts_with", function()
        assert.is_true(tools.starts_with("microcircuits-cc", "microcircuits"))
        assert.is_false(tools.starts_with("micro", "microcircuits"))
        assert.is_true(tools.starts_with("anything", ""))
    end)

    it("ends_with", function()
        assert.is_true(tools.ends_with("processor_1x1", "_1x1"))
        assert.is_false(tools.ends_with("processor", "_1x1"))
        assert.is_true(tools.ends_with("anything", ""))
    end)

    it("comma_value", function()
        assert.are.equal("1,234,567", tools.comma_value(1234567))
        assert.are.equal("-1,000", tools.comma_value(-1000))
        assert.are.equal("", tools.comma_value(nil))
    end)
end)

describe("tools.sprite_to_signal", function()
    it("splits type/name sprites", function()
        assert.are.same({ type = "fluid", name = "water" }, tools.sprite_to_signal("fluid/water"))
    end)

    it("maps virtual-signal to virtual", function()
        assert.are.same({ type = "virtual", name = "signal-A" }, tools.sprite_to_signal("virtual-signal/signal-A"))
    end)

    it("treats a bare name as an item", function()
        assert.are.same({ type = "item", name = "iron-plate" }, tools.sprite_to_signal("iron-plate"))
    end)

    it("returns nil for nil", function()
        assert.is_nil(tools.sprite_to_signal(nil))
    end)
end)

describe("tools.id_to_filter", function()
    it("returns bare item names unchanged", function()
        assert.are.equal("iron-plate", tools.id_to_filter("iron-plate"))
    end)

    it("returns normal-quality items as a name", function()
        assert.are.equal("iron-plate", tools.id_to_filter("item/iron-plate"))
    end)

    it("keeps item quality", function()
        assert.are.same(
            { type = "item", name = "iron-plate", comparator = "=", quality = "rare" },
            tools.id_to_filter("item/iron-plate/=/rare"))
    end)

    it("keeps virtual signals and their quality", function()
        assert.are.same({ type = "virtual", name = "signal-A" }, tools.id_to_filter("virtual/signal-A"))
        assert.are.same(
            { type = "virtual", name = "signal-A", comparator = ">", quality = "epic" },
            tools.id_to_filter("virtual/signal-A/>/epic"))
    end)

    it("keeps quality for other signal types", function()
        assert.are.same(
            { type = "fluid", name = "water", comparator = "=", quality = "rare" },
            tools.id_to_filter("fluid/water/=/rare"))
        assert.are.same(
            { type = "entity", name = "inserter", comparator = "=", quality = "normal" },
            tools.id_to_filter("entity/inserter"))
    end)

    it("round-trips through signal_to_id", function()
        local signal = { type = "fluid", name = "water", comparator = "=", quality = "legendary" }
        assert.are.same(signal, tools.id_to_filter(tools.signal_to_id(signal)))
    end)
end)

describe("tools item strings", function()
    it("round-trips item_to_string and string_to_item", function()
        local item = { name = "iron-plate", comparator = "<", quality = "rare" }
        assert.are.same(item, tools.string_to_item(tools.item_to_string(item)))
    end)

    it("defaults comparator and quality", function()
        assert.are.same({ name = "iron-plate", comparator = "=", quality = "normal" }, tools.string_to_item("iron-plate"))
    end)
end)

describe("tools.get_local_disp", function()
    it("rotates offsets by direction", function()
        local d = defines.direction
        assert.are.same({ x = 1, y = 2 }, tools.get_local_disp(d.north, { 1, 2 }))
        assert.are.same({ x = -1, y = -2 }, tools.get_local_disp(d.south, { 1, 2 }))
        assert.are.same({ x = 2, y = -1 }, tools.get_local_disp(d.west, { 1, 2 }))
        assert.are.same({ x = -2, y = 1 }, tools.get_local_disp(d.east, { 1, 2 }))
    end)
end)

describe("tools.fround", function()
    it("rounds tiny values to zero", function()
        assert.are.equal(0, tools.fround(0.0000001))
    end)

    it("keeps a few significant digits", function()
        assert.are.near(123, tools.fround(123.456), 1e-9)
    end)
end)

describe("tools.on_event", function()
    local handlers, filters

    before_each(function()
        handlers, filters = {}, {}
        _G.script = {
            get_event_handler = function(event) return handlers[event] end,
            get_event_filter = function(event) return filters[event] end,
            on_event = function(event, handler, f)
                handlers[event] = handler
                filters[event] = f
            end,
        }
    end)

    after_each(function()
        _G.script = nil
    end)

    it("chains handlers for the same event", function()
        local calls = {}
        tools.on_event(1, function() table.insert(calls, "a") end)
        tools.on_event(1, function() table.insert(calls, "b") end)
        handlers[1]({})
        assert.are.same({ "a", "b" }, calls)
    end)

    it("merges filters when both registrations have one", function()
        tools.on_event(1, function() end, { { filter = "name", name = "a" } })
        tools.on_event(1, function() end, { { filter = "name", name = "b" } })
        assert.are.same({ { filter = "name", name = "a" }, { filter = "name", name = "b" } }, filters[1])
    end)

    it("drops the filter when either registration has none", function()
        tools.on_event(1, function() end, { { filter = "name", name = "a" } })
        tools.on_event(1, function() end)
        assert.is_nil(filters[1])

        tools.on_event(2, function() end)
        tools.on_event(2, function() end, { { filter = "name", name = "a" } })
        assert.is_nil(filters[2])
    end)
end)
