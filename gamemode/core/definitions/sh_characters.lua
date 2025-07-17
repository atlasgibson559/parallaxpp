--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.character:RegisterVariable("steamid", {
    Type = ax.types.string,
    Field = "steamid",
    Default = ""
})

ax.character:RegisterVariable("schema", {
    Type = ax.types.string,
    Field = "schema",
    Default = "parallax"
})

ax.character:RegisterVariable("data", {
    Type = ax.types.string,
    Field = "data",
    Default = "[]",

    Alias = "DataInternal"
})

ax.character:RegisterVariable("name", {
    Type = ax.types.string,
    Field = "name",
    Default = "John Doe",

    Editable = true,
    ZPos = -3,
    Name = "character.create.name",

    AllowNonAscii = true,
    Numeric = false,

    OnValidate = function(self, parent, payload, client)
        if ( !isstring(payload.name) ) then
            return false, "Name must be a string!"
        end

        local name = payload.name or ""
        local factionData = ax.faction:Get(payload.faction)
        if ( !ax.util:IsFaction(factionData) ) then
            return false, "Invalid faction!"
        end

        local lengthMin = factionData.NameLengthMin or ax.config:Get("characters.minNameLength") or 3
        local lengthMax = factionData.NameLengthMax or ax.config:Get("characters.maxNameLength") or 32
        local trimmed = string.Trim(name)
        if ( string.len(trimmed) < lengthMin ) then
            return false, "Name must be at least " .. lengthMin .. " characters long!"
        elseif ( string.len(trimmed) > lengthMax ) then
            return false, "Name must be at most " .. lengthMax .. " characters long!"
        end

        if ( isnumber(ax.util:FindString(trimmed, "[^%a%d%s]")) and factionData.AllowNonAscii != true ) then
            return false, "Name can only contain letters, numbers and spaces!"
        end

        if ( isnumber(ax.util:FindString(trimmed, "%s%s")) and factionData.AllowMultipleSpaces != true ) then
            return false, "Name cannot contain multiple spaces in a row!"
        end

        return true
    end
})

ax.character:RegisterVariable("description", {
    Type = ax.types.text,
    Field = "description",
    Default = "A mysterious person.",

    Editable = true,
    ZPos = 0,
    Name = "character.create.description",

    OnValidate = function(self, parent, payload, client)
        if ( !isstring(payload.description) ) then
            return false, "Description must be a string!"
        end

        local trimmed = string.Trim(payload.description or "")
        local len = string.len(trimmed)

        local minLength = ax.config:Get("characters.minDescriptionLength")
        if ( len < minLength ) then
            return false, "Description must be at least " .. minLength .. " characters long!"
        end

        local maxLength = ax.config:Get("characters.maxDescriptionLength")
        if ( len > maxLength ) then
            return false, "Description must be at most " .. maxLength .. " characters long!"
        end

        return true
    end
})

ax.character:RegisterVariable("model", {
    Type = ax.types.string,
    Field = "model",
    Default = "models/player/kleiner.mdl",

    Editable = true,
    ZPos = 0,
    Name = "character.create.model",

    OnValidate = function(self, parent, payload, client)
        local faction = ax.faction:Get(payload.faction)
        if ( ax.util:IsFaction(faction) ) then
            for _, v in SortedPairs(faction:GetModels()) do
                local model = istable(v) and v[1] or v

                if ( model == payload.model ) then
                    return true
                end
            end

            return false, "Model is not valid for this faction!"
        end

        return false
    end,

    OnPopulate = function(self, parent, payload, client)
        local label = parent:Add("ax.text")
        label:Dock(TOP)
        label:SetFont("ax.large")

        local translation = ax.localization:GetPhrase(self.Name)
        local bTranslated = translation != self.Name

        label:SetText(bTranslated and translation or self.Name or k)

        local scroller = parent:Add("ax.scroller.vertical")
        scroller:Dock(FILL)

        local layout = scroller:Add("DIconLayout")
        layout:Dock(FILL)
        layout.Paint = function(this, width, height)
            surface.SetDrawColor(ax.color:Get("background.transparent"))
            surface.DrawRect(0, 0, width, height)
        end

        local faction = ax.faction:Get(payload.faction)
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
                    ax.client:Notify("You have selected " .. model .. " as your model!", NOTIFY_HINT)
                    payload.model = model
                    layout.selected = icon
                end
                icon.Paint = function(this, w, h)
                    if ( ispanel(layout.selected) and this == layout.selected ) then
                        surface.SetDrawColor(ax.color:Get("white"))
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

ax.character:RegisterVariable("skin", {
    Type = ax.types.number,
    Field = "skin",
    Default = 0
})

ax.character:RegisterVariable("money", {
    Type = ax.types.number,
    Field = "money",
    Default = 0
})

ax.character:RegisterVariable("faction", {
    Type = ax.types.number,
    Field = "faction",
    Default = 0,

    Editable = true,

    OnSet = function(this, character, value)
        local faction = ax.faction:Get(value)
        if ( faction and faction.OnSet ) then
            faction:OnSet(character, value)
        end

        local client = character:GetPlayer()
        if ( IsValid(client) ) then
            client:SetTeam(value)
        end
    end,
})

ax.character:RegisterVariable("class", {
    Type = ax.types.number,
    Field = "class",
    Default = 0
})

ax.character:RegisterVariable("flags", {
    Type = ax.types.string,
    Field = "flags",
    Default = "",
})

ax.character:RegisterVariable("play_time", {
    Type = ax.types.number,
    Field = "play_time",
    Alias = "PlayTime",
    Default = 0
})

ax.character:RegisterVariable("last_played", {
    Type = ax.types.number,
    Field = "last_played",
    Alias = "LastPlayed",
    Default = 0
})