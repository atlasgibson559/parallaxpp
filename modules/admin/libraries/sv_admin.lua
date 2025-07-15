--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Handle admin commands from console
concommand.Add("ax_admin_kick", function(client, cmd, args)
    if ( !IsValid(client) or !CAMI.PlayerHasAccess(client, "Parallax - Kick Players", nil) ) then
        return
    end

    local target = player.GetByUniqueID(args[1])
    local reason = args[2] or "No reason provided"

    if ( IsValid(target) ) then
        MODULE:LogAction(client, "kicked", target, reason)
        target:Kick(reason)
    end
end)

concommand.Add("ax_admin_ban", function(client, cmd, args)
    if ( !IsValid(client) or !CAMI.PlayerHasAccess(client, "Parallax - Ban Players", nil) ) then
        return
    end

    local target = player.GetByUniqueID(args[1])
    local duration = tonumber(args[2]) or 0
    local reason = args[3] or "No reason provided"

    if ( IsValid(target) ) then
        local banData = {
            steamid = target:SteamID64(),
            name = target:SteamName(),
            admin = client:SteamID64(),
            adminName = client:SteamName(),
            reason = reason,
            timestamp = os.time(),
            duration = duration,
            expires = duration > 0 and (os.time() + duration * 60) or 0
        }

        MODULE.BannedPlayers[target:SteamID64()] = banData
        MODULE:SaveData()
        MODULE:LogAction(client, "banned", target, reason, duration)

        target:Kick("Banned: " .. reason)
    end
end)

if ( timer.Exists("Parallax.Admin.BanCleanup") ) then
    timer.Remove("Parallax.Admin.BanCleanup")
end

-- Periodic ban list cleanup
timer.Create("Parallax.Admin.BanCleanup", 3600, 0, function()
    local cleaned = 0
    for steamid, banData in pairs(MODULE.BannedPlayers) do
        if ( banData.expires > 0 and os.time() > banData.expires ) then
            MODULE.BannedPlayers[steamid] = nil
            cleaned = cleaned + 1
        end
    end

    if ( cleaned > 0 ) then
        MODULE:SaveData()
        ax.util:Print("Cleaned up " .. cleaned .. " expired bans.")
    end
end)

--- Creates a new ticket
-- @param client Player - The player creating the ticket
-- @param title string - Ticket title
-- @param description string - Ticket description
-- @return number - Ticket ID
function MODULE:CreateTicket(client, title, description)
    local ticketID = self.NextTicketID
    self.NextTicketID = self.NextTicketID + 1

    self.Tickets[ticketID] = {
        id = ticketID,
        title = title,
        description = description,
        creator = client:SteamID64(),
        creatorName = client:SteamName(),
        status = "open",
        claimer = nil,
        claimerName = nil,
        timestamp = os.time(),
        lastActivity = os.time()
    }

    self.TicketComments[ticketID] = {}

    self:SaveData()
    self:LogAction(client, "created ticket", nil, "Title: " .. title)

    net.Start("ax.admin.ticket.update")
        net.WriteTable(self.Tickets)
        net.WriteTable(self.TicketComments)
    net.Send(client)

    return ticketID
end

--- Adds a comment to a ticket
-- @param ticketID number - Ticket ID
-- @param client Player - The player adding the comment
-- @param message string - Comment message
function MODULE:AddTicketComment(ticketID, client, message)
    if (!self.TicketComments[ticketID]) then
        self.TicketComments[ticketID] = {}
    end

    local comment = {
        author = client:SteamID64(),
        authorName = client:SteamName(),
        message = message,
        timestamp = os.time(),
        isAdmin = CAMI.PlayerHasAccess(client, "Parallax - Admin Menu", nil)
    }

    table.insert(self.TicketComments[ticketID], comment)

    -- Update ticket activity
    if (self.Tickets[ticketID]) then
        self.Tickets[ticketID].lastActivity = os.time()
    end

    self:SaveData()
    self:LogAction(client, "commented on ticket", nil, "Ticket ID: " .. ticketID)

    net.Start("ax.admin.ticket.update")
        net.WriteTable(self.Tickets)
        net.WriteTable(self.TicketComments)
    net.Send(client)
end

--- Gets all tickets for a player
-- @param client Player - The player
-- @return table - Player's tickets
function MODULE:GetPlayerTickets(client)
    local playerTickets = {}

    for id, ticket in pairs(self.Tickets) do
        if (ticket.creator == client:SteamID64() and ticket.status != "closed") then
            table.insert(playerTickets, ticket)
        end
    end

    return playerTickets
end

--- Gets all active tickets
-- @return table - All active tickets
function MODULE:GetActiveTickets()
    local activeTickets = {}

    for id, ticket in pairs(self.Tickets) do
        if (ticket.status != "closed") then
            table.insert(activeTickets, ticket)
        end
    end

    return activeTickets
end

--- Auto-closes inactive tickets
function MODULE:CleanupInactiveTickets()
    local autoCloseHours = ax.config:Get("admin.tickets.autoClose", 24)
    local cutoffTime = os.time() - (autoCloseHours * 3600)

    for id, ticket in pairs(self.Tickets) do
        if (ticket.status != "closed" and ticket.lastActivity < cutoffTime) then
            ticket.status = "closed"
            self:LogAction(nil, "auto-closed ticket", nil, "Ticket ID: " .. id .. " (inactive)")
        end
    end

    self:SaveData()

    net.Start("ax.admin.ticket.update")
        net.WriteTable(self.Tickets)
        net.WriteTable(self.TicketComments)
    net.Send(client)
end