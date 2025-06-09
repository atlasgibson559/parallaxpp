local MODULE = MODULE

function MODULE:PlayerCanHearPlayersVoice(listener, speaker)
    local charSpeaker = speaker:GetCharacter()
    local charListener = listener:GetCharacter()

    if ( !charSpeaker or !charListener ) then return false end

    local speakerVoiceMode = speaker:GetRelay("voiceMode", 2) -- Default's to "Normal"
    if ( speakerVoiceMode == 1 ) then -- Whisper
        return ax.chat.classes.whisper:CanHear(speaker, listener), true
    elseif ( speakerVoiceMode == 3 ) then -- Yell
        return ax.chat.classes.yell:CanHear(speaker, listener), true
    end
end