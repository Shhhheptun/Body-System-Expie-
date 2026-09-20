-- Если что это просто штука для тестов и тут типа может быть почти чо угодно
local DEBUG = true
local function debugLog(...)
	if not DEBUG then return end
	print(...)
end

local Players = game:GetService("Players")
local BodyService = require(game.ServerScriptService.BodySystem.BodyService)
local MoodleService = require(game.ServerScriptService.BodySystem.MoodleService)

debugLog("After require", BodyService)
debugLog("CreateBody exists:", BodyService.CreateBody)

-- ждём пока тело реально появится
local player = Players.PlayerAdded:Wait()

repeat task.wait() until BodyService.Bodies[player]


local body = BodyService.Bodies[player]

print("USING BODY:", body)

task.wait(2)

body.Hunger = 100

body.Thirst = 100

body.Energy = 50

body.OxygenBlocked = false

body.Parts.Head.LimbPain = 0

body.Parts.Chest.LimbPain = 0

body.Temperature = 36.6

body.EnvironmentTemperature = 20

task.wait(3)

body.BloodViscosity = 0

body.Oxygen = 100

body.Brain = 90

body.Consciousness = 30

body.Adrenaline = 0

body.Parts.Chest.Infection = 0

body.Parts.Head.Infection = 0

body.Parts.Head.Skin = 100

body.Parts.Head.Muscle = 9

body.Sepsis = 0

body.Parts.Chest.Disinfected = false

MoodleService:Evaluate(player, body)

local function printMoodle()
	
end

-- ==============================
-- СТАТЫ ТЕЛА (без Min/Max)
-- ==============================
print("=== ГЛОБАЛЬНЫЕ СТАТЫ ===")
print("Brain:", body.Brain)
print("Consciousness:", body.Consciousness)
print("HearingLoss:", body.HearingLoss)
print("Pain:", body.Pain)
print("BasePain:", body.BasePain)
print("Shock:", body.Shock)
print("Blood:", body.Blood)
print("NormalBlood:", body.NormalBlood)
print("BloodViscosity:", body.BloodViscosity)
print("AllBleeds:", body.AllBleeds)
print("HeartRate:", body.HeartRate)
print("Adrenaline:", body.Adrenaline)
print("Oxygen:", body.Oxygen)
print("OxygenBlocked:", body.OxygenBlocked)
print("SepsisShock:", body.SepsisShock)
print("HasAntibiotics:", body.HasAntibiotics)
print("Energized:", body.Energized)
print("NonePainK_Overdose:", body.NonePainK_Overdose)
print("LastStand:", body.LastStand)
print("Disinfected:", body.Disinfected)
print("Caffeination:", body.Caffeination)
print("Hunger:", body.Hunger)
print("Immunity:", body.Immunity)
print("Temperature:", body.Temperature)
print("EnvironmentTemperature:", body.EnvironmentTemperature)
print("EnvironmentPercent:", body.EnvironmentPercent)
print("Sepsis:", body.Sepsis)
print("Infection:", body.Infection)
print("Thirst:", body.Thirst)
print("Wetness:", body.Wetness)
print("Energy:", body.Energy)
print("Stamina:", body.Stamina)
print("Stimulated:", body.Stimulated)
print("PainKillers:", body.PainKillers)
print("Hemothorax:", body.Hemothorax)
print("InternalBleeding:", body.InternalBleeding)

-- ==============================
-- СОСТОЯНИЯ (States)
-- ==============================
print("\n=== СОСТОЯНИЯ ===")
print("Unconscious:", body.States.Unconscious)
print("Dead:", body.States.Dead)
print("Sleep:", body.States.Sleep)
print("Concussed:", body.States.Concussed)

-- ==============================
-- КОНЕЧНОСТИ (Parts)
-- ==============================
print("\n=== КОНЕЧНОСТИ ===")
for partName, partData in pairs(body.Parts) do
	print("\n--- " .. partName .. " ---")
	print("  DisplayName:", partData.DisplayName)
	print("  Skin:", partData.Skin)
	print("  Muscle:", partData.Muscle)
	print("  RegenTimer:", partData.RegenTimer)
	print("  LimbBleed:", partData.LimbBleed)
	print("  LimbPain:", partData.LimbPain)
	print("  Infection:", partData.Infection)
	print("  Fracture:", partData.Fracture)
	print("  Dislocation:", partData.Dislocation)
	print("  Disinfected:", partData.Disinfected)
	print("  Shrapnel:", partData.Shrapnel)
	
	-- Специальные поля для головы
	if partName == "Head" then
		print("  JawRipped:", partData.JawRipped)
		print("  LeftEyeRipped:", partData.LeftEyeRipped)
		print("  RightEyeRipped:", partData.RightEyeRipped)
		print("  SmthinIn:", partData.SmthinIn)
	end
end



debugLog("BodyService =", BodyService)
debugLog("MoodleService =", MoodleService)



debugLog("BodyServise:", BodyService)
debugLog("CreateBody:", BodyService.CreateBody)


