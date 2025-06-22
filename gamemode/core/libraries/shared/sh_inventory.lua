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

Parallax.Inventory = Parallax.Inventory or {}
Parallax.Inventory.Meta = Parallax.Inventory.Meta or {}
Parallax.Inventory.Stored = Parallax.Inventory.Stored or {}

-- Create an inventory object
function Parallax.Inventory:CreateObject(data)
    if ( !data or !istable(data) ) then
        Parallax.Util:PrintError("Invalid data passed to CreateObject")
        return
    end

    local inventory = setmetatable({}, self.Meta)

    inventory.ID = tonumber(data.ID or data.id or 0)
    inventory.CharacterID = tonumber(data.CharacterID or data.character_id or 0)
    inventory.Name = data.Name or data.name or "Inventory"
    inventory.MaxWeight = tonumber(data.MaxWeight or data.max_weight) or Parallax.Config:Get("inventory.max.weight", 20)
    inventory.Items = Parallax.Util:SafeParseTable(data.Items or data.items)
    inventory.Data = Parallax.Util:SafeParseTable(data.Data or data.data)
    inventory.Receivers = Parallax.Util:SafeParseTable(data.Receivers or data.receivers)

    self.Stored[inventory.ID] = inventory

    return inventory
end

function Parallax.Inventory:Get(id)
    return tonumber(id) and self.Stored[id] or nil
end

function Parallax.Inventory:GetAll()
    return self.Stored
end

function Parallax.Inventory:GetByCharacterID(characterID)
    local inventories = {}

    for _, inv in pairs(self.Stored) do
        if ( inv:GetOwner() == characterID ) then
            table.insert(inventories, inv)
        end
    end

    return inventories
end

Parallax.inventory = Parallax.Inventory