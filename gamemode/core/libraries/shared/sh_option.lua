--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Options library
-- @module Parallax.Option

Parallax.Option = Parallax.Option or {}
Parallax.Option.Stored = Parallax.Option.Stored or {}

function Parallax.Option:SetDefault(key, default)
    local stored = self.Stored[key]
    if ( !istable(stored) ) then
        Parallax.Util:PrintError("Option \"" .. key .. "\" does not exist!")
        return false
    end

    stored.Default = default

    if ( SERVER ) then
        Parallax.Net:Start(nil, "option.sync", self.Instances)
    end

    return true
end

if ( CLIENT ) then
    Parallax.Option.Instances = Parallax.Option.Instances or {}

    function Parallax.Option:Load()
        hook.Run("PreOptionsLoad")

        for k, v in pairs(Parallax.Data:Get("options", {}, true, true)) do
            local stored = self.Stored[k]
            if ( !istable(stored) ) then
                Parallax.Util:PrintError("Option \"" .. k .. "\" does not exist!")
                continue
            end

            if ( !istable(self.Instances[k]) ) then
                self.Instances[k] = nil
            end

            if ( v != nil and v != stored.Default ) then
                if ( Parallax.Util:DetectType(v) != stored.Type ) then
                    Parallax.Util:PrintError("Option \"" .. k .. "\" is not of type \"" .. stored.Type .. "\"!")
                    continue
                end

                self.Instances[k] = v
            end
        end

        Parallax.Net:Start("option.sync", self.Instances)
        hook.Run("PostOptionsLoad", self.Instances)
    end

    function Parallax.Option:GetSaveData()
        local data = {}
        for k, v in pairs(self.Instances) do
            if ( v != nil and v != self.Stored[k].Default ) then
                data[k] = v
            end
        end

        return data
    end

    function Parallax.Option:Set(key, value, bNoNetworking)
        local stored = self.Stored[key]
        if ( !istable(stored) ) then
            Parallax.Util:PrintError("Option \"" .. key .. "\" does not exist!")
            return false
        end

        local oldValue = stored.Value != nil and stored.Value or stored.Default
        local bResult = hook.Run("PreOptionChanged", Parallax.Client, key, value, oldValue)
        if ( bResult == false ) then return false end

        if ( !istable(self.Instances[key]) ) then
            self.Instances[key] = nil
        end

        if ( value != nil and value != stored.Default ) then
            self.Instances[key] = value
        end

        if ( stored.NoNetworking != true and !bNoNetworking ) then
            Parallax.Net:Start("option.set", key, value)
        end

        if ( isfunction(stored.OnChange) ) then
            stored:OnChange(value, oldValue, Parallax.Client)
        end

        Parallax.Data:Set("options", self:GetSaveData(), true, true)

        hook.Run("PostOptionChanged", Parallax.Client, key, value, oldValue)

        return true
    end

    function Parallax.Option:Get(key, fallback)
        local optionData = self.Stored[key]
        if ( !istable(optionData) ) then
            Parallax.Util:PrintError("Option \"" .. key .. "\" does not exist!")
            return fallback
        end

        local instance = self.Instances[key]
        if ( instance == nil ) then
            if ( optionData.Default == nil ) then
                Parallax.Util:PrintError("Option \"" .. key .. "\" has no value or default set!")
                return fallback
            end

            return optionData.Default
        end

        return instance
    end

    function Parallax.Option:GetDefault(key)
        local optionData = self.Stored[key]
        if ( !istable(optionData) ) then
            Parallax.Util:PrintError("Option \"" .. key .. "\" does not exist!")
            return nil
        end

        return optionData.Default
    end

    --- Set the option to the default value
    -- @realm client
    -- @string key The option key to reset
    -- @treturn boolean Returns true if the option was reset successfully, false otherwise
    -- @usage Parallax.Option:Reset(key)
    function Parallax.Option:Reset(key)
        local optionData = self.Stored[key]
        if ( !istable(optionData) ) then
            Parallax.Util:PrintError("Option \"" .. key .. "\" does not exist!")
            return false
        end

        self:Set(key, optionData.Default)

        return true
    end

    function Parallax.Option:ResetAll()
        self.Instances = {}

        Parallax.Data:Set("options", {}, true, true)
        Parallax.Net:Start("option.sync", {})
    end
end

local requiredFields = {
    "Name",
    "Description",
    "Default"
}

function Parallax.Option:Register(key, data)
    local bResult = hook.Run("PreOptionRegistered", key, data)
    if ( bResult == false ) then return false end

    for _, v in pairs(requiredFields) do
        if ( data[v] == nil ) then
            Parallax.Util:PrintError("Option \"" .. key .. "\" is missing required field \"" .. v .. "\"!\n")
            return false
        end
    end

    if ( data.Type == nil ) then
        data.Type = Parallax.Util:DetectType(data.Default)

        if ( data.Type == nil ) then
            Parallax.Util:PrintError("Option \"" .. key .. "\" has an invalid type!")
            return false
        end
    end

    if ( data.Category == nil ) then
        data.Category = "misc"
    end

    if ( data.SubCategory == nil ) then
        data.SubCategory = "other"
    end

    data.UniqueID = key

    self.Stored[key] = data
    hook.Run("PostOptionRegistered", key, data)

    return true
end

Parallax.option = Parallax.Option