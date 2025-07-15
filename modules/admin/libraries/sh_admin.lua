--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

--- Registers a usergroup with additional properties
-- @param name string - Group name
-- @param level number - Hierarchy level
-- @param color Color - Group color
-- @param immunity number - Immunity level (0-100)
function MODULE:RegisterGroup(name, level, color, immunity)
    local group = {
        Name = name,
        Level = level or 0,
        Color = color or Color(255, 255, 255),
        Immunity = immunity or 0
    }

    CAMI.RegisterUsergroup(group, "Parallax")
    self.Groups[name] = group

    if ( SERVER ) then
        self:SaveData()
    end
end

--- Registers a permission
-- @param name string - Permission name
-- @param level number - Minimum access level required for this permission
function MODULE:RegisterPermission(name, level)
    local permission = {
        Name = name,
        Level = level
    }

    CAMI.RegisterPrivilege(permission)
    self.Permissions[name] = permission

    if ( SERVER ) then
        self:SaveData()
    end
end

--- Checks if a player has immunity over another player
-- @param admin Player - The admin player
-- @param target Player - The target player
-- @return boolean - True if admin has immunity over target
function MODULE:HasImmunity(admin, target)
    if ( !ax.config:Get("admin.immunity") ) then
        return true
    end

    if ( !IsValid(admin) or !IsValid(target) ) then
        return false
    end

    if ( admin == target ) then
        return true
    end

    local adminGroup = self.Groups[admin:GetUserGroup()]
    local targetGroup = self.Groups[target:GetUserGroup()]

    if ( !adminGroup or !targetGroup ) then
        return true
    end

    return adminGroup.Immunity >= targetGroup.Immunity
end

--- Checks if a player can target another player based on hierarchy
-- @param admin Player - The admin player
-- @param target Player - The target player
-- @return boolean - True if admin can target
function MODULE:CanTarget(admin, target)
    if ( !ax.config:Get("admin.hierarchy") ) then
        return true
    end

    if ( !IsValid(admin) or !IsValid(target) ) then
        return false
    end

    if ( admin == target ) then
        return true
    end

    local adminGroup = self.Groups[admin:GetUserGroup()]
    local targetGroup = self.Groups[target:GetUserGroup()]

    if ( !adminGroup or !targetGroup ) then
        return true
    end

    return adminGroup.Level >= targetGroup.Level
end

--- Logs an admin action
-- @param admin Player - The admin who performed the action
-- @param action string - The action performed
-- @param target Player - The target of the action (optional)
-- @param reason string - Reason for the action (optional)
-- @param duration number - Duration of the action (optional)
function MODULE:LogAction(admin, action, target, reason, duration)
    if ( !ax.config:Get("admin.logging") ) then
        return
    end

    local logEntry = {
        timestamp = os.time(),
        admin = IsValid(admin) and admin:SteamID64() or "Console",
        adminName = IsValid(admin) and admin:SteamName() or "Console",
        action = action,
        target = IsValid(target) and target:SteamID64() or nil,
        targetName = IsValid(target) and target:SteamName() or nil,
        reason = reason or "No reason provided",
        duration = duration or 0
    }

    table.insert(self.AdminLogs, logEntry)

    -- Keep only last 1000 log entries
    if ( self.AdminLogs[1000] != nil ) then
        table.remove(self.AdminLogs, 1)
    end

    -- Print to console
    local logMessage = string.format("[ADMIN] %s %s", logEntry.adminName, action)
    if ( IsValid(target) ) then
        logMessage = logMessage .. " " .. target:SteamName()
    end

    if ( reason and reason != "" ) then
        logMessage = logMessage .. " - Reason: " .. reason
    end

    if ( duration and duration > 0 ) then
        logMessage = logMessage .. " - Duration: " .. duration .. "s"
    end

    ax.util:Print(logMessage)

    -- Save logs
    if ( SERVER ) then
        self:SaveData()
    end
end

--- Gets admin logs with optional filtering
-- @param filter table - Filter options
-- @return table - Filtered log entries
function MODULE:GetLogs(filter)
    local logs = self.AdminLogs
    if ( !filter ) then
        return logs
    end

    local filtered = {}
    for _, log in ipairs(logs) do
        local include = true

        if ( filter.admin and log.admin != filter.admin ) then
            include = false
        end

        if ( filter.action and !ax.util:FindString(log.action, filter.action) ) then
            include = false
        end

        if ( filter.target and log.target != filter.target ) then
            include = false
        end

        if ( filter.after and log.timestamp < filter.after ) then
            include = false
        end

        if ( filter.before and log.timestamp > filter.before ) then
            include = false
        end

        if ( include ) then
            table.insert(filtered, log)
        end
    end

    return filtered
end

--- Gets all groups
-- @return table - All registered groups
function MODULE:GetGroups()
    return self.Groups
end

--- Gets all permissions
-- @return table - All registered permissions
function MODULE:GetPermissions()
    return self.Permissions
end

--- Gets a group by name
-- @param name string - Group name
-- @return table - Group data
function MODULE:GetGroup(name)
    return self.Groups[name]
end

--- Gets a permission by name
-- @param name string - Permission name
-- @return table - Permission data
function MODULE:GetPermission(name)
    return self.Permissions[name]
end

--- Gets the group color for a player
-- @param client Player - The player
-- @return Color - Group color
function MODULE:GetGroupColor(client)
    if ( !IsValid(client) ) then
        return Color(255, 255, 255)
    end

    local group = self.Groups[client:GetUserGroup()]
    return group and group.Color or Color(255, 255, 255)
end

--- Gets the group level for a player
-- @param client Player - The player
-- @return number - Group level
function MODULE:GetGroupLevel(client)
    if ( !IsValid(client) ) then
        return 0
    end

    local group = self.Groups[client:GetUserGroup()]
    return group and group.Level or 0
end

-- Usergroup management data
if (SERVER) then
    MODULE.CustomUsergroups = MODULE.CustomUsergroups or {}
    MODULE.PlayerUsergroups = MODULE.PlayerUsergroups or {}
    MODULE.TempUsergroups = MODULE.TempUsergroups or {}
end

--- Creates a new usergroup
-- @param name string - Group name
-- @param inherits string - Group to inherit from
-- @param level number - Hierarchy level
-- @param color Color - Group color
-- @param immunity number - Immunity level
-- @param admin Player - Admin who created the group
function MODULE:CreateUsergroup(name, inherits, level, color, immunity, admin)
    if (!SERVER) then return end

    local usergroup = {
        Name = name,
        Inherits = inherits or "user",
        Level = level or 1,
        Color = color or Color(255, 255, 255),
        Immunity = immunity or 0,
        Custom = true,
        Creator = IsValid(admin) and admin:SteamID64() or "Console",
        Created = os.time()
    }

    -- Register with CAMI
    CAMI.RegisterUsergroup({
        Name = name,
        Inherits = inherits or "user"
    }, "Parallax")

    -- Store in our system
    self.CustomUsergroups[name] = usergroup
    self.Groups[name] = usergroup

    self:SaveData()
    self:LogAction(admin, "created usergroup", nil, "Created usergroup: " .. name)

    -- Broadcast to all admins
    self:BroadcastUsergroupUpdate()
end

--- Edits an existing usergroup
-- @param name string - Group name
-- @param data table - New data
-- @param admin Player - Admin who edited the group
function MODULE:EditUsergroup(name, data, admin)
    if (!SERVER) then return end

    local usergroup = self.CustomUsergroups[name] or self.Groups[name]
    if (!usergroup) then return false end

    -- Update data
    if (data.Inherits) then usergroup.Inherits = data.Inherits end
    if (data.Level) then usergroup.Level = data.Level end
    if (data.Color) then usergroup.Color = data.Color end
    if (data.Immunity) then usergroup.Immunity = data.Immunity end

    -- Update CAMI registration
    CAMI.RegisterUsergroup({
        Name = name,
        Inherits = usergroup.Inherits
    }, "Parallax")

    self:SaveData()
    self:LogAction(admin, "edited usergroup", nil, "Edited usergroup: " .. name)

    -- Broadcast to all admins
    self:BroadcastUsergroupUpdate()

    return true
end

--- Deletes a usergroup
-- @param name string - Group name
-- @param admin Player - Admin who deleted the group
function MODULE:DeleteUsergroup(name, admin)
    if (!SERVER) then return end

    local usergroup = self.CustomUsergroups[name]
    if (!usergroup) then return false end

    -- Move all players with this group to user
    for _, ply in player.Iterator() do
        if (ply:GetUserGroup() == name) then
            self:SetPlayerUsergroup(ply, "user", 0, "Group deleted", admin)
        end
    end

    -- Remove from systems
    CAMI.UnregisterUsergroup(name, "Parallax")
    self.CustomUsergroups[name] = nil
    self.Groups[name] = nil

    self:SaveData()
    self:LogAction(admin, "deleted usergroup", nil, "Deleted usergroup: " .. name)

    -- Broadcast to all admins
    self:BroadcastUsergroupUpdate()

    return true
end

--- Sets a player's usergroup with optional duration
-- @param player Player - Target player
-- @param groupName string - Group name
-- @param duration number - Duration in minutes (0 = permanent)
-- @param reason string - Reason for change
-- @param admin Player - Admin who made the change
function MODULE:SetPlayerUsergroup(player, groupName, duration, reason, admin)
    if (!SERVER) then return end

    local oldGroup = player:GetUserGroup()
    local steamID = player:SteamID64()

    -- Clear any existing temp usergroup
    if (self.TempUsergroups[steamID]) then
        timer.Remove("TempUsergroup_" .. steamID)
        self.TempUsergroups[steamID] = nil
    end

    -- Set the usergroup
    player:SetUserGroup(groupName)

    -- Store permanent usergroup change
    self.PlayerUsergroups[steamID] = {
        group = groupName,
        setBy = IsValid(admin) and admin:SteamID64() or "Console",
        setByName = IsValid(admin) and admin:SteamName() or "Console",
        reason = reason or "No reason provided",
        timestamp = os.time()
    }

    -- Handle temporary usergroup
    if (duration and duration > 0) then
        self.TempUsergroups[steamID] = {
            originalGroup = oldGroup,
            tempGroup = groupName,
            expires = os.time() + (duration * 60),
            reason = reason,
            setBy = IsValid(admin) and admin:SteamID64() or "Console"
        }

        -- Create timer to revert
        timer.Create("TempUsergroup_" .. steamID, duration * 60, 1, function()
            if (IsValid(player)) then
                player:SetUserGroup(oldGroup)
                self:LogAction(nil, "temp usergroup expired", player, "Reverted from " .. groupName .. " to " .. oldGroup)
                ax.notification:Send(player, "Your temporary usergroup has expired. Reverted to " .. oldGroup)
            end
            self.TempUsergroups[steamID] = nil
        end)
    end

    -- Signal CAMI
    CAMI.SignalUserGroupChanged(player, oldGroup, groupName, "Parallax")

    self:SaveData()
    self:LogAction(admin, "set usergroup", player, "Changed from " .. oldGroup .. " to " .. groupName .. " - " .. reason, duration)

    -- Broadcast usergroup update
    net.Start("ax.admin.group.update")
        net.WriteString(steamID)
        net.WriteString(groupName)
        net.WriteTable(self.Groups)
    net.Broadcast()
end

--- Checks if an admin can assign a specific usergroup
-- @param admin Player - Admin player
-- @param groupName string - Group name to check
-- @return boolean - Can assign
function MODULE:CanAssignGroup(admin, groupName)
    if (!IsValid(admin)) then return true end

    local adminGroup = self.Groups[admin:GetUserGroup()]
    local targetGroup = self.Groups[groupName]

    if (!adminGroup or !targetGroup) then return false end

    -- Admins can only assign groups at or below their level
    return adminGroup.Level >= targetGroup.Level
end

--- Broadcasts usergroup updates to all clients
function MODULE:BroadcastUsergroupUpdate()
    if (!SERVER) then return end

    net.Start("ax.admin.group.update")
        net.WriteString("")
        net.WriteString("")
        net.WriteTable(self.Groups)
    net.Broadcast()
end

--- Gets all custom usergroups
-- @return table - Custom usergroups
function MODULE:GetCustomUsergroups()
    return self.CustomUsergroups or {}
end

--- Gets temporary usergroups
-- @return table - Temporary usergroups
function MODULE:GetTempUsergroups()
    return self.TempUsergroups or {}
end

-- Override SaveData to include usergroup data
local oldSaveData = MODULE.SaveData
function MODULE:SaveData()
    if (oldSaveData) then
        oldSaveData(self)
    end

    local data = {
        banned_players = self.BannedPlayers,
        admin_logs = self.AdminLogs,
        tickets = self.Tickets,
        ticket_comments = self.TicketComments,
        next_ticket_id = self.NextTicketID,
        custom_usergroups = self.CustomUsergroups,
        player_usergroups = self.PlayerUsergroups,
        temp_usergroups = self.TempUsergroups
    }

    ax.data:Set("admin", data, true, true)
end

-- Override LoadData to include usergroup data
local oldLoadData = MODULE.LoadData
function MODULE:LoadData()
    if (oldLoadData) then
        oldLoadData(self)
    end

    local data = ax.data:Get("admin", {}, true, true)

    if (data.custom_usergroups) then
        self.CustomUsergroups = data.custom_usergroups

        -- Re-register custom usergroups with CAMI
        for name, usergroup in pairs(self.CustomUsergroups) do
            CAMI.RegisterUsergroup({
                Name = name,
                Inherits = usergroup.Inherits
            }, "Parallax")

            self.Groups[name] = usergroup
        end
    end

    if (data.player_usergroups) then
        self.PlayerUsergroups = data.player_usergroups
    end

    if (data.temp_usergroups) then
        self.TempUsergroups = data.temp_usergroups

        -- Recreate temp usergroup timers
        for steamID, tempData in pairs(self.TempUsergroups) do
            local remainingTime = tempData.expires - os.time()
            if (remainingTime > 0) then
                timer.Create("TempUsergroup_" .. steamID, remainingTime, 1, function()
                    local player = player.GetBySteamID64(steamID)
                    if (IsValid(player)) then
                        player:SetUserGroup(tempData.originalGroup)
                        self:LogAction(nil, "temp usergroup expired", player, "Reverted from " .. tempData.tempGroup .. " to " .. tempData.originalGroup)
                        ax.notification:Send(player, "Your temporary usergroup has expired. Reverted to " .. tempData.originalGroup)
                    end
                    self.TempUsergroups[steamID] = nil
                end)
            else
                -- Expired, remove it
                self.TempUsergroups[steamID] = nil
            end
        end
    end
end