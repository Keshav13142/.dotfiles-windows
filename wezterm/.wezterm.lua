local wezterm = require("wezterm")
local act = wezterm.action

-- Maximize screen on startup
-- wezterm.on("gui-startup", function()
-- 	local _, _, window = wezterm.mux.spawn_window({})
-- 	window:gui_window():maximize()
-- end)

-- Status bar right info
wezterm.on("update-right-status", function(window, pane)
	local cwd = " " .. pane:get_current_working_dir():sub(8) .. " " -- remove file:// uri prefix
	local date = wezterm.strftime(" %A, %B %-d, %I:%M %p ")
	local hostname = " " .. wezterm.hostname() .. " "

	window:set_right_status(wezterm.format({
		{ Foreground = { Color = "#928374" } },
		{ Text = cwd },
		{ Text = "|" },
		{ Text = date },
		{ Text = "|" },
		{ Text = hostname },
	}))
end)

return {
	default_prog = { "pwsh", "-nologo" },

	-- WSL
	-- default_domain = "WSL:Ubuntu-22.04",
	wsl_domains = {
		{
			name = "WSL:Ubuntu-22.04",
			distribution = "Ubuntu-22.04",
			username = "keshav",
			default_cwd = "~",
		},
	},

	-- Fonts
	font = wezterm.font({
		family = "JetBrainsMono Nerd Font Mono",
	}),
	font_size = 14,

	-- Tab bar
	hide_tab_bar_if_only_one_tab = true,
	show_new_tab_button_in_tab_bar = false,
	show_tabs_in_tab_bar = true,
	tab_bar_at_bottom = true,
	use_fancy_tab_bar = false,

	-- General
	audible_bell = "Disabled",
	pane_focus_follows_mouse = true,
	automatically_reload_config = true,
	exit_behavior = "Close",
	force_reverse_video_cursor = true,
	scrollback_lines = 10000,
	show_update_window = true,
	use_dead_keys = false,

	-- Window
	adjust_window_size_when_changing_font_size = false,
	window_background_opacity = 0.95,
	window_close_confirmation = "NeverPrompt",
	window_padding = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	},

	-- Colors
	colors = {
		background = "#000000",
		tab_bar = {
			background = "#141617",

			active_tab = {
				bg_color = "#282828",
				fg_color = "#d4be98",
				intensity = "Bold",
				underline = "None",
				italic = true,
				strikethrough = false,
			},

			inactive_tab = {
				bg_color = "#1d2021",
				fg_color = "#7c6f64",
				intensity = "Half",
				underline = "None",
				italic = false,
				strikethrough = false,
			},

			inactive_tab_hover = {
				bg_color = "#32302f",
				fg_color = "#909090",
				italic = true,
			},
		},
	},
	color_scheme = "Gruvbox Dark (Gogh)",

	-- Keymaps
	disable_default_key_bindings = false,
	leader = { key = " ", mods = "CTRL", timeout_milliseconds = 1000 },
	keys = {
		-- Splits
		{
			key = "|",
			mods = "LEADER|SHIFT",
			action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
		},
		{
			key = '"',
			mods = "LEADER|SHIFT",
			action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
		},

		-- Open command pallete
		{
			key = "p",
			mods = "CTRL|SHIFT",
			action = act.ActivateCommandPalette,
		},

		-- Enter copy mode
		{ key = "v", mods = "LEADER", action = act.ActivateCopyMode },

		-- Navigate tabs
		{ key = "1", mods = "CTRL", action = act.ActivateTab(0) },
		{ key = "2", mods = "CTRL", action = act.ActivateTab(1) },
		{ key = "3", mods = "CTRL", action = act.ActivateTab(2) },
		{ key = "4", mods = "CTRL", action = act.ActivateTab(3) },
		{ key = "5", mods = "CTRL", action = act.ActivateTab(4) },
		{ key = "6", mods = "CTRL", action = act.ActivateTab(5) },
		{ key = "[", mods = "CTRL", action = act.ActivateTabRelative(-1) },
		{ key = "]", mods = "CTRL", action = act.ActivateTabRelative(1) },

		-- Resize panes
		{
			key = "h",
			mods = "CTRL|SHIFT",
			action = act.AdjustPaneSize({ "Left", 5 }),
		},
		{
			key = "l",
			mods = "CTRL|SHIFT",
			action = act.AdjustPaneSize({ "Right", 5 }),
		},
		{
			key = "j",
			mods = "CTRL|SHIFT",
			action = act.AdjustPaneSize({ "Down", 5 }),
		},
		{
			key = "K",
			mods = "CTRL|SHIFT",
			action = act.AdjustPaneSize({ "Up", 5 }),
		},

		-- Focus panes
		{
			key = "h",
			mods = "CTRL",
			action = act.ActivatePaneDirection("Left"),
		},
		{
			key = "l",
			mods = "CTRL",
			action = act.ActivatePaneDirection("Right"),
		},
		{
			key = "k",
			mods = "CTRL",
			action = act.ActivatePaneDirection("Up"),
		},
		{
			key = "j",
			mods = "CTRL",
			action = act.ActivatePaneDirection("Down"),
		},

		-- Move pane to new tab
		{
			key = "n",
			mods = "LEADER",
			action = wezterm.action_callback(function(_, pane)
				local _, _ = pane:move_to_new_tab()
			end),
		},

		-- Copy/Paste
		{ action = act.CopyTo("Clipboard"), mods = "CTRL|SHIFT", key = "C" },
		{ action = act.PasteFrom("Clipboard"), mods = "CTRL|SHIFT", key = "V" },

		-- Open new tab
		{
			key = "c",
			mods = "LEADER",
			action = act.SpawnTab("CurrentPaneDomain"),
		},

		-- Close stuff
		{
			key = "q",
			mods = "LEADER",
			action = act.CloseCurrentPane({ confirm = true }),
		},
		{
			key = "w",
			mods = "CTRL|SHIFT",
			action = act.CloseCurrentTab({ confirm = true }),
		},

		-- Cycle through tabs
		{ key = "{", mods = "CTRL|SHIFT", action = act.MoveTabRelative(-1) },
		{ key = "}", mods = "CTRL|SHIFT", action = act.MoveTabRelative(1) },

		-- Font stuff
		{ action = act.DecreaseFontSize, mods = "CTRL", key = "-" },
		{ action = act.IncreaseFontSize, mods = "CTRL", key = "=" },
		{ action = act.ResetFontSize, mods = "CTRL", key = "0" },

		-- Full screen
		{ action = act.Nop, mods = "ALT", key = "Enter" },
		{ action = act.ToggleFullScreen, key = "F11" },
		{ action = act.ToggleFullScreen, mods = "ALT", key = "f" },
	},

	-- https://github.com/keshav13142
	mouse_bindings = {
		-- Ctrl-click will open the link under the mouse cursor
		{
			event = { Up = { streak = 1, button = "Left" } },
			mods = "CTRL",
			action = wezterm.action.OpenLinkAtMouseCursor,
		},
	},
}
