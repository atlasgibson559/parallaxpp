--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Character library.
-- @module Parallax.Character

Parallax.Character = Parallax.Character or {} -- Character library.
Parallax.Character.Meta = Parallax.Character.Meta or {} -- All currently registered character meta functions.
Parallax.Character.variables = Parallax.Character.variables or {} -- All currently registered variables.
Parallax.Character.fields = Parallax.Character.fields or {} -- All currently registered fields.
Parallax.Character.Stored = Parallax.Character.Stored or {} -- All currently stored characters which are in use.

--- Registers a variable for the character.
-- @realm shared
function Parallax.Character:RegisterVariable(key, data)
    data.Index = table.Count(self.variables) + 1

    if ( data.Alias != nil ) then
        if ( isstring(data.Alias) ) then
            data.Alias = { data.Alias }
        end

        for i = 1, #data.Alias do
            local v = data.Alias[i]
            self.Meta["Get" .. v] = function(character)
                return self:GetVariable(character:GetID(), key)
            end

            if ( SERVER ) then
                self.Meta["Set" .. v] = function(character, value)
                    self:SetVariable(character:GetID(), key, value)
                end

                local field = data.Field
                if ( field ) then
                    Parallax.Database:RegisterVar("ax_characters", key, data.Default or nil)
                    self.fields[key] = field
                end
            end
        end
    else
        local upperKey = string.upper(key:sub(1, 1)) .. key:sub(2)

        self.Meta["Get" .. upperKey] = function(character)
            return self:GetVariable(character:GetID(), key)
        end

        if ( SERVER ) then
            self.Meta["Set" .. upperKey] = function(character, value)
                self:SetVariable(character:GetID(), key, value)
            end

            local field = data.Field
            if ( field ) then
                Parallax.Database:RegisterVar("ax_characters", key, data.Default or nil)
                self.fields[key] = field
            end
        end
    end

    self.variables[key] = data
end

function Parallax.Character:SetVariable(id, key, value)
    if ( !self.variables[key] ) then
        Parallax.Util:PrintError("Attempted to set a variable that does not exist!")
        return false, "Attempted to set a variable that does not exist!"
    end

    local character = self.Stored[id]
    if ( !character ) then
        Parallax.Util:PrintError("Attempted to set a variable for a character that does not exist!")
        return false, "Attempted to set a variable for a character that does not exist!"
    end

    local data = self.variables[key]
    if ( data.OnSet ) then
        value = data:OnSet(character, value)
    end

    character[key] = value

    if ( SERVER ) then
        Parallax.Database:Update("ax_characters", { [key] = value }, "id = " .. id)

        if ( data.Field ) then
            local field = data.Field
            if ( field ) then
                Parallax.Database:Update("ax_characters", { [field] = value }, "id = " .. id)
            end
        end

        if ( !data.NoNetworking ) then
            Parallax.Net:Start(nil, "character.variable.set", id, key, value)
        end
    end
end

function Parallax.Character:GetVariable(id, key)
    local character = self.Stored[id]
    if ( !character ) then
        Parallax.Util:PrintError("Attempted to get a variable for a character that does not exist!")
        return false, "Attempted to get a variable for a character that does not exist!"
    end

    local variable = self.variables[key]
    if ( !variable ) then return end

    local output = Parallax.Util:CoerceType(variable.Type, character[key])
    if ( variable.OnGet ) then
        return variable:OnGet(character, output)
    end

    return output
end

function Parallax.Character:CreateObject(characterID, data, client)
    if ( !characterID or !data ) then
        Parallax.Util:PrintError("Attempted to create a character object with invalid data!")
        return false, "Invalid data provided"
    end

    if ( self.Stored[characterID] ) then
        Parallax.Util:PrintWarning("Attempted to create a character object that already exists!")
        return self.Stored[characterID], "Character already exists"
    end

    characterID = tonumber(characterID)

    local character = setmetatable({}, self.Meta)
    character.ID = characterID
    character.Player = client or NULL
    character.Schema = SCHEMA.Folder
    character.SteamID = client and client:SteamID64() or nil

    if ( istable(data.inventories) ) then
        character.Inventories = data.inventories
    elseif ( isstring(data.inventories) and data.inventories != "" ) then
        character.Inventories = util.JSONToTable(data.inventories) or {}
    else
        character.Inventories = {}
    end

    for k, v in pairs(self.variables) do
        if ( data[k] ) then
            character[k] = data[k]
        elseif ( v.Default ) then
            character[k] = v.Default
        end
    end

    self.Stored[characterID] = character

    return character
end

function Parallax.Character:GetPlayerByCharacter(id)
    for _, client in player.Iterator() do
        if ( client:GetCharacterID() == tonumber(id) ) then
            return client
        end
    end

    return false, "Player not found"
end

function Parallax.Character:Get(id)
    return self.Stored[id]
end

function Parallax.Character:GetAll()
    return self.Stored
end

function Parallax.Character:GetAllVariables()
    return self.variables
end

Parallax.character = Parallax.Character