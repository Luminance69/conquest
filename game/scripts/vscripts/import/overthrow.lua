require("import/utils")
require("import/disable_help")

_G.tPlayersMuted = {}
for player_id = 0, 24 do
	_G.tPlayersMuted[player_id] = {}
end

RegisterCustomEventListener("set_mute_player", function(data)
	if data and data.PlayerID and data.toPlayerId then
		local fromId = data.PlayerID
		local toId = data.toPlayerId
		local disable = data.disable

		_G.tPlayersMuted[fromId][toId] = disable == 1
	end
end)
