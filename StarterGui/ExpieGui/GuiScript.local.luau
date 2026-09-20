-- LocalScript внутри BodyGui
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Снос дэфолт инвентаря
local StarterGui = game:GetService("StarterGui")
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local player = Players.LocalPlayer
local container = script.Parent:WaitForChild("BodyGui")

-- Путь к данным (согласно BodyService.txt)
local bodyStateFolder = ReplicatedStorage:WaitForChild("BodySystem"):WaitForChild("BodyState")
local playerFolder = bodyStateFolder:WaitForChild(tostring(player.UserId))
local bodyAttributes = playerFolder:WaitForChild("Body")

-- Константы цветов
local COLOR_BLACK = Color3.fromRGB(0, 0, 0)
local COLOR_RED = Color3.fromRGB(255, 0, 0)
local COLOR_WHITE = Color3.fromRGB(255, 255, 255)

-- Настройки мигания
local BLINK_SPEED = 10 -- Скорость мигания (чем выше, тем быстрее)

-- Список конечностей
local Limbs = {
	"Head", "Chest", "Stomach",
	"LeftShoulder", "LeftForearm", 
	"RightShoulder", "RightForearm",
	"LeftThigh", "LeftShin",
	"RightThigh", "RightShin"
}

-- Таблица для хранения текущих значений для мигания
local muscleStates = {}

local function updateLimbColors(limbName)
	local limbFrame = container:FindFirstChild(limbName)
	if not limbFrame then return end

	local muscleLayer = limbFrame:FindFirstChild("muscleLayer")
	local skinLayer = limbFrame:FindFirstChild("skinLayer")

	-- Получаем данные из атрибутов (имена вида Chest_Muscle)
	local muscleHP = bodyAttributes:GetAttribute(limbName .. "_Muscle") or 100
	local skinHP = bodyAttributes:GetAttribute(limbName .. "_Skin") or 100

	-- 1. Обновление Слоя Кожи (Skin)
	-- Белый (100) -> Красный (0)
	if skinLayer then
		local alpha = math.clamp((100 - skinHP) / 100, 0, 1)
		skinLayer.ImageColor3 = COLOR_WHITE:Lerp(COLOR_RED, alpha)
	end

	-- 2. Обновление Слоя Мышц (Muscle)
	-- Черный (100) -> Красный (10)
	if muscleLayer then
		muscleStates[limbName] = muscleHP -- сохраняем для цикла мигания

		if muscleHP >= 10 then
			-- Линейное изменение от 100 до 10
			local alpha = math.clamp((100 - muscleHP) / 90, 0, 1)
			muscleLayer.ImageColor3 = COLOR_BLACK:Lerp(COLOR_RED, alpha)
		end
	end
end

-- Подписываемся на изменение атрибутов
bodyAttributes.AttributeChanged:Connect(function(attributeName)
	-- Проверяем, какая конечность изменилась (например, "Chest_Skin")
	for _, limb in ipairs(Limbs) do
		if string.find(attributeName, limb) then
			updateLimbColors(limb)
			break
		end
	end
end)

-- Цикл для обработки мигания (когда HP < 10)
RunService.Heartbeat:Connect(function()
	local t = os.clock()
	local blinkAlpha = (math.sin(t * BLINK_SPEED) + 1) / 2

	for _, limbName in ipairs(Limbs) do
		local hp = muscleStates[limbName]
		if hp and hp < 10 then
			local limbFrame = container:FindFirstChild(limbName)
			if limbFrame and limbFrame:FindFirstChild("muscleLayer") then
				-- Мигаем между Черным и Красным
				limbFrame.muscleLayer.ImageColor3 = COLOR_BLACK:Lerp(COLOR_RED, blinkAlpha)
			end
		end
	end
end)

-- Инициализация при запуске
for _, limb in ipairs(Limbs) do
	updateLimbColors(limb)
end

-- === СИСТЕМА ОТКРЫТИЯ/ЗАКРЫТИЯ КУКЛЫ ===
local isOpen = false
local isAnimating = false

-- Сохраняем стандартные значения
local DEFAULT_SIZE = container.Size
local DEFAULT_POSITION = container.Position
local DEFAULT_BG_TRANSPARENCY = container.BackgroundTransparency

-- Запоминаем стандартные прозрачности слоёв
local layerTransparencies = {}
for _, limbName in ipairs(Limbs) do
	local limbFrame = container:FindFirstChild(limbName)
	if limbFrame then
		for _, layer in ipairs(limbFrame:GetChildren()) do
			if layer:IsA("ImageLabel") then
				layerTransparencies[layer] = layer.ImageTransparency
			end
		end
	end
end

-- Запоминаем стандартные прозрачности HotSlots (Frame + UIStroke)
local hotSlotsFolder = container:FindFirstChild("HotSlots")
local slotTransparencies = {}
if hotSlotsFolder then
	for _, slot in ipairs(hotSlotsFolder:GetChildren()) do
		if slot:IsA("Frame") then
			slotTransparencies[slot] = slot.BackgroundTransparency
			local stroke = slot:FindFirstChildOfClass("UIStroke")
			if stroke then
				slotTransparencies[stroke] = stroke.Transparency
			end
		end
	end
end

-- По умолчанию скрыто
container.Size = UDim2.fromScale(0, 0)
container.Position = UDim2.fromScale(0.5, 0.5)
container.BackgroundTransparency = 1
for _, limbName in ipairs(Limbs) do
	local limbFrame = container:FindFirstChild(limbName)
	if limbFrame then
		for _, layer in ipairs(limbFrame:GetChildren()) do
			if layer:IsA("ImageLabel") then
				layer.ImageTransparency = 1
			end
		end
	end
end
-- Скрываем HotSlots при старте
for slot, _ in pairs(slotTransparencies) do
	if slot:IsA("Frame") then
		slot.BackgroundTransparency = 1
	elseif slot:IsA("UIStroke") then
		slot.Transparency = 1
	end
end

-- Анимация открытия
local function openBodyGui()
	if isAnimating or isOpen then return end
	isAnimating = true
	
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	
	-- Анимируем Container
	local containerTween = TweenService:Create(container, tweenInfo, {
		Size = DEFAULT_SIZE,
		Position = DEFAULT_POSITION
	})
	containerTween:Play()
	
	-- Анимируем слои (появление)
	task.wait(0.1) -- небольшая задержка для эффекта
	for _, limbName in ipairs(Limbs) do
		local limbFrame = container:FindFirstChild(limbName)
		if limbFrame then
			for _, layer in ipairs(limbFrame:GetChildren()) do
				if layer:IsA("ImageLabel") then
					local layerTween = TweenService:Create(layer, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						ImageTransparency = layerTransparencies[layer] or 0
					})
					layerTween:Play()
				end
			end
		end
	end
	-- Анимируем HotSlots (появление)
	for slot, defaultTransparency in pairs(slotTransparencies) do
		local tweenInfo2 = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		if slot:IsA("Frame") then
			local slotTween = TweenService:Create(slot, tweenInfo2, {
				BackgroundTransparency = defaultTransparency
			})
			slotTween:Play()
		elseif slot:IsA("UIStroke") then
			local strokeTween = TweenService:Create(slot, tweenInfo2, {
				Transparency = defaultTransparency
			})
			strokeTween:Play()
		end
	end
	
	containerTween.Completed:Wait()
	isOpen = true
	isAnimating = false
end

-- Анимация закрытия
local function closeBodyGui()
	if isAnimating or not isOpen then return end
	isAnimating = true
	
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	
	-- Анимируем слои (исчезновение)
	for _, limbName in ipairs(Limbs) do
		local limbFrame = container:FindFirstChild(limbName)
		if limbFrame then
			for _, layer in ipairs(limbFrame:GetChildren()) do
				if layer:IsA("ImageLabel") then
					local layerTween = TweenService:Create(layer, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						ImageTransparency = 1
					})
					layerTween:Play()
				end
			end
		end
	end
	-- Анимируем HotSlots (исчезновение)
	for slot, _ in pairs(slotTransparencies) do
		local tweenInfo3 = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		if slot:IsA("Frame") then
			local slotTween = TweenService:Create(slot, tweenInfo3, {
				BackgroundTransparency = 1
			})
			slotTween:Play()
		elseif slot:IsA("UIStroke") then
			local strokeTween = TweenService:Create(slot, tweenInfo3, {
				Transparency = 1
			})
			strokeTween:Play()
		end
	end
	
	task.wait(0.15) -- даём слоям начать исчезать
	
	-- Анимируем Container
	local containerTween = TweenService:Create(container, tweenInfo, {
		Size = UDim2.fromScale(0, 0),
		Position = UDim2.fromScale(0.5, 0.5)
	})
	containerTween:Play()
	
	containerTween.Completed:Wait()
	isOpen = false
	isAnimating = false
end

-- Обработка нажатия LeftAlt
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.LeftAlt then
		if isOpen then
			closeBodyGui()
		else
			openBodyGui()
		end
	end
end)