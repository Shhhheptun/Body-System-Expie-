-- SleepSystem
-- ServerScriptService/BodySystem/Systems/SleepSystem

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StorageBodySystem = ReplicatedStorage:WaitForChild("BodySystem")
local SleepRemote = StorageBodySystem:WaitForChild("SleepRemote")
local Config = require(StorageBodySystem:WaitForChild("Expie_Config"))

local SleepSystem = {}

print("[SleepSystem] Серверная система загружена и готова.")

-- Качества сна и их параметры
local SLEEP_QUALITY = Config.SleepQuality or {
	Bad      = { effectMultiplier = 0.70, wakeThreshold = 70 },
	Mediocre = { effectMultiplier = 0.85, wakeThreshold = 85 },
	Okay     = { effectMultiplier = 1.0,  wakeThreshold = 100 },
	Good     = { effectMultiplier = 1.25, wakeThreshold = 100, caffeinationBonus = 25 },
}

-- Базовая скорость восстановления энергии во сне (модифицируется effectMultiplier качества)
local SLEEP_BASE_ENERGY_REGEN = 0.4

local function clamp(v, min, max)
	return math.max(min, math.min(max, v))
end

-- Проверка, находится ли голова персонажа в воде
local function isHeadInWater(character)
	local head = character:FindFirstChild("Head")
	if not head then return false end
	local pos = head.Position
	local halfSize = Vector3.new(2, 2, 2)
	local region = Region3.new(pos - halfSize, pos + halfSize)
	region = region:ExpandToGrid(4)
	local ok, materials = pcall(function()
		return workspace.Terrain:ReadVoxels(region, 4)
	end)
	if not ok or not materials then return false end
	for x = 1, #materials do
		for y = 1, #materials[x] do
			for z = 1, #materials[x][y] do
				if materials[x][y][z] == Enum.Material.Water then
					return true
				end
			end
		end
	end
	return false
end

-- Получение порога энергии для пробуждения на основе активных условий
-- Возвращает минимальный порог среди всех активных условий
local function getWakeUpThreshold(body)
	local thresholds = {}

	-- === КРИТИЧЕСКИЕ УСЛОВИЯ ===
	-- Температура < 30°C -> пробуждение при 0 энергии
	if body.Temperature < 30 then table.insert(thresholds, 0) end
	-- Общая боль > 31 -> пробуждение при 1 энергии
	if body.Pain > 31 then table.insert(thresholds, 1) end
	-- Голова в воде -> пробуждение при 4 энергии
	if body._HeadInWater then table.insert(thresholds, 4) end

	-- === НЕКРИТИЧЕСКИЕ УСЛОВИЯ ===
	-- Голод < 35 -> 50
	if body.Hunger < 35 then table.insert(thresholds, 50) end
	-- Жажда < 35 -> 50
	if body.Thirst < 35 then table.insert(thresholds, 50) end
	-- Сепсис > 35 -> 50
	if body.Sepsis > 35 then table.insert(thresholds, 50) end
	-- Температура < 32°C -> 50
	if body.Temperature < 32 then table.insert(thresholds, 50) end
	-- Температура > 39.5°C -> 50
	if body.Temperature > 39.5 then table.insert(thresholds, 50) end

	-- === ПОРОГ ОТ КАЧЕСТВА СНА ===
	local quality = body._SleepQuality or "Okay"
	local qualityConfig = SLEEP_QUALITY[quality]
	if qualityConfig then
		table.insert(thresholds, qualityConfig.wakeThreshold)
	end

	-- Минимальный порог = самое срочное условие
	local minThreshold = 100
	for _, t in ipairs(thresholds) do
		if t < minThreshold then minThreshold = t end
	end
	return minThreshold
end

-- Безопасное физическое укладывание персонажа
local function setCharacterLying(character, lieDown)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end

	if lieDown then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		humanoid.PlatformStand = true
		-- АБСОЛЮТНЫЙ поворот (не относительно текущего CFrame), чтобы не накручивать при повторных вызовах
		local pos = rootPart.CFrame.Position
		rootPart.CFrame = CFrame.new(pos) * CFrame.Angles(math.rad(-90), 0, 0)
	else
		humanoid.PlatformStand = false
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		-- АБСОЛЮТНЫЙ поворот обратно на ноги
		local pos = rootPart.CFrame.Position
		rootPart.CFrame = CFrame.new(pos)
	end
end

-- Функция засыпания (Изолирована от Heartbeat через task.spawn)
function SleepSystem.FallAsleep(body, isForced)
	-- Проверка, чтобы не запускать процесс повторно, пока он уже идет
	if body.States.Sleep or body.States.TransitioningSleep then return end

	local player = body.Player
	if not player or not player.Character then return end

	body.States.TransitioningSleep = true -- Временный флаг блокировки повторных вызовов
	print(string.format("[SleepSystem.FallAsleep] %s засыпает. Принудительно: %s", player.Name, tostring(isForced)))

	-- Блокируем управление на сервере
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.WalkSpeed = 0 humanoid.JumpPower = 0 end

	-- Отправляем клиенту сигнал плавно гасить экран (Транзишн 4 секунды)
	SleepRemote:FireClient(player, "StartSleepTransition", isForced)

	-- Выносим ожидание в отдельный поток, чтобы НЕ блокировать основной Heartbeat игры!
	task.spawn(function()
		task.wait(4)

		-- Проверяем, не ливнул ли игрок за 4 секунды
		if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then 
			body.States.TransitioningSleep = false
			return 
		end

		body.States.Sleep = true
		body.States.ForcedSleep = isForced
		body.Consciousness = 0
		-- Качество сна по умолчанию "Okay".
		-- БУДУЩАЯ СИСТЕМА ПОВЕРХНОСТЕЙ: должна установить body._SleepQuality
		-- ("Bad", "Mediocre", "Okay", "Good") ДО вызова FallAsleep
		-- или перезаписать его здесь.
		body._SleepQuality = body._SleepQuality or "Okay"
		body._CaffeinationApplied = false
		body.NeedsMoodUpdate = true
		body.States.TransitioningSleep = false -- Снимаем блок транзишена

		setCharacterLying(player.Character, true)

		-- Даем команду клиенту перейти в финальную фазу сна (полная темнота)
		SleepRemote:FireClient(player, "GoToSleep", isForced)
		print(string.format("[SleepSystem] %s уснул полностью.", player.Name))
	end)
end

-- Функция пробуждения
function SleepSystem.WakeUp(body, isPanic)
	if not body.States.Sleep or body.States.TransitioningWake then return end

	local player = body.Player
	if not player or not player.Character then return end

	body.States.TransitioningWake = true -- Блокировка повторного вызова пробуждения
	print(string.format("[SleepSystem.WakeUp] %s начинает просыпаться. Паника: %s", player.Name, tostring(isPanic)))

	setCharacterLying(player.Character, false)

	-- Клиент начинает плавно убирать черный экран (2 секунды)
	SleepRemote:FireClient(player, "StartWakeUpTransition", isPanic)

	task.spawn(function()
		task.wait(2)

		if not player or not player.Character then 
			body.States.TransitioningWake = false
			return 
		end

		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.WalkSpeed = 16 humanoid.JumpPower = 50 end

		-- Бонус кафеинации при хорошем качестве сна (5 минут)
		if body._SleepQuality == "Good" and not body._CaffeinationApplied then
			local qualityConfig = SLEEP_QUALITY.Good
			body.Caffeination = math.clamp(
				(body.Caffeination or 0) + qualityConfig.caffeinationBonus,
				Config.Global.MIN_CAFFEINATION,
				Config.Global.MAX_CAFFEINATION
			)
			body._CaffeinationApplied = true
			print(string.format("[SleepSystem] %s получил бонус кафеинации за хороший сон (+%d)", player.Name, qualityConfig.caffeinationBonus))
		end

		body.States.Sleep = false
		body.States.ForcedSleep = false
		body.Consciousness = 100
		body.NeedsMoodUpdate = true
		body.States.TransitioningWake = false -- Снимаем блок

		-- Полная свобода действий
		SleepRemote:FireClient(player, "FullyAwake")
		print(string.format("[SleepSystem] %s окончательно проснулся.", player.Name))
	end)
end

function SleepSystem.Update(body, dt)
	if body.Energy == nil then body.Energy = 100 end
	if body.States.Sleep == nil then body.States.Sleep = false end
	if body.States.ForcedSleep == nil then body.States.ForcedSleep = false end
	if body.States.TransitioningSleep == nil then body.States.TransitioningSleep = false end

	-- Логика сна
	if body.States.Sleep then
		-- Уже просыпается — пропускаем
		if body.States.TransitioningWake then return end

		-- Качество сна определяется системой поверхностей (внешне).
		-- Здесь только используем установленное значение.
		local qualityConfig = SLEEP_QUALITY[body._SleepQuality]
		body._SleepEffectMultiplier = qualityConfig and qualityConfig.effectMultiplier or 1.0

		-- Реген энергии: базовая скорость × модификатор качества
		local regenRate = SLEEP_BASE_ENERGY_REGEN * (qualityConfig and qualityConfig.effectMultiplier or 1.0)
		body.Energy = clamp(body.Energy + regenRate * dt, 0, 100)
		body.Consciousness = 0

		-- Проверка головы в воде (раз в 0.5 сек для производительности)
		local character = body.Player and body.Player.Character
		body._WaterCheckTimer = (body._WaterCheckTimer or 0) + dt
		if body._WaterCheckTimer >= 0.5 then
			body._WaterCheckTimer = 0
			body._HeadInWater = character and isHeadInWater(character) or false
		end

		-- Проверка условий пробуждения
		local wakeThreshold = getWakeUpThreshold(body)

		if body.Energy >= wakeThreshold then
			print(string.format("[SleepSystem] %s просыпается: энергия %.1f >= порога %d (качество: %s)",
				body.Player.Name, body.Energy, wakeThreshold, body._SleepQuality or "Unknown"))
			SleepSystem.WakeUp(body, false)
		end
		return
	end

	-- АВТО-ВЫРУБОН при 0 энергии
	if body.Energy <= 0 and not body.States.Sleep and not body.States.TransitioningSleep then
		print(string.format("[SleepSystem] Энергия %s на нуле! Вырубает...", body.Player.Name))
		SleepSystem.FallAsleep(body, true)
	end
end

return SleepSystem