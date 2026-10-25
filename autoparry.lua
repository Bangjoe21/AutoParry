--[[
    Auto Parry + UI
    Cara pakai:
      1) Hosting file ini (GitHub raw / pastebin raw), lalu jalankan:
         loadstring(game:HttpGet("URL_RAW_SCRIPT_INI"))()
      2) Atau tempel langsung sebagai LocalScript di game kamu sendiri.

    CATATAN: Sesuaikan bagian CONFIG dengan game kamu
    (nama folder bola, tombol parry, dsb).
]]

----------------------------------------------------------------
-- CONFIG (ubah sesuai game kamu)
----------------------------------------------------------------
local CONFIG = {
    BallsFolderName = "Balls",       -- nama folder tempat bola berada di workspace
    BallAttribute   = "realBall",    -- attribute penanda bola asli (set nil jika tidak ada)
    ParryKey        = Enum.KeyCode.F,-- tombol parry di game kamu
    ParryTime       = 0.55,          -- parry jika bola akan sampai dalam X detik
    MinSpeed        = 5,             -- abaikan bola yang hampir diam
    Cooldown        = 0.25,          -- jeda antar parry (detik)
    PingCompensate  = true,          -- tambahkan kompensasi ping
}

----------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer

-- Bersihkan instance lama jika script dijalankan 2x
local guiParent = (gethui and gethui()) or player:WaitForChild("PlayerGui")
local old = guiParent:FindFirstChild("AutoParryUI")
if old then old:Destroy() end

----------------------------------------------------------------
-- STATE
----------------------------------------------------------------
local State = {
    Enabled = false,
    LastParry = 0,
    ParryCount = 0,
    ParryTime = CONFIG.ParryTime,
}

----------------------------------------------------------------
-- LOGIKA AUTO PARRY
----------------------------------------------------------------
local function getPing()
    if not CONFIG.PingCompensate then return 0 end
    local ok, value = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    return ok and (value / 1000) or 0
end

local function doParry()
    VirtualInputManager:SendKeyEvent(true, CONFIG.ParryKey, false, game)
    task.wait(0.02)
    VirtualInputManager:SendKeyEvent(false, CONFIG.ParryKey, false, game)
end

local function getBalls()
    local folder = workspace:FindFirstChild(CONFIG.BallsFolderName)
    if not folder then return {} end
    local result = {}
    for _, ball in ipairs(folder:GetChildren()) do
        if ball:IsA("BasePart") then
            if not CONFIG.BallAttribute or ball:GetAttribute(CONFIG.BallAttribute) ~= false then
                table.insert(result, ball)
            end
        end
    end
    return result
end

local function checkBalls()
    if not State.Enabled then return end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if os.clock() - State.LastParry < CONFIG.Cooldown then return end

    for _, ball in ipairs(getBalls()) do
        local velocity = ball.AssemblyLinearVelocity
        local speed = velocity.Magnitude
        if speed >= CONFIG.MinSpeed then
            local toPlayer = root.Position - ball.Position
            local distance = toPlayer.Magnitude
            -- kecepatan bola mendekati kita (dot product)
            local closing = velocity:Dot(toPlayer.Unit)
            if closing > 0 then
                local timeToHit = distance / closing
                if timeToHit <= (State.ParryTime + getPing()) then
                    State.LastParry = os.clock()
                    State.ParryCount += 1
                    doParry()
                    return
                end
            end
        end
    end
end

----------------------------------------------------------------
-- UI
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "AutoParryUI"
gui.ResetOnSpawn = false
gui.Parent = guiParent

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(260, 190)
main.Position = UDim2.new(0.5, -130, 0.3, 0)
main.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(90, 90, 255)
stroke.Thickness = 1.5

-- Title bar (untuk drag)
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 34)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
title.BorderSizePixel = 0
title.Text = "  ⚔ Auto Parry"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.Parent = main
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(28, 24)
minimize.Position = UDim2.new(1, -34, 0, 5)
minimize.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
minimize.Text = "-"
minimize.TextColor3 = Color3.new(1, 1, 1)
minimize.Font = Enum.Font.GothamBold
minimize.TextSize = 16
minimize.Parent = title
Instance.new("UICorner", minimize).CornerRadius = UDim.new(0, 6)

local body = Instance.new("Frame")
body.Size = UDim2.new(1, 0, 1, -34)
body.Position = UDim2.fromOffset(0, 34)
body.BackgroundTransparency = 1
body.Parent = main

-- Tombol toggle
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1, -24, 0, 36)
toggle.Position = UDim2.fromOffset(12, 12)
toggle.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
toggle.Text = "Auto Parry: OFF"
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 14
toggle.Parent = body
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 8)

-- Input parry time
local label = Instance.new("TextLabel")
label.Size = UDim2.new(0.55, 0, 0, 28)
label.Position = UDim2.fromOffset(12, 58)
label.BackgroundTransparency = 1
label.Text = "Parry Time (detik):"
label.TextColor3 = Color3.fromRGB(200, 200, 220)
label.TextXAlignment = Enum.TextXAlignment.Left
label.Font = Enum.Font.Gotham
label.TextSize = 13
label.Parent = body

local box = Instance.new("TextBox")
box.Size = UDim2.new(0.35, 0, 0, 26)
box.Position = UDim2.new(0.62, 0, 0, 59)
box.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
box.Text = tostring(State.ParryTime)
box.TextColor3 = Color3.new(1, 1, 1)
box.Font = Enum.Font.Gotham
box.TextSize = 13
box.ClearTextOnFocus = false
box.Parent = body
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

-- Statistik
local stats = Instance.new("TextLabel")
stats.Size = UDim2.new(1, -24, 0, 22)
stats.Position = UDim2.fromOffset(12, 94)
stats.BackgroundTransparency = 1
stats.Text = "Parry: 0 | Ping: 0 ms"
stats.TextColor3 = Color3.fromRGB(160, 160, 190)
stats.TextXAlignment = Enum.TextXAlignment.Left
stats.Font = Enum.Font.Gotham
stats.TextSize = 12
stats.Parent = body

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -24, 0, 20)
hint.Position = UDim2.fromOffset(12, 120)
hint.BackgroundTransparency = 1
hint.Text = "Tekan RightShift untuk sembunyikan UI"
hint.TextColor3 = Color3.fromRGB(110, 110, 140)
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Font = Enum.Font.Gotham
hint.TextSize = 11
hint.Parent = body

----------------------------------------------------------------
-- UI INTERAKSI
----------------------------------------------------------------
local function refreshToggle()
    if State.Enabled then
        toggle.Text = "Auto Parry: ON"
        toggle.BackgroundColor3 = Color3.fromRGB(50, 160, 80)
    else
        toggle.Text = "Auto Parry: OFF"
        toggle.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
    end
end

toggle.MouseButton1Click:Connect(function()
    State.Enabled = not State.Enabled
    refreshToggle()
end)

box.FocusLost:Connect(function()
    local value = tonumber(box.Text)
    if value and value > 0 and value < 3 then
        State.ParryTime = value
    end
    box.Text = tostring(State.ParryTime)
end)

local minimized = false
minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    body.Visible = not minimized
    main.Size = minimized and UDim2.fromOffset(260, 34) or UDim2.fromOffset(260, 190)
    minimize.Text = minimized and "+" or "-"
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        gui.Enabled = not gui.Enabled
    end
end)

-- Drag UI (mouse & touch)
do
    local dragging, dragStart, startPos
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

----------------------------------------------------------------
-- LOOP UTAMA
----------------------------------------------------------------
local conn = RunService.Heartbeat:Connect(checkBalls)

task.spawn(function()
    while gui.Parent do
        stats.Text = string.format("Parry: %d | Ping: %d ms",
            State.ParryCount, math.floor(getPing() * 1000))
        task.wait(0.5)
    end
    conn:Disconnect()
end)
