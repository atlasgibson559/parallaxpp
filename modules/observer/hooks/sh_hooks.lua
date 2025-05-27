local MODULE = MODULE

function MODULE:CanPlayerObserve(client, state)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Observer") ) then return false end

    return true
end

function MODULE:ShouldDrawObserverHUD(client)
    return true
end