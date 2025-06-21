--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--[[-----------------------------------------------------------------------------
    Character Networking
-----------------------------------------------------------------------------]]--

Parallax.Net:Hook("character.load", function(client, characterID)
    Parallax.Character:Load(client, characterID)
end)

Parallax.Net:Hook("character.delete", function(client, characterID)
    local character = Parallax.Character:Get(characterID)
    if ( !character ) then return end

    local bResult = hook.Run("PrePlayerDeletedCharacter", client, characterID)
    if ( bResult == false ) then return end

    Parallax.Character:Delete(characterID)

    hook.Run("PostPlayerDeletedCharacter", client, characterID)
end)

Parallax.Net:Hook("character.create", function(client, payload)
    if ( !istable(payload) ) then
        Parallax.Net:Start(client, "character.create.failed", "Invalid payload!")
        return
    end

    local canCreate, reason = hook.Run("PrePlayerCreatedCharacter", client, payload)
    if ( canCreate == false ) then
        Parallax.Net:Start(client, "character.create.failed", reason or "Failed to create character!")
        return
    end

    for k, v in pairs(Parallax.Character.variables) do
        if ( v.Editable != true ) then continue end

        -- This is a bit of a hack, but it works for now.
        if ( v.Type == Parallax.Types.string or v.Type == Parallax.Types.text ) then
            payload[k] = string.Trim(payload[k] or "")
        end

        if ( isfunction(v.OnValidate) ) then
            local validate, reasonString = v:OnValidate(nil, payload, client)
            if ( !validate ) then
                Parallax.Net:Start(client, "character.create.failed", reasonString or "Failed to validate character!")
                return
            end
        end
    end

    Parallax.Character:Create(client, payload, function(success, result)
        if ( !success ) then
            Parallax.Util:PrintError("Failed to create character: " .. result)
            Parallax.Net:Start(client, "character.create.failed", result or "Failed to create character!")
            return
        end

        Parallax.Character:Load(client, result:GetID())

        Parallax.Net:Start(client, "character.create")

        hook.Run("PostPlayerCreatedCharacter", client, result, payload)
    end)
end)

--[[-----------------------------------------------------------------------------
    Chat Networking
-----------------------------------------------------------------------------]]--

-- None

--[[-----------------------------------------------------------------------------
    Config Networking
-----------------------------------------------------------------------------]]--

Parallax.Net:Hook("config.reset", function(client, key)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Manage Config", nil) ) then return end

    local stored = Parallax.Config.stored[key]
    if ( !istable(stored) ) then return end

    local bResult = hook.Run("PrePlayerConfigReset", client, key)
    if ( bResult == false ) then return end

    Parallax.Config:Reset(key)

    hook.Run("PostPlayerConfigReset", client, key)
end)

Parallax.Net:Hook("config.set", function(client, key, value)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Manage Config", nil) ) then return end

    local stored = Parallax.Config.stored[key]
    if ( !istable(stored) ) then return end

    if ( value == nil ) then return end

    local oldValue = Parallax.Config:Get(key)

    local bResult = hook.Run("PrePlayerConfigChanged", client, key, value, oldValue)
    if ( bResult == false ) then return end

    Parallax.Config:Set(key, value)

    hook.Run("PostPlayerConfigChanged", client, key, value, oldValue)
end)

--[[-----------------------------------------------------------------------------
    Option Networking
-----------------------------------------------------------------------------]]--

Parallax.Net:Hook("option.set", function(client, key, value)
    local bResult = hook.Run("PreOptionChanged", client, key, value)
    if ( bResult == false ) then return false end

    Parallax.Option:Set(client, key, value, true)

    hook.Run("PostOptionChanged", client, key, value)
end)

Parallax.Net:Hook("option.sync", function(client, data)
    if ( !IsValid(client) or !istable(data) ) then return end

    for k, v in pairs(Parallax.Option.stored) do
        local stored = Parallax.Option.stored[k]
        if ( !istable(stored) ) then
            Parallax.Util:PrintError("Option \"" .. k .. "\" does not exist!")
            continue
        end

        if ( stored.NoNetworking ) then continue end

        if ( data[k] != nil ) then
            if ( Parallax.Util:DetectType(data[k]) != stored.Type ) then
                Parallax.Util:PrintError("Option \"" .. k .. "\" is not of type \"" .. stored.Type .. "\"!")
                continue
            end

            local cliIndex = client:EntIndex()
            if ( !istable(Parallax.Option.clients[cliIndex]) ) then
                Parallax.Option.clients[cliIndex] = {}
            end

            Parallax.Option.clients[cliIndex][k] = data[k]
        end
    end
end)

--[[-----------------------------------------------------------------------------
    Inventory Networking
-----------------------------------------------------------------------------]]--

Parallax.Net:Hook("inventory.cache", function(client, inventoryID)
    if ( !inventoryID ) then return end

    Parallax.Inventory:Cache(client, inventoryID)
end)

--[[-----------------------------------------------------------------------------
    Item Networking
-----------------------------------------------------------------------------]]--

Parallax.Net:Hook("item.entity", function(client, itemID, entity)
    if ( !IsValid(entity) ) then return end

    local item = Parallax.Item:Get(itemID)
    if ( !item ) then return end

    item:SetEntity(entity)
end)

Parallax.Net:Hook("item.perform", function(client, itemID, actionName)
    if ( !itemID or !actionName ) then return end

    local item = Parallax.Item:Get(itemID)
    if ( !item or item:GetOwner() != client:GetCharacterID() ) then return end

    Parallax.Item:PerformAction(itemID, actionName)
end)

Parallax.Net:Hook("item.spawn", function(client, uniqueID)
    if ( !isstring(uniqueID) or !istable(Parallax.Item.stored[uniqueID]) ) then return end

    local pos = client:GetEyeTrace().HitPos + vector_up

    Parallax.Item:Spawn(nil, uniqueID, pos, nil, function(entity)
        if ( IsValid(entity) ) then
            client:Notify("Spawned item: " .. uniqueID)
        else
            client:Notify("Failed to spawn item.")
        end
    end)
end)

--[[-----------------------------------------------------------------------------
    Currency Networking
-----------------------------------------------------------------------------]]--

-- None

--[[-----------------------------------------------------------------------------
    Miscellaneous Networking
-----------------------------------------------------------------------------]]--

Parallax.Net:Hook("client.voice.start", function(client, speaker)
    hook.Run("PlayerStartVoice", speaker)
end)

Parallax.Net:Hook("client.voice.end", function(client, prevSpeaker)
    hook.Run("PlayerEndVoice", prevSpeaker)
end)

Parallax.Net:Hook("client.chatbox.text.changed", function(client, text)
    if ( !IsValid(client) or !text ) then return end

    hook.Run("PlayerChatTextChanged", client, text)
end, true)

Parallax.Net:Hook("client.chatbox.type.changed", function(client, newType, oldType)
    if ( !IsValid(client) or !newType or !oldType ) then return end

    hook.Run("PlayerChatTypeChanged", client, newType, oldType)
end, true)

Parallax.Net:Hook("command.run", function(client, command, arguments)
    Parallax.Command:Run(client, command, arguments)
end)