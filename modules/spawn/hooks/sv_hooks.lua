--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

--- Initialize the spawn system
function MODULE:Initialize()
    -- Initialize the spawns table using the proper database API
    ax.database:InitializeTable("ax_spawns", {
        id = "INTEGER PRIMARY KEY AUTOINCREMENT",
        faction = "INTEGER NOT NULL",
        pos_x = "REAL NOT NULL",
        pos_y = "REAL NOT NULL",
        pos_z = "REAL NOT NULL",
        ang_p = "REAL NOT NULL",
        ang_y = "REAL NOT NULL",
        ang_r = "REAL NOT NULL",
        schema = "TEXT NOT NULL"
    })

    -- Load all spawn points after table is initialized
    MODULE.spawn:LoadAll()
end

--- Handle player spawning
function MODULE:PlayerSpawn(client)
    if ( !IsValid(client) or client:Team() == 0 ) then return end

    local character = client:GetCharacter()
    if ( !character ) then return end

    local factionID = character:GetFaction()
    local spawn = MODULE.spawn:GetRandom(factionID)

    if ( spawn ) then
        -- Small delay to ensure proper spawning
        timer.Simple(0.1, function()
            if ( !IsValid(client) ) then return end

            client:SetPos(spawn.pos)
            client:SetAngles(spawn.ang)
            client:SetVelocity(Vector(0, 0, 0))
        end)
    else
        -- Fallback to default spawn behavior
        ax.util:PrintError("No spawn points found for faction " .. factionID .. "!")
    end
end

--- Sync spawn points to newly connected players
function MODULE:PlayerReady(client)
    MODULE.spawn:Sync(client)
end

--- Handle character switching
function MODULE:PostPlayerLoadedCharacter(client, character)
    if ( !IsValid(client) or client:Team() == 0 ) then return end

    -- Respawn the player to use the new faction's spawn points
    timer.Simple(0.1, function()
        if ( !IsValid(client) ) then return end
        client:Spawn()
    end)
end

function MODULE:OnReloaded()
    MODULE.spawn:LoadAll()
end