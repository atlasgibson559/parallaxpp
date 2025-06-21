--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Inventory management library.
-- @module Parallax.Inventory

function Parallax.Inventory:Register(data, callback)
    if ( !istable(data) or !data.characterID ) then
        Parallax.Util:PrintError("Invalid data provided for inventory registration.")
        return false
    end

    local bResult = hook.Run("PreInventoryRegistered", data)
    if ( bResult == false ) then
        Parallax.Util:PrintError("PreInventoryRegistered hook denied inventory registration for character " .. data.characterID)
        return false
    end

    Parallax.Database:Insert("ax_inventories", {
        character_id = data.characterID,
        name = data.name or "Main",
        max_weight = data.maxWeight or Parallax.Config:Get("inventory.max.weight", 20),
        data = util.TableToJSON(data.data or {})
    }, function(inventoryID)
        if ( !inventoryID ) then
            Parallax.Util:PrintError("Failed to insert inventory into database for character " .. data.characterID)
            return false
        end

        data.ID = inventoryID

        local inventory = self:CreateObject(data)
        if ( !inventory ) then
            Parallax.Util:PrintError("Failed to create inventory object for ID " .. inventoryID)
            return false
        end

        self.Stored[inventoryID] = inventory
        self:AssignToCharacter(data.characterID, inventoryID)
        self:Broadcast(inventory)

        if ( callback ) then
            callback(inventory)
        end

        hook.Run("PostInventoryRegistered", inventory)
    end)
end

function Parallax.Inventory:AssignToCharacter(characterID, inventoryID, callback)
    if ( !characterID or !inventoryID ) then
        Parallax.Util:PrintError("Invalid character ID or inventory ID for assignment.")
        return
    end

    local bResult = hook.Run("PreInventoryAssigned", characterID, inventoryID)
    if ( bResult == false ) then
        Parallax.Util:PrintError("PreInventoryAssigned hook denied assignment of inventory " .. inventoryID .. " to character " .. characterID)
        return
    end

    Parallax.Database:Select("ax_characters", nil, "id = " .. characterID, function(result)
        if ( !result or !result[1] ) then
            Parallax.Util:PrintError("Character with ID " .. characterID .. " not found in database.")
            return
        end

        local inventories = util.JSONToTable(result[1].inventories or "[]") or {}

        local found = false
        for i = 1, #inventories do
            if ( inventories[i] == inventoryID ) then
                found = true
                break
            end
        end

        if ( !found ) then
            table.insert(inventories, inventoryID)
        end

        Parallax.Database:Update("ax_characters", {
            inventories = util.TableToJSON(inventories)
        }, "id = " .. characterID)

        local character = Parallax.Character:Get(characterID)
        if ( character ) then
            character:SetInventories(inventories)
        end

        if ( callback ) then
            callback(inventoryID)
        end

        hook.Run("PostInventoryAssigned", characterID, inventoryID)
    end)
end

function Parallax.Inventory:Broadcast(inventory)
    if ( !inventory ) then return end

    local receivers = inventory:GetReceivers()
    if ( !istable(receivers) ) then return end

    Parallax.Net:Start(receivers, "inventory.register", {
        ID = inventory:GetID(),
        CharacterID = inventory:GetOwner(),
        Name = inventory:GetName(),
        MaxWeight = inventory:GetMaxWeight(),
        Items = inventory:GetItems(),
        Data = inventory:GetData(),
        Receivers = inventory.Receivers
    })
end

function Parallax.Inventory:Cache(client, inventoryID, callback)
    if ( !IsValid(client) or !inventoryID ) then
        Parallax.Util:PrintError("Invalid client or inventory ID for caching.")
        return
    end

    local bResult = hook.Run("PreInventoryCached", inventoryID, client)
    if ( bResult == false ) then
        Parallax.Util:PrintError("PreInventoryCached hook denied caching of inventory " .. inventoryID .. " for player " .. tostring(client))
        return
    end

    -- Yeah, big pyramid of function calls...
    Parallax.Database:Select("ax_inventories", nil, "id = " .. inventoryID, function(result)
        if ( !result or !result[1] ) then
            Parallax.Util:PrintError("Failed to cache inventory with ID " .. inventoryID .. " for player " .. tostring(client))
            return
        end

        local inventory = self:CreateObject(result[1])
        if ( !inventory ) then
            Parallax.Util:PrintError("Failed to create inventory object for ID " .. inventoryID)
            return
        end

        self.Stored[inventoryID] = inventory

        self:AssignToCharacter(inventory:GetOwner(), inventoryID, function(invID)
            if ( !invID ) then
                Parallax.Util:PrintError("Failed to assign inventory " .. invID .. " to character " .. inventory:GetOwner())
                return
            end

            Parallax.Item:Cache(inventory:GetOwner(), function(items)
                if ( !items ) then
                    Parallax.Util:PrintError("Failed to cache items for inventory " .. invID)
                    return
                end

                local itemIDs = {}
                for _, item in pairs(Parallax.Item.instances) do
                    if ( item:GetOwner() == inventory:GetOwner() ) then
                        table.insert(itemIDs, item:GetID())
                    end
                end

                inventory.Items = itemIDs

                Parallax.Net:Start(client, "inventory.cache", {
                    ID = inventory:GetID(),
                    CharacterID = inventory:GetOwner(),
                    Name = inventory:GetName(),
                    MaxWeight = inventory:GetMaxWeight(),
                    Items = inventory:GetItems(),
                    Data = inventory:GetData(),
                    Receivers = inventory.Receivers
                })

                if ( callback ) then
                    callback(inventory)
                end

                hook.Run("PostInventoryCached", inventory, client)
            end)
        end)
    end)
end

function Parallax.Inventory:CacheAll(characterID, callback)
    if ( !characterID ) then
        Parallax.Util:PrintError("Invalid character ID for caching inventories.")
        return
    end

    local bResult = hook.Run("PreInventoryCacheAll", characterID)
    if ( bResult == false ) then
        Parallax.Util:PrintError("PreInventoryCacheAll hook denied caching of all inventories for character " .. characterID)
        return
    end

    Parallax.Database:Select("ax_characters", nil, "id = " .. characterID, function(result)
        if ( !result or !result[1] ) then
            Parallax.Util:PrintError("Character with ID " .. characterID .. " not found in database.")
            return
        end

        local inventories = util.JSONToTable(result[1].inventories or "[]") or {}
        -- Check if we are the last inventory to cache, and if so, run the callback
        local count = #inventories
        for i = 1, count do
            local inventoryID = inventories[i]
            local client = Parallax.Character:GetPlayerByCharacter(characterID)
            if ( !IsValid(client) ) then
                Parallax.Util:PrintError("Invalid client for character " .. characterID)
                return
            end

            self:Cache(client, inventoryID, function(success, inventory)
                if ( !success ) then
                    Parallax.Util:PrintError("Failed to cache inventory " .. inventoryID .. " for character " .. characterID)
                    return
                end

                Parallax.Util:Print("Cached inventory " .. inventoryID .. " for character " .. characterID)

                -- If we have a callback, call it with the cached inventory
                if ( callback and i == count ) then
                    callback(inventory)
                end
            end)
        end

        hook.Run("PostInventoryCacheAll", characterID)
    end)
end

function Parallax.Inventory:AddItem(inventoryID, itemID, uniqueID, data)
    if ( !inventoryID or !itemID or !uniqueID ) then
        Parallax.Util:PrintError("Invalid parameters for item addition.")
        return false
    end

    local item = Parallax.Item:Get(itemID)
    if ( !item ) then
        Parallax.Util:PrintError("Invalid item ID " .. itemID .. " for addition.")
        return false
    end

    local inventory = self:Get(inventoryID)
    if ( !inventory ) then
        Parallax.Util:PrintError("Invalid inventory ID " .. inventoryID .. " for item addition.")
        return false
    end

    local receivers = inventory:GetReceivers()
    if ( !receivers or !istable(receivers) ) then
        receivers = {}
    end

    local items = inventory:GetItems()
    if ( !items or !istable(items) ) then
        items = {}
    end

    local found = false
    for i = 1, #items do
        if ( items[i] == itemID ) then
            found = true
            break
        end
    end

    if ( !found ) then
        table.insert(items, itemID)
    end

    item:SetInventory(inventoryID)

    if ( SERVER ) then
        data = data or {}

        Parallax.Database:Update("ax_items", {
            inventory_id = inventoryID,
            data = util.TableToJSON(data)
        }, "id = " .. itemID)

        Parallax.Net:Start(receivers, "inventory.item.add", inventoryID, itemID, uniqueID, data)
    end

    hook.Run("OnItemAdded", item, inventoryID, uniqueID, data)

    return true
end

function Parallax.Inventory:RemoveItem(inventoryID, itemID)
    if ( !inventoryID or !itemID ) then
        Parallax.Util:PrintError("Invalid parameters for item removal.")
        return false
    end

    local item = Parallax.Item:Get(itemID)
    if ( !item ) then
        Parallax.Util:PrintError("Invalid item ID " .. itemID .. " for removal.")
        return false
    end

    local inventory = self:Get(inventoryID)
    if ( !inventory ) then
        Parallax.Util:PrintError("Invalid inventory ID " .. inventoryID .. " for item removal.")
        return false
    end

    local found = true
    local items = inventory:GetItems()
    for i = 1, #items do
        if ( items[i] != itemID ) then
            found = false
            break
        end
    end

    if ( found ) then
        table.RemoveByValue(items, itemID)
    end

    item:SetInventory(0)

    if ( SERVER ) then
        Parallax.Database:Update("ax_items", {
            inventory_id = 0
        }, "id = " .. itemID)

        local receivers = inventory:GetReceivers()
        if ( istable(receivers) ) then
            Parallax.Net:Start(receivers, "inventory.item.remove", inventoryID, itemID)
        end
    end

    hook.Run("OnItemRemoved", item, inventoryID)

    return true
end