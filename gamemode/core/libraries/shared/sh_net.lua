--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Parallax.Net
-- Streaming data layer using sfs. NetStream-style API.
-- @realm shared

Parallax.Net = Parallax.Net or {}
Parallax.Net.stored = Parallax.Net.stored or {}
Parallax.Net.cooldown = Parallax.Net.cooldown or {}

if ( SERVER ) then
    util.AddNetworkString("Parallax.Net.msg")
end

--- Hooks a network message.
-- @string name Unique identifier.
-- @func callback Callback with player, unpacked arguments.
function Parallax.Net:Hook(name, callback, bNoDelay)
    self.stored[name] = {callback, bNoDelay or false}
end

--- Starts a stream.
-- @param target Player, table, vector or nil (nil = broadcast or to server).
-- @string name Hook name.
-- @vararg Arguments to send.
if ( SERVER ) then
    function Parallax.Net:Start(target, name, ...)
        local arguments = {...}
        local encoded = sfs.encode(arguments)
        if ( !isstring(encoded) or #encoded < 1 ) then return end

        local recipients = {}
        local sendPVS = false

        if ( isvector(target) ) then
            sendPVS = true
        elseif ( istable(target) ) then
            local targetCount = #target
            for i = 1, targetCount do
                local v = target[i]
                if ( IsValid(v) and v:IsPlayer() ) then
                    recipients[#recipients + 1] = v
                end
            end
        elseif ( IsValid(target) and target:IsPlayer() ) then
            recipients[1] = target
        else
            recipients = select(2, player.Iterator())
        end

        net.Start("Parallax.Net.msg")
            net.WriteString(name)
            net.WriteData(encoded, #encoded)

        if ( sendPVS ) then
            net.SendPVS(target)
        else
            net.Send(recipients)
        end

        if ( Parallax.Config:Get("debug.networking") ) then
            Parallax.Util:Print("[Networking] Sent '" .. name .. "' to " .. (SERVER and #recipients .. " players" or "server"))
        end
    end
else
    function Parallax.Net:Start(name, ...)
        local arguments = {...}
        local encoded = sfs.encode(arguments)
        if ( !isstring(encoded) or #encoded < 1 ) then return end

        net.Start("Parallax.Net.msg")
            net.WriteString(name)
            net.WriteData(encoded, #encoded)
        net.SendToServer()
    end
end

net.Receive("Parallax.Net.msg", function(len, client)
    local name = net.ReadString()
    local raw = net.ReadData(len / 8)

    local ok, decoded = pcall(sfs.decode, raw)
    if ( !ok or type(decoded) != "table" ) then
        Parallax.Util:PrintError("[Networking] Decode failed for '" .. name .. "'")
        return
    end

    local stored = Parallax.Net.stored[name]
    if ( !istable(stored) or #stored < 1 ) then
        Parallax.Util:PrintError("[Networking] No handler for '" .. name .. "'")
        return
    end

    local callback = stored[1]
    if ( !isfunction(callback) ) then
        Parallax.Util:PrintError("[Networking] No handler for '" .. name .. "'")
        return
    end

    if ( SERVER ) then
        local configCooldown = Parallax.Config:Get("networking.cooldown", 0.1)
        if ( !stored[2] and isnumber(configCooldown) and configCooldown > 0 ) then
            local steam64 = client:SteamID64()
            if ( !istable(Parallax.Net.cooldown[steam64]) ) then Parallax.Net.cooldown[steam64] = {} end
            if ( !isnumber(Parallax.Net.cooldown[steam64][name]) ) then Parallax.Net.cooldown[steam64][name] = 0 end

            local coolDown = Parallax.Net.cooldown[steam64][name]
            if ( isnumber(coolDown) and coolDown > CurTime() ) then
                Parallax.Util:PrintWarning("[Networking] '" .. name .. "' is on cooldown for " .. math.ceil(coolDown - CurTime()) .. " seconds, ignoring request from " .. (tostring(client) or "unknown"))

                return
            end

            Parallax.Net.cooldown[steam64][name] = CurTime() + (configCooldown or 0.1)
        end

        callback(client, unpack(decoded))
    else
        callback(unpack(decoded))
    end

    if ( Parallax.Config:Get("debug.networking") ) then
        Parallax.Util:Print("[Networking] Received '" .. name .. "' from " .. (SERVER and client:Nick() or "server"))
    end
end)

--[[
--- Example usage:
if ( SERVER ) then
    Parallax.Net:Hook("test", function(client, val, val2)
        print(client, "sent:", val, val2)
    end)
end

if ( CLIENT ) then
    Parallax.Net:Start(nil, "test", {89})
    Parallax.Net:Start(nil, "test", "hello", "world")
end
]]