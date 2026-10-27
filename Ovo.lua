--==================================================--
-- CAÇADOR DE OVOS GIGANTES (Delta Mobile)
-- Só considera ovos com peso >= PESO_MINIMO (milhões)
--==================================================--

local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local PLACE_ID = game.PlaceId
local PESO_MINIMO = 1000000      -- 1 milhão. Mude aqui (ex: 5000000)
local SCRIPT_URL = "https://raw.githubusercontent.com/dan882877-commits/Roube-um-ovo/refs/heads/main/Ovo.lua"
local rodandoBot = true
local ovoAlvo = nil

-- Se rodar de novo no novo servidor, evita duplicar o painel
local guiParent = (gethui and gethui()) or game:GetService("CoreGui")
local antigo = guiParent:FindFirstChild("OvoDetectorPainel")
if antigo then antigo:Destroy() end

if SCRIPT_URL ~= "" and queue_on_teleport then
    queue_on_teleport(('loadstring(game:HttpGet("%s"))()'):format(SCRIPT_URL))
end

--========== UI ==========--
local gui = Instance.new("ScreenGui")
gui.Name = "OvoDetectorPainel"
gui.ResetOnSpawn = false
gui.Parent = guiParent

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 160)
frame.Position = UDim2.new(0.05, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.Text = "Ovos Gigantes (1M+)"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 14
title.Font = Enum.Font.SourceSansBold
title.Parent = frame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 50)
status.Position = UDim2.new(0, 10, 0, 45)
status.BackgroundTransparency = 1
status.Text = "Status: Iniciando..."
status.TextColor3 = Color3.fromRGB(0, 255, 128)
status.TextSize = 13
status.Font = Enum.Font.SourceSansSemibold
status.TextWrapped = true
status.Parent = frame

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, -20, 0, 35)
btn.Position = UDim2.new(0, 10, 0, 105)
btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
btn.Text = "Pausar Bot"
btn.TextColor3 = Color3.new(1, 1, 1)
btn.TextSize = 14
btn.Font = Enum.Font.SourceSansBold
btn.Parent = frame
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

local function setStatus(txt, cor)
    status.Text = "Status: " .. txt
    status.TextColor3 = cor or Color3.fromRGB(0, 255, 128)
end

btn.MouseButton1Click:Connect(function()
    rodandoBot = not rodandoBot
    btn.Text = rodandoBot and "Pausar Bot" or "Ativar Bot"
    btn.BackgroundColor3 = rodandoBot and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(50, 200, 50)
    setStatus(rodandoBot and "Reativado" or "Pausado", Color3.fromRGB(255, 200, 0))
end)

--========== LEITURA DE PESO ==========--
-- Converte "1.5M", "2,3B", "850K", "1500000" em número
local SUFIXOS = { K = 1e3, M = 1e6, B = 1e9, T = 1e12 }

local function parsePeso(texto)
    if type(texto) ~= "string" then return nil end
    texto = texto:gsub(",", ""):gsub("%s", "")
    local num, suf = texto:match("(%d+%.?%d*)([KkMmBbTt]?)")
    num = tonumber(num)
    if not num then return nil end
    return num * (SUFIXOS[suf:upper()] or 1)
end

local NOMES_PESO = { "peso", "weight", "size", "tamanho", "mass" }

local function lerPeso(obj)
    -- 1) Attributes
    for nome, valor in pairs(obj:GetAttributes()) do
        local n = nome:lower()
        for _, k in ipairs(NOMES_PESO) do
            if n:find(k) then
                local p = type(valor) == "number" and valor or parsePeso(tostring(valor))
                if p then return p end
            end
        end
    end
    -- 2) Values e textos (BillboardGui) dentro do ovo
    for _, d in ipairs(obj:GetDescendants()) do
        local n = d.Name:lower()
        if d:IsA("NumberValue") or d:IsA("IntValue") then
            for _, k in ipairs(NOMES_PESO) do
                if n:find(k) then return d.Value end
            end
        elseif d:IsA("StringValue") then
            for _, k in ipairs(NOMES_PESO) do
                if n:find(k) then
                    local p = parsePeso(d.Value)
                    if p then return p end
                end
            end
        elseif d:IsA("TextLabel") then
            local p = parsePeso(d.Text)
            if p and p >= 1000 then return p end
        end
    end
    return nil
end

--========== BUSCA DE OVOS ==========--
local function pareceOvo(obj)
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
    local n = obj.Name:lower()
    return n:find("ovo") or n:find("egg")
end

local function acharOvoGigante()
    local melhor, melhorPeso = nil, 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if pareceOvo(obj) then
            local peso = lerPeso(obj)
            if peso and peso >= PESO_MINIMO and peso > melhorPeso then
                melhor, melhorPeso = obj, peso
            end
        end
    end
    return melhor, melhorPeso
end

local function irAteOvo(ovo)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local cf = ovo:IsA("Model") and ovo:GetPivot() or ovo.CFrame
    root.CFrame = cf + Vector3.new(0, 4, 0)
end

--========== SERVER HOP ==========--
local function alternarServidor()
    setStatus("Trocando de servidor...", Color3.fromRGB(255, 150, 0))
    local ok, err = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. PLACE_ID
            .. "/servers/Public?sortOrder=Desc&limit=100"
        local resp = game:HttpGet(url)
        local data = HttpService:JSONDecode(resp)
        local lista = {}
        for _, s in ipairs(data.data or {}) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                table.insert(lista, s.id)
            end
        end
        if #lista == 0 then error("nenhum servidor livre") end
        TeleportService:TeleportToPlaceInstance(PLACE_ID, lista[math.random(#lista)], player)
        task.wait(10)
    end)
    if not ok then
        setStatus("Erro: " .. tostring(err), Color3.fromRGB(255, 80, 80))
        task.wait(4)
    end
end

--========== LOOP PRINCIPAL ==========--
task.spawn(function()
    while task.wait(2) do
        if rodandoBot then
            -- Já achou? Fica no ovo e não troca mais de sala
            if ovoAlvo and ovoAlvo.Parent then
                irAteOvo(ovoAlvo)
                setStatus("Ovo gigante alvo! Fique aqui.", Color3.fromRGB(255, 215, 0))
            else
                ovoAlvo = nil
                setStatus("Procurando ovo gigante...")
                task.wait(3) -- espera o mapa carregar
                local ovo, peso = acharOvoGigante()
                if ovo then
                    ovoAlvo = ovo
                    setStatus(("GIGANTE achado! Peso: %s"):format(tostring(peso)), Color3.fromRGB(255, 215, 0))
                    irAteOvo(ovo)
                else
                    alternarServidor()
                end
            end
        end
    end
end)
