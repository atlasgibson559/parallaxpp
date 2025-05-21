function SWEP:TranslateAnimation(anim)
    local vm = self:GetOwner():GetViewModel()
    if ( IsValid(vm) ) then
        local seq = vm:LookupSequence(anim)
        if ( seq > 0 ) then
            return seq
        end
    end

    return -1
end

function SWEP:PlayAnimation(anim, rate)
    local vm = self:GetOwner():GetViewModel()
    if ( IsValid(vm) ) then
        local seq = self:TranslateAnimation(anim)
        if ( seq > 0 ) then
            vm:SendViewModelMatchingSequence(seq)
            vm:SetPlaybackRate(rate or 1)
        end
    end
end

function SWEP:GetActiveAnimation()
    local vm = self:GetOwner():GetViewModel()
    if ( IsValid(vm) ) then
        return vm:GetSequenceName(vm:GetSequence())
    end

    return ""
end

function SWEP:GetActiveAnimationDuration()
    local vm = self:GetOwner():GetViewModel()
    if ( IsValid(vm) ) then
        return vm:SequenceDuration(vm:GetSequence())
    end

    return 0
end