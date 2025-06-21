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
    self:Dock(FILL)

    local title = self:Add("Parallax.Text")
    title:Dock(TOP)
    title:SetFont("Parallax.Huge.Bold")
    title:SetText("INVENTORY")

    local inventory = self:Add("Parallax.Inventory")
    inventory:Dock(FILL)
    inventory:SetInventory()
end

vgui.Register("Parallax.Tab.Inventory", PANEL, "EditablePanel")