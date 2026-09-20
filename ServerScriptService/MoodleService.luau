-- MoodleService
-- Server/BodySystem/MoodleService
-- Логика вычисления мудов

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

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MoodleDefs = require(ReplicatedStorage.BodySystem.MoodleDefs)

local SortedCategories = {} -- отсортированный список категорий по приоритету

for name, category in pairs(MoodleDefs) do
	table.insert(SortedCategories, {
		name = name,
		data = category,
		priority = category.priority or 0
	})
end

table.sort(SortedCategories, function(a, b)
	return a.priority > b.priority
end)

local MoodleService = {}

MoodleService.MoodlesEvaluated = Instance.new("BindableEvent")
MoodleService.MoodleAdded = Instance.new("BindableEvent")
MoodleService.MoodleRemoved = Instance.new("BindableEvent")

function MoodleService:Evaluate(player, body)
body.Moodles = body.Moodles or {}
body.ActiveMoodles = body.ActiveMoodles or {}

	debugLog("[EVAL START] body: ", body, "Hunger = ", body.Hunger, "Thirst = ", body.Thirst, "Pain = ", body.Pain)

	for _, entry in ipairs(SortedCategories) do
		local categoryName = entry.name
		local category = entry.data
		
	local previousMoodleId = body.Moodles[categoryName]
	local newState = nil

	-- ищем активное состояние категории
		for _, state in ipairs(category.states) do
			local ok = false
			-- вызываем condition один раз и запоминаем результат
			local success, res = pcall(function() return state.condition(body) end)
			if not success then
				debugLog("[EVAL][ERROR] state.condition threw:", categoryName, state.id, res)
			else
				ok = res and true or false
			end

			debugLog("[EVAL CHECK]", categoryName, "state:", state.id, "->", ok, " (thirst=", body.Thirst, " hunger=", body.Hunger, ")")

			if ok then
				newState = state
				break
			end
		end

	local newMoodleId = newState and newState.id or nil
	
		debugLog("[EVAL RESULT]", categoryName, "previous:", previousMoodleId, "new:", newMoodleId)

	-- ЕСЛИ НИЧЕГО НЕ ИЗМЕНИЛОСЬ — ПРОПУСКАЕМ
	if previousMoodleId == newMoodleId then
		continue
	end
	
		debugLog("[EVAL REMOVE CHECK]", categoryName, "previousMoodleId:", previousMoodleId)

	-- УБИРАЕМ СТАРЫЙ МУД
	if previousMoodleId then
		body.ActiveMoodles[previousMoodleId] = nil

		MoodleService.MoodleRemoved:Fire(body, previousMoodleId)

		debugLog("[MOODLE REMOVED]", categoryName, previousMoodleId)
	end

		debugLog("[EVAL ADD CHECK]", categoryName, "newState:", newState and newState.id or "<nil>")

	-- ДОБАВЛЯЕМ НОВЫЙ
	if newState then
		body.Moodles[categoryName] = newMoodleId
		body.ActiveMoodles[newMoodleId] = {
			category = categoryName,
			displayName = newState.displayName,
			description = newState.description,
		}

		MoodleService.MoodleAdded:Fire(body, newMoodleId, body.ActiveMoodles[newMoodleId])

		debugLog("[MOODLE ADDED]", categoryName, newMoodleId)
	else
		body.Moodles[categoryName] = nil
		
	end
		debugLog2("=== SORTED CATEGORIES ===")
		for i, entry in ipairs(SortedCategories) do
			debugLog2(i, entry.name)
		end
		debugLog2("=========================")
  end
	MoodleService.MoodlesEvaluated:Fire(body) 
end
      
return MoodleService