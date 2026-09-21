local OxygenSystem = {}

local function clamp(v,min,max)
	return math.max(min,math.min(max,v))
end

local function getBloodOxygenLimit(bloodPercent)

	if bloodPercent >= 0.875 then
		return 1

	elseif bloodPercent >= 0.75 then
		local t = (bloodPercent - 0.75) / 0.125
		return 0.86 + 0.12 * t

	elseif bloodPercent >= 0.625 then
		local t = (bloodPercent - 0.625) / 0.125
		return 0.56 + 0.29 * t

	else
		return 0.41 * (bloodPercent / 0.625)
	end

end

function OxygenSystem.Update(body, dt)

	-- ===== КРОВЬ =====
	local bloodPercent = body.Blood / body.NormalBlood
	bloodPercent = clamp(bloodPercent, 0, 1)

	local bloodLimit = getBloodOxygenLimit(bloodPercent)

	-- ===== ЛЁГКИЕ =====
	local lungFactor = 1
	local hemothorax = body.Hemothorax or 0

	-- Гемоторакс снижает максимальный кислород на 0.66 за пункт выше 10
	local hemothoraxOxygenPenalty = 0
	if hemothorax > 10 then
		hemothoraxOxygenPenalty = (hemothorax - 10) * 0.66
	end

	-- ===== ИСТОЧНИКИ БЛОКИРОВКИ КИСЛОРОДА =====
	-- Проверяем все причины блокировки: OxygenBlocked (другие системы) и SepsisShock (InfectionSystem)
	local isOxygenBlocked = body.OxygenBlocked == true or body.SepsisShock == true

	if isOxygenBlocked then
		lungFactor = 0
	end

	lungFactor = clamp(lungFactor, 0, 1)

	-- ===== ВЯЗКОСТЬ КРОВИ =====
	local viscosityPenalty = body.BloodViscosity or 0

	-- ===== СЕПСИС ПЕНАЛЬТИ =====
	local sepsisOxygenPenalty = body.SepsisOxygenPenalty or 0
	local sepsisOxygenReduction = body.MaxOxygen * (sepsisOxygenPenalty / 100)

	local effectiveMaxOxygen = math.max(body.MaxOxygen - viscosityPenalty - hemothoraxOxygenPenalty - sepsisOxygenReduction, 0)

	-- ===== TARGET =====
	local targetOxygen = effectiveMaxOxygen * bloodLimit * lungFactor

	-- ===== СКОРОСТЬ (ЛИНЕЙНАЯ) =====
	local regenRate = 5
	local drainRate = 1

	if isOxygenBlocked then
		drainRate = 1
	end

	if targetOxygen > body.Oxygen then
		body.Oxygen = math.min(body.Oxygen + regenRate * dt, targetOxygen)
	elseif isOxygenBlocked then
		body.Oxygen = math.max(body.Oxygen - drainRate * dt, targetOxygen)
	elseif targetOxygen < body.Oxygen then
		body.Oxygen = targetOxygen
	end

	body.Oxygen = clamp(body.Oxygen, body.MinOxygen, body.MaxOxygen)

	-- ===== BRAIN DAMAGE =====
	-- Проверяем уже обновлённый Oxygen, чтобы гипоксия начинала
	-- влиять на мозг в тот же тик, когда кислород опустился ниже 5.
	if body.Oxygen < 5 then
		body.Brain -= 1.5 * dt
	end

	body.Brain = math.max(body.Brain, 0)

end

return OxygenSystem
