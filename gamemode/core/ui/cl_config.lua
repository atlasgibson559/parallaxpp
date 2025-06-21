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

    self.buttons = self:Add("Parallax.Scroller.Horizontal")
    self.buttons:Dock(TOP)
    self.buttons:DockMargin(0, ScreenScaleH(4), 0, 0)
    self.buttons:SetTall(ScreenScaleH(24))
    self.buttons.Paint = nil

    self.buttons.btnLeft:SetAlpha(0)
    self.buttons.btnRight:SetAlpha(0)

    self.container = self:Add("Parallax.Scroller.Vertical")
    self.container:Dock(FILL)
    self.container:GetVBar():SetWide(0)
    self.container.Paint = nil

    self.search = self:Add("Parallax.Text.entry")
    self.search:Dock(TOP)
    self.search:SetUpdateOnType(true)
    self.search:SetPlaceholderText(Parallax.Localization:GetPhrase("search.description.config"))
    self.search.OnValueChange = function(this, value)
        if ( value and value != "" ) then
            self:PopulateCategory(nil, value)
        else
            self:PopulateCategory(Parallax.GUI.configLast)
        end
    end

    local categories = {}
    for k, v in pairs(Parallax.Config.stored) do
        local found = false
        for i = 1, #categories do
            if ( categories[i] == v.Category ) then
                found = true
                break
            end
        end

        if ( found ) then continue end

        table.insert(categories, v.Category)
    end

    for k, v in SortedPairs(categories) do
        local button = self.buttons:Add("Parallax.Button.Flat")
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

    if ( Parallax.GUI.configLast ) then
        self:PopulateCategory(Parallax.GUI.configLast)
    else
        self:PopulateCategory(categories[1])
    end
end

function PANEL:PopulateCategory(category, toSearch)
    if ( category ) then
        Parallax.GUI.configLast = category
    end

    self.container:Clear()

    local config = {}
    for k, v in pairs(Parallax.Config.stored) do
        if ( category and Parallax.Util:FindString(v.Category, category) == false ) then
            continue
        end

        if ( toSearch and Parallax.Util:FindString(Parallax.Localization:GetPhrase(v.Name), toSearch) == false ) then
            continue
        end

        table.insert(config, v)
    end

    table.sort(config, function(a, b)
        return Parallax.Localization:GetPhrase(a.Name) < Parallax.Localization:GetPhrase(b.Name)
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
            local label = self.container:Add("Parallax.Text")
            label:Dock(TOP)
            label:DockMargin(0, 0, 0, ScreenScaleH(4))
            label:SetFont("Parallax.huge.bold")
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
    local value = Parallax.Config:Get(configData.UniqueID)

    local panel = self.container:Add("Parallax.Button.Flat")
    panel:Dock(TOP)
    panel:SetText(configData.Name)
    panel:SetTall(ScreenScaleH(26))
    panel:SetContentAlignment(4)
    panel:SetTextInset(ScreenScale(6), 0)

    local enabled = Parallax.Localization:GetPhrase("enabled")
    local enable = Parallax.Localization:GetPhrase("enable")
    local disabled = Parallax.Localization:GetPhrase("disabled")
    local disable = Parallax.Localization:GetPhrase("disable")
    local unknown = Parallax.Localization:GetPhrase("unknown")

    local label
    local configs
    if ( configData.Type == Parallax.Types.bool ) then
        label = panel:Add("Parallax.Text")
        label:Dock(RIGHT)
        label:DockMargin(0, 0, ScreenScale(8), 0)
        label:SetText(value and enabled or disabled, true)
        label:SetFont("Parallax.large")
        label:SetWide(ScreenScale(128))
        label:SetContentAlignment(6)
        label.Think = function(this)
            this:SetTextColor(panel:GetTextColor())
        end

        panel.DoClick = function()
            Parallax.Net:Start("config.set", configData.UniqueID, !value)

            value = !value

            label:SetText(value and "< " .. enabled .. " >" or "< " .. disabled .. " >", true)
        end

        panel.DoRightClick = function()
            local menu = DermaMenu()
            menu:AddOption(Parallax.Localization:GetPhrase("reset"), function()
                Parallax.Net:Start("config.reset", configData.UniqueID)

                value = Parallax.Config:GetDefault(configData.UniqueID)
                label:SetText(value and enabled or disabled, true)
            end):SetIcon("icon16/arrow_refresh.png")
            menu:AddSpacer()
            menu:AddOption(value and disable or enable, function()
                Parallax.Net:Start("config.set", configData.UniqueID, !value)

                value = !value

                label:SetText(value and "< " .. enabled .. " >" or "< " .. disabled .. " >", true)
            end):SetIcon(value and "icon16/cross.png" or "icon16/tick.png")

            if ( Parallax.Client:IsDeveloper() and Parallax.Config:Get("debug.developer") ) then
                menu:AddSpacer()
                menu:AddOption(Parallax.Localization:GetPhrase("copy"), function()
                    SetClipboardText(configData.UniqueID)
                    Parallax.Client:EmitSound("ui/buttonclickrelease.wav", 60, 100, 0.1, CHAN_STATIC)
                end):SetIcon("icon16/pencil.png")
            end

            menu:Open()
        end
    elseif ( configData.Type == Parallax.Types.number ) then
        local slider = panel:Add("Parallax.Slider")
        slider:Dock(RIGHT)
        slider:DockMargin(ScreenScale(8), ScreenScaleH(4), ScreenScale(8), ScreenScaleH(4))
        slider:SetWide(ScreenScale(128))
        slider:SetMouseInputEnabled(false)

        slider.Paint = function(this, width, height)
            draw.RoundedBox(0, 0, 0, width, height, Parallax.Color:Get("background.slider"))
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

        label = panel:Add("Parallax.Text")
        label:Dock(RIGHT)
        label:DockMargin(0, 0, -ScreenScale(4), 8)
        label:SetText(value)
        label:SetFont("Parallax.large")
        label:SetWide(ScreenScale(128))
        label:SetContentAlignment(6)
        label.Think = function(this)
            this:SetTextColor(panel:GetTextColor())
            this:SetText(tostring(slider:GetValue()), true, true)
        end

        slider.OnValueChanged = function(this, _)
            Parallax.Net:Start("config.set", configData.UniqueID, this:GetValue())
            Parallax.Client:EmitSound("ui/buttonrollover.wav", 100, 100, 1, CHAN_STATIC)
        end

        panel.DoClick = function(this)
            if ( !slider.bCursorInside ) then
                Parallax.Net:Start("config.reset", configData.UniqueID)

                value = Parallax.Config:GetDefault(configData.UniqueID)
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
            menu:AddOption(Parallax.Localization:GetPhrase("reset"), function()
                Parallax.Net:Start("config.reset", configData.UniqueID)

                value = Parallax.Config:GetDefault(configData.UniqueID)
                slider:SetValue(value)
                label:SetText(value)
            end):SetIcon("icon16/arrow_refresh.png")
            menu:AddSpacer()
            menu:AddOption(Parallax.Localization:GetPhrase("set"), function()
                Derma_StringRequest(
                    Parallax.Localization:GetPhrase("set", configData.Name),
                    Parallax.Localization:GetPhrase("set.description.config", configData.Name),
                    value,
                    function(text)
                        if ( text == "" ) then return end

                        local num = tonumber(text)
                        if ( !num ) then
                            Derma_Message(Parallax.Localization:GetPhrase("invalid.number"), "Error", "OK")
                            return
                        end

                        Parallax.Net:Start("config.set", configData.UniqueID, num)

                        value = num
                        slider:SetValue(value)
                        label:SetText(value)
                    end
                )
            end):SetIcon("icon16/pencil.png")

            if ( Parallax.Client:IsDeveloper() and Parallax.Config:Get("debug.developer") ) then
                menu:AddSpacer()
                menu:AddOption(Parallax.Localization:GetPhrase("copy"), function()
                    SetClipboardText(configData.UniqueID)
                    Parallax.Client:EmitSound("ui/buttonclickrelease.wav", 60, 100, 0.1, CHAN_STATIC)
                end):SetIcon("icon16/pencil.png")
            end

            menu:Open()
        end
    elseif ( configData.Type == Parallax.Types.array ) then
        configs = configData:Populate()
        local keys = {}
        for k2, _ in pairs(configs) do
            table.insert(keys, k2)
        end

        local phrase = (configs and configs[value]) and Parallax.Localization:GetPhrase(configs[value]) or unknown

        label = panel:Add("Parallax.Text")
        label:Dock(RIGHT)
        label:DockMargin(0, 0, ScreenScale(8), 0)
        label:SetText(phrase, true)
        label:SetFont("Parallax.large")
        label:SetWide(ScreenScale(128))
        label:SetContentAlignment(6)
        label.Think = function(this)
            this:SetTextColor(panel:GetTextColor())
        end

        panel.DoClick = function()
            -- Pick the next key depending on where the cursor is near the label, if the cursor is near the left side of the label, pick the previous key, if it's near the right side, pick the next key.
            local x, _ = label:CursorPos()
            local w, _ = label:GetSize()
            local percent = x / w
            local nextKey = nil
            for i = 1, #keys do
                if ( keys[i] == value ) then
                    nextKey = keys[i + (percent < 0.5 and -1 or 1)] or keys[1]
                    break
                end
            end

            nextKey = nextKey or keys[1]
            nextKey = tostring(nextKey)

            Parallax.Net:Start("config.set", configData.UniqueID, nextKey)

            value = nextKey

            label:SetText("< " .. (configs and configs[value] or unknown) .. " >", true)
        end

        panel.DoRightClick = function()
            local menu = DermaMenu()
            menu:AddOption(Parallax.Localization:GetPhrase("reset"), function()
                Parallax.Net:Start("config.reset", configData.UniqueID)

                value = Parallax.Config:GetDefault(configData.UniqueID)
                label:SetText(configs and configs[value] or unknown, true)
            end):SetIcon("icon16/arrow_refresh.png")
            menu:AddSpacer()
            for k2, v2 in SortedPairs(configs) do
                menu:AddOption(v2, function()
                    Parallax.Net:Start("config.set", configData.UniqueID, k2)

                    value = k2

                    phrase = (configs and configs[value]) and Parallax.Localization:GetPhrase(configs[value]) or unknown
                    label:SetText(panel:IsHovered() and "< " .. phrase .. " >" or phrase, true)
                end):SetIcon("icon16/tick.png")
            end

            if ( Parallax.Client:IsDeveloper() and Parallax.Config:Get("debug.developer") ) then
                menu:AddSpacer()
                menu:AddOption(Parallax.Localization:GetPhrase("copy"), function()
                    SetClipboardText(configData.UniqueID)
                    Parallax.Client:EmitSound("ui/buttonclickrelease.wav", 60, 100, 0.1, CHAN_STATIC)
                end):SetIcon("icon16/pencil.png")
            end

            menu:Open()
        end
    elseif ( configData.Type == Parallax.Types.color ) then
        local color = panel:Add("EditablePanel")
        color:Dock(RIGHT)
        color:DockMargin(ScreenScale(8), ScreenScaleH(4), ScreenScale(8), ScreenScaleH(4))
        color:SetWide(ScreenScale(128))
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
                Parallax.Util:DrawBlur(this, 2)
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
                Parallax.Net:Start("config.set", configData.UniqueID, value)
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
            menu:AddOption(Parallax.Localization:GetPhrase("reset"), function()
                Parallax.Net:Start("config.reset", configData.UniqueID)

                value = Parallax.Config:GetDefault(configData.UniqueID)
                color.color = value
            end):SetIcon("icon16/arrow_refresh.png")

            if ( Parallax.Client:IsDeveloper() and Parallax.Config:Get("debug.developer") ) then
                menu:AddSpacer()
                menu:AddOption(Parallax.Localization:GetPhrase("copy"), function()
                    SetClipboardText(configData.UniqueID)
                    Parallax.Client:EmitSound("ui/buttonclickrelease.wav", 60, 100, 0.1, CHAN_STATIC)
                end):SetIcon("icon16/pencil.png")
            end

            menu:Open()
        end
    elseif ( configData.Type == Parallax.Types.string ) then
        local text = panel:Add("Parallax.Text.entry")
        text:Dock(RIGHT)
        text:DockMargin(ScreenScale(8), ScreenScaleH(4), ScreenScale(8), ScreenScaleH(4))
        text:SetWide(ScreenScale(128))
        text:SetFont("Parallax.large")
        text:SetText(value)

        text.OnEnter = function(this)
            local newValue = this:GetText()
            if ( newValue == value ) then return end

            Parallax.Net:Start("config.set", configData.UniqueID, newValue)

            value = newValue

            Parallax.Client:EmitSound("ui/buttonclickrelease.wav", 60, pitch, 0.1, CHAN_STATIC)
        end

        panel.DoRightClick = function()
            local menu = DermaMenu()
            menu:AddOption(Parallax.Localization:GetPhrase("reset"), function()
                Parallax.Net:Start("config.reset", configData.UniqueID)

                value = Parallax.Config:GetDefault(configData.UniqueID)
                text:SetText(value)
            end):SetIcon("icon16/arrow_refresh.png")
            menu:AddSpacer()
            menu:AddOption(Parallax.Localization:GetPhrase("set"), function()
                Derma_StringRequest(
                    Parallax.Localization:GetPhrase("set", configData.Name),
                    Parallax.Localization:GetPhrase("set.description.config", configData.Name),
                    value,
                    function(textString)
                        if ( textString == "" ) then return end

                        Parallax.Net:Start("config.set", configData.UniqueID, textString)

                        value = textString
                        text:SetText(value)
                    end
                )
            end):SetIcon("icon16/pencil.png")

            if ( Parallax.Client:IsDeveloper() and Parallax.Config:Get("debug.developer") ) then
                menu:AddSpacer()
                menu:AddOption(Parallax.Localization:GetPhrase("copy"), function()
                    SetClipboardText(configData.UniqueID)
                    Parallax.Client:EmitSound("ui/buttonclickrelease.wav", 60, 100, 0.1, CHAN_STATIC)
                end):SetIcon("icon16/pencil.png")
            end

            menu:Open()
        end
    end

    panel.OnHovered = function(this)
        if ( configData.Type == Parallax.Types.bool ) then
            label:SetText(value and "< " .. enabled .. " >" or "< " .. disabled .. " >", true)
        elseif ( configData.Type == Parallax.Types.array ) then
            local phrase = (configs and configs[value]) and Parallax.Localization:GetPhrase(configs[value]) or unknown
            label:SetText("< " .. phrase .. " >", true)
        end

        if ( !IsValid(Parallax.GUI.tooltip) ) then
            Parallax.GUI.tooltip = vgui.Create("Parallax.Tooltip")
            Parallax.GUI.tooltip:SetText(configData.Name, configData.Description)
            Parallax.GUI.tooltip:SizeToContents()
            Parallax.GUI.tooltip:SetPanel(this)
        else
            Parallax.GUI.tooltip:SetText(configData.Name, configData.Description)
            Parallax.GUI.tooltip:SizeToContents()

            timer.Simple(0, function()
                if ( IsValid(Parallax.GUI.tooltip) ) then
                    Parallax.GUI.tooltip:SetPanel(this)
                end
            end)
        end
    end

    panel.OnUnHovered = function(this)
        if ( configData.Type == Parallax.Types.bool ) then
            label:SetText(value and enabled or disabled, true)
        elseif ( configData.Type == Parallax.Types.array ) then
            local phrase = (configs and configs[value]) and Parallax.Localization:GetPhrase(configs[value]) or unknown
            label:SetText(phrase, true)
        end

        if ( IsValid(Parallax.GUI.tooltip) ) then
            Parallax.GUI.tooltip:SetPanel(nil)
        end
    end
end

vgui.Register("Parallax.Config", PANEL, "EditablePanel")

Parallax.GUI.configLast = nil