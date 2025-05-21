AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function SWEP:Initialize()
    self:SetHoldType(self.HoldType or "pistol")
end