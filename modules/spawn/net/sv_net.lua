--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

util.AddNetworkString("ax.spawn.sync")
util.AddNetworkString("ax.spawn.add")
util.AddNetworkString("ax.spawn.remove")

--- Receive spawn sync updates
net.Receive("ax.spawn.sync", function(len, client)
    -- This is sent from server to client only
end)