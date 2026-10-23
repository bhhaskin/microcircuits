-- Minimal stand-ins for the Factorio globals the pure helpers touch at load time.
-- busted runs on Lua 5.4; Factorio runs a modified Lua 5.2, so add what 5.4 dropped.

math.pow = math.pow or function(x, y) return x ^ y end

defines = {
    print_skip = { never = 0 },
    controllers = { ghost = 0, character = 1, god = 2, editor = 3, cutscene = 4, spectator = 5, remote = 6 },
    direction = {
        north = 0, northeast = 2, east = 4, southeast = 6,
        south = 8, southwest = 10, west = 12, northwest = 14,
    },
}

log = function() end
