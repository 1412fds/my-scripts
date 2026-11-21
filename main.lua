-- سكربت واجهة تحكم بسيطة لـ Roblox (مناسب للتجربة في Delta)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- إعدادات افتراضية
local DEFAULT_SPEED = 16
local DEFAULT_JUMP = 50
local targetSpeed = DEFAULT_SPEED
local targetJump = DEFAULT_JUMP
local lockStats = false

-- دالة لتطبيق السرعة والقفز على الشخصية الحالية
local function applyCharacterStats(char)
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = targetSpeed
		-- دعم كلا النظامين (JumpPower أو UseJumpPower / JumpHeight)
		if humanoid.UseJumpPower then
			humanoid.JumpPower = targetJump
		else
			humanoid.JumpHeight = math.max(1, targetJump * 0.145)
		end
	end
end

-- إعادة تطبيق الخصائص تلقائياً عند ولادة الشخصية أو تغييرها إذا كان القفل مفعلاً
LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(0.2)
	if lockStats then
		applyCharacterStats(char)
	end
end)

-- بناء الواجهة
local function createMenu()
	local parentGui = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui")

	-- حذف واجهة سابقة بنفس الاسم إن وجدت
	local oldGui = parentGui:FindFirstChild("CustomDeltaMenu")
	if oldGui then
		oldGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CustomDeltaMenu"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = parentGui

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 250, 0, 215)
	mainFrame.Position = UDim2.new(0.5, -125, 0.5, -107)
	mainFrame.BackgroundColor3 = Color3.fromRGB(24, 26, 33)
	mainFrame.BorderSizePixel = 0
	mainFrame.Active = true
	mainFrame.Draggable = true
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = mainFrame

	-- شريط العنوان
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -40, 0, 36)
	titleLabel.Position = UDim2.new(0, 12, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "لوحة التحكم السريعة"
	titleLabel.TextColor3 = Color3.fromRGB(240, 244, 248)
	titleLabel.TextSize = 15
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = mainFrame

	-- زر تصغير / إغلاق
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(0, 28, 0, 28)
	toggleBtn.Position = UDim2.new(1, -34, 0, 4)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 49, 62)
	toggleBtn.Text = "-"
	toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleBtn.TextSize = 18
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.Parent = mainFrame

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 6)
	toggleCorner.Parent = toggleBtn

	-- حاوية العناصر
	local bodyFrame = Instance.new("Frame")
	bodyFrame.Name = "Body"
	bodyFrame.Size = UDim2.new(1, -24, 1, -46)
	bodyFrame.Position = UDim2.new(0, 12, 0, 40)
	bodyFrame.BackgroundTransparency = 1
	bodyFrame.Parent = mainFrame

	local minimized = false
	toggleBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		bodyFrame.Visible = not minimized
		toggleBtn.Text = minimized and "+" or "-"
		mainFrame.Size = minimized and UDim2.new(0, 250, 0, 38) or UDim2.new(0, 250, 0, 215)
	end)

	-- حقل إدخال السرعة
	local speedBox = Instance.new("TextBox")
	speedBox.Size = UDim2.new(1, 0, 0, 34)
	speedBox.Position = UDim2.new(0, 0, 0, 0)
	speedBox.BackgroundColor3 = Color3.fromRGB(36, 40, 51)
	speedBox.Text = tostring(DEFAULT_SPEED)
	speedBox.PlaceholderText = "السرعة (مثال: 32)"
	speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	speedBox.PlaceholderColor3 = Color3.fromRGB(150, 158, 175)
	speedBox.TextSize = 13
	speedBox.Font = Enum.Font.Gotham
	speedBox.Parent = bodyFrame
	Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0, 6)

	-- حقل إدخال قوة القفز
	local jumpBox = Instance.new("TextBox")
	jumpBox.Size = UDim2.new(1, 0, 0, 34)
	jumpBox.Position = UDim2.new(0, 0, 0, 42)
	jumpBox.BackgroundColor3 = Color3.fromRGB(36, 40, 51)
	jumpBox.Text = tostring(DEFAULT_JUMP)
	jumpBox.PlaceholderText = "قوة القفز (مثال: 80)"
	jumpBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	jumpBox.PlaceholderColor3 = Color3.fromRGB(150, 158, 175)
	jumpBox.TextSize = 13
	jumpBox.Font = Enum.Font.Gotham
	jumpBox.Parent = bodyFrame
	Instance.new("UICorner", jumpBox).CornerRadius = UDim.new(0, 6)

	-- زر تطبيق القيم
	local applyBtn = Instance.new("TextButton")
	applyBtn.Size = UDim2.new(1, 0, 0, 36)
	applyBtn.Position = UDim2.new(0, 0, 0, 86)
	applyBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
	applyBtn.Text = "تطبيق السرعة والقفز"
	applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	applyBtn.TextSize = 13
	applyBtn.Font = Enum.Font.GothamBold
	applyBtn.Parent = bodyFrame
	Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0, 6)

	applyBtn.MouseButton1Click:Connect(function()
		local s = tonumber(speedBox.Text)
		local j = tonumber(jumpBox.Text)
		if s then targetSpeed = math.clamp(s, 0, 250) end
		if j then targetJump = math.clamp(j, 0, 300) end
		applyCharacterStats(LocalPlayer.Character)
	end)

	-- زر تثبيت القيم بعد إعادة الظهور + إعادة ضبط
	local lockBtn = Instance.new("TextButton")
	lockBtn.Size = UDim2.new(0.58, -4, 0, 32)
	lockBtn.Position = UDim2.new(0, 0, 0, 130)
	lockBtn.BackgroundColor3 = Color3.fromRGB(52, 58, 74)
	lockBtn.Text = "تثبيت بعد الموت: معطل"
	lockBtn.TextColor3 = Color3.fromRGB(235, 235, 235)
	lockBtn.TextSize = 11
	lockBtn.Font = Enum.Font.GothamBold
	lockBtn.Parent = bodyFrame
	Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 6)

	lockBtn.MouseButton1Click:Connect(function()
		lockStats = not lockStats
		lockBtn.Text = lockStats and "تثبيت بعد الموت: مفعل" or "تثبيت بعد الموت: معطل"
		lockBtn.BackgroundColor3 = lockStats and Color3.fromRGB(22, 163, 74) or Color3.fromRGB(52, 58, 74)
		if lockStats then
			applyCharacterStats(LocalPlayer.Character)
		end
	end)

	local resetBtn = Instance.new("TextButton")
	resetBtn.Size = UDim2.new(0.42, -4, 0, 32)
	resetBtn.Position = UDim2.new(0.58, 4, 0, 130)
	resetBtn.BackgroundColor3 = Color3.fromRGB(185, 28, 28)
	resetBtn.Text = "إعادة ضبط"
	resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	resetBtn.TextSize = 11
	resetBtn.Font = Enum.Font.GothamBold
	resetBtn.Parent = bodyFrame
	Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 6)

	resetBtn.MouseButton1Click:Connect(function()
		targetSpeed = DEFAULT_SPEED
		targetJump = DEFAULT_JUMP
		speedBox.Text = tostring(DEFAULT_SPEED)
		jumpBox.Text = tostring(DEFAULT_JUMP)
		applyCharacterStats(LocalPlayer.Character)
	end)
end

createMenu()
