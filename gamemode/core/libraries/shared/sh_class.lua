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
Parallax.Class.stored = {}
Parallax.Class.instances = {}
Parallax.Class.Meta = Parallax.Class.Meta or {}

function Parallax.Class:Register(classData)
    local CLASS = setmetatable(classData, self.Meta)
    if ( !isnumber(CLASS.Faction) ) then
        Parallax.Util:PrintError("Attempted to register a class without a valid faction!")
        return false
    end

    local faction = Parallax.Faction:Get(CLASS.Faction)
    if ( faction == nil or !istable(faction) ) then
        Parallax.Util:PrintError("Attempted to register a class for an invalid faction!")
        return false
    end

    local bResult = hook.Run("PreClassRegistered", CLASS)
    if ( bResult == false ) then
        Parallax.Util:PrintError("Attempted to register a class that was blocked by a hook!")
        return false, "Attempted to register a class that was blocked by a hook!"
    end

    local uniqueID = string.lower(string.gsub(CLASS.Name, "%s+", "_")) .. "_" .. CLASS.Faction
    for i = 1, #self.instances do
        if ( self.instances[i].UniqueID == uniqueID ) then
            return false, "Attempted to register a class that already exists!"
        end
    end

    CLASS.UniqueID = CLASS.UniqueID or uniqueID

    self.stored[CLASS.UniqueID] = CLASS

    for i = 1, #self.instances do
        if ( self.instances[i].UniqueID == CLASS.UniqueID ) then
            table.remove(self.instances, i)
            break
        end
    end

    CLASS.ID = #self.instances + 1

    table.insert(self.instances, CLASS)
    self.stored[CLASS.UniqueID] = CLASS

    hook.Run("PostClassRegistered", CLASS)

    return CLASS.ID
end

function Parallax.Class:Get(identifier)
    if ( identifier == nil ) then
        Parallax.Util:PrintError("Attempted to get a faction with an invalid identifier!")
        return false
    end

    if ( isnumber(identifier) ) then
        return self.instances[identifier]
    end

    if ( self.stored[identifier] ) then
        return self.stored[identifier]
    end

    for i = 1, #self.instances do
        local v = self.instances[i]
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
    return self.instances
end