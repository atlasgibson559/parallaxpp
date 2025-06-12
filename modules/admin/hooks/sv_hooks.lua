local MODULE = MODULE

function MODULE:PostPlayerReady(client)
    if ( !IsValid(client) or client:IsBot() ) then return end

    if ( !game.IsDedicated() and client == Player(1) ) then
        client:SetDBVar("usergroup", "superadmin") -- Default usergroup
        client:SaveDB()
        client:SetUserGroup("superadmin")
        ax.util:Print(tostring(client) .. " is assigned to usergroup '" .. client:GetUserGroup() .. "'.")

        return
    end

    local usergroup = client:GetDBVar("usergroup", "user")
    if ( !CAMI.GetUsergroup(usergroup) ) then
        usergroup = "user" -- Fallback to default user group if not found
        ax.util:PrintWarning("Usergroup '" .. usergroup .. "' not found for " .. tostring(client) .. ". Defaulting to 'user'.")
        client:SetDBVar("usergroup", usergroup)
        client:SaveDB()
    end

    client:SetUserGroup(usergroup)

    ax.util:Print(tostring(client) .. " has been assigned to usergroup '" .. usergroup .. "'.")
end

function MODULE:SaveData()
    for _, client in player.Iterator() do
        if ( client:IsBot() ) then continue end

        local usergroup = client:GetUserGroup()
        if ( usergroup and CAMI.GetUsergroup(usergroup) ) then
            client:SetDBVar("usergroup", usergroup)
            client:SaveDB()
            ax.util:Print("Saving usergroup '" .. usergroup .. "' for " .. tostring(client) .. "...")
        else
            ax.util:PrintWarning("Invalid usergroup for " .. tostring(client) .. ". Not saving usergroup!")
        end
    end
end

function MODULE:PlayerSpawnNPC(client, npcType, weapon)
    return client:HasPermission("Parallax - Spawn NPCs")
end

function MODULE:PlayerSpawnSWEP(client, weapon, swepTable)
    return client:HasPermission("Parallax - Spawn Weapons")
end

function MODULE:PlayerGiveSWEP(client, weapon, spawnInfo)
    return client:HasPermission("Parallax - Spawn Weapons")
end