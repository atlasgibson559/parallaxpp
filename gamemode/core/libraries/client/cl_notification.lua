--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

Parallax.Notification = Parallax.Notification or {}
Parallax.Notification.Stored = Parallax.Notification.Stored or {}

-- Configuration
local PANEL_WIDTH = ScrW() / 2.5
local PANEL_MARGIN = 8
local PANEL_SPACING = 4
local INTERP_SPEED = 8
local FONT_NAME = "Parallax.Bold"

-- Utility function to create a notification
function Parallax.Notification:Add(text, duration, bgColor)
    duration = duration or 3
    bgColor.a = 200

    -- Create panel
    local panel = vgui.Create("DPanel")
    panel:SetWide(PANEL_WIDTH)
    panel:SetDrawOnTop(true)

    -- Prepare wrapped lines
    local maxTextWidth = PANEL_WIDTH - PANEL_MARGIN * 2

    local phrase = Parallax.Localization:GetPhrase(text)
    if ( isstring(phrase) ) then text = phrase end

    local lines = Parallax.Util:GetWrappedText(text, FONT_NAME, maxTextWidth)
    surface.SetFont(FONT_NAME)
    local _, lineHeight = surface.GetTextSize("Ay")
    local totalHeight = #lines * lineHeight + PANEL_MARGIN * 2
    panel:SetTall(totalHeight)

    -- Paint background and text
    panel.Paint = function(this, width, height)
        surface.SetDrawColor(bgColor)
        surface.DrawRect(0, 0, width, height)

        -- draw each line
        for i = 1, #lines do
            draw.SimpleText(
                lines[i],
                FONT_NAME,
                PANEL_MARGIN,
                PANEL_MARGIN + (i - 1) * lineHeight,
                Parallax.Color:Get("white"),
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_TOP
            )
        end
    end

    -- Initial position off-screen
    local scrW, _ = ScrW(), ScrH()
    panel.CurrentX = (scrW - PANEL_WIDTH) / 2
    panel.CurrentY = -panel:GetTall()
    panel.TargetX = panel.CurrentX
    panel.TargetY = panel.CurrentY
    panel:SetPos(panel.CurrentX, panel.CurrentY)

    -- Think hook for interpolation
    panel.Think = function(this)
        local frameTime = FrameTime()
        this.CurrentX = Lerp(frameTime * INTERP_SPEED, this.CurrentX, this.TargetX)
        this.CurrentY = Lerp(frameTime * INTERP_SPEED, this.CurrentY, this.TargetY)
        this:SetPos(this.CurrentX, this.CurrentY)
    end

    -- Insert at beginning
    table.insert(self.Stored, 1, panel)

    -- Animate all notifications to new positions
    self:RepositionAll()

    -- Fade in
    panel:SetAlpha(0)
    panel:AlphaTo(255, 0.2, 0)

    -- Remove after duration
    timer.Simple(duration, function()
        if ( IsValid(panel) ) then
            panel:AlphaTo(0, 0.2, 0, function() panel:Remove() end)
            -- Remove and reposition
            timer.Simple(0.35, function()
                for i = 1, #self.Stored do
                    if self.Stored[i] == panel then
                        table.remove(self.Stored, i)
                        break
                    end
                end

                self:RepositionAll()
            end)
        end
    end)
end

-- Reposition notifications using Lerp targets
function Parallax.Notification:RepositionAll()
    local scrW = ScrW()
    local storedCount = #self.Stored
    for i = 1, storedCount do
        local panel = self.Stored[i]
        if ( IsValid(panel) ) then
            panel.TargetX = (scrW - PANEL_WIDTH) / 2
            panel.TargetY = PANEL_SPACING + (i - 1) * (panel:GetTall() + PANEL_SPACING)
        end
    end
end

notification.AddLegacy = function(text, type, length)
    local color
    if ( type == NOTIFY_ERROR ) then
        color = Parallax.Config:Get("color.error")
        Parallax.Client:EmitSound("Parallax.Notification.error")
    elseif ( type == NOTIFY_HINT ) then
        color = Parallax.Config:Get("color.success")
        Parallax.Client:EmitSound("Parallax.Notification.hint")
    else
        color = Parallax.Config:Get("color.info")
        Parallax.Client:EmitSound("Parallax.Notification.generic")
    end

    Parallax.Notification:Add(text, length or 3, color)
end

concommand.Add("test_notification", function(client, cmd, arguments)
    local text = table.concat(arguments, " ")
    Parallax.Notification:Add(text, 5)
end)

sound.Add({
    name = "Parallax.Notification.error",
    channel = CHAN_STATIC,
    volume = 1.0,
    level = 80,
    sound = "parallax/ui/error.wav"
})

sound.Add({
    name = "Parallax.Notification.hint",
    channel = CHAN_STATIC,
    volume = 1.0,
    level = 80,
    sound = "parallax/ui/hint.wav"
})

sound.Add({
    name = "Parallax.Notification.generic",
    channel = CHAN_STATIC,
    volume = 1.0,
    level = 80,
    sound = "parallax/ui/generic.wav"
})

Parallax.notification = Parallax.Notification