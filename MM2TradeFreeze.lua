--[[
	Modern Dark Minimalist Roblox GUI
	Place this as a LocalScript inside StarterGui (or use script.Parent for ScreenGui parenting).
	Features:
	- Always-on-top ScreenGui (DisplayOrder = max, ZIndexBehavior = Sibling)
	- Smooth custom drag (UserInputService)
	- Minimize / Close / Destroy header controls
	- Toggle Switch button (Button 1)
	- Pulse Bounce button (Button 2)
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------
local COLORS = {
	Background = Color3.fromRGB(24, 24, 28),
	Header = Color3.fromRGB(18, 18, 22),
	Stroke = Color3.fromRGB(45, 45, 52),
	Text = Color3.fromRGB(235, 235, 240),
	SubText = Color3.fromRGB(160, 160, 170),
	ButtonNeutral = Color3.fromRGB(40, 40, 46),
	ButtonHover = Color3.fromRGB(52, 52, 60),
	Accent = Color3.fromRGB(0, 255, 170), -- neon green/cyan
	PulseFlash = Color3.fromRGB(80, 170, 255),
	CloseIcon = Color3.fromRGB(200, 80, 80),
	KillIcon = Color3.fromRGB(255, 70, 70),
}

local FONT = Enum.Font.GothamSSm -- fallback-safe modern font (FredokaOne/BuilderSans may not exist on all clients)
local TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_INFO_FAST = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

------------------------------------------------------------
-- SCREEN GUI
------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ModernDarkGUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 2147483647 -- max possible value, always on top
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = false
screenGui.Parent = playerGui

------------------------------------------------------------
-- MAIN FRAME
------------------------------------------------------------
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 320, 0, 220)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -110)
mainFrame.BackgroundColor3 = COLORS.Background
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLORS.Stroke
mainStroke.Thickness = 1
mainStroke.Parent = mainFrame

-- Soft dropshadow (using an ImageLabel placed behind the frame)
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217" -- generic soft shadow asset
shadow.ImageColor3 = Color3.new(0, 0, 0)
shadow.ImageTransparency = 0.55
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.Size = UDim2.new(1, 40, 1, 40)
shadow.Position = UDim2.new(0, -20, 0, -20)
shadow.ZIndex = mainFrame.ZIndex - 1
shadow.Parent = mainFrame

------------------------------------------------------------
-- HEADER BAR
------------------------------------------------------------
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 36)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = COLORS.Header
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 8)
headerCorner.Parent = header

-- Mask the bottom corners of the header so it looks like a flat-bottomed bar
local headerMask = Instance.new("Frame")
headerMask.Name = "HeaderMask"
headerMask.BackgroundColor3 = COLORS.Header
headerMask.BorderSizePixel = 0
headerMask.Size = UDim2.new(1, 0, 0, 10)
headerMask.Position = UDim2.new(0, 0, 1, -10)
headerMask.ZIndex = header.ZIndex
headerMask.Parent = header

local headerPadding = Instance.new("UIPadding")
headerPadding.PaddingLeft = UDim.new(0, 12)
headerPadding.PaddingRight = UDim.new(0, 8)
headerPadding.Parent = header

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Size = UDim2.new(0.6, 0, 1, 0)
title.Position = UDim2.new(0, 0, 0, 0)
title.Font = FONT
title.Text = "Modern Panel"
title.TextColor3 = COLORS.Text
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

------------------------------------------------------------
-- HEADER BUTTONS (Minimize, Close, Kill)
------------------------------------------------------------
local buttonHolder = Instance.new("Frame")
buttonHolder.Name = "WindowControls"
buttonHolder.BackgroundTransparency = 1
buttonHolder.Size = UDim2.new(0, 90, 1, 0)
buttonHolder.Position = UDim2.new(1, -90, 0, 0)
buttonHolder.Parent = header

local controlsLayout = Instance.new("UIListLayout")
controlsLayout.FillDirection = Enum.FillDirection.Horizontal
controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
controlsLayout.Padding = UDim.new(0, 6)
controlsLayout.SortOrder = Enum.SortOrder.LayoutOrder
controlsLayout.Parent = buttonHolder

local function createIconButton(name, text, color, layoutOrder)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 24, 0, 24)
	btn.BackgroundColor3 = COLORS.ButtonNeutral
	btn.BackgroundTransparency = 0.3
	btn.AutoButtonColor = false
	btn.Font = FONT
	btn.Text = text
	btn.TextColor3 = color
	btn.TextSize = 14
	btn.LayoutOrder = layoutOrder
	btn.Parent = buttonHolder

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TWEEN_INFO_FAST, {BackgroundTransparency = 0}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TWEEN_INFO_FAST, {BackgroundTransparency = 0.3}):Play()
	end)

	return btn
end

local minimizeBtn = createIconButton("MinimizeButton", "—", COLORS.SubText, 1)
local closeBtn = createIconButton("CloseButton", "✕", COLORS.CloseIcon, 2)
local killBtn = createIconButton("KillButton", "☠", COLORS.KillIcon, 3)

------------------------------------------------------------
-- BODY
------------------------------------------------------------
local body = Instance.new("Frame")
body.Name = "Body"
body.BackgroundTransparency = 1
body.Size = UDim2.new(1, 0, 1, -36)
body.Position = UDim2.new(0, 0, 0, 36)
body.Parent = mainFrame

local bodyPadding = Instance.new("UIPadding")
bodyPadding.PaddingTop = UDim.new(0, 16)
bodyPadding.PaddingBottom = UDim.new(0, 16)
bodyPadding.PaddingLeft = UDim.new(0, 16)
bodyPadding.PaddingRight = UDim.new(0, 16)
bodyPadding.Parent = body

local bodyLayout = Instance.new("UIListLayout")
bodyLayout.FillDirection = Enum.FillDirection.Vertical
bodyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
bodyLayout.VerticalAlignment = Enum.VerticalAlignment.Center
bodyLayout.Padding = UDim.new(0, 14)
bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
bodyLayout.Parent = body

------------------------------------------------------------
-- BUTTON 1: TOGGLE SWITCH
------------------------------------------------------------
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleSwitchButton"
toggleButton.Size = UDim2.new(1, 0, 0, 44)
toggleButton.BackgroundColor3 = COLORS.ButtonNeutral
toggleButton.AutoButtonColor = false
toggleButton.Font = FONT
toggleButton.Text = "Freeze Trade"
toggleButton.TextColor3 = COLORS.Text
toggleButton.TextSize = 16
toggleButton.LayoutOrder = 1
toggleButton.Parent = body

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleButton

local togglePadding = Instance.new("UIPadding")
togglePadding.PaddingLeft = UDim.new(0, 10)
togglePadding.PaddingRight = UDim.new(0, 10)
togglePadding.Parent = toggleButton

local toggleState = false
local toggleOriginalSize = toggleButton.Size

toggleButton.MouseButton1Click:Connect(function()
	toggleState = not toggleState

	if toggleState then
		TweenService:Create(toggleButton, TWEEN_INFO, {
			BackgroundColor3 = COLORS.Accent,
			Size = toggleOriginalSize + UDim2.new(0, 0, 0, 4),
		}):Play()
		TweenService:Create(toggleButton, TWEEN_INFO, {TextColor3 = Color3.fromRGB(10, 10, 10)}):Play()
	else
		TweenService:Create(toggleButton, TWEEN_INFO, {
			BackgroundColor3 = COLORS.ButtonNeutral,
			Size = toggleOriginalSize,
		}):Play()
		TweenService:Create(toggleButton, TWEEN_INFO, {TextColor3 = COLORS.Text}):Play()
	end
end)

------------------------------------------------------------
-- BUTTON 2: PULSE BOUNCE
------------------------------------------------------------
local pulseButton = Instance.new("TextButton")
pulseButton.Name = "PulseBounceButton"
pulseButton.Size = UDim2.new(1, 0, 0, 44)
pulseButton.BackgroundColor3 = COLORS.ButtonNeutral
pulseButton.AutoButtonColor = false
pulseButton.Font = FONT
pulseButton.Text = "Force Accept"
pulseButton.TextColor3 = COLORS.Text
pulseButton.TextSize = 16
pulseButton.LayoutOrder = 2
pulseButton.Parent = body

local pulseCorner = Instance.new("UICorner")
pulseCorner.CornerRadius = UDim.new(0, 8)
pulseCorner.Parent = pulseButton

local pulsePadding = Instance.new("UIPadding")
pulsePadding.PaddingLeft = UDim.new(0, 10)
pulsePadding.PaddingRight = UDim.new(0, 10)
pulsePadding.Parent = pulseButton

local pulseOriginalSize = pulseButton.Size
local pulseOriginalColor = COLORS.ButtonNeutral
local pulseDebounce = false

pulseButton.MouseButton1Click:Connect(function()
	if pulseDebounce then return end
	pulseDebounce = true

	local growSize = UDim2.new(
		pulseOriginalSize.X.Scale, pulseOriginalSize.X.Offset * 1.1,
		pulseOriginalSize.Y.Scale, pulseOriginalSize.Y.Offset * 1.1
	)

	-- Grow + flash color
	local growTween = TweenService:Create(pulseButton, TWEEN_INFO_FAST, {
		Size = growSize,
		BackgroundColor3 = COLORS.PulseFlash,
	})
	growTween:Play()

	growTween.Completed:Connect(function()
		-- Shrink back + revert color
		local shrinkTween = TweenService:Create(pulseButton, TWEEN_INFO_FAST, {
			Size = pulseOriginalSize,
			BackgroundColor3 = pulseOriginalColor,
		})
		shrinkTween:Play()
		shrinkTween.Completed:Connect(function()
			pulseDebounce = false
		end)
	end)
end)

------------------------------------------------------------
-- MINIMIZE / CLOSE / KILL LOGIC
------------------------------------------------------------
local expandedSize = mainFrame.Size
local collapsedSize = UDim2.new(expandedSize.X.Scale, expandedSize.X.Offset, 0, 36)
local isMinimized = false

minimizeBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		TweenService:Create(mainFrame, TWEEN_INFO, {Size = collapsedSize}):Play()
		minimizeBtn.Text = "+"
	else
		TweenService:Create(mainFrame, TWEEN_INFO, {Size = expandedSize}):Play()
		minimizeBtn.Text = "—"
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	-- Fade out every relevant GuiObject, then disable (not destroy) the ScreenGui
	local tweens = {}

	for _, obj in ipairs(screenGui:GetDescendants()) do
		if obj:IsA("Frame") or obj:IsA("TextButton") then
			table.insert(tweens, TweenService:Create(obj, TWEEN_INFO, {BackgroundTransparency = 1}))
		elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
			table.insert(tweens, TweenService:Create(obj, TWEEN_INFO, {TextTransparency = 1}))
		elseif obj:IsA("ImageLabel") then
			table.insert(tweens, TweenService:Create(obj, TWEEN_INFO, {ImageTransparency = 1}))
		elseif obj:IsA("UIStroke") then
			table.insert(tweens, TweenService:Create(obj, TWEEN_INFO, {Transparency = 1}))
		end
	end

	for _, tween in ipairs(tweens) do
		tween:Play()
	end

	task.delay(TWEEN_INFO.Time, function()
		screenGui.Enabled = false
	end)
end)

killBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

------------------------------------------------------------
-- CUSTOM DRAG SCRIPT (UserInputService)
------------------------------------------------------------
local dragging = false
local dragStart
local startPos

local function updateDrag(input)
	local delta = input.Position - dragStart
	mainFrame.Position = UDim2.new(
		startPos.X.Scale, startPos.X.Offset + delta.X,
		startPos.Y.Scale, startPos.Y.Offset + delta.Y
	)
end

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		updateDrag(input)
	end
end)
