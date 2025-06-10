--- Options library
-- @module ax.option

ax.option = ax.option or {}
ax.option.stored = ax.option.stored or {}
ax.option.clients = ax.option.clients or {}

function ax.option:Set(client, key, value, bNoNetworking)
    local stored = self.stored[key]
    if ( !istable(stored) ) then
        ax.util:PrintError("Option \"" .. key .. "\" does not exist!")
        return false
    end

    if ( !IsValid(client) ) then return false end

    local bResult = hook.Run("PreOptionChanged", client, key, value)
    if ( bResult == false ) then return false end

    if ( stored.NoNetworking != true ) then
        if ( !bNoNetworking ) then
            ax.net:Start(client, "option.set", key, value)
        end

        local index = client:EntIndex()
        if ( ax.option.clients[index] == nil ) then
            ax.option.clients[index] = {}
        end

        ax.option.clients[index][key] = value
    end

    if ( isfunction(stored.OnChange) ) then
        stored:OnChange(value, client)
    end

    return true
end

function ax.option:Get(client, key, fallback)
    if ( !IsValid(client) ) then return default end

    local stored = ax.option.stored[key]
    if ( !istable(stored) ) then
        ax.util:PrintError("Option \"" .. key .. "\" does not exist!")
        return default
    end

    if ( stored.NoNetworking ) then
        ax.util:PrintWarning("Option \"" .. key .. "\" is not networked!")
        return fallback
    end

    local clientStored = ax.option.clients[client:EntIndex()]
    if ( !istable(clientStored) ) then
        return fallback
    end

    local value = clientStored[key]
    if ( value != nil ) then
        return value
    end

    return fallback
end