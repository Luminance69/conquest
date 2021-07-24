modifier_curfew = {}

function modifier_curfew:RemoveOnDeath() return true end
function modifier_curfew:IsDebuff() return true end

function modifier_curfew:OnCreated(keys)
    if IsClient() then return end

    self.parent = self:GetParent()
    self.oldPos = self.parent:GetAbsOrigin()
    self.baseHeight = 128

    self.farmingPhaseTime = keys.farmingPhaseTime
    self.soundProc = "General.InvalidTarget_Invulnerable"
    self.team = self.parent:GetTeamNumber()

    self:StartIntervalThink(0.1)
end

function modifier_curfew:OnIntervalThink()
    if not self.parent or not self.team then
        self:Destroy()
        return
    end

    if GameRules:GetDOTATime(false, false) >= self.farmingPhaseTime or self.team == DOTA_TEAM_NEUTRALS then
        self:Destroy()
        return
    end

    local newPos = self.parent:GetAbsOrigin()

    if self:IsTrespassing(newPos) then
        FindClearSpaceForUnit(self.parent, self.oldPos, true)

        if self.parent:GetPlayerID() and self.parent:GetPlayerID() ~= -1 then
            EmitAnnouncerSoundForPlayer(self.soundProc, self.parent:GetPlayerID())
        end
    else
        self.oldPos = newPos
    end
end

function modifier_curfew:IsTrespassing(position)
    local groundHeight = GetGroundHeight(position, self.parent)

    if groundHeight <= self.baseHeight then return false end

    if self.team ~= DOTA_TEAM_CUSTOM_1 and position.y > 3900  then return true end
    if self.team ~= DOTA_TEAM_CUSTOM_2 and position.x > 3900  then return true end
    if self.team ~= DOTA_TEAM_CUSTOM_3 and position.y < -3900 then return true end
    if self.team ~= DOTA_TEAM_CUSTOM_4 and position.x < -3900 then return true end

    return false
end