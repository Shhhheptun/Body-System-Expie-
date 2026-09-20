-- BloodDebugConsole - GUI консоль для отладки кровеносной системы
-- StarterGui.BloodDebugConsole

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Подключение к Remote
local remote = ReplicatedStorage:WaitForChild("BodySystem"):WaitForChild("BloodDebugRemote")

-- Список конечностей
local limbNames = {
	"Head", "Chest", "Stomach",
	"LeftThigh", "RightThigh", "LeftShin", "RightShin",
	"LeftShoulder", "RightShoulder", "LeftForearm", "RightForearm"
}

-- Свойства конечностей
local limbProperties = {
	["Skin"] = function(limb, value)
		remote:FireServer("SetSkin", {Limb = limb, Value = value})
		return string.format("Skin %s = %.1f%%", limb, value)
	end,
	["LimbBleed"] = function(limb, value)
		remote:FireServer("SetLimbBleed", {Limb = limb, Value = value})
		return string.format("LimbBleed %s = %.1f", limb, value)
	end,
	["Shrapnel"] = function(limb, value)
		local boolValue = value > 0
		remote:FireServer("SetShrapnel", {Limb = limb, Value = boolValue})
		return string.format("Shrapnel %s = %s", limb, boolValue and "ON" or "OFF")
	end,
}

-- Глобальные свойства
local globalProperties = {
	["InternalBleed"] = function(value)
		remote:FireServer("SetInternalBleeding", {Value = value})
		return string.format("InternalBleed = %.1f", value)
	end,
	["Hemothorax"] = function(value)
		remote:FireServer("SetHemothorax", {Value = value})
		return string.format("Hemothorax = %.1f", value)
	end,
}

-- Пресеты
local presets = {
	["critical"] = function()
		remote:FireServer("PresetCritical", {})
		return "Пресет КРИТ применён"
	end,
	["light"] = function()
		remote:FireServer("PresetLight", {})
		return "Пресет ЛЁГКИЙ применён"
	end,
	["reset"] = function()
		remote:FireServer("PresetReset", {})
		return "Пресет СБРОС применён"
	end,
}

-- ===== СОЗДАНИЕ GUI =====

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BloodConsoleGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Главная рамка
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 400, 0, 200)
mainFrame.Position = UDim2.new(0.5, -200, 1, -220)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 100, 100)
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

-- Заголовок
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleBar

local titleBottom = Instance.new("Frame")
titleBottom.Size = UDim2.new(1, 0, 0, 10)
titleBottom.Position = UDim2.new(0, 0, 1, -10)
titleBottom.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
titleBottom.BorderSizePixel = 0
titleBottom.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🩸 Blood Console (F8)"
title.TextColor3 = Color3.fromRGB(255, 120, 120)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Кнопка закрытия
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -28, 0.5, -12)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeBtn
closeBtn.Parent = titleBar

-- Поле ввода
local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(1, -20, 0, 32)
inputBox.Position = UDim2.new(0, 10, 0, 40)
inputBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
inputBox.Text = ""
inputBox.PlaceholderText = "Введите команду... (например: RightForearm.Skin = 75)"
inputBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
inputBox.TextSize = 14
inputBox.Font = Enum.Font.Code
inputBox.ClearTextOnFocus = false
local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 6)
inputCorner.Parent = inputBox
local inputStroke = Instance.new("UIStroke")
inputStroke.Color = Color3.fromRGB(80, 80, 100)
inputStroke.Thickness = 1
inputStroke.Parent = inputBox
inputBox.Parent = mainFrame

-- Кнопка выполнения
local execBtn = Instance.new("TextButton")
execBtn.Size = UDim2.new(0, 100, 0, 28)
execBtn.Position = UDim2.new(0, 10, 0, 80)
execBtn.BackgroundColor3 = Color3.fromRGB(80, 150, 80)
execBtn.Text = "Выполнить"
execBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
execBtn.TextSize = 12
execBtn.Font = Enum.Font.GothamBold
local execCorner = Instance.new("UICorner")
execCorner.CornerRadius = UDim.new(0, 6)
execCorner.Parent = execBtn
execBtn.Parent = mainFrame

-- Кнопка справки
local helpBtn = Instance.new("TextButton")
helpBtn.Size = UDim2.new(0, 80, 0, 28)
helpBtn.Position = UDim2.new(0, 120, 0, 80)
helpBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
helpBtn.Text = "Справка"
helpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
helpBtn.TextSize = 12
helpBtn.Font = Enum.Font.Gotham
local helpCorner = Instance.new("UICorner")
helpCorner.CornerRadius = UDim.new(0, 6)
helpCorner.Parent = helpBtn
helpBtn.Parent = mainFrame

-- Кнопка очистки
local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0, 80, 0, 28)
clearBtn.Position = UDim2.new(0, 210, 0, 80)
clearBtn.BackgroundColor3 = Color3.fromRGB(150, 80, 80)
clearBtn.Text = "Очистить"
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearBtn.TextSize = 12
clearBtn.Font = Enum.Font.Gotham
clearBtn.Parent = mainFrame
local clearCorner = Instance.new("UICorner")
clearCorner.CornerRadius = UDim.new(0, 6)
clearCorner.Parent = clearBtn

-- Поле вывода (лог)
local outputBox = Instance.new("TextBox")
outputBox.Size = UDim2.new(1, -20, 0, 70)
outputBox.Position = UDim2.new(0, 10, 1, -80)
outputBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
outputBox.Text = ""
outputBox.TextColor3 = Color3.fromRGB(150, 255, 150)
outputBox.TextSize = 11
outputBox.Font = Enum.Font.Code
outputBox.TextXAlignment = Enum.TextXAlignment.Left
outputBox.TextYAlignment = Enum.TextYAlignment.Top
outputBox.MultiLine = true
outputBox.TextWrapped = true
outputBox.ClearTextOnFocus = false
outputBox.TextEditable = false
local outputCorner = Instance.new("UICorner")
outputCorner.CornerRadius = UDim.new(0, 6)
outputCorner.Parent = outputBox
outputBox.Parent = mainFrame

-- ===== ФУНКЦИИ =====

local function addOutput(text)
	local timestamp = os.date("%H:%M:%S")
	local newLine = string.format("[%s] %s", timestamp, text)
	outputBox.Text = outputBox.Text .. newLine .. "\n"
	-- Автоскролл вниз
end

local function clearOutput()
	outputBox.Text = ""
end

local function showHelp()
	addOutput("=== СПРАВКА ===")
	addOutput("Формат: Конечность.Свойство = Значение")
	addOutput("Конечности: Head, Chest, Stomach,")
	addOutput("  Left/Right Thigh/Shin/Shoulder/Forearm")
	addOutput("Свойства: Skin, LimbBleed, Shrapnel")
	addOutput("Глобальные: InternalBleed, Hemothorax")
	addOutput("Пресеты: preset critical/light/reset")
	addOutput("Пример: RightForearm.Skin = 75")
end

-- Парсинг команды
local function parseCommand(message)
	message = message:match("^%s*(.-)%s*$")
	if message == "" then return nil end
	
	-- Проверяем пресет
	local presetName = message:match("^preset%s+(%a+)")
	if presetName and presets[presetName:lower()] then
		return presets[presetName:lower()]()
	end
	
	-- Проверяем глобальное свойство
	local globalProp, globalValue = message:match("^(%a+)%s*=%s*(.+)")
	if globalProp and globalValue then
		globalProp = globalProp
		if globalProperties[globalProp] then
			local numValue = tonumber(globalValue)
			if numValue then
				return globalProperties[globalProp](numValue)
			end
		end
	end
	
	-- Проверяем свойство конечности
	local limb, prop, value = message:match("^(%a+)%.(%a+)%s*=%s*(.+)")
	if limb and prop and value then
		local validLimb = nil
		for _, name in ipairs(limbNames) do
			if name:lower() == limb:lower() then
				validLimb = name
				break
			end
		end
		
		if validLimb and limbProperties[prop] then
			local numValue = tonumber(value)
			if numValue then
				return limbProperties[prop](validLimb, numValue)
			end
		end
	end
	
	return "Неизвестная команда. Нажмите 'Справка'"
end

-- ===== СОБЫТИЯ =====

execBtn.MouseButton1Click:Connect(function()
	local cmd = inputBox.Text
	if cmd ~= "" then
		local result = parseCommand(cmd)
		if result then
			addOutput(result)
		end
	end
end)

helpBtn.MouseButton1Click:Connect(showHelp)

clearBtn.MouseButton1Click:Connect(clearOutput)

closeBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end)

-- Enter для выполнения
inputBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		local cmd = inputBox.Text
		if cmd ~= "" then
			local result = parseCommand(cmd)
			if result then
				addOutput(result)
			end
		end
	end
end)

-- F8 для открытия/закрытия
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.F8 then
		mainFrame.Visible = not mainFrame.Visible
		if mainFrame.Visible then
			inputBox:CaptureFocus()
		end
	end
end)

print("[BloodConsole] Загружен. Нажмите F8 для открытия консоли.")