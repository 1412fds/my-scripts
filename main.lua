-- سكربت متعدد القوائم مع كشف الماب التلقائي، قود مود، ESP، وقسم 99 ليلة
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

-- معرفات مابات كمثال (استبدل/أضف PlaceId المابات التي تريدها)
local MAP_IDS = {
	NIGHTS_99 = 79546208627805, -- مثال: ضع PlaceId الصحيح لماب 99 ليلة إذا اختلف
}

-- إعدادات الحالة العامة
local Config = {
	WalkSpeed = 16,
	JumpPower = 50,
	LockStats = false,
	GodMode = false,
	EspEnabled = false,
	SelectedMap = "Auto", -- "Auto", "99 Nights", "Universal"
}

local Connections = {}
local EspFolder = Instance.new("Folder")
EspFolder.Name = "ScriptEspObjects"
EspFolder.Parent = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui")

-- تنظيف الاتصالات السابقة عند إعادة التشغيل
local function clearConnections()
	for _, conn in ipairs(Connections) do
		if typeof(conn) == "RBXScriptConnection" then
			conn:Disconnect()
		end
	end
	table.clear(Connections)
end

-- تطبيق خصائص الحركة على الشخصية
local function applyMovement(char)
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	humanoid.WalkSpeed = Config.WalkSpeed
	if humanoid.UseJumpPower then
		humanoid.JumpPower = Config.JumpPower
	else
		humanoid.JumpHeight = math.max(1, Config.JumpPower * 0.145)
	end
end

-- منطق القود مود (محاولة حماية الصحة من جهة العميل)
local godConnection
local function setGodMode(enabled)
	Config.GodMode = enabled
	if godConnection then
		godConnection:Disconnect()
		godConnection = nil
	end

	local function hookHumanoid(hum)
		if not hum or not Config.GodMode then return end
		hum.MaxHealth = math.huge
		hum.Health = hum.MaxHealth

		godConnection = hum.HealthChanged:Connect(function(newHp)
			if Config.GodMode and newHp < hum.MaxHealth then
				hum.Health = hum.MaxHealth
			end
		end)
	end

	if enabled and LocalPlayer.Character then
		hookHumanoid(LocalPlayer.Character:FindFirstChildOfClass("Humanoid"))
	end
end

-- نظام ESP بسيط ونظيف للاعبين
local function clearEsp()
	for _, item in ipairs(EspFolder:GetChildren()) do
		item:Destroy()
	end
end

local function createPlayerEsp(player)
	if player == LocalPlayer or not Config.EspEnabled then return end
	local char = player.Character
	if not char or not char.Parent then return end

	if EspFolder:FindFirstChild(player.Name) then
		EspFolder[player.Name]:Destroy()
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = player.Name
	highlight.Adornee = char
	highlight.FillColor = Color3.fromRGB(239, 68, 68)
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.55
	highlight.OutlineTransparency = 0
	highlight.Parent = EspFolder
end

local function refreshEsp()
	clearEsp()
	if not Config.EspEnabled then return end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			createPlayerEsp(plr)
		end
	end
end

-- مراقبة ظهور الشخصيات واللاعبين
table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(0.25)
	if Config.LockStats then
		applyMovement(char)
	end
	if Config.GodMode then
		setGodMode(true)
	end
end))

table.insert(Connections, Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function()
		task.wait(0.3)
		if Config.EspEnabled then
			createPlayerEsp(plr)
		end
	end)
end))

table.insert(Connections, Players.PlayerRemoving:Connect(function(plr)
	local existing = EspFolder:FindFirstChild(plr.Name)
	if existing then
		existing:Destroy()
	end
end))

-- أدوات مخصصة لماب 99 ليلة (أمثلة قابلة للتوسيع)
local function boostNightVisibility(enable)
	if enable then
		Lighting.Ambient = Color3.fromRGB(160, 160, 175)
		Lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 175)
		Lighting.Brightness = 2.2
	else
		Lighting.Ambient = Color3.fromRGB(70, 70, 70)
		Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
		Lighting.Brightness = 1
	end
end

-- تحديد الماب الحالي تلقائياً أو حسب الاختيار
local function detectCurrentMap()
	if Config.SelectedMap ~= "Auto" then
		return Config.SelectedMap
	end
	if game.PlaceId == MAP_IDS.NIGHTS_99 then
		return "99 Nights"
	end
	return "Universal"
end

-- بناء واجهة مبسطة بتبويبات (عام / ESP / قود مود / 99 ليلة / المابات)
local function buildHub()
	local parentGui = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui")
	local old = parentGui:FindFirstChild("MultiMapHubGui")
	if old then old:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "MultiMapHubGui"
	gui.ResetOnSpawn = false
	gui.Parent = parentGui

	local main = Instance.new("Frame")
	main.Size = UDim2.new(0, 360, 0, 260)
	main.Position = UDim2.new(0.5, -180, 0.5, -130)
	main.BackgroundColor3 = Color3.fromRGB(20, 22, 29)
	main.BorderSizePixel = 0
	main.Active = true
	main.Draggable = true
	main.Parent = gui
	Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, -16, 0, 32)
	header.Position = UDim2.new(0, 10, 0, 4)
	header.BackgroundTransparency = 1
	header.Text = "Hub متعدد القوائم | الماب الحالي: " .. detectCurrentMap()
	header.TextColor3 = Color3.fromRGB(240, 244, 248)
	header.TextSize = 13
	header.Font = Enum.Font.GothamBold
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Parent = main

	local tabBar = Instance.new("Frame")
	tabBar.Size = UDim2.new(1, -16, 0, 28)
	tabBar.Position = UDim2.new(0, 8, 0, 38)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent = main

	local contentArea = Instance.new("Frame")
	contentArea.Size = UDim2.new(1, -16, 1, -76)
	contentArea.Position = UDim2.new(0, 8, 0, 70)
	contentArea.BackgroundColor3 = Color3.fromRGB(28, 31, 40)
	contentArea.BorderSizePixel = 0
	contentArea.Parent = main
	Instance.new("UICorner", contentArea).CornerRadius = UDim.new(0, 8)

	local tabs = { "عام", "حماية/ESP", "99 ليلة", "المابات" }
	local pages = {}

	for i, tabName in ipairs(tabs) do
		local page = Instance.new("ScrollingFrame")
		page.Name = tabName
		page.Size = UDim2.new(1, -12, 1, -12)
		page.Position = UDim2.new(0, 6, 0, 6)
		page.BackgroundTransparency = 1
		page.ScrollBarThickness = 4
		page.Visible = (i == 1)
		page.Parent = contentArea

		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 6)
		layout.Parent = page

		pages[tabName] = page

		local tabBtn = Instance.new("TextButton")
		tabBtn.Size = UDim2.new(1 / #tabs, -4, 1, 0)
		tabBtn.Position = UDim2.new((i - 1) / #tabs, 2, 0, 0)
		tabBtn.BackgroundColor3 = (i == 1) and Color3.fromRGB(59, 130, 246) or Color3.fromRGB(40, 44, 56)
		tabBtn.Text = tabName
		tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		tabBtn.TextSize = 11
		tabBtn.Font = Enum.Font.GothamBold
		tabBtn.Parent = tabBar
		Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 6)

		tabBtn.MouseButton1Click:Connect(function()
			for name, p in pairs(pages) do
				p.Visible = (name == tabName)
			end
			for _, child in ipairs(tabBar:GetChildren()) do
				if child:IsA("TextButton") then
					child.BackgroundColor3 = (child.Text == tabName) and Color3.fromRGB(59, 130, 246) or Color3.fromRGB(40, 44, 56)
				end
			end
		end)
	end

	local function addActionButton(parentPage, labelText, onClick)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 32)
		btn.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
		btn.Text = labelText
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 12
		btn.Font = Enum.Font.GothamBold
		btn.Parent = parentPage
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		btn.MouseButton1Click:Connect(function()
			onClick(btn)
		end)
		return btn
	end

	-- تبويب عام
	addActionButton(pages["عام"], "زيادة السرعة (32)", function()
		Config.WalkSpeed = 32
		applyMovement(LocalPlayer.Character)
	end)

	addActionButton(pages["عام"], "زيادة القفز (90)", function()
		Config.JumpPower = 90
		applyMovement(LocalPlayer.Character)
	end)

	addActionButton(pages["عام"], "إعادة ضبط الحركة (16 / 50)", function()
		Config.WalkSpeed = 16
		Config.JumpPower = 50
		applyMovement(LocalPlayer.Character)
	end)

	-- تبويب حماية/ESP
	addActionButton(pages["حماية/ESP"], "تبديل قود مود (God Mode)", function(btn)
		setGodMode(not Config.GodMode)
		btn.Text = Config.GodMode and "قود مود: مفعل" or "قود مود: معطل"
	end)

	addActionButton(pages["حماية/ESP"], "تبديل ESP للاعبين", function(btn)
		Config.EspEnabled = not Config.EspEnabled
		refreshEsp()
		btn.Text = Config.EspEnabled and "ESP اللاعبين: مفعل" or "ESP اللاعبين: معطل"
	end)

	-- تبويب 99 ليلة
	addActionButton(pages["99 ليلة"], "تبديل إضاءة الليل (Night Boost)", function(btn)
		local active = btn.Text:find("مفعل") ~= nil
		boostNightVisibility(not active)
		btn.Text = (not active) and "إضاءة الليل: مفعل" or "إضاءة الليل: معطل"
	end)

	-- تبويب المابات
	addActionButton(pages["المابات"], "وضع تلقائي (Auto Detect)", function()
		Config.SelectedMap = "Auto"
		header.Text = "Hub متعدد القوائم | الماب الحالي: " .. detectCurrentMap()
	end)

	addActionButton(pages["المابات"], "فتح قائمة 99 ليلة يدوياً", function()
		Config.SelectedMap = "99 Nights"
		header.Text = "Hub متعدد القوائم | الماب الحالي: 99 Nights"
		for name, p in pairs(pages) do
			p.Visible = (name == "99 ليلة")
		end
	end)

	addActionButton(pages["المابات"], "فتح القائمة العامة يدوياً", function()
		Config.SelectedMap = "Universal"
		header.Text = "Hub متعدد القوائم | الماب الحالي: Universal"
		for name, p in pairs(pages) do
			p.Visible = (name == "عام")
		end
	end)
end

buildHub()
