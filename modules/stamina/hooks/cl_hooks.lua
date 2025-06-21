--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:ShouldDrawStamina()
    if ( IsValid(Parallax.gui.mainmenu) ) then return false end
    if ( IsValid(Parallax.gui.tab) ) then return false end

    return IsValid(Parallax.Client) and Parallax.Config:Get("stamina", true) and Parallax.Client:Alive() and istable(Parallax.Client:GetRelay("stamina"))
end

local staminaLerp = 0
local staminaAlpha = 0
local staminaTime = 0
local staminaLast = 0
function MODULE:HUDPaint()
    local shouldDraw = hook.Run("ShouldDrawStamina")
    if ( shouldDraw == false ) then
        Parallax.globals.drawingStamina = nil
        return
    end

    local staminaFraction = Parallax.Stamina:GetFraction()
    staminaLerp = Lerp(FrameTime() * 5, staminaLerp, staminaFraction)

    if ( staminaLast != staminaFraction ) then
        staminaTime = CurTime() + 5
        staminaLast = staminaFraction
    elseif ( staminaTime < CurTime() ) then
        staminaAlpha = Lerp(FrameTime() * 2, staminaAlpha, 0)
    elseif ( staminaAlpha < 255 ) then
        staminaAlpha = Lerp(FrameTime() * 8, staminaAlpha, 255)
    end

    if ( math.Round(staminaAlpha) > 0 and staminaLerp > 0 ) then
        local scrW, scrH = ScrW(), ScrH()

        local barWidth, barHeight = scrW / 6, ScreenScale(4)
        local barX, barY = scrW / 2 - barWidth / 2, scrH / 1.025 - barHeight / 2

        Parallax.Util:DrawBlurRect(barX, barY, barWidth, barHeight, 2, nil, staminaAlpha)

        surface.SetDrawColor(ColorAlpha(Parallax.Color:Get("background.transparent"), staminaAlpha / 2))
        surface.DrawRect(barX, barY, barWidth, barHeight)

        surface.SetDrawColor(ColorAlpha(Parallax.Color:Get("white"), staminaAlpha))
        surface.DrawRect(barX, barY, barWidth * staminaLerp, barHeight)

        Parallax.globals.drawingStamina = true
    else
        Parallax.globals.drawingStamina = nil
    end
end