--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Default colors
Parallax.Color:Register("black", color_black)
Parallax.Color:Register("blue", Color(0, 0, 255, 255))
Parallax.Color:Register("blue.soft", Color(100, 100, 255, 255))
Parallax.Color:Register("brown", Color(165, 40, 40, 255))
Parallax.Color:Register("brown.soft", Color(200, 100, 100, 255))
Parallax.Color:Register("cyan", Color(0, 255, 255, 255))
Parallax.Color:Register("cyan.soft", Color(100, 255, 255, 255))
Parallax.Color:Register("dark.gray", Color(170, 170, 170, 255))
Parallax.Color:Register("dark.gray.soft", Color(190, 190, 190, 255))
Parallax.Color:Register("gray", Color(130, 130, 130, 255))
Parallax.Color:Register("gray.soft", Color(170, 170, 170, 255))
Parallax.Color:Register("green", Color(0, 255, 0, 255))
Parallax.Color:Register("green.soft", Color(100, 255, 100, 255))
Parallax.Color:Register("light.gray", Color(210, 210, 210, 255))
Parallax.Color:Register("light.gray.soft", Color(230, 230, 230, 255))
Parallax.Color:Register("lime", Color(0, 255, 0, 255))
Parallax.Color:Register("lime.soft", Color(100, 255, 100, 255))
Parallax.Color:Register("maroon", Color(130, 0, 0, 255))
Parallax.Color:Register("maroon.soft", Color(180, 100, 100, 255))
Parallax.Color:Register("navy", Color(0, 0, 130, 255))
Parallax.Color:Register("navy.soft", Color(100, 100, 180, 255))
Parallax.Color:Register("olive", Color(130, 130, 0, 255))
Parallax.Color:Register("olive.soft", Color(180, 180, 100, 255))
Parallax.Color:Register("orange", Color(255, 165, 0, 255))
Parallax.Color:Register("orange.soft", Color(255, 200, 100, 255))
Parallax.Color:Register("pink", Color(255, 190, 205, 255))
Parallax.Color:Register("pink.soft", Color(255, 210, 220, 255))
Parallax.Color:Register("purple", Color(130, 0, 130, 255))
Parallax.Color:Register("purple.soft", Color(180, 100, 180, 255))
Parallax.Color:Register("red", Color(255, 0, 0, 255))
Parallax.Color:Register("red.soft", Color(255, 100, 100, 255))
Parallax.Color:Register("silver", Color(190, 190, 190, 255))
Parallax.Color:Register("silver.soft", Color(220, 220, 220, 255))
Parallax.Color:Register("white", color_white)
Parallax.Color:Register("yellow", Color(255, 255, 0, 255))
Parallax.Color:Register("yellow.soft", Color(255, 255, 100, 255))

-- Framework colors
Parallax.Color:Register("background", color_black)
Parallax.Color:Register("background.transparent", Color(0, 0, 0, 255 / 2))
Parallax.Color:Register("background.notification", Color(50, 50, 50, 200))
Parallax.Color:Register("background.slider", Color(200, 200, 200, 100))
Parallax.Color:Register("chat", Color(230, 230, 110, 255))
Parallax.Color:Register("chat.action", color_white)
Parallax.Color:Register("chat.ooc", Color(200, 25, 0, 255))
Parallax.Color:Register("chat.whisper", Color(70, 110, 230, 255))
Parallax.Color:Register("chat.yell", Color(230, 110, 70, 255))
Parallax.Color:Register("foreground", Color(50, 50, 50, 255))
Parallax.Color:Register("foreground.transparent", Color(50, 50, 50, 255 / 2))
Parallax.Color:Register("options.shadow", Color(0, 0, 0, 150))
Parallax.Color:Register("text", Color(200, 200, 200, 255))
Parallax.Color:Register("text.light", color_white)