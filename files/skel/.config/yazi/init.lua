--Header:children_add(function()
--	if ya.target_family() ~= "unix" then
--		return ""
--	end
--	return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("blue")
--end, 500, Header.LEFT)

function Linemode:size_and_mtime()
	local time = math.floor(self._file.cha.mtime or 0)
	if time == 0 then
		time = ""
	elseif os.date("%Y", time) == os.date("%Y") then
		time = os.date("%d %b~%H:%M", time)
	else
		time = os.date("%d %b %Y ", time)
	end

	local size = self._file:size()
	if size then
		size = ya.readable_size(size)
	else
		local folder = cx.active:history(self._file.url)
		size = folder and tostring(#folder.files) or ""
	end
	
	return string.format("%s - %s", size, time)
end

Status:children_add(function()
	local h = cx.active.current.hovered
	if h == nil or ya.target_family() ~= "unix" then
		return ""
	end

	return ui.Line {
		ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
		":",
		ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
		" ",
	}
end, 500, Status.RIGHT)

require("full-border"):setup {
	-- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
	type = ui.Border.ROUNDED,
}
require("smart-enter"):setup {
	open_multi = true,
}

require("folder-rules"):setup()

--require("eza-preview"):setup({level = 1,follow_symlinks = true})
require("git"):setup()
--require("starship"):setup()
require("archivemount"):setup()

require("yatline"):setup({
	--theme = my_theme,
	section_separator = { open = "", close = "" },
	part_separator =    { open = "", close = "" },
	inverse_separator = { open = "", close = "" },

	style_a = {
		fg = "black",
		bg_mode = {
			normal = "#fab387",
			select = "brightyellow",
			un_set = "brightred"
		}
	},
	style_b = { bg = "brightblack", fg = "brightwhite" },
	style_c = { bg = "black", fg = "brightwhite" },

	permissions_t_fg = "green",
	permissions_r_fg = "yellow",
	permissions_w_fg = "red",
	permissions_x_fg = "cyan",
	permissions_s_fg = "white",

	tab_width = 20,
	tab_use_inverse = false,

	selected = { icon = "󰻭", fg = "yellow" },
	copied = { icon = "", fg = "green" },
	cut = { icon = "", fg = "red" },

	total = { icon = "󰮍", fg = "yellow" },
	succ = { icon = "", fg = "green" },
	fail = { icon = "", fg = "red" },
	found = { icon = "󰮕", fg = "blue" },
	processed = { icon = "󰐍", fg = "green" },

	show_background = false,

	display_header_line = true,
	display_status_line = true,

	component_positions = { "header", "tab", "status" },

	header_line = {
		left = {
			section_a = {
        			{type = "line", custom = false, name = "tabs", params = {"left"}},
			},
			section_b = {
			},
			section_c = {
			}
		},
		right = {
			section_a = {
					{type = "string", custom = false, name = "cursor_position"},
			},
			section_b = {
					{type = "coloreds", custom = false, name = "githead"},
			},
			section_c = {
			}
		}
	},

	status_line = {
		left = {
			section_a = {
        			{type = "string", custom = false, name = "tab_mode"},
			},
			section_b = {
        			{type = "coloreds", custom = false, name = "task_states"},
        			{type = "coloreds", custom = false, name = "task_workload"},
        			{type = "coloreds", custom = false, name = "count"},
			},
			section_c = {
        			{type = "string", custom = false, name = "hovered_size"},
			}
		},
		right = {
			section_a = {
        			{type = "string", custom = false, name = "hovered_ownership"},
			},
			section_b = {
        			{type = "coloreds", custom = false, name = "permissions"},
			},
			section_c = {
        			{type = "string", custom = false, name = "hovered_file_extension", params = {true}},
--        			{type = "string", custom = false, name = "hovered_mime"},
			}
		}
	},
})
require("yatline-githead"):setup()








