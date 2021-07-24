modifier_ancient_degen = {}

function modifier_ancient_degen:OnCreated(keys)
    if IsClient() then return end

    self.parent = self:GetParent()

    self.sound_proc = "announcer_announcer_anc_attack_yr"
    self.next_time = 0

    local fightingPhaseTime = keys.fightingPhaseTime

    self.degen = math.floor(self.parent:GetMaxHealth() / fightingPhaseTime)

    self:StartIntervalThink(1)
end

function modifier_ancient_degen:OnIntervalThink()
    self.health = self.parent:GetHealth()

    if self.health <= self.degen then
        self.parent:SetHealth(1)
    else
        self.parent:SetHealth(self.health - self.degen)
    end
end

function modifier_ancient_degen:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE,
    }
end

function modifier_ancient_degen:OnTakeDamage(keys)
    if keys.unit ~= self.parent then return end
    local time = GameRules:GetDOTATime(false, false)

    if self.next_time < time and self.parent:IsAlive() then
        EmitAnnouncerSoundForTeam(self.sound_proc, self.parent:GetTeam())
        self.next_time = time + 15
    end
end

function modifier_ancient_degen:CheckState()
    return {
        [MODIFIER_STATE_SPECIALLY_UNDENIABLE] = true,
    }
end