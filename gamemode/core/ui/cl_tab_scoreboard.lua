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

    local title = self:Add("ax.Text")
    title:Dock(TOP)
    title:SetFont("ax.Huge.Bold")
    title:SetText("SCOREBOARD")

    local scoreboard = self:Add("ax.Scoreboard")
    scoreboard:Dock(FILL)
end

vgui.Register("ax.Tab.Scoreboard", PANEL, "EditablePanel")