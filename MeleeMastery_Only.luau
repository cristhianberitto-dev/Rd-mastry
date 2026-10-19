-- Melee Mastery Farm - interface independente
-- Contem apenas: toggle do farm + controle de altura.
-- Alvos/quests por Sea baseados nas configuracoes publicas do Redz Hub V2.
-- Nao carrega nem executa as outras funcoes do Redz Hub.

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Enemies = workspace:WaitForChild("Enemies")
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

local oldGui
local guiParent
if type(gethui) == "function" then
    local ok, result = pcall(gethui)
    if ok then guiParent = result end
end
guiParent = guiParent or PlayerGui
oldGui = guiParent:FindFirstChild("MeleeMasteryOnlyUI")
if oldGui then oldGui:Destroy() end

local Configs = {
    [2753915549] = {
        SeaName = "Sea 1",
        Enemies = {"Galley Captain"},
        QuestName = "FountainQuest",
        QuestIndex = 2,
        QuestPosition = CFrame.new(5258, 39, 4052),
        SpawnPoints = {
            CFrame.new(5985, 70, 4790),
            CFrame.new(5472, 70, 4887)
        }
    },
    [4442272183] = {
        SeaName = "Sea 2",
        Enemies = {"Water Fighter"},
        QuestName = "ForgottenQuest",
        QuestIndex = 2,
        QuestPosition = CFrame.new(-3056, 240, -10145),
        SpawnPoints = {
            CFrame.new(-3339, 290, -10412),
            CFrame.new(-3518, 290, -10419),
            CFrame.new(-3536, 290, -10607),
            CFrame.new(-3345, 280, -10667)
        }
    },
    [7449423635] = {
        SeaName = "Sea 3",
        Enemies = {"Isle Champion"},
        QuestName = "TikiQuest2",
        QuestIndex = 2,
        QuestPosition = CFrame.new(-16540, 56, 1051),
        SpawnPoints = {
            CFrame.new(-16634, 85, 1106),
            CFrame.new(-16735, 60, 1075),
            CFrame.new(-16888, 35, 1011)
        }
    }
}
local Config = Configs[game.PlaceId]

local Enabled = false
local Height = 35
local LoopToken = 0
local lastQuestStart = 0
local spawnIndex = 1
local lastSpawnMove = 0
local lastClick = 0

local function Make(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local GUI = Make("ScreenGui", {
    Name = "MeleeMasteryOnlyUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, guiParent)

local Main = Make("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(286, 190),
    Position = UDim2.new(0.5, -143, 0.48, -95),
    BackgroundColor3 = Color3.fromRGB(20, 23, 31),
    BorderSizePixel = 0,
    Active = true
}, GUI)
Make("UICorner", {CornerRadius = UDim.new(0, 10)}, Main)
Make("UIStroke", {Color = Color3.fromRGB(75, 96, 130), Thickness = 1}, Main)

local Header = Make("TextLabel", {
    Name = "Header",
    Size = UDim2.new(1, -18, 0, 32),
    Position = UDim2.fromOffset(12, 5),
    BackgroundTransparency = 1,
    Text = "MELEE MASTERY FARM",
    TextColor3 = Color3.fromRGB(115, 210, 255),
    TextSize = 15,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, Main)

local Status = Make("TextLabel", {
    Name = "Status",
    Size = UDim2.new(1, -24, 0, 22),
    Position = UDim2.fromOffset(12, 38),
    BackgroundTransparency = 1,
    Text = Config and (Config.SeaName .. " detectado") or "Sea nao reconhecido",
    TextColor3 = Config and Color3.fromRGB(170, 180, 195) or Color3.fromRGB(255, 120, 120),
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left
}, Main)

local Toggle = Make("TextButton", {
    Name = "FarmToggle",
    Size = UDim2.new(1, -24, 0, 38),
    Position = UDim2.fromOffset(12, 66),
    BackgroundColor3 = Color3.fromRGB(42, 48, 61),
    BorderSizePixel = 0,
    Text = "Melee Mastery Farm: OFF",
    TextColor3 = Color3.fromRGB(240, 244, 250),
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = true
}, Main)
Make("UICorner", {CornerRadius = UDim.new(0, 7)}, Toggle)

local HeightText = Make("TextLabel", {
    Name = "HeightLabel",
    Size = UDim2.new(1, -24, 0, 20),
    Position = UDim2.fromOffset(12, 112),
    BackgroundTransparency = 1,
    Text = "Altura acima do NPC: " .. Height,
    TextColor3 = Color3.fromRGB(220, 226, 236),
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left
}, Main)

local SliderBack = Make("Frame", {
    Name = "SliderBack",
    Size = UDim2.new(1, -24, 0, 10),
    Position = UDim2.fromOffset(12, 140),
    BackgroundColor3 = Color3.fromRGB(48, 56, 72),
    BorderSizePixel = 0
}, Main)
Make("UICorner", {CornerRadius = UDim.new(1, 0)}, SliderBack)
local SliderFill = Make("Frame", {
    Name = "SliderFill",
    Size = UDim2.new((Height - 10) / 140, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(75, 184, 245),
    BorderSizePixel = 0
}, SliderBack)
Make("UICorner", {CornerRadius = UDim.new(1, 0)}, SliderFill)
local SliderButton = Make("TextButton", {
    Name = "SliderButton",
    Size = UDim2.new(1, 0, 0, 28),
    Position = UDim2.new(0, 0, 0.5, -14),
    BackgroundTransparency = 1,
    Text = "",
    AutoButtonColor = false
}, SliderBack)

local Footer = Make("TextLabel", {
    Name = "Footer",
    Size = UDim2.new(1, -24, 0, 17),
    Position = UDim2.fromOffset(12, 161),
    BackgroundTransparency = 1,
    Text = "Somente esta funcao esta incluida",
    TextColor3 = Color3.fromRGB(125, 137, 157),
    TextSize = 9,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left
}, Main)

-- Arrastar a janela pelo cabecalho.
do
    local dragging = false
    local dragStart, startPosition
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = Main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function UpdateHeightFromX(screenX)
    local left = SliderBack.AbsolutePosition.X
    local width = math.max(SliderBack.AbsoluteSize.X, 1)
    local alpha = math.clamp((screenX - left) / width, 0, 1)
    Height = math.clamp(math.floor(10 + alpha * 140 + 0.5), 10, 150)
    SliderFill.Size = UDim2.new((Height - 10) / 140, 0, 1, 0)
    HeightText.Text = "Altura acima do NPC: " .. Height
end

local sliderDragging = false
SliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
        UpdateHeightFromX(input.Position.X)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateHeightFromX(input.Position.X)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
    end
end)

local function GetCharacterParts()
    local character = Player.Character
    if not character then return nil, nil, nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0 then return nil, nil, nil end
    return character, humanoid, root
end

local function IsTargetName(name)
    if not Config then return false end
    return table.find(Config.Enemies, name) ~= nil
end

local function GetTarget()
    local _, _, playerRoot = GetCharacterParts()
    if not playerRoot then return nil end
    local best, bestDistance = nil, math.huge
    for _, enemy in ipairs(Enemies:GetChildren()) do
        if IsTargetName(enemy.Name) then
            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
            local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
            if humanoid and humanoid.Health > 0 and root then
                local distance = (playerRoot.Position - root.Position).Magnitude
                if distance < bestDistance then
                    best, bestDistance = enemy, distance
                end
            end
        end
    end
    return best
end

local function GetQuestText()
    local ok, visible, titleText = pcall(function()
        local main = Player:FindFirstChild("PlayerGui") and Player.PlayerGui:FindFirstChild("Main")
        local quest = main and main:FindFirstChild("Quest")
        local title = quest and quest:FindFirstChild("Container")
            and quest.Container:FindFirstChild("QuestTitle")
            and quest.Container.QuestTitle:FindFirstChild("Title")
        return quest and quest.Visible or false, title and title.Text or ""
    end)
    if not ok then return false, "" end
    return visible, titleText
end

local function HasCorrectQuest()
    local visible, title = GetQuestText()
    if not visible then return false end
    title = string.lower(string.gsub(title, "-", ""))
    for _, name in ipairs(Config.Enemies) do
        if string.find(title, string.lower(string.gsub(name, "-", "")), 1, true) then
            return true
        end
    end
    return false
end

local function MoveTo(cf)
    local _, _, root = GetCharacterParts()
    if not root then return end
    if (root.Position - cf.Position).Magnitude > 7 then
        root.CFrame = cf
    end
end

local function EquipMelee()
    local character, humanoid = GetCharacterParts()
    if not character or not humanoid then return false end
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == "Melee" then
            return true
        end
    end
    for _, tool in ipairs(Player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == "Melee" then
            pcall(function() humanoid:EquipTool(tool) end)
            return true
        end
    end
    return false
end

local function EnableHaki()
    local character = Player.Character
    if character and not character:FindFirstChild("HasBuso") then
        pcall(function() CommF:InvokeServer("Buso") end)
    end
end

local function ClickAttack()
    if os.clock() - lastClick < 0.12 then return end
    lastClick = os.clock()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(math.huge, math.huge))
    end)
    task.delay(0.08, function()
        pcall(function() VirtualUser:Button1Up(Vector2.new(math.huge, math.huge)) end)
    end)
end

local function EnlargeAndGroup(target)
    local targetRoot = target and (target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart)
    if not targetRoot then return end
    pcall(function()
        targetRoot.Size = Vector3.new(50, 50, 50)
        targetRoot.CanCollide = false
    end)
    if type(sethiddenproperty) == "function" then
        pcall(sethiddenproperty, Player, "SimulationRadius", math.huge)
    end
    for _, enemy in ipairs(Enemies:GetChildren()) do
        if enemy ~= target and IsTargetName(enemy.Name) then
            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
            local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
            if humanoid and humanoid.Health > 0 and root and (root.Position - targetRoot.Position).Magnitude < 350 then
                pcall(function()
                    root.CFrame = targetRoot.CFrame
                    root.Size = Vector3.new(50, 50, 50)
                    root.CanCollide = false
                    humanoid.WalkSpeed = 0
                    humanoid.JumpPower = 0
                end)
            end
        end
    end
end

local function FarmLoop(token)
    if not Config then
        Enabled = false
        Toggle.Text = "Melee Mastery Farm: OFF"
        Toggle.BackgroundColor3 = Color3.fromRGB(42, 48, 61)
        Status.Text = "Sea nao reconhecido"
        return
    end

    Status.Text = Config.SeaName .. " | Alvo: " .. Config.Enemies[1]
    while Enabled and token == LoopToken do
        task.wait(0.12)
        local character, humanoid, root = GetCharacterParts()
        if character and humanoid and root then
            if not HasCorrectQuest() then
                local visible = GetQuestText()
                if visible then
                    if os.clock() - lastQuestStart > 2 then
                        pcall(function() CommF:InvokeServer("AbandonQuest") end)
                        lastQuestStart = os.clock()
                    end
                else
                    MoveTo(Config.QuestPosition)
                    if (root.Position - Config.QuestPosition.Position).Magnitude <= 8 and os.clock() - lastQuestStart > 2 then
                        pcall(function() CommF:InvokeServer("StartQuest", Config.QuestName, Config.QuestIndex) end)
                        lastQuestStart = os.clock()
                    end
                end
            else
                local target = GetTarget()
                if target then
                    local targetRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
                    if targetRoot then
                        local desired = targetRoot.CFrame + Vector3.new(0, Height, 0)
                        MoveTo(desired)
                        EquipMelee()
                        EnableHaki()
                        EnlargeAndGroup(target)
                        ClickAttack()
                    end
                else
                    if os.clock() - lastSpawnMove > 2.5 then
                        spawnIndex = (spawnIndex % #Config.SpawnPoints) + 1
                        MoveTo(Config.SpawnPoints[spawnIndex])
                        lastSpawnMove = os.clock()
                    end
                end
            end
        end
    end
end

Toggle.Activated:Connect(function()
    if not Config then
        Status.Text = "Entre no Sea 1, Sea 2 ou Sea 3"
        return
    end
    Enabled = not Enabled
    if Enabled then
        LoopToken += 1
        local myToken = LoopToken
        Toggle.Text = "Melee Mastery Farm: ON"
        Toggle.BackgroundColor3 = Color3.fromRGB(26, 123, 91)
        Status.Text = "Iniciando farm..."
        task.spawn(FarmLoop, myToken)
    else
        LoopToken += 1
        Toggle.Text = "Melee Mastery Farm: OFF"
        Toggle.BackgroundColor3 = Color3.fromRGB(42, 48, 61)
        Status.Text = Config.SeaName .. " | Farm pausado"
    end
end)

Player.CharacterAdded:Connect(function()
    task.wait(1)
    if Enabled then
        LoopToken += 1
        local myToken = LoopToken
        task.spawn(FarmLoop, myToken)
    end
end)

print("Melee Mastery Farm UI carregada. Somente uma opcao esta incluida.")
