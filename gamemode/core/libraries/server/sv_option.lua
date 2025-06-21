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
Parallax.Option.stored = Parallax.Option.stored or {}
Parallax.Option.clients = Parallax.Option.clients or {}

function Parallax.Option:Set(client, key, value, bNoNetworking)
    local stored = self.stored[key]
    if ( !istable(stored) ) then
        Parallax.Util:PrintError("Option \"" .. key .. "\" does not exist!")
        return false
    end

    if ( !IsValid(client) ) then return false end

    local bResult = hook.Run("PreOptionChanged", client, key, value)
    if ( bResult == false ) then return false end

    if ( stored.NoNetworking != true ) then
        if ( !bNoNetworking ) then
            Parallax.Net:Start(client, "option.set", key, value)
        end

        local index = client:EntIndex()
        if ( Parallax.Option.clients[index] == nil ) then
            Parallax.Option.clients[index] = {}
        end

        Parallax.Option.clients[index][key] = value
    end

    if ( isfunction(stored.OnChange) ) then
        stored:OnChange(value, client)
    end

    return true
end

function Parallax.Option:Get(client, key, fallback)
    if ( !IsValid(client) ) then return default end

    local stored = Parallax.Option.stored[key]
    if ( !istable(stored) ) then
        Parallax.Util:PrintError("Option \"" .. key .. "\" does not exist!")
        return default
    end

    if ( stored.NoNetworking ) then
        Parallax.Util:PrintWarning("Option \"" .. key .. "\" is not networked!")
        return fallback
    end

    local clientStored = Parallax.Option.clients[client:EntIndex()]
    if ( !istable(clientStored) ) then
        return fallback
    end

    local value = clientStored[key]
    if ( value != nil ) then
        return value
    end

    return fallback
end