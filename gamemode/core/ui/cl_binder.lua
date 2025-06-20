--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- ax.binder
-- A simple key binder panel for binding a single key input.
-- @panel ax.binder

local PANEL = {}

AccessorFunc(PANEL, "m_iSelectedNumber", "SelectedNumber", FORCE_NUMBER)

ax.binds = ax.binds or {}
local release = {}
hook.Add("Think", "ax.keybinds.logic", function()
    for settingName, keyCode in pairs(ax.binds) do
        local settingData = ax.option.stored[settingName]
        if ( !istable(settingData) or settingData.Type != ax.types.number or !settingData.IsKeybind ) then continue end
        if ( !isnumber(keyCode) ) then continue end

        if ( input.IsKeyDown(keyCode) ) then
            if ( !release[settingName] ) then
                release[settingName] = true

                if ( isfunction(settingData.OnPressed) ) then
                    settingData:OnPressed()
                end

                hook.Run("PostKeybindPressed", settingName, keyCode)
            end
        else
            if ( release[settingName] ) then
                if ( isfunction(settingData.OnReleased) ) then
                    settingData:OnReleased()
                end

                hook.Run("PostKeybindReleased", settingName, keyCode)
            end

            release[settingName] = false
        end
    end
end)

function PANEL:Init()
    self:SetText("")
    self:SetFont("parallax")
    self:SetContentAlignment(5)
    self:SetDrawBackground(true)
    self:SetDrawBorder(true)
    self:SetPaintBackgroundEnabled(true)
    self:SetPaintBorderEnabled(true)
    self:SetSelectedNumber(0)
    self:SetMouseInputEnabled(true)
    self:SetKeyboardInputEnabled(false)

    self.Trapping = false
end

function PANEL:OnMouseReleased(mouseCode)
    if ( mouseCode != MOUSE_LEFT ) then return end
    self:GetParent():RequestFocus()
    self:SetText("...")

    input.StartKeyTrapping()
    self.Trapping = true
    self:SetKeyboardInputEnabled(true)
end

function PANEL:OnKeyCodePressed(code)

end

function PANEL:OnChange(code)
    -- Optional override
end

function PANEL:UpdateText()
    self:SetText(input.GetKeyName(self:GetSelectedNumber()) or "None")
end

function PANEL:AllowEnter(bAllow)
    self.AllowEnter = bAllow
end

function PANEL:SetValue(value)
    self:SetSelectedNumber(value)
    self:UpdateText()
end

function PANEL:Think()
    if ( self.Trapping and !self:IsKeyboardInputEnabled() ) then
        self.Trapping = false

        return
    end

    if ( input.IsKeyTrapping() and self.Trapping ) then
        local code = input.CheckKeyTrapping()
        if ( !isnumber(code) ) then return end

        if ( code == KEY_ESCAPE ) then
            self:SetKeyboardInputEnabled(false)
            self.Trapping = false
            self:UpdateText()
            return
        end

        self:SetValue(code)
        self:SetKeyboardInputEnabled(false)

        if ( isfunction(self.OnChange) ) then
            self:OnChange(code)
        end

        self.Trapping = false
    end
end

vgui.Register("ax.binder", PANEL, "ax.button")