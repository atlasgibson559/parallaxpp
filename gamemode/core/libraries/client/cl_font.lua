--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Font library.
-- @module Parallax.Font

Parallax.Font = {}
Parallax.Font.Stored = {}

surface.CreateFontInternal = surface.CreateFontInternal or surface.CreateFont

--- Registers a new font.
-- @realm client
-- @string name The name of the font.
-- @tab data The font data.
function surface.CreateFont(name, data)
    if ( string.sub(name, 1, 8) == "parallax" ) then
        Parallax.Font.Stored[name] = data
    end

    surface.CreateFontInternal(name, data)
end

--- Returns a font by its name.
-- @realm shared
-- @string name The name of the font.
-- @return tab The font.
function Parallax.Font:Get(name)
    return self.Stored[name]
end

concommand.Add("ax_list_font", function(client)
    for name, data in pairs(Parallax.Font.Stored) do
        Parallax.Util:Print("Font: ", Parallax.Color:Get("cyan"), name)
        PrintTable(data)
    end
end)

Parallax.font = Parallax.Font