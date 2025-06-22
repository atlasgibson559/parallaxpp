--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Class library
-- @module Parallax.Class

Parallax.Class = Parallax.Class or {}
Parallax.Class.Stored = {}
Parallax.Class.Instances = {}
Parallax.Class.Meta = Parallax.Class.Meta or {}

function Parallax.Class:Instance()
    return setmetatable({}, self.Meta)
end

function Parallax.Class:Get(identifier)
    if ( identifier == nil ) then
        Parallax.Util:PrintError("Attempted to get a faction with an invalid identifier!")
        return false
    end

    if ( isnumber(identifier) ) then
        return self.Instances[identifier]
    end

    if ( self.Stored[identifier] ) then
        return self.Stored[identifier]
    end

    for i = 1, #self.Instances do
        local v = self.Instances[i]
        if ( Parallax.Util:FindString(v.Name, identifier) or Parallax.Util:FindString(v.UniqueID, identifier) ) then
            return v
        end
    end

    return nil
end

function Parallax.Class:CanSwitchTo(client, classID)
    local class = self:Get(classID)
    if ( !class ) then return false end

    local hookRun = hook.Run("CanPlayerJoinClass", client, class)
    if ( hookRun == false ) then return false end

    if ( isfunction(class.CanSwitchTo) and !class:CanSwitchTo(client) ) then
        return false
    end

    if ( !class.IsDefault ) then
        return false
    end

    return true
end

function Parallax.Class:OnSwitch(client, classID)
    local class = self:Get(classID)
    if ( !class ) then return false end

    local character = client:GetCharacter()
    if ( !character ) then
        Parallax.Util:PrintError("Attempted to switch class for a player without a character!")
        return false
    end

    local hookRun = hook.Run("CanPlayerJoinClass", client, classID)
    if ( hookRun != nil and hookRun == false ) then return false end

    character:SetClass(classID)

    if ( isfunction(class.OnBecome) ) then
        class:OnBecome(client)
    end

    return true
end

function Parallax.Class:GetAll()
    return self.Instances
end

Parallax.class = Parallax.Class