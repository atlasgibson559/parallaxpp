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

    self.buttons = self:Add("ax.scroller.horizontal")
    self.buttons:Dock(TOP)
    self.buttons:DockMargin(0, ScreenScaleH(4), 0, 0)
    self.buttons:SetTall(ScreenScaleH(24))
    self.buttons.Paint = nil

    self.buttons.btnLeft:SetAlpha(0)
    self.buttons.btnRight:SetAlpha(0)

    self.container = self:Add("ax.scroller.vertical")
    self.container:Dock(FILL)
    self.container:GetVBar():SetWide(0)
    self.container.Paint = nil

    self.search = self:Add("ax.text.entry")
    self.search:Dock(TOP)
    self.search:SetUpdateOnType(true)
    self.search:SetPlaceholderText(ax.localization:GetPhrase("search.description.config"))
    self.search.OnValueChange = function(this, value)
        if ( value and value != "" ) then
            self:PopulateCategory(nil, value)
        else
            self:PopulateCategory(ax.gui.ConfigLast)
        end
    end

    local categories = {}
    for k, v in pairs(ax.config.stored) do
        local found = false
        for i = 1, #categories do
            if ( categories[i] == v.Category ) then
                found = true
                break
            end
        end

        if ( found ) then continue end

        categories[#categories + 1] = v.Category
    end

    for k, v in SortedPairs(categories) do
        local button = self.buttons:Add("ax.button.flat")
        button:Dock(LEFT)
        button:SetText(v)
        button:SizeToContents()

        button.DoClick = function()
            self.search:SetText("")
            self.search:OnValueChange("")
            self:PopulateCategory(v)
        end

        self.buttons:AddPanel(button)
    end

    if ( ax.gui.ConfigLast ) then
        self:PopulateCategory(ax.gui.ConfigLast)
    else
        self:PopulateCategory(categories[1])
    end
end

function PANEL:PopulateCategory(category, toSearch)
    if ( category ) then
        ax.gui.ConfigLast = category
    end

    self.container:Clear()

    local config = {}
    for k, v in pairs(ax.config.stored) do
        if ( category and ax.util:FindString(v.Category, category) == false ) then
            continue
        end

        if ( toSearch and ax.util:FindString(ax.localization:GetPhrase(v.Name), toSearch) == false ) then
            continue
        end

        config[#config + 1] = v
    end

    table.sort(config, function(a, b)
        return ax.localization:GetPhrase(a.Name) < ax.localization:GetPhrase(b.Name)
    end)

    local subCategories = {}
    for i = 1, #config do
        local v = config[i]
        local subCategory = string.lower(v.SubCategory or "")
        if ( subCategory and !subCategories[subCategory] ) then
            subCategories[subCategory] = true
        end
    end

    if ( table.Count(subCategories) > 1 ) then
        for k, v in SortedPairs(subCategories) do
            local label = self.container:Add("ax.text")
            label:Dock(TOP)
            label:DockMargin(0, 0, 0, ScreenScaleH(4))
            label:SetFont("ax.huge.bold")
            label:SetText(string.upper(k))

            for k2, v2 in SortedPairs(config) do
                if ( string.lower(v2.SubCategory or "") == string.lower(k) ) then
                    self:AddConfig(v2)
                end
            end
        end
    else
        for k, v in SortedPairs(config) do
            self:AddConfig(v)
        end
    end
end

function PANEL:AddConfig(configData)
    local value = ax.config:Get(configData.UniqueID)

    local panel = self.container:Add("ax.button.flat")
    panel:Dock(TOP)
    panel:SetText(configData.Name)
    panel:SetTall(ScreenScaleH(26))
    panel:SetContentAlignment(4)
    panel:SetTextInset(ScreenScale(6), 0)

    local enabled = ax.localization:GetPhrase("enabled")
    local enable = ax.localization:GetPhrase("enable")
    local disabled = ax.localization:GetPhrase("disabled")
    local disable = ax.localization:GetPhrase("disable")
    local unknown = ax.localization:GetPhrase("unknown")

    local label
    local configs
    if ( configData.Type == ax.types.bool ) then
        label = panel:Add("ax.text")
        label:Dock(RIGHT)
        label:DockMargin(0, 0, ScreenScale(8), 0)
        label:SetText(value and enabled or disabled, true)
        label:SetFont("ax.large")
        label:SetWide(ScreenScale(192))
        label:SetContentAlignment(6)
        label.Think = function(this)
            this:SetTextColor(panel:GetTextColor())
        end

        panel.DoClick = function()
            net.Start("ax.config.set")
                net.WriteString(configData.UniqueID)
                net.WriteType(!value)
            net.SendToServer()

            value = !value

            label:SetText(value and "< " .. enabled .. " >" or "< " .. disabled .. " >", true)
        end

        panel.DoRightClick = function()
            local menu = DermaMenu()
            menu:AddOption(ax.localization:GetPhrase("reset"), function()
                net.Start("ax.config.reset")
                    net.WriteString(configData.UniqueID)
                net.SendToServer()

                value = ax.config:GetDefault(configData.UniqueID)
                label:SetText(value and enabled or disabled, true)
            end):SetIcon("icon16/arrow_refresh.png")
            menu:AddSpacer()
            menu:AddOption(value and disable or enable, function()
                net.Start("ax.config.set")
                    net.WriteString(configData.UniqueID)
                    net.WriteType(!value)
                net.SendToServer()

                value = !value

                label:SetText(value and "< " .. enabled .. " >" or "< " .. disabled .. " >", true)
            end):SetIcon(value and "icon16/cross.png" or "icon16/tick.png")

            if ( ax.client:IsDeveloper() and ax.config:Get("debug.developer") ) then
                menu:AddSpacer()
                menu:AddOption(ax.localization:GetPhrase("copy"), function()
                    SetClipboardText(configData.UniqueID)
                    ax.client:EmitSound("ui/buttonclickrelease.wav", 60, 100, 0.1, CHAN_STATIC)
                end):SetIcon("icon16/pencil.png")
            end

            menu:Open()
        end
    elseif ( configData.Type == ax.types.number ) then
        local slider = panel:Add("ax.slider")
        slider:Dock(RIGHT)
        slider:DockMargin(ScreenScale(8), ScreenScaleH(6), ScreenScale(8), ScreenScaleH(6))
        slider:SetWide(ScreenScale(192))
        slider:SetMouseInputEnabled(false)

        slider.Paint = function(this, width, height)
            draw.RoundedBox(0, 0, 0, width, height, ax.color:Get("background.slider"))
            local fraction = (this.value - this.min) / (this.max - this.min)
            local barWidth = math.Clamp(fraction * width, 0, width)
            local inertia = panel:GetInertia()
            local full = 255 * (-inertia + 1)
            draw.RoundedBox(0, 0, 0, barWidth, height, Color(full, full, full, 255))
        end

        slider.Think = function(this)
            local x, y = this:CursorPos()
            local w, h = this:GetSize()
            if ( x >= 0 and x <= w and y >= 0 and y <= h ) then
                this.bCursorInside = true
            else
                this.bCursorInside = false
            end
        end

        slider:SetMin(configData.Min or 0)
        slider:SetMax(configData.Max or 100)
        slider:SetDecimals(configData.Decimals or 0)
        slider:SetValue(value, true)

        label = panel:Add("ax.text")
        label:Dock(RIGHT)
        label:DockMargin(0, 0, -ScreenScale(4), 8)
        label:SetText(value)
        label:SetFont("ax.large")
        label:SetWide(ScreenScale(192))
        label:SetContentAlignment(6)
        label.Think = function(this)
            this:SetTextColor(panel:GetTextColor())
            this:SetText(tostring(slider:GetValue()), true, true)
        end

        slider.OnValueChanged = function(this, _)
            net.Start("ax.config.set")
                net.WriteString(configData.UniqueID)
                net.WriteType(this:GetValue())
            net.SendToServer()

            ax.client:EmitSound("ui/buttonrollover.wav", 100, 100, 1, CHAN_STATIC)
        end

        panel.DoClick = function(this)
            if ( !slider.bCursorInside ) then
                net.Start("ax.config.reset")
                    net.WriteString(configData.UniqueID)
                net.SendToServer()

                value = ax.config:GetDefault(configData.UniqueID)
                slider:SetValue(value)
                label:SetText(value)

                return
            end

            slider.dragging = true
            slider:MouseCapture(true)
            slider:OnCursorMoved(slider:CursorPos())
        end

        panel.DoRightClick = function(this)
            local menu = DermaMenu()
            menu:AddOption(ax.localization:GetPhrase("reset"), function()
                net.Start("ax.config.reset")
                    net.WriteString(configData.UniqueID)
                net.SendToServer()

                value = ax.config:GetDefault(configData.UniqueID)
                slider:SetValue(value)
                label:SetText(value)
            end):SetIcon("icon16/arrow_refresh.png")
            menu:AddSpacer()
            menu:AddOption(ax.localization:GetPhrase("set"), function()
                Derma_StringRequest(
                    ax.localization:GetPhrase("set", configData.Name),
                    ax.localization:GetPhrase("set.description.config", configData.Name),
                    value,
                    function(text)
                        if ( text == "" ) then return end

                        local num = tonumber(text)
                        if ( !num ) then
                            Derma_Message(ax.localization:GetPhrase("invalid.number"), "Error", "OK")
                            return
                        end

                        net.Start("ax.config.set")
                            net.WriteString(configData.UniqueID)
                            net.WriteType(num)
                        net.SendToServer()

                        value = num
                        slider:SetValue(value)
                        label:SetText(value)
                    end
                )
            end):SetIcon("icon16/pencil.png")

            if ( ax.client:IsDeveloper() and ax.config:Get("debug.developer") ) then
                menu:AddSpacer()
                menu:AddOption(ax.localization:GetPhrase("copy"), function()
                    SetClipboardText(configData.UniqueID)
                    ax.client:EmitSound("ui/buttonclickrelease.wav", 60, 100, 0.1, CHAN_STATIC)
                end):SetIcon("icon16/pencil.png")
            end

            menu:Open()
        end
    elseif ( configData.Type == ax.types.array ) then
        configs = configData:Populate()
        local keys = {}
        for k2, _ in pairs(configs) do
            keys[#keys + 1] = k2
        end

        local phrase = (configs and configs[value]) and ax.localization:GetPhrase(configs[value]) or unknown

        label = panel:Add("ax.text")
        label:Dock(RIGHT)
        label:DockMargin(0, 0, ScreenScale(8), 0)
        label:SetText(phrase, true)
        label:SetFont("ax.large")
        label:SetWide(ScreenScale(192))
        label:SetContentAlignment(6)
        label.Think = function(this)
            this:SetTextColor(panel:GetTextColor())
        end

        panel.DoClick = function()
            -- Pick the next key depending on where the cursor is near the label, if the cursor is near the left side of the label, pick the previous key, if it's near the right side, pick the next key.
            local newKey = value
            local x, y = label:CursorPos()
            local w, h = label:GetSize()
            local pitch = 100
            if ( x < w / 2 ) then
                -- Cursor is on the left side, pick the previous key.
                local index = table.KeyFromValue(keys, value)
                if ( index and index > 1 ) then
                    newKey = keys[index - 1]
                    pitch = 80
                end
            else
                -- Cursor is on the right side, pick the next key.
                local index = table.KeyFromValue(keys, value)
                if ( index and index < #keys ) then
                    newKey = keys[index + 1]
                    pitch = 120
                end
            end

            net.Start("ax.config.set")
                net.WriteString(configData.UniqueID)
                net.WriteType(newKey)
            net.SendToServer()
            value = newKey

            label:SetText("< " .. (configs and configs[value] or unknown) .. " >", true)
        end

        panel.DoRightClick = function()
            local menu = DermaMenu()
            menu:AddOption(ax.localization:GetPhrase("reset"), function()
                net.Start("ax.config.reset")
                    net.WriteString(configData.UniqueID)
                net.SendToServer()
                value = ax.option:Get(configData.UniqueID)

                label:SetText("< " .. (configs and configs[value] or unknown) .. " >", true)
            end):SetIcon("icon16/arrow_refresh.png")
            menu:AddSpacer()
            for k2, v2 in SortedPairs(configs) do
                menu:AddOption(v2, function()
                    net.Start("ax.config.set")
                        net.WriteString(configData.UniqueID)
                        net.WriteType(k2)
                    net.SendToServer()
                    value = k2

                    phrase = (configs and configs[value]) and ax.localization:GetPhrase(configs[value]) or unknown
                    label:SetText(panel:IsHovered() and "< " .. phrase .. " >" or phrase, true)
                end):SetIcon("icon16/tick.png")
            end

            if ( ax.client:IsDeveloper() and ax.config:Get("debug.developer") ) then
                menu:AddSpacer()
                menu:AddOption(ax.localization:GetPhrase("copy"), function()
                    SetClipboardText(configData.UniqueID)
                    ax.client:EmitSound("ui/buttonclickrelease.wav", 60, 100, 0.1, CHAN_STATIC)
                end):SetIcon("icon16/pencil.png")
            end

            menu:Open()
        end
    elseif ( configData.Type == ax.types.color ) then
        local color = panel:Add("EditablePanel")
        color:Dock(RIGHT)
        color:DockMargin(ScreenScale(8), ScreenScaleH(6), ScreenScale(8), ScreenScaleH(6))
        color:SetWide(ScreenScale(192))
        color:SetMouseInputEnabled(false)
        color.color = value
        color.Paint = function(this, width, height)
            draw.RoundedBox(0, 0, 0, width, height, this.color)
        end

        panel.DoClick = function()
            local blocker = vgui.Create("EditablePanel", self)
            blocker:SetSize(ScrW(), ScrH())
            blocker:SetPos(0, 0)
            blocker:MakePopup()
            blocker.Paint = function(this, width, height)
                ax.util:DrawBlur(this, 2)
                draw.RoundedBox(0, 0, 0, width, height, Color(0, 0, 0, 200))
            end
            blocker.OnMousePressed = function(this, key)
                if ( key == MOUSE_LEFT ) then
                    this:Remove()
                end
            end
            blocker.OnKeyPressed = function(this, key)
                this:Remove()
            end
            blocker.Think = function(this)
                if ( ! system.HasFocus() ) then
                    this:Remove()
                end
            end
            blocker.OnRemove = function(this)
                net.Start("ax.config.set")
                    net.WriteString(configData.UniqueID)
                    net.WriteType(value)
                net.SendToServer()
            end

            local frame = blocker:Add("EditablePanel")
            frame:SetSize(300, 200)
            frame:SetPos(gui.MouseX() - 150, gui.MouseY() - 100)

            local mixer = frame:Add("DColorMixer")
            mixer:Dock(FILL)
            mixer:SetAlphaBar(false)
            mixer:SetPalette(true)
            mixer:SetWangs(true)
            mixer:SetColor(value)
            mixer.ValueChanged = function(this, old)
                local new = Color(old.r, old.g, old.b, 255)
                value = new
                color.color = new
            end
        end

        panel.DoRightClick = function()
            local menu = DermaMenu()
            menu:AddOption(ax.localization:GetPhrase("reset"), function()
                net.Start("ax.config.reset")
                    net.WriteString(configData.UniqueID)
                net.SendToServer()

                value = ax.config:GetDefault(configData.UniqueID)
                color.color = value
            end):SetIcon("icon16/arrow_refresh.png")

            if ( ax.client:IsDeveloper() and ax.config:Get("debug.developer") ) then
                menu:AddSpacer()
                menu:AddOption(ax.localization:GetPhrase("copy"), function()
                    SetClipboardText(configData.UniqueID)
                    ax.client:EmitSound("ui/buttonclickrelease.wav", 60, 100, 0.1, CHAN_STATIC)
                end):SetIcon("icon16/pencil.png")
            end

            menu:Open()
        end
    elseif ( configData.Type == ax.types.string ) then
        local text = panel:Add("ax.text.entry")
        text:Dock(RIGHT)
        text:DockMargin(ScreenScale(8), ScreenScaleH(6), ScreenScale(8), ScreenScaleH(6))
        text:SetWide(ScreenScale(192))
        text:SetFont("ax.large")
        text:SetText(value)

        text.OnEnter = function(this)
            local newValue = this:GetText()
            if ( newValue == value ) then return end

            net.Start("ax.config.set")
                net.WriteString(configData.UniqueID)
                net.WriteType(newValue)
            net.SendToServer()

            value = newValue

            ax.client:EmitSound("ui/buttonclickrelease.wav", 60, pitch, 0.1, CHAN_STATIC)
        end

        panel.DoRightClick = function()
            local menu = DermaMenu()
            menu:AddOption(ax.localization:GetPhrase("reset"), function()
                net.Start("ax.config.reset")
                    net.WriteString(configData.UniqueID)
                net.SendToServer()

                value = ax.config:GetDefault(configData.UniqueID)
                text:SetText(value)
            end):SetIcon("icon16/arrow_refresh.png")
            menu:AddSpacer()
            menu:AddOption(ax.localization:GetPhrase("set"), function()
                Derma_StringRequest(
                    ax.localization:GetPhrase("set", configData.Name),
                    ax.localization:GetPhrase("set.description.config", configData.Name),
                    value,
                    function(textString)
                        if ( textString == "" ) then return end

                        net.Start("ax.config.set")
                            net.WriteString(configData.UniqueID)
                            net.WriteString(textString)
                        net.SendToServer()

                        value = textString
                        text:SetText(value)
                    end
                )
            end):SetIcon("icon16/pencil.png")

            if ( ax.client:IsDeveloper() and ax.config:Get("debug.developer") ) then
                menu:AddSpacer()
                menu:AddOption(ax.localization:GetPhrase("copy"), function()
                    SetClipboardText(configData.UniqueID)
                    ax.client:EmitSound("ui/buttonclickrelease.wav", 60, 100, 0.1, CHAN_STATIC)
                end):SetIcon("icon16/pencil.png")
            end

            menu:Open()
        end
    end

    panel.OnHovered = function(this)
        if ( configData.Type == ax.types.bool ) then
            label:SetText(value and "< " .. enabled .. " >" or "< " .. disabled .. " >", true)
        elseif ( configData.Type == ax.types.array ) then
            local phrase = (configs and configs[value]) and ax.localization:GetPhrase(configs[value]) or unknown
            label:SetText("< " .. phrase .. " >", true)
        end

        if ( !IsValid(ax.gui.Tooltip) ) then
            ax.gui.Tooltip = vgui.Create("ax.tooltip")
            ax.gui.Tooltip:SetText(configData.Name, configData.Description)
            ax.gui.Tooltip:SizeToContents()
            ax.gui.Tooltip:SetPanel(this)
        else
            ax.gui.Tooltip:SetText(configData.Name, configData.Description)
            ax.gui.Tooltip:SizeToContents()

            timer.Simple(0, function()
                if ( IsValid(ax.gui.Tooltip) ) then
                    ax.gui.Tooltip:SetPanel(this)
                end
            end)
        end
    end

    panel.OnUnHovered = function(this)
        if ( configData.Type == ax.types.bool ) then
            label:SetText(value and enabled or disabled, true)
        elseif ( configData.Type == ax.types.array ) then
            local phrase = (configs and configs[value]) and ax.localization:GetPhrase(configs[value]) or unknown
            label:SetText(phrase, true)
        end

        if ( IsValid(ax.gui.Tooltip) ) then
            ax.gui.Tooltip:SetPanel(nil)
        end
    end
end

vgui.Register("ax.config", PANEL, "EditablePanel")

ax.gui.ConfigLast = nil
