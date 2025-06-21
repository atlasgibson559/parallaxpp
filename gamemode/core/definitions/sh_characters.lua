--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

Parallax.Character:RegisterVariable("steamid", {
    Type = Parallax.Types.string,
    Field = "steamid",
    Default = ""
})

Parallax.Character:RegisterVariable("schema", {
    Type = Parallax.Types.string,
    Field = "schema",
    Default = "parallax"
})

Parallax.Character:RegisterVariable("data", {
    Type = Parallax.Types.string,
    Field = "data",
    Default = "[]",

    Alias = "DataInternal"
})

Parallax.Character:RegisterVariable("name", {
    Type = Parallax.Types.string,
    Field = "name",
    Default = "John Doe",

    Editable = true,
    ZPos = -3,
    Name = "character.create.name",

    AllowNonAscii = true,
    Numeric = false,

    OnValidate = function(self, parent, payload, client)
        local name = payload.name or ""
        local factionData = Parallax.Faction:Get(payload.faction)
        local lengthMin = factionData.NameLengthMin or Parallax.Config:Get("characters.minNameLength") or 3
        local lengthMax = factionData.NameLengthMax or Parallax.Config:Get("characters.maxNameLength") or 32
        local trimmed = string.Trim(name)
        if ( string.len(trimmed) < lengthMin ) then
            return false, "Name must be at least " .. lengthMin .. " characters long!"
        elseif ( string.len(trimmed) > lengthMax ) then
            return false, "Name must be at most " .. lengthMax .. " characters long!"
        end

        if ( isnumber(string.find(trimmed, "[^%a%d%s]")) and factionData.AllowNonAscii != true ) then
            return false, "Name can only contain letters, numbers and spaces!"
        end

        if ( isnumber(string.find(trimmed, "%s%s")) and factionData.AllowMultipleSpaces != true ) then
            return false, "Name cannot contain multiple spaces in a row!"
        end

        return true
    end
})

Parallax.Character:RegisterVariable("description", {
    Type = Parallax.Types.text,
    Field = "description",
    Default = "A mysterious person.",

    Editable = true,
    ZPos = 0,
    Name = "character.create.description",

    OnValidate = function(self, parent, payload, client)
        local trimmed = string.Trim(payload.description or "")
        local len = string.len(trimmed)

        local minLength = Parallax.Config:Get("characters.minDescriptionLength")
        if ( len < minLength ) then
            return false, "Description must be at least " .. minLength .. " characters long!"
        end

        local maxLength = Parallax.Config:Get("characters.maxDescriptionLength")
        if ( len > maxLength ) then
            return false, "Description must be at most " .. maxLength .. " characters long!"
        end

        return true
    end
})

Parallax.Character:RegisterVariable("model", {
    Type = Parallax.Types.string,
    Field = "model",
    Default = "models/player/kleiner.mdl",

    Editable = true,
    ZPos = 0,
    Name = "character.create.model",

    OnValidate = function(self, parent, payload, client)
        local faction = Parallax.Faction:Get(payload.faction)
        if ( istable(faction) ) then
            local found = false
            for _, v in SortedPairs(faction:GetModels()) do
                local model = istable(v) and v[1] or v

                if ( model == payload.model ) then
                    found = true
                    break
                end
            end

            if ( !found ) then
                return false, "Model is not valid for this faction!"
            end
        end

        return true
    end,

    OnPopulate = function(self, parent, payload, client)
        local label = parent:Add("Parallax.text")
        label:Dock(TOP)
        label:SetFont("Parallax.large")

        local translation = Parallax.Localization:GetPhrase(self.Name)
        local bTranslated = translation != self.Name

        label:SetText(bTranslated and translation or self.Name or k)

        local scroller = parent:Add("Parallax.scroller.vertical")
        scroller:Dock(FILL)

        local layout = scroller:Add("DIconLayout")
        layout:Dock(FILL)
        layout.Paint = function(this, width, height)
            surface.SetDrawColor(Parallax.Color:Get("background.transparent"))
            surface.DrawRect(0, 0, width, height)
        end

        local faction = Parallax.Faction:Get(payload.faction)
        if ( istable(faction) ) then
            for _, v in SortedPairs(faction:GetModels()) do
                local model = istable(v) and v[1] or v

                local icon = layout:Add("SpawnIcon")
                if ( istable(v) ) then
                    icon:SetModel(model, v[2], v[3])
                else
                    icon:SetModel(model)
                end

                icon:SetSize(64, 128)
                icon:SetTooltip(model)
                icon.DoClick = function()
                    Parallax.Client:Notify("You have selected " .. model .. " as your model!", NOTIFY_HINT)
                    payload.model = model
                    layout.selected = icon
                end
                icon.Paint = function(this, w, h)
                    if ( ispanel(layout.selected) and this == layout.selected ) then
                        surface.SetDrawColor(Parallax.Color:Get("white"))
                        surface.DrawRect(0, 0, w, h)
                    end
                end
            end
        end
    end,

    OnSet = function(self, character, value)
        local client = character:GetPlayer()
        if ( IsValid(client) ) then
            client:SetModel(value)
        end
    end
})

Parallax.Character:RegisterVariable("skin", {
    Type = Parallax.Types.number,
    Field = "skin",
    Default = 0
})

Parallax.Character:RegisterVariable("money", {
    Type = Parallax.Types.number,
    Field = "money",
    Default = 0
})

Parallax.Character:RegisterVariable("faction", {
    Type = Parallax.Types.number,
    Field = "faction",
    Default = 0,

    Editable = true,

    OnSet = function(this, character, value)
        local faction = Parallax.Faction:Get(value)
        if ( faction and faction.OnSet ) then
            faction:OnSet(character, value)
        end

        local client = character:GetPlayer()
        if ( IsValid(client) ) then
            client:SetTeam(value)
        end
    end
})

Parallax.Character:RegisterVariable("class", {
    Type = Parallax.Types.number,
    Field = "class",
    Default = 0
})

Parallax.Character:RegisterVariable("flags", {
    Type = Parallax.Types.string,
    Field = "flags",
    Default = "",
})

Parallax.Character:RegisterVariable("play_time", {
    Type = Parallax.Types.number,
    Field = "play_time",
    Alias = "PlayTime",
    Default = 0
})

Parallax.Character:RegisterVariable("last_played", {
    Type = Parallax.Types.number,
    Field = "last_played",
    Alias = "LastPlayed",
    Default = 0
})