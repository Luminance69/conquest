modifier_neutral_camp = {}

function modifier_neutral_camp:CheckState()
    return {
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_OUT_OF_GAME] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = false,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = false,
    }
end

function modifier_neutral_camp:GetCampType()
    local name = self.spawner:GetUnitName()

    if string.find(name, "easy") then
        return "easy"
    elseif string.find(name, "hard") then
        return "hard"
    else
        return "ancient"
    end
end

function modifier_neutral_camp:OnCreated()
    if IsClient() then return end

    self:CheckState()

    self.spawner = self:GetParent()
    self.origin = self.spawner:GetAbsOrigin()

    self.camp_type = self:GetCampType()
    self.neutral_spawns = _G.NEUTRAL_SPAWNS[self.camp_type] -- KV of all neutral camps found in scripts/kv/neutral_spawns.kv

    self.neutrals = {}
end

function modifier_neutral_camp:DeclareFunctions()
    return {MODIFIER_PROPERTY_PROVIDES_FOW_POSITION}
end

function modifier_neutral_camp:GetModifierProvidesFOWVision()
    return 1
end