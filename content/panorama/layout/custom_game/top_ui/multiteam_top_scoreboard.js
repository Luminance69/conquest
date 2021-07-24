"use strict";

var g_ScoreboardHandle = null;

function UpdateScoreboard() {
	if (Game.GetMapInfo().map_display_name == "battleground") {
		$("#MultiteamScoreboard").style.visibility = "collapse";
	} else {
		ScoreboardUpdater_SetScoreboardActive(g_ScoreboardHandle, true);

		$.Schedule(0.2, UpdateScoreboard);
	}
}

function CheckTeamMargin() {
	const root = $("#MultiteamScoreboard");
	root.Children().forEach((p, i) => {
		p.style.marginLeft = "10px";
		if (!p.visible) {
			const prev_p = root.GetChild(i - 1);
			if (prev_p) {
				prev_p.style.marginLeft = "100px";
			}
		}
		if (i == 2) p.style.marginLeft = "100px";
	});
	$.Schedule(5, CheckTeamMargin);
}

(function () {
	var shouldSort = false;

	if (GameUI.CustomUIConfig().multiteam_top_scoreboard) {
		var cfg = GameUI.CustomUIConfig().multiteam_top_scoreboard;
		if (cfg.LeftInjectXMLFile) {
			$("#LeftInjectXMLFile").BLoadLayout(cfg.LeftInjectXMLFile, false, false);
		}
		if (cfg.RightInjectXMLFile) {
			$("#RightInjectXMLFile").BLoadLayout(cfg.RightInjectXMLFile, false, false);
		}

		if (typeof cfg.shouldSort !== "undefined") {
			shouldSort = cfg.shouldSort;
		}
	}

	if (ScoreboardUpdater_InitializeScoreboard === null) {
		$.Msg("WARNING: This file requires shared_scoreboard_updater.js to be included.");
	}

	var scoreboardConfig = {
		teamXmlName: "file://{resources}/layout/custom_game/top_ui/multiteam_top_scoreboard_team.xml",
		playerXmlName: "file://{resources}/layout/custom_game/top_ui/multiteam_top_scoreboard_player.xml",
		shouldSort: shouldSort,
	};
	g_ScoreboardHandle = ScoreboardUpdater_InitializeScoreboard(scoreboardConfig, $("#MultiteamScoreboard"));

	UpdateScoreboard();
	$.Schedule(1, CheckTeamMargin);
})();
