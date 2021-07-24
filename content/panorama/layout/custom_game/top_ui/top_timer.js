var darknessEndTime = -Number.MAX_VALUE;
function secondsToMS(seconds, bTwoChars) {
	var sec_num = parseInt(seconds, 10);
	var minutes = Math.floor(sec_num / 60);
	var seconds = Math.floor(sec_num - minutes * 60);

	if (bTwoChars && minutes < 10) minutes = "0" + minutes;
	if (seconds < 10) seconds = "0" + seconds;
	return minutes + ":" + seconds;
}
function Update() {
	$.Schedule(0.1, Update);
	var rawTime = Game.GetDOTATime(false, true);
	var time = Math.abs(rawTime);
	var isNSNight = rawTime < darknessEndTime;
	var timeThisDayLasts = time - Math.floor(time / 600) * 600;
	var isDayTime = !isNSNight && timeThisDayLasts <= 300;
	var context = $.GetContextPanel();

	context.SetHasClass("DayTime", isDayTime);
	context.SetHasClass("NightTime", !isDayTime);
	context.SetDialogVariable("time_of_day", secondsToMS(time, true));
	context.SetDialogVariable("time_until", secondsToMS((isDayTime ? 300 : 600) - timeThisDayLasts, true));
	context.SetDialogVariable("day_phase", $.Localize(isDayTime ? "DOTA_HUD_Night" : "DOTA_HUD_Day"));

	$("#DayTime").visible = isDayTime;
	$("#NightTime").visible = !isNSNight && !isDayTime;
	$("#NightstalkerNight").visible = isNSNight;

	context.SetHasClass("AltPressed", GameUI.IsAltDown());
}

function TimerClick() {
	if (GameUI.IsAltDown()) {
		GameEvents.SendCustomGameEventToServer("OnTimerClick", {});
	}
}

(function () {
	GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_TIMEOFDAY, false);
	GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_HEROES, false);
	GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_BAR_BACKGROUND, false);
	FindDotaHudElement("topbar").visible = true;
	GameEvents.Subscribe("time_nightstalker_darkness", function (data) {
		darknessEndTime = Game.GetDOTATime(false, false) + data.duration;
	});
	Update();
})();
