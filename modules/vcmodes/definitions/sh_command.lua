local MODULE = MODULE

ax.command:Register("ChangeVoiceMode", {
    Description = "Change your voice chat mode.",
    AdminOnly = false,
    Arguments = {
        {
            Type = ax.types.number,
            ErrorMsg = "You must provide a valid player to take a flag from!"
        }
    },
    Callback = function(info, client, arguments)
        local char = client:GetCharacter()

        if ( !char ) then
            client:Notify("You must have a character to change your voice mode!")
            return
        end

        local hashMap = {}
        for k, v in ipairs(MODULE.Modes) do
            hashMap[v] = true
        end

        local mode = arguments[1]
        if ( hashMap[mode] ) then
            client:SetRelay("voiceMode", table.KeyFromValue(MODULE.Modes, mode))
        else
            client:Notify("Invalid voice chat mode! Valid modes are: " .. table.concat(MODULE.Modes, ", ") .. ".")
            return
        end

        client:Notify("Your voice chat mode has been changed to " .. mode .. ".")
    end
})