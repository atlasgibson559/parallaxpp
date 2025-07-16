--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.Name = "Weapon Select"
MODULE.Description = "Advanced weapon selection system with vertical layout and smooth animations."
MODULE.Author = "Riggs"

if ( SERVER ) then
    util.AddNetworkString("ax.weaponselect.deathclose")
end

-- I WROTE THIS IN VR ( NOT MODULE, JUST THIS COMMENT ) (useless change, gotta test smth)