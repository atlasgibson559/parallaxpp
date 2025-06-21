--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Schema library.
-- @module Parallax.Schema

Parallax.Schema = {}

local default = {
    Name = "Unknown",
    Description = "No description available.",
    Author = "Unknown"
}

--- Initializes the schema.
-- @realm shared
-- @return boolean Returns true if the schema was successfully initialized, false otherwise.
-- @internal
function Parallax.Schema:Initialize()
    SCHEMA = SCHEMA or {}

    local folder = engine.ActiveGamemode()
    local schema = folder .. "/schema/boot.lua"

    file.CreateDir("parallax/" .. folder)

    Parallax.Util:Print("Searching for schema...")

    local bSuccess = file.Exists(schema, "LUA")
    if ( !bSuccess ) then
        Parallax.Util:PrintError("Schema not found!")
        return false
    else
        SCHEMA.Folder = folder

        Parallax.Util:Print("Schema found, loading \"" .. SCHEMA.Folder .. "\"...")
    end

    hook.Run("PreInitializeSchema", SCHEMA, schema)

    for k, v in pairs(default) do
        if ( !SCHEMA[k] ) then
            SCHEMA[k] = v
        end
    end

    Parallax.Hooks:Register("SCHEMA")
    Parallax.Util:LoadFolder(folder .. "/schema/libraries/external", true)
    Parallax.Util:LoadFolder(folder .. "/schema/libraries/client", true)
    Parallax.Util:LoadFolder(folder .. "/schema/libraries/shared", true)
    Parallax.Util:LoadFolder(folder .. "/schema/libraries/server", true)
    Parallax.Util:LoadFolder(folder .. "/schema/factions", true)
    Parallax.Util:LoadFolder(folder .. "/schema/classes", true)
    Parallax.Util:LoadFolder(folder .. "/schema/definitions", true)
    Parallax.Util:LoadFolder(folder .. "/schema/meta", true)
    Parallax.Util:LoadFolder(folder .. "/schema/ui", true)
    Parallax.Util:LoadFolder(folder .. "/schema/hooks", true)
    Parallax.Util:LoadFolder(folder .. "/schema/net", true)
    Parallax.Util:LoadFolder(folder .. "/schema/languages", true)
    Parallax.Item:LoadFolder(folder .. "/schema/items")
    Parallax.Util:LoadFolder(folder .. "/schema/config", true)

    -- Load the current map config if it exists
    local map = game.GetMap()
    local path = folder .. "/schema/config/maps/" .. map .. ".lua"
    if ( file.Exists(path, "LUA") ) then
        hook.Run("PreInitializeMapConfig", SCHEMA, path, map)
        Parallax.Util:Print("Loading map config for \"" .. map .. "\"...")
        Parallax.Util:LoadFile(path, "shared")
        Parallax.Util:Print("Loaded map config for \"" .. map .. "\".")
        hook.Run("PostInitializeMapConfig", SCHEMA, path, map)
    else
        Parallax.Util:PrintWarning("Failed to find map config for \"" .. map .. "\".")
    end

    if ( SERVER ) then
        Parallax.Config:Load()
    end

    -- Load the sh_schema.lua file after we load all necessary files
    Parallax.Util:LoadFile(schema, "shared")

    -- Load the modules after the schema file is loaded
    Parallax.Module:LoadFolder(folder .. "/modules")

    -- Load the database configuration
    if ( SERVER ) then
        local database = folder .. "/schema/database.lua"
        if ( file.Exists(database, "LUA") ) then
            Parallax.Util:Print("Loading database config...")
            Parallax.Util:LoadFile(folder .. "/schema/database.lua", "server")
            Parallax.Util:Print("Loaded database config.")
        else
            Parallax.Util:PrintWarning("Failed to find database config, using SQLite.")
            Parallax.Database:Initialize()
        end
    end

    Parallax.Util:Print("Loaded schema " .. SCHEMA.Name)

    hook.Run("PostInitializeSchema", SCHEMA, path)

    return true
end