--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Configuration for the gamemode
-- @module Parallax.Config

Parallax.Config = Parallax.Config or {}
Parallax.Config.Stored = Parallax.Config.Stored or {}
Parallax.Config.Instances = Parallax.Config.Instances or {}

--- Loads the configuration from the file.
-- @realm shared
-- @return Whether or not the configuration was loaded.
-- @usage Parallax.Config:Load()
-- @internal
function Parallax.Config:Load()
    local config = Parallax.Data:Get("config", {}, false, false)

    for k, v in pairs(config) do
        local storedData = self.Stored[k]
        if ( !istable(storedData) ) then continue end

        self.Instances[k] = {}
        self.Instances[k].Value = Parallax.Util:CoerceType(storedData.Type, v)
    end

    local tableToSend = self:GetNetworkData()
    Parallax.Net:Start(nil, "config.sync", tableToSend)

    Parallax.Util:Print("Configuration loaded.")
    hook.Run("PostConfigLoad", config, tableToSend)

    return true
end

function Parallax.Config:GetSaveData()
    local saveData = {}
    for k, v in pairs(self.Instances) do
        local storedData = self.Stored[k]
        if ( !istable(storedData) ) then continue end
        if ( storedData.NoSave ) then continue end

        saveData[k] = v.Value
    end

    return saveData
end

function Parallax.Config:GetNetworkData()
    local saveData = self:GetSaveData()
    for k, v in pairs(saveData) do
        local storedData = self.Stored[k]
        if ( !istable(storedData) ) then continue end

        if ( storedData.NoNetworking ) then
            saveData[k] = nil
        end
    end

    return saveData
end

--- Saves the configuration to the file.
-- @realm server
-- @return Whether or not the configuration was saved.
-- @usage Parallax.Config:Save() -- Saves the configuration to the file.
-- @internal
function Parallax.Config:Save()
    hook.Run("PreConfigSave")

    local values = self:GetSaveData()

    Parallax.Data:Set("config", values, false, false)

    hook.Run("PostConfigSave", values)
    Parallax.Util:Print("Configuration saved.")

    return true
end

--- Set the config to the default value
-- @realm server
-- @string key The config key to reset
-- @return boolean Returns true if the config was reset successfully, false otherwise
-- @usage Parallax.Config:Reset(key) -- Resets the config to the default value.
function Parallax.Config:Reset(key)
    local configData = self.Stored[key]
    if ( !istable(configData) ) then
        Parallax.Util:PrintError("Config \"" .. key .. "\" does not exist!")
        return false
    end

    self:Set(key, configData.Default)

    return true
end

--- Resets the configuration to the default values.
-- @realm server
-- @return Whether or not the configuration was reset.
-- @usage Parallax.Config:ResetAll() -- Resets the configuration to the default values.
function Parallax.Config:ResetAll()
    hook.Run("PreConfigReset")

    for k, v in pairs(self.Stored) do
        self:Reset(k)
    end

    Parallax.Net:Start(nil, "config.sync", self:GetNetworkData())

    self:Save()
    hook.Run("PostConfigReset")

    return true
end

--- Synchronizes the configuration with the player.
-- @realm server
-- @param client The player to synchronize the configuration with.
-- @return Whether or not the configuration was synchronized with the player.
-- @usage Parallax.Config:Synchronize(Entity(1)) -- Synchronizes the configuration with the first player.
function Parallax.Config:Synchronize(client)
    local tableToSend = self:GetNetworkData()

    if ( !IsValid(client) ) then
        Parallax.Net:Start(nil, "config.sync", tableToSend)
        hook.Run("PostConfigSync")

        return
    end

    local shouldSend = hook.Run("PreConfigSync", client, tableToSend)
    if ( shouldSend == false ) then return false end

    Parallax.Net:Start(client, "config.sync", tableToSend)
    hook.Run("PostConfigSync", client)

    return true
end

Parallax.config = Parallax.Config