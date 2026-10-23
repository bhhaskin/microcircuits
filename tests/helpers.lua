-- Shared helpers for the in-game regression tests (not a test file itself).
local commons = require("scripts.commons")
local editor = require("scripts.editor")

local H = {}

H.force = "player"

---@type LuaEntity[]
local created = {}

---@return LuaSurface
function H.surface()
    return game.surfaces[1]
end

---Remember an entity so H.cleanup() destroys it.
---@param entity LuaEntity?
---@return LuaEntity?
function H.track(entity)
    if entity then table.insert(created, entity) end
    return entity
end

---Create a processor on nauvis.
---@param position MapPosition
---@param opts {name:string?, raise:boolean?}?
---@return LuaEntity
---@return ProcInfo?
function H.create_processor(position, opts)
    opts = opts or {}
    local raise = opts.raise
    if raise == nil then raise = true end
    local entity = H.surface().create_entity {
        name = opts.name or commons.processor_name,
        position = position,
        force = H.force,
        raise_built = raise
    }
    assert(entity, "processor not created")
    H.track(entity)
    return entity, storage.procinfos[entity.unit_number]
end

---Create a processor that has an (unpacked) editor surface, the way
---editor.edit_selected does, but without a player.
---@param position MapPosition
---@return LuaEntity
---@return ProcInfo
---@return LuaSurface
function H.create_unpacked_processor(position)
    local processor, procinfo = H.create_processor(position)
    assert(procinfo, "no procinfo")
    local surface = editor.get_or_create_surface(procinfo)
    return processor, procinfo, surface
end

---Build a blueprint string from blueprint entity definitions.
---@param bp_entities BlueprintEntity[]
---@return string
function H.make_blueprint(bp_entities)
    local inv = game.create_inventory(1)
    local bp = inv[1]
    bp.set_stack { name = "blueprint", count = 1 }
    bp.set_blueprint_entities(bp_entities)
    local s = bp.export_stack()
    inv.destroy()
    return s
end

---Read blueprint entities of a blueprint string
---@param s string
---@return BlueprintEntity[]
function H.blueprint_entities(s)
    local inv = game.create_inventory(1)
    local bp = inv[1]
    bp.set_stack { name = "blueprint", count = 1 }
    assert(bp.import_stack(s) ~= 1, "blueprint import failed")
    local entities = bp.get_blueprint_entities() or {}
    inv.destroy()
    return entities
end

---Find hidden packed entities under a processor
---@param processor LuaEntity
---@param names string|string[]?
---@return LuaEntity[]
function H.packed_entities(processor, names)
    return processor.surface.find_entities_filtered {
        position = processor.position,
        radius = 1.5,
        name = names or commons.packed_entities
    }
end

---@param count integer?
---@return integer
function H.count_processor_surfaces()
    local n = 0
    for _, s in pairs(game.surfaces) do
        if string.find(s.name, commons.surface_name_pattern) then n = n + 1 end
    end
    return n
end

---Destroy everything created by the tests (processors via script_raised_destroy
---so the mod cleans its sub-entities, procinfo and editor surface).
function H.cleanup()
    for _, entity in pairs(created) do
        if entity.valid then
            if string.find(entity.name, commons.processor_pattern) then
                entity.destroy { raise_destroy = true }
            else
                entity.destroy()
            end
        end
    end
    created = {}
end

---Signal helper
---@param name string
---@return SignalID
function H.vsignal(name)
    return { type = "virtual", name = name }
end

return H
