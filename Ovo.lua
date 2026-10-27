--==================================================--
-- SCRIPT DE AUTO-HOP COM PAINEL VISUAL (DELTA MOBILE)
-- Jogo: Roube um Ovo (PlaceId: 1719231710)
--==================================================--

local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local DISCORD_WEBHOOK_URL = "https://discord.com"
local PLACE_ID = game.PlaceId or 1719231710
local PESO_MINIMO_ALERTA = 50000
local rodandoBot = true

-- CRIAÇÃO DO PAINEL VISUAL (UI MOBILE)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OvoDetectorPainel"
screenGui.Parent = CoreGui
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 160)
mainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BackgroundTransparency = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 35)
titleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
titleLabel.Text = "Caçador de Ovos 50k+"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleLabel

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 40)
statusLabel.Position = UDim2.new(0, 10, 0, 45)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Iniciando..."
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 128)
statusLabel.TextSize = 13
statusLabel.Font = Enum.Font.SourceSansSemiBold
statusLabel.TextWrapped = true
statusLabel.Parent = mainFrame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -20, 0, 35)
toggleButton.Position = UDim2.new(0, 10, 0, 105)
toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
toggleButton.Text = "Desativar Bot"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 14
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = toggleButton

-- Botão de Ligar/Desligar
toggleButton.MouseButton1Click:Connect(function()
    rodandoBot = not rodandoBot
    if rodandoBot then
        toggleButton.Text = "Desativar Bot"
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        statusLabel.Text = "Status: Bot Reativado!"
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 128)
    else
        toggleButton.Text = "Ativar Bot"
        toggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        statusLabel.Text = "Status: Bot Pausado."
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)

-- FUNÇÕES DE SEGURANÇA E LÓGICA DO SERVER HOP

local function alternarServidor()
    statusLabel.Text = "Status: Procurando novo servidor..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
    task.wait(1)
    
    local x = pcall(function()
        local sfUrl = "https://roblox.com" .. PLACE_ID .. "/servers/Public?sortOrder=Desc&limit=100"
        local req = HttpService:JSONDecode(game:HttpGet(sfUrl))
        local servidores = req and req.data
        if servidores then
            for _, s in pairs(servidores) do
                if s.playing and s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(PLACE_ID, s.id, Players.LocalPlayer)
                    return
                end
            end
        end
    end)
    
    if not x then
        statusLabel.Text = "Erro ao trocar de sala. Tentando novamente..."
        task.wait(3)
        TeleportService:Teleport(PLACE_ID, Players.LocalPlayer)
    end
end

-- LOOP PRINCIPAL DE VARREDURA
task.spawn(function()
    while task.wait(2) do
        if rodandoBot then
            statusLabel.Text = "Status: Procurando ovos na sala..."
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 128)
            
            -- Procura por ovos no Workspace (Altere "Ovos" se o nome do grupo no jogo for diferente)
            local ovosFolder = Workspace:FindFirstChild("Ovos") or Workspace:FindFirstChild("Eggs")
            local ovoEncontrado = false
            
            if ovosFolder then
                for _, ovo in pairs(ovosFolder:GetChildren()) do
                    -- Se encontrar algum ovo grande ou valioso baseado no nome/peso
                    if ovo:IsA("BasePart") or ovo:FindFirstChildOfClass("TouchTransmitter") then
                        ovoEncontrado = true
                        statusLabel.Text = "Status: Ovo detectado! Teleportando..."
                        -- Teleporta o jogador até o ovo
                        local root = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if root then
                            root.CFrame = ovo.CFrame
                            task.wait(1)
                        end
                    end
                end
            end
            
            -- Se varreu o mapa e não achou ovos, faz o Server Hop automaticamente
            if not ovoEncontrado then
                statusLabel.Text = "Status: Nenhum ovo bom. Mudando de sala..."
                task.wait(1.5)
                alternarServidor()
            end
        end
    end
end)
