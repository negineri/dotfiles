-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
config.font = wezterm.font 'PlemolJP Console NF'

config.color_schemes = {
    ['Default Dark Modern (VSCode)'] = {
        foreground = "#cccccc",
        background = "#1f1f1f",
        cursor_bg = "#cccccc",
        cursor_border = "#cccccc",
        cursor_fg = "#aeafad",
        selection_bg = "rgba(38,79,120,50%)",
        selection_fg = "none",

        -- ansi["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]
        -- brights["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]
        ansi = { "#000000", "#cd3131", "#0dbc79", "#e5e510", "#2472c8", "#bc3fbc", "#11a8cd", "#e5e5e5", },
        brights = { "#666666", "#f14c4c", "#23d18b", "#f5f543", "#3b8eea", "#d670d6", "#29b8db", "#e5e5e5", },
    },
    ['Default Light Modern (VSCode)'] = {
        foreground = "#3b3b3b",
        background = "#ffffff",
        cursor_bg = "#005fb8",
        cursor_border = "#005fb8",
        cursor_fg = "#ffffff",
        selection_bg = "rgba(173,214,255,50%)",
        selection_fg = "none",

        -- ansi["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]
        -- brights["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]
        ansi = { "#000000", "#cd3131", "#00bc00", "#949800", "#0451a5", "#bc05bc", "#0598bc", "#555555", },
        brights = { "#666666", "#cd3131", "#14ce14", "#b5ba00", "#0451a5", "#bc05bc", "#0598bc", "#a5a5a5", },
    },
}

-- wezterm.gui is not available to the mux server, so take care to
-- do something reasonable when this config is evaluated by the mux
function get_appearance()
    if wezterm.gui then
        return wezterm.gui.get_appearance()
    end
    return 'Dark'
end
  
function scheme_for_appearance(appearance)
    if appearance:find 'Dark' then
        return 'Default Dark Modern (VSCode)'
    else
        return 'Default Light Modern (VSCode)'
    end
end

config.color_scheme = scheme_for_appearance(get_appearance())

config.send_composed_key_when_left_alt_is_pressed = true

-- For example, changing the color scheme:
-- config.color_scheme = 'AdventureTime'

-- and finally, return the configuration to wezterm
return config
