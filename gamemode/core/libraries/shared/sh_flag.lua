--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

Parallax.Flag = Parallax.Flag or {}
Parallax.Flag.stored = {}

function Parallax.Flag:Register(flag, description, callback)
    if ( !isstring(flag) or #flag != 1 ) then
        Parallax.Util:PrintError("Attempted to register a flag without a flag character!")
        return false
    end

    self.stored[flag] = {
        description = description or "No description provided",
        callback = callback or nil
    }

    return true
end

function Parallax.Flag:Get(flag)
    return self.stored[flag]
end

function Parallax.Flag:GetAll()
    return self.stored
end