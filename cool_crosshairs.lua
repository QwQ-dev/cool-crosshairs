---@diagnostic disable: undefined-global

--- BY QWQ-DEV (https://github.com/QwQ-dev) AND KNF7

local ui_get, ui_set = ui.get, ui.set
local entity_get_local_player = entity.get_local_player
local entity_get_player_weapon = entity.get_player_weapon
local entity_get_prop = entity.get_prop
local entity_is_alive = entity.is_alive

local globals_frametime = globals.frametime
local client_screen_size = client.screen_size
local renderer_gradient = renderer.gradient

local clamp = function(v, min, max)
    local num = v

    num = num < min and min or num
    num = num > max and max or num

    return num
end

-- UI references for Custom scope lines
local scope_overlay = ui.reference('VISUALS', 'Effects', 'Remove scope overlay')
local master_switch = ui.new_checkbox('Visuals', 'Effects', 'Enable Custom Crosshairs')
local num_crosshairs_slider = ui.new_slider('Visuals', 'Effects', 'Number of Crosshairs', 1, 10, 2) -- Default to 2, max 10

-- Each crosshair's attributes
local crosshairs = {}
for i = 1, 10 do
    crosshairs[i] = {
        color_picker = ui.new_color_picker('Visuals', 'Effects', 'Crosshair ' .. i .. ' Color', 255, 255, 255, 255),
        overlay_position = ui.new_slider('Visuals', 'Effects', 'Crosshair ' .. i .. ' Position', 0, 500, 250),
        overlay_offset = ui.new_slider('Visuals', 'Effects', 'Crosshair ' .. i .. ' Offset', 0, 500, 15),
        fade_time = ui.new_slider('Visuals', 'Effects', 'Crosshair ' .. i .. ' Fade Time', 4, 20, 12, true, 'fr', 1, { [4] = 'Off' })
    }
end

local global_alphas = {}

-- Initialize the global_alphas array to avoid nil values
for i = 1, 10 do
    global_alphas[i] = 0
end

-- Function to paint the UI for crosshairs
local g_paint_ui = function()
    ui_set(scope_overlay, true)
end

-- Function to paint the custom crosshairs
local g_paint = function()
    local num_crosshairs = ui_get(num_crosshairs_slider)
    local width, height = client_screen_size()

    -- Get the player's current weapon and state
    local me = entity_get_local_player()
    local wpn = entity_get_player_weapon(me)
    local scope_level = entity_get_prop(wpn, 'm_zoomLevel')
    local scoped = entity_get_prop(me, 'm_bIsScoped') == 1
    local resume_zoom = entity_get_prop(me, 'm_bResumeZoom') == 1
    local is_valid = entity_is_alive(me) and wpn ~= nil and scope_level ~= nil

    -- Update alpha for all crosshairs
    for i = 1, num_crosshairs do
        -- Ensure that global_alphas[i] is initialized before using it
        if global_alphas[i] == nil then
            global_alphas[i] = 0
        end

        local fade_time = ui_get(crosshairs[i].fade_time)
        local FT = fade_time > 4 and (globals_frametime() * fade_time) or 1

        -- Update global alpha for each crosshair
        if is_valid and scope_level > 0 and scoped and not resume_zoom then
            global_alphas[i] = clamp(global_alphas[i] + FT, 0, 1)
        else
            global_alphas[i] = clamp(global_alphas[i] - FT, 0, 1)
        end

        local offset = ui_get(crosshairs[i].overlay_offset)
        local initial_position = ui_get(crosshairs[i].overlay_position)
        local color = { ui_get(crosshairs[i].color_picker) }

        -- Render the crosshair
        renderer_gradient(width / 2 - initial_position, height / 2, initial_position - offset, 1, 
            color[1], color[2], color[3], 0, color[1], color[2], color[3], global_alphas[i] * color[4], true)
        renderer_gradient(width / 2 + offset, height / 2, initial_position - offset, 1, 
            color[1], color[2], color[3], global_alphas[i] * color[4], color[1], color[2], color[3], 0, true)

        renderer_gradient(width / 2, height / 2 - initial_position, 1, initial_position - offset, 
            color[1], color[2], color[3], 0, color[1], color[2], color[3], global_alphas[i] * color[4], false)
        renderer_gradient(width / 2, height / 2 + offset, 1, initial_position - offset, 
            color[1], color[2], color[3], global_alphas[i] * color[4], color[1], color[2], color[3], 0, false)
    end

    ui_set(scope_overlay, false)
end

-- Function to update crosshair UI visibility based on selected number of crosshairs
local function update_crosshairs_visibility()
    local num_crosshairs = ui_get(num_crosshairs_slider)
    
    -- Hide extra crosshairs based on the selected number
    for i = 1, 10 do
        if i <= num_crosshairs then
            -- Show the crosshair configuration options for the first 'num_crosshairs' number
            ui.set_visible(crosshairs[i].color_picker, true)
            ui.set_visible(crosshairs[i].overlay_position, true)
            ui.set_visible(crosshairs[i].overlay_offset, true)
            ui.set_visible(crosshairs[i].fade_time, true)
        else
            -- Hide the remaining crosshair configuration options
            ui.set_visible(crosshairs[i].color_picker, false)
            ui.set_visible(crosshairs[i].overlay_position, false)
            ui.set_visible(crosshairs[i].overlay_offset, false)
            ui.set_visible(crosshairs[i].fade_time, false)
        end
    end
end

-- UI callback to handle the master switch and update crosshairs visibility
local ui_callback = function()
    local master_switch_state = ui_get(master_switch)

    -- Register callbacks based on master switch state
    if master_switch_state then
        client.set_event_callback('paint_ui', g_paint_ui)
        client.set_event_callback('paint', g_paint)
    else
        client.unset_event_callback('paint_ui', g_paint_ui)
        client.unset_event_callback('paint', g_paint)
    end

    -- Update crosshair visibility when the master switch or number of crosshairs changes
    update_crosshairs_visibility()
end

-- Register the callback for the master switch and the number of crosshairs slider
ui.set_callback(master_switch, ui_callback)
ui.set_callback(num_crosshairs_slider, function()
    ui_callback()
end)

-- Initial call to ensure proper state
ui_callback()
