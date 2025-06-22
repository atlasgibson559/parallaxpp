--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

GM.Name = "Parallax"
GM.Author = "Riggs and bloodycop6385"
GM.Description = "Parallax is a modular roleplay framework for Garry's Mod, built for performance, structure, and developer clarity."
GM.State = "Beta"

ax.Util:Print("Framework Initializing...")
ax.Util:LoadFolder("libraries/external")
ax.Util:LoadFolder("libraries/client")
ax.Util:LoadFolder("libraries/shared")
ax.Util:LoadFolder("libraries/server")
ax.Util:LoadFolder("definitions")
ax.Util:LoadFolder("meta")
ax.Util:LoadFolder("ui")
ax.Util:LoadFolder("hooks")
ax.Util:LoadFolder("net")
ax.Util:LoadFolder("languages")
ax.Util:Print("Framework Initialized.")

function widgets.PlayerTick()
end

hook.Remove("PlayerTick", "TickWidgets")