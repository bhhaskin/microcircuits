local commons = require("scripts.commons")

local prefix = commons.prefix
local ccutils = require("scripts.ccutils")
local tools = require("scripts.tools")
local display = require("scripts.display")
local input = require("scripts.input")
local build = require("scripts.build")

local debug = tools.debug
local cdebug = tools.cdebug
local get_vars = tools.get_vars
local strip = tools.strip

local EDITOR_SIZE = commons.EDITOR_SIZE
local internal_iopoint_name = commons.internal_iopoint_name
local internal_connector_name = commons.internal_connector_name
local display_name = commons.display_name
local input_name = commons.input_name

local allowed_name_map = build.allowed_name_map
local remote_name_map = build.remote_name_map
local textplate_map = build.textplate_map

local editor = {}
local button_prefix = prefix .. "-button"
local label_prefix = prefix .. "-label"
local checkbox_prefix = prefix .. "-checkbox"
local message_prefix = prefix .. "-message"
local tooltip_prefix = prefix .. "-tooltip"
local iopanel_name = prefix .. "-iopole_panel"

---@param player LuaPlayer
---@return boolean
function editor.close_editor_panel(player)
    ---@type LuaGuiElement
    local b = player.gui.left[prefix .. "-intern_panel"]
    if b then
        b.destroy()
        return true
    end
    return false
end

local get_procinfo = build.get_procinfo
editor.get_proc_info = build.get_procinfo

---@param processor LuaEntity
---@return string
function editor.get_surface_name(processor)
    return commons.surface_prefix .. processor.unit_number
end

---@param name string
---@return string?
local function is_allowed(name)
    local packed_name = allowed_name_map[name]
    if packed_name then return packed_name end
    if textplate_map[name] then return name end
    if remote_name_map[name] then return name end
    return nil
end

local internal_panel_name = commons.internal_panel_name

---@param player LuaPlayer
---@param procinfo ProcInfo
function editor.create_editor_panel(player, procinfo)
    ccutils.close_all(player)
    editor.close_editor_panel(player)

    local outer_frame = player.gui.left.add {
        type = "frame",
        direction = "vertical",
        name = internal_panel_name,
        caption = { prefix .. ".main-title" }
    }

    local frame = outer_frame.add {
        type = "frame",
        direction = "vertical",
        style = "inside_shallow_frame_with_padding",
    }

    local exit_flow = frame.add { type = "flow", direction = "horizontal" }
    local b = exit_flow.add {
        type = "button",
        caption = { button_prefix .. ".exit_editor" },
        name = prefix .. "-exit_editor",
        tooltip = { tooltip_prefix .. ".exit" }
    }
    b.style.width = 160

    b = exit_flow.add {
        type = "button",
        caption = { button_prefix .. ".models" },
        name = prefix .. "-models",
        tooltip = { tooltip_prefix .. ".models" }
    }
    b.style.width = 160

    local add_flow = frame.add {
        type = "flow",
        direction = "horizontal"
    }
    local label = add_flow.add {
        type = "label",
        caption = { prefix .. ".add_component_label" }
    }
    label.style.top_margin = 10

    b = add_flow.add {
        type = "sprite-button",
        tooltip = { tooltip_prefix .. ".add_iopole" },
        name = prefix .. "-add_iopole",
        sprite = "item/" .. commons.internal_iopoint_name
    }
    b = add_flow.add {
        type = "sprite-button",
        tooltip = { tooltip_prefix .. ".add__internal_connector" },
        name = prefix .. "-add_internal_connector",
        sprite = "item/" .. internal_connector_name
    }
    b = add_flow.add {
        type = "sprite-button",
        tooltip = { tooltip_prefix .. ".add_display" },
        name = prefix .. "-add_display",
        sprite = "item/" .. display_name
    }
    b = add_flow.add {
        type = "sprite-button",
        tooltip = { tooltip_prefix .. ".add_input" },
        name = prefix .. "-add_input",
        sprite = "item/" .. commons.input_name
    }

    local info_flow = frame.add {
        type = "flow",
        direction = "horizontal",
        name = "info_flow"
    }
    b = info_flow.add {
        type = "checkbox",
        state = procinfo.is_packed or false,
        caption = { prefix .. "-parameters.is_packed" },
        tooltip = { tooltip_prefix .. ".is_packed" },
        name = prefix .. "-is_packed"
    }
    b.style.right_margin = 10
    b.style.top_margin = 10
    b = info_flow.add {
        type = "choose-elem-button",
        tooltip = { tooltip_prefix .. ".sprite1" },
        name = prefix .. "-sprite1",
        elem_type = "signal",
        signal = ccutils.translate_signal(tools.sprite_to_signal(procinfo.sprite1))
    }
    b = info_flow.add {
        type = "choose-elem-button",
        tooltip = { tooltip_prefix .. ".sprite2" },
        name = prefix .. "-sprite2",
        elem_type = "signal",
        signal = ccutils.translate_signal(tools.sprite_to_signal(procinfo.sprite2))
    }

    local title_flow = frame.add {
        type = "flow",
        direction = "horizontal"
    }
    title_flow.style.top_margin = 5
    local label = title_flow.add {
        type = "label",
        caption = { prefix .. ".title_label" }
    }
    local ftitle = title_flow.add {
        type = "textfield",
        name = prefix .. "-title",
        text = procinfo.label or "",
        tooltip = { prefix .. "-tooltip.title" },
        icon_selector = true
    }
    ftitle.style.width = 300
end

-----------------------------------------------------------------

tools.on_event(defines.events.on_gui_elem_changed,
    ---@param e EventData.on_gui_elem_changed
    function(e)
        local player = game.players[e.player_index]
        local name
        if not e.element.valid then return end
        if e.element.name == prefix .. "-sprite1" then
            name = "sprite1"
        elseif e.element.name == prefix .. "-sprite2" then
            name = "sprite2"
        else
            return
        end

        local procinfo = storage.surface_map[player.surface.name]
        if not procinfo then return end
        procinfo[name] = tools.signal_to_sprite(e.element.elem_value --[[@as SignalID]])
        editor.draw_sprite(procinfo)
    end)

-----------------------------------------------------------------

---@param surface LuaSurface
---@param x number
---@param y number
---@return number
---@return number
function editor.find_room(surface, x, y)
    local count = 0
    while true do
        local entities = surface.find_entities({ { x - 1, y - 1 }, { x + 1, y + 1 } })
        if #entities == 0 then break end
        x = x + 1
        if x > EDITOR_SIZE / 2 - 1 then
            x = -EDITOR_SIZE / 2 + 1
            y = y + 1
            if y > EDITOR_SIZE / 2 - 1 then y = -EDITOR_SIZE / 2 + 1 end
        end
        count = count + 1
        if count > 1000 then break end
    end
    return x, y
end

local allow_controller_types = {

    [defines.controllers.god] = true,
    [defines.controllers.character] = true,
    [defines.controllers.remote] = true,
    [defines.controllers.editor] = true
}

---@param surface LuaSurface?
---@param player LuaPlayer?
---@return boolean
local function has_other_players(surface, player)
    if not surface or not surface.valid then return false end
    local index = surface.index
    for _, p in pairs(game.players) do
        if p ~= player and p.valid and
            (p.surface_index == index or p.physical_surface_index == index) then
            return true
        end
    end
    return false
end

editor.has_other_players = has_other_players

---@param player LuaPlayer
---@param processor LuaEntity
function editor.edit_selected(player, processor)
    local vars = get_vars(player)
    if vars.last_click and vars.last_click > game.tick - 120 then return end
    vars.last_click = game.tick

    if not allow_controller_types[player.controller_type] then
        return
    end

    if not processor or not processor.valid then return end

    local procinfo = get_procinfo(processor, true)
    ---@cast procinfo -nil
    local previous_procinfo = vars.procinfo
    local previous_processor = vars.processor
    vars.procinfo = procinfo
    vars.processor = processor
    local existing = procinfo.surface ~= nil and procinfo.surface.valid
    local surface = editor.get_or_create_surface(procinfo)

    -- Do not rebuild the surface under another player's feet
    if procinfo.is_packed and not (existing and has_other_players(surface, player)) then
        if existing then editor.clean_surface(procinfo) end
        build.restore_packed_circuits(procinfo)
        input.apply_parameters(procinfo)
        input.disconnect_comms(surface)
    end

    -- Origin is stored per player: several players may edit the same processor
    if not vars.origins then vars.origins = {} end
    vars.origins[procinfo.unit_number] = {
        surface_name = player.surface.name,
        position = player.position,
        controller_type = player.controller_type,
        physical_surface_index = player.physical_surface_index,
        physical_controller_type = player.physical_controller_type,
        physical_position = player.physical_position
    }
    if not string.find(player.physical_surface.name, commons.surface_name_pattern) and
        not string.find(player.surface.name, commons.surface_name_pattern) then
        vars.physical_surface_index = player.physical_surface_index
        vars.physical_controller_type = player.physical_controller_type
        vars.physical_position = player.physical_position
    end

    local x, y = editor.find_room(surface, 0, 0)
    if not player.teleport({ x, y }, surface) then
        vars.origins[procinfo.unit_number] = nil
        vars.procinfo = previous_procinfo
        vars.processor = previous_processor
        if procinfo.is_packed and not existing and not has_other_players(surface) then
            editor.delete_surface(procinfo)
        end
    end
end

---@param procinfo ProcInfo?
---@param player LuaPlayer
---@return table?
local function get_origin(procinfo, player)
    if not procinfo then return nil end
    local origins = get_vars(player).origins
    local origin = origins and origins[procinfo.unit_number]
    if not origin and procinfo.origin_surface_name then
        -- Legacy: origin was stored on procinfo
        origin = {
            surface_name = procinfo.origin_surface_name,
            position = procinfo.origin_surface_position,
            controller_type = procinfo.origin_controller_type,
            physical_surface_index = procinfo.physical_surface_index,
            physical_controller_type = procinfo.physical_controller_type,
            physical_position = procinfo.physical_position
        }
    end
    return origin
end

---@param surface LuaSurface?
---@return boolean
local function is_valid_return_surface(surface)
    if not surface or not surface.valid then return false end
    if string.find(surface.name, commons.surface_name_pattern) then
        -- A processor surface is only a valid destination while it is in use
        return storage.surface_map ~= nil and storage.surface_map[surface.name] ~= nil
    end
    return true
end

---@param procinfo ProcInfo?
---@param player LuaPlayer
---@param to_origin boolean?
local function exit_player(procinfo, player, to_origin)
    ---@type MapPosition
    local ret_surface_position
    ---@type defines.controllers?
    local ret_controller_type
    ---@type LuaSurface?
    local ret_surface

    local vars = tools.get_vars(player)
    local origin = get_origin(procinfo, player)
    if not to_origin and origin then
        ret_surface = game.surfaces[origin.surface_name]
        ret_surface_position = origin.position
        ret_controller_type = origin.controller_type
    end
    if not is_valid_return_surface(ret_surface) and vars.physical_surface_index then
        ret_surface = game.surfaces[vars.physical_surface_index]
        ret_surface_position = vars.physical_position
        ret_controller_type = vars.physical_controller_type
    end
    if not is_valid_return_surface(ret_surface) then
        ret_surface = game.surfaces[1]
        ret_surface_position = { x = 0, y = 0 }
        ret_controller_type = nil
    end
    ---@cast ret_surface -nil
    ret_controller_type = ret_controller_type or defines.controllers.character
    local ret_surface_name = ret_surface.name

    if ret_controller_type == defines.controllers.character
        or ret_controller_type == defines.controllers.god
    then
        player.teleport(ret_surface_position, ret_surface_name)
        local platform = ret_surface.platform
        if platform then
            player.enter_space_platform(platform)
        end
    else
        local physical_surface = origin and origin.physical_controller_type and
            game.surfaces[origin.physical_surface_index]
        if physical_surface and physical_surface.valid then
            ---@cast origin -nil
            player.teleport(origin.physical_position, physical_surface, false, false)
            local platform = physical_surface.platform
            if platform then
                player.enter_space_platform(platform)
            end
        end
        player.set_controller {
            type = ret_controller_type,
            position = ret_surface_position,
            surface = ret_surface_name
        }
    end
end

---@param player LuaPlayer
local function close_editor_guis(player)
    ccutils.close_all(player)
    editor.close_iopanel(player)
    editor.close_editor_panel(player)
end

---Move every player currently on a processor surface back out (e.g. before deletion)
---@param surface LuaSurface
function editor.evacuate_surface(surface)
    if not surface or not surface.valid then return end

    local surface_procinfo = storage.surface_map and storage.surface_map[surface.name]
    local index = surface.index
    for _, player in pairs(game.players) do
        if player.valid and player.surface_index == index then
            local vars = get_vars(player)
            local procinfo = surface_procinfo or vars.procinfo
            close_editor_guis(player)
            -- Clear state first so on_player_changed_surface does no exit processing
            vars.procinfo = nil
            vars.processor = nil
            vars.is_standard_exit = false
            exit_player(procinfo, player)
            if procinfo and vars.origins then
                vars.origins[procinfo.unit_number] = nil
            end
            if player.surface_index == index then
                -- Last resort: force the player out
                player.teleport({ 0, 0 }, game.surfaces[1])
            end
        end
    end
end

---@param e EventData.on_gui_click
local function on_exit_editor(e)
    local player = game.players[e.player_index]
    close_editor_guis(player)

    local vars = get_vars(player)
    local procinfo = vars.procinfo
    vars.is_standard_exit = true
    exit_player(procinfo, player, e.control)
end

---@param player LuaPlayer
function editor.close_all(player)
    editor.close_iopanel(player)
    display.close(player)
    input.close(player)
    tools.fire_user_event("models.close", player)
end

ccutils.close_all = editor.close_all

---@param e EventData.on_gui_checked_state_changed
local function on_gui_checked_state_changed(e)
    if not e.element or e.element.name ~= prefix .. "-is_packed" then return end
    local player = game.players[e.player_index]

    local vars = get_vars(player)
    local procinfo = vars.procinfo
    if not procinfo then return end
    local new_packed = e.element.state
    editor.set_packed(procinfo, new_packed, player)
end

---@param parent ProcInfo
function editor.recursive_pack(parent)
    if not parent.surface then return end
    local processors = parent.surface.find_entities_filtered {
        name = { commons.processor_name, commons.processor_name_1x1 }
    }
    for _, processor in pairs(processors) do
        local procinfo = get_procinfo(processor, false)
        if procinfo and not procinfo.is_packed then
            editor.recursive_pack(procinfo)
            build.destroy_unpacked_proxies(procinfo)
            build.save_packed_circuits(procinfo)
            build.disconnect_all_iopoints(procinfo)
            build.create_packed_circuit(procinfo)
            editor.delete_surface(procinfo)
            procinfo.is_packed = true
        end
    end
end

---@param procinfo ProcInfo
---@param is_packed boolean
---@param player LuaPlayer?
function editor.set_packed(procinfo, is_packed, player)
    if procinfo.is_packed == is_packed then return end

    procinfo.is_packed = is_packed
    if is_packed then
        build.destroy_unpacked_proxies(procinfo)
        editor.recursive_pack(procinfo)
        build.save_packed_circuits(procinfo)
        build.disconnect_all_iopoints(procinfo)
        local _, _, externals = build.create_packed_circuit(procinfo)
        if externals and #externals > 0 and player then
            player.print({ "microcircuits-message.external_present" })
        end
        input.apply_parameters(procinfo)
        input.disconnect_comms(procinfo.surface)
    else
        build.destroy_packed_circuit(procinfo)
        build.connect_all_iopoints(procinfo)
        input.apply_parameters(procinfo)
        display.restore(procinfo)
        input.disconnect_comms(procinfo.surface)
        input.connect_comms(procinfo.surface)
        build.create_unpacked_proxies(procinfo)
    end
end

---@param procinfo ProcInfo
function editor.regenerate_packed(procinfo)
    if not procinfo.is_packed then return end

    build.create_packed_circuit(procinfo)
end

tools.on_event(defines.events.on_gui_checked_state_changed,
    on_gui_checked_state_changed)

---@param player LuaPlayer
---@return boolean
local function check_stack(player)
    local stack = player.cursor_stack
    if stack and stack.valid then
        if stack.count > 0 then
            if stack.name == internal_iopoint_name
                or stack.name == internal_connector_name
                or stack.name == display_name
                or stack.name == input_name
            then
                return true
            end

            local main_inventory = player.get_main_inventory()
            if not main_inventory then return false end
            local empty_stack = main_inventory.find_empty_stack()
            if empty_stack then
                empty_stack.transfer_stack(stack)
            else
                player.surface.spill_item_stack { position = player.position, stack = stack }
            end
            stack.clear()
        end
        return true
    end

    return false
end

---@param e EventData.on_gui_click
local function on_add_pole(e)
    local player = game.players[e.player_index]
    if check_stack(player) then player.cursor_ghost = internal_iopoint_name end
end

---@param e EventData.on_gui_click
local function on_add_internal_connector(e)
    local player = game.players[e.player_index]
    if check_stack(player) then
        player.cursor_ghost = internal_connector_name
    end
end

---@param e EventData.on_gui_click
local function on_add_display(e)
    local player = game.players[e.player_index]
    if check_stack(player) then
        player.cursor_ghost = display_name
    end
end

---@param e EventData.on_gui_click
local function on_add_input(e)
    local player = game.players[e.player_index]
    if check_stack(player) then
        player.cursor_ghost = commons.input_name
    end
end

---@param e EventData.on_gui_click
local function on_models_open(e)
    local player = game.players[e.player_index]
    tools.fire_user_event("models.open", player)
end

tools.on_gui_click(prefix .. "-exit_editor", on_exit_editor)
tools.on_gui_click(prefix .. "-models", on_models_open)
tools.on_gui_click(prefix .. "-add_iopole", on_add_pole)
tools.on_gui_click(prefix .. "-add_internal_connector",
    on_add_internal_connector)
tools.on_gui_click(prefix .. "-add_display",
    on_add_display)
tools.on_gui_click(prefix .. "-add_input",
    on_add_input)

---------------------------------------------------------------

---@param procinfo ProcInfo
---@return LuaSurface
function editor.get_or_create_surface(procinfo)
    if not storage.surface_map then
        ---@type table<string, ProcInfo>
        storage.surface_map = {}
    end

    local surface_name = editor.get_surface_name(procinfo.processor)
    local surface = game.get_surface(surface_name)
    if surface and surface == procinfo.surface and surface.valid then
        return surface
    end

    if not surface or not surface.valid then
        local mgs = {
            width = EDITOR_SIZE,
            height = EDITOR_SIZE,
            no_enemies_mode = true,
            property_expression_names = {},
            default_enable_all_autoplace_controls = false,
                autoplace_settings = {
                entity = { treat_missing_as_default = false, frequency = "none" },
                tile = { treat_missing_as_default = false },
                decorative = { treat_missing_as_default = false, frequency = "none" }
            },
        }
        surface = game.create_surface(surface_name, mgs)


        surface.always_day = true
        surface.show_clouds = false
        surface.request_to_generate_chunks({ 0, 0 }, 8)
        surface.force_generate_chunk_requests()
        surface.destroy_decoratives({})

        for _, force in pairs(game.forces) do
            force.set_surface_hidden(surface, true)
        end

        local tiles = {}
        local tile_proto = prefix .. "-ground"
        if not prototypes.tile[tile_proto] then
            tile_proto = "refined-concrete"
        end

        for _, tile in ipairs(surface.find_tiles_filtered {
            position = { 0, 0 },
            radius = EDITOR_SIZE + 2
        }) do
            local position = tile.position
            if (math.abs(position.x) > EDITOR_SIZE / 2 or math.abs(position.y) >
                    EDITOR_SIZE / 2) then
                table.insert(tiles, { name = "out-of-map", position = position })
            else
                table.insert(tiles, { name = tile_proto, position = position })
            end
        end

        surface.set_tiles(tiles)
    end

    procinfo.surface = surface
    storage.surface_map[surface_name] = procinfo
    editor.clean_surface(procinfo)
    return surface
end

---@param procinfo ProcInfo
function editor.clean_surface(procinfo)
    if not procinfo.surface then return end
    for _, entity in ipairs(procinfo.surface.find_entities()) do
        if entity.valid and entity.type ~= "character" then
            if not entity.mine({ raise_destroyed = true }) then
                entity.destroy()
            end
        end
    end
    for _, entity in ipairs(procinfo.surface.find_entities()) do
        if entity.valid and entity.type ~= "character" then
            entity.destroy()
        end
    end
    editor.connect_energy(procinfo)
end

---------------------------------------------------------------

---@param procinfo ProcInfo
function editor.connect_energy(procinfo)
    local processor = procinfo.processor
    local in_pole = procinfo.in_pole
    if not in_pole or not in_pole.valid then
        in_pole = procinfo.surface.create_entity {
            name = prefix .. "-energy_pole",
            position = { EDITOR_SIZE / 2 + 4, 4 },
            force = processor.force
        }
        procinfo.in_pole = in_pole
        in_pole.destructible = false
    end

    local generator = procinfo.generator
    if not generator or not generator.valid then
        generator = procinfo.surface.create_entity {
            name = prefix .. "-energy_source",
            position = { EDITOR_SIZE / 2 + 4, 10 },
            force = processor.force
        }
        procinfo.generator = generator
        generator.destructible = false
    end

    local radar_name = prefix .. "-radar"
    local radar_proto = prototypes.entity[radar_name]
    if radar_proto and procinfo.surface.count_entities_filtered { name = radar_name, limit = 1 } == 0 then
        local radar = procinfo.surface.create_entity {
            name = radar_name,
            position = { EDITOR_SIZE / 2 + 10, 16 },
            force = processor.force
        }
        radar.destructible = false
    end

    -- Old stuff
    local energy_pole = procinfo.energ_pole
    if energy_pole and energy_pole.valid then
        energy_pole.destroy()
        procinfo.energ_pole = nil
    end

    local accu = procinfo.accu
    if accu and accu.valid then
        accu.destroy()
        procinfo.accu = nil
    end
end

---------------------------------------------------------------

---@param player LuaPlayer
function editor.close_iopanel(player)
    local panel = player.gui.screen[iopanel_name]
    if panel then
        tools.get_vars(player).edit_location = panel.location
        panel.destroy()
    end

    panel = player.gui.left[iopanel_name]
    if panel then
        panel.destroy()
    end
end

---------------------------------------------------------------

local display_options = {

    { prefix .. "-dropdown.all" }, { prefix .. "-dropdown.one_line" },
    { prefix .. "-dropdown.none" }
}

---@param player LuaPlayer
---@param entity LuaEntity
function editor.open_iopole(player, entity)
    if not entity or not entity.valid or entity.name ~= internal_iopoint_name then
        return
    end

    ccutils.close_all(player)

    player.opened = nil

    local vars = get_vars(player)
    local procinfo = storage.surface_map and storage.surface_map[entity.surface.name]
    if not procinfo then return end

    local iopoint_info = procinfo.iopoint_infos[entity.unit_number]
    if not iopoint_info then return end

    local ids = {}
    for i = 1, #procinfo.iopoints do table.insert(ids, tostring(i)) end

    vars.iopole = entity

    local outer_frame, frame = tools.create_standard_panel(player, {
        panel_name = iopanel_name,
        title = { prefix .. "-iopanel.title" },
        is_draggable = true,
        create_inner_frame = true,
        close_button_name = prefix .. ".iopole_ok"
    })

    local flow = frame.add { type = "flow", direction = "horizontal" }
    local label1 = flow.add {
        type = "label",
        caption = { label_prefix .. ".iopole_id" }
    }
    label1.style.width = 200
    local combo = flow.add {
        type = "drop-down",
        name = prefix .. ".iopole_index",
        items = ids,
        selected_index = (iopoint_info.index and iopoint_info.index <= #ids) and iopoint_info.index or nil
    }
    combo.style.width = 100

    flow = frame.add { type = "flow", direction = "horizontal" }
    local label2 = flow.add {
        type = "label",
        caption = { label_prefix .. ".iopole_name" }
    }
    label2.style.width = 200
    local name = flow.add {
        type = "textfield",
        name = prefix .. ".iopole_name",
        text = iopoint_info.label,
        icon_selector = true
    }
    flow.style.bottom_margin = 10

    flow = frame.add { type = "flow", direction = "horizontal" }
    flow.style.bottom_margin = 10
    label1 = flow.add {
        type = "label",
        caption = { label_prefix .. ".io_direction" }
    }
    label1.style.width = 200
    local cb = flow.add {
        type = "checkbox",
        caption = { checkbox_prefix .. ".io_input" },
        name = prefix .. ".io_input",
        state = iopoint_info.input == true
    }
    cb.style.right_margin = 20
    flow.add {
        type = "checkbox",
        caption = { checkbox_prefix .. ".io_output" },
        name = prefix .. ".io_output",
        state = iopoint_info.output ~= false
    }

    flow = frame.add { type = "flow", direction = "horizontal" }
    flow.style.bottom_margin = 10
    flow.add { type = "label", caption = { label_prefix .. ".red_display" } }
    flow.add {
        type = "drop-down",
        name = prefix .. ".red_display",
        items = display_options,
        selected_index = iopoint_info.red_display and iopoint_info.red_display +
            1 or 1
    }

    local d = flow.add {
        type = "label",
        caption = { label_prefix .. ".green_display" }
    }
    d.style.left_margin = 10
    flow.add {
        type = "drop-down",
        name = prefix .. ".green_display",
        items = display_options,
        selected_index = iopoint_info.green_display and
            iopoint_info.green_display + 1 or 1
    }

    local edit_location = vars.edit_location
    if edit_location then
        outer_frame.location = edit_location
    else
        outer_frame.force_auto_center()
    end
end

---@param e EventData.on_gui_opened
local function on_gui_open_iopole(e)
    local player = game.players[e.player_index]
    local entity = e.entity
    editor.open_iopole(player, entity)
end

---------------------------------------------------------------

---@param procinfo ProcInfo
---@param iopole LuaEntity
---@return IOPointInfo?
function editor.get_iopoint_info(procinfo, iopole)
    if not iopole.valid then return nil end
    local iopoint_infos = procinfo.iopoint_infos
    local iopoint_info = iopoint_infos[iopole.unit_number]
    if not iopoint_info then
        iopoint_info = {}
        iopoint_infos[iopole.unit_number] = iopoint_info
    end
    return iopoint_info
end

local get_iopoint_info = editor.get_iopoint_info

---------------------------------------------------------------

---@type table<string, boolean>
local iopole_fields = {
    [prefix .. ".iopole_index"] = true,
    [prefix .. ".red_display"] = true,
    [prefix .. ".green_display"] = true

}

---@param e EventData.on_gui_selection_state_changed
local function on_gui_selection_state_changed(e)
    if not e.element then return end

    local name = e.element.name
    if not iopole_fields[name] then return end

    local player = game.players[e.player_index]
    local vars = get_vars(player)

    ---@type LuaEntity
    local iopole = vars.iopole
    if not iopole or not iopole.valid then return end

    ---@type ProcInfo
    local procinfo = vars.procinfo
    local iopole_info = get_iopoint_info(procinfo, iopole)

    if name == prefix .. ".iopole_index" then
        ---@cast iopole_info -nil
        if not procinfo.is_packed then
            build.disconnect_iopole(procinfo, iopole_info)
        end
        iopole_info.index = e.element.selected_index
        if not procinfo.is_packed then
            build.connect_iopole(procinfo, iopole_info)
        end
    elseif name == prefix .. ".red_display" then
        iopole_info.red_display = e.element.selected_index - 1
    elseif name == prefix .. ".green_display" then
        iopole_info.green_display = e.element.selected_index - 1
    end
end

---@param e EventData.on_gui_checked_state_changed(
local function on_gui_checked_state_changed(e)
    if not e.element then return end

    local name = e.element.name
    local player = game.players[e.player_index]
    local vars = get_vars(player)

    ---@type LuaEntity
    local iopole = vars.iopole
    if not (iopole and iopole.valid) then return end

    ---@type ProcInfo
    local procinfo = vars.procinfo
    if not procinfo then return end

    local iopole_info = get_iopoint_info(procinfo, iopole)
    if name == prefix .. ".io_input" then
        iopole_info.input = e.element.state
    elseif name == prefix .. ".io_output" then
        iopole_info.output = e.element.state
    end
end

---------------------------------------------------------------

---@param e EventData.on_gui_text_changed
local function on_gui_text_changed(e)
    if not e.element or not e.element.valid then return end

    local player = game.players[e.player_index]
    local vars = get_vars(player)
    if e.element.name == prefix .. ".iopole_name" then
        local iopole = vars.iopole
        if not iopole or not iopole.valid then return end
        local procinfo = vars.procinfo

        local iopoint_info = get_iopoint_info(procinfo, iopole)
        if not iopoint_info then return end
        iopoint_info.label = e.element.text
        build.update_io_text(iopoint_info)
    elseif e.element.name == prefix .. "-title" then
        local procinfo = vars.procinfo --[[@as ProcInfo]]
        ---@type string | nil
        local text
        text = e.element.text
        if text == '' then text = nil end
        procinfo.label = text
    end
end

---@param e EventData.on_gui_confirmed
local function on_gui_confirmed(e)
    local player = game.players[e.player_index]
    editor.close_iopanel(player)
end


---------------------------------------------------------------

---@param procinfo ProcInfo
function editor.delete_surface(procinfo)
    local surface = procinfo.surface
    if not surface then return end
    if not surface.valid then
        procinfo.surface = nil
        return
    end

    editor.evacuate_surface(surface)
    editor.clean_surface(procinfo)
    storage.surface_map[surface.name] = nil
    game.delete_surface(surface)
    procinfo.surface = nil
end

---@param e EventData.on_pre_surface_deleted
function editor.on_pre_surface_deleted(e)
    local surface = game.surfaces[e.surface_index]
    if not surface or not string.find(surface.name, commons.surface_name_pattern) then return end

    editor.evacuate_surface(surface)

    local procinfo = storage.surface_map and storage.surface_map[surface.name]
    if procinfo == nil then return end

    editor.clean_surface(procinfo)
    storage.surface_map[surface.name] = nil
    procinfo.surface = nil
end

tools.on_event(defines.events.on_pre_surface_deleted,
    editor.on_pre_surface_deleted)

---------------------------------------------------------------

---@param procinfo ProcInfo
function editor.draw_sprite(procinfo)
    local processor = procinfo.processor
    if not (processor and processor.valid) then return end

    if procinfo.sprite_ids then
        for _, id in pairs(procinfo.sprite_ids) do
            if type(id) == "number" then
                local o = rendering.get_object_by_id(id)
                if o then
                    o.destroy()
                end
            else
                id.destroy()
            end
        end
        procinfo.sprite_ids = nil
    end

    if not procinfo.sprite1 and not procinfo.sprite2 then return end

    ---@type number[]
    local ids = {}
    local scale, scale2
    local target_y = -0.07
    if processor.name == commons.processor_name then
        scale = 1.65
        scale2 = 1.2
    else
        scale = 0.85
        scale2 = 0.6
    end

    local sprite1 = ccutils.check_sprite(procinfo.sprite1)
    if sprite1 then
        local id = rendering.draw_sprite {
            surface = processor.surface,
            sprite = sprite1,
            target = {
                offset = { 0, target_y * scale },
                entity = processor
            },
            x_scale = scale,
            y_scale = scale,
            render_layer = "lower-object"
        }
        table.insert(ids, id)
    end

    local sprite2 = ccutils.check_sprite(procinfo.sprite2)
    if sprite2 then
        local id = rendering.draw_sprite {
            surface = processor.surface,
            sprite = sprite2,
            target = {
                offset = { 0, target_y * scale },
                entity = processor
            },
            x_scale = scale2,
            y_scale = scale2,
            render_layer = "lower-object"
        }
        table.insert(ids, id)
    end

    procinfo.sprite_ids = ids
end

---------------------------------------------------------------

---@param e EventData.on_player_changed_surface
local function on_player_changed_surface(e)
    local player = game.players[e.player_index]
    local vars = get_vars(player)
    local procinfo = vars.procinfo

    local is_standard_exit = vars.is_standard_exit
    vars.is_standard_exit = false

    if procinfo and not (procinfo.processor and procinfo.processor.valid) then
        close_editor_guis(player)
        if vars.origins then vars.origins[procinfo.unit_number] = nil end
        vars.procinfo = nil
        vars.processor = nil
        procinfo = nil
    end

    ---@param leaving ProcInfo
    local function leave_procinfo(leaving)
        if vars.origins then vars.origins[leaving.unit_number] = nil end
        leaving.tick = game.tick
        build.save_packed_circuits(leaving)
        if (leaving.is_packed) then
            if is_standard_exit then
                -- Keep the surface while other players are still editing it
                if not has_other_players(leaving.surface, player) then
                    editor.delete_surface(leaving)
                    local _, recursionError = build.create_packed_circuit(leaving)
                    input.apply_parameters(leaving)
                    if recursionError then
                        player.print {
                            message_prefix .. ".recursion_error", recursionError
                        }
                    end
                end
            else
                editor.set_packed(leaving, false)
            end
        else
            build.create_unpacked_proxies(leaving)
        end
    end

    -- Exiting surface
    if procinfo and procinfo.surface and procinfo.surface.valid and
        procinfo.surface.index == e.surface_index then
        close_editor_guis(player)

        player.opened = nil
        vars.procinfo = nil
        vars.processor = nil
        leave_procinfo(procinfo)

        -- Also leave the enclosing processors the player skipped (exit to origin)
        local parent = procinfo
        while true do
            local processor = parent.processor
            if not (processor and processor.valid) then break end
            parent = storage.surface_map[processor.surface.name]
            if not parent or not (vars.origins and vars.origins[parent.unit_number]) then break end
            if not (parent.surface and parent.surface.valid) or
                parent.surface.index == player.surface_index then
                break
            end
            leave_procinfo(parent)
        end
    end

    local surface_name = player.surface.name
    procinfo = storage.surface_map[surface_name]
    if procinfo then
        vars.procinfo = procinfo
        vars.processor = procinfo.processor
        editor.create_editor_panel(player, procinfo)
    end
end

---------------------------------------------------------------

---@param e EventData.on_gui_click
tools.on_gui_click(prefix .. ".iopole_ok", function(e)
    local player = game.players[e.player_index]
    editor.close_iopanel(player)
end)

tools.on_event(defines.events.on_gui_opened, on_gui_open_iopole)
tools.on_event(defines.events.on_gui_confirmed, on_gui_confirmed)
tools.on_event(defines.events.on_gui_selection_state_changed,
    on_gui_selection_state_changed)
tools.on_event(defines.events.on_gui_checked_state_changed,
    on_gui_checked_state_changed)
tools.on_event(defines.events.on_gui_text_changed, on_gui_text_changed)
tools.on_event(defines.events.on_player_changed_surface,
    on_player_changed_surface)

--------------------------------------------------------------------------------------

---@param procinfo ProcInfo
---@return table<integer, IOPointInfo>
local function get_iopoint_map(procinfo)
    local map = {}
    for _, iopoint_info in pairs(procinfo.iopoint_infos) do
        if iopoint_info.index then map[iopoint_info.index] = iopoint_info end
    end
    return map
end

---@param procinfo ProcInfo
---@return integer
local function find_iopoint_index(procinfo)
    local map = get_iopoint_map(procinfo)
    for i = 1, #procinfo.iopoints do if not map[i] then return i end end
    return 1
end

---@param procinfo ProcInfo
---@param index integer
---@return integer
local function check_ipoint_index(procinfo, index)
    if storage.surface_restoring then return index end

    local map = get_iopoint_map(procinfo)
    if index then
        if index > #procinfo.iopoints then index = 1 end
        if not map[index] then return index end
    end
    for i = 1, #procinfo.iopoints do if not map[i] then return i end end
    return 1
end


---@param entity LuaEntity
---@param tags Tags
---@param procinfo ProcInfo
local function init_internal_point(entity, tags, procinfo)
    ---@type IOPointInfo
    local circuit = { label = "" }
    if tags then
        local iotags = tags --[[@as IOPointInfo ]]
        circuit.label = iotags.label
        circuit.index = check_ipoint_index(procinfo, iotags.index)
        circuit.input = iotags.input
        circuit.output = iotags.output
        circuit.red_display = iotags.red_display
        circuit.green_display = iotags.green_display
    else
        circuit.index = find_iopoint_index(procinfo)
    end
    local iopoint_info = build.create_iopoint(procinfo, entity, circuit)
    build.update_io_text(iopoint_info)
end

editor.init_internal_point = init_internal_point


---@param player_index integer?
---@param text LocalisedString
---@param position MapPosition?
local function fly_text(player_index, text, position)
    if not player_index then return end

    local player = game.players[player_index]
    player.create_local_flying_text {
        text = text,
        create_at_cursor = not position and true,
        position = position,
        color = { r = 1.0, a = 0.5 },
        speed = 40
    }
end

local ghost_classes = {
    [internal_iopoint_name]   = true,
    [internal_connector_name] = true,
    [display_name]            = true,
    [input_name]              = true

}

local function refresh_unpacked_proxies(procinfo)
    if procinfo and not procinfo.is_packed then
        build.create_unpacked_proxies(procinfo)
    end
end

---@param entity LuaEntity
---@param e EventData.on_robot_built_entity | EventData.script_raised_built | EventData.on_built_entity | EventData.script_raised_revive
local function on_build(entity, e)
    if not entity or not entity.valid then return end

    local name = entity.name
    local procinfo = storage.surface_map and storage.surface_map[entity.surface.name]
    if not procinfo then
        return
    end

    local tags = e.tags
    if not tags then
        -- on_built_entity has no 'stack' (2.x): look at consumed items
        local consumed_items = e.consumed_items
        if consumed_items and consumed_items.valid then
            for i = 1, #consumed_items do
                local stack = consumed_items[i]
                if stack.valid_for_read and stack.is_item_with_tags then
                    local stack_tags = stack.tags
                    if stack_tags and next(stack_tags) then
                        tags = stack_tags
                        break
                    end
                end
            end
        end
    end
    if not tags then
        local stack = e.stack
        if stack and stack.valid_for_read and stack.is_item_with_tags then
            tags = stack.tags
        end
    end
    if tags then
        if tags.__ then tags = tags.__ end
        if tags.__delete then
            entity.destroy()
            return
        end
    end

    if name == display_name then
        if tags then
            display.register(entity, tags --[[@as Display]])
        end
    elseif name == "display-panel" then
        refresh_unpacked_proxies(procinfo)
    elseif name == input_name then
        if not IsProcessorRebuilding and tags then
            tags.value_id = tools.get_id()
        elseif tags then
            tools.upgrade_id(tags.value_id)
        end
        input.register(entity, tags --[[@as Input]])
    elseif name == internal_iopoint_name then
        init_internal_point(entity, tags, procinfo)
    elseif name == internal_connector_name then
        entity.operable = false
    elseif name == "entity-ghost" and is_allowed(entity.ghost_name) then
        if ghost_classes[entity.ghost_name] then
            local d, new = entity.silent_revive { raise_revive = true }
        else
            if e.player_index then
                local player = game.players[e.player_index]
                if commons.remote_controllers[player.controller_type] then
                    entity.revive { raise_revive = true }
                end
            end
        end
    elseif procinfo and not is_allowed(name) then
        if settings.global[prefix .. "-allow-external"].value then
            if procinfo.is_packed then
                fly_text(e.player_index, { message_prefix .. ".not_allowed_packed" }, entity.position)
            end
            return
        else
            fly_text(e.player_index, { message_prefix .. ".not_allowed" }, entity.position)
        end
        if not storage.destroy_list then
            storage.destroy_list = { entity }
        else
            table.insert(storage.destroy_list, entity)
        end
    end
end

---@param entity LuaEntity
local function destroy_invalid(entity)
    local m = entity.prototype.mineable_properties
    local position = entity.position
    local surface = entity.surface
    local force = entity.force --[[@as LuaForce]]
    if not entity.mine { raise_destroyed = true, ignore_minable = true } then
        entity.destroy()
    end
    if m.minable and m.products then
        for _, p in pairs(m.products) do
            surface.spill_item_stack { position = position,
                stack = { name = p.name, count = p.amount },
                enable_looted = true,
                force = force }
        end
    end
end

tools.on_nth_tick(5, function()
    if not storage.destroy_list then return end
    for _, entity in ipairs(storage.destroy_list) do
        if entity.valid then destroy_invalid(entity) end
    end
    storage.destroy_list = nil
end)

---@param ev EventData.on_robot_built_entity
local function on_robot_built(ev)
    local entity = ev.entity

    on_build(entity, ev)
end

---@param ev EventData.script_raised_built
local function on_script_built(ev)
    local entity = ev.entity

    on_build(entity, ev)
end

---@param ev EventData.script_raised_revive
local function on_script_revive(ev)
    local entity = ev.entity

    on_build(entity, ev)
end

---@param ev EventData.on_built_entity
local function on_player_built(ev)
    local entity = ev.entity

    on_build(entity, ev)
end

local class_to_save = {
    [input_name] = true,
    [display_name] = true,
    [internal_iopoint_name] = true
}

---@param e EventData.on_marked_for_deconstruction
local function on_marked_for_deconstruction(e)
    local player_index = e.player_index
    if not player_index then return end

    local player = game.players[e.player_index]
    local entity = e.entity
    local procinfo = storage.surface_map and storage.surface_map[entity.surface.name]
    if not procinfo then return end

    if not entity.valid then return end

    local name = entity.name
    local need_mining = false

    if name == "display-panel" then
        refresh_unpacked_proxies(procinfo)
    end

    if e.player_index then
        if name == internal_iopoint_name then
            editor.save_undo_tags(e.player_index, entity.position, build.get_internal_iopoint_tags(entity))
            need_mining = true
        elseif name == input_name then
            local tags = input.get_tags(entity)
            editor.save_undo_tags(e.player_index, entity.position, tags)
            need_mining = true
        elseif name == display_name then
            local tags = display.get_tags(entity)
            editor.save_undo_tags(e.player_index, entity.position, tags)
            need_mining = true
        elseif name == commons.internal_connector_name then
            need_mining = true
        elseif commons.processor_names[name] then
            return
        end
    end

    if entity.valid and (commons.remote_controllers[player.controller_type] or need_mining) then
        if entity.name == internal_iopoint_name then
            editor.destroy_internal_iopoint(entity)
        end
        entity.mine { raise_destroyed = true }
    end
end

---@param e EventData.on_cancelled_deconstruction
local function on_cancelled_deconstruction(e)
    local entity = e.entity
    if not entity or not entity.valid then return end
    if entity.name ~= "display-panel" then return end

    local procinfo = storage.surface_map and storage.surface_map[entity.surface.name]
    refresh_unpacked_proxies(procinfo)
end

tools.on_event(defines.events.on_built_entity, on_player_built)
tools.on_event(defines.events.on_robot_built_entity, on_robot_built)
tools.on_event(defines.events.script_raised_built, on_script_built)
tools.on_event(defines.events.script_raised_revive, on_script_revive)
tools.on_event(defines.events.on_marked_for_deconstruction,
    on_marked_for_deconstruction)
tools.on_event(defines.events.on_cancelled_deconstruction,
    on_cancelled_deconstruction)

--------------------------------------------------------------------------------------

local filter_names = { {} }

---@type string[]
local surface_name_filter = {
    "constant-combinator", "decider-combinator", "arithmetic-combinator", "selector-combinator",
    "display-panel",
    "big-electric-pole", "small-electric-pole", "medium-electric-pole",
    "substation", internal_iopoint_name, "small-lamp"
}

for name, _ in pairs(textplate_map) do table.insert(surface_name_filter, name) end

---------------------------------------------------------------

---@param entity LuaEntity
function editor.destroy_internal_iopoint(entity)
    if not entity.valid then return end

    ---@type ProcInfo
    local procinfo = storage.surface_map[entity.surface.name]
    if not procinfo then return end

    procinfo.iopoint_infos[entity.unit_number] = nil
    tools.close_ui(entity.unit_number, editor.close_iopanel, "iopole")
end

local function on_mined(ev)
    local entity = ev.entity
    local procinfo = storage.surface_map and storage.surface_map[entity.surface.name]
    if entity.name == "display-panel" then
        refresh_unpacked_proxies(procinfo)
    elseif entity.name == internal_iopoint_name then
        if ev.player_index then
            editor.save_undo_tags(ev.player_index, entity.position, build.get_internal_iopoint_tags(entity))
        end
        editor.destroy_internal_iopoint(entity)
        if ev.buffer then ev.buffer.clear() end
    elseif entity.name == internal_connector_name then
        if ev.buffer then ev.buffer.clear() end
    elseif entity.name == display_name then
        if ev.buffer then ev.buffer.clear() end
        if ev.player_index then
            local tags = display.get_tags(entity)
            editor.save_undo_tags(ev.player_index, entity.position, tags)
        end
        display.mine(entity)
    elseif entity.name == input_name then
        if ev.buffer then ev.buffer.clear() end
        if ev.player_index then
            local tags = input.get_tags(entity)
            editor.save_undo_tags(ev.player_index, entity.position, tags)
        end
        input.mine(entity)
    end
end

---@param ev EventData.on_player_mined_entity|EventData.on_robot_mined_entity|EventData.on_entity_died|EventData.script_raised_destroy
local function on_player_mined_entity(ev)
    on_mined(ev)
end

---@param e EventData.on_gui_closed
local function on_gui_closed(e)
    local entity = e.entity
    if not entity or not entity.valid then return end
    if entity.name ~= "display-panel" then return end

    local procinfo = storage.surface_map and storage.surface_map[entity.surface.name]
    if procinfo and not procinfo.is_packed then
        build.create_unpacked_proxies(procinfo)
    end
end

---@param e EventData.on_entity_settings_pasted
local function on_entity_settings_pasted(e)
    local destination = e.destination
    if not destination or not destination.valid then return end
    if destination.name ~= "display-panel" then return end

    local procinfo = storage.surface_map and storage.surface_map[destination.surface.name]
    if procinfo and not procinfo.is_packed then
        build.create_unpacked_proxies(procinfo)
    end
end

local mine_filter = {
    { filter = 'name', name = "display-panel" },
    { filter = 'name', name = internal_iopoint_name },
    { filter = 'name', name = internal_connector_name },
    { filter = 'name', name = display_name },
    { filter = 'name', name = input_name }
}
tools.on_event(defines.events.on_player_mined_entity, on_player_mined_entity, mine_filter)
tools.on_event(defines.events.on_robot_mined_entity, on_mined, mine_filter)
tools.on_event(defines.events.on_entity_died, on_mined, mine_filter)
tools.on_event(defines.events.script_raised_destroy, on_mined, mine_filter)
tools.on_event(defines.events.on_gui_closed, on_gui_closed)
tools.on_event(defines.events.on_entity_settings_pasted, on_entity_settings_pasted)

---@type table<string, boolean>
local forbidden_prototypes = {

    ["container"] = true,
    ["logistic-container"] = true,
    ["assembling-machine"] = false, -- Recipe Combinator is implemented as an assembling machine - https://mods.factorio.com/mod/lo-recipe-combinator - but it tested to work fine if allow it!
    ["boiler"] = true,
    ["transport-belt"] = true,
    ["underground-belt"] = true,
    ["splitter"] = true,
    ["loader"] = true,
    ["loader-1x1"] = true,
    ["pipe"] = true,
    ["pipe-to-ground"] = true,
    ["rail"] = true
}

---@param driver RemoteInterface
function editor.add_combinator(driver)
    if not driver or not driver.name or remote_name_map[driver.name] then return end

    local proto = prototypes.entity[driver.name]
    if not proto or forbidden_prototypes[proto.type] then return end

    remote_name_map[driver.name] = driver
    table.insert(surface_name_filter, driver.name)
    local packed_names = driver.packed_names
    if packed_names then
        for _, name in ipairs(packed_names) do
            table.insert(commons.packed_entities, name)
            table.insert(commons.entities_to_destroy, name)
        end
    end
end

---@param name string
function editor.remove_combinator(name)
    local driver = remote_name_map[name]
    if not driver then return end

    remote_name_map[name] = nil
    for i, n in ipairs(surface_name_filter) do
        if n == name then
            table.remove(surface_name_filter, i)
            break
        end
    end

    local packed_names = driver.packed_names
    if packed_names then
        for _, np in ipairs(packed_names) do
            for i, n in ipairs(commons.packed_entities) do
                if n == np then
                    table.remove(commons.packed_entities, i)
                    break
                end
            end
            for i, n in ipairs(commons.entities_to_destroy) do
                if n == np then
                    table.remove(commons.entities_to_destroy, i)
                    break
                end
            end
        end
    end
end

remote.add_interface(prefix, {
    add_combinator = editor.add_combinator,
    remove_combinator = editor.remove_combinator
})

--[[
    Remote fields:

        name: string, entity name

        packed_names: string[] , liste of entities used in packed mode

        interface_name : name of reverse interface

    Reverse interface:

        get_info(entity) : add private information on entities
            return {a structure containing private information}
            reserved fields:
                name,  index, position, direction

        create_packed_entity(info, surface, position, force)
            create a packed entity from 'info' structure'

        create_entity(info, surface, force)
            create a normal entity from information
            (position, direction, name) is in 'info' structure

--]]

---@param player_index integer
---@param pos MapPosition
---@param tags Tags
function editor.save_undo_tags(player_index, pos, tags)
end

return editor
