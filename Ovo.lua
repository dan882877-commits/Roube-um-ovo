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
local SCRIPT_URL = ""            -- link raw do seu GitHub (reinicia após o hop)
local rodandoBot = true
local ovoAlvo = nil

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
title.BackgroundColor3 = Color3.fr
