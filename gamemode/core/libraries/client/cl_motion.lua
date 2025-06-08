--- Advanced panel animation handler using easing for custom fields.
-- Supports delays, per-field animation isolation, and cancelation.
-- @module ax.motion

ax.motion = ax.motion or {}
ax.motion.active = ax.motion.active or {}

--- Starts a property animation on a panel.
-- @tparam Panel panel The target panel.
-- @tparam number duration Duration in seconds.
-- @tparam table data Contains Target, Easing, optional Delay, Think, OnComplete.
function ax.motion:Animate(panel, duration, data)
    if ( !IsValid(panel) or !istable(data) or !istable(data.Target) ) then return end

    local easing = data.Easing or "OutQuad"
    local delay = data.Delay or 0
    local startTime = SysTime()

    for key, targetValue in pairs(data.Target) do
        local current = panel[key] or 0

        for i = #self.active, 1, -1 do
            local anim = self.active[i]
            if ( anim.panel == panel and anim.key == key and anim.current ) then
                current = anim.current
                table.remove(self.active, i)
            end
        end

        table.insert(self.active, {
            panel = panel,
            key = key,
            duration = duration,
            delay = delay,
            start = startTime,
            origin = current,
            target = targetValue,
            current = current,
            easing = easing,
            think = isfunction(data.Think) and data.Think or nil,
            onComplete = isfunction(data.OnComplete) and data.OnComplete or nil
        })
    end
end

--- Cancels a specific animation on a panel.
-- @tparam Panel panel The panel whose animation to cancel.
-- @tparam string key The custom property key to cancel.
function ax.motion:Cancel(panel, key)
    for i = #self.active, 1, -1 do
        local anim = self.active[i]
        if ( anim.panel == panel and anim.key == key ) then
            table.remove(self.active, i)
        end
    end
end

--- Cancels all animations on a panel.
-- @tparam Panel panel The panel to cancel all animations for.
function ax.motion:CancelAll(panel)
    for i = #self.active, 1, -1 do
        if ( self.active[i].panel == panel ) then
            table.remove(self.active, i)
        end
    end
end

--- Think hook to update active animations.
hook.Add("Think", "ax.motion.Update", function()
    local now = SysTime()

    for i = #ax.motion.active, 1, -1 do
        local anim = ax.motion.active[i]

        if ( !IsValid(anim.panel) ) then
            table.remove(ax.motion.active, i)
            continue
        end

        if ( now < anim.start + anim.delay ) then
            continue
        end

        local t = (now - anim.start - anim.delay) / anim.duration
        local done = (t >= 1)

        anim.current = ax.ease:Lerp(anim.easing, t, anim.origin, anim.target)

        if ( anim.think ) then
            anim.think({[anim.key] = anim.current})
        else
            anim.panel[anim.key] = anim.current
        end

        if ( done ) then
            -- Ensure final value is written back
            anim.panel[anim.key] = anim.target

            if ( anim.onComplete ) then
                anim.onComplete(anim.panel)
            end

            table.remove(ax.motion.active, i)
        end
    end
end)

-- Add Animate method to all panels.
do
    local PANEL = FindMetaTable("Panel")

    --- Animate custom properties with easing.
    -- @tparam number duration Duration in seconds.
    -- @tparam table data Table with Target, Easing, Delay, Think, OnComplete.
    function PANEL:Animate(duration, data)
        ax.motion:Animate(self, duration, data)
    end

    --- Cancel a specific animation on this panel.
    -- @tparam string key The property key to cancel.
    function PANEL:CancelAnimation(key)
        ax.motion:Cancel(self, key)
    end

    --- Cancel all animations on this panel.
    function PANEL:CancelAllAnimations()
        ax.motion:CancelAll(self)
    end
end