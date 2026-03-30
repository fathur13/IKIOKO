-- =============================================
--   AUTO SAMBUNG KATA V14 FAST BY - alekhub
--   - Semua fitur V13 Fast
--   - NEW: Load wordlist otomatis dari GitHub
--     Tidak perlu file lokal, semua executor support
-- =============================================

print = function() end
warn = function() end

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Remotes = RS:WaitForChild("Remotes")
local SubmitWord = Remotes:WaitForChild("SubmitWord")

local CONFIG = {
    DELAY_MIN = 0.05,
    DELAY_MAX = 0.15,
    MIN_LENGTH = 3,
    AUTO_ON = false,
}

-- =============================================
--   WORDLIST
-- =============================================
local byPrefix = {}
local usedWords = {}
local totalWords = 0

local function indexWord(word)
    for len = 1, #word do
        local prefix = word:sub(1, len)
        if not byPrefix[prefix] then byPrefix[prefix] = {} end
        table.insert(byPrefix[prefix], word)
    end
    totalWords = totalWords + 1
end

local masterLoaded = false

local function loadWordlist()
    local GITHUB_URL = "https://raw.githubusercontent.com/fathur13/IKIOKO/refs/heads/main/MasterWordList.txt"

    local function indexRaw(raw)
        local count = 0
        for w in raw:gmatch("[^\r\n]+") do
            local wc = w:lower():gsub("%s+", "")
            if wc:match("^%a+$") and #wc >= CONFIG.MIN_LENGTH then
                indexWord(wc)
                count = count + 1
            end
        end
        return count
    end

    -- ===== STEP 1: Fetch dari GitHub via executor HTTP =====
    local raw = nil

    -- Cara 1: request() - support Delta, Fluxus, dll
    if not raw and request then
        local ok, res = pcall(request, {
            Url = GITHUB_URL,
            Method = "GET"
        })
        if ok and res and res.Body and #res.Body > 100 then
            raw = res.Body
        end
    end

    -- Cara 2: http.request() - varian lain
    if not raw and http and http.request then
        local ok, res = pcall(http.request, GITHUB_URL)
        if ok and res and #res > 100 then
            raw = res
        end
    end

    -- Cara 3: game:HttpGet() - support beberapa executor
    if not raw then
        local ok, res = pcall(function()
            return game:HttpGet(GITHUB_URL)
        end)
        if ok and res and #res > 100 then
            raw = res
        end
    end

    -- Cara 4: syn.request() - Synapse
    if not raw and syn and syn.request then
        local ok, res = pcall(syn.request, {
            Url = GITHUB_URL,
            Method = "GET"
        })
        if ok and res and res.Body and #res.Body > 100 then
            raw = res.Body
        end
    end

    -- Cara 5: HttpService via game - fallback universal
    if not raw then
        local ok, res = pcall(function()
            local hs = game:GetService("HttpService")
            return hs:GetAsync(GITHUB_URL)
        end)
        if ok and res and #res > 100 then
            raw = res
        end
    end

    if raw then
        local count = indexRaw(raw)
        if count > 100 then
            masterLoaded = true
            return
        end
    end

    -- ===== STEP 2: Fallback baca file lokal =====
    local ok2, raw2 = pcall(readfile, "MasterWordList.txt")
    if ok2 and raw2 and #raw2 > 100 then
        local count = indexRaw(raw2)
        if count > 100 then
            masterLoaded = true
            return
        end
    end

    -- ===== STEP 3: Fallback ModuleScript di game =====
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("ModuleScript") and v.Name == "MasterWordList" then
            local ok3, result = pcall(require, v)
            if ok3 and type(result) == "table" then
                for _, w in ipairs(result) do
                    local wc = tostring(w):lower():gsub("%s+", "")
                    if wc:match("^%a+$") and #wc >= CONFIG.MIN_LENGTH then
                        indexWord(wc)
                    end
                end
                masterLoaded = true
            end
            break
        end
    end
end

-- =============================================
--   CARI KATA
-- =============================================
local function getWord(prefix)
    prefix = prefix:lower():gsub("%s+", "")
    if #prefix == 0 then return nil end

    local killerEnds = {
        ia=true, if=true, tif=true, ks=true, ksa=true,
        ax=true, by=true, cy=true, dh=true, ch=true, dl=true,
        ei=true, eo=true, eu=true, ex=true, ey=true, ez=true,
        gh=true, gn=true, gr=true, gy=true,
        ie=true, oi=true, lt=true, ly=true,
        iki=true, ipe=true, iya=true, ipi=true,
        oe=true, oo=true, ns=true, ox=true,
        pt=true, mn=true, mp=true, nd=true,
        sm=true, nj=true, ty=true, tl=true, th=true
    }

    local function isKillerWord(word)
        for suffix, _ in pairs(killerEnds) do
            if word:sub(-#suffix) == suffix then
                return true
            end
        end
        return false
    end

    for len = #prefix, 1, -1 do
        local p = prefix:sub(1, len)
        local candidates = byPrefix[p]
        if candidates then
            local killers, short, long = {}, {}, {}
            for _, word in ipairs(candidates) do
                if not usedWords[word] and word:sub(1, len) == p then
                    if isKillerWord(word) then
                        table.insert(killers, word)
                    elseif #word <= 5 then
                        table.insert(short, word)
                    else
                        table.insert(long, word)
                    end
                end
            end

            if #killers > 0 then
                table.sort(killers, function(a, b) return #a > #b end)
                return killers[math.random(1, math.min(#killers, 3))]
            end
            if #short > 0 then
                return short[math.random(1, math.min(#short, 15))]
            end
            if #long > 0 then
                return long[math.random(1, math.min(#long, 15))]
            end
        end
    end
    return nil
end

local function shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

local function getSuggestions(prefix, count)
    prefix = prefix:lower():gsub("%s+", "")
    local suggestions, seen = {}, {}
    if #prefix == 0 then return suggestions end

    for len = #prefix, 1, -1 do
        local p = prefix:sub(1, len)
        local candidates = byPrefix[p]
        if candidates then
            local pool = {}

            for _, word in ipairs(candidates) do
                if word:sub(1, len) == p and not seen[word] then
                    seen[word] = true
                    table.insert(pool, word)
                end
            end

            -- 🔥 shuffle BESAR (bukan short/long lagi)
            shuffle(pool)

            -- 🔥 ambil random slice (biar beda terus)
            local startIndex = math.random(1, math.max(1, #pool - count))
            for i = startIndex, math.min(startIndex + count - 1, #pool) do
                table.insert(suggestions, pool[i])
                if #suggestions >= count then break end
            end
        end
        if #suggestions >= count then break end
    end

    return suggestions
end

-- local KILLER_SUFFIXES = {"f", "x", "q", "z", "w", "v", "c"}

-- local ISME_WORDS = {
--     "kanibalisme","nasionalisme","kapitalisme","sosialisme","komunisme",
--     "feminisme","heroisme","egoisme","nihilisme","optimisme",
--     "pesimisme","romantisme","sadisme","masokisme","fanatisme",
--     "plagiarisme","idealisme","realisme","empirisme","liberalisme",
--     "konservatisme","absolutisme","anarkisme","paternalisme","seksisme",
--     "rasisme","ateisme","terorisme","vandalisme","alkoholisme",
--     "nepotisme","oportunisme","chauvinisme","urbanisme","regionalisme",
--     "separatisme","ekstremisme","populisme","materialisme","sekularisme",
--     "individualisme","kolektivisme","sentralisme","pluralisme","patriotisme",
--     "modernisme","naturalisme","impresionisme","ekspresionisme","eksistensialisme",
-- }

-- local TIF_WORDS = {
--     "representatif","administratif","informatif","komunikatif","produktif",
--     "konstruktif","destruktif","instruktif","kolektif","objektif",
--     "subjektif","perspektif","kompetitif","definitif","sensitif",
--     "deklaratif","naratif","komparatif","operatif","konservatif",
--     "normatif","formatif","transformatif","afirmatif","inovatif",
--     "kreatif","alternatif","kooperatif","preventif","kumulatif",
-- }

-- local IF_WORDS = {
--     "aktif","pasif","positif","negatif","agresif","defensif",
--     "ofensif","masif","eksplosif","impulsif","kompulsif","obsesif",
--     "depresif","eksklusif","inklusif","ekspansif","refleksif","progresif",
--     "regresif","ekstensif","intensif","responsif","komprehensif","persuasif",
-- }

-- local function getKillerSuggestions(prefix, count)
--     prefix = prefix:lower():gsub("%s+", "")
--     local results, seen = {}, {}
--     if #prefix == 0 then return results end

--     for len = #prefix, 1, -1 do
--         local p = prefix:sub(1, len)
--         local candidates = byPrefix[p]
--         if candidates then
--             for _, suffix in ipairs(KILLER_SUFFIXES) do
--                 for _, word in ipairs(candidates) do
--                     if not usedWords[word] and not seen[word]
--                         and word:sub(1, len) == p
--                         and word:sub(-1) == suffix then
--                         seen[word] = true
--                         table.insert(results, word)
--                         if #results >= 15 then break end
--                     end
--                 end
--                 if #results >= 15 then break end
--             end
--         end
--         if #results >= 15 then break end
--     end

--     local extras = {}
--     for _, w in ipairs(ISME_WORDS) do table.insert(extras, w) end
--     for _, w in ipairs(TIF_WORDS) do table.insert(extras, w) end
--     for _, w in ipairs(IF_WORDS) do table.insert(extras, w) end

--     for len = #prefix, 1, -1 do
--         local p = prefix:sub(1, len)
--         for _, word in ipairs(extras) do
--             if not seen[word] and word:sub(1, len) == p then
--                 seen[word] = true
--                 table.insert(results, word)
--                 if #results >= count then break end
--             end
--         end
--         if #results >= count then break end
--     end

--     return results
-- end
local function getKillerSuggestions(prefix, count)
    prefix = prefix:lower():gsub("%s+", "")
    local results, seen = {}, {}
    local killerEnds = {
        ia=true, if=true, tif=true, ks=true, ksa=true,
        ax=true, by=true, cy=true, dh=true, ch=true, dl=true,
        ei=true, eo=true, eu=true, ex=true, ey=true, ez=true,
        gh=true, gn=true, gr=true, gy=true,
        ie=true, oi=true, lt=true, ly=true,
        iki=true, ipe=true, iya=true, ipi=true,
        oe=true, oo=true, ns=true, ox=true,
        pt=true, mn=true, mp=true, nd=true,
        sm=true, nj=true, ty=true, tl=true, th=true
    }
    
    local function isKillerWord(word)
        for suffix, _ in pairs(killerEnds) do
            if word:sub(-#suffix) == suffix then
                return true
            end
        end
        return false
    end

    if #prefix == 0 then return results end

    for len = #prefix, 1, -1 do
        local p = prefix:sub(1, len)
        local candidates = byPrefix[p]
        if candidates then
            local pool = {}

            -- ambil semua kandidat killer dulu
            for _, word in ipairs(candidates) do
                if word:sub(1, len) == p 
                and not seen[word] 
                and isKillerWord(word) then
                    seen[word] = true
                    table.insert(pool, word)
                end
            end

            -- 🔥 SHUFFLE BIAR ACAK TOTAL
            shuffle(pool)

            -- 🔥 RANDOM SLICE (BIAR GAK NGAMBIL DEPAN TERUS)
            local startIndex = math.random(1, math.max(1, #pool - count))
            for i = startIndex, math.min(startIndex + count - 1, #pool) do
                table.insert(results, pool[i])
                if #results >= count then break end
            end
        end

        if #results >= count then break end
    end

    return results
end

-- =============================================
--   UI
-- =============================================
local ITEM_H   = 30
local ITEM_GAP = 34

local function createUI()
    local existing = LocalPlayer.PlayerGui:FindFirstChild("AutoKataUI")
    if existing then existing:Destroy() end

    local leftRows  = 15
    local rightRows = 20
    local saranStartY = 90
    local saranEndY   = saranStartY + (leftRows - 1) * ITEM_GAP + ITEM_H
    local countY      = saranEndY + 6
    local rightEndY   = 10 + rightRows * ITEM_GAP + ITEM_H
    local contentH    = math.max(countY + ITEM_H + 10, rightEndY + 10)
    local FIXED_HEIGHT = 300 -- 🔥 bebas kamu atur sendiri
    local frameH = FIXED_HEIGHT

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoKataUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = LocalPlayer.PlayerGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 520, 0, frameH)
    MainFrame.Position = UDim2.new(0, 20, 0, 20)
    MainFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
    MainFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
    MainFrame.BackgroundTransparency = 0.3 -- 🔥 makin besar makin transparan (0.5 = lebih tembus)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", MainFrame)
    stroke.Color = Color3.fromRGB(70, 200, 220)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.4

    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 44)
    Header.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    Header.BackgroundTransparency = 0.3
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)
    local hfix = Instance.new("Frame", Header)
    hfix.Size = UDim2.new(1, 0, 0, 12)
    hfix.Position = UDim2.new(0, 0, 1, -12)
    hfix.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    hfix.BorderSizePixel = 0

    local Title = Instance.new("TextLabel", Header)
    Title.Size = UDim2.new(1, -150, 1, 0)
    Title.Position = UDim2.new(0, 14, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "AUTO SAMBUNG KATA V14 FAST BY - alekhub"
    Title.TextColor3 = Color3.fromRGB(70, 220, 220)
    Title.TextSize = 14
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local function makeBtn(parent, xOff, bg, txt)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(0, 28, 0, 28)
        btn.Position = UDim2.new(1, xOff, 0, 8)
        btn.BackgroundColor3 = bg
        btn.Text = txt
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        return btn
    end

    local MinBtn   = makeBtn(Header, -66, Color3.fromRGB(50, 50, 65), "-")
    local CloseBtn = makeBtn(Header, -34, Color3.fromRGB(190, 55, 55), "X")

    local HeaderToggle = Instance.new("TextButton", Header)
    HeaderToggle.Size = UDim2.new(0, 0, 0, 0)
    HeaderToggle.BackgroundTransparency = 1
    HeaderToggle.Text = ""
    HeaderToggle.Visible = false

    local HeaderCircle = Instance.new("Frame", HeaderToggle)
    HeaderCircle.Size = UDim2.new(0, 18, 0, 18)
    HeaderCircle.Position = UDim2.new(0, 3, 0.5, -9)
    HeaderCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    HeaderCircle.BorderSizePixel = 0
    Instance.new("UICorner", HeaderCircle).CornerRadius = UDim.new(1, 0)

    local divider = Instance.new("Frame", MainFrame)
    divider.Size = UDim2.new(0, 1, 1, -50)
    divider.Position = UDim2.new(0, 240, 0, 48)
    divider.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    divider.BorderSizePixel = 0

    local function makeCard(parent, xOffset, panelW, yPos, h)
        local f = Instance.new("Frame", parent)
        f.Size = UDim2.new(0, panelW - 24, 0, h or ITEM_H)
        f.Position = UDim2.new(0, xOffset + 12, 0, yPos)
        f.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
        f.BackgroundTransparency = 0.4 -- 🔥 ini bikin semua kotak transparan
        f.BorderSizePixel = 0
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
        lbl.TextSize = size or 10
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextWrapped = true
        return lbl
    end

    local LEFT_W = 240
    local Content = Instance.new("ScrollingFrame", MainFrame)
    Content.Name = "Content"
    Content.Size = UDim2.new(0, LEFT_W, 1, -44)
    Content.Position = UDim2.new(0, 0, 0, 44)
    Content.BackgroundTransparency = 1
    Content.ScrollBarThickness = 4
    Content.ScrollBarImageColor3 = Color3.fromRGB(70, 180, 110)
    Content.CanvasSize = UDim2.new(0, 0, 0, countY + 50)
    Content.ScrollingDirection = Enum.ScrollingDirection.Y

    local toggleCard = makeCard(Content, 0, LEFT_W, 8, 26)
    makeLabel(toggleCard, "Auto Submit", Color3.fromRGB(210, 210, 210), 12)

    local ToggleBtn = Instance.new("TextButton", toggleCard)
    ToggleBtn.Size = UDim2.new(0, 44, 0, 24)
    ToggleBtn.Position = UDim2.new(1, -52, 0.5, -12)
    ToggleBtn.BackgroundColor3 = CONFIG.AUTO_ON and Color3.fromRGB(70, 200, 110) or Color3.fromRGB(55, 55, 70)
    ToggleBtn.Text = ""
    ToggleBtn.BorderSizePixel = 0
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

    local Circle = Instance.new("Frame", ToggleBtn)
    Circle.Size = UDim2.new(0, 18, 0, 18)
    Circle.Position = CONFIG.AUTO_ON and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.BorderSizePixel = 0
    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)

    local StatusLbl = makeLabel(makeCard(Content, 0, LEFT_W, 40, ITEM_H), "Status: Menunggu...", Color3.fromRGB(140, 140, 165), 11)
    StatusLbl.Name = "StatusLbl"

    local PrefixLbl = makeLabel(makeCard(Content, 0, LEFT_W, 64, ITEM_H), "Huruf awal: -", Color3.fromRGB(255, 195, 70), 11)
    PrefixLbl.Font = Enum.Font.GothamBold
    PrefixLbl.Name = "PrefixLbl"

    local SaranLabels = {}
    for i = 1, 15 do
        local yPos = saranStartY + (i - 1) * ITEM_GAP
        local green = math.max(120, 205 - i * 5)
        local lbl = makeLabel(
            makeCard(Content, 0, LEFT_W, yPos, ITEM_H),
            "Saran " .. i .. ": -",
            Color3.fromRGB(70, green, 110), 24
        )
        lbl.Font = Enum.Font.GothamBold
        lbl.Name = "Saran" .. i .. "Lbl"
        SaranLabels[i] = lbl
    end

    local CountLbl = makeLabel(makeCard(Content, 0, LEFT_W, countY, ITEM_H), "Submit: 0  |  Kata: " .. totalWords, Color3.fromRGB(140, 140, 165), 11)
    CountLbl.Name = "CountLbl"

    local RIGHT_X = 240
    local RIGHT_W = 280
    local KILLER_COUNT = 30

    local RightContent = Instance.new("Frame", MainFrame)
    RightContent.Name = "RightContent"
    RightContent.Size = UDim2.new(0, RIGHT_W, 1, -44)
    RightContent.Position = UDim2.new(0, RIGHT_X, 0, 44)
    RightContent.BackgroundTransparency = 1

    local hCard = Instance.new("Frame", RightContent)
    hCard.Size = UDim2.new(1, -12, 0, ITEM_H)
    hCard.Position = UDim2.new(0, 6, 0, 6)
    hCard.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    hCard.BorderSizePixel = 0
    Instance.new("UICorner", hCard).CornerRadius = UDim.new(0, 7)
    local hLbl = Instance.new("TextLabel", hCard)
    hLbl.Size = UDim2.new(1, -10, 1, 0)
    hLbl.Position = UDim2.new(0, 10, 0, 0)
    hLbl.BackgroundTransparency = 1
    hLbl.Text = "Kata Pembunuh (bisa scroll)"
    hLbl.TextColor3 = Color3.fromRGB(220, 100, 100)
    hLbl.TextSize = 24
    hLbl.Font = Enum.Font.GothamBold
    hLbl.TextXAlignment = Enum.TextXAlignment.Left

    local scrollY = ITEM_H + 10
    local RightScroll = Instance.new("ScrollingFrame", RightContent)
    RightScroll.Size = UDim2.new(1, 0, 1, -scrollY)
    RightScroll.Position = UDim2.new(0, 0, 0, scrollY)
    RightScroll.BackgroundTransparency = 1
    RightScroll.BorderSizePixel = 0
    RightScroll.ScrollBarThickness = 4
    RightScroll.ScrollBarImageColor3 = Color3.fromRGB(70, 180, 110)
    RightScroll.CanvasSize = UDim2.new(0, 0, 0, KILLER_COUNT * ITEM_GAP + 10)
    RightScroll.ScrollingDirection = Enum.ScrollingDirection.Y

    local KillerLabels = {}
    for i = 1, KILLER_COUNT do
        local yPos = (i - 1) * ITEM_GAP + 4
        local card = Instance.new("Frame", RightScroll)
        card.Size = UDim2.new(1, -12, 0, ITEM_H)
        card.Position = UDim2.new(0, 6, 0, yPos)
        card.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
        card.BackgroundTransparency = 0.4
        card.BorderSizePixel = 0
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 7)

        local color
        if i <= 15 then
            color = Color3.fromRGB(math.max(90, 230 - i*4), 110, 110)
        elseif i <= 25 then
            color = Color3.fromRGB(220, 150, 60)
        elseif i <= 35 then
            color = Color3.fromRGB(220, 200, 60)
        else
            color = Color3.fromRGB(150, 200, 255)
        end

        local lbl = Instance.new("TextLabel", card)
        lbl.Size = UDim2.new(1, -10, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = i .. ": -"
        lbl.TextColor3 = color
        lbl.TextSize = 13
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextWrapped = true
        lbl.Name = "Killer" .. i
        KillerLabels[i] = lbl
    end

    return {
        MainFrame = MainFrame,
        Content = Content,
        RightContent = RightContent,
        ToggleBtn = ToggleBtn, Circle = Circle,
        HeaderToggle = HeaderToggle, HeaderCircle = HeaderCircle,
        StatusLbl = StatusLbl,
        PrefixLbl = PrefixLbl,
        SaranLabels = SaranLabels,
        LastLbl = SaranLabels[1],
        CountLbl = CountLbl,
        KillerLabels = KillerLabels,
        MinBtn = MinBtn, CloseBtn = CloseBtn,
        frameH = frameH,
    }
end

-- =============================================
--   MAIN
-- =============================================
local submitCount = 0
local isSubmitting = false
local lastPrefix = ""
local autoEnabled = CONFIG.AUTO_ON

loadWordlist()
local UI = createUI()

local function setStatus(text, color)
    UI.StatusLbl.Text = "Status: " .. text
    UI.StatusLbl.TextColor3 = color or Color3.fromRGB(140, 140, 165)
end

local function setToggle(state)
    autoEnabled = state
    local onColor  = Color3.fromRGB(70, 200, 110)
    local offColor = Color3.fromRGB(55, 55, 70)
    local onPos    = UDim2.new(1, -21, 0.5, -9)
    local offPos   = UDim2.new(0, 3, 0.5, -9)
    TweenService:Create(UI.ToggleBtn,    TweenInfo.new(0.2), {BackgroundColor3 = state and onColor or offColor}):Play()
    TweenService:Create(UI.Circle,       TweenInfo.new(0.2), {Position = state and onPos or offPos}):Play()
    TweenService:Create(UI.HeaderToggle, TweenInfo.new(0.2), {BackgroundColor3 = state and onColor or offColor}):Play()
    TweenService:Create(UI.HeaderCircle, TweenInfo.new(0.2), {Position = state and onPos or offPos}):Play()
    if state then
        setStatus("Auto aktif!", Color3.fromRGB(70, 200, 110))
    else
        setStatus("Mode saran - ketik manual", Color3.fromRGB(100, 180, 255))
    end
    lastPrefix = ""
    isSubmitting = false
end

UI.ToggleBtn.MouseButton1Click:Connect(function() setToggle(not autoEnabled) end)
UI.HeaderToggle.MouseButton1Click:Connect(function() setToggle(not autoEnabled) end)

local minimized = false
UI.MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    UI.Content.Visible      = not minimized
    UI.RightContent.Visible = not minimized
    UI.MainFrame.Size = minimized
        and UDim2.new(0, 520, 0, 44)
        or  UDim2.new(0, 520, 0, UI.frameH)
    UI.MinBtn.Text = minimized and "[]" or "-"
end)

UI.CloseBtn.MouseButton1Click:Connect(function()
    autoEnabled = false
    LocalPlayer.PlayerGui:FindFirstChild("AutoKataUI"):Destroy()
end)

local function getMistakeCount()
    local ok, result = pcall(function()
        local mistakeUI = LocalPlayer.PlayerGui
            :WaitForChild("MatchUI", 1)
            .BottomUI.CenterUI.MistakeUI
        local count = 0
        for i = 1, 5 do
            local wrong = mistakeUI:FindFirstChild("Wrong" .. i)
            if wrong then
                local icon = wrong:FindFirstChild("WrongIcon")
                if icon and icon.ImageTransparency < 0.1 then count = count + 1 end
            end
        end
        return count
    end)
    if ok then return result end
    return -1
end

local function isMyTurn()
    local ok1, result1 = pcall(function()
        local char = LocalPlayer.Character
        if not char then return false end
        local head = char:FindFirstChild("Head")
        if not head then return false end
        local bb = head:FindFirstChild("TurnBillboard")
        return bb ~= nil
    end)
    if ok1 and result1 then return true end

    local ok2, result2 = pcall(function()
        local submit = LocalPlayer.PlayerGui
            :WaitForChild("MatchUI", 0.5)
            .BottomUI.TopUI.WordSubmit
        return submit.Visible
    end)
    if ok2 and result2 then return true end

    return false
end

local function doSubmit(prefix)
    if isSubmitting then return end
    prefix = prefix:lower():gsub("%s+", "")
    if #prefix == 0 then return end
    if prefix == lastPrefix then return end

    if not isMyTurn() then return end

    isSubmitting = true
    lastPrefix   = prefix

    spawn(function()
        wait(3)
        if isSubmitting and lastPrefix == prefix then
            isSubmitting = false
            lastPrefix = ""
            setStatus("Watchdog reset!", Color3.fromRGB(200, 150, 50))
        end
    end)

    UI.PrefixLbl.Text = "Huruf awal: " .. prefix:upper()

    spawn(function()
        local killerWords = getKillerSuggestions(prefix, 30)
        for i, lbl in ipairs(UI.KillerLabels) do
            lbl.Text = i .. ": " .. (killerWords[i] and killerWords[i]:upper() or "-")
        end
    end)

    if not autoEnabled then
        local suggestions = getSuggestions(prefix, 15)
        for i, lbl in ipairs(UI.SaranLabels) do
            lbl.Text = "Saran " .. i .. ": " .. (suggestions[i] and suggestions[i]:upper() or "-")
        end
        setStatus("Ketik salah satu!", Color3.fromRGB(100, 180, 255))
        isSubmitting = false
        return
    end

    local MAX_TRIES = 5
    local tries = 0

    setStatus("FAST: " .. prefix:upper() .. "...", Color3.fromRGB(255, 195, 70))

    local mistakeBase = getMistakeCount()
    local triedWords = {}

    while tries < MAX_TRIES and autoEnabled do
        local word = getWord(prefix)
        if not word then
            setStatus("Tidak ada kata: " .. prefix:upper(), Color3.fromRGB(200, 70, 70))
            break
        end

        usedWords[word] = true
        table.insert(triedWords, word)
        tries = tries + 1

        if not autoEnabled then break end

        if not isMyTurn() then
            for _, w in ipairs(triedWords) do usedWords[w] = nil end
            break
        end

        local mistakeBefore = getMistakeCount()

        local ok3, textbox = pcall(function()
            return LocalPlayer.PlayerGui
                :WaitForChild("MatchUI", 1)
                .BottomUI.TopUI.WordSubmit.Word
        end)
        if ok3 and textbox then
            textbox.Text = word
        end

        setStatus("⚡ " .. word:upper(), Color3.fromRGB(100, 220, 255))
        SubmitWord:FireServer(word)
        wait(0.15)

        local mistakeAfter = getMistakeCount()
        if mistakeBefore ~= -1 and mistakeAfter > mistakeBase then
            mistakeBase = mistakeAfter
            usedWords[word] = nil
            setStatus("Ditolak: " .. word:upper() .. " retry...", Color3.fromRGB(200, 70, 70))
        else
            submitCount = submitCount + 1
            UI.SaranLabels[1].Text = "Kata terakhir: " .. word:upper()
            for i = 2, 15 do
                if UI.SaranLabels[i] then UI.SaranLabels[i].Text = "" end
            end
            UI.CountLbl.Text = "Submit: " .. submitCount .. "  |  Kata: " .. totalWords
            setStatus("⚡ OK: " .. word:upper(), Color3.fromRGB(70, 200, 110))
            break
        end
    end

    isSubmitting = false
end

local lastDisplayPrefix = ""

local function forceSubmit(prefix)
    isSubmitting = false
    lastPrefix = ""
    lastDisplayPrefix = ""
    doSubmit(prefix)
end

-- =============================================
--   UPDATE DISPLAY (saran + killer, tanpa submit)
-- =============================================
local function updateDisplayAll(prefix)
    prefix = prefix:lower():gsub("%s+", "")
    if #prefix == 0 then return end
    if prefix == lastDisplayPrefix then return end
    lastDisplayPrefix = prefix

    UI.PrefixLbl.Text = "Huruf awal: " .. prefix:upper()

    local suggestions = getSuggestions(prefix, 15)
    for i, lbl in ipairs(UI.SaranLabels) do
        lbl.Text = "Saran " .. i .. ": " .. (suggestions[i] and suggestions[i]:upper() or "-")
    end

    spawn(function()
        local killerWords = getKillerSuggestions(prefix, 30)
        for i, lbl in ipairs(UI.KillerLabels) do
            lbl.Text = i .. ": " .. (killerWords[i] and killerWords[i]:upper() or "-")
        end
    end)

    if not isMyTurn() then
        setStatus("[Musuh] Prefix: " .. prefix:upper() .. " | Lihat saran~", Color3.fromRGB(180, 120, 255))
    end
end

-- =============================================
--   MONITOR
-- =============================================
local function monitorMyBillboard()
    local function watchChar(char)
        local head = char:WaitForChild("Head", 5)
        if not head then return end

        local function onMyTurn()
            wait(0.1)
            local ok, prefix = pcall(function()
                return LocalPlayer.PlayerGui
                    :WaitForChild("MatchUI", 1)
                    .BottomUI.TopUI.WordServerFrame.WordServer.Text
            end)
            if ok and prefix then
                local t = prefix:gsub("%s+", ""):lower()
                if #t >= 1 and t:match("^%a+$") then
                    forceSubmit(t)
                end
            end
        end

        local existing = head:FindFirstChild("TurnBillboard")
        if existing then onMyTurn() end
        head.ChildAdded:Connect(function(c)
            if c.Name == "TurnBillboard" then onMyTurn() end
        end)
    end
    if LocalPlayer.Character then watchChar(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(watchChar)
end

local function monitorRemotes()
    local function onEvent(data)
        if data then
            local prefix = tostring(data):gsub("%s+", ""):lower()
            if #prefix >= 1 then
                updateDisplayAll(prefix)
            end
        end
    end
    local bs = Remotes:FindFirstChild("BillboardStart")
    if bs then bs.OnClientEvent:Connect(onEvent) end
    local bu = Remotes:FindFirstChild("BillboardUpdate")
    if bu then bu.OnClientEvent:Connect(onEvent) end
end

local function monitorUILabel()
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    spawn(function()
        local matchUI  = pg:WaitForChild("MatchUI", 30);  if not matchUI then return end
        local bottomUI = matchUI:WaitForChild("BottomUI", 10); if not bottomUI then return end
        local topUI    = bottomUI:WaitForChild("TopUI", 10);   if not topUI then return end
        local wsf      = topUI:WaitForChild("WordServerFrame", 10); if not wsf then return end

        local function watchWordServer(ws)
            ws:GetPropertyChangedSignal("Text"):Connect(function()
                local t = ws.Text:gsub("%s+", ""):lower()
                if #t >= 1 and t:match("^%a+$") then
                    updateDisplayAll(t)
                end
            end)
        end

        local existing = wsf:FindFirstChild("WordServer")
        if existing then watchWordServer(existing) end
        wsf.ChildAdded:Connect(function(c)
            if c.Name == "WordServer" then watchWordServer(c) end
        end)
    end)
end

local function monitorManualSubmit()
    spawn(function()
        local pg = LocalPlayer:WaitForChild("PlayerGui")
        local matchUI = pg:WaitForChild("MatchUI", 30); if not matchUI then return end
        local ok, wordSubmit = pcall(function()
            return matchUI:WaitForChild("BottomUI", 10)
                .TopUI:WaitForChild("WordSubmit", 10)
        end)
        if not ok or not wordSubmit then return end

        local lastDisplayed = ""

        local function getTypedWord()
            local slots = {}
            for _, child in pairs(wordSubmit:GetChildren()) do
                if child:IsA("TextLabel") and child.Name == "Word" then
                    local lo = child.LayoutOrder
                    local letter = child.Text:gsub("%s+", "")
                    if lo > 0 and letter ~= "" then
                        table.insert(slots, {order = lo, letter = letter})
                    end
                end
            end
            if #slots == 0 then return "" end
            table.sort(slots, function(a, b) return a.order < b.order end)
            local result = ""
            for _, s in ipairs(slots) do result = result .. s.letter end
            return result:lower()
        end

        local function updateSaran(typed)
            if typed == lastDisplayed then return end
            lastDisplayed = typed
            if #typed == 0 then return end
            UI.PrefixLbl.Text = "Huruf awal: " .. typed:upper()
            isSubmitting = false
            local suggestions = getSuggestions(typed, 15)
            for i, lbl in ipairs(UI.SaranLabels) do
                lbl.Text = "Saran " .. i .. ": " .. (suggestions[i] and suggestions[i]:upper() or "-")
            end
            spawn(function()
                local killerWords = getKillerSuggestions(typed, 30)
                for i, lbl in ipairs(UI.KillerLabels) do
                    lbl.Text = i .. ": " .. (killerWords[i] and killerWords[i]:upper() or "-")
                end
            end)
            setStatus("Ketik salah satu!", Color3.fromRGB(100, 180, 255))
        end

        local function onChanged()
            if autoEnabled then return end
            if isSubmitting then return end
            local typed = getTypedWord()
            if typed == "" and lastDisplayed ~= "" then
                if #lastDisplayed >= CONFIG.MIN_LENGTH and not usedWords[lastDisplayed] then
                    usedWords[lastDisplayed] = true
                end
                lastDisplayed = ""
                lastPrefix = ""
                return
            end
            updateSaran(typed)
        end

        for _, child in pairs(wordSubmit:GetChildren()) do
            if child:IsA("TextLabel") and child.Name == "Word" then
                child:GetPropertyChangedSignal("Text"):Connect(onChanged)
                child:GetPropertyChangedSignal("LayoutOrder"):Connect(onChanged)
            end
        end

        wordSubmit.ChildAdded:Connect(function(child)
            if child:IsA("TextLabel") and child.Name == "Word" then
                child:GetPropertyChangedSignal("Text"):Connect(onChanged)
                child:GetPropertyChangedSignal("LayoutOrder"):Connect(onChanged)
                onChanged()
            end
        end)

        wordSubmit.ChildRemoved:Connect(function(child)
            if child:IsA("TextLabel") and child.Name == "Word" then
                onChanged()
            end
        end)
    end)
end

local function monitorMatchUI()
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local cooldown = false

    local function resetAll()
        if cooldown then return end
        cooldown = true
        submitCount = 0
        isSubmitting = false
        lastPrefix = ""
        lastDisplayPrefix = ""
        usedWords = {}
        UI.CountLbl.Text = "Submit: 0  |  Kata: " .. totalWords
        UI.PrefixLbl.Text = "Huruf awal: -"
        UI.SaranLabels[1].Text = "Kata terakhir: -"
        for i = 2, 15 do
            if UI.SaranLabels[i] then UI.SaranLabels[i].Text = "Saran " .. i .. ": -" end
        end
        for i, lbl in ipairs(UI.KillerLabels) do lbl.Text = i .. ": -" end
        setStatus("Reset! Siap ronde baru~", Color3.fromRGB(100, 180, 255))
        wait(3)
        cooldown = false
    end

    spawn(function()
        while true do
            wait(0.2)
            local resultUI = pg:FindFirstChild("ResultUI")
            if resultUI and resultUI.Enabled then
                resetAll()
            end
        end
    end)
end

monitorMyBillboard()
monitorRemotes()
monitorUILabel()
monitorManualSubmit()
monitorMatchUI()

if totalWords > 0 then
    setStatus("⚡ FAST MODE - Siap! (" .. totalWords .. " kata)", Color3.fromRGB(70, 220, 220))
else
    setStatus("⚠ Gagal load wordlist! Cek koneksi internet", Color3.fromRGB(220, 100, 100))
end