--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Hybrid SQL Wrapper for Parallax (MySQL/SQLite)
-- Uses MySQLOO if configured, otherwise falls back to SQLite.
-- @module Parallax.Database

Parallax.Database = Parallax.Database or {}
Parallax.Database.backend = Parallax.Database.backend or Parallax.SQLite -- Default to SQLite if MySQL is not available

--- Initializes the hybrid database system.
-- @tparam table[opt] config MySQL connection config
-- @usage Parallax.Database:Initialize({ host = "localhost", username = "root", password = "", database = "gmod", port = 3306 })
function Parallax.Database:Initialize(config)
    if ( Parallax.Util:HasMysqlooBinary() and Parallax.SQLOO ) then
        if ( config ) then
            Parallax.Util:Print("Initializing MySQL connection...")
            Parallax.SQLOO:Initialize(config, function()
                Parallax.Util:PrintSuccess("MySQL connection established.")
                self.backend = Parallax.SQLOO
                self:LoadTables()

                hook.Run("DatabaseConnected")
            end, function(err)
                Parallax.Util:PrintError("MySQL connection failed: " .. err)
                self:Fallback(err)

                hook.Run("DatabaseConnectionFailed", err)
            end)
        else
            self:Fallback("MySQL config not provided")
        end
    else
        self:Fallback("MySQLOO not found")
    end
end

--- Fallback to SQLite if MySQL is unavailable.
-- @tparam string reason Reason for fallback
-- @usage Parallax.Database:Fallback("MySQL connection failed")
function Parallax.Database:Fallback(reason)
    self.backend = Parallax.SQLite
    Parallax.Util:PrintWarning((reason or "MySQL unavailable") .. ". Falling back to SQLite.")

    hook.Run("DatabaseFallback", reason)
end

--- Returns current backend object.
-- @treturn table Either Parallax.SQLOO or Parallax.SQLite
function Parallax.Database:GetBackend()
    return self.backend
end

--- Wraps backend call if available.
-- @tparam string fn Function name
-- @tparam ... Arguments
-- @return Returns backend function result
local function dispatch(fn, ...)
    if ( Parallax.Database.backend and Parallax.Database.backend[fn] ) then
        return Parallax.Database.backend[fn](Parallax.Database.backend, ...)
    else
        if ( Parallax.Database.backend == nil ) then
            Parallax.Util:PrintError("Database backend not initialized, cannot call: " .. fn .. " from " .. debug.getinfo(2, "S").source)
        else
            Parallax.Util:PrintError("Database backend missing method: " .. fn)
        end

        return false
    end
end

-- Proxy calls
local proxies = {
    "RegisterVar",
    "InitializeTable",
    "Insert",
    "Select",
    "Update",
    "Delete",
    "LoadRow",
    "SaveRow",
    "GetDefaultRow"
}

for i = 1, #proxies do
    local fn = proxies[i]
    Parallax.Database[fn] = function(self, ...)
        return dispatch(fn, ...)
    end
end

function Parallax.Database:LoadTables()
    hook.Run("PreDatabaseTablesLoaded")

    self:RegisterVar("ax_players", "name", "")
    self:RegisterVar("ax_players", "ip", "")
    self:RegisterVar("ax_players", "play_time", 0)
    self:RegisterVar("ax_players", "last_played", 0)
    self:RegisterVar("ax_players", "data", "{}")

    self:InitializeTable("ax_players", {
        steamid = "VARCHAR(32) PRIMARY KEY",
        name = "TEXT",
        ip = "TEXT",
        play_time = "INT",
        last_played = "INT",
        data = "TEXT"
    })

    self:InitializeTable("ax_characters", {
        id = "INTEGER PRIMARY KEY AUTOINCREMENT",
        steamid = "VARCHAR(32)",
        inventories = "TEXT",
        data = "TEXT"
    })

    self:InitializeTable("ax_inventories", {
        id = "INTEGER PRIMARY KEY AUTOINCREMENT",
        character_id = "INT",
        name = "TEXT",
        max_weight = "INT",
        data = "TEXT"
    })

    self:InitializeTable("ax_items", {
        id = "INTEGER PRIMARY KEY AUTOINCREMENT",
        inventory_id = "INT",
        character_id = "INT",
        unique_id = "TEXT",
        data = "TEXT"
    })

    hook.Run("PostDatabaseTablesLoaded")
end

--- Prints which database backend is currently in use. Used for debugging purposes.
-- @usage Parallax.Database:PrintBackend()
-- @return "Using MySQL backend." or "Using SQLite backend."
function Parallax.Database:PrintBackend()
    if ( self.backend == Parallax.SQLOO ) then
        Parallax.Util:Print("Using MySQL backend.")
    elseif ( self.backend == Parallax.SQLite ) then
        Parallax.Util:Print("Using SQLite backend.")
    else
        -- Quite unlikely, but just in case
        Parallax.Util:PrintError("Unknown database backend in use!")
    end
end