--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- A library for managing modules in the gamemode.
-- @module Parallax.Module

Parallax.Module = {}
Parallax.Module.Stored = {}
Parallax.Module.disabled = {}

--- Returns a module by its unique identifier or name.
-- @realm shared
-- @string identifier The unique identifier or name of the module.
-- @return table The module.
function Parallax.Module:Get(identifier)
    if ( identifier == nil or !isstring(identifier) ) then
        Parallax.Util:PrintError("Attempted to get an invalid module!")
        return false
    end

    if ( self.Stored[identifier] ) then
        return self.Stored[identifier]
    end

    for k, v in pairs(self.Stored) do
        if ( Parallax.Util:FindString(v.Name, identifier) ) then
            return v
        end
    end

    return false
end

function Parallax.Module:LoadFolder(path)
    if ( !path or path == "" ) then
        Parallax.Util:PrintError("Attempted to load an invalid module folder!")
        return false
    end

    hook.Run("PreInitializeModules")

    Parallax.Util:Print("Loading modules from \"" .. path .. "\"...")

    local files, folders = file.Find(path .. "/*", "LUA")
    local folderCount = #folders
    for i = 1, folderCount do
        local v = folders[i]
        if ( file.Exists(path .. "/" .. v .. "/boot.lua", "LUA") ) then
            MODULE = { UniqueID = v }
                hook.Run("PreInitializeModule", MODULE)
                Parallax.Util:LoadFile(path .. "/" .. v .. "/boot.lua", "shared")
                Parallax.Util:LoadFolder(path .. "/" .. v .. "/ui", true)
                Parallax.Util:LoadFolder(path .. "/" .. v .. "/libraries/external", true)
                Parallax.Util:LoadFolder(path .. "/" .. v .. "/libraries/client", true)
                Parallax.Util:LoadFolder(path .. "/" .. v .. "/libraries/shared", true)
                Parallax.Util:LoadFolder(path .. "/" .. v .. "/libraries/server", true)
                Parallax.Util:LoadFolder(path .. "/" .. v .. "/factions", true)
                Parallax.Util:LoadFolder(path .. "/" .. v .. "/classes", true)
                Parallax.Util:LoadFolder(path .. "/" .. v .. "/definitions", true)
                Parallax.Util:LoadFolder(path .. "/" .. v .. "/meta", true)
                Parallax.Util:LoadFolder(path .. "/" .. v .. "/ui", true)
                Parallax.Util:LoadFolder(path .. "/" .. v .. "/hooks", true)
                Parallax.Util:LoadFolder(path .. "/" .. v .. "/net", true)
                Parallax.Util:LoadFolder(path .. "/" .. v .. "/languages", true)
                Parallax.Item:LoadFolder(path .. "/" .. v .. "/items")
                Parallax.Util:LoadFolder(path .. "/" .. v .. "/config", true)
                Parallax.Util:LoadEntities(path .. "/" .. v .. "/entities")
                self.Stored[v] = MODULE
                hook.Run("PostInitializeModule", MODULE)
            MODULE = nil
        else
            Parallax.Util:PrintError("Module " .. v .. " is missing a shared module file.")
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
            Parallax.Util:LoadFile(path .. "/" .. v, realm)
            self.Stored[ModuleUniqueID] = MODULE
            hook.Run("PostInitializeModule", MODULE)
        MODULE = nil
    end

    if ( files[1] != nil or folders[1] != nil ) then
        Parallax.Util:Print("Loaded " .. #files .. " files and " .. #folders .. " folders from \"" .. path .. "\", total " .. (#files + #folders) .. " modules.")
    end

    hook.Run("PostInitializeModules")
end

Parallax.module = Parallax.Module