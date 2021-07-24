fountain_regen_and_stuff = {}

function fountain_regen_and_stuff:Spawn()
    if IsServer() then
        self:SetLevel(1)
    end
end

function fountain_regen_and_stuff:GetIntrinsicModifierName()
    return "modifier_fountain_regen_and_stuff"
end

modifier_fountain_regen_and_stuff = {}

LinkLuaModifier("modifier_fountain_regen_and_stuff", "abilities/fountain_regen_and_stuff", LUA_MODIFIER_MOTION_NONE)

function modifier_fountain_regen_and_stuff:CheckState()
    return {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_DISARMED] = self.ancient_dead,
    }
end

function modifier_fountain_regen_and_stuff:OnCreated()
	if IsClient() then return end
    self.ability = self:GetAbility()

    self.radius = self.ability:GetSpecialValueFor("radius")

    self.ancient_dead = false
end

function modifier_fountain_regen_and_stuff:IsAura()
    return true
end

function modifier_fountain_regen_and_stuff:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_fountain_regen_and_stuff:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_fountain_regen_and_stuff:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_INVULNERABLE end
function modifier_fountain_regen_and_stuff:GetModifierAura() return "modifier_fountain_healing_aura" end
function modifier_fountain_regen_and_stuff:GetAuraRadius() return self.radius end

modifier_fountain_healing_aura = {}

LinkLuaModifier("modifier_fountain_healing_aura", "abilities/fountain_regen_and_stuff", LUA_MODIFIER_MOTION_NONE)

function modifier_fountain_healing_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
        MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE,
    }
end

function modifier_fountain_healing_aura:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()

    if not self.ability then return end

    self.is_courier = self.parent:IsCourier()

    self.hp_regen_pct = self.ability:GetSpecialValueFor("hp_regen_pct") * (self.is_courier and 0.2 or 1)
    self.mana_regen_pct = self.ability:GetSpecialValueFor("mana_regen_pct") * (self.is_courier and 0.2 or 1)

    -- Only refill bottle on main hero
    -- Dude i dont even want to know why Util is sometimes nil
    if Util and Util:IsMainHero(self.parent) then
        self:StartIntervalThink(0.25)
    end
end

function modifier_fountain_healing_aura:GetModifierHealthRegenPercentage()
    return self.hp_regen_pct
end

function modifier_fountain_healing_aura:GetModifierTotalPercentageManaRegen()
    return self.mana_regen_pct
end

function modifier_fountain_healing_aura:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = self.is_courier,
    }
end

-- Refill bottle
function modifier_fountain_healing_aura:OnIntervalThink()
    for i=0,5 do
        item = self.parent:GetItemInSlot(i)

        if item and item:GetAbilityName() == "item_bottle" then
            item:SetCurrentCharges(3)
        end
    end
end