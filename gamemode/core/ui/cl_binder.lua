--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PANEL = {}
DEFINE_BASECLASS("DBinder")

-- Check: https://wiki.facepunch.com/gmod/input.StartKeyTrapping
-- Check: https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/dbinder.lua


vgui.Register("ax.binder", PANEL, "DBinder")