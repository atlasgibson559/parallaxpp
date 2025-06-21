--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Faction library
-- @module Parallax.Faction

Parallax.Faction = Parallax.Faction or {}
Parallax.Faction.stored = {}
Parallax.Faction.instances = {}
Parallax.Faction.Meta = Parallax.Faction.Meta or {}

function Parallax.Faction:Register(factionData)
    local FACTION = setmetatable(factionData, self.Meta)

    local bResult = hook.Run("PreFactionRegistered", FACTION)
    if ( bResult == false ) then
        Parallax.Util:PrintError("Attempted to register a faction that was blocked by a hook!")
        return false, "Attempted to register a faction that was blocked by a hook!"
    end

    local uniqueID = string.lower(string.gsub(FACTION.Name, "%s+", "_"))
    for i = 1, #self.instances do
        if ( self.instances[i].UniqueID == uniqueID ) then
            return false, "Attempted to register a faction that already exists!"
        end
    end

    FACTION.UniqueID = FACTION.UniqueID or uniqueID
    FACTION.ID = #self.instances + 1

    table.insert(self.instances, FACTION)

    self.stored[FACTION.UniqueID] = FACTION

    team.SetUp(FACTION.ID, FACTION.Name, FACTION.Color, false)
    hook.Run("PostFactionRegistered", FACTION)

    return FACTION.ID
end

function Parallax.Faction:Get(identifier)
    if ( identifier == nil ) then
        return false, "Attempted to get a faction without an identifier!"
    end

    if ( isnumber(identifier) ) then
        if ( identifier < 1 ) then
            Parallax.Util:PrintError("Attempted to get a faction with an invalid ID!")
            return false, "Attempted to get a faction with an invalid ID!"
        end

        return self.instances[identifier]
    elseif ( isstring(identifier) ) then
        if ( self.stored[identifier] ) then
            return self.stored[identifier]
        end

        for i = 1, #self.instances do
            local v = self.instances[i]
            if ( Parallax.Util:FindString(v.Name, identifier) or Parallax.Util:FindString(v.UniqueID, identifier) ) then
                return v
            end
        end
    end

    return nil
end

function Parallax.Faction:CanSwitchTo(client, factionID, oldFactionID)
    if ( !IsValid(client) ) then
        Parallax.Util:PrintError("Attempted to check if a player can switch to a faction without a client!")
        return false, "Attempted to check if a player can switch to a faction without a client!"
    end

    local faction = self:Get(factionID)
    if ( !faction ) then
        return false, "Faction does not exist."
    end

    if ( oldFactionID ) then
        local oldFaction = self:Get(oldFactionID)
        if ( oldFaction ) then
            if ( oldFaction.ID == faction.ID ) then return false end

            if ( oldFaction.CanLeave and !oldFaction:CanLeave(client) ) then
                return false, "You cannot leave this faction."
            end
        end
    end

    local hookRun = hook.Run("CanPlayerJoinFaction", client, factionID)
    if ( hookRun != nil and hookRun == false ) then return false end

    if ( faction.CanSwitchTo and !faction:CanSwitchTo(client) ) then
        return false, "You cannot switch to this faction."
    end

    if ( !faction.IsDefault and !client:HasWhitelist(faction.UniqueID) ) then
        return false, "You do not have permission to join this faction."
    end

    if ( isfunction(faction.OnSwitch) ) then
        faction:OnSwitch(client)
    end

    return true
end

function Parallax.Faction:GetAll()
    return self.instances
end