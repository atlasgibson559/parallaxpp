DEFINE_BASECLASS("EditablePanel")

local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)

    local scoreboard = self:Add("ax.scoreboard")
    scoreboard:Dock(FILL)
end

vgui.Register("ax.tab.scoreboard", PANEL, "EditablePanel")