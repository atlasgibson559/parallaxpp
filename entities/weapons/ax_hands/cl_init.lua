include("shared.lua")

function SWEP:CheckYaw()
    local client = self:GetOwner()
    local playerPitch = client:EyeAngles().p
    if ( playerPitch < -20 ) then
        if ( client:OnCooldown("hands") ) then return end
        client:SetCooldown("hands", 0.5)

        ax.net:Start("hands.reset")
    end
end

function SWEP:Think()
    if ( self:GetOwner() ) then
        self:CheckYaw()
    end
end