--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DEFINE_BASECLASS("EditablePanel")

local PANEL = {}

function PANEL:Init()
    Parallax.GUI.inventory = self

    self:Dock(FILL)

    self.buttons = self:Add("Parallax.Scroller.Horizontal")
    self.buttons:Dock(TOP)
    self.buttons:DockMargin(0, ScreenScaleH(4), 0, 0)
    self.buttons:SetTall(ScreenScaleH(24))
    self.buttons.Paint = nil

    self.container = self:Add("Parallax.Scroller.Vertical")
    self.container:Dock(FILL)
    self.container:GetVBar():SetWide(0)
    self.container.Paint = nil

    self.info = self:Add("EditablePanel")
    self.info:Dock(RIGHT)
    self.info:DockPadding(ScreenScale(4), ScreenScaleH(4), ScreenScale(4), ScreenScaleH(4))
    self.info:SetWide(ScreenScale(128))
    self.info.Paint = function(this, width, height)
        draw.RoundedBox(0, 0, 0, width, height, Color(0, 0, 0, 150))
    end

    local inventories = Parallax.Inventory:GetByCharacterID(Parallax.Client:GetCharacter():GetID())
    if ( #inventories == 0 ) then
        local label = self.buttons:Add("Parallax.Text")
        label:Dock(FILL)
        label:SetFont("Parallax.Large")
        label:SetText("inventory.empty")
        label:SetContentAlignment(5)

        return
    end

    for _, inventory in pairs(inventories) do
        local button = self.buttons:Add("Parallax.Button.Flat")
        button:Dock(LEFT)
        button:SetText(inventory:GetName())
        button:SizeToContents()

        button.DoClick = function()
            self:SetInventory(inventory:GetID())
        end
    end

    -- Pick the first inventory by default
    local firstInventory = inventories[1]
    if ( firstInventory ) then
        self:SetInventory(firstInventory:GetID())
    end
end

function PANEL:SetInventory(id)
    if ( !id ) then return end

    local inventory = Parallax.Inventory:Get(id)
    if ( !inventory ) then return end

    self.container:Clear()

    local total = inventory:GetWeight() / Parallax.Config:Get("inventory.max.weight", 20)

    local progress = self.container:Add("DProgress")
    progress:Dock(TOP)
    progress:SetFraction(total)
    progress:SetTall(ScreenScale(12))
    progress:DockMargin(0, 0, ScreenScale(8), 0)
    progress.Paint = function(this, width, height)
        draw.RoundedBox(0, 0, 0, width, height, Color(0, 0, 0, 150))

        local fraction = this:GetFraction()
        draw.RoundedBox(0, 0, 0, width * fraction, height, Color(100, 200, 175, 200))
    end

    local maxWeight = Parallax.Config:Get("inventory.max.weight", 20)
    local weight = math.Round(maxWeight * progress:GetFraction(), 2)

    local label = progress:Add("Parallax.Text")
    label:Dock(FILL)
    label:SetFont("parallax")
    label:SetText(weight .. "kg / " .. maxWeight .. "kg")
    label:SetContentAlignment(5)

    local items = inventory:GetItems()
    if ( #items == 0 ) then
        label = self.container:Add("Parallax.Text")
        label:Dock(TOP)
        label:SetFont("Parallax.Large")
        label:SetText("inventory.empty")
        label:SetContentAlignment(5)

        self:SetInfo()

        return
    end

    local sortedItems = {}
    local itemsCount = #items

    for i = 1, itemsCount do
        local itemID = items[i]
        local item = Parallax.Item:Get(itemID)
        if ( item ) then
            table.insert(sortedItems, itemID)
        end
    end

    local sortType = Parallax.Option:Get("inventory.sort")
    table.sort(sortedItems, function(a, b)
        local itemA = Parallax.Item:Get(a)
        local itemB = Parallax.Item:Get(b)

        if ( !itemA or !itemB ) then return false end

        if ( sortType == "name" ) then
            return itemA:GetName() < itemB:GetName()
        elseif ( sortType == "weight" ) then
            return itemA:GetWeight() < itemB:GetWeight()
        elseif ( sortType == "category" ) then
            return itemA:GetCategory() < itemB:GetCategory()
        end

        return false
    end)

    local groups = {}
    for i = 1, #sortedItems do
        local itemID = sortedItems[i]
        local item = Parallax.Item:Get(itemID)
        if ( item ) then
            local uid = item:GetUniqueID()
            local def = Parallax.Item.stored[uid] or {}
            local stackable = ( !def.NoStack )
            local dataKey = stackable and util.TableToJSON(item:GetData() or {}) or tostring(itemID)
            local key = util.CRC(uid .. dataKey)

            if ( !groups[key] ) then
                groups[key] = {
                    firstID = itemID,
                    count = 0
                }
            end

            groups[key].count = groups[key].count + 1
        end
    end

    for _, group in pairs(groups) do
        local pnl = self.container:Add("Parallax.Item")
        pnl:Dock(TOP)
        pnl:DockMargin(0, 0, ScreenScale(8), 0)
        pnl:SetItem(group.firstID)
        pnl:SetCount(group.count)
    end

    if ( Parallax.GUI.inventoryItemIDLast and self:IsValidItemID(Parallax.GUI.inventoryItemIDLast) ) then
        self:SetInfo(Parallax.GUI.inventoryItemIDLast)
    else
        self:SetInfo(sortedItems[1])
    end
end

function PANEL:IsValidItemID(id)
    if ( !id or !tonumber(id) ) then return false end

    local item = Parallax.Item:Get(id)
    if ( !item ) then return false end

    local inventory = Parallax.Client:GetInventoryByID(item:GetInventory())
    if ( !inventory ) then return false end

    return true
end

function PANEL:SetInfo(id)
    self.info:Clear()

    if ( !self:IsValidItemID(id) ) then
        return
    end

    Parallax.GUI.inventoryItemIDLast = id

    local item = Parallax.Item:Get(id)

    local icon = self.info:Add("DAdjustableModelPanel")
    icon:Dock(TOP)
    icon:SetSize(self.info:GetWide() - 32, self.info:GetWide() - 32)
    icon:SetModel(item:GetModel())
    icon:SetSkin(item:GetSkin())

    local entity = icon:GetEntity()
    local pos = entity:GetPos()
    local camData = PositionSpawnIcon(entity, pos)
    if ( camData ) then
        icon:SetCamPos(camData.origin)
        icon:SetFOV(camData.fov)
        icon:SetLookAng(camData.angles)
    end

    local name = self.info:Add("Parallax.Text")
    name:Dock(TOP)
    name:DockMargin(0, 0, 0, -ScreenScaleH(4))
    name:SetFont("Parallax.Large.bold")
    name:SetText(item:GetName(), true)

    local description = item:GetDescription()
    local descriptionWrapped = Parallax.Util:GetWrappedText(description, "parallax", self.info:GetWide() - 32)
    for k, v in pairs(descriptionWrapped) do
        local text = self.info:Add("Parallax.Text")
        text:Dock(TOP)
        text:DockMargin(0, 0, 0, -ScreenScaleH(4))
        text:SetText(v, true)
    end

    local actions = self.info:Add("DIconLayout")
    actions:Dock(BOTTOM)
    actions:DockMargin(-ScreenScale(4), ScreenScaleH(4), -ScreenScale(4), -ScreenScaleH(4))
    actions:SetSpaceX(0)
    actions:SetSpaceY(0)
    actions.Paint = nil

    timer.Simple(0.1, function()
        for actionName, actionData in pairs(item.Actions or {}) do
            if ( actionName == "Take" ) then continue end
            if ( isfunction(actionData.OnCanRun) and actionData:OnCanRun(item, Parallax.Client) == false ) then continue end

            local button = actions:Add("Parallax.Button.Flat")
            button:SetText(actionData.Name or actionName)
            button:SizeToContents()
            button.DoClick = function()
                Parallax.Net:Start("item.perform", id, actionName)
            end

            if ( actionData.Icon ) then
                button:SetIcon(actionData.Icon)
            end
        end
    end)
end

vgui.Register("Parallax.Inventory", PANEL, "EditablePanel")