-- SleepClient (ЛокалСкрипт в ExpieGui)
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

if not game:IsLoaded() then game.Loaded:Wait() end

local LocalPlayer = Players.LocalPlayer
local StorageBodySystem = ReplicatedStorage:WaitForChild("BodySystem")
local SleepRemote = StorageBodySystem:WaitForChild("SleepRemote")

local PlayerModule = nil
local Controls = nil
pcall(function()
	PlayerModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
	Controls = PlayerModule:GetControls()
end)

local isSleeping = false
local isTransitioning = false 
local lastPressTime = 0
local nextPressCooldown = 0.1 
local wakeUpProgress = 0
local lastPressTimestamp = 0

local panicPhrases = {
	"wake up...", "wake up", "Wake up!", 
	"WAKE UP!!!", " W A K E   U P ",
	" Y O U   A R E   N O T   I N   S A F E ",
	" G E T   O U T   F R O M   H E R E ",
	" N O W "
}

local screenGui = script.Parent
local realSleepButton = screenGui:FindFirstChild("Sleep", true)
local progressBarFrame = screenGui:FindFirstChild("ProgressBar", true)
local panicTextLabel = screenGui:FindFirstChild("PanicText", true)

local function toggleInputLock(lock)
	if Controls then
		if lock then Controls:Disable() else Controls:Enable() end
	else
		local character = LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = lock and 0 or 16
			humanoid.JumpPower = lock and 0 or 50
		end
	end
end

-- Обработка интерфейса паники в цикле
RunService.Heartbeat:Connect(function(dt)
	if not isSleeping or isTransitioning then 
		if progressBarFrame then progressBarFrame.Visible = false end
		if panicTextLabel then panicTextLabel.Visible = false end
		return 
	end

	if wakeUpProgress > 0 then
		if progressBarFrame then
			progressBarFrame.Visible = true
			progressBarFrame.Size = UDim2.new(wakeUpProgress / 100, 0, progressBarFrame.Size.Y.Scale, progressBarFrame.Size.Y.Offset)
		end
		if panicTextLabel then panicTextLabel.Visible = true end
	else
		if progressBarFrame then progressBarFrame.Visible = false end
		if panicTextLabel then panicTextLabel.Visible = false end
	end

	if os.clock() - lastPressTimestamp > 1.0 and wakeUpProgress > 0 then
		wakeUpProgress = math.max(0, wakeUpProgress - 40 * dt)
	end
end)

if realSleepButton and realSleepButton:IsA("GuiButton") then
	realSleepButton.MouseButton1Click:Connect(function()
		if not isSleeping and not isTransitioning then
			print("[SleepClient] Запрос на обычный сон отправлен...")
			SleepRemote:FireServer("RequestSleep")
		end
	end)
end

-- Получение точных стейтов от сервера
SleepRemote.OnClientEvent:Connect(function(action, data)
	if action == "StartSleepTransition" then
		isTransitioning = true
		toggleInputLock(true)
		print("[SleepClient] Экран начинает темнеть (Анимация 4 сек)...")
		-- ТУТ ТВOЙ Tween ТЕМНОТЫ НА 4 СЕКУНДЫ

	elseif action == "GoToSleep" then
		isSleeping = true
		isTransitioning = false
		wakeUpProgress = 0
		toggleInputLock(true)
		print("[SleepClient] Полная темнота. Персонаж уснул.")
		-- ТУТ ТВOЙ КОД ПОЛНОГО БЛЭКАУТА

	elseif action == "StartWakeUpTransition" then
		isSleeping = false
		isTransitioning = true
		wakeUpProgress = 0
		print("[SleepClient] Экран светлеет (Пробуждение 2 сек)...")
		-- ТУТ ТВOЙ Tween СВЕТА НА 2 СЕКУНДЫ

	elseif action == "FullyAwake" then
		isTransitioning = false
		toggleInputLock(false)
		print("[SleepClient] Свобода движений возвращена.")

	elseif action == "SleepDenied" then
		isTransitioning = false
		toggleInputLock(false)
		print("[SleepClient] Сон отклонён сервером.")
	end
end)

-- Спам кнопок
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not isSleeping or isTransitioning or gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.Keyboard then
		local now = os.clock()
		if now - lastPressTime >= nextPressCooldown then
			lastPressTime = now
			lastPressTimestamp = now

			nextPressCooldown = math.random(10, 30) / 100 -- Сделал КД чуть быстрее (0.1 - 0.3 сек)
			local addedProgress = math.random(6, 12)
			wakeUpProgress = math.min(100, wakeUpProgress + addedProgress)

			if panicTextLabel then
				local phraseIndex = math.clamp(math.floor(wakeUpProgress / 12) + 1, 1, #panicPhrases)
				panicTextLabel.Text = panicPhrases[phraseIndex]
			end

			print(string.format("[SleepClient] Клик засчитан! Прогресс: %.1f%%", wakeUpProgress))

			if wakeUpProgress >= 100 then
				print("[SleepClient] Шкала заполнена! Отправка RequestWakeUp...")
				SleepRemote:FireServer("RequestWakeUp")
			end
		end
	end
end)