ax.net:Hook("animations.update", function(client, animations, holdType)
    if ( !IsValid(client) ) then return end

    local clientTable = client:GetTable()

    clientTable.axAnimations = animations
    clientTable.axHoldType = holdType
    clientTable.axLastAct = -1

    -- ew...
    client:SetIK(false)
end)