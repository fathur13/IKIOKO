-- =============================================
--   AUTO SAMBUNG KATA V14 - PERFECT FIX
--   ✅ MENGIKUTI 100% HURUF YANG DIKETIK ✅ Saran+Killer RANDOM
-- =============================================

print = function() end
warn = function() end

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Remotes = RS:WaitForChild("Remotes")

local CONFIG = { MIN_LENGTH = 3 }
local customSuffix = {}

-- =============================================
--   WORDLIST
-- =============================================
local byPrefix = {}
local totalWords = 0

local function indexWord(word)
    for len = 1, #word do
        local prefix = word:sub(1, len)
        if not byPrefix[prefix] then byPrefix[prefix] = {} end
        table.insert(byPrefix[prefix], word)
    end
    totalWords = totalWords + 1
end

-- Load wordlist
spawn(function()
    pcall(function()
        local res = game:HttpGet("https://raw.githubusercontent.com/fathur13/IKIOKO/refs/heads/main/MasterWordList.txt")
        for w in res:gmatch("[^\r\n]+") do
            local wc = w:lower():gsub("%s+", "")
            if wc:match("^%a+$") and #wc >= CONFIG.MIN_LENGTH then indexWord(wc) end
        end
    end)
end)

local BUILTIN = {"aktif","pasif","positif","negatif","tif","ksa","nd","ks","pt","mp","nt","identifikasi","kompetitif","kreatif","motif","adaptif","naratif","formatif"}
for _, w in ipairs(BUILTIN) do indexWord(w:lower()) end

local KILLER_SUFFIXES = {"cis","dot","tif","if","ksa","iki","nd","ks","pt","mp","nt","ax","ex","ox","oo","ty","th","ly","lt","gn","gr","gh","ei","eo","eu","ch","dh","ipe","iya", "ia", "sih", "owa"}

-- ✅ SARAN - MENGIKUTI LENGKAP PREFIX
local function getSuggestions(prefix, count)
    prefix = prefix:lower():gsub("%s+", "")
    local suggestions = {}
    if #prefix == 0 then return suggestions end

    local candidates = byPrefix[prefix]
    local prioritized = {}
    local fallback = {}

    if candidates then
        for _, word in ipairs(candidates) do
            if word:sub(1, #prefix) == prefix then

                -- cek suffix match
                local matchSuffix = (#customSuffix == 0)

                for _, suf in ipairs(customSuffix) do
                    if word:sub(-#suf) == suf then
                        matchSuffix = true
                        break
                    end
                end

                if matchSuffix then
                    table.insert(prioritized, word)
                else
                    table.insert(fallback, word)
                end
            end
        end
    end

    -- kalau PRIORITAS kosong → fallback dipakai semua
    local pool = {}

    if #prioritized > 0 then
        pool = prioritized
    else
        pool = fallback
    end

    -- shuffle random
    for i = #pool, 2, -1 do
        local j = math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end

    local results = {}
    for i = 1, math.min(count, #pool) do
        results[i] = pool[i]
    end

    return results
end

-- ✅ KILLER - MENGIKUTI LENGKAP PREFIX
local function getKillerSuggestions(prefix, count)
    prefix = prefix:lower():gsub("%s+", "")
    if #prefix == 0 then return {} end

    local pool = {}
    local candidates = byPrefix[prefix]

    if candidates then
        for _, word in ipairs(candidates) do
            for _, suf in ipairs(KILLER_SUFFIXES) do
                if word:sub(-#suf) == suf then
                    pool[#pool + 1] = word
                    break
                end
            end
        end
    end

    -- shuffle
    for i = #pool, 2, -1 do
        local j = math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end

    local results = {}
    for i = 1, math.min(count, #pool) do
        results[i] = pool[i]
    end

    return results
end

-- =============================================
--   UI
-- =============================================
local ITEM_H, ITEM_GAP = 30, 34
local UI = nil
local minimized = false

local function createUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoKataUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = LocalPlayer.PlayerGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 520, 0, 300)
    MainFrame.Position = UDim2.new(0, 20, 0, 20)
    MainFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
    MainFrame.BackgroundTransparency = 0.3
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", MainFrame)
    stroke.Color = Color3.fromRGB(70, 200, 220); stroke.Thickness = 1.5

    -- Header
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 44)
    Header.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    Header.Parent = MainFrame
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

    local Title = Instance.new("TextLabel", Header)
    Title.Size = UDim2.new(1, -120, 1, 0)
    Title.Position = UDim2.new(0, 14, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "V14 PERFECT - 100% MENGIKUTI KETIKAN"
    Title.TextColor3 = Color3.fromRGB(70, 220, 220)
    Title.TextSize = 14
    Title.Font = Enum.Font.GothamBold

    local MinBtn = Instance.new("TextButton", Header)
    MinBtn.Size = UDim2.new(0, 28, 0, 28)
    MinBtn.Position = UDim2.new(1, -90, 0, 8)
    MinBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    MinBtn.Text = "-"
    MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.BorderSizePixel = 0
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

    local CloseBtn = Instance.new("TextButton", Header)
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -34, 0, 8)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(190, 55, 55)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.BorderSizePixel = 0
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

    local divider = Instance.new("Frame", MainFrame)
    divider.Size = UDim2.new(0, 1, 1, -50)
    divider.Position = UDim2.new(0, 240, 0, 48)
    divider.BackgroundColor3 = Color3.fromRGB(40, 40, 55)

    local function makeCard(parent, xOffset, panelW, yPos, h)
        local f = Instance.new("Frame", parent)
        f.Size = UDim2.new(0, panelW - 24, 0, h or ITEM_H)
        f.Position = UDim2.new(0, xOffset + 12, 0, yPos)
        f.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
        f.BackgroundTransparency = 0.4
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 7)
        return f
    end

    local function makeLabel(parent, text, color, size)
        local lbl = Instance.new("TextLabel", parent)
        lbl.Size = UDim2.new(1, -10, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = color or Color3.fromRGB(210, 210, 210)
        lbl.TextSize = size or 11
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        return lbl
    end

    -- LEFT: SARAN
    local LEFT_W = 240
    local Content = Instance.new("ScrollingFrame", MainFrame)
    Content.Size = UDim2.new(0, LEFT_W, 1, -44)
    Content.Position = UDim2.new(0, 0, 0, 44)
    Content.BackgroundTransparency = 1
    Content.ScrollBarThickness = 4
    Content.ScrollBarImageColor3 = Color3.fromRGB(70, 180, 110)
    Content.Parent = MainFrame

    local StatusLbl = makeLabel(makeCard(Content, 0, LEFT_W, 8, 26), "Loading...", Color3.fromRGB(140, 140, 165), 11)

    local PrefixLbl = makeLabel(makeCard(Content, 0, LEFT_W, 40, 26), "Prefix: -", Color3.fromRGB(255, 195, 70), 14)
    PrefixLbl.Font = Enum.Font.GothamBold
    -- INPUT SUFFIX MANUAL
    local SuffixBox = Instance.new("TextBox", makeCard(Content, 0, LEFT_W, 70, 26))
    SuffixBox.Size = UDim2.new(1, -10, 1, 0)
    SuffixBox.Position = UDim2.new(0, 10, 0, 0)
    SuffixBox.BackgroundTransparency = 1
    SuffixBox.PlaceholderText = "Akhiran... (contoh: an, if, ks)"
    SuffixBox.Text = ""
    SuffixBox.TextColor3 = Color3.fromRGB(200, 200, 255)
    SuffixBox.TextSize = 12
    SuffixBox.Font = Enum.Font.Gotham
    SuffixBox.TextXAlignment = Enum.TextXAlignment.Left

    SuffixBox:GetPropertyChangedSignal("Text"):Connect(function()
        local raw = SuffixBox.Text:lower()
        customSuffix = {}

        for s in raw:gmatch("[^,]+") do
            local clean = s:gsub("%s+", "")
            if clean ~= "" then
                table.insert(customSuffix, clean)
            end
        end

        -- 🔥 FORCE UPDATE
        lastPrefix = ""
    end)

    local SaranLabels = {}
    for i = 1, 12 do
        local yPos = 100 + (i - 1) * ITEM_GAP
        local lbl = makeLabel(makeCard(Content, 0, LEFT_W, yPos), "-", Color3.fromRGB(70, 200, 110), 18)
        lbl.Font = Enum.Font.GothamBold
        SaranLabels[i] = lbl
    end

    local CountLbl = makeLabel(makeCard(Content, 0, LEFT_W, 340, 26), "Total: 0")
    Content.CanvasSize = UDim2.new(0, 0, 0, 380)

    -- RIGHT: KILLER
    local RightContent = Instance.new("Frame", MainFrame)
    RightContent.Size = UDim2.new(0, 280, 1, -44)
    RightContent.Position = UDim2.new(0, 240, 0, 44)
    RightContent.BackgroundTransparency = 1

    local KillerTitle = Instance.new("TextLabel", makeCard(RightContent, 0, 280, 8, 26))
    KillerTitle.Size = UDim2.new(1, -10, 1, 0)
    KillerTitle.Position = UDim2.new(0, 10, 0, 0)
    KillerTitle.BackgroundTransparency = 1
    KillerTitle.Text = "🔥 KILLER SUFFIX"
    KillerTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
    KillerTitle.Font = Enum.Font.GothamBold
    KillerTitle.TextSize = 13

    local RightScroll = Instance.new("ScrollingFrame", RightContent)
    RightScroll.Size = UDim2.new(1, 0, 1, -44)
    RightScroll.Position = UDim2.new(0, 0, 0, 44)
    RightScroll.BackgroundTransparency = 1
    RightScroll.ScrollBarThickness = 4
    RightScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 100, 100)

    local KillerLabels = {}
    for i = 1, 25 do
        local yPos = (i - 1) * ITEM_GAP + 4
        local card = Instance.new("Frame", RightScroll)
        card.Size = UDim2.new(1, -12, 0, ITEM_H)
        card.Position = UDim2.new(0, 6, 0, yPos)
        card.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
        card.BackgroundTransparency = 0.4
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 7)

        local lbl = Instance.new("TextLabel", card)
        lbl.Size = UDim2.new(1, -10, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = "-"
        lbl.TextColor3 = Color3.fromRGB(255, 120, 100)
        lbl.TextSize = 13
        lbl.Font = Enum.Font.GothamBold
        KillerLabels[i] = lbl
    end
    RightScroll.CanvasSize = UDim2.new(0, 0, 0, 25 * ITEM_GAP + 10)

    -- Events
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Content.Visible = not minimized
        RightContent.Visible = not minimized
        MainFrame.Size = minimized and UDim2.new(0, 520, 0, 44) or UDim2.new(0, 520, 0, 300)
        MinBtn.Text = minimized and "□" or "-"
    end)

    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    Content.Visible = false
    RightContent.Visible = false
    MinBtn.Text = "□"
    minimized = true

    return {StatusLbl, PrefixLbl, SaranLabels, CountLbl, KillerLabels, Content, RightContent}
end

-- =============================================
--   MAIN LOGIC - 100% MENGIKUTI KETIKAN
-- =============================================
UI = createUI()
local lastPrefix = ""

local function setStatus(text, color)
    UI[1].Text = text
    UI[1].TextColor3 = color or Color3.fromRGB(140, 140, 165)
end

local function updateDisplay(prefix)
    local suffixKey = table.concat(customSuffix, ",")
    local currentKey = prefix .. "|" .. suffixKey
    if currentKey == lastPrefix then return end
    lastPrefix = currentKey
    
    UI[2].Text = "Prefix: '" .. prefix:upper() .. "' (" .. #prefix .. " huruf)"
    UI[4].Text = "Total: " .. totalWords

    -- Saran
    local suggestions = getSuggestions(prefix, 12)
    for i, lbl in ipairs(UI[3]) do
        lbl.Text = suggestions[i] and suggestions[i]:upper() or "-"
        lbl.TextColor3 = suggestions[i] and Color3.fromRGB(70, 200, 110) or Color3.fromRGB(100, 100, 100)
    end

    -- Killer
    local killers = getKillerSuggestions(prefix, 25)
    for i, lbl in ipairs(UI[5]) do
        lbl.Text = killers[i] and killers[i]:upper() or "-"
        lbl.TextColor3 = killers[i] and Color3.fromRGB(255, 120, 100) or Color3.fromRGB(100, 100, 100)
    end

    setStatus("🔥 '" .. prefix:upper() .. "' | " .. #suggestions .. " saran | " .. #killers .. " killer", Color3.fromRGB(70, 220, 220))
end

-- ✅ MONITOR MULTI PATH - LEBIH AKRAT
spawn(function()
    while UI do
        wait(0.1)
        local prefix = ""
        
        -- PATH 1: WordServer (utama)
        pcall(function()
            local matchUI = LocalPlayer.PlayerGui:FindFirstChild("MatchUI")
            if matchUI then
                local bottomUI = matchUI:FindFirstChild("BottomUI")
                if bottomUI then
                    local topUI = bottomUI:FindFirstChild("TopUI")
                    if topUI then
                        local wordServerFrame = topUI:FindFirstChild("WordServerFrame")
                        if wordServerFrame then
                            local wordServer = wordServerFrame:FindFirstChild("WordServer")
                            if wordServer and wordServer:IsA("TextLabel") then
                                prefix = wordServer.Text
                            end
                        end
                    end
                end
            end
        end)
        
        -- PATH 2: Cek input box lain
        if prefix == "" then
            pcall(function()
                local matchUI = LocalPlayer.PlayerGui:FindFirstChild("MatchUI")
                if matchUI then
                    for _, obj in pairs(matchUI:GetDescendants()) do
                        if obj:IsA("TextBox") or obj:IsA("TextLabel") then
                            local text = obj.Text or obj.Name
                            if text:match("^[a-zA-Z]+$") and #text >= 1 and #text <= 10 then
                                prefix = text
                                break
                            end
                        end
                    end
                end
            end)
        end
        
        local cleanPrefix = prefix:gsub("%s+", ""):lower()
        if cleanPrefix:match("^%a+$") and #cleanPrefix >= 1 then
            updateDisplay(cleanPrefix)
        end
    end
end)

-- Remotes
pcall(function()
    Remotes:FindFirstChild("BillboardStart").OnClientEvent:Connect(function(data)
        local prefix = tostring(data):gsub("%s+", ""):lower()
        if #prefix >= 1 then updateDisplay(prefix) end
    end)
end)
pcall(function()
    Remotes:FindFirstChild("BillboardUpdate").OnClientEvent:Connect(function(data)
        local prefix = tostring(data):gsub("%s+", ""):lower()
        if #prefix >= 1 then updateDisplay(prefix) end
    end)
end)

wait(2)
setStatus("✅ PERFECT READY - 100% MENGIKUTI KETIKAN!", Color3.fromRGB(70, 220, 220))
print("🚀 V14 PERFECT - Mengikuti AN = saran AN!")