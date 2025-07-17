--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:PostEntitySetModel(ent, model)
    if ( !IsValid(ent) or !ent:IsPlayer() ) then return end

    local client = ent
    local clientTable = client:GetTable()
    if ( !clientTable ) then return end

    local weapon = client:GetActiveWeapon()
    if ( !IsValid(weapon) ) then return end

    local holdType = weapon:GetHoldType()
    if ( !holdType ) then return end

    holdType = HOLDTYPE_TRANSLATOR[holdType] or holdType

    local animTable = ax.animations.stored[ax.animations:GetModelClass(model)]
    if ( animTable and animTable[holdType] ) then
        clientTable.axAnimations = animTable[holdType]
    else
        clientTable.axAnimations = {}
    end

    net.Start("ax.animations.update")
        net.WritePlayer(client)
        net.WriteTable(clientTable.axAnimations)
        net.WriteString(holdType)
    net.Broadcast()
end

function MODULE:PlayerLoadout(client)
    if ( !IsValid(client) ) then return end

    local weapon = client:GetActiveWeapon()
    if ( !IsValid(weapon) ) then return end

    local holdType = weapon:GetHoldType()
    if ( !holdType ) then return end

    local clientTable = client:GetTable()

    holdType = HOLDTYPE_TRANSLATOR[holdType] or holdType

    local animTable = ax.animations.stored[ax.animations:GetModelClass(client:GetModel())]
    if ( animTable and animTable[holdType] ) then
        clientTable.axAnimations = animTable[holdType]
    else
        clientTable.axAnimations = {}
    end

    net.Start("ax.animations.update")
        net.WritePlayer(client)
        net.WriteTable(clientTable.axAnimations)
        net.WriteString(holdType)
    net.Broadcast()
end

function MODULE:PlayerSwitchWeapon(client, oldWeapon, newWeapon)
    if ( !IsValid(client) ) then return end
    if ( !IsValid(newWeapon) ) then return end

    local holdType = newWeapon:GetHoldType()
    if ( !holdType ) then return end

    local clientTable = client:GetTable()

    holdType = HOLDTYPE_TRANSLATOR[holdType] or holdType

    local animTable = ax.animations.stored[ax.animations:GetModelClass(client:GetModel())]
    if ( animTable and animTable[holdType] ) then
        clientTable.axAnimations = animTable[holdType]
    else
        clientTable.axAnimations = {}
    end

    net.Start("ax.animations.update")
        net.WritePlayer(client)
        net.WriteTable(clientTable.axAnimations)
        net.WriteString(holdType)
    net.Broadcast()
end
