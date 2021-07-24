ChatCommands = ChatCommands or class({})

function ChatCommands:Init()
	ListenToGameEvent(
        "player_chat",
        function(event)
		    ChatCommands:OnPlayerChat(event)
	    end,
        nil
    )
end

function ChatCommands:OnPlayerChat(event)
	if not event.userid then return end

	event.player = PlayerInstanceFromIndex( event.userid )
	if not event.player then return end

	event.hero = event.player:GetAssignedHero()
	if not event.hero then return end

	event.player_id = event.hero:GetPlayerID()

    if not (tostring(PlayerResource:GetSteamID(event.player_id)) == "76561198188258659" or IsInToolsMode() or IsCheatMode()) then return end

	local command_source = string.lower(event.text)

	if string.sub(command_source, 0, 1) ~= "-" then return end
	-- removing `-`
	command_source = string.sub(command_source, 2, -1)

	local arguments = {}
    
    for token in string.gmatch(command_source, "[^%s]+") do
        table.insert(arguments, token)
    end

	local command_name = table.remove(arguments, 1)

    -- -spawn <hero> <team | ally> <level>

    if command_name == "spawn" then
        local spawn_hero = arguments[1] and "npc_dota_hero_"..arguments[1] or "npc_dota_hero_lina"
        local team = (arguments[2] and arguments[2] == "ally" and event.hero:GetTeamNumber()) or (arguments[2] and arguments[2] == "enemy" and (event.hero:GetTeamNumber() == 6 and 7) or 6) or (arguments[2] and arguments[2] + 5) or (event.hero:GetTeamNumber() == 6 and 7) or 6
        local level = arguments[3] and tonumber(arguments[3]) or 1
        
        unit = CreateUnitByName(spawn_hero, event.hero:GetAbsOrigin(), true, nil, nil, team)

        for i=2, level do
            unit:HeroLevelUp(false)
        end
    end

    if command_name == "test" then
        units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_1, Vector(0, 0, 0), nil, -1, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

        for _,unit in pairs(units) do
            print(unit:GetUnitName(), unit:FindAllModifiers())
        end
    end

    if command_name == "timescale" and arguments[1] then
        local var = tonumber(arguments[1])

        if var < 0.1 then var = 0.1 end

        Convars:SetFloat("host_timescale", var)
    end

    if command_name == "globalvision" and arguments[1] then
        local team = tonumber(arguments[1]+5)

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
    end
end

ChatCommands:Init()