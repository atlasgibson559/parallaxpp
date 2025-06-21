--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Relay
-- A secure value distribution system using SFS for packing and syncing values.
-- Provides shared (global), user (per-player), and entity (per-entity) scopes.
-- @module Parallax.Relay

Parallax.Relay = Parallax.Relay or {}
Parallax.Relay.shared = Parallax.Relay.shared  or {}
Parallax.Relay.user = Parallax.Relay.user or {}
Parallax.Relay.entity = Parallax.Relay.entity or {}

local playerMeta = FindMetaTable("Player")
local entityMeta = FindMetaTable("Entity")

function Parallax.Relay:SetRelay(key, value, recipient)
    self.shared[key] = value

    if ( SERVER ) then
        Parallax.Net:Start(recipient, "relay.shared", key, value)
    end
end

function Parallax.Relay:GetRelay(key, default)
    local v = self.shared[key]
    return v != nil and v or default
end

if ( CLIENT ) then
    Parallax.Net:Hook("relay.shared", function(key, value)
        if ( value == nil ) then return end

        Parallax.Relay.shared[key] = value
    end)
end

function playerMeta:SetRelay(key, value, recipient)
    if ( SERVER ) then
        local index = self:EntIndex()
        Parallax.Relay.user[index] = Parallax.Relay.user[index] or {}
        Parallax.Relay.user[index][key] = value

        Parallax.Net:Start(recipient, "relay.user", index, key, value)
    end
end

function playerMeta:GetRelay(key, default)
    local index = self:EntIndex()
    local t = Parallax.Relay.user[index]
    if ( t == nil ) then
        return default
    end

    return t[key] == nil and default or t[key]
end

if ( CLIENT ) then
    Parallax.Net:Hook("relay.user", function(index, key, value)
        if ( value == nil ) then return end

        Parallax.Relay.user[index] = Parallax.Relay.user[index] or {}
        Parallax.Relay.user[index][key] = value
    end)
end

function entityMeta:SetRelay(key, value, recipient)
    if ( SERVER ) then
        local index = self:EntIndex()
        Parallax.Relay.entity[index] = Parallax.Relay.entity[index] or {}
        Parallax.Relay.entity[index][key] = value

        Parallax.Net:Start(recipient, "relay.entity", index, key, value)
    end
end

function entityMeta:GetRelay(key, default)
    local index = self:EntIndex()
    local t = Parallax.Relay.entity[index]
    if ( t == nil ) then
        return default
    end

    return t[key] == nil and default or t[key]
end

if ( CLIENT ) then
    Parallax.Net:Hook("relay.entity", function(index, key, value)
        if ( value == nil ) then return end

        Parallax.Relay.entity[index] = Parallax.Relay.entity[index] or {}
        Parallax.Relay.entity[index][key] = value
    end)
end

hook.Add("EntityRemoved", "Parallax.Relay.cleanup.entity", function(entity)
    local index = entity:EntIndex()
    if ( SERVER ) then Parallax.Net:Start(nil, "relay.cleanup", index) end

    if ( entity:IsPlayer() ) then
        if ( Parallax.Relay.user[index] ) then
            Parallax.Relay.user[index] = nil
        end

        return
    end

    if ( Parallax.Relay.entity[index] ) then
        Parallax.Relay.entity[index] = nil
    end
end)

if ( SERVER ) then
    hook.Add("SaveData", "Parallax.Relay.cleanup", function()
        for index, _ in pairs(Parallax.Relay.user) do
            if ( !IsValid(Entity(index)) ) then
                Parallax.Relay.user[index] = nil
            end
        end

        for index, _ in pairs(Parallax.Relay.entity) do
            if ( !IsValid(Entity(index)) ) then
                Parallax.Relay.entity[index] = nil
            end
        end
    end)
else
    Parallax.Net:Hook("relay.cleanup", function(index)
        local ent = Entity(index)
        if ( !IsValid(ent) ) then return end

        if ( ent:IsPlayer() ) then
            if ( Parallax.Relay.user[index] ) then
                Parallax.Relay.user[index] = nil
            end

            return
        end

        if ( Parallax.Relay.entity[index] ) then
            Parallax.Relay.entity[index] = nil
        end
    end)
end