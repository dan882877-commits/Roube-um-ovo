--==================================================--
-- CAÇADOR DE OVOS GIGANTES (Delta Mobile)
-- Só aceita ovos eterno/divino/secreto (lista TIPOS) com peso >= PESO_MINIMO
--==================================================--

local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local inicioServidor = os.clock()

-- Evita ser expulso por inatividade enquanto espera
pcall(function()
    local VirtualUser = game:GetService("VirtualUser")
    player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(4)

local PLACE_ID = game.PlaceId
local PESO_MINIMO = 1000000   -- em kg. Raro abaixo disso e considerado "pequeno" e troca de servidor
local MIN_JOGADORES = 1       -- servidor com pelo menos 1 pessoa
local MAX_JOGADORES = 5       -- e no maximo 5 (servidor vazio)
local ESPERAR_SEGUNDOS = 0    -- sem ovo raro: 0 = fica no servidor esperando spawn. Ex: 600 = troca apos 10 min

-- Tipos aceitos (procura no nome/texto do ovo). Deixe {} para aceitar qualquer tipo.
local TIPOS = { "eternal", "eterno", "divine", "divino", "secret", "secreto", "whale", "baleia" }
local SCRIPT_URL = "https://raw.githubusercontent.com/dan882877-commits/Roube-um-ovo/refs/heads/main/Ovo.lua"
local WEBHOOK = ""   -- cole aqui o link do webhook do Discord (opcional)
local rodandoBot = true
local ovoAlvo = nil
local posOvo = nil

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
title.Text = "Caçador de Ovos Raros"
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
    texto = texto:lower():gsub("kg", ""):gsub(",", ""):gsub("%s", "")
    local num, suf = texto:match("(%d+%.?%d*)([kmbt]?)")
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
        elseif d:IsA("TextLabel") and d.Text:lower():find("kg") then
            local p = parsePeso(d.Text)
            if p then return p end
        end
    end
    return nil
end

--========== BUSCA DE OVOS ==========--
-- true se o ovo ja foi pego por algum jogador (mao, mochila, personagem)
local function naMaoDeAlguem(obj)
    for _, pl in ipairs(Players:GetPlayers()) do
        if obj:IsDescendantOf(pl) then return true end
        if pl.Character and obj:IsDescendantOf(pl.Character) then return true end
    end
    return false
end

local function pareceOvo(obj)
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
    local n = obj.Name:lower()
    if not (n:find("ovo") or n:find("egg")) then return false end
    return not naMaoDeAlguem(obj)
end

local maiorVisto = 0
local maiorInfo = ""

-- Junta nome, atributos e textos do ovo (ex: "Prehistoric Egg (Eternal) 2,536,813kg")
local function textoDoOvo(obj)
    local partes = { obj.Name }
    for nome, valor in pairs(obj:GetAttributes()) do
        table.insert(partes, nome .. " " .. tostring(valor))
    end
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("TextLabel") then
            table.insert(partes, d.Text)
        elseif d:IsA("StringValue") then
            table.insert(partes, d.Value)
        end
    end
    return table.concat(partes, " "):lower()
end

local function tipoAceito(texto)
    if #TIPOS == 0 then return true end
    for _, t in ipairs(TIPOS) do
        if texto:find(t, 1, true) then return true end
    end
    return false
end

local function acharOvoGigante()
    local melhor, melhorPeso = nil, 0
    local raroPequeno = false
    maiorVisto, maiorInfo = 0, ""
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if pareceOvo(obj) then
            local peso = lerPeso(obj)
            if peso then
                local texto = textoDoOvo(obj)
                if peso > maiorVisto then
                    maiorVisto = peso
                    maiorInfo = texto:sub(1, 40)
                end
                if tipoAceito(texto) then
                    if peso >= PESO_MINIMO then
                        if peso > melhorPeso then melhor, melhorPeso = obj, peso end
                    else
                        raroPequeno = true
                    end
                end
            end
        end
    end
    return melhor, melhorPeso, raroPequeno
end

local function irAteOvo(ovo)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local cf = ovo:IsA("Model") and ovo:GetPivot() or ovo.CFrame
    root.CFrame = cf + Vector3.new(0, 4, 0)
end

local function posDoOvo(ovo)
    return ovo:IsA("Model") and ovo:GetPivot().Position or ovo.Position
end

--========== SERVER HOP ==========--
local function alternarServidor()
    setStatus(("Maior: %s kg [%s]. Trocando..."):format(tostring(maiorVisto), maiorInfo), Color3.fromRGB(255, 150, 0))
    local ok, err = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. PLACE_ID
            .. "/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100"
        local data = HttpService:JSONDecode(game:HttpGet(url))
        local lista = {}
        for _, s in ipairs(data.data or {}) do
            if s.playing and s.id ~= game.JobId
                and s.playing >= MIN_JOGADORES
                and s.playing <= MAX_JOGADORES then
                table.insert(lista, s.id)
            end
        end
        if #lista == 0 then error("sem servidor com " .. MIN_JOGADORES .. "-" .. MAX_JOGADORES .. " jogadores") end
        TeleportService:TeleportToPlaceInstance(PLACE_ID, lista[math.random(#lista)], player)
        task.wait(10)
    end)
    if not ok then
        setStatus("Falhou: " .. tostring(err), Color3.fromRGB(255, 80, 80))
        task.wait(3)
        pcall(function() TeleportService:Teleport(PLACE_ID, player) end)
        task.wait(10)
    end
end

--========== AVISO NO DISCORD ==========--
local function avisarDiscord(peso)
    if WEBHOOK == "" then return end
    local link = ("https://www.roblox.com/games/start?placeId=%d&gameInstanceId=%s")
        :format(PLACE_ID, game.JobId)
    local req = request or http_request or (syn and syn.request)
    if not req then return end
    pcall(function()
        req({
            Url = WEBHOOK,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({
                content = ("🥚 Ovo gigante: %s kg\nEntrar no servidor: %s"):format(tostring(peso), link)
            })
        })
    end)
end

--========== LOOP PRINCIPAL ==========--
task.spawn(function()
    while task.wait(2) do
        if rodandoBot then
            if ovoAlvo then
                -- Achou gigante: fica parado ate o ovo sumir ou ser roubado
                local ok = ovoAlvo.Parent ~= nil
                    and not naMaoDeAlguem(ovoAlvo)
                    and (posDoOvo(ovoAlvo) - posOvo).Magnitude < 40
                if ok then
                    setStatus("Ovo gigante aqui! Pegue ele.", Color3.fromRGB(255, 215, 0))
                else
                    ovoAlvo = nil
                    setStatus("Ovo roubado/sumiu! Procurando outro...", Color3.fromRGB(255, 80, 80))
                    task.wait(2)
                end
            else
                setStatus("Procurando ovo raro...")
                task.wait(3)
                local ovo, peso, raroPequeno = acharOvoGigante()
                if ovo then
                    -- raro E gigante: para aqui
                    ovoAlvo = ovo
                    posOvo = posDoOvo(ovo)
                    setStatus(("GIGANTE achado! %s kg"):format(tostring(peso)), Color3.fromRGB(255, 215, 0))
                    irAteOvo(ovo)
                    avisarDiscord(peso)
                elseif raroPequeno then
                    -- raro mas pequeno: troca de servidor para rerolar o peso
                    setStatus(("Raro pequeno (%s kg). Trocando..."):format(tostring(maiorVisto)), Color3.fromRGB(255, 150, 0))
                    alternarServidor()
                else
                    -- nenhum raro: fica no servidor esperando spawn
                    local esperou = os.clock() - inicioServidor
                    if ESPERAR_SEGUNDOS > 0 and esperou >= ESPERAR_SEGUNDOS then
                        alternarServidor()
                    else
                        setStatus(("Nenhum raro aqui. Aguardando spawn... (%ds)"):format(math.floor(esperou)), Color3.fromRGB(0, 200, 255))
                        task.wait(5)
                    end
                end
            end
        end
    end
end)
