modifier_super_fast = {}

function modifier_super_fast:RemoveOnDeath() return not (self.parent.IsCourier and self.parent:IsCourier()) end
function modifier_super_fast:IsHidden() return true end

function modifier_super_fast:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end

function modifier_super_fast:GetModifierMoveSpeedBonus_Percentage( params )
    return self.parent and not self.parent:IsNull() and self.parent:IsCourier() and 50 or 10
end

function modifier_super_fast:OnCreated()
    self.parent = self:GetParent()

    if not self.parent.GetPlayerID then return end
    
    if not self.parent:GetPlayerID() then return end

    self.player_id = self.parent:GetPlayerID()

    self:StartIntervalThink(1)
end

function modifier_super_fast:OnIntervalThink()
    if not self.player_id then return end
    
    local networth = PlayerResource:GetNetWorth(self.player_id)

    local streak = math.max(self.parent:GetStreak() - 2, 0) 

    self.parent:SetMaximumGoldBounty(200 + networth * 0.006 + streak * 100)
    self.parent:SetMinimumGoldBounty(200 + networth * 0.007 + streak * 100)
end