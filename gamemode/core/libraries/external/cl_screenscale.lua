--- Cached Screen Scale
-- Caches the results of ScreenScale && ScreenScaleH to improve performance.
-- @Winkarst

local scrW, scrH = ScrW() / 640, ScrH() / 480

function ScreenScale(width)
    return width * scrW
end

function ScreenScaleH(height)
    return height * scrH
end

hook.Add("OnScreenSizeChanged", "CachedScreenScale", function(oldWidth, oldHeight, newWidth, newHeight)
    scrW, scrH = newWidth / 640, newHeight / 480
end)