ITEM.Name = "Weapon Base"
ITEM.Description = "A base for all weapons."
ITEM.Category = "Weapons"
ITEM.Model = Model("models/weapons/w_smg1.mdl")

ITEM.Weight = 5

ITEM.WeaponClass = "weapon_base"

ITEM.Actions.Equip = {
    Name = "Equip",
    Description = "Equip the pistol.",
    OnRun = function(this, item, client)
        local weapon = client:Give(item.WeaponClass)
        if ( !IsValid(weapon) ) then return end

        local axWeapons = client:GetRelay("weapons", {})
        axWeapons[item.WeaponClass] = item:GetID()
        client:SetRelay("weapons", axWeapons)

        client:SelectWeapon(item.WeaponClass)

        item:SetData("equipped", true)
    end,
    OnCanRun = function(this, item, client)
        local axWeapons = client:GetRelay("weapons", {})
        return !axWeapons[item.WeaponClass] and !client:HasWeapon(item.WeaponClass)
    end
}

ITEM.Actions.EquipUn = {
    Name = "Unequip",
    Description = "Unequip the pistol.",
    OnRun = function(this, item, client)
        client:StripWeapon(item.WeaponClass)
        client:SelectWeapon("ax_hands")

        local axWeapons = client:GetRelay("weapons", {})
        axWeapons[item.WeaponClass] = nil
        client:SetRelay("weapons", axWeapons)

        item:SetData("equipped", false)
    end,
    OnCanRun = function(this, item, client)
        local axWeapons = client:GetRelay("weapons", {})
        local axWeaponID = axWeapons[item.WeaponClass]
        return tobool(axWeaponID and client:HasWeapon(item.WeaponClass) and axWeaponID == item:GetID())
    end
}

ITEM:Hook("Drop", function(item, client)
    local axWeapons = client:GetRelay("weapons", {})
    if ( client:HasWeapon(item.WeaponClass) and axWeapons[item.WeaponClass] == item:GetID() ) then
        client:StripWeapon(item.WeaponClass)
        client:SelectWeapon("ax_hands")

        axWeapons[item.WeaponClass] = nil
        client:SetRelay("weapons", axWeapons)

        item:SetData("equipped", false)
    end
end)

function ITEM:OnCache()
    self:SetData("equipped", self:GetData("equipped", false))
end