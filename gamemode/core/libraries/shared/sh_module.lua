--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- A library for managing modules in the gamemode.
-- @module ax.module

ax.module = {}
ax.module.stored = {}
ax.module.disabled = {}

--- Returns a module by its unique identifier or name.
-- @realm shared
-- @string identifier The unique identifier or name of the module.
-- @return table The module.
function ax.module:Get(identifier)
    if ( identifier == nil or !isstring(identifier) ) then
        ax.Util:PrintError("Attempted to get an invalid module!")
        return false
    end

    if ( self.stored[identifier] ) then
        return self.stored[identifier]
    end

    for k, v in pairs(self.stored) do
        if ( ax.Util:FindString(v.Name, identifier) ) then
            return v
        end
    end

    return false
end

function ax.module:LoadFolder(path)
    if ( !path or path == "" ) then
        ax.Util:PrintError("Attempted to load an invalid module folder!")
        return false
    end

    hook.Run("PreInitializeModules")

    ax.Util:Print("Loading modules from \"" .. path .. "\"...")

    local files, folders = file.Find(path .. "/*", "LUA")
    local folderCount = #folders
    for i = 1, folderCount do
        local v = folders[i]
        if ( file.Exists(path .. "/" .. v .. "/boot.lua", "LUA") ) then
            MODULE = { UniqueID = v }
                hook.Run("PreInitializeModule", MODULE)
                ax.Util:LoadFile(path .. "/" .. v .. "/boot.lua", "shared")
                ax.Util:LoadFolder(path .. "/" .. v .. "/ui", true)
                ax.Util:LoadFolder(path .. "/" .. v .. "/libraries/external", true)
                ax.Util:LoadFolder(path .. "/" .. v .. "/libraries/client", true)
                ax.Util:LoadFolder(path .. "/" .. v .. "/libraries/shared", true)
                ax.Util:LoadFolder(path .. "/" .. v .. "/libraries/server", true)
                ax.Util:LoadFolder(path .. "/" .. v .. "/factions", true)
                ax.Util:LoadFolder(path .. "/" .. v .. "/classes", true)
                ax.Util:LoadFolder(path .. "/" .. v .. "/definitions", true)
                ax.Util:LoadFolder(path .. "/" .. v .. "/meta", true)
                ax.Util:LoadFolder(path .. "/" .. v .. "/ui", true)
                ax.Util:LoadFolder(path .. "/" .. v .. "/hooks", true)
                ax.Util:LoadFolder(path .. "/" .. v .. "/net", true)
                ax.Util:LoadFolder(path .. "/" .. v .. "/languages", true)
                ax.item:LoadFolder(path .. "/" .. v .. "/items")
                ax.Util:LoadFolder(path .. "/" .. v .. "/config", true)
                ax.Util:LoadEntities(path .. "/" .. v .. "/entities")
                self.stored[v] = MODULE
                hook.Run("PostInitializeModule", MODULE)
            MODULE = nil
        else
            ax.Util:PrintError("Module " .. v .. " is missing a shared module file.")
        end
    end

    local fileCount = #files
    for i = 1, fileCount do
        local v = files[i]
        local ModuleUniqueID = string.StripExtension(v)
        if ( string.sub(v, 1, 3) == "cl_" or string.sub(v, 1, 3) == "sv_" or string.sub(v, 1, 3) == "sh_" ) then
            ModuleUniqueID = string.sub(v, 4)
        end

        local realm = "shared"
        if ( string.sub(v, 1, 3) == "cl_" ) then
            realm = "client"
        elseif ( string.sub(v, 1, 3) == "sv_" ) then
            realm = "server"
        end

        MODULE = { UniqueID = ModuleUniqueID }
            hook.Run("PreInitializeModule", MODULE)
            ax.Util:LoadFile(path .. "/" .. v, realm)
            self.stored[ModuleUniqueID] = MODULE
            hook.Run("PostInitializeModule", MODULE)
        MODULE = nil
    end

    if ( files[1] != nil or folders[1] != nil ) then
        ax.Util:Print("Loaded " .. #files .. " files and " .. #folders .. " folders from \"" .. path .. "\", total " .. (#files + #folders) .. " modules.")
    end

    hook.Run("PostInitializeModules")
end

ax.module = ax.module