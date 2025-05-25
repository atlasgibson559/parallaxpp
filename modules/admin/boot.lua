local MODULE = MODULE

MODULE.Name        = "Admin"
MODULE.ID          = "admin"
MODULE.Description = "Editable admin system using CAMI and Parallax persistence."
MODULE.Author      = "Riggs"

MODULE.Groups      = {}
MODULE.Permissions = {}

--- Registers a usergroup and stores it persistently.
-- @string name
-- @number privilege
function MODULE:RegisterGroup(name, privilege)
    local group = {
        Name = name,
        Inherits = nil,
        Privilege = privilege
    }

    CAMI.RegisterUsergroup(group, "Parallax")

    self.Groups[name] = group
    self:SaveData()
end

--- Registers a permission and stores it persistently.
-- @string name
-- @string minAccess
function MODULE:RegisterPermission(name, minAccess)
    local permission = {
        Name = name,
        MinAccess = minAccess,
        HasAccess = nil
    }

    CAMI.RegisterPrivilege(permission)

    self.Permissions[name] = permission
    self:SaveData()
end

function MODULE:GetGroups()
    return self.Groups
end

function MODULE:GetPermissions()
    return self.Permissions
end