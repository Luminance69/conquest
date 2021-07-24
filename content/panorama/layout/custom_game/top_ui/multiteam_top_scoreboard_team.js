var ancient_hp_hood = $("#AncientState");
var ancient_ent;
var hood_team_id = $.GetContextPanel().GetAttributeInt("team_id", -1);

function UpdateAncientHP() {
	const hp_pct = Entities.GetHealthPercent(ancient_ent) / 100;
	ancient_hp_hood.value = hp_pct;
	if (hp_pct >= 0) $.Schedule(0, UpdateAncientHP);
	else ancient_hp_hood.GetParent().AddClass("BAncientDestoyed");
}

function UpdateAncientEnt(data) {
	if (data[hood_team_id] == undefined) return;
	ancient_ent = data[hood_team_id];
	UpdateAncientHP();
}

(function () {
	var cfg = GameUI.CustomUIConfig().multiteam_top_scoreboard;
	if (cfg) {
		if (cfg.TeamOverlayXMLFile) {
			$("#TeamOverlayXMLFile").SetAttributeInt("team_id", hood_team_id);

			$("#TeamOverlayXMLFile").BLoadLayout(cfg.TeamOverlayXMLFile, false, false);
		}
	}
	if (GameUI.CustomUIConfig().team_colors) {
		var teamColor = GameUI.CustomUIConfig().team_colors[hood_team_id];
		if (teamColor) {
			$("#AncientState_Left").style.backgroundColor = teamColor;
		}
	}
	GameEvents.Subscribe("top_menu:update_ancient_entity", UpdateAncientEnt);
	GameEvents.SendCustomGameEventToServer("top_menu:get_ancient_entity", {});
})();
