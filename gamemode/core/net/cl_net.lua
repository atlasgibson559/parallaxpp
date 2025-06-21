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

Parallax.Net:Hook("character.cache.all", function(data)
    if ( !istable(data) ) then
        Parallax.Util:PrintError("Invalid data received for character cache!")
        return
    end

    if ( Parallax.Config:Get("debug.developer", false) ) then
        print("Received character cache data:")
        PrintTable(data)
    end

    local client = Parallax.Client
    local clientTable = client:GetTable()

    for k, v in pairs(data) do
        local character = Parallax.Character:CreateObject(v.ID, v, client)
        local characterID = character:GetID()

        Parallax.Character.Stored = Parallax.Character.Stored or {}
        Parallax.Character.Stored[characterID] = character

        clientTable.axCharacters = clientTable.axCharacters or {}
        clientTable.axCharacters[characterID] = character
    end

    -- Rebuild the main menu
    if ( IsValid(Parallax.GUI.Mainmenu) ) then
        Parallax.GUI.Mainmenu:Remove()
        Parallax.GUI.Mainmenu = vgui.Create("Parallax.Mainmenu")
    end

    Parallax.Client:Notify("All characters cached!", NOTIFY_HINT)
end)

Parallax.Net:Hook("character.cache", function(data)
    if ( !istable(data) ) then return end

    local client = Parallax.Client
    local clientTable = client:GetTable()

    local character = Parallax.Character:CreateObject(data.ID, data, client)
    local characterID = character:GetID()

    Parallax.Character.Stored = Parallax.Character.Stored or {}
    Parallax.Character.Stored[characterID] = character

    clientTable.axCharacters = clientTable.axCharacters or {}
    clientTable.axCharacters[characterID] = character
    clientTable.axCharacter = character

    Parallax.Client:Notify("Character " .. characterID .. " cached!", NOTIFY_HINT)
end)

Parallax.Net:Hook("character.create.failed", function(reason)
    if ( !reason ) then return end

    Parallax.Client:Notify(reason)
end)

Parallax.Net:Hook("character.create", function()
    -- Do something here...
end)

Parallax.Net:Hook("character.delete", function(characterID)
    if ( !isnumber(characterID) ) then return end

    local character = Parallax.Character.Stored[characterID]
    if ( !character ) then return end

    Parallax.Character.Stored[characterID] = nil

    local client = Parallax.Client
    local clientTable = client:GetTable()
    if ( clientTable.axCharacters ) then
        clientTable.axCharacters[characterID] = nil
    end

    clientTable.axCharacter = nil

    if ( IsValid(Parallax.GUI.Mainmenu) ) then
        Parallax.GUI.Mainmenu:Populate()
    end

    Parallax.Notification:Add("Character " .. characterID .. " deleted!", 5, Parallax.Config:Get("color.success"))
end)

Parallax.Net:Hook("character.load.failed", function(reason)
    if ( !reason ) then return end

    Parallax.Client:Notify(reason)
end)

Parallax.Net:Hook("character.load", function(characterID)
    if ( characterID == 0 ) then return end

    if ( IsValid(Parallax.GUI.Mainmenu) ) then
        Parallax.GUI.Mainmenu:Remove()
    end

    local client = Parallax.Client

    local character, reason = Parallax.Character:CreateObject(characterID, Parallax.Character.Stored[characterID], client)
    if ( !character ) then
        Parallax.Util:PrintError("Failed to load character ", characterID, ", ", reason, "!")
        return
    end

    local currentCharacter = client:GetCharacter()
    local clientTable = client:GetTable()

    Parallax.Character.Stored = Parallax.Character.Stored or {}
    Parallax.Character.Stored[characterID] = character

    clientTable.axCharacters = clientTable.axCharacters or {}
    clientTable.axCharacters[characterID] = character
    clientTable.axCharacter = character

    hook.Run("PlayerLoadedCharacter", character, currentCharacter)
end)

Parallax.Net:Hook("character.variable.set", function(characterID, key, value)
    if ( !characterID or !key or !value ) then return end

    local character = Parallax.Character:Get(characterID)
    if ( !character ) then return end

    character[key] = value
end)

--[[-----------------------------------------------------------------------------
    Chat Networking
-----------------------------------------------------------------------------]]--

Parallax.Net:Hook("chat.send", function(data)
    if ( !istable(data) ) then return end

    local speaker = data.Speaker and Entity(data.Speaker) or nil
    local uniqueID = data.UniqueID
    local text = data.Text

    local chatData = Parallax.Chat:Get(uniqueID)
    if ( istable(chatData) ) then
        chatData:OnChatAdd(speaker, text)
    end
end)

Parallax.Net:Hook("chat.text", function(data)
    if ( !istable(data) ) then return end

    chat.AddText(unpack(data))
end)

--[[-----------------------------------------------------------------------------
    Config Networking
-----------------------------------------------------------------------------]]--

Parallax.Net:Hook("config.sync", function(data)
    if ( !istable(data) ) then return end

    for key, value in pairs(data) do
        Parallax.Config:Set(key, value)
    end
end)

Parallax.Net:Hook("config.set", function(key, value)
    Parallax.Config:Set(key, value)
end)

--[[-----------------------------------------------------------------------------
    Option Networking
-----------------------------------------------------------------------------]]--

Parallax.Net:Hook("option.set", function(key, value)
    local stored = Parallax.Option.Stored[key]
    if ( !istable(stored) ) then return end

    Parallax.Option:Set(key, value, true)
end)

--[[-----------------------------------------------------------------------------
    Inventory Networking
-----------------------------------------------------------------------------]]--

Parallax.Net:Hook("inventory.cache", function(data)
    if ( !istable(data) ) then return end

    local inventory = Parallax.Inventory:CreateObject(data)
    if ( inventory ) then
        Parallax.Inventory.Stored[inventory:GetID()] = inventory

        local character = Parallax.Character.Stored[inventory.CharacterID]
        if ( character ) then
            local inventories = character:GetInventories()

            local found = false
            for i = 1, #inventories do
                if ( inventories[i] == inventory ) then
                    found = true
                    break
                end
            end

            if ( !found ) then
                table.insert(inventories, inventory)
            end

            character:SetInventories(inventories)
        end
    end
end)

Parallax.Net:Hook("inventory.item.add", function(inventoryID, itemID, uniqueID, data)
    local item = Parallax.Item:Add(itemID, inventoryID, uniqueID, data)
    if ( !item ) then return end

    local inventory = Parallax.Inventory:Get(inventoryID)
    if ( inventory ) then
        local items = inventory:GetItems()
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
    end
end)

Parallax.Net:Hook("inventory.item.remove", function(inventoryID, itemID)
    local inventory = Parallax.Inventory:Get(inventoryID)
    if ( !inventory ) then return end

    local items = inventory:GetItems()
    local found = false
    for i = 1, #items do
        if ( items[i] == itemID ) then
            found = true
            break
        end
    end

    if ( found ) then
        table.RemoveByValue(items, itemID)
    end

    local item = Parallax.Item:Get(itemID)
    if ( item ) then
        item:SetInventory(0)
    end
end)

Parallax.Net:Hook("inventory.refresh", function(inventoryID)
    local panel = Parallax.GUI.Inventory
    if ( IsValid(panel) ) then
        panel:SetInventory(inventoryID)
    end
end)

Parallax.Net:Hook("inventory.register", function(data)
    if ( !istable(data) ) then return end

    local inventory = Parallax.Inventory:CreateObject(data)
    if ( inventory ) then
        Parallax.Inventory.Stored[inventory.ID] = inventory
    end
end)

--[[-----------------------------------------------------------------------------
    Item Networking
-----------------------------------------------------------------------------]]--

Parallax.Net:Hook("item.add", function(itemID, inventoryID, uniqueID, data)
    Parallax.Item:Add(itemID, inventoryID, uniqueID, data)
end)

Parallax.Net:Hook("item.cache", function(data)
    if ( !istable(data) ) then return end

    for k, v in pairs(data) do
        local item = Parallax.Item:CreateObject(v)
        if ( item ) then
            Parallax.Item.Instances[item.ID] = item

            if ( item.OnCache ) then
                item:OnCache()
            end
        end
    end
end)

Parallax.Net:Hook("item.data", function(itemID, key, value)
    local item = Parallax.Item:Get(itemID)
    if ( !item ) then return end

    item:SetData(key, value)
end)

Parallax.Net:Hook("item.entity", function(entity, itemID)
    if ( !IsValid(entity) ) then return end

    local item = Parallax.Item:Get(itemID)
    if ( !item ) then return end

    item:SetEntity(entity)
end)

--[[-----------------------------------------------------------------------------
    Currency Networking
-----------------------------------------------------------------------------]]--

Parallax.Net:Hook("currency.give", function(entity, amount)
    if ( !IsValid(entity) ) then return end

    local phrase = Parallax.Localization:GetPhrase("currency.pickup")
    phrase = string.format(phrase, amount .. Parallax.Currency:GetSymbol())

    Parallax.Client:Notify(phrase)
end)

--[[-----------------------------------------------------------------------------
    Miscellaneous Networking
-----------------------------------------------------------------------------]]--

Parallax.Net:Hook("database.save", function(data)
    Parallax.Client:GetTable().axDatabase = data
end)

Parallax.Net:Hook("gesture.play", function(client, name)
    if ( !IsValid(client) ) then return end

    client:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, client:LookupSequence(name), 0, true)
end)

Parallax.Net:Hook("splash", function()
    Parallax.GUI.Splash = vgui.Create("Parallax.Splash")
end)

Parallax.Net:Hook("mainmenu", function()
    Parallax.GUI.Mainmenu = vgui.Create("Parallax.Mainmenu")
end)

Parallax.Net:Hook("notification.send", function(text, type, duration)
    if ( !text ) then return end

    notification.AddLegacy(text, type, duration)
end)

Parallax.Net:Hook("flag.list", function(target, hasFlags)
    if ( !IsValid(target) or !target:IsPlayer() ) then return end

    local query = {}
    table.insert(query, "Select which flag you want to give to " .. target:Name() .. ".")
    table.insert(query, "Flag List")

    local flags = Parallax.Flag:GetAll()
    local availableFlags = {}
    for key, data in pairs(flags) do
        if ( !isstring(key) or #key != 1 ) then continue end
        if ( hasFlags[key] ) then continue end

        table.insert(query, key)
        table.insert(query, function()
            Parallax.Command:Run("CharGiveFlags", target, key)
        end)

        table.insert(availableFlags, key)
    end

    if ( availableFlags[1] == nil ) then
        Parallax.Client:Notify("The target player already has all flags, so you cannot give them any more!")
        return
    end

    table.insert(query, "Cancel")

    Derma_Query(unpack(query))
end)

-- TODO: This is a temporary solution, should be replaced with a more robust caption library.
local function GetCaptionDuration(...)
    local duration = 0
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if ( isstring(v) ) then
            for _ in string.gmatch(v, "%S+") do
                duration = duration + 0.5
            end
        end
    end

    return duration
end

local function ConvertCaptionToChatArguments(caption)
    local segments = {}
    local pos = 1

    while true do
        local len_s, raw, delay_s, next_pos = string.match(caption,
            "<len:([%d%.]+)>(.-)<delay:([%d%.]+)>()",
            pos
        )
        if ( !len_s ) then break end

        local r, g, b = string.match(raw, "<clr:(%d+),(%d+),(%d+)>")
        local R = r and tonumber(r) or 255
        local G = g and tonumber(g) or 255
        local B = b and tonumber(b) or 255

        local text = raw
        text = string.gsub(text, "<clr:%d+,%d+,%d+>", "")
        text = string.gsub(text, "<I>", "")
        text = string.gsub(text, "<cr>", "\n")
        text = string.match(text, "^%s*(.-)%s*$")

        table.insert(segments, {
            len   = tonumber(len_s),
            color = Color(R, G, B),
            text  = text,
            delay = tonumber(delay_s),
        })

        pos = next_pos
    end

    local rem = string.sub(caption, pos)
    local len_s, raw = string.match(rem, "<len:([%d%.]+)>(.*)")
    if ( len_s and string.match(raw, "%S") ) then
        local r, g, b = string.match(raw, "<clr:(%d+),(%d+),(%d+)>")
        local R = r and tonumber(r) or 255
        local G = g and tonumber(g) or 255
        local B = b and tonumber(b) or 255

        local text = raw
            :gsub("<clr:%d+,%d+,%d+>", "")
            :gsub("<I>", "")
            :gsub("<cr>", "\n")
            :match("^%s*(.-)%s*$")

        table.insert(segments, {
            len   = tonumber(len_s),
            color = Color(R, G, B),
            text  = text,
            delay = nil,
        })
    end

    return segments
end

local function PrintQueue(data, idx)
    local segments, i

    if ( isstring(data) ) then
        segments = ConvertCaptionToChatArguments(data)
        i = 1
    else
        segments = data
        i = idx
    end

    local seg = segments[i]
    if ( !seg ) then return end

    chat.AddText(seg.color, seg.text)

    if ( seg.delay ) then
        timer.Simple(seg.delay, function()
            PrintQueue(segments, i + 1)
        end)
    end
end

-- hook becomes trivial:
Parallax.Net:Hook("caption", function(arguments)
    if ( !isstring(arguments) or arguments == "" ) then
        Parallax.Util:PrintError("Invalid arguments for caption!")
        return
    end

    PrintQueue(arguments)

    gui.AddCaption(arguments, CAPTION_DURATION or GetCaptionDuration(arguments))
end)
