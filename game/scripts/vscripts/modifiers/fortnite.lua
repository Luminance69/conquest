modifier_fortnite = {}

function modifier_fortnite:IsHidden() return false end
function modifier_fortnite:RemoveOnDeath() return true end
function modifier_fortnite:IsPurgable() return false end
function modifier_fortnite:IsDebuff()
    return self.stonks < 0
end

function modifier_fortnite:OnCreated(keys)
    self:SetHasCustomTransmitterData(true)
    self.parent = self:GetParent()

    self.fortnite_time = keys.fortnite_time

    self.interval = 0.25

    self.stonks = 0
    
    self.time_outside = 0

    self:StartIntervalThink(self.interval)
end

function modifier_fortnite:OnIntervalThink()

    local radius = math.max(9000 - (GameRules:GetDOTATime(false, false) - self.fortnite_time) * 6000 / 300, 3000)

    local pos = self.parent:GetAbsOrigin()

    local distance = pos:Length2D()

    self.stonks = math.floor((radius - distance) / 100)
    self:IsDebuff()

    self:SetStackCount(math.abs(self.stonks))

    if distance > radius then
        self.time_outside = self.time_outside + self.interval * 2

        if IsServer() then
            -- 2% max hp per second per 1000 units, + 0.1% per second spent outside 
            local damage = ((distance - radius) * 0.00002 + 0.001 * self.time_outside) * self.parent:GetMaxHealth() * self.interval

            local damage_table = {
                victim = self.parent,
                attacker = self.parent,
                damage = damage,
                damage_type = DAMAGE_TYPE_PURE,
                damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY,
            }

            ApplyDamage(damage_table)
        end
    end
    
    if self.time_outside > 0 then
        self.time_outside = self.time_outside - self.interval
    end
end

function modifier_fortnite:AddCustomTransmitterData( )
	return {
		fortnite_time = self.fortnite_time,
	}
end

function modifier_fortnite:HandleCustomTransmitterData( data )
	self.fortnite_time = data.fortnite_time
end