downfall_true_sight = {}

function downfall_true_sight:Spawn()
    if IsServer() then
        self:SetLevel(1)
    end
end

function downfall_true_sight:GetIntrinsicModifierName()
    return "modifier_downfall_true_sight"
end

modifier_downfall_true_sight = {}

LinkLuaModifier("modifier_downfall_true_sight", "abilities/downfall_true_sight", LUA_MODIFIER_MOTION_NONE)


function modifier_downfall_true_sight:IsAura()
    return true
end

function modifier_downfall_true_sight:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_downfall_true_sight:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_downfall_true_sight:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_INVULNERABLE end
function modifier_downfall_true_sight:GetModifierAura() return "modifier_downfall_true_sight_aura" end
function modifier_downfall_true_sight:GetAuraRadius() return 900 end

modifier_downfall_true_sight_aura = {}

LinkLuaModifier("modifier_downfall_true_sight_aura", "abilities/downfall_true_sight", LUA_MODIFIER_MOTION_NONE)

function modifier_downfall_true_sight_aura:IsHidden() return true end
function modifier_downfall_true_sight_aura:IsDebuff() return true end
function modifier_downfall_true_sight_aura:IsPurgable() return false end
function modifier_downfall_true_sight_aura:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end

function modifier_downfall_true_sight_aura:CheckState()
	return {
		[MODIFIER_STATE_INVISIBLE] = false
	}
end 

function modifier_downfall_true_sight_aura:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
	}
end

function modifier_downfall_true_sight_aura:GetModifierInvisibilityLevel()
	return 0
end