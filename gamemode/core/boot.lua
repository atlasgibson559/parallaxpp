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

Parallax.Util:Print("Framework Initializing...")
Parallax.Util:LoadFolder("libraries/external")
Parallax.Util:LoadFolder("libraries/client")
Parallax.Util:LoadFolder("libraries/shared")
Parallax.Util:LoadFolder("libraries/server")
Parallax.Util:LoadFolder("definitions")
Parallax.Util:LoadFolder("meta")
Parallax.Util:LoadFolder("ui")
Parallax.Util:LoadFolder("hooks")
Parallax.Util:LoadFolder("net")
Parallax.Util:LoadFolder("languages")
Parallax.Util:Print("Framework Initialized.")

function widgets.PlayerTick()
end

hook.Remove("PlayerTick", "TickWidgets")