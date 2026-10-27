-- =======================================================
-- SCRIPT DE AUTO-HOP COM PAINEL VISUAL (DELTA MOBILE)
-- Jogo: Roube um Ovo (PlaceId: 17192317180)
-- =======================================================

local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1564694669072277584/KiYa8kkyJp_HYlIIp2EATBIvnHVhgrDixq9XIx4OtI6hEUD86e5CoOX4jIdcKMK8HEL3"
local PLACE_ID = game.PlaceId or 17192317180
local PESO_MINIMO_ALERTA = 50000 
local rodandoBot = true

-- -------------------------------------------------------
-- CRIAÇÃO DO PAINEL VISUAL (UI MOBILE)
-- -------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OvoDetectorPainel"
screenGui.Parent = CoreGui
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 160)
mainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true -- Permite arrastar o painel pela tela no celular
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 35)
titleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
titleLabel.Text = " 🥚 Caçador de Ovos 50k+"
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
statusLabel.Text = "Status: Procurando Ovos..."
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 128)
statusLabel.TextSize:eq = 13
statusLabel.TextSize = 13
statusLabel.Font = Enum.Font.SourceSansSemibold
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

-- -------------------------------------------------------
-- FUNÇÕES DE SEGURANÇA E LÓGICA
-- -------------------------------------------------------
local function esperarAleatorio(minimo, maximo)
    local tempo = math.random(minimo * 10, maximo * 10) / 10
    task.wait(tempo)
end

local function extrairNumero(texto)
    if not texto then return 0 end
    local limpo = string.gsub(texto, "[^%d]", "")
    return tonumber(limpo) or 0
end

local function monitorarServidor()
    if not rodandoBot then return end
    
    statusLabel.Text = "Status: Varrendo sala atual..."
    esperarAleatorio(1.5, 2.5)

    local peso = 0
    local mult = 1.0
    local nome = "Ovo Desconhecido"
    local ovoEncontrado = nil

    pcall(function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and (string.find(string.lower(obj.Name), "egg") or string.find(string.lower(obj.Name), "ovo")) then
                ovoEncontrado = obj
                nome = obj.Name
                
                peso = obj:GetAttribute("Weight") or obj:GetAttribute("Peso") or 0
                mult = obj:GetAttribute("Multiplier") or obj:GetAttribute("Multiplicador") or 1.0
                
                if peso == 0 then
                    for _, child in pairs(obj:GetDescendants()) do
                        if child:IsA("TextLabel") then
                            local txt = child.Text
                            if string.find(string.lower(txt), "kg") or string.find(string.lower(txt), "peso") then
                                peso = extrairNumero(txt)
                            end
                        end
                    end
                end
                
                if peso > 0 then break end
            end
        end
    end)

    if peso >= PESO_MINIMO_ALERTA then
        statusLabel.Text = "🚨 OVO GIGANTE ACHADO! Enviando..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        
        pcall(function()
            local mensagem = {
                ["embeds"] = {{
                    ["title"] = "🚨 OVO GIGANTE DETECTADO (AUTO-BOT) 🚨",
                    ["color"] = 65438,
                    ["fields"] = {
                        {["name"] = "Nome do Ovo", ["value"] = "`" .. nome .. "`", ["inline"] = true},
                        {["name"] = "Multiplicador", ["value"] = "`x" .. tostring(mult) .. "`", ["inline"] = true},
                        {["name"] = "Peso Atual", ["value"] = "`" .. tostring(peso) .. " KG`", ["inline"] = false},
                        {["name"] = "👉 ENTRAR NO SERVIDOR", ["value"] = "[Clique Aqui para Pegar](https://roblox.com" .. PLACE_ID .. "?launchData=" .. game.JobId .. ")", ["inline"] = false}
                    }
                }}
            }

            local req = (syn and syn.request) or (http and http.request) or http_request or request
            if req then
                req({
                    Url = DISCORD_WEBHOOK_URL,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode(mensagem)
                })
            end
        end)
    else
        statusLabel.Text = "Status: Nenhum ovo 50k+ aqui."
        statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end

    esperarAleatorio(3.5, 5.5)

    if not rodandoBot then return end
    statusLabel.Text = "Status: Trocando de servidor..."

    pcall(function()
        local urlAPI = "https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/Public?sortOrder=Asc&limit=100"
        local resposta = game:HttpGet(urlAPI)
        local decodificado = HttpService:JSONDecode and HttpService:JSONDecode(resposta)
        
        if decodificado and decodificado.data then
            for _, servidor in pairs(decodificado.data) do
                if servidor.id ~= game.JobId and servidor.playing < servidor.maxPlayers then
                    TeleportService:TeleportToPlaceInstance(PLACE_ID, servidor.id, Players.LocalPlayer)
                    break
                end
            end
        end
    end)
end

-- Loop contínuo de varredura e troca de servidores
task.spawn(function()
    while true do
        if rodandoBot then
            pcall(monitorarServidor)
        end
        task.wait(1)
    end
end)
