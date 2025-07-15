--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

if ( IsValid(ax.gui.admin) ) then
    ax.gui.admin:Remove()
end

if ( IsValid(ax.gui.adminContext) ) then
    ax.gui.adminContext:Remove()
end

-- Create admin menu
function MODULE:CreateAdminMenu()
    if ( IsValid(ax.gui.admin) ) then
        ax.gui.admin:Remove()
    end

    adminMenu = vgui.Create("DFrame")
    adminMenu:SetSize(800, 600)
    adminMenu:Center()
    adminMenu:SetTitle("Admin Menu")
    adminMenu:SetDeleteOnClose(true)
    adminMenu:SetDraggable(true)
    adminMenu:SetScreenLock(true)
    adminMenu:SetBackgroundBlur(true)
    adminMenu:MakePopup()

    -- Create tab panel
    local tabPanel = vgui.Create("DPropertySheet", adminMenu)
    tabPanel:Dock(FILL)

    -- Players tab
    local playersPanel = vgui.Create("DPanel")
    playersPanel:Dock(FILL)

    local playersList = vgui.Create("DListView", playersPanel)
    playersList:SetPos(10, 10)
    playersList:SetSize(350, 550)
    playersList:SetMultiSelect(false)
    playersList:AddColumn("Name")
    playersList:AddColumn("Group")
    playersList:AddColumn("SteamID")

    -- Populate players list
    for _, client in player.Iterator() do
        local line = playersList:AddLine(client:SteamName(), client:GetUserGroup(), client:SteamID())
        line.client = client
    end

    -- Player actions panel
    local actionsPanel = vgui.Create("DPanel", playersPanel)
    actionsPanel:SetPos(370, 10)
    actionsPanel:SetSize(400, 550)
    actionsPanel.Paint = function(this, width, height)
        surface.SetDrawColor(50, 50, 50, 200)
        surface.DrawRect(0, 0, width, height)
    end

    local selectedPlayer = nil

    -- Player selection handler
    playersList.OnRowSelected = function(lst, index, pnl)
        selectedPlayer = pnl.client

        -- Clear previous buttons
        for _, child in pairs(actionsPanel:GetChildren()) do
            child:Remove()
        end

        if ( !IsValid(selectedPlayer) ) then return end

        -- Create action buttons
        local y = 10
        local buttonHeight = 25
        local buttonSpacing = 5

        local function CreateButton(text, permission, callback)
            if ( !CAMI.PlayerHasAccess(ax.client, permission, nil) ) then
                return
            end

            local btn = vgui.Create("DButton", actionsPanel)
            btn:SetPos(10, y)
            btn:SetSize(380, buttonHeight)
            btn:SetText(text)
            btn.DoClick = callback

            y = y + buttonHeight + buttonSpacing

            return btn
        end

        -- Player info
        local infoLabel = vgui.Create("DLabel", actionsPanel)
        infoLabel:SetPos(10, y)
        infoLabel:SetSize(380, 60)
        infoLabel:SetText("Selected: " .. selectedPlayer:SteamName() .. "\nGroup: " .. selectedPlayer:GetUserGroup() .. "\nSteamID: " .. selectedPlayer:SteamID())
        infoLabel:SetWrap(true)
        infoLabel:SetAutoStretchVertical(true)
        y = y + 70

        -- Action buttons
        CreateButton("Kick", "Parallax - Kick Players", function()
            Derma_StringRequest("Kick Player", "Enter reason:", "No reason provided", function(text)
                ax.command:Run("PlyKick", selectedPlayer:UserID(), text)
            end)
        end)

        CreateButton("Ban", "Parallax - Ban Players", function()
            local reasonFrame = vgui.Create("DFrame")
            reasonFrame:SetSize(400, 200)
            reasonFrame:Center()
            reasonFrame:SetTitle("Ban Player")
            reasonFrame:MakePopup()

            local reasonEntry = vgui.Create("DTextEntry", reasonFrame)
            reasonEntry:SetPos(10, 30)
            reasonEntry:SetSize(380, 25)
            reasonEntry:SetPlaceholderText("Enter reason...")

            local durationEntry = vgui.Create("DNumSlider", reasonFrame)
            durationEntry:SetPos(10, 60)
            durationEntry:SetSize(380, 25)
            durationEntry:SetText("Duration (minutes, 0 = permanent)")
            durationEntry:SetMin(0)
            durationEntry:SetMax(10080)
            durationEntry:SetDecimals(0)

            local banBtn = vgui.Create("DButton", reasonFrame)
            banBtn:SetPos(10, 120)
            banBtn:SetSize(380, 30)
            banBtn:SetText("Ban Player")
            banBtn.DoClick = function()
                local reason = reasonEntry:GetValue()
                local duration = durationEntry:GetValue()
                ax.command:Run("PlyBan", selectedPlayer:UserID(), duration, reason)
                reasonFrame:Close()
            end

            local cancelBtn = vgui.Create("DButton", reasonFrame)
            cancelBtn:SetPos(10, 155)
            cancelBtn:SetSize(380, 30)
            cancelBtn:SetText("Cancel")
            cancelBtn.DoClick = function()
                reasonFrame:Close()
            end
        end)

        CreateButton("Goto", "Parallax - Teleport", function()
            ax.command:Run("PlyGoto", selectedPlayer:UserID())
        end)

        CreateButton("Bring", "Parallax - Bring Players", function()
            ax.command:Run("PlyBring", selectedPlayer:UserID())
        end)

        CreateButton("Freeze / Unfreeze", "Parallax - Freeze Players", function()
            ax.command:Run("PlyFreeze", selectedPlayer:UserID())
        end)

        CreateButton("Slay", "Parallax - Slay Players", function()
            ax.command:Run("PlySlay", selectedPlayer:UserID())
        end)

        CreateButton("Respawn", "Parallax - Respawn Players", function()
            ax.command:Run("PlyRespawn", selectedPlayer:UserID())
        end)
    end

    tabPanel:AddSheet("Players", playersPanel, "icon16/user.png")

    -- Server tab
    local serverPanel = vgui.Create("DPanel")
    serverPanel:Dock(FILL)

    local serverY = 10
    local function CreateServerButton(text, permission, callback)
        if ( !CAMI.PlayerHasAccess(ax.client, permission, nil) ) then
            return
        end

        local btn = vgui.Create("DButton", serverPanel)
        btn:SetPos(10, serverY)
        btn:SetSize(200, 30)
        btn:SetText(text)
        btn.DoClick = callback

        serverY = serverY + 35

        return btn
    end

    CreateServerButton("Cleanup Map", "Parallax - Cleanup", function()
        Derma_Query("Are you sure you want to cleanup the map?", "Cleanup Map", "Yes", function()
            Derma_StringRequest("Cleanup Map", "Enter reason for cleanup:", "No reason provided", function(text)
                ax.command:Run("CleanupMap", text)
            end)
        end, "No", function() end)
    end)

    CreateServerButton("Change Map", "Parallax - Map Control", function()
        Derma_StringRequest("Change Map", "Enter map name:", "", function(text)
            Derma_StringRequest("Change Map Reason", "Enter reason for changing the map:", "No reason provided", function(reason)
                ax.command:Run("ChangeMap", text, reason)
            end, function() end)
        end)
    end)

    CreateServerButton("View Logs", "Parallax - View Logs", function()
        ax.command:Run("ViewLogs", "20")
    end)

    tabPanel:AddSheet("Server", serverPanel, "icon16/server.png")

    -- Logs tab
    local logsPanel = vgui.Create("DPanel")
    logsPanel:Dock(FILL)

    local logsList = vgui.Create("DListView", logsPanel)
    logsList:Dock(FILL)
    logsList:SetMultiSelect(false)
    logsList:AddColumn("Time")
    logsList:AddColumn("Admin")
    logsList:AddColumn("Action")
    logsList:AddColumn("Target")
    logsList:AddColumn("Reason")

    -- Populate logs (this would need to be networked from server)
    -- For now, just show example
    logsList:AddLine("12:34:56", "Admin", "kicked", "Player", "Rule violation")

    tabPanel:AddSheet("Logs", logsPanel, "icon16/script.png")

    -- Tickets tab
    local ticketsPanel = vgui.Create("DPanel")
    ticketsPanel:Dock(FILL)

    local ticketsList = vgui.Create("DListView", ticketsPanel)
    ticketsList:SetPos(10, 10)
    ticketsList:SetSize(350, 550)
    ticketsList:SetMultiSelect(false)
    ticketsList:AddColumn("ID")
    ticketsList:AddColumn("Title")
    ticketsList:AddColumn("Creator")
    ticketsList:AddColumn("Status")
    ticketsList:AddColumn("Created")

    -- Ticket details panel for admin
    local adminDetailsPanel = vgui.Create("DPanel", ticketsPanel)
    adminDetailsPanel:SetPos(370, 10)
    adminDetailsPanel:SetSize(400, 550)
    adminDetailsPanel.Paint = function(this, width, height)
        surface.SetDrawColor(50, 50, 50, 200)
        surface.DrawRect(0, 0, width, height)
    end

    -- Ticket selection handler
    ticketsList.OnRowSelected = function(lst, index, pnl)
        local ticket = pnl.ticket
        if (!ticket) then return end

        MODULE:ShowTicketDetails(adminDetailsPanel, ticket)
    end

    -- Refresh function for admin menu
    adminMenu.RefreshTickets = function()
        ticketsList:Clear()
        adminDetailsPanel:Clear()

        for id, ticket in pairs(MODULE.ClientTickets) do
            local timeStr = os.date("%m/%d %H:%M", ticket.timestamp)
            local line = ticketsList:AddLine(ticket.id, ticket.title, ticket.creatorName, ticket.status, timeStr)
            line.ticket = ticket

            -- Color code by status
            line.Paint = function(this, width, height)
                local color = ax.color:Get("white")
                if ( ticket.status == "open" ) then
                    color = this:IsLineSelected() and ax.color:Get("green.dark") or ax.color:Get("green.soft")
                elseif ( ticket.status == "claimed" ) then
                    color = this:IsLineSelected() and ax.color:Get("yellow.dark") or ax.color:Get("yellow.soft")
                elseif ( ticket.status == "closed" ) then
                    color = this:IsLineSelected() and ax.color:Get("red.dark") or ax.color:Get("red.soft")
                end

                surface.SetDrawColor(color)
                surface.DrawRect(0, 0, width, height)
            end

            ticketsList:SortByColumn(4, true)

            if ( ticket.id == MODULE.SelectedTicketID ) then
                MODULE:ShowTicketDetails(adminDetailsPanel, ticket)
            end
        end
    end

    adminMenu.RefreshTickets()

    tabPanel:AddSheet("Tickets", ticketsPanel, "icon16/report.png")

    ax.gui.admin = adminMenu
    MODULE.AdminMenu = adminMenu
end

-- Open admin menu command
concommand.Add("ax_admin_menu", function()
    if ( !CAMI.PlayerHasAccess(ax.client, "Parallax - Admin Menu", nil) ) then
        ax.notification:Send(ax.client, "You don't have permission to access the admin menu.")
        return
    end

    MODULE:CreateAdminMenu()
end)

-- Create ticket menu
function MODULE:CreateTicketMenu()
    if (!ax.config:Get("admin.tickets.enabled", true)) then
        ax.notification:Send(ax.client, "Ticket system is disabled.")
        return
    end

    if (IsValid(ax.gui.tickets)) then
        ax.gui.tickets:Remove()
    end

    local ticketMenu = vgui.Create("DFrame")
    ticketMenu:SetSize(800, 600)
    ticketMenu:Center()
    ticketMenu:SetTitle("Ticket System")
    ticketMenu:SetDeleteOnClose(true)
    ticketMenu:SetDraggable(true)
    ticketMenu:SetScreenLock(true)
    ticketMenu:SetBackgroundBlur(true)
    ticketMenu:MakePopup()

    -- Request ticket list
    net.Start("ax.admin.ticket.list")
    net.SendToServer()

    -- Create main panel
    local mainPanel = vgui.Create("DPanel", ticketMenu)
    mainPanel:Dock(FILL)
    mainPanel:DockMargin(5, 5, 5, 5)

    -- Create ticket button
    local createButton = vgui.Create("DButton", mainPanel)
    createButton:SetText("Create New Ticket")
    createButton:SetSize(150, 30)
    createButton:SetPos(10, 10)
    createButton.DoClick = function()
        MODULE:ShowCreateTicketDialog()
    end

    -- Tickets list
    local ticketsList = vgui.Create("DListView", mainPanel)
    ticketsList:SetPos(10, 50)
    ticketsList:SetSize(375, 500)
    ticketsList:SetMultiSelect(false)
    ticketsList:AddColumn("ID")
    ticketsList:AddColumn("Title")
    ticketsList:AddColumn("Status")
    ticketsList:AddColumn("Created")

    -- Ticket details panel
    local detailsPanel = vgui.Create("DPanel", mainPanel)
    detailsPanel:SetPos(395, 50)
    detailsPanel:SetSize(375, 500)
    detailsPanel.Paint = function(this, width, height)
        surface.SetDrawColor(50, 50, 50, 200)
        surface.DrawRect(0, 0, width, height)
    end

    -- Ticket selection handler
    ticketsList.OnRowSelected = function(lst, index, pnl)
        local ticket = pnl.ticket
        if (!ticket) then return end

        MODULE:ShowTicketDetails(detailsPanel, ticket)
    end

    -- Refresh function
    ticketMenu.RefreshTickets = function()
        ticketsList:Clear()
        detailsPanel:Clear()

        for id, ticket in pairs(MODULE.ClientTickets) do
            local timeStr = os.date("%m/%d %H:%M", ticket.timestamp)
            local line = ticketsList:AddLine(ticket.id, ticket.title, ticket.status, timeStr)
            line.ticket = ticket

            -- Color code by status
            line.Paint = function(this, width, height)
                local color = ax.color:Get("white")
                if ( ticket.status == "open" ) then
                    color = this:IsLineSelected() and ax.color:Get("green.dark") or ax.color:Get("green.soft")
                elseif ( ticket.status == "claimed" ) then
                    color = this:IsLineSelected() and ax.color:Get("yellow.dark") or ax.color:Get("yellow.soft")
                elseif ( ticket.status == "closed" ) then
                    color = this:IsLineSelected() and ax.color:Get("red.dark") or ax.color:Get("red.soft")
                end

                surface.SetDrawColor(color)
                surface.DrawRect(0, 0, width, height)
            end

            ticketsList:SortByColumn(4, true)

            if ( ticket.id == MODULE.SelectedTicketID ) then
                MODULE:ShowTicketDetails(detailsPanel, ticket)
            end
        end
    end

    ticketMenu.RefreshTickets()

    ax.gui.tickets = ticketMenu
    MODULE.TicketMenu = ticketMenu
end

-- Show create ticket dialog
function MODULE:ShowCreateTicketDialog()
    local createDialog = vgui.Create("DFrame")
    createDialog:SetSize(400, 300)
    createDialog:Center()
    createDialog:SetTitle("Create Ticket")
    createDialog:MakePopup()

    local titleLabel = vgui.Create("DLabel", createDialog)
    titleLabel:SetPos(10, 30)
    titleLabel:SetSize(380, 20)
    titleLabel:SetText("Title:")

    local titleEntry = vgui.Create("DTextEntry", createDialog)
    titleEntry:SetPos(10, 50)
    titleEntry:SetSize(380, 25)
    titleEntry:SetPlaceholderText("Enter ticket title...")

    local descLabel = vgui.Create("DLabel", createDialog)
    descLabel:SetPos(10, 85)
    descLabel:SetSize(380, 20)
    descLabel:SetText("Description:")

    local descEntry = vgui.Create("DTextEntry", createDialog)
    descEntry:SetPos(10, 105)
    descEntry:SetSize(380, 120)
    descEntry:SetMultiline(true)
    descEntry:SetPlaceholderText("Enter detailed description...")

    local submitButton = vgui.Create("DButton", createDialog)
    submitButton:SetPos(10, 235)
    submitButton:SetSize(185, 30)
    submitButton:SetText("Create Ticket")
    submitButton.DoClick = function()
        local title = titleEntry:GetValue()
        local description = descEntry:GetValue()

        if (title == "" or description == "") then
            ax.notification:Send(ax.client, "Title and description cannot be empty.")
            return
        end

        net.Start("ax.admin.ticket.create")
            net.WriteString(title)
            net.WriteString(description)
        net.SendToServer()

        createDialog:Close()
    end

    local cancelButton = vgui.Create("DButton", createDialog)
    cancelButton:SetPos(205, 235)
    cancelButton:SetSize(185, 30)
    cancelButton:SetText("Cancel")
    cancelButton.DoClick = function()
        createDialog:Close()
    end
end

-- Show ticket details
function MODULE:ShowTicketDetails(panel, ticket)
    if (!IsValid(panel)) then return end

    print("Showing details for ticket ID:", ticket.id)

    self.SelectedTicketID = ticket.id

    -- Clear previous content
    for _, child in pairs(panel:GetChildren()) do
        child:Remove()
    end

    -- Store reference to current ticket
    if (IsValid(MODULE.TicketMenu)) then
        MODULE.TicketMenu.currentTicketID = ticket.id
    end

    -- Ticket info
    local titleLabel = vgui.Create("DLabel", panel)
    titleLabel:SetPos(10, 10)
    titleLabel:SetSize(355, 20)
    titleLabel:SetText("Title: " .. ticket.title)
    titleLabel:SetFont("DermaDefaultBold")

    local statusLabel = vgui.Create("DLabel", panel)
    statusLabel:SetPos(10, 35)
    statusLabel:SetSize(355, 20)
    statusLabel:SetText("Status: " .. ticket.status .. (ticket.claimerName and " (by " .. ticket.claimerName .. ")" or ""))

    local creatorLabel = vgui.Create("DLabel", panel)
    creatorLabel:SetPos(10, 60)
    creatorLabel:SetSize(355, 20)
    creatorLabel:SetText("Creator: " .. ticket.creatorName)

    local timeLabel = vgui.Create("DLabel", panel)
    timeLabel:SetPos(10, 85)
    timeLabel:SetSize(355, 20)
    timeLabel:SetText("Created: " .. os.date("%Y-%m-%d %H:%M:%S", ticket.timestamp))

    -- Description
    local descLabel = vgui.Create("DLabel", panel)
    descLabel:SetPos(10, 110)
    descLabel:SetSize(355, 20)
    descLabel:SetText("Description:")
    descLabel:SetFont("DermaDefaultBold")

    local descText = vgui.Create("DLabel", panel)
    descText:SetPos(10, 135)
    descText:SetSize(355, 60)
    descText:SetText(ticket.description)
    descText:SetWrap(true)
    descText:SetAutoStretchVertical(true)

    -- Comments section
    local commentsLabel = vgui.Create("DLabel", panel)
    commentsLabel:SetPos(10, 200)
    commentsLabel:SetSize(355, 20)
    commentsLabel:SetText("Comments:")
    commentsLabel:SetFont("DermaDefaultBold")

    local commentsList = vgui.Create("DListView", panel)
    commentsList:SetPos(10, 225)
    commentsList:SetSize(355, 120)
    commentsList:SetMultiSelect(false)
    commentsList:AddColumn("Author")
    commentsList:AddColumn("Message")
    commentsList:AddColumn("Time")
    commentsList:SetSortable(true)

    -- Populate comments
    local comments = MODULE.ClientTicketComments[ticket.id] or {}
    for _, comment in pairs(comments) do
        local timeStr = os.date("%m/%d %H:%M:%S", comment.timestamp)
        local line = commentsList:AddLine(comment.authorName, comment.message, timeStr)

        if ( comment.isAdmin ) then
            line.Paint = function(this, width, height)
                surface.SetDrawColor(this:IsLineSelected() and ax.color:Get("maroon.dark") or ax.color:Get("maroon.soft"))
                surface.DrawRect(0, 0, width, height)
            end
        end
    end

    commentsList:SortByColumn(3, true)

    -- Comment input
    local commentEntry = vgui.Create("DTextEntry", panel)
    commentEntry:SetPos(10, 355)
    commentEntry:SetSize(270, 25)
    commentEntry:SetPlaceholderText("Enter comment...")

    local commentButton = vgui.Create("DButton", panel)
    commentButton:SetPos(285, 355)
    commentButton:SetSize(80, 25)
    commentButton:SetText("Comment")
    commentButton.DoClick = function()
        local message = commentEntry:GetValue()
        if (message == "") then
            ax.notification:Send(ax.client, "Comment cannot be empty.")
            return
        end

        net.Start("ax.admin.ticket.comment")
            net.WriteUInt(ticket.id, 32)
            net.WriteString(message)
        net.SendToServer()

        commentEntry:SetValue("")
    end

    -- Store reference to comment entry for live updates
    if (IsValid(MODULE.TicketMenu)) then
        MODULE.TicketMenu.currentCommentEntry = commentEntry
    end

    -- Handle enter key for comment submission
    commentEntry.OnEnter = function()
        commentButton:DoClick()
    end

    -- Action buttons
    local isAdmin = CAMI.PlayerHasAccess(ax.client, "Parallax - Admin Menu", nil)
    local isCreator = ticket.creator == ax.client:SteamID64()
    local creator = player.GetBySteamID64(ticket.creator)

    local buttonY = 390
    local buttonSpacing = 5
    local buttonsPerRow = 5
    local currentButton = 0
    local buttonWidth = panel:GetWide() / buttonsPerRow - (buttonsPerRow - 1) * (buttonSpacing * 2) / buttonsPerRow
    local buttonHeight = 25

    local function CreateActionButton(text, permission, callback)
        if (!CAMI.PlayerHasAccess(ax.client, permission, nil)) then
            return
        end

        local x = 10 + (currentButton % buttonsPerRow) * (buttonWidth + buttonSpacing)
        local y = buttonY + math.floor(currentButton / buttonsPerRow) * (buttonHeight + buttonSpacing)

        local btn = vgui.Create("DButton", panel)
        btn:SetPos(x, y)
        btn:SetSize(buttonWidth, buttonHeight)
        btn:SetText(text)
        btn.DoClick = callback

        currentButton = currentButton + 1
        return btn
    end

    -- Ticket management buttons
    if (isAdmin and ticket.status == "open") then
        CreateActionButton("Claim", "Parallax - Admin Menu", function()
            net.Start("ax.admin.ticket.claim")
                net.WriteUInt(ticket.id, 32)
            net.SendToServer()
        end)
    end

    if ((isAdmin or isCreator) and ticket.status != "closed") then
        CreateActionButton("Close", "Parallax - Admin Menu", function()
            Derma_Query("Are you sure you want to close this ticket?", "Close Ticket", "Yes", function()
                net.Start("ax.admin.ticket.close")
                    net.WriteUInt(ticket.id, 32)
                net.SendToServer()
            end, "No", function() end)
        end)
    end

    -- Player action buttons (only for admins and if creator is online)
    if (isAdmin and IsValid(creator)) then
        CreateActionButton("Goto", "Parallax - Teleport", function()
            ax.command:Run("PlyGoto", creator:UserID())
        end)

        CreateActionButton("Bring", "Parallax - Bring Players", function()
            ax.command:Run("PlyBring", creator:UserID())
        end)

        CreateActionButton("Return", "Parallax - Teleport", function()
            ax.command:Run("PlyReturn", creator:UserID())
        end)

        CreateActionButton("Spectate", "Parallax - Spectate", function()
            ax.command:Run("PlySpectate", creator:UserID())
        end)

        CreateActionButton("Freeze", "Parallax - Freeze Players", function()
            ax.command:Run("PlyFreeze", creator:UserID())
        end)

        CreateActionButton("Heal", "Parallax - Admin Menu", function()
            Derma_StringRequest("Heal Player", "How much health do you want to give " .. creator:SteamName() .. "?", "25", function(health)
                ax.command:Run("PlyHeal", creator:UserID(), tonumber(health) or 25)
            end, "Cancel", function() end)
        end)

        CreateActionButton("Strip", "Parallax - Strip Weapons", function()
            Derma_Query("Are you sure you want to strip all weapons from " .. creator:SteamName() .. "?", "Strip Weapons", "Yes", function()
                ax.command:Run("PlyStrip", creator:UserID())
            end, "No", function() end)
        end)

        CreateActionButton("Slay", "Parallax - Slay Players", function()
            Derma_Query("Are you sure you want to slay " .. creator:SteamName() .. "?", "Slay Player", "Yes", function()
                ax.command:Run("PlySlay", creator:UserID())
            end, "No", function() end)
        end)

        CreateActionButton("Respawn", "Parallax - Respawn Players", function()
            ax.command:Run("PlyRespawn", creator:UserID())
        end)

        CreateActionButton("Kick", "Parallax - Kick Players", function()
            Derma_StringRequest("Kick Player", "Enter reason:", "Ticket #" .. ticket.id, function(reason)
                ax.command:Run("PlyKick", creator:UserID(), reason)
            end)
        end)

        CreateActionButton("Ban", "Parallax - Ban Players", function()
            local banFrame = vgui.Create("DFrame")
            banFrame:SetSize(300, 150)
            banFrame:Center()
            banFrame:SetTitle("Ban Player")
            banFrame:MakePopup()

            local reasonEntry = vgui.Create("DTextEntry", banFrame)
            reasonEntry:SetPos(10, 30)
            reasonEntry:SetSize(280, 25)
            reasonEntry:SetValue("Ticket #" .. ticket.id)

            local durationSlider = vgui.Create("DNumSlider", banFrame)
            durationSlider:SetPos(10, 60)
            durationSlider:SetSize(280, 25)
            durationSlider:SetText("Duration (minutes)")
            durationSlider:SetMin(0)
            durationSlider:SetMax(10080)
            durationSlider:SetValue(0)

            local banBtn = vgui.Create("DButton", banFrame)
            banBtn:SetPos(10, 100)
            banBtn:SetSize(135, 25)
            banBtn:SetText("Ban")
            banBtn.DoClick = function()
                local reason = reasonEntry:GetValue()
                local duration = durationSlider:GetValue()
                ax.command:Run("PlyBan", creator:UserID(), duration, reason)
                banFrame:Close()
            end

            local cancelBtn = vgui.Create("DButton", banFrame)
            cancelBtn:SetPos(155, 100)
            cancelBtn:SetSize(135, 25)
            cancelBtn:SetText("Cancel")
            cancelBtn.DoClick = function()
                banFrame:Close()
            end
        end)

        -- Admin utility buttons
        CreateActionButton("Noclip", "Parallax - Noclip", function()
            ax.command:Run("ToggleNoclip", creator:UserID())
        end)

        CreateActionButton("God", "Parallax - Godmode", function()
            ax.command:Run("ToggleGodmode", creator:UserID())
        end)
    elseif (isAdmin and !IsValid(creator)) then
        -- Show offline player info
        local offlineLabel = vgui.Create("DLabel", panel)
        offlineLabel:SetPos(10, buttonY)
        offlineLabel:SetSize(355, 20)
        offlineLabel:SetText("Player is offline - Limited actions available")
        offlineLabel:SetTextColor(ax.color:Get("orange"))

        -- Only show ban option for offline players
        CreateActionButton("Ban", "Parallax - Ban Offline", function()
            local banFrame = vgui.Create("DFrame")
            banFrame:SetSize(300, 150)
            banFrame:Center()
            banFrame:SetTitle("Ban Offline Player")
            banFrame:MakePopup()

            local reasonEntry = vgui.Create("DTextEntry", banFrame)
            reasonEntry:SetPos(10, 30)
            reasonEntry:SetSize(280, 25)
            reasonEntry:SetValue("Ticket #" .. ticket.id)

            local durationSlider = vgui.Create("DNumSlider", banFrame)
            durationSlider:SetPos(10, 60)
            durationSlider:SetSize(280, 25)
            durationSlider:SetText("Duration (minutes)")
            durationSlider:SetMin(0)
            durationSlider:SetMax(10080)
            durationSlider:SetValue(0)

            local banBtn = vgui.Create("DButton", banFrame)
            banBtn:SetPos(10, 100)
            banBtn:SetSize(135, 25)
            banBtn:SetText("Ban")
            banBtn.DoClick = function()
                local reason = reasonEntry:GetValue()
                local duration = durationSlider:GetValue()

                -- Create offline ban
                local banData = {
                    steamid = ticket.creator,
                    name = ticket.creatorName,
                    admin = ax.client:SteamID64(),
                    adminName = ax.client:SteamName(),
                    reason = reason,
                    timestamp = os.time(),
                    duration = duration,
                    expires = duration > 0 and (os.time() + duration * 60) or 0
                }

                net.Start("ax.admin.ban.offline")
                    net.WriteTable(banData)
                net.SendToServer()

                banFrame:Close()
            end

            local cancelBtn = vgui.Create("DButton", banFrame)
            cancelBtn:SetPos(155, 100)
            cancelBtn:SetSize(135, 25)
            cancelBtn:SetText("Cancel")
            cancelBtn.DoClick = function()
                banFrame:Close()
            end
        end)
    end
end

-- Open ticket menu command
concommand.Add("ax_ticket_menu", function()
    MODULE:CreateTicketMenu()
end)