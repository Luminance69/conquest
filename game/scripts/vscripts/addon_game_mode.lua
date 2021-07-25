GameMode = GameMode or class({})

require("lib/timers")
require("lib/util")
require("lib/notifications")
require("import/overthrow")
require("chat_commands")

LinkLuaModifier("modifier_curfew", "modifiers/curfew", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_super_fast", "modifiers/super_fast", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pre_game_stunned", "modifiers/pre_game_stunned", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ancient_degen", "modifiers/ancient_degen", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fortnite", "modifiers/fortnite", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_neutral_camp", "modifiers/neutral_camp", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_neutral_ai", "modifiers/neutral_ai", LUA_MODIFIER_MOTION_NONE)

HERO_SELECTION_TIME = 45
PRE_GAME_TIME = IsInToolsMode() and 5 or 15
FARMING_PHASE_TIME = IsInToolsMode() and 60 or 5 * 60
FIGHTING_PHASE_TIME = IsInToolsMode() and 15 or 20 * 60
CREEP_SPAWN_FREQUENCY = IsInToolsMode() and 5 or 60
MAX_PLAYERS_PER_TEAM = GetMapName() == "6v6v6v6" and 6 or GetMapName() == "3v3v3v3" and 3 or 6
BANS_PER_TEAM = math.ceil(MAX_PLAYERS_PER_TEAM/2)

_G.MAX_CREEPS_PER_NORMAL_CAMP = 12
_G.MAX_CREEPS_PER_ANCIENT_CAMP = 9
_G.NEUTRAL_SPAWNS = LoadKeyValues("scripts/kv/neutral_spawns.kv")
_G.NEUTRAL_ITEM_DROP_CHANCE = {0.6 / MAX_PLAYERS_PER_TEAM, 0.3 / MAX_PLAYERS_PER_TEAM}
_G.NEUTRAL_ITEMS_PER_TIER = MAX_PLAYERS_PER_TEAM
_G.NEUTRAL_ITEM_TIMERS = IsInToolsMode() and {0, 0.2, 0.4, 0.6, 0.8} or {0, 5, 10, 15, 25}
_G.NEUTRAL_ITEMS = LoadKeyValues("scripts/kv/neutral_items.kv")

function Activate()
	GameMode:InitGameMode()
end

function GameMode:InitGameMode()
    Convars:SetFloat("host_timescale", 1)
    ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(GameMode, "OnStateChange"), self)
    ListenToGameEvent("npc_spawned", Dynamic_Wrap(GameMode, "OnNpcSpawned"), self)
    ListenToGameEvent("entity_killed", Dynamic_Wrap(GameMode, "OnNpcKilled"), self)
	
	local game_entity = GameRules:GetGameModeEntity()

	game_entity:SetModifierGainedFilter(Dynamic_Wrap(GameMode, "ModifierGainedFilter"), self)
	game_entity:SetExecuteOrderFilter(Dynamic_Wrap(GameMode, "ExecuteOrderFilter"), self)

    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 0)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 0)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_1, MAX_PLAYERS_PER_TEAM)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_2, MAX_PLAYERS_PER_TEAM)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_3, MAX_PLAYERS_PER_TEAM)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_4, MAX_PLAYERS_PER_TEAM)

    GameRules:SetShowcaseTime(0)
    GameRules:SetHeroSelectionTime(HERO_SELECTION_TIME)
    GameRules:SetStrategyTime(0)
    GameRules:SetPreGameTime(PRE_GAME_TIME)

    GameRules:SetUseUniversalShopMode(true)
    GameRules:SetStartingGold(1500)
    GameRules:SetUseBaseGoldBountyOnHeroes(true)
    GameRules:SetCustomGameBansPerTeam(BANS_PER_TEAM)

	game_entity:SetDraftingBanningTimeOverride(IsInToolsMode() and 0 or 10)

    game_entity:SetBuybackEnabled(false)
    game_entity:SetRespawnTimeScale(0.5)
end

function GameMode:ModifierGainedFilter(data)
	local disable_help_result = DisableHelp.ModifierGainedFilter(data)
	if disable_help_result == false then
		return false
	end
	return true
end

function GameMode:ExecuteOrderFilter(data)
	local order_type = data.order_type
	local player_id = data.issuer_player_id_const
	local target = data.entindex_target ~= 0 and EntIndexToHScript(data.entindex_target) or nil
	local ability = data.entindex_ability ~= 0 and EntIndexToHScript(data.entindex_ability) or nil
	-- `entindex_ability` is item id in some orders without entity
	if ability and not ability.GetAbilityName then ability = nil end
	local unit
	-- TODO: Are there orders without a unit?
	if data.units and data.units["0"] then
		unit = EntIndexToHScript(data.units["0"])
	end
	
	local disable_help_result = DisableHelp.ExecuteOrderFilter(order_type, ability, target, unit)
	if disable_help_result == false then
		return false
	end

    -- This should hopefully prevent players using enemy couriers
    for _,unit in pairs(data.units) do
		unit = EntIndexToHScript(data.units["0"])
        if unit:IsCourier() and unit:GetPlayerOwnerID() ~= player_id then
            return false
        end
    end
	
	return true
end

function GameMode:OnStateChange()
    if IsClient() then return end

    local state = GameRules:State_Get()

    if state == DOTA_GAMERULES_STATE_PRE_GAME then
        self.game_started = false
        self.sudden_death = false
        if not IsInToolsMode() then
            Convars:SetFloat("host_timescale", 0.25)
        end
        Timers:CreateTimer((IsInToolsMode() and 2 or 10), function() self:OnGameStart() end)
    end

    if state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        self:OnStartFarming()
        Timers:CreateTimer(FARMING_PHASE_TIME, function() self:OnStartFighting() end)
        Timers:CreateTimer(FARMING_PHASE_TIME + FIGHTING_PHASE_TIME, function() self:OnStartSuddenDeath(true) end)
    end
end

function GameMode:OnGameStart()
    GameMode:SetupColors()

    self.spawners = self:GetAllNeutralSpawners()

    for _,spawner in pairs(spawners) do
        spawner:AddNewModifier(spawner, nil, "modifier_neutral_camp", nil)
    end

    local players_per_team = 6

    if IsInToolsMode() then
        for i = 0, players_per_team - 2 do
            CreateUnitByName("npc_dota_hero_lina", Vector(0, 7500, 0), true, nil, nil, DOTA_TEAM_CUSTOM_1)
        end
        for i = 0, players_per_team - 1 do
            CreateUnitByName("npc_dota_hero_lina", Vector(7500, 0, 0), true, nil, nil, DOTA_TEAM_CUSTOM_2)
        end
        for i = 0, players_per_team - 1 do
            CreateUnitByName("npc_dota_hero_lina", Vector(0, -7500, 0), true, nil, nil, DOTA_TEAM_CUSTOM_3)
        end
        for i = 0, players_per_team - 1 do
            CreateUnitByName("npc_dota_hero_lina", Vector(-7500, 0, 0), true, nil, nil, DOTA_TEAM_CUSTOM_4)
        end
    end

    self.teams = {
        [DOTA_TEAM_CUSTOM_1] = {["heroes"] = {}, ["neutral_items"] = {[0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {}, }, ["ancient_alive"] = true, ["players_eliminated"] = 0, ["team_eliminated"] = false, ["team_name"] = "Northern Invaders"},
        [DOTA_TEAM_CUSTOM_2] = {["heroes"] = {}, ["neutral_items"] = {[0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {}, }, ["ancient_alive"] = true, ["players_eliminated"] = 0, ["team_eliminated"] = false, ["team_name"] = "Eastern Spirits"},
        [DOTA_TEAM_CUSTOM_3] = {["heroes"] = {}, ["neutral_items"] = {[0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {}, }, ["ancient_alive"] = true, ["players_eliminated"] = 0, ["team_eliminated"] = false, ["team_name"] = "Southern Hunters"},
        [DOTA_TEAM_CUSTOM_4] = {["heroes"] = {}, ["neutral_items"] = {[0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {}, }, ["ancient_alive"] = true, ["players_eliminated"] = 0, ["team_eliminated"] = false, ["team_name"] = "Western Marauders"},
    }

    for _,hero in pairs(HeroList:GetAllHeroes()) do
        if not hero then
            Notifications:BottomToAll({text="HERO DOES NOT EXIST, SEND A SCREENSHOT OF THIS MESSAGE IN #BUG-REPORTS IN DISCORD. #0001", duration=5.0, style={color="red"}}) -- #0001
        else
            table.insert(self.teams[hero:GetTeamNumber()]["heroes"], hero)

            self:InitialiseHero(hero)
        end
    end

    self.alive_teams = 0

    for id,team_data in pairs(self.teams) do
        if #team_data["heroes"] == 0 then
            self:EliminateTeam(id)
        else
            self.alive_teams = self.alive_teams + 1
        end
    end

    Convars:SetFloat("host_timescale", 1)
    self.game_started = true
end

function GameMode:OnStartFarming()
    Notifications:BottomToAll({text="Farming phase has begun! Players cannot enter enemy teams bases.", duration=5.0})

    Timers:CreateTimer(FrameTime(), function()
        self:SpawnCamps()
        
        return CREEP_SPAWN_FREQUENCY
    end)
    -- Just in case
    GameMode:SetupColors()
end

function GameMode:OnStartFighting()
    Notifications:BottomToAll({text="Fighting phase has begun! Players can now enter enemy teams bases.", duration=5.0})
    Notifications:BottomToAll({text="Easy neutral camps will no longer respawn.", duration=5.0})

    local ancients = self:GetAllAncients()

    for _,ancient in pairs(ancients) do
        ancient:RemoveModifierByName("modifier_invulnerable")
        ancient:AddNewModifier(ancient, nil, "modifier_ancient_degen", {fightingPhaseTime = FIGHTING_PHASE_TIME})
    end
end

function GameMode:OnStartSuddenDeath(force)

    local ancients = self:GetAllAncients()

    if (#ancients ~= 0 and not force) or self.sudden_death then return end

    self.sudden_death = true

    self.fortnite_time = GameRules:GetDOTATime(false, false)

    local heroes = HeroList:GetAllHeroes()

    for _,hero in pairs(heroes) do
        hero:AddNewModifier(hero, nil, "modifier_fortnite", {fortnite_time = self.fortnite_time})
    end

    for _,ancient in pairs(ancients) do
        ancient:ForceKill(true)
    end

    Timers:CreateTimer(
        2,
        function()
            Notifications:BottomToAll({text="Sudden death has begun! All ancients have been destroyed!", duration=5.0})
            Notifications:BottomToAll({text="Hard neutral camps will no longer respawn.", duration=10.0})
            Notifications:BottomToAll({text="Players will take damage if they stray too far from the centre of the map.", duration=15.0})
        end
    )
end

function GameMode:OnNpcSpawned(event)
    local unit = EntIndexToHScript(event.entindex)

    if unit:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS and unit:IsCreature() and unit:GetPlayerOwner() ~= nil then
        unit:AddNewModifier(unit, nil, "modifier_curfew", {farmingPhaseTime = FARMING_PHASE_TIME})
        unit:AddNewModifier(unit, nil, "modifier_super_fast", {})

        if not self.game_started then
            unit:AddNewModifier(unit, nil, "modifier_pre_game_stunned", {})
        end
        
        if self.sudden_death and self.fortnite_time then
            unit:AddNewModifier(unit, nil, "modifier_fortnite", {fortnite_time = self.fortnite_time})
        end
    end

end

function GameMode:OnNpcKilled(event)
    local unit = EntIndexToHScript(event.entindex_killed)

    if not unit then return end

    team = unit:GetTeamNumber()

    if unit:IsBuilding() then
        self:OnAncientDestroyed(team)
    end

    if team == DOTA_TEAM_NEUTRALS then
        local killer = EntIndexToHScript(event.entindex_attacker)

        if Util:IsMainHero(killer) then
            self:GiveNeutralItem(unit, killer)
        end

        local killer_team = killer:GetTeamNumber()

        killer_allies = FindUnitsInRadius(killer_team, unit:GetAbsOrigin(), nil, 1600, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

        real_allies = {}

        local ally_count = 0

        for _,ally in pairs(killer_allies) do
            if Util:IsMainHero(ally) and killer:GetPlayerOwner() and ally:GetPlayerOwner() and killer:GetPlayerOwner() ~= ally:GetPlayerOwner() and ally:IsAlive() then
                ally_count = ally_count + 1
                table.insert(real_allies, ally)
            end
        end

        local gold = math.floor(unit:GetGoldBounty() * 0.75 / ally_count)

        if ally_count > 0 then
            for _,ally in pairs(real_allies) do
                local player_id = ally:GetPlayerOwnerID()

                if player_id and player_id ~= -1 then
                    PlayerResource:ModifyGold(player_id, gold, true, DOTA_ModifyGold_CreepKill)
                    
                    local player = PlayerResource:GetPlayer(player_id)
                    if player then
                        SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, ally, gold, player)
                    end
                end
            end
        else
            gold = math.floor(unit:GetGoldBounty() * 0.2)

            local player_id = killer:GetPlayerOwnerID()

            if player_id and player_id ~= -1 then
                PlayerResource:ModifyGold(player_id, gold, true, DOTA_ModifyGold_CreepKill)

                local player = PlayerResource:GetPlayer(player_id)
                if player then
                    SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, player:GetAssignedHero(), gold, player)
                end
            end
        end
    end

    if Util:IsMainHero(unit) then
        if self.teams[team]["ancient_alive"] == false then
            self.teams[team]["players_eliminated"] = self.teams[team]["players_eliminated"] + 1

            if self.teams[team]["players_eliminated"] == #self.teams[team]["heroes"] then
                self:EliminateTeam(team)
            end
        end
    end
end

function GameMode:OnAncientDestroyed(team)
    local heroes = HeroList:GetAllHeroes()

    for _,hero in pairs(heroes) do
        if hero:GetTeamNumber() == team then
            hero:SetRespawnsDisabled(true)
        end
    end

    local units = FindUnitsInRadius(team, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)

    for _,unit in pairs(units) do
        if unit:GetUnitName() == "npc_dota_downfall_fountain" then
            local modifier = unit:FindModifierByName("modifier_fountain_regen_and_stuff")
            modifier.ancient_dead = true
        end
    end

    self.teams[team]["ancient_alive"] = false

    Notifications:BottomToAll({text=self.teams[team]["team_name"].."\'s Ancient has been destroyed!\nPlayers from this team will no longer respawn", duration=5.0})

    self:OnStartSuddenDeath(false)
end

function GameMode:EliminateTeam(team)
    self.teams[team]["team_eliminated"] = true

    self.alive_teams = self.alive_teams - 1

    Notifications:BottomToAll({text=self.teams[team]["team_name"].." has been eliminated!", duration=5.0})

    --[[

    -- TODO: add a custom chat so players who are eliminated cant all chat

    local FOWVectors = {
        Vector(0, 0, 4096),

        Vector(-4096, 0, 4096),
        Vector(0, -4096, 4096),
        Vector(0, 4096, 4096),
        Vector(4096, 0, 4096),

        Vector(-4096, -4096, 4096),
        Vector(-4096, 4096, 4096),
        Vector(4096, -4096, 4096),
        Vector(4096, 4096, 4096),

        Vector(-8192, 0, 4096),
        Vector(0, -8192, 4096),
        Vector(0, 8192, 4096),
        Vector(8192, 0, 4096),

        Vector(-8192, -8192, 4096),
        Vector(8192, -8192, 4096),
        Vector(-8192, 8192, 4096),
        Vector(8192, 8192, 4096),

        Vector(-8192, -4096, 4096),
        Vector(8192, -4096, 4096),
        Vector(-8192, 4096, 4096),
        Vector(8192, 4096, 4096),

        Vector(-4096, -8192, 4096),
        Vector(4096, -8192, 4096),
        Vector(-4096, 8192, 4096),
        Vector(4096, 8192, 4096),
    }
    
    for _,vector in pairs(FOWVectors) do
        AddFOWViewer(team, vector, 999999999, 69420, false)
    end

    ]]

    -- Win detection
    if self.alive_teams == 1 then
        for id,team_data in pairs(self.teams) do
            if team_data["team_eliminated"] == false then
                Notifications:TopToAll({text=self.teams[id]["team_name"].." Victory!", duration=5.0, style={color="green", ["font-size"]="108px"}})
                if not IsInToolsMode() then
                    Timers:CreateTimer(10, function() GameRules:SetGameWinner(id) end)
                end
            end
        end
    end
end

function GameMode:SpawnCamps()
    local kill_easy_camps = GameRules:GetDOTATime(false, false) > FARMING_PHASE_TIME + 1
    local kill_hard_camps = GameRules:GetDOTATime(false, false) > FARMING_PHASE_TIME + FIGHTING_PHASE_TIME + 1

    local spawners = {}

    for _,spawner in pairs(self.spawners) do
        local modifier = spawner:FindModifierByName("modifier_neutral_camp")

        local neutrals = {}
        for _,neutral in pairs(modifier.neutrals) do
            if neutral and not neutral:IsNull() and neutral:IsAlive() then
                table.insert(neutrals, neutral)
            end
        end

        if (modifier.camp_type == "easy" and kill_easy_camps) or (modifier.camp_type == "hard" and kill_hard_camps) then
            if #neutrals == 0 then
                UTIL_Remove(spawner)
            else
                table.insert(spawners, spawner)
            end
        else
            local neutral_camp_spawning = modifier.neutral_spawns[tostring(RandomInt(0, Util:GetKVLength(modifier.neutral_spawns)-1))]

            local neutral_camp_spawn_count = Util:GetKVLength(neutral_camp_spawning)

            local neutral_camp_spawn_limit = modifier.camp_type == "ancient" and _G.MAX_CREEPS_PER_ANCIENT_CAMP or _G.MAX_CREEPS_PER_NORMAL_CAMP

            if #neutrals <= (neutral_camp_spawn_limit - neutral_camp_spawn_count) then -- If spawning this camp would bring total creep count over the limit then bail
                for i = 0, neutral_camp_spawn_count do
                    local neutral = CreateUnitByName(neutral_camp_spawning[tostring(i)], modifier.origin, true, nil, nil, DOTA_TEAM_NEUTRALS)
                    table.insert(neutrals, neutral)
                end
            end
            modifier.neutrals = neutrals

            table.insert(spawners, spawner)
        end
    end

    self.spawners = spawners
end

function GameMode:GetAllAncients()
    return FindUnitsInRadius(DOTA_TEAM_NEUTRALS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
end

function GameMode:GetAllNeutralSpawners()
    units = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)

    spawners = {}

    for _,unit in pairs(units) do
        if string.find(unit:GetUnitName(), "npc_dota_downfall_neutral_camp") then
            table.insert(spawners, unit)
        end
    end

    return spawners
end

function GameMode:SetupColors()
    self.team_colors = {}
	self.team_colors[DOTA_TEAM_CUSTOM_1] = { 197, 77, 168 }  --    Pink
	self.team_colors[DOTA_TEAM_CUSTOM_2] = { 255, 108, 0 }   --    Orange
	self.team_colors[DOTA_TEAM_CUSTOM_3] = { 52, 85, 255 }   --    Blue
	self.team_colors[DOTA_TEAM_CUSTOM_4] = { 101, 212, 19 }  --    Green

    self.player_colors = {
        {70,70,255},
		{0,255,255},
		{255,0,255},
		{255,255,0},
		{255,165,0},
		{0,255,0},
		{255,0,0},
		{75,0,130},
		{109,49,19},
		{255,20,147},
		{128,128,0},
		{255,255,255},
        {255,135,195},
		{160,180,70},
		{100,220,250},
		{0,128,0},
		{165,105,0},
		{153,50,204},
		{0,128,128},
		{0,0,165},
		{128,0,0},
		{180,255,180},
		{255,127,80},
		{0,0,0},
    }

    for team, color in pairs(self.team_colors) do
		SetTeamCustomHealthbarColor(team, color[1], color[2], color[3])
	end

    for player_id = 0, PlayerResource:GetPlayerCount() - 1 do
        local color = self.player_colors[player_id+1]
        PlayerResource:SetCustomPlayerColor(player_id, color[1], color[2], color[3])
    end
end

function GameMode:GiveNeutralItem(unit, killer)
    local team = killer:GetTeamNumber()

    local game_time = GameRules:GetDOTATime(false, false)
    local neutral_found = false

    local chance = unit:IsAncient() and _G.NEUTRAL_ITEM_DROP_CHANCE[1] or _G.NEUTRAL_ITEM_DROP_CHANCE[2]

    for tier,time in pairs(_G.NEUTRAL_ITEM_TIMERS) do
        if game_time > time * 60 and RandomFloat(0,1) < chance then
            tier = tier - 1

            local count = 0

            for _,item in pairs(self.teams[team]["neutral_items"][tier]) do
                count = count + 1
            end

            if count < _G.NEUTRAL_ITEMS_PER_TIER then
                while not neutral_found do
                    local random_neutral_item = _G.NEUTRAL_ITEMS[tostring(tier)][tostring(RandomInt(0, Util:GetKVLength(_G.NEUTRAL_ITEMS[tostring(tier)]) - 1))]

                    if not self.teams[team]["neutral_items"][tier][random_neutral_item] then
                        self.teams[team]["neutral_items"][tier][random_neutral_item] = true

                        DropNeutralItemAtPositionForHero(random_neutral_item, unit:GetAbsOrigin(), killer, tier + 1, true)

                        neutral_found = true
                    end
                end
            end
        end
    end
end

function GameMode:InitialiseHero(hero)
    local player = hero:GetPlayerOwner()

    if player then
        local courier = player:SpawnCourierAtPosition(hero:GetAbsOrigin())

        courier:AddNewModifier(courier, nil, "modifier_super_fast", {})

        for i=2,5 do
            hero:HeroLevelUp(false)
        end

        hero:RemoveModifierByName("modifier_pre_game_stunned")
    else
        Timers:CreateTimer({1,
            callback = function()
                self:InitialiseHero(hero)
            end
        })
    end
end

RegisterCustomEventListener("top_menu:get_ancient_entity", function(data)
	local player_id = data.PlayerID
	if not player_id then return end
	
	local ancients = GameMode:GetAllAncients()
	local entities = {}
	for _,x in pairs(ancients) do
		entities[x:GetTeam()] = x:GetEntityIndex()
	end
	if entities then
		CustomGameEventManager:Send_ServerToAllClients("top_menu:update_ancient_entity", entities)
	end
end)
