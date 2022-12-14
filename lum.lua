--[[
MIT License

Copyright (c) 2022 kooshie

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

--[[
 TODO:
 - Implement `gum spin` with function [DONE]
 - Add support for Windows
]]

--[[ Start ]]--

--- @class lum
--[[
The lum module
]]
local lum = {}

--[[ Misc. ]]--

local os_execute
	= os.execute
local io_popen, io_write
	= io.popen, io.write
local table_insert, table_concat, table_pack, table_unpack
	= table.insert, table.concat, table.pack, table.unpack

local function table_copy(orig)
	-- Src: http://lua-users.org/wiki/CopyTable
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in pairs(orig) do
			copy[orig_key] = orig_value
		end
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

local function iswindows()
	return type(package) == 'table' and type(package.config) == 'string' and package.config:sub(1, 1) == '\\'
end

--[[ API ]]--

local gum_option = {
	join = {
		horizontal = "--horizontal",
		vertical = "--vertical",
		align = "--align",
	},
	confirm = {
		affirmative = "--affirmative",
		negative = "--negative",
		timeout = "--timeout"
	},
	spin = {
		spinner = "--spinner",
		title = "--title",
		align = "--align",

		spinner_background = "--spinner.background",
		spinner_foreground = "--spinner.foreground",
		spinner_border = "--spinnner.border",
		spinner_border_background = "--spinner.border-background",
		spinner_border_foreground = "--spinner.border-foreground",
		spinner_height = "--spinner.height",
		spinner_width = "--spinner.width",
		spinner_margin = "--spinner.margin",
		spinner_padding = "--spinner.padding",
		spinner_bold = "--spinner.bold",
		spinner_faint = "--spinner.faint",
		spinner_italic = "--spinner.italic",
		spinner_strikethrough = "--spinner.strikethrough",
		spinner_underline = "--spinner.underline",

		title_background = "--title.background",
		title_foreground = "--title.foreground",
		title_border = "--title.border",
		title_border_background = "--title.border.background",
		title_border_foreground = "--title.border.foreground",
		title_height = "--title.height",
		title_width = "--title.width",
		title_margin = "--title.margin",
		title_padding = "--title.padding",
		title_bold = "--title.bold",
		title_faint = "--title.faint",
		title_italic = "--title.italic",
		title_strikethrough = "--title.strikethrough",
		title_underline = "--title.underline"

	}
}

local function cmd_handle(fn_name, cmd, option)
	local cmd_buff = {}
	cmd_buff[1] = cmd

	local fn_option = gum_option[fn_name]
	for o_name, o_val in pairs(option) do
		if not fn_option[o_name] then
			error("Invalid option: " .. o_name)
		end

		if type(o_val) == "boolean" then
			table_insert(cmd_buff, o_val and fn_option[o_name] or "")
		else
			table_insert(cmd_buff, fn_option[o_name] .. "='" .. tostring(o_val) .. "'")
		end
	end
	return table_concat(cmd_buff, " ")
end

lum._winsupport = false

if iswindows() and not lum._winsupport then
	error "Lum only works with POSIX shell (`sh`), especially Linux. But you can enable Windows support by changing `lum._winsupport` to `true`."
end

function lum.confirm(prompt, option)
	option = option or {
		affirmative = "Yes",
		negative = "No",
		timeout = 0
	}

	local cmd = cmd_handle("confirm", "gum confirm", option)

	local _, _, code = os_execute(cmd .. (prompt and " " .. "'" .. prompt .. "'" or ""))
	return code < 1
end

function lum.write()
	local gum = io_popen "gum write"
	local data = gum:read "a":gsub("\n$", "")
	gum:close()
	return data
end

function lum.file(path)
	local gum = io_popen("gum file " .. (path or "."))
	local data = gum:read "a":gsub("\n$", "")
	gum:close()
	return data
end

function lum.join(...)
	local option = {
		horizontal = false,
		vertical = false,
		align = "left"
	}

	local vararg = {...}
	if type(vararg[#vararg]) == "table" and next(vararg[#vararg]) then
		option = table_copy(vararg[#vararg])
		vararg[#vararg] = nil
	elseif type(vararg[#vararg]) == "table" and not next(vararg[#vararg]) then
		vararg[#vararg] = nil
	end
	local cmd = cmd_handle("join", "gum join", option)

	local buff = {}
	for _, v in pairs(vararg) do
		table_insert(buff, "'"  ..  tostring(v) .. "'")
	end

	local gum = io_popen(cmd .. " " .. table_concat(buff, " "))
	local data = gum:read "a":gsub("\n$", "")
	gum:close()
	return data
end

function lum.spin(fn,option)
	option = option or {
		spinner = "dot",
		title = "Loading...",
		align = "left"
	}

	local cmd = cmd_handle("spin","gum spin",option)
	return function(...)
		local gum = io_popen(cmd.." -- sleep 999999 & echo $!")
		local pid = gum:read "*l"
		local rets = table_pack(fn(...))
		gum:close()
		os_execute("kill "..pid)
		return table_unpack(rets)
	end
end

return lum
