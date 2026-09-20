-- DebugMoodleLogger
-- ServerScriptService/BodySystem/DebugMoodleLogger
local DEBUG = false
local function debugLog(...)
	if not DEBUG then return end
	print(...)
end

local DEBUG2 = true
local function debugLog2(...)
	if not DEBUG2 then return end
	print(...)
end

local MoodleService = require(
	game.ServerScriptService.BodySystem.MoodleService
)

local function dumpActiveMoodles(body)
	debugLog2("BODY IS:", body) -- НЕ ТРОГАТЬ
	debugLog2("╔══════════ ACTIVE MOODLES ══════════╗")

	if not body or not body.ActiveMoodles or next(body.ActiveMoodles) == nil then
		debugLog2("║ (none)")
	else
		for category, data in pairs(body.ActiveMoodles) do
			debugLog2(
				"║",
				category,
				"|", data.displayName,
				"|", data.description
			)
		end
	end

	debugLog2("╚══════════════════════════════════╝")
end

-- Moodle added
MoodleService.MoodleAdded.Event:Connect(function(body, moodId)
	dumpActiveMoodles(body)
	debugLog(">>> ACTIVE MOODLES UPDATE (ADDED)")
end)

-- Moodle removed
MoodleService.MoodleRemoved.Event:Connect(function(body, moodId)
	dumpActiveMoodles(body)
	debugLog(">>> ACTIVE MOODLES UPDATE (REMOVED)")
end)

-- Moodles evaluated
MoodleService.MoodlesEvaluated.Event:Connect(function(body, moodId)
	dumpActiveMoodles(body)
	debugLog(">>> ACTIVE MOODLES UPDATE (EVALUATED)")
end)