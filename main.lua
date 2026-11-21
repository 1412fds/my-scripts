-- سكربت متعدد القوائم مع كشف الماب التلقائي، قود مود، ESP، انتقال للاعبين، وقسم 99 ليلة
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- معرفات مابات كمثال (استبدل/أضف PlaceId المابات التي تريدها)
local MAP_IDS = {
	NIGHTS_99 = 79546208627805, -- ضع PlaceId الصحيح لماب 99 ليلة إذا اختلف
}

-- إعدادات الحالة العامة
local Config = {
	WalkSpeed = 28,
	JumpPower = 80,
	FlySpeed = 60,
	LockStats = false,
	GodMode = false,
	EspEnabled = false,
	FlyEnabled = false,
	NoClipEnabled = false,
	NightBoostEnabled = false,
	SelectedMap = "Auto", -- "Auto", "99 Nights", "Universal"
	FontIndex = 1,
}

-- قائمة خطوط مختلفة لتغيير شكل النص في المنيو (عدّل الترتيب أو أضف خطوطاً حسب رغبتك)
local FONT_CHOICES = {
	Enum.Font.Arcade,
	Enum.Font.Highway,
	Enum.Font.Bangers,
	Enum.Font.Code,
	Enum.Font.SourceSansItalic,
}

local function getCurrentFont()
	return FONT_CHOICES[Config.FontIndex] or Enum.Font.Arcade
end

local StyledObjects = {}

local function applyFontToObject(instanceObj, size, alignRight)
	if instanceObj:IsA("TextLabel") or instanceObj:IsA("TextButton") or instanceObj:IsA("TextBox") then
		instanceObj.Font = getCurrentFont()
		if size then
			instanceObj.TextSize = size
		end
		if alignRight ~= nil then
			instanceObj.TextXAlignment = alignRight and Enum.TextXAlignment.Right or Enum.TextXAlignment.Center
		end
		table.insert(StyledObjects, {
			Obj = instanceObj,
			Size = size or instanceObj.TextSize,
			AlignRight = alignRight,
		})
	end
end

local function refreshAllFonts()
	local chosenFont = getCurrentFont()
	for _, entry in ipairs(StyledObjects) do
		local obj = entry.Obj
		if obj and obj.Parent then
			obj.Font = chosenFont
			if entry.Size then
				obj.TextSize = entry.Size
			end
			if entry.AlignRight ~= nil then
				obj.TextXAlignment = entry.AlignRight and Enum.TextXAlignment.Right or Enum.TextXAlignment.Center
			end
		end
	end
end

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
	local targetChar = char or LocalPlayer.Character
	local humanoid = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
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

-- طيران (Fly) واختراق الجدران (NoClip)
local flyVel, flyGyro
local function stopFly()
	Config.FlyEnabled = false
	if flyVel then flyVel:Destroy() flyVel = nil end
	if flyGyro then flyGyro:Destroy() flyGyro = nil end
	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = false end
end

local function startFly()
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end

	stopFly()
	Config.FlyEnabled = true
	hum.PlatformStand = true

	flyVel = Instance.new("BodyVelocity")
	flyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	flyVel.Velocity = Vector3.zero
	flyVel.Parent = root

	flyGyro = Instance.new("BodyGyro")
	flyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	flyGyro.P = 3000
	flyGyro.CFrame = root.CFrame
	flyGyro.Parent = root
end

table.insert(Connections, RunService.RenderStepped:Connect(function()
	if Config.FlyEnabled then
		local char = LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local cam = Workspace.CurrentCamera
		if root and cam and flyVel and flyGyro then
			local dir = Vector3.zero
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end

			if dir.Magnitude > 0 then
				dir = dir.Unit * Config.FlySpeed
			end
			flyVel.Velocity = dir
			flyGyro.CFrame = cam.CFrame
		end
	end

	if Config.NoClipEnabled and LocalPlayer.Character then
		for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end
end))

-- نظام ESP بسيط ونظيف للاعبين
local function clearEsp()
	for _, item in ipairs(EspFolder:GetChildren()) do
		item:Destroy()
	end
end

local function createPlayerEsp(player)
	if player == LocalPlayer or not Config.EspEnabled then return end
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not char or not char.Parent or not head then return end

	if EspFolder:FindFirstChild(player.Name) then
		EspFolder[player.Name]:Destroy()
	end

	local holder = Instance.new("Folder")
	holder.Name = player.Name
	holder.Parent = EspFolder

	local highlight = Instance.new("Highlight")
	highlight.Adornee = char
	highlight.FillColor = Color3.fromRGB(239, 68, 68)
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.52
	highlight.OutlineTransparency = 0
	highlight.Parent = holder

	local bb = Instance.new("BillboardGui")
	bb.Adornee = head
	bb.Size = UDim2.new(0, 150, 0, 26)
	bb.StudsOffset = Vector3.new(0, 2.3, 0)
	bb.AlwaysOnTop = true
	bb.Parent = holder

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = player.DisplayName .. " (@" .. player.Name .. ")"
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.TextStrokeTransparency = 0.15
	applyFontToObject(lbl, 12, false)
	lbl.Parent = bb
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

-- انتقال للاعب بالاسم أو لأقرب لاعب
local function teleportToPlayerByName(partialName)
	local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot or not partialName or partialName == "" then return false, "اكتب اسم اللاعب أولاً" end

	local query = string.lower(partialName)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local nMatch = string.find(string.lower(plr.Name), query, 1, true)
			local dMatch = string.find(string.lower(plr.DisplayName), query, 1, true)
			if nMatch or dMatch then
				local targetRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if targetRoot then
					myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -3.5)
					return true, "تم الانتقال إلى: " .. plr.Name
				end
			end
		end
	end
	return false, "لم يتم العثور على لاعب بهذا الاسم"
end

local function teleportToNearestPlayer()
	local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return false, "الشخصية غير جاهزة" end

	local nearestRoot, nearestName, bestDist = nil, nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
			if tRoot then
				local d = (tRoot.Position - myRoot.Position).Magnitude
				if d < bestDist then
					bestDist = d
					nearestRoot = tRoot
					nearestName = plr.Name
				end
			end
		end
	end

	if nearestRoot then
		myRoot.CFrame = nearestRoot.CFrame * CFrame.new(0, 0, -3.5)
		return true, "تم الانتقال لأقرب لاعب: " .. tostring(nearestName)
	end
	return false, "لا يوجد لاعبون آخرون في الماب"
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
	if Config.FlyEnabled then
		startFly()
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
	Config.NightBoostEnabled = enable
	if enable then
		Lighting.Ambient = Color3.fromRGB(165, 165, 180)
		Lighting.OutdoorAmbient = Color3.fromRGB(165, 165, 180)
		Lighting.Brightness = 2.4
		Lighting.FogEnd = 100000
	else
		Lighting.Ambient = Color3.fromRGB(70, 70, 70)
		Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
		Lighting.Brightness = 1
		Lighting.FogEnd = 1000
	end
end

local function tpToNearestItem(keyword)
	local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not root or not keyword or keyword == "" then return false end
	local query = string.lower(keyword)
	local bestCF, bestDist = nil, math.huge

	for _, obj in ipairs(Workspace:GetDescendants()) do
		if string.find(string.lower(obj.Name), query, 1, true) then
			local cf = obj:IsA("BasePart") and obj.CFrame or (obj:IsA("Model") and obj:GetPivot() or nil)
			if cf then
				local dist = (cf.Position - root.Position).Magnitude
				if dist < bestDist then
					bestDist = dist
					bestCF = cf
				end
			end
		end
	end

	if bestCF then
		root.CFrame = bestCF + Vector3.new(0, 4, 0)
		return true
	end
	return false
end

local function bringMatchedItems(keyword)
	local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not root or not keyword or keyword == "" then return 0 end
	local query = string.lower(keyword)
	local moved = 0

	for _, obj in ipairs(Workspace:GetDescendants()) do
		if string.find(string.lower(obj.Name), query, 1, true) then
			local ok = pcall(function()
				local target = root.CFrame * CFrame.new(0, 0, -4 - (moved * 1.5))
				if obj:IsA("BasePart") and not obj.Anchored then
					obj.CFrame = target
					moved += 1
				elseif obj:IsA("Model") then
					obj:PivotTo(target)
					moved += 1
				end
			end)
			if ok and moved >= 5 then
				break
			end
		end
	end
	return moved
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

-- بناء واجهة منيو عربية قوية بخط مختلف وانتقال للاعبين
local function buildHub()
	table.clear(StyledObjects)
	local parentGui = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui")
	local old = parentGui:FindFirstChild("MultiMapHubGui")
	if old then old:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "MultiMapHubGui"
	gui.ResetOnSpawn = false
	gui.Parent = parentGui

	local main = Instance.new("Frame")
	main.Size = UDim2.new(0, 390, 0, 315)
	main.Position = UDim2.new(0.5, -195, 0.5, -157)
	main.BackgroundColor3 = Color3.fromRGB(16, 18, 25)
	main.BorderSizePixel = 0
	main.Active = true
	main.Draggable = true
	main.Parent = gui
	Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(59, 130, 246)
	stroke.Thickness = 1.4
	stroke.Transparency = 0.35
	stroke.Parent = main

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, -46, 0, 34)
	header.Position = UDim2.new(0, 10, 0, 3)
	header.BackgroundTransparency = 1
	header.Text = "منيو القوائم الشامل | الماب: " .. detectCurrentMap()
	header.TextColor3 = Color3.fromRGB(248, 250, 252)
	applyFontToObject(header, 13, true)
	header.Parent = main

	local minBtn = Instance.new("TextButton")
	minBtn.Size = UDim2.new(0, 28, 0, 26)
	minBtn.Position = UDim2.new(0, 8, 0, 7)
	minBtn.BackgroundColor3 = Color3.fromRGB(38, 43, 58)
	minBtn.Text = "-"
	minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	applyFontToObject(minBtn, 16, false)
	minBtn.Parent = main
	Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 7)

	local tabBar = Instance.new("Frame")
	tabBar.Size = UDim2.new(1, -16, 0, 30)
	tabBar.Position = UDim2.new(0, 8, 0, 40)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent = main

	local contentArea = Instance.new("Frame")
	contentArea.Size = UDim2.new(1, -16, 1, -78)
	contentArea.Position = UDim2.new(0, 8, 0, 74)
	contentArea.BackgroundColor3 = Color3.fromRGB(24, 27, 37)
	contentArea.BorderSizePixel = 0
	contentArea.Parent = main
	Instance.new("UICorner", contentArea).CornerRadius = UDim.new(0, 10)

	local minimized = false
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		tabBar.Visible = not minimized
		contentArea.Visible = not minimized
		minBtn.Text = minimized and "+" or "-"
		main.Size = minimized and UDim2.new(0, 390, 0, 42) or UDim2.new(0, 390, 0, 315)
	end)

	local tabs = { "عام", "لاعبين/ESP", "99 ليلة", "المابات" }
	local pages = {}
	local tabButtons = {}

	local function openTab(targetName)
		for name, p in pairs(pages) do
			p.Visible = (name == targetName)
		end
		for name, b in pairs(tabButtons) do
			b.BackgroundColor3 = (name == targetName) and Color3.fromRGB(59, 130, 246) or Color3.fromRGB(37, 42, 56)
		end
	end

	for i, tabName in ipairs(tabs) do
		local page = Instance.new("ScrollingFrame")
		page.Name = tabName
		page.Size = UDim2.new(1, -12, 1, -12)
		page.Position = UDim2.new(0, 6, 0, 6)
		page.BackgroundTransparency = 1
		page.ScrollBarThickness = 4
		page.CanvasSize = UDim2.new(0, 0, 0, 430)
		page.Visible = (i == 1)
		page.Parent = contentArea

		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 6)
		layout.Parent = page

		pages[tabName] = page

		local tabBtn = Instance.new("TextButton")
		tabBtn.Size = UDim2.new(1 / #tabs, -4, 1, 0)
		tabBtn.Position = UDim2.new((i - 1) / #tabs, 2, 0, 0)
		tabBtn.BackgroundColor3 = (i == 1) and Color3.fromRGB(59, 130, 246) or Color3.fromRGB(37, 42, 56)
		tabBtn.Text = tabName
		tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		applyFontToObject(tabBtn, 12, false)
		tabBtn.Parent = tabBar
		Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 7)

		tabButtons[tabName] = tabBtn
		tabBtn.MouseButton1Click:Connect(function()
			openTab(tabName)
		end)
	end

	local function addActionButton(parentPage, labelText, bgColor, onClick)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 33)
		btn.BackgroundColor3 = bgColor or Color3.fromRGB(43, 49, 66)
		btn.Text = labelText
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		applyFontToObject(btn, 13, false)
		btn.Parent = parentPage
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
		btn.MouseButton1Click:Connect(function()
			onClick(btn)
		end)
		return btn
	end

	local function addInputBox(parentPage, placeholderText, defaultVal)
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, 0, 0, 32)
		box.BackgroundColor3 = Color3.fromRGB(33, 37, 50)
		box.Text = defaultVal or ""
		box.PlaceholderText = placeholderText
		box.TextColor3 = Color3.fromRGB(255, 255, 255)
		box.PlaceholderColor3 = Color3.fromRGB(150, 158, 175)
		applyFontToObject(box, 12, true)
		box.Parent = parentPage
		Instance.new("UICorner", box).CornerRadius = UDim.new(0, 7)
		return box
	end

	-- === تبويب عام ===
	local speedInput = addInputBox(pages["عام"], "السرعة (مثال: 35)", tostring(Config.WalkSpeed))
	local jumpInput = addInputBox(pages["عام"], "القفز (مثال: 95)", tostring(Config.JumpPower))

	addActionButton(pages["عام"], "تطبيق السرعة والقفز", Color3.fromRGB(37, 99, 235), function()
		local s = tonumber(speedInput.Text)
		local j = tonumber(jumpInput.Text)
		if s then Config.WalkSpeed = math.clamp(s, 0, 300) end
		if j then Config.JumpPower = math.clamp(j, 0, 350) end
		applyMovement(LocalPlayer.Character)
	end)

	addActionButton(pages["عام"], "قفل الحركة بعد الموت: معطل", nil, function(btn)
		Config.LockStats = not Config.LockStats
		btn.Text = Config.LockStats and "قفل الحركة بعد الموت: مفعل" or "قفل الحركة بعد الموت: معطل"
	end)

	addActionButton(pages["عام"], "طيران (WASD + Space/Ctrl): معطل", nil, function(btn)
		if Config.FlyEnabled then
			stopFly()
			btn.Text = "طيران (WASD + Space/Ctrl): معطل"
		else
			startFly()
			btn.Text = "طيران (WASD + Space/Ctrl): مفعل"
		end
	end)

	addActionButton(pages["عام"], "اختراق الجدران NoClip: معطل", nil, function(btn)
		Config.NoClipEnabled = not Config.NoClipEnabled
		btn.Text = Config.NoClipEnabled and "اختراق الجدران NoClip: مفعل" or "اختراق الجدران NoClip: معطل"
	end)

	addActionButton(pages["عام"], "تغيير خط المنيو (" .. tostring(getCurrentFont().Name) .. ")", Color3.fromRGB(109, 40, 217), function(btn)
		Config.FontIndex = (Config.FontIndex % #FONT_CHOICES) + 1
		refreshAllFonts()
		btn.Text = "تغيير خط المنيو (" .. tostring(getCurrentFont().Name) .. ")"
	end)

	addActionButton(pages["عام"], "إعادة ضبط الحركة (16 / 50)", Color3.fromRGB(153, 27, 27), function()
		Config.WalkSpeed = 16
		Config.JumpPower = 50
		speedInput.Text = "16"
		jumpInput.Text = "50"
		applyMovement(LocalPlayer.Character)
	end)

	-- === تبويب لاعبين/ESP ===
	local targetPlayerBox = addInputBox(pages["لاعبين/ESP"], "اكتب اسم اللاعب للانتقال إليه", "")

	addActionButton(pages["لاعبين/ESP"], "الانتقال إلى اللاعب المكتوب", Color3.fromRGB(37, 99, 235), function()
		local ok, msg = teleportToPlayerByName(targetPlayerBox.Text)
		print(msg)
	end)

	addActionButton(pages["لاعبين/ESP"], "الانتقال إلى أقرب لاعب في الماب", Color3.fromRGB(14, 165, 233), function()
		local ok, msg = teleportToNearestPlayer()
		print(msg)
	end)

	addActionButton(pages["لاعبين/ESP"], "تبديل قود مود (God Mode)", Color3.fromRGB(22, 163, 74), function(btn)
		setGodMode(not Config.GodMode)
		btn.Text = Config.GodMode and "قود مود: مفعل" or "قود مود: معطل"
	end)

	addActionButton(pages["لاعبين/ESP"], "تبديل ESP للاعبين", Color3.fromRGB(220, 38, 38), function(btn)
		Config.EspEnabled = not Config.EspEnabled
		refreshEsp()
		btn.Text = Config.EspEnabled and "ESP اللاعبين: مفعل" or "ESP اللاعبين: معطل"
	end)

	-- === تبويب 99 ليلة ===
	addActionButton(pages["99 ليلة"], "تبديل إضاءة الليل (Night Boost)", Color3.fromRGB(217, 119, 6), function(btn)
		boostNightVisibility(not Config.NightBoostEnabled)
		btn.Text = Config.NightBoostEnabled and "إضاءة الليل: مفعل" or "إضاءة الليل: معطل"
	end)

	local itemInput = addInputBox(pages["99 ليلة"], "اكتب اسم عنصر/مورد (مثال: Log)", "")
	addActionButton(pages["99 ليلة"], "الانتقال لأقرب عنصر مطابق", nil, function()
		local ok = tpToNearestItem(itemInput.Text)
		print(ok and "تم الانتقال للعنصر" or "لم يُعثر على عنصر مطابق")
	end)

	addActionButton(pages["99 ليلة"], "سحب عناصر مطابقة أمامك", nil, function()
		local count = bringMatchedItems(itemInput.Text)
		print("عدد العناصر التي تمت محاولة سحبها: " .. tostring(count))
	end)

	-- === تبويب المابات ===
	addActionButton(pages["المابات"], "وضع تلقائي (Auto Detect)", nil, function()
		Config.SelectedMap = "Auto"
		header.Text = "منيو القوائم الشامل | الماب: " .. detectCurrentMap()
		openTab(game.PlaceId == MAP_IDS.NIGHTS_99 and "99 ليلة" or "عام")
	end)

	addActionButton(pages["المابات"], "فتح قائمة 99 ليلة يدوياً", nil, function()
		Config.SelectedMap = "99 Nights"
		header.Text = "منيو القوائم الشامل | الماب: 99 Nights"
		openTab("99 ليلة")
	end)

	addActionButton(pages["المابات"], "فتح القائمة العامة يدوياً", nil, function()
		Config.SelectedMap = "Universal"
		header.Text = "منيو القوائم الشامل | الماب: Universal"
		openTab("عام")
	end)

	if detectCurrentMap() == "99 Nights" then
		openTab("99 ليلة")
	end
end

buildHub()
