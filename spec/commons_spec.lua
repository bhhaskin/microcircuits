local commons = require("scripts.commons")

describe("commons.get_color", function()
    it("returns the default for missing or invalid input", function()
        local default = { r = 1, g = 1, b = 1, a = 1 }
        assert.are.equal(default, commons.get_color(nil, default))
        assert.are.equal(default, commons.get_color("zzzzzz", default))
    end)

    it("decodes RRGGBB", function()
        assert.are.same({ r = 1, g = 0, b = 0, a = 1 }, commons.get_color("FF0000"))
        assert.are.same({ r = 0, g = 1, b = 0, a = 1 }, commons.get_color("00FF00"))
        assert.are.same({ r = 0, g = 0, b = 1, a = 1 }, commons.get_color("0000FF"))
    end)

    it("keeps intermediate blue values", function()
        local color = commons.get_color("000080")
        assert.are.near(128 / 255, color.b, 1e-9)
        assert.are.equal(0, color.r)
        assert.are.equal(0, color.g)
    end)

    it("reads alpha from the leading byte of AARRGGBB", function()
        local color = commons.get_color("80FF8000")
        assert.are.near(128 / 255, color.a, 1e-9)
        assert.are.equal(1, color.r)
        assert.are.near(128 / 255, color.g, 1e-9)
        assert.are.equal(0, color.b)
    end)
end)

describe("commons surface names", function()
    it("matches renamed editor surfaces only", function()
        local pattern = commons.surface_name_pattern
        assert.truthy(string.find(commons.surface_prefix .. "123", pattern))
        assert.falsy(string.find("proc_123", pattern))
        assert.falsy(string.find("nauvis", pattern))
    end)
end)
