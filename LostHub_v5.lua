--// LOST HUB HALLOWEEN EDITION | v5.1 | Orange & Purple
--// Loading novo, tela de key nova (lembrar key, tentativas, bloqueio),
--// mais opcoes em cada jogo, novos jogos (Booga Booga, Bee Swarm, Build A Boat),
--// alerta de inimigo, anti void, auto rejoin, auto server hop e muito mais.
--// Key: Lost

--========================
-- SERVICES
--========================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local guiParent = (gethui and gethui()) or CoreGui

--========================
-- PALETA
--========================
local C = {
    bg     = Color3.fromRGB(12, 5, 16),
    panel  = Color3.fromRGB(22, 10, 28),
    item   = Color3.fromRGB(34, 16, 40),
    hover  = Color3.fromRGB(58, 28, 64),
    off    = Color3.fromRGB(64, 38, 70),
    line   = Color3.fromRGB(110, 56, 84),
    accent = Color3.fromRGB(255, 122, 24),
    white  = Color3.fromRGB(255, 238, 218),
    text   = Color3.fromRGB(242, 214, 192),
    sub    = Color3.fromRGB(168, 124, 136),
    ok     = Color3.fromRGB(255, 176, 64),
    bad    = Color3.fromRGB(226, 62, 62),
}

--========================
-- HELPERS
--========================
local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do
        o[k] = v
    end
    if parent then
        o.Parent = parent
    end
    return o
end

local function corner(o, r)
    return new("UICorner", {CornerRadius = UDim.new(0, r)}, o)
end

local function stroke(o, color, thickness, transparency)
    return new("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, o)
end

local function tween(obj, time, props, style, direction)
    local tw = TweenService:Create(
        obj,
        TweenInfo.new(time or 0.3, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end

-- sistema de cor de destaque (tema) ------------------------------------
local AccentFns = {}
local function onAccent(fn)
    table.insert(AccentFns, fn)
    pcall(fn, C.accent)
end
local function setAccent(col)
    C.accent = col
    for _, f in ipairs(AccentFns) do
        pcall(f, col)
    end
end
local function shade(col, m)
    return Color3.new(math.clamp(col.R * m, 0, 1), math.clamp(col.G * m, 0, 1), math.clamp(col.B * m, 0, 1))
end

-- particulas flutuantes --------------------------------------------------
local function makeParticles(parent, n, color)
    local list = {}
    for i = 1, n do
        local s = math.random(2, 4)
        local f = new("Frame", {
            Size = UDim2.fromOffset(s, s),
            Position = UDim2.fromScale(math.random(), math.random()),
            BackgroundColor3 = color or C.white,
            BackgroundTransparency = 0.6 + math.random() * 0.35,
            BorderSizePixel = 0,
            ZIndex = 0,
        }, parent)
        corner(f, s)
        list[i] = {
            f = f, x = f.Position.X.Scale, y = f.Position.Y.Scale,
            v = 0.02 + math.random() * 0.05, d = (math.random() - 0.5) * 0.02, ph = math.random() * 6,
        }
    end
    local function step(dt, t)
        for _, p in ipairs(list) do
            p.y = p.y - p.v * dt
            p.x = p.x + math.sin(t + p.ph) * 0.01 * dt + p.d * dt
            if p.y < -0.02 then
                p.y = 1.02
                p.x = math.random()
            end
            p.f.Position = UDim2.fromScale(p.x, p.y)
        end
    end
    return step, list
end


-- particulas de emoji (morcegos, fantasmas, abobora...)
local function makeEmojiParticles(parent, n, list)
    local items = {}
    for i = 1, n do
        local lab = new("TextLabel", {
            Size = UDim2.fromOffset(26, 26),
            Position = UDim2.fromScale(math.random(), math.random()),
            BackgroundTransparency = 1,
            Text = list[math.random(1, #list)],
            TextSize = math.random(12, 22),
            TextTransparency = 0.5 + math.random() * 0.3,
            ZIndex = 0,
        }, parent)
        items[i] = {f = lab, x = lab.Position.X.Scale, y = lab.Position.Y.Scale,
            v = 0.02 + math.random() * 0.05, ph = math.random() * 6}
    end
    return function(dt, t)
        for _, p in ipairs(items) do
            p.y = p.y - p.v * dt
            if p.y < -0.05 then
                p.y = 1.05
                p.x = math.random()
            end
            p.f.Position = UDim2.fromScale(p.x + math.sin(t * 0.8 + p.ph) * 0.02, p.y)
            p.f.Rotation = math.sin(t + p.ph) * 14
        end
    end
end

--========================
-- LIMPAR GUIs ANTIGAS
--========================
pcall(function()
    for _, name in ipairs({"LostHub", "LostHubKey", "LostHubFOV", "LostHubToast", "LostHubESP", "LostHubFX"}) do
        local old = guiParent:FindFirstChild(name)
        if old then
            old:Destroy()
        end
    end
    local oldBlur = Lighting:FindFirstChild("LostHubBlur")
    if oldBlur then
        oldBlur:Destroy()
    end
end)

--==================================================
-- INTRO + KEY (tudo dentro de um bloco para liberar variaveis locais)
--==================================================
do
    local KEYS = {["Lost"] = true}
    local KEY_FILE = "LostHub_key.txt"
    local MAX_TRIES, LOCK_TIME = 5, 15
    local keyOk = false

    local function trim(s)
        return (s:gsub("^%s+", ""):gsub("%s+$", ""))
    end

    local function fadeAll(root, t)
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                tween(d, t, {TextTransparency = 1, BackgroundTransparency = 1})
            elseif d:IsA("ImageLabel") then
                tween(d, t, {ImageTransparency = 1, BackgroundTransparency = 1})
            elseif d:IsA("Frame") then
                tween(d, t, {BackgroundTransparency = 1})
            elseif d:IsA("UIStroke") then
                tween(d, t, {Transparency = 1})
            end
        end
    end

    local function vpScale(base)
        local cam = workspace.CurrentCamera
        local h = cam and cam.ViewportSize.Y or 720
        return math.clamp(h / base, 0.5, 1)
    end

    local Blur = new("BlurEffect", {Name = "LostHubBlur", Size = 0}, Lighting)
    pcall(function()
        tween(Blur, 0.6, {Size = 22})
    end)

    local KeyGui = new("ScreenGui", {
        Name = "LostHubKey",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, guiParent)

    ----------------------------------------------------------------------
    -- LOADING SCREEN v5
    ----------------------------------------------------------------------
    local Intro = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = C.bg,
        BorderSizePixel = 0,
    }, KeyGui)

    new("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(6, 2, 10)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(38, 15, 42)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 1, 8)),
        }),
    }, Intro)

    local introParticles = makeEmojiParticles(Intro, 34, {"🦇", "👻", "🎃", "🕸", "🍬", "💀", "🕷"})

    -- linha de varredura vertical
    local Scan = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = C.white,
        BackgroundTransparency = 0.82,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, Intro)
    new("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, Scan)

    -- cantos decorativos
    local function cornerMark(ax, ay, px, py)
        local f = new("Frame", {
            AnchorPoint = Vector2.new(ax, ay),
            Position = UDim2.new(px, ax == 0 and 18 or -18, py, ay == 0 and 18 or -18),
            Size = UDim2.fromOffset(34, 34),
            BackgroundTransparency = 1,
        }, Intro)
        new("Frame", {
            AnchorPoint = Vector2.new(ax, 0), Position = UDim2.new(ax, 0, ay, ay == 0 and 0 or -2),
            Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = C.line, BorderSizePixel = 0,
        }, f)
        new("Frame", {
            AnchorPoint = Vector2.new(0, ay), Position = UDim2.new(ax, ax == 0 and 0 or -2, ay, 0),
            Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = C.line, BorderSizePixel = 0,
        }, f)
    end
    cornerMark(0, 0, 0, 0)
    cornerMark(1, 0, 1, 0)
    cornerMark(0, 1, 0, 1)
    cornerMark(1, 1, 1, 1)

    local Stage = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
    }, Intro)
    local StageScale = new("UIScale", {Scale = vpScale(720)}, Stage)

    local LOGO_Y = -105
    local Circle = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0, LOGO_Y),
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = C.panel,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
    }, Stage)
    corner(Circle, 100)
    local CircleStroke = stroke(Circle, C.accent, 2, 0.2)
    tween(Circle, 0.8, {Size = UDim2.new(0, 190, 0, 190)}, Enum.EasingStyle.Back)

    local function makeRing(size, thickness, transparency)
        local ring = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 0, 0, LOGO_Y),
            Size = UDim2.new(0, size, 0, size),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, Stage)
        corner(ring, size / 2)
        local st = stroke(ring, C.accent, thickness, transparency)
        new("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.5, 1),
                NumberSequenceKeypoint.new(1, 0),
            }),
        }, st)
        return ring, st
    end

    local Ring1, Ring1Stroke = makeRing(226, 2, 0.15)
    local Ring2, Ring2Stroke = makeRing(262, 1, 0.4)
    local Ring3, Ring3Stroke = makeRing(300, 1, 0.6)
    local Ring4, Ring4Stroke = makeRing(340, 1, 0.8)

    local Orbs = {}
    for i = 1, 12 do
        local o = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, i % 3 == 0 and 6 or 4, 0, i % 3 == 0 and 6 or 4),
            BackgroundColor3 = C.white,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
        }, Stage)
        corner(o, 3)
        Orbs[i] = o
    end

    -- abobora de Halloween desenhada em UI (jack-o'-lantern com brilho de vela)
    local function makePumpkin(parent, cx, cy)
        local ink = Color3.fromRGB(14, 6, 10)
        local glowCol = Color3.fromRGB(255, 218, 96)
        local group = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, cx, 0, cy),
            Size = UDim2.fromOffset(150, 150),
            BackgroundTransparency = 1,
        }, parent)
        local scale = new("UIScale", {Scale = 1}, group)
        local function box(x, y, w, h, col, r, par)
            local f = new("Frame", {
                Position = UDim2.fromOffset(x, y),
                Size = UDim2.fromOffset(w, h),
                BackgroundColor3 = col,
                BorderSizePixel = 0,
            }, par or group)
            if r then corner(f, r) end
            return f
        end
        local function grad(f, c1, c2)
            new("UIGradient", {
                Rotation = 90,
                Color = ColorSequence.new({ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2)}),
            }, f)
        end

        local stem = box(64, 0, 20, 32, Color3.fromRGB(86, 120, 40), 6)
        stem.Rotation = 12
        grad(stem, Color3.fromRGB(130, 170, 64), Color3.fromRGB(58, 88, 28))
        local vine = box(80, 8, 26, 5, Color3.fromRGB(76, 150, 56), 3)
        vine.Rotation = -28

        for _, l in ipairs({{4, 28, 64, 112}, {82, 28, 64, 112}, {26, 20, 98, 124}}) do
            local f = box(l[1], l[2], l[3], l[4], Color3.fromRGB(255, 140, 30), math.floor(l[3] / 2))
            grad(f, Color3.fromRGB(255, 176, 56), Color3.fromRGB(206, 84, 10))
            stroke(f, Color3.fromRGB(122, 46, 6), 2, 0.2)
        end

        local eyes, halos = {}, {}
        for i, x in ipairs({36, 84}) do
            halos[i] = box(x - 2, 52, 34, 34, glowCol, 17)
            halos[i].BackgroundTransparency = 0.82
            eyes[i] = new("TextLabel", {
                Position = UDim2.fromOffset(x, 50),
                Size = UDim2.fromOffset(30, 36),
                BackgroundTransparency = 1,
                Text = "▲",
                TextColor3 = glowCol,
                TextSize = 36,
                Font = Enum.Font.GothamBlack,
                TextStrokeColor3 = ink,
                TextStrokeTransparency = 0.3,
            }, group)
        end
        local nose = new("TextLabel", {
            Position = UDim2.fromOffset(65, 82),
            Size = UDim2.fromOffset(20, 16),
            BackgroundTransparency = 1,
            Text = "▼",
            TextColor3 = ink,
            TextSize = 14,
            Font = Enum.Font.GothamBlack,
        }, group)

        local mouth = box(38, 100, 74, 30, glowCol, 12)
        mouth.BackgroundTransparency = 0.12
        stroke(mouth, ink, 2, 0.2)
        for i = 0, 3 do
            local t1 = box(46 + i * 16, 96, 10, 10, Color3.fromRGB(240, 120, 20), 2)
            t1.Rotation = 45
            local t2 = box(54 + i * 16, 124, 10, 10, Color3.fromRGB(240, 120, 20), 2)
            t2.Rotation = 45
        end

        return {group = group, scale = scale, eyes = eyes, halos = halos, mouth = mouth, glitch = 0, cx = cx, cy = cy}
    end

    local function animatePumpkin(pk, now)
        local flick = 0.06 + (math.sin(now * 9) * 0.5 + 0.5) * 0.14 + (math.random() < 0.05 and 0.3 or 0)
        pk.mouth.BackgroundTransparency = flick
        for i = 1, 2 do
            pk.eyes[i].TextTransparency = flick * 0.7
            pk.halos[i].BackgroundTransparency = 0.9 - flick * 0.6
        end
        if math.random() < 0.012 then
            pk.glitch = now + 0.09
        end
        local jx = now < pk.glitch and math.random(-5, 5) or 0
        pk.group.Position = UDim2.new(0, pk.cx + jx, 0, pk.cy + math.sin(now * 2) * 4)
        pk.group.Rotation = math.sin(now * 1.6) * 5 + (jx ~= 0 and math.random(-4, 4) or 0)
    end

    local Skull = makePumpkin(Stage, 0, LOGO_Y)

    -- titulo letra por letra
    local TITLE = "LOST HUB"
    local letters = {}
    for i = 1, #TITLE do
        local x = (i - (#TITLE + 1) / 2) * 30
        local l = new("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, x, 0, 116),
            Size = UDim2.fromOffset(30, 44),
            BackgroundTransparency = 1,
            Text = TITLE:sub(i, i),
            TextColor3 = C.white,
            TextSize = 34,
            Font = Enum.Font.GothamBlack,
            TextTransparency = 1,
        }, Stage)
        letters[i] = {l = l, x = x}
    end

    local VerTag = new("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0, 148),
        Size = UDim2.fromOffset(190, 16),
        BackgroundTransparency = 1,
        Text = "HALLOWEEN EDITION  •  V5.1",
        TextColor3 = C.sub,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextTransparency = 1,
    }, Stage)

    -- barra de progresso
    local BarBack = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0, 176),
        Size = UDim2.new(0, 340, 0, 5),
        BackgroundColor3 = C.off,
        BorderSizePixel = 0,
    }, Stage)
    corner(BarBack, 3)
    local BarFill = new("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = C.white,
        BorderSizePixel = 0,
    }, BarBack)
    corner(BarFill, 3)
    new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(110, 110, 116)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
        }),
    }, BarFill)
    local BarGlow = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = C.white,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
    }, BarFill)
    corner(BarGlow, 7)

    local Loading = new("TextLabel", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, -170, 0, 196),
        Size = UDim2.fromOffset(260, 16),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = C.text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Stage)

    local Percent = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(0, 170, 0, 196),
        Size = UDim2.fromOffset(70, 16),
        BackgroundTransparency = 1,
        Text = "0%",
        TextColor3 = C.white,
        TextSize = 12,
        Font = Enum.Font.GothamBlack,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, Stage)

    -- checklist das etapas
    local INTRO_TIME = 5.2
    local IntroSteps = {
        {0.0, "Invocando os espiritos"},
        {1.0, "Acendendo as aboboras"},
        {2.0, "Despertando os morcegos"},
        {3.0, "Enchendo o saco de doces"},
        {4.0, "Abrindo o portal"},
    }
    local stepLabels = {}
    for i, s in ipairs(IntroSteps) do
        stepLabels[i] = new("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 0, 0, 226 + (i - 1) * 16),
            Size = UDim2.fromOffset(300, 14),
            BackgroundTransparency = 1,
            Text = "○  " .. s[2],
            TextColor3 = C.off,
            TextSize = 11,
            Font = Enum.Font.Gotham,
        }, Stage)
    end

    local Tip = new("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0, 328),
        Size = UDim2.fromOffset(420, 16),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = C.sub,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextTransparency = 0.2,
    }, Stage)
    local TIPS = {
        "Dica: RightShift esconde e mostra o menu.",
        "Dica: ligue a Noite Assombrada na aba HALLOWEEN.",
        "Dica: a aba HALLOWEEN tem musicas de terror e chuva de emojis.",
        "Dica: ESP de aboboras e doces para eventos de Halloween.",
        "Dica: use o Modo Vassoura para voar pelo mapa.",
        "Dica: cuidado... nem todo fantasma e amigavel.",
    }

    -- morcegos voando pela tela
    local bats = {}
    for i = 1, 7 do
        bats[i] = {
            l = new("TextLabel", {
                Size = UDim2.fromOffset(34, 34),
                BackgroundTransparency = 1,
                Text = "🦇",
                TextSize = 22 + (i % 3) * 6,
                ZIndex = 3,
            }, Intro),
            sp = 0.05 + math.random() * 0.06, ph = math.random() * 10,
            y = 0.08 + math.random() * 0.75, dir = (i % 2 == 0) and 1 or -1,
        }
    end
    local function animateBats(now)
        for _, b in ipairs(bats) do
            local x = ((now * b.sp * b.dir + b.ph) % 1.3) - 0.15
            b.l.Position = UDim2.new(x, 0, b.y + math.sin(now * 3 + b.ph) * 0.03, 0)
            b.l.Rotation = math.sin(now * 6 + b.ph) * 12
        end
    end

    task.spawn(function()
        local start = os.clock()
        local last = start
        while os.clock() - start < INTRO_TIME do
            local now = os.clock()
            local dt, elapsed = now - last, now - start
            last = now
            local pulse = math.sin(now * 3)

            introParticles(dt, now)
            animateBats(now)
            Scan.Position = UDim2.new(0, 0, (now * 0.22) % 1, 0)
            Ring1.Rotation = Ring1.Rotation + 2.8
            Ring2.Rotation = Ring2.Rotation - 1.7
            Ring3.Rotation = Ring3.Rotation + 1.0
            Ring4.Rotation = Ring4.Rotation - 0.6
            animatePumpkin(Skull, now)
            CircleStroke.Transparency = 0.2 + math.abs(pulse) * 0.3

            for i, o in ipairs(Orbs) do
                local a = now * (1.2 + (i % 3) * 0.35) + (i / #Orbs) * math.pi * 2
                local r = 128 + math.sin(now * 2 + i) * 10 + (i % 3) * 14
                o.Position = UDim2.new(0, math.cos(a) * r, 0, LOGO_Y + math.sin(a) * r)
            end

            -- titulo letra por letra com brilho
            for i, d in ipairs(letters) do
                local a = math.clamp((elapsed - 0.35 - i * 0.08) / 0.35, 0, 1)
                d.l.TextTransparency = 1 - a
                d.l.Position = UDim2.new(0, d.x, 0, 116 + (1 - a) * 18)
                local g = 0.72 + 0.28 * math.sin(now * 4 - i * 0.6)
                d.l.TextColor3 = Color3.new(1, 0.42 + 0.38 * g, 0.08 + 0.1 * g)
            end
            VerTag.TextTransparency = 1 - math.clamp((elapsed - 1.2) / 0.5, 0, 1)

            -- progresso suave com pequenas "travadas"
            local raw = math.clamp(elapsed / INTRO_TIME, 0, 1)
            local p = raw * raw * (3 - 2 * raw)
            BarFill.Size = UDim2.new(p, 0, 1, 0)
            BarGlow.BackgroundTransparency = 0.5 + math.abs(pulse) * 0.4
            Percent.Text = math.floor(p * 100) .. "%"

            local cur = 1
            for i, s in ipairs(IntroSteps) do
                if elapsed >= s[1] then
                    cur = i
                end
            end
            for i, s in ipairs(IntroSteps) do
                local lab = stepLabels[i]
                if i < cur then
                    lab.Text = "✓  " .. s[2]
                    lab.TextColor3 = C.sub
                elseif i == cur then
                    lab.Text = "▸  " .. s[2]
                    lab.TextColor3 = C.white
                else
                    lab.Text = "○  " .. s[2]
                    lab.TextColor3 = C.off
                end
            end

            local msg = string.upper(IntroSteps[cur][2])
            local chars = math.clamp(math.floor((elapsed - IntroSteps[cur][1]) * 40), 0, #msg)
            Loading.Text = string.sub(msg, 1, chars) .. ((math.floor(now * 3) % 2 == 0) and "▌" or "") ..
                string.rep(".", math.floor(now * 2) % 4)

            local tipIdx = math.floor(elapsed / 1.3) % #TIPS + 1
            Tip.Text = TIPS[tipIdx]
            task.wait()
        end
        for i, s in ipairs(IntroSteps) do
            stepLabels[i].Text = "✓  " .. s[2]
            stepLabels[i].TextColor3 = C.sub
        end
        BarFill.Size = UDim2.new(1, 0, 1, 0)
        Percent.Text = "100%"
    end)

    task.wait(INTRO_TIME + 0.15)

    -- saida: onda de choque + fade
    local Shock = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0, LOGO_Y),
        Size = UDim2.new(0, 120, 0, 120),
        BackgroundTransparency = 1,
    }, Stage)
    corner(Shock, 1000)
    local ShockStroke = stroke(Shock, C.white, 3, 0)
    tween(Shock, 0.8, {Size = UDim2.new(0, 2200, 0, 2200)}, Enum.EasingStyle.Quad)
    tween(ShockStroke, 0.8, {Transparency = 1})
    tween(Skull.scale, 0.45, {Scale = 1.5}, Enum.EasingStyle.Back)
    tween(StageScale, 0.5, {Scale = StageScale.Scale * 1.12})
    fadeAll(Stage, 0.4)
    task.wait(0.45)
    fadeAll(Intro, 0.3)
    tween(Intro, 0.3, {BackgroundTransparency = 1})
    task.wait(0.35)
    Intro.Visible = false

    ----------------------------------------------------------------------
    -- TELA DE KEY v5
    ----------------------------------------------------------------------
    local KW, KH = 430, 340
    local KeyFrame = new("Frame", {
        Name = "KeyFrame",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, KW, 0, KH),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, KeyGui)
    corner(KeyFrame, 16)
    new("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 15, 42)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 6, 20)),
        }),
    }, KeyFrame)
    local KeyStroke = stroke(KeyFrame, C.accent, 1.6, 0.25)
    local KeyGrad = new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, C.line),
            ColorSequenceKeypoint.new(0.5, C.white),
            ColorSequenceKeypoint.new(1, C.line),
        }),
    }, KeyStroke)

    local keyParticles = makeEmojiParticles(KeyFrame, 12, {"🦇", "👻", "🎃", "🕸", "🍬"})

    local keyBase = vpScale(560)
    local KeyScale = new("UIScale", {Scale = keyBase * 0.6}, KeyFrame)
    tween(KeyScale, 0.6, {Scale = keyBase}, Enum.EasingStyle.Back)

    -- icone animado
    local KeyIcon = new("TextLabel", {
        Position = UDim2.new(0, 20, 0, 18),
        Size = UDim2.new(0, 48, 0, 48),
        BackgroundColor3 = C.item,
        Text = "🎃",
        TextSize = 28,
        Font = Enum.Font.GothamBlack,
        TextColor3 = C.white,
        BorderSizePixel = 0,
    }, KeyFrame)
    corner(KeyIcon, 12)
    local IconStroke = stroke(KeyIcon, C.line, 1.5, 0.2)
    local IconGrad = new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, C.line),
            ColorSequenceKeypoint.new(0.5, C.white),
            ColorSequenceKeypoint.new(1, C.line),
        }),
    }, IconStroke)

    local KeyTitle = new("TextLabel", {
        Position = UDim2.new(0, 82, 0, 17),
        Size = UDim2.new(0, 124, 0, 28),
        BackgroundTransparency = 1,
        Text = "LOST HUB",
        TextColor3 = C.white,
        TextSize = 22,
        Font = Enum.Font.GothamBlack,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, KeyFrame)

    local KeyTag = new("TextLabel", {
        Position = UDim2.new(0, 214, 0, 22),
        Size = UDim2.new(0, 34, 0, 18),
        BackgroundColor3 = C.item,
        Text = "HW",
        TextColor3 = C.accent,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
    }, KeyFrame)
    corner(KeyTag, 5)

    local KeySubtitle = new("TextLabel", {
        Position = UDim2.new(0, 82, 0, 49),
        Size = UDim2.new(1, -100, 0, 18),
        BackgroundTransparency = 1,
        Text = "Diga a senha para atravessar o portal...",
        TextColor3 = C.sub,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, KeyFrame)

    new("Frame", {
        Position = UDim2.new(0, 20, 0, 84),
        Size = UDim2.new(1, -40, 0, 1),
        BackgroundColor3 = C.line,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
    }, KeyFrame)

    new("TextLabel", {
        Position = UDim2.new(0, 22, 0, 98),
        Size = UDim2.new(0, 120, 0, 14),
        BackgroundTransparency = 1,
        Text = "SUA KEY",
        TextColor3 = C.sub,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, KeyFrame)

    local KeyInput = new("TextBox", {
        Position = UDim2.new(0, 20, 0, 116),
        Size = UDim2.new(1, -40, 0, 46),
        BackgroundColor3 = C.item,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        PlaceholderText = "Digite ou cole sua key...",
        PlaceholderColor3 = C.sub,
        Text = "",
        TextColor3 = C.white,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, KeyFrame)
    corner(KeyInput, 10)
    new("UIPadding", {PaddingLeft = UDim.new(0, 46), PaddingRight = UDim.new(0, 56)}, KeyInput)
    local InputStroke = stroke(KeyInput, C.line, 1.2)

    new("TextLabel", {
        Position = UDim2.new(0, 32, 0, 127),
        Size = UDim2.fromOffset(24, 24),
        BackgroundTransparency = 1,
        Text = "🔑",
        TextSize = 15,
        TextColor3 = C.white,
        Font = Enum.Font.GothamBold,
        ZIndex = 3,
    }, KeyFrame)
    local Counter = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -32, 0, 129),
        Size = UDim2.fromOffset(40, 18),
        BackgroundTransparency = 1,
        Text = "0",
        TextColor3 = C.sub,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 3,
    }, KeyFrame)
    KeyInput:GetPropertyChangedSignal("Text"):Connect(function()
        Counter.Text = tostring(#KeyInput.Text)
    end)

    local Remember = true
    local RememberBtn = new("TextButton", {
        Position = UDim2.new(0, 20, 0, 176),
        Size = UDim2.new(0, 150, 0, 22),
        BackgroundTransparency = 1,
        Text = "☑  Lembrar key",
        TextColor3 = C.text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
    }, KeyFrame)
    RememberBtn.MouseButton1Click:Connect(function()
        Remember = not Remember
        RememberBtn.Text = (Remember and "☑" or "☐") .. "  Lembrar key"
        RememberBtn.TextColor3 = Remember and C.text or C.sub
    end)

    local Tries = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -20, 0, 176),
        Size = UDim2.new(0, 170, 0, 22),
        BackgroundTransparency = 1,
        Text = "Tentativas 0/" .. MAX_TRIES,
        TextColor3 = C.sub,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, KeyFrame)

    local Enter = new("TextButton", {
        Position = UDim2.new(0, 20, 0, 210),
        Size = UDim2.new(1, -40, 0, 44),
        BackgroundColor3 = C.hover,
        BorderSizePixel = 0,
        Text = "ABRIR O PORTAL",
        TextColor3 = C.white,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        ClipsDescendants = true,
    }, KeyFrame)
    corner(Enter, 10)
    local EnterStroke = stroke(Enter, C.line, 1)
    local EnterGrad = new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 190, 195)),
        }),
        Rotation = 90,
    }, Enter)

    local ProgBack = new("Frame", {
        Position = UDim2.new(0, 20, 0, 266),
        Size = UDim2.new(1, -40, 0, 3),
        BackgroundColor3 = C.off,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
    }, KeyFrame)
    corner(ProgBack, 2)
    local ProgFill = new("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = C.white,
        BorderSizePixel = 0,
    }, ProgBack)
    corner(ProgFill, 2)

    local Status = new("TextLabel", {
        Position = UDim2.new(0, 20, 0, 278),
        Size = UDim2.new(1, -40, 0, 20),
        BackgroundTransparency = 1,
        Text = "O portal aguarda sua key...",
        TextColor3 = C.sub,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
    }, KeyFrame)

    new("TextLabel", {
        Position = UDim2.new(0, 20, 0, 312),
        Size = UDim2.new(1, -40, 0, 16),
        BackgroundTransparency = 1,
        Text = "Lost Hub Halloween Edition  •  RightShift esconde o menu",
        TextColor3 = C.off,
        TextSize = 9,
        Font = Enum.Font.Gotham,
    }, KeyFrame)

    Enter.MouseEnter:Connect(function()
        tween(Enter, 0.15, {BackgroundColor3 = C.line})
        tween(EnterStroke, 0.15, {Color = C.accent})
    end)
    Enter.MouseLeave:Connect(function()
        tween(Enter, 0.15, {BackgroundColor3 = C.hover})
        tween(EnterStroke, 0.15, {Color = C.line})
    end)
    KeyInput.Focused:Connect(function()
        tween(InputStroke, 0.2, {Color = C.accent, Thickness = 1.8})
    end)
    KeyInput.FocusLost:Connect(function()
        tween(InputStroke, 0.2, {Color = C.line, Thickness = 1.2})
    end)

    local keyAnimating = true
    task.spawn(function()
        local last = os.clock()
        while keyAnimating do
            local now = os.clock()
            KeyGrad.Rotation = (KeyGrad.Rotation + 1.8) % 360
            IconGrad.Rotation = (IconGrad.Rotation - 3) % 360
            KeyIcon.Rotation = math.sin(now * 2) * 4
            keyParticles(now - last, now)
            last = now
            task.wait()
        end
    end)

    local checking, tries, lockedUntil = false, 0, 0
    local function setStatus(text, col)
        Status.Text = text
        Status.TextColor3 = col or C.sub
    end

    local function shake()
        local original = KeyFrame.Position
        for i = 1, 8 do
            KeyFrame.Position = original + UDim2.new(0, (i % 2 == 0 and 10 or -10), 0, 0)
            task.wait(0.03)
        end
        KeyFrame.Position = original
    end

    local function lockout()
        lockedUntil = os.clock() + LOCK_TIME
        task.spawn(function()
            while os.clock() < lockedUntil and not keyOk do
                local left = math.ceil(lockedUntil - os.clock())
                Enter.Text = "BLOQUEADO (" .. left .. "s)"
                setStatus("Muitas tentativas. Aguarde " .. left .. "s.", C.bad)
                ProgFill.Size = UDim2.new(1 - (lockedUntil - os.clock()) / LOCK_TIME, 0, 1, 0)
                ProgFill.BackgroundColor3 = C.bad
                task.wait(0.1)
            end
            if not keyOk then
                tries = 0
                Tries.Text = "Tentativas 0/" .. MAX_TRIES
                Enter.Text = "ABRIR O PORTAL"
                ProgFill.Size = UDim2.new(0, 0, 1, 0)
                ProgFill.BackgroundColor3 = C.white
                setStatus("Pode tentar novamente.", C.sub)
            end
        end)
    end

    local function checkKey()
        if checking or keyOk or os.clock() < lockedUntil then
            return
        end
        checking = true

        local txt = trim(KeyInput.Text)
        if #txt == 0 then
            setStatus("Digite a key primeiro.", C.bad)
            checking = false
            return
        end

        setStatus("Verificando...", C.text)
        Enter.Text = "INVOCANDO..."
        ProgFill.BackgroundColor3 = C.white
        tween(ProgFill, 0.55, {Size = UDim2.new(1, 0, 1, 0)}, Enum.EasingStyle.Quad)
        task.wait(0.6)

        if KEYS[txt] then
            keyOk = true
            setStatus("✓ O portal se abriu... boo!", C.ok)
            Enter.Text = "🎃  PORTAL ABERTO"
            tween(Enter, 0.25, {BackgroundColor3 = C.white, TextColor3 = C.bg})
            tween(KeyStroke, 0.25, {Thickness = 4})
            tween(KeyIcon, 0.3, {BackgroundColor3 = C.white, TextColor3 = C.bg})
            if writefile then
                pcall(function()
                    if Remember then
                        writefile(KEY_FILE, txt)
                    elseif isfile and isfile(KEY_FILE) and delfile then
                        delfile(KEY_FILE)
                    end
                end)
            end
            task.wait(0.7)
        else
            tries = tries + 1
            Tries.Text = "Tentativas " .. tries .. "/" .. MAX_TRIES
            setStatus("✕ Os espiritos recusaram essa key!", C.bad)
            Enter.Text = "ABRIR O PORTAL"
            ProgFill.Size = UDim2.new(0, 0, 1, 0)
            tween(InputStroke, 0.15, {Color = C.bad})
            shake()
            tween(InputStroke, 0.4, {Color = C.line})
            KeyInput.Text = ""
            if tries >= MAX_TRIES then
                lockout()
            end
        end

        checking = false
    end

    Enter.MouseButton1Click:Connect(checkKey)
    KeyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            checkKey()
        end
    end)

    -- key salva: preenche e entra sozinho
    task.spawn(function()
        if readfile and isfile then
            local ok, saved = pcall(function()
                if isfile(KEY_FILE) then
                    return trim(readfile(KEY_FILE))
                end
            end)
            if ok and saved and KEYS[saved] then
                KeyInput.Text = saved
                setStatus("Key salva encontrada. Entrando...", C.text)
                task.wait(1)
                checkKey()
            end
        end
    end)

    repeat
        task.wait()
    until keyOk

    keyAnimating = false
    tween(KeyScale, 0.45, {Scale = keyBase * 1.15}, Enum.EasingStyle.Quad)
    tween(KeyFrame, 0.45, {BackgroundTransparency = 1})
    fadeAll(KeyFrame, 0.35)
    task.wait(0.5)

    pcall(function()
        KeyGui:Destroy()
    end)
    pcall(function()
        tween(Blur, 0.5, {Size = 0})
        task.delay(0.55, function()
            pcall(function()
                Blur:Destroy()
            end)
        end)
    end)
end

--==================================================
-- ESTADO / CONEXOES
--==================================================
local State = {
    Speed = 16, Jump = 50, SpeedMode = "WalkSpeed",
    SpeedOn = false, JumpOn = false,
    InfJump = false, Noclip = false, Bhop = false,
    Fly = false, FlySpeed = 60,
    AntiAFK = false, AntiFling = false, RespawnBack = false, CamNoclip = false,
    CamFov = false, CamFovVal = 90,
    Fullbright = false, NoFog = false, XRay = false,
    Trigger = false,
    Hitbox = false, HitSize = 8,
    AutoClick = false, CPS = 10,
    InstaPrompt = false, AutoPrompt = false,
    AutoCollect = false, CollectRange = 60,
    TPClick = false,
    Crosshair = false,
    Rainbow = false,
    Particles = true,
    TitleGlitch = true,
    Spin = false, SpinSpeed = 20,
    Neon = false,
    ChatSpam = false, ChatDelay = 4, ChatMsg = "Lost Hub on top",
    -- novos v5
    AntiVoid = false, FallGuard = false,
    AutoRejoin = false, AutoHop = false, HopMin = 15,
    EnemyAlert = false, AlertDist = 60,
}

local alive = true
local Conns = {}
local Ticks = {}      -- funcoes chamadas todo frame (dt, t)
local Toggles, Sliders = {}, {}
local X = {}          -- funcoes/estado extras (evita limite de locals)

local function bind(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Conns, c)
    return c
end

local function getChar() return LocalPlayer.Character end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

--==================================================
-- NOTIFICACOES
--==================================================
local ToastGui = new("ScreenGui", {
    Name = "LostHubToast",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 10,
}, guiParent)

local ToastHolder = new("Frame", {
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -16, 1, -16),
    Size = UDim2.new(0, 290, 1, -32),
    BackgroundTransparency = 1,
}, ToastGui)

new("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
}, ToastHolder)

local function notify(title, msg, dur, kind)
    dur = dur or 3
    local icon, icolor = "ℹ", C.accent
    if kind == "ok" then icon, icolor = "✓", Color3.fromRGB(120, 220, 150)
    elseif kind == "err" then icon, icolor = "✕", C.bad end

    local wrap = new("Frame", {Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1}, ToastHolder)
    local card = new("Frame", {
        Position = UDim2.new(1, 60, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
    }, wrap)
    corner(card, 10)
    stroke(card, C.line, 1)

    local ic = new("TextLabel", {
        Position = UDim2.new(0, 10, 0.5, -15),
        Size = UDim2.new(0, 30, 0, 30),
        BackgroundColor3 = C.item,
        Text = icon,
        TextColor3 = icolor,
        TextSize = 16,
        Font = Enum.Font.GothamBlack,
    }, card)
    corner(ic, 8)

    new("TextLabel", {
        Position = UDim2.new(0, 48, 0, 8),
        Size = UDim2.new(1, -58, 0, 16),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = C.white,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, card)

    new("TextLabel", {
        Position = UDim2.new(0, 48, 0, 25),
        Size = UDim2.new(1, -58, 0, 18),
        BackgroundTransparency = 1,
        Text = msg,
        TextColor3 = C.sub,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, card)

    local bar = new("Frame", {
        Position = UDim2.new(0, 10, 1, -6),
        Size = UDim2.new(1, -20, 0, 2),
        BackgroundColor3 = icolor,
        BorderSizePixel = 0,
    }, card)
    corner(bar, 1)

    tween(card, 0.4, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Back)
    tween(bar, dur, {Size = UDim2.new(0, 0, 0, 2)}, Enum.EasingStyle.Linear)

    task.delay(dur, function()
        tween(card, 0.3, {Position = UDim2.new(1, 60, 0, 0)})
        task.wait(0.3)
        wrap:Destroy()
    end)
end

--==================================================
-- MAIN GUI
--==================================================
local MAIN_W, MAIN_H = 600, 470

local Gui = new("ScreenGui", {
    Name = "LostHub",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, guiParent)

local Main = new("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, MAIN_W, 0, MAIN_H),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
}, Gui)
corner(Main, 14)
new("UIGradient", {
    Rotation = 90,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(32, 13, 36)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(11, 4, 15)),
    }),
}, Main)

local UIBase = 1
local MainScale = new("UIScale", {Scale = 0.7}, Main)
tween(MainScale, 0.55, {Scale = UIBase}, Enum.EasingStyle.Back)

local MainStroke = stroke(Main, C.accent, 1.5, 0.15)
local StrokeGrad = new("UIGradient", {}, MainStroke)

local ParticleLayer = new("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    ZIndex = 0,
}, Main)
local mainParticleStep, mainParticleList = makeParticles(ParticleLayer, 30, C.accent)
table.insert(Ticks, function(dt, t)
    if State.Particles then
        mainParticleStep(dt, t)
    end
end)

local TopBar = new("Frame", {
    Size = UDim2.new(1, 0, 0, 56),
    BackgroundTransparency = 1,
}, Main)

local Title = new("TextLabel", {
    Position = UDim2.new(0, 20, 0, 10),
    Size = UDim2.new(0, 220, 0, 24),
    BackgroundTransparency = 1,
    Text = "🎃  LOST HUB",
    TextColor3 = C.white,
    TextSize = 19,
    Font = Enum.Font.GothamBlack,
    TextXAlignment = Enum.TextXAlignment.Left,
}, TopBar)

local TitleGrad = new("UIGradient", {}, Title)

local VersionTag = new("TextLabel", {
    Position = UDim2.new(0, 168, 0, 13),
    Size = UDim2.new(0, 34, 0, 16),
    BackgroundColor3 = C.item,
    Text = "HW",
    TextColor3 = C.accent,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
}, TopBar)
corner(VersionTag, 5)
onAccent(function(col) VersionTag.TextColor3 = col end)

local GameLabel = new("TextLabel", {
    Position = UDim2.new(0, 22, 0, 33),
    Size = UDim2.new(0, 330, 0, 14),
    BackgroundTransparency = 1,
    Text = "halloween edition • 🎃🦇👻",
    TextColor3 = C.sub,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
}, TopBar)

local FPSLabel = new("TextLabel", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -125, 0, 20),
    Size = UDim2.new(0, 190, 0, 16),
    BackgroundTransparency = 1,
    Text = "60 FPS",
    TextColor3 = C.sub,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Right,
}, TopBar)

-- tema dinamico
onAccent(function(col)
    MainStroke.Color = col
    StrokeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, shade(col, 0.22)),
        ColorSequenceKeypoint.new(0.5, Color3.new(
            math.clamp(col.R + 0.35, 0, 1), math.clamp(col.G + 0.35, 0, 1), math.clamp(col.B + 0.35, 0, 1))),
        ColorSequenceKeypoint.new(1, shade(col, 0.22)),
    })
    TitleGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, shade(col, 0.65)),
        ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, shade(col, 0.65)),
    })
    for _, p in ipairs(mainParticleList) do
        p.f.BackgroundColor3 = col
    end
end)

local function windowButton(text, xOffset, hoverColor)
    local b = new("TextButton", {
        Position = UDim2.new(1, xOffset, 0, 13),
        Size = UDim2.new(0, 30, 0, 30),
        BackgroundColor3 = C.item,
        Text = text,
        TextColor3 = C.text,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, TopBar)
    corner(b, 8)
    local sc = new("UIScale", {Scale = 1}, b)
    b.MouseEnter:Connect(function()
        tween(b, 0.15, {BackgroundColor3 = hoverColor or C.hover})
        tween(sc, 0.15, {Scale = 1.1}, Enum.EasingStyle.Back)
    end)
    b.MouseLeave:Connect(function()
        tween(b, 0.15, {BackgroundColor3 = C.item})
        tween(sc, 0.15, {Scale = 1})
    end)
    return b
end

local Close = windowButton("×", -45, Color3.fromRGB(110, 35, 40))
local Minimize = windowButton("−", -80, C.hover)

new("Frame", {
    Position = UDim2.new(0, 14, 0, 56),
    Size = UDim2.new(1, -28, 0, 1),
    BackgroundColor3 = C.line,
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
}, Main)

-- brilho que corre pela linha do topo
local Sweep = new("Frame", {
    Position = UDim2.new(0, 14, 0, 56),
    Size = UDim2.new(0, 110, 0, 1),
    BackgroundColor3 = C.white,
    BorderSizePixel = 0,
    ZIndex = 3,
}, Main)
new("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1),
    }),
}, Sweep)
table.insert(Ticks, function(dt, t)
    Sweep.Position = UDim2.new(0, 14 + ((t * 0.35) % 1) * (MAIN_W - 28 - 110), 0, 56)
end)

local Sidebar = new("Frame", {
    Position = UDim2.new(0, 12, 0, 66),
    Size = UDim2.new(0, 124, 1, -78),
    BackgroundColor3 = C.panel,
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
}, Main)
corner(Sidebar, 10)

local TabIndicator = new("Frame", {
    Position = UDim2.new(0, 0, 0, 14),
    Size = UDim2.new(0, 3, 0, 22),
    BackgroundColor3 = C.white,
    BorderSizePixel = 0,
}, Sidebar)
corner(TabIndicator, 2)
onAccent(function(col)
    TabIndicator.BackgroundColor3 = col
end)

-- cartao do jogador (parte de baixo da sidebar)
do
    local card = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -8),
        Size = UDim2.new(1, -16, 0, 46),
        BackgroundColor3 = C.item,
        BorderSizePixel = 0,
    }, Sidebar)
    corner(card, 8)
    local av = new("ImageLabel", {
        Position = UDim2.new(0, 6, 0.5, -15),
        Size = UDim2.new(0, 30, 0, 30),
        BackgroundColor3 = C.off,
        BorderSizePixel = 0,
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=60&h=60",
    }, card)
    corner(av, 15)
    local avStroke = stroke(av, C.accent, 1.5, 0.2)
    onAccent(function(col) avStroke.Color = col end)
    new("TextLabel", {
        Position = UDim2.new(0, 42, 0, 8),
        Size = UDim2.new(1, -46, 0, 14),
        BackgroundTransparency = 1,
        Text = LocalPlayer.DisplayName,
        TextColor3 = C.white,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, card)
    local dot = new("Frame", {
        Position = UDim2.new(0, 42, 0, 28),
        Size = UDim2.new(0, 6, 0, 6),
        BackgroundColor3 = Color3.fromRGB(110, 225, 140),
        BorderSizePixel = 0,
    }, card)
    corner(dot, 3)
    X.SessionLabel = new("TextLabel", {
        Position = UDim2.new(0, 52, 0, 24),
        Size = UDim2.new(1, -56, 0, 14),
        BackgroundTransparency = 1,
        Text = "Online 00:00",
        TextColor3 = C.sub,
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)
    X.SessionStart = os.clock()
    table.insert(Ticks, function(dt, t)
        dot.BackgroundTransparency = 0.5 - math.sin(t * 3) * 0.5
        local s = math.floor(os.clock() - X.SessionStart)
        X.SessionLabel.Text = string.format("Online %02d:%02d", math.floor(s / 60) % 100, s % 60)
    end)
end

local Content = new("Frame", {
    Position = UDim2.new(0, 148, 0, 66),
    Size = UDim2.new(1, -160, 1, -78),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
}, Main)

--==================================================
-- PAGINAS / TABS
--==================================================
local Pages = {}
local TabButtons = {}
local scrollBars = {}

local function createPage(name)
    local Page = new("ScrollingFrame", {
        Name = name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, Content)
    table.insert(scrollBars, Page)

    new("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, Page)

    new("UIPadding", {
        PaddingRight = UDim.new(0, 6),
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 8),
    }, Page)

    Pages[name] = Page
    return Page
end

onAccent(function(col)
    for _, p in ipairs(scrollBars) do
        p.ScrollBarImageColor3 = col
    end
end)

local currentTab
local function setActiveTab(tabName)
    currentTab = tabName
    for name, data in pairs(TabButtons) do
        local active = name == tabName
        tween(data.button, 0.2, {
            BackgroundColor3 = active and C.item or C.panel,
            TextColor3 = active and C.white or C.sub,
        })
        if active then
            tween(TabIndicator, 0.35, {Position = UDim2.new(0, 0, 0, data.y + 6)}, Enum.EasingStyle.Back)
        end
    end
end

local function showPage(name, tabName)
    for pageName, page in pairs(Pages) do
        page.Visible = pageName == name
    end
    local page = Pages[name]
    if page then
        page.Position = UDim2.new(0, 22, 0, 0)
        tween(page, 0.35, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Quint)
        local i = 0
        for _, child in ipairs(page:GetChildren()) do
            if child:IsA("GuiObject") then
                i = i + 1
                if i <= 14 then
                    local sc = child:FindFirstChild("EnterScale")
                    if sc then
                        sc.Scale = 0.94
                        task.delay(i * 0.02, function()
                            tween(sc, 0.25, {Scale = 1}, Enum.EasingStyle.Back)
                        end)
                    end
                end
            end
        end
    end
    if tabName then
        setActiveTab(tabName)
    end
end

local function createTab(text, pageName, order)
    local y = 8 + (order - 1) * 36
    local Button = new("TextButton", {
        Position = UDim2.new(0, -140, 0, y),
        Size = UDim2.new(1, -16, 0, 31),
        BackgroundColor3 = C.panel,
        Text = text,
        TextColor3 = C.sub,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, Sidebar)
    corner(Button, 8)
    Button.TextScaled = true
    new("UITextSizeConstraint", {MaxTextSize = 11, MinTextSize = 7}, Button)
    new("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}, Button)
    TabButtons[pageName] = {button = Button, y = y}

    task.delay(0.15 + order * 0.07, function()
        tween(Button, 0.45, {Position = UDim2.new(0, 8, 0, y)}, Enum.EasingStyle.Back)
    end)

    Button.MouseEnter:Connect(function()
        tween(Button, 0.15, {TextColor3 = C.white})
    end)
    Button.MouseLeave:Connect(function()
        if currentTab == pageName then
            return
        end
        tween(Button, 0.15, {TextColor3 = C.sub})
    end)
    Button.MouseButton1Click:Connect(function()
        showPage(pageName, pageName)
    end)
end

local Principal = createPage("Principal")
local Halloween = createPage("Halloween")
local Visual = createPage("Visual")
local Combate = createPage("Combate")
local Troll = createPage("Troll")
local Mundo = createPage("Mundo")
local Otimizacao = createPage("Otimizacao")
local Scripts = createPage("Scripts")
local Config = createPage("Config")

createTab("🎃  PRINCIPAL", "Principal", 1)
createTab("🦇  HALLOWEEN", "Halloween", 2)
createTab("👁  VISUAL", "Visual", 3)
createTab("🔪  COMBATE", "Combate", 4)
createTab("👻  TROLL", "Troll", 5)
createTab("🕸  MUNDO", "Mundo", 6)
createTab("⚡  OTIMIZAÇÃO", "Otimizacao", 7)
createTab("📜  SCRIPTS", "Scripts", 8)
createTab("⚙  CONFIG", "Config", 9)

--==================================================
-- COMPONENTES
--==================================================
local UI = {}

local function enterScale(o)
    new("UIScale", {Name = "EnterScale", Scale = 1}, o)
end

local function ripple(btn)
    local m = UserInputService:GetMouseLocation()
    local rel = m - btn.AbsolutePosition
    local r = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(rel.X, rel.Y),
        Size = UDim2.fromOffset(0, 0),
        BackgroundColor3 = C.white,
        BackgroundTransparency = 0.78,
        BorderSizePixel = 0,
        ZIndex = btn.ZIndex + 5,
    }, btn)
    corner(r, 500)
    local s = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2.4
    tween(r, 0.55, {Size = UDim2.fromOffset(s, s), BackgroundTransparency = 1})
    task.delay(0.6, function()
        r:Destroy()
    end)
end

function UI.Section(parent, text)
    local holder = new("Frame", {Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1}, parent)
    local size = TextService:GetTextSize(text, 11, Enum.Font.GothamBold, Vector2.new(1000, 24))
    local lab = new("TextLabel", {
        Size = UDim2.new(0, size.X + 4, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.accent,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, holder)
    onAccent(function(col)
        lab.TextColor3 = col
    end)
    new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, size.X + 12, 0.5, 0),
        Size = UDim2.new(1, -(size.X + 12), 0, 1),
        BackgroundColor3 = C.line,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
    }, holder)
    return holder
end

function UI.Label(parent, text, height)
    return new("TextLabel", {
        Size = UDim2.new(1, 0, 0, height or 30),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.sub,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, parent)
end

function UI.Toggle(parent, text, default, callback, key)
    local row = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = C.item,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, parent)
    corner(row, 8)
    enterScale(row)
    local rowStroke = stroke(row, C.accent, 1, 1)

    new("TextLabel", {
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -70, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local track = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 38, 0, 20),
        BackgroundColor3 = C.off,
        BorderSizePixel = 0,
    }, row)
    corner(track, 10)

    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14),
        BackgroundColor3 = C.sub,
        BorderSizePixel = 0,
    }, track)
    corner(knob, 7)

    local enabled = false
    local obj = {}
    local function set(v, silent)
        enabled = v and true or false
        tween(track, 0.2, {BackgroundColor3 = enabled and C.accent or C.off})
        tween(rowStroke, 0.25, {Transparency = enabled and 0.65 or 1})
        tween(knob, 0.3, {
            Position = enabled and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
            BackgroundColor3 = enabled and C.bg or C.sub,
            Size = UDim2.new(0, 14, 0, 14),
        }, Enum.EasingStyle.Back)
        if not silent and callback then
            task.spawn(callback, enabled)
        end
    end

    onAccent(function(col)
        rowStroke.Color = col
        if enabled then
            track.BackgroundColor3 = col
        end
    end)

    row.MouseEnter:Connect(function()
        tween(row, 0.15, {BackgroundColor3 = C.hover})
    end)
    row.MouseLeave:Connect(function()
        tween(row, 0.15, {BackgroundColor3 = C.item})
    end)
    row.MouseButton1Down:Connect(function()
        tween(knob, 0.1, {Size = UDim2.new(0, 18, 0, 14)})
    end)
    row.MouseButton1Click:Connect(function()
        ripple(row)
        set(not enabled)
    end)

    if default then
        set(true)
    end

    obj.Set = set
    obj.Get = function() return enabled end
    if key then
        Toggles[key] = obj
    end
    return obj
end

function UI.Button(parent, text, callback)
    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = C.item,
        Text = text,
        TextColor3 = C.text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ClipsDescendants = true,
    }, parent)
    corner(btn, 8)
    enterScale(btn)
    local st = stroke(btn, C.line, 1, 0.6)
    local scale = new("UIScale", {Scale = 1}, btn)

    btn.MouseEnter:Connect(function()
        tween(btn, 0.15, {BackgroundColor3 = C.hover, TextColor3 = C.white})
        tween(st, 0.15, {Transparency = 0.1})
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, 0.15, {BackgroundColor3 = C.item, TextColor3 = C.text})
        tween(st, 0.15, {Transparency = 0.6})
        tween(scale, 0.1, {Scale = 1})
    end)
    btn.MouseButton1Down:Connect(function()
        tween(scale, 0.08, {Scale = 0.97})
    end)
    btn.MouseButton1Up:Connect(function()
        tween(scale, 0.18, {Scale = 1}, Enum.EasingStyle.Back)
    end)
    btn.MouseButton1Click:Connect(function()
        ripple(btn)
        if callback then
            task.spawn(callback)
        end
    end)

    return btn
end

function UI.Input(parent, text, default, callback)
    local Box = new("TextBox", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = C.item,
        Text = tostring(default),
        PlaceholderText = text,
        TextColor3 = C.white,
        PlaceholderColor3 = C.sub,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
    }, parent)
    corner(Box, 8)
    enterScale(Box)
    local st = stroke(Box, C.line, 1, 0.6)

    Box.Focused:Connect(function()
        tween(st, 0.2, {Color = C.accent, Transparency = 0})
    end)
    Box.FocusLost:Connect(function()
        tween(st, 0.2, {Color = C.line, Transparency = 0.6})
        local number = tonumber(Box.Text)
        if number then
            callback(number)
        else
            Box.Text = tostring(default)
        end
    end)
    return Box
end

function UI.TextInput(parent, placeholder, default, callback)
    local Box = new("TextBox", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = C.item,
        Text = default or "",
        PlaceholderText = placeholder,
        TextColor3 = C.white,
        PlaceholderColor3 = C.sub,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
    }, parent)
    corner(Box, 8)
    enterScale(Box)
    local st = stroke(Box, C.line, 1, 0.6)
    Box.Focused:Connect(function()
        tween(st, 0.2, {Color = C.accent, Transparency = 0})
    end)
    Box.FocusLost:Connect(function()
        tween(st, 0.2, {Color = C.line, Transparency = 0.6})
        if callback then
            callback(Box.Text)
        end
    end)
    return Box
end

function UI.Slider(parent, text, min, max, default, callback, key)
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = C.item,
        BorderSizePixel = 0,
    }, parent)
    corner(row, 8)
    enterScale(row)

    new("TextLabel", {
        Position = UDim2.new(0, 12, 0, 6),
        Size = UDim2.new(1, -80, 0, 18),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local valueLabel = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 6),
        Size = UDim2.new(0, 60, 0, 18),
        BackgroundTransparency = 1,
        Text = tostring(default),
        TextColor3 = C.white,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, row)

    local bar = new("Frame", {
        Position = UDim2.new(0, 12, 0, 35),
        Size = UDim2.new(1, -24, 0, 6),
        BackgroundColor3 = C.off,
        BorderSizePixel = 0,
    }, row)
    corner(bar, 3)

    local fill = new("Frame", {
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
    }, bar)
    corner(fill, 3)
    onAccent(function(col)
        fill.BackgroundColor3 = col
    end)

    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 12, 0, 12),
        BackgroundColor3 = C.white,
        BorderSizePixel = 0,
    }, fill)
    corner(knob, 6)

    local value = default
    local function apply(v, silent)
        v = math.clamp(math.floor(v + 0.5), min, max)
        value = v
        valueLabel.Text = tostring(v)
        tween(fill, 0.08, {Size = UDim2.new((v - min) / (max - min), 0, 1, 0)}, Enum.EasingStyle.Linear)
        if not silent then
            callback(v)
        end
    end

    local dragging = false
    local function update(inputX)
        local a = math.clamp((inputX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        apply(min + (max - min) * a)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            tween(knob, 0.15, {Size = UDim2.new(0, 17, 0, 17)}, Enum.EasingStyle.Back)
            update(input.Position.X)
        end
    end)
    bind(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end)
    bind(UserInputService.InputEnded, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            tween(knob, 0.15, {Size = UDim2.new(0, 12, 0, 12)}, Enum.EasingStyle.Back)
        end
    end)

    local obj = {Frame = row, Set = apply, Get = function() return value end}
    if key then
        Sliders[key] = obj
    end
    return obj
end

function UI.Cycle(parent, text, options, default, callback)
    local idx = table.find(options, default) or 1
    local b
    b = UI.Button(parent, text .. ": " .. options[idx], function()
        idx = idx % #options + 1
        b.Text = text .. ": " .. options[idx]
        callback(options[idx])
    end)
    return b
end

function UI.Dropdown(parent, text, getOptions, callback)
    local wrap = new("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.item,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, parent)
    corner(wrap, 8)
    enterScale(wrap)
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3)}, wrap)

    local head = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        Text = "   " .. text .. "  ▾",
        TextColor3 = C.text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 0,
    }, wrap)

    local holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible = false,
        LayoutOrder = 1,
    }, wrap)
    new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 3),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    }, holder)
    new("UIPadding", {PaddingBottom = UDim.new(0, 6)}, holder)

    local open = false
    local function rebuild()
        for _, c in ipairs(holder:GetChildren()) do
            if c:IsA("TextButton") then
                c:Destroy()
            end
        end
        for _, opt in ipairs(getOptions()) do
            local b = new("TextButton", {
                Size = UDim2.new(1, -12, 0, 28),
                BackgroundColor3 = C.panel,
                Text = tostring(opt),
                TextColor3 = C.text,
                TextSize = 11,
                Font = Enum.Font.Gotham,
                AutoButtonColor = false,
                BorderSizePixel = 0,
            }, holder)
            corner(b, 6)
            b.MouseEnter:Connect(function()
                tween(b, 0.12, {BackgroundColor3 = C.hover})
            end)
            b.MouseLeave:Connect(function()
                tween(b, 0.12, {BackgroundColor3 = C.panel})
            end)
            b.MouseButton1Click:Connect(function()
                head.Text = "   " .. text .. ": " .. tostring(opt) .. "  ▾"
                open = false
                holder.Visible = false
                callback(opt)
            end)
        end
    end

    head.MouseButton1Click:Connect(function()
        open = not open
        if open then
            rebuild()
        end
        holder.Visible = open
    end)
    return wrap
end

--==================================================
-- AIMBOT / TRIGGER / HITBOX
--==================================================
local Aim = {
    On = false, FOV = 120, Smooth = 30,
    TeamCheck = true, WallCheck = true,
    Part = "Head", ShowFOV = true, ShowTarget = true,
    Predict = 0,
    Always = false,
    Sticky = true,
    Mode = "Cursor",
    Key = "Botao direito",
    MaxDist = 1500,
    Locked = nil,
}

local FOVGui = new("ScreenGui", {
    Name = "LostHubFOV",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, guiParent)

local FOVCircle = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.new(0, Aim.FOV * 2, 0, Aim.FOV * 2),
    BackgroundTransparency = 1,
    Visible = false,
}, FOVGui)
corner(FOVCircle, 1000)
local FOVStroke = stroke(FOVCircle, C.accent, 1.5, 0.3)
onAccent(function(col)
    FOVStroke.Color = col
end)

local TargetMark = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.new(0, 14, 0, 14),
    BackgroundTransparency = 1,
    Visible = false,
}, FOVGui)
corner(TargetMark, 7)
local TargetStroke = stroke(TargetMark, C.white, 2, 0)
local TargetName = new("TextLabel", {
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 1, 4),
    Size = UDim2.new(0, 120, 0, 14),
    BackgroundTransparency = 1,
    TextColor3 = C.white,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextStrokeTransparency = 0.4,
}, TargetMark)

local CrossH = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 16, 0, 16),
    BackgroundTransparency = 1,
    Visible = false,
}, FOVGui)
local chParts = {
    new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0, BackgroundColor3 = C.white}, CrossH),
    new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 2, 1, 0), BorderSizePixel = 0, BackgroundColor3 = C.white}, CrossH),
}
onAccent(function(col)
    for _, p in ipairs(chParts) do
        p.BackgroundColor3 = col
    end
    TargetStroke.Color = col
end)

local function isVisible(part)
    local camera = workspace.CurrentCamera
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    local origin = camera.CFrame.Position
    local res = workspace:Raycast(origin, part.Position - origin, params)
    return res == nil or res.Instance:IsDescendantOf(part.Parent)
end

local function aimPart(char)
    local names = {Aim.Part, "Head", "UpperTorso", "Torso", "HumanoidRootPart"}
    for _, n in ipairs(names) do
        local p = char:FindFirstChild(n)
        if p and p:IsA("BasePart") then
            return p
        end
    end
end

local function validPlayer(pl)
    if pl == LocalPlayer then return false end
    local char = pl.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if Aim.TeamCheck and pl.Team ~= nil and pl.Team == LocalPlayer.Team then return false end
    if char:FindFirstChildOfClass("ForceField") then return false end
    return true
end

local function scoreTarget(pl, cam, mouse)
    local part = aimPart(pl.Character)
    if not part then return end
    local pos, onScreen = cam:WorldToViewportPoint(part.Position)
    if not onScreen then return end
    local dc = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
    if dc > Aim.FOV then return end
    local dist = (cam.CFrame.Position - part.Position).Magnitude
    if dist > Aim.MaxDist then return end
    if Aim.WallCheck and not isVisible(part) then return end
    local hum = pl.Character:FindFirstChildOfClass("Humanoid")
    local score = dc
    if Aim.Mode == "Distancia" then
        score = dist
    elseif Aim.Mode == "Vida" then
        score = hum.Health
    end
    return score, part
end

local function getTarget()
    local cam = workspace.CurrentCamera
    local mouse = UserInputService:GetMouseLocation()
    local bestPl, bestPart, bestScore = nil, nil, math.huge
    for _, pl in ipairs(Players:GetPlayers()) do
        if validPlayer(pl) then
            local s, part = scoreTarget(pl, cam, mouse)
            if s and s < bestScore then
                bestPl, bestPart, bestScore = pl, part, s
            end
        end
    end
    return bestPl, bestPart
end

local function aimHeld()
    if Aim.Always then return true end
    local k = Aim.Key
    if k == "Botao direito" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif k == "Botao esquerdo" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    elseif k == "Shift" then
        return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    elseif k == "Q" then
        return UserInputService:IsKeyDown(Enum.KeyCode.Q)
    elseif k == "E" then
        return UserInputService:IsKeyDown(Enum.KeyCode.E)
    end
    return false
end

local lastTrig = 0
table.insert(Ticks, function(dt)
    local mousePos = UserInputService:GetMouseLocation()
    FOVCircle.Visible = Aim.On and Aim.ShowFOV
    FOVCircle.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
    FOVCircle.Size = UDim2.new(0, Aim.FOV * 2, 0, Aim.FOV * 2)
    CrossH.Visible = State.Crosshair

    if State.Trigger and os.clock() - lastTrig > 0.12 then
        local t = Mouse.Target
        local model = t and t:FindFirstAncestorOfClass("Model")
        local pl = model and Players:GetPlayerFromCharacter(model)
        if pl and validPlayer(pl) then
            lastTrig = os.clock()
            pcall(function()
                if mouse1click then
                    mouse1click()
                else
                    VirtualUser:ClickButton1(Vector2.new())
                end
            end)
        end
    end

    if not Aim.On then
        Aim.Locked = nil
        TargetMark.Visible = false
        return
    end

    local holding = aimHeld()
    tween(FOVStroke, 0.1, {Transparency = holding and 0 or 0.3})
    if not holding then
        Aim.Locked = nil
        TargetMark.Visible = false
        return
    end

    local cam = workspace.CurrentCamera
    local part
    if Aim.Sticky and Aim.Locked then
        if validPlayer(Aim.Locked) then
            part = aimPart(Aim.Locked.Character)
            if part and Aim.WallCheck and not isVisible(part) then
                part = nil
                Aim.Locked = nil
            end
        else
            Aim.Locked = nil
        end
    end
    if not part then
        local pl, p = getTarget()
        Aim.Locked = pl
        part = p
    end

    if part then
        local aimPos = part.Position + part.AssemblyLinearVelocity * (Aim.Predict / 100)
        local goal = CFrame.new(cam.CFrame.Position, aimPos)
        local a = 1 - (1 - math.clamp(Aim.Smooth / 100, 0.01, 1)) ^ (math.clamp(dt, 0, 0.1) * 60)
        cam.CFrame = cam.CFrame:Lerp(goal, a)

        if Aim.ShowTarget then
            local sp, on = cam:WorldToViewportPoint(part.Position)
            TargetMark.Visible = on
            TargetMark.Position = UDim2.fromOffset(sp.X, sp.Y)
            TargetName.Text = Aim.Locked and Aim.Locked.DisplayName or ""
        end
    else
        TargetMark.Visible = false
    end
end)

local HitOrig = {}
task.spawn(function()
    while alive do
        for _, pl in ipairs(Players:GetPlayers()) do
            local root = pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
            if root then
                if State.Hitbox then
                    if not HitOrig[root] then
                        HitOrig[root] = {root.Size, root.Transparency, root.CanCollide}
                    end
                    root.Size = Vector3.new(State.HitSize, State.HitSize, State.HitSize)
                    root.Transparency = 0.75
                    root.CanCollide = false
                elseif HitOrig[root] then
                    root.Size, root.Transparency, root.CanCollide = unpack(HitOrig[root])
                    HitOrig[root] = nil
                end
            end
        end
        task.wait(0.25)
    end
end)

local function restoreHitbox()
    for root, d in pairs(HitOrig) do
        pcall(function()
            root.Size, root.Transparency, root.CanCollide = unpack(d)
        end)
        HitOrig[root] = nil
    end
end

--==================================================
-- ESP (chams, caixa 2D, nome, vida, distancia, tracers)
--==================================================
local ESPGui = new("ScreenGui", {
    Name = "LostHubESP",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, guiParent)

local ESP = {
    Chams = false, Box = false, Names = false, Health = false, Tracers = false,
    TeamColor = false, TeamCheck = false, MaxDist = 2000, TracerFrom = "Baixo",
    ColorFn = nil,
}
local ESPData = {}

local function clearESP(pl)
    local d = ESPData[pl]
    if d then
        for _, k in ipairs({"hl", "box", "line"}) do
            if d[k] then
                pcall(function() d[k]:Destroy() end)
            end
        end
        ESPData[pl] = nil
    end
end

local function espColor(pl)
    if ESP.ColorFn then
        local ok, c = pcall(ESP.ColorFn, pl)
        if ok and c then
            return c
        end
    end
    if ESP.TeamColor and pl.Team then
        return pl.TeamColor.Color
    end
    return C.accent
end

local function ensureBox(d)
    if d.box then return end
    local box = new("Frame", {BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false}, ESPGui)
    d.boxStroke = stroke(box, C.white, 1.5, 0)
    d.name = new("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 0, -2),
        Size = UDim2.new(0, 160, 0, 14),
        BackgroundTransparency = 1,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextColor3 = C.white,
        TextStrokeTransparency = 0.4,
    }, box)
    d.info = new("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 1, 2),
        Size = UDim2.new(0, 160, 0, 12),
        BackgroundTransparency = 1,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextColor3 = C.text,
        TextStrokeTransparency = 0.5,
    }, box)
    d.hbBack = new("Frame", {
        Position = UDim2.new(0, -6, 0, 0),
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BorderSizePixel = 0,
    }, box)
    d.hbFill = new("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(80, 230, 120),
        BorderSizePixel = 0,
    }, d.hbBack)
    d.box = box
end

local function updateESP()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local anyBox = ESP.Box or ESP.Names or ESP.Health
    local any = anyBox or ESP.Chams or ESP.Tracers
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then
            local char = pl.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local skip = ESP.TeamCheck and pl.Team ~= nil and pl.Team == LocalPlayer.Team
            local dist = root and (cam.CFrame.Position - root.Position).Magnitude or math.huge

            if any and root and hum and hum.Health > 0 and not skip and dist <= ESP.MaxDist then
                local d = ESPData[pl]
                if not d then
                    d = {}
                    ESPData[pl] = d
                end
                local col = espColor(pl)

                if ESP.Chams then
                    if not d.hl or d.hl.Parent ~= char then
                        if d.hl then d.hl:Destroy() end
                        d.hl = new("Highlight", {
                            Name = "LostESP",
                            FillTransparency = 0.55,
                            OutlineTransparency = 0,
                            DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                            Adornee = char,
                        }, char)
                    end
                    d.hl.FillColor = col
                    d.hl.OutlineColor = C.white
                elseif d.hl then
                    d.hl:Destroy()
                    d.hl = nil
                end

                if anyBox then
                    ensureBox(d)
                    local head = char:FindFirstChild("Head")
                    local topW = (head and head.Position or root.Position + Vector3.new(0, 2, 0)) + Vector3.new(0, 0.7, 0)
                    local botW = root.Position - Vector3.new(0, 3, 0)
                    local t = cam:WorldToViewportPoint(topW)
                    local b = cam:WorldToViewportPoint(botW)
                    if t.Z > 0 and b.Z > 0 then
                        local h = math.abs(b.Y - t.Y)
                        local w = h * 0.58
                        d.box.Position = UDim2.fromOffset((t.X + b.X) / 2 - w / 2, math.min(t.Y, b.Y))
                        d.box.Size = UDim2.fromOffset(w, h)
                        d.box.Visible = true
                        d.boxStroke.Enabled = ESP.Box
                        d.boxStroke.Color = col
                        d.name.Visible = ESP.Names
                        d.info.Visible = ESP.Names
                        d.name.Text = pl.DisplayName
                        d.name.TextColor3 = col
                        local tool = char:FindFirstChildOfClass("Tool")
                        d.info.Text = string.format("[%dm]%s", math.floor(dist), tool and ("  " .. tool.Name) or "")
                        d.hbBack.Visible = ESP.Health
                        local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                        d.hbFill.Size = UDim2.new(1, 0, pct, 0)
                        d.hbFill.BackgroundColor3 = Color3.fromRGB(255, 70, 70):Lerp(Color3.fromRGB(80, 230, 120), pct)
                    else
                        d.box.Visible = false
                    end
                elseif d.box then
                    d.box.Visible = false
                end

                if ESP.Tracers then
                    if not d.line then
                        d.line = new("Frame", {
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            BorderSizePixel = 0,
                            BackgroundTransparency = 0.25,
                        }, ESPGui)
                    end
                    local v = cam:WorldToViewportPoint(root.Position)
                    if v.Z > 0 then
                        local vp = cam.ViewportSize
                        local from
                        if ESP.TracerFrom == "Centro" then
                            from = Vector2.new(vp.X / 2, vp.Y / 2)
                        elseif ESP.TracerFrom == "Mouse" then
                            from = UserInputService:GetMouseLocation()
                        else
                            from = Vector2.new(vp.X / 2, vp.Y)
                        end
                        local to = Vector2.new(v.X, v.Y)
                        local delta = to - from
                        d.line.Visible = true
                        d.line.Size = UDim2.fromOffset(delta.Magnitude, 1.5)
                        d.line.Position = UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2)
                        d.line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
                        d.line.BackgroundColor3 = col
                    else
                        d.line.Visible = false
                    end
                elseif d.line then
                    d.line:Destroy()
                    d.line = nil
                end
            else
                clearESP(pl)
            end
        end
    end
end

table.insert(Ticks, updateESP)
bind(Players.PlayerRemoving, clearESP)

--==================================================
-- SCANNER (prompts / objetos) + ESP DE OBJETOS
--==================================================
local Obj = {On = false, Keywords = {}, HL = {}}
local Scan = {prompts = {}, objs = {}}

local function setKeywords(list)
    local out = {}
    for _, k in ipairs(list) do
        local s = tostring(k):lower():gsub("^%s+", ""):gsub("%s+$", "")
        if #s > 0 then
            table.insert(out, s)
        end
    end
    Obj.Keywords = out
end

local function partOf(o)
    if o:IsA("BasePart") then
        return o
    end
    return o:FindFirstChildWhichIsA("BasePart", true)
end

local function nameHas(d, kws)
    local n = d.Name:lower()
    for _, k in ipairs(kws) do
        if n:find(k, 1, true) then
            return true
        end
    end
    return false
end

task.spawn(function()
    while alive do
        local needP = State.InstaPrompt or State.AutoPrompt
        local needO = (Obj.On or State.AutoCollect) and #Obj.Keywords > 0
        if needP or needO then
            local prompts, objs = {}, {}
            local kws = Obj.Keywords
            local count = 0
            for i, d in ipairs(workspace:GetDescendants()) do
                if needP and d:IsA("ProximityPrompt") then
                    table.insert(prompts, d)
                elseif needO and count < 300 and (d:IsA("BasePart") or d:IsA("Model")) then
                    if nameHas(d, kws) then
                        count = count + 1
                        table.insert(objs, d)
                    end
                end
                if i % 4000 == 0 then
                    task.wait()
                end
            end
            Scan.prompts, Scan.objs = prompts, objs
        end
        task.wait(2.5)
    end
end)

local function clearObj()
    for o, h in pairs(Obj.HL) do
        pcall(function()
            h.hl:Destroy()
            h.bb:Destroy()
        end)
        Obj.HL[o] = nil
    end
end

task.spawn(function()
    while alive do
        if Obj.On and #Obj.Keywords > 0 then
            local root = getRoot()
            local list = {}
            for _, o in ipairs(Scan.objs) do
                if o.Parent then
                    table.insert(list, o)
                end
            end
            if root then
                table.sort(list, function(a, b)
                    local pa, pb = partOf(a), partOf(b)
                    if not pa then return false end
                    if not pb then return true end
                    return (pa.Position - root.Position).Magnitude < (pb.Position - root.Position).Magnitude
                end)
            end
            local seen = {}
            for i = 1, math.min(#list, 25) do
                local o = list[i]
                seen[o] = true
                if not Obj.HL[o] then
                    local p = partOf(o)
                    local entry = {}
                    entry.hl = new("Highlight", {
                        FillColor = C.accent,
                        OutlineColor = C.white,
                        FillTransparency = 0.5,
                        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                        Adornee = o,
                    }, o)
                    entry.bb = new("BillboardGui", {
                        Size = UDim2.fromOffset(120, 18),
                        StudsOffset = Vector3.new(0, 2.5, 0),
                        AlwaysOnTop = true,
                        Adornee = p,
                    }, p or o)
                    entry.lab = new("TextLabel", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = o.Name,
                        TextColor3 = C.white,
                        TextSize = 11,
                        Font = Enum.Font.GothamBold,
                        TextStrokeTransparency = 0.4,
                    }, entry.bb)
                    Obj.HL[o] = entry
                end
                local e = Obj.HL[o]
                local p = partOf(o)
                if root and p and e.lab then
                    e.lab.Text = string.format("%s [%dm]", o.Name, math.floor((p.Position - root.Position).Magnitude))
                end
            end
            for o, h in pairs(Obj.HL) do
                if not seen[o] then
                    pcall(function()
                        h.hl:Destroy()
                        h.bb:Destroy()
                    end)
                    Obj.HL[o] = nil
                end
            end
        else
            clearObj()
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while alive do
        if State.InstaPrompt then
            for _, p in ipairs(Scan.prompts) do
                pcall(function() p.HoldDuration = 0 end)
            end
        end
        task.wait(1)
    end
end)

task.spawn(function()
    while alive do
        local root = getRoot()
        if root and State.AutoPrompt and fireproximityprompt then
            for _, p in ipairs(Scan.prompts) do
                pcall(function()
                    if p.Enabled and p.Parent then
                        local pos
                        if p.Parent:IsA("BasePart") then
                            pos = p.Parent.Position
                        elseif p.Parent:IsA("Attachment") then
                            pos = p.Parent.WorldPosition
                        end
                        if pos and (pos - root.Position).Magnitude <= p.MaxActivationDistance then
                            fireproximityprompt(p)
                        end
                    end
                end)
            end
        end
        task.wait(0.3)
    end
end)

task.spawn(function()
    while alive do
        local root = getRoot()
        if root and State.AutoCollect and firetouchinterest then
            for _, o in ipairs(Scan.objs) do
                pcall(function()
                    local part = o.Parent and partOf(o)
                    if part and (part.Position - root.Position).Magnitude <= State.CollectRange then
                        firetouchinterest(root, part, 0)
                        task.wait()
                        firetouchinterest(root, part, 1)
                    end
                end)
            end
        end
        task.wait(0.4)
    end
end)

task.spawn(function()
    while alive do
        if State.AutoClick then
            pcall(function()
                if mouse1click then
                    mouse1click()
                else
                    VirtualUser:ClickButton1(Vector2.new())
                end
            end)
            task.wait(1 / math.max(State.CPS, 1))
        else
            task.wait(0.2)
        end
    end
end)

--==================================================
-- HELPERS DE JOGO
--==================================================
local function tpTo(pos)
    local root = getRoot()
    if root then
        root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    end
end

local function smoothTeleport(pos, duration)
    local root = getRoot()
    if not root then
        notify("Erro", "Personagem nao encontrado.", 3, "err")
        return
    end
    local target = CFrame.new(pos + Vector3.new(0, 3, 0))
    local dist = (root.Position - target.Position).Magnitude
    local time = duration or math.max(dist / 140, 0.4)

    root.Anchored = true
    local tw = TweenService:Create(root, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = target})
    tw:Play()
    tw.Completed:Wait()
    root.Anchored = false
end

local function highestPart(container)
    local best, bestY = nil, -math.huge
    local i = 0
    for _, d in ipairs(container:GetDescendants()) do
        i = i + 1
        if i % 5000 == 0 then task.wait() end
        if d:IsA("BasePart") and d.Anchored and d.CanCollide
            and not (d.Parent and d.Parent:FindFirstChildOfClass("Humanoid")) then
            local y = d.Position.Y + d.Size.Y / 2
            if y > bestY then
                best, bestY = d, y
            end
        end
    end
    return best, bestY
end

local function nearestObj(matchFn)
    local root = getRoot()
    if not root then return end
    local best, bestD = nil, math.huge
    local i = 0
    for _, d in ipairs(workspace:GetDescendants()) do
        i = i + 1
        if i % 5000 == 0 then task.wait() end
        if (d:IsA("BasePart") or d:IsA("Model")) and matchFn(d) then
            local p = partOf(d)
            if p then
                local dist = (p.Position - root.Position).Magnitude
                if dist < bestD then
                    best, bestD = p, dist
                end
            end
        end
    end
    return best
end

local function playerNames()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(t, p.Name)
        end
    end
    if #t == 0 then
        t[1] = "(ninguem)"
    end
    return t
end

local function preset(tog, sli)
    for k, v in pairs(tog or {}) do
        if Toggles[k] then Toggles[k].Set(v) end
    end
    for k, v in pairs(sli or {}) do
        if Sliders[k] then Sliders[k].Set(v) end
    end
end

local function serverHop()
    notify("Server Hop", "Procurando outro servidor...", 3)
    local ok, res = pcall(function()
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    if ok and res and res.data then
        for _, s in ipairs(res.data) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                return
            end
        end
    end
    notify("Server Hop", "Nenhum servidor disponivel.", 3, "err")
end

local function fpsBoost()
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    Lighting.GlobalShadows = false
    for _, d in ipairs(Lighting:GetChildren()) do
        if d:IsA("PostEffect") or d:IsA("Atmosphere") then
            pcall(function() d.Enabled = false end)
        end
    end
    local n = 0
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then
            pcall(function() d.Enabled = false end)
        elseif d:IsA("BasePart") then
            pcall(function()
                d.Material = Enum.Material.SmoothPlastic
                d.CastShadow = false
            end)
        end
        n = n + 1
        if n % 500 == 0 then task.wait() end
    end
    notify("FPS Boost", "Graficos reduzidos.", 3, "ok")
end

local function sendChat(msg)
    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            TextChatService.TextChannels.RBXGeneral:SendAsync(msg)
        else
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
        end
    end)
end

--==================================================
-- LOGICA EXTRA (troll, xray, neon, anti fling, respawn)
--==================================================
local TS = {Stick = false, Mode = "Atras", Dist = 5, OrbitSpeed = 3, Angle = 0, Sel = nil, Origin = nil}

local function selPlayer()
    local p = TS.Sel
    if p and p.Parent == Players then
        return p
    end
end
local function selRoot()
    local p = selPlayer()
    local c = p and p.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local NeonSaved = {}
local function restoreNeon()
    for p, d in pairs(NeonSaved) do
        pcall(function()
            p.Color, p.Material = d[1], d[2]
        end)
        NeonSaved[p] = nil
    end
end

local XRaySaved = {}
local function setXray(on)
    if on then
        task.spawn(function()
            local n = 0
            for _, d in ipairs(workspace:GetDescendants()) do
                if not State.XRay then break end
                if d:IsA("BasePart") and d.LocalTransparencyModifier == 0 then
                    local m = d:FindFirstAncestorOfClass("Model")
                    if not (m and Players:GetPlayerFromCharacter(m)) then
                        XRaySaved[d] = true
                        d.LocalTransparencyModifier = 0.65
                    end
                end
                n = n + 1
                if n % 1500 == 0 then task.wait() end
            end
        end)
    else
        for d in pairs(XRaySaved) do
            pcall(function() d.LocalTransparencyModifier = 0 end)
            XRaySaved[d] = nil
        end
    end
end

table.insert(Ticks, function(dt, t)
    local root = getRoot()
    if not root then return end

    if TS.Stick then
        local tr = selRoot()
        if tr then
            local cf
            if TS.Mode == "Atras" then
                cf = tr.CFrame * CFrame.new(0, 0, TS.Dist)
            elseif TS.Mode == "Frente" then
                cf = tr.CFrame * CFrame.new(0, 0, -TS.Dist) * CFrame.Angles(0, math.pi, 0)
            elseif TS.Mode == "Em cima" then
                cf = tr.CFrame * CFrame.new(0, TS.Dist, 0)
            else
                TS.Angle = TS.Angle + dt * TS.OrbitSpeed
                local off = Vector3.new(math.cos(TS.Angle) * TS.Dist, 0, math.sin(TS.Angle) * TS.Dist)
                cf = CFrame.new(tr.Position + off, tr.Position)
            end
            root.CFrame = cf
            root.AssemblyLinearVelocity = Vector3.zero
        end
    elseif State.Spin then
        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(State.SpinSpeed), 0)
    end

    if State.Neon then
        local char = getChar()
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                if not NeonSaved[p] then
                    NeonSaved[p] = {p.Color, p.Material}
                end
                p.Material = Enum.Material.Neon
                p.Color = Color3.fromHSV((t * 0.3) % 1, 0.8, 1)
            end
        end
    end
end)

local function flingPlayer(pl)
    local myRoot = getRoot()
    local tc = pl and pl.Character
    local tr = tc and tc:FindFirstChild("HumanoidRootPart")
    if not myRoot or not tr then
        notify("Fling", "Jogador invalido.", 3, "err")
        return
    end
    local origin = myRoot.CFrame
    local conn = RunService.Heartbeat:Connect(function()
        if myRoot.Parent and tr.Parent then
            myRoot.CFrame = tr.CFrame
            myRoot.AssemblyAngularVelocity = Vector3.new(0, 1e6, 0)
            myRoot.AssemblyLinearVelocity = Vector3.new(1e6, 1e6, 1e6)
        end
    end)
    task.wait(1.3)
    conn:Disconnect()
    for _ = 1, 6 do
        myRoot.AssemblyLinearVelocity = Vector3.zero
        myRoot.AssemblyAngularVelocity = Vector3.zero
        myRoot.CFrame = origin
        task.wait()
    end
end

bind(RunService.Stepped, function()
    if not State.AntiFling then return end
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character then
            for _, p in ipairs(pl.Character:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = false
                end
            end
        end
    end
end)

local deathCF
local function hookChar(c)
    local h = c:WaitForChild("Humanoid", 5)
    if h then
        h.Died:Connect(function()
            local r = c:FindFirstChild("HumanoidRootPart")
            if r then deathCF = r.CFrame end
        end)
    end
end
bind(LocalPlayer.CharacterAdded, function(c)
    task.spawn(hookChar, c)
    if State.RespawnBack and deathCF then
        local r = c:WaitForChild("HumanoidRootPart", 5)
        if r then
            task.wait(0.4)
            r.CFrame = deathCF
        end
        deathCF = nil
    end
end)
if getChar() then
    task.spawn(hookChar, getChar())
end

task.spawn(function()
    while alive do
        if State.ChatSpam and #State.ChatMsg > 0 then
            sendChat(State.ChatMsg)
            task.wait(math.max(State.ChatDelay, 3))
        else
            task.wait(0.4)
        end
    end
end)

--==================================================
-- NOVOS SISTEMAS v5
--==================================================
-- jogador mais proximo
function X.nearestPlayer()
    local r = getRoot()
    if not r then return end
    local best, bd
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local pr = p.Character:FindFirstChild("HumanoidRootPart")
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if pr and h and h.Health > 0 then
                local d = (pr.Position - r.Position).Magnitude
                if not bd or d < bd then
                    best, bd = p, d
                end
            end
        end
    end
    return best, bd
end

-- slots de posicao (3 slots, compartilhados por todos os jogos)
X.Slots = {}
function X.slotButtons(page)
    UI.Section(page, "POSICOES (3 SLOTS)")
    for i = 1, 3 do
        UI.Button(page, "💾  Salvar no slot " .. i, function()
            local r = getRoot()
            if r then
                X.Slots[i] = r.Position
                notify("Posicao", "Slot " .. i .. " salvo.", 2, "ok")
            end
        end)
        UI.Button(page, "↩  Ir para o slot " .. i, function()
            if X.Slots[i] then
                smoothTeleport(X.Slots[i])
            else
                notify("Posicao", "Slot " .. i .. " vazio.", 3, "err")
            end
        end)
    end
end

-- alerta de inimigo perto
X.lastAlert = 0
table.insert(Ticks, function()
    if not State.EnemyAlert or os.clock() - X.lastAlert < 2 then return end
    local p, d = X.nearestPlayer()
    if p and d <= State.AlertDist and not (Aim.TeamCheck and p.Team and p.Team == LocalPlayer.Team) then
        X.lastAlert = os.clock()
        notify("Alerta", p.DisplayName .. " a " .. math.floor(d) .. " studs", 2, "err")
    end
end)

-- anti void + protecao de queda
X.lastSafe = nil
table.insert(Ticks, function()
    local r, h = getRoot(), getHum()
    if not r or not h then return end
    if h.FloorMaterial ~= Enum.Material.Air then
        X.lastSafe = r.CFrame
    end
    if State.AntiVoid and X.lastSafe and r.Position.Y < workspace.FallenPartsDestroyHeight + 60 then
        r.AssemblyLinearVelocity = Vector3.zero
        r.CFrame = X.lastSafe + Vector3.new(0, 4, 0)
        notify("Anti Void", "Voce foi trazido de volta.", 2, "ok")
    end
    if State.FallGuard and r.AssemblyLinearVelocity.Y < -70 then
        r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -35, r.AssemblyLinearVelocity.Z)
    end
end)

-- auto rejoin ao ser desconectado
task.spawn(function()
    pcall(function()
        local overlay = CoreGui:WaitForChild("RobloxPromptGui", 10):WaitForChild("promptOverlay", 10)
        bind(overlay.ChildAdded, function(c)
            if State.AutoRejoin and c.Name == "ErrorPrompt" then
                task.wait(2)
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end)
            end
        end)
    end)
end)

-- server hop automatico a cada X minutos
task.spawn(function()
    local acc = 0
    while alive do
        task.wait(5)
        if State.AutoHop then
            acc = acc + 5
            if acc >= State.HopMin * 60 then
                acc = 0
                serverHop()
            end
        else
            acc = 0
        end
    end
end)

-- utilidades de jogadores proximos
function X.nearbyBlock(page, sub)
    UI.Section(page, "JOGADORES PROXIMOS")
    UI.Button(page, "📍  Teleportar ao mais proximo", function()
        local p = X.nearestPlayer()
        local r = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if r then tpTo(r.Position) else notify("Proximo", "Ninguem por perto.", 3, "err") end
    end)
    UI.Button(page, "👁  Observar o mais proximo", function()
        local p = X.nearestPlayer()
        local h = p and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if h then
            workspace.CurrentCamera.CameraSubject = h
            notify("Observar", p.DisplayName, 2, "ok")
        else
            notify("Proximo", "Ninguem por perto.", 3, "err")
        end
    end)
    UI.Button(page, "🌀  Orbitar o mais proximo", function()
        local p = X.nearestPlayer()
        if not p then notify("Proximo", "Ninguem por perto.", 3, "err") return end
        TS.Sel = p
        TS.Mode = "Orbitar"
        local r = getRoot()
        TS.Origin = r and r.CFrame
        TS.Stick = true
        if Toggles.stick then Toggles.stick.Set(true, true) end
        notify("Orbitar", p.DisplayName .. " (desligue em TROLL)", 3, "ok")
    end)
    UI.Button(page, "👁  Parar de observar", function()
        local h = getHum()
        if h then workspace.CurrentCamera.CameraSubject = h end
    end)
    UI.Toggle(page, "Alerta de inimigo perto", false, function(on) State.EnemyAlert = on end, (not sub) and "enemyalert" or nil)
    UI.Slider(page, "Distancia do alerta", 10, 300, State.AlertDist, function(v) State.AlertDist = v end, (not sub) and "alertdist" or nil)
end


--==================================================
-- MUSICA (player por ID + tentativa na boombox)
--==================================================
X.Music = {Vol = 50, Speed = 100, Loop = false, Queue = nil, QIdx = 0, Cur = nil, Fav = {}, token = 0, fails = 0}
X.MusicSound = new("Sound", {Name = "LostHubMusic", Volume = 2.5, Looped = false}, game:GetService("SoundService"))
X.FavFile = "LostHub_music.json"

pcall(function()
    if isfile and readfile and isfile(X.FavFile) then
        local d = HttpService:JSONDecode(readfile(X.FavFile))
        if type(d) == "table" then X.Music.Fav = d end
    end
end)
function X.saveFavs()
    if writefile then
        pcall(function() writefile(X.FavFile, HttpService:JSONEncode(X.Music.Fav)) end)
    end
end

function X.musicSetLabel(text)
    for _, l in ipairs(X.Music.labels or {}) do
        if l.Parent then l.Text = text end
    end
end

function X.musicPlay(id, name)
    local clean = tostring(id or ""):gsub("%D", "")
    if #clean == 0 then
        notify("Musica", "Digite um ID (so numeros).", 3, "err")
        return
    end
    local snd = X.MusicSound
    snd:Stop()
    snd.SoundId = "rbxassetid://" .. clean
    snd.Volume = X.Music.Vol / 20
    snd.PlaybackSpeed = X.Music.Speed / 100
    snd.Looped = X.Music.Loop and not X.Music.Queue
    X.Music.Cur = {id = clean, name = name or clean}
    X.Music.token = X.Music.token + 1
    local token = X.Music.token
    snd:Play()
    X.musicSetLabel("Carregando: " .. (name or clean) .. " ...")
    task.spawn(function()
        local t0 = os.clock()
        while token == X.Music.token and not snd.IsLoaded and os.clock() - t0 < 7 do
            task.wait(0.1)
        end
        if token ~= X.Music.token then return end
        if not snd.IsLoaded or snd.TimeLength <= 0 then
            X.musicSetLabel("Falhou: " .. (name or clean))
            notify("Musica", "Nao carregou (ID privado/removido): " .. (name or clean), 3, "err")
            if X.Music.Queue then
                X.Music.fails = X.Music.fails + 1
                if X.Music.fails >= #X.Music.Queue then
                    X.Music.Queue = nil
                    X.Music.fails = 0
                    notify("Playlist", "Nenhuma musica da lista carregou.", 4, "err")
                else
                    task.wait(0.3)
                    X.musicNext()
                end
            end
        else
            X.Music.fails = 0
            X.musicSetLabel("Tocando: " .. (name or clean))
            notify("Tocando", name or clean, 3, "ok")
        end
    end)
end

function X.musicNext()
    local q = X.Music.Queue
    if not q or #q == 0 then
        notify("Playlist", "Nenhuma playlist ativa.", 2, "err")
        return
    end
    X.Music.QIdx = X.Music.QIdx % #q + 1
    local s = q[X.Music.QIdx]
    X.musicPlay(s[2], s[1])
end

function X.musicQueue(list, shuffle)
    local q = {}
    for _, s in ipairs(list) do table.insert(q, s) end
    if shuffle then
        for i = #q, 2, -1 do
            local j = math.random(1, i)
            q[i], q[j] = q[j], q[i]
        end
    end
    X.Music.Queue, X.Music.QIdx, X.Music.fails = q, 0, 0
    X.musicNext()
end

function X.musicStop()
    X.Music.token = X.Music.token + 1
    X.Music.Queue = nil
    X.MusicSound:Stop()
    X.musicSetLabel("Nada tocando.")
end

bind(X.MusicSound.Ended, function()
    if X.Music.Queue then
        X.musicNext()
    end
end)

-- tentativa experimental de mandar o ID para a boombox do jogo
function X.boomboxSend(id)
    local clean = tostring(id or ""):gsub("%D", "")
    if #clean == 0 then
        notify("Boombox", "Digite um ID (so numeros).", 3, "err")
        return
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local tool
    for _, holder in ipairs({getChar(), bp}) do
        if holder then
            for _, t in ipairs(holder:GetChildren()) do
                if t:IsA("Tool") and t.Name:lower():find("boom") then
                    tool = t
                    break
                end
            end
        end
        if tool then break end
    end
    local remotes = {}
    local function isRemote(d) return d:IsA("RemoteEvent") or d:IsA("RemoteFunction") end
    if tool then
        local h = getHum()
        if h and tool.Parent == bp then pcall(function() h:EquipTool(tool) end) end
        for _, d in ipairs(tool:GetDescendants()) do
            if isRemote(d) then table.insert(remotes, d) end
        end
    end
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if isRemote(d) then
            local n = d.Name:lower()
            if n:find("boom") or n:find("music") or n:find("song") or n:find("radio") then
                table.insert(remotes, d)
            end
        end
    end
    if #remotes == 0 then
        notify("Boombox", "Nenhuma boombox/remote de musica achada.", 4, "err")
        return
    end
    local num = tonumber(clean)
    local patterns = {{clean}, {num}, {"Play", clean}, {"PlaySong", clean}, {"rbxassetid://" .. clean}}
    for _, r in ipairs(remotes) do
        for _, args in ipairs(patterns) do
            pcall(function()
                if r:IsA("RemoteEvent") then
                    r:FireServer(unpack(args))
                else
                    task.spawn(function() r:InvokeServer(unpack(args)) end)
                end
            end)
            task.wait(0.05)
        end
    end
    notify("Boombox", "Enviado para " .. #remotes .. " remote(s). Se ninguem ouvir, o jogo nao aceita ID customizado.", 5)
end

-- listas (IDs de sites publicos; alguns podem estar privados/removidos, a playlist pula sozinha)
X.MusicLists = {
    {"🎃 HALLOWEEN", {
        {"Spooky Scary Skeletons", "138081566"}, {"Spooky Scary Skeletons (alt)", "515669032"},
        {"Spooky Scary Skeletons (versao 3)", "142376088"}, {"Spooky Scary Skeletons (versao 4)", "100828050594137"},
        {"This Is Halloween", "349626331"}, {"This Is Halloween (alt)", "517273860"},
        {"Halloween Theme (Michael Myers)", "380808812"}, {"Halloween Kills Theme", "7757344022"},
        {"Creepy Music Box", "143382469"}, {"Scary Music Box", "209322206"},
        {"Spooky Month Theme", "6003667593"}, {"Spooky Seasonal Track", "11058768310"},
        {"Nightmare Music", "6991661856"}, {"Night OwL", "1843391637"}, {"Left for Dead", "1835370806"},
    }},
    {"🦇 AMBIENTE ASSOMBRADO", {
        {"Scary Forest", "139393062477955"}, {"Liminal Space Creepy Music", "134959834418523"},
        {"Scales of Horror Wind Up", "134348091099832"}, {"Cemetery of Masked Men", "95963342988177"},
        {"Horror Sweetheart", "133459153618562"}, {"Midnight Litany of Drones", "140704980462451"},
        {"Wailing Winds", "138056737764176"}, {"Forgotten Crypt", "139743346356072"},
        {"Chilling Fog", "140033496825661"}, {"Haunted Castle Melody", "138917352150837"},
        {"Simple Creepy Atmosphere", "139765110669684"}, {"Insane Patients", "1835337424"},
        {"Fear Enhancer", "1835337231"}, {"Clockwork Murder", "1835370059"},
        {"Sleep Paralysis", "1842447761"}, {"Eerie Memories", "1835261249"}, {"Demon Dimension", "1835356065"},
    }},
    {"🔥 PHONK", {
        {"Dark City Lights Phonk", "101101342670886"}, {"War Inside (Gym Phonk)", "78586039905107"},
        {"Lost Phonk", "139266399633943"}, {"Phonk Assassin Mode", "93666258819111"},
        {"GTR Phonk", "83624433031847"}, {"GTA VI Phonk", "112576678639596"},
        {"Phonk Drift", "72653741821355"}, {"Rogue City Phonk", "111109407506851"},
        {"Pure Phonk Violence", "96461852889782"}, {"Phonk Nightmare Race", "129127997655557"},
        {"Move Through Fire (Dark Duet)", "118673350158682"}, {"Final Ride Phonk", "86802355429172"},
        {"Mega Phonk", "134434412138800"}, {"Doggy Phonk", "123047130884626"},
        {"PHONK.exe", "97192334657561"}, {"Above Phonk", "89824897586105"},
        {"Jazz Metal Phonk", "135071730662747"}, {"Roblox Phonk", "136932193331774"},
        {"She Stares Intently", "136716637489655"}, {"The Night Burns Me", "101098976710405"},
        {"Dark Phonk Damage", "105529482486905"}, {"DTI Phonk", "139161205970637"},
        {"Blackout Drift", "85290495098172"}, {"Bloody Phonk", "136350225160627"},
        {"Burn the Night", "136579058345590"}, {"Cowbell God", "16190760005"},
        {"Down2Kill", "16190760285"}, {"Black Seed", "14145622615"},
        {"Bell Pepper", "14145626111"}, {"Dionic", "15689445424"},
        {"Phonk't Out", "14145625743"}, {"The Final Phonk", "14145620056"},
        {"Emotional Damage", "14145621151"},
    }},
    {"🇧🇷 PHONK BRASILEIRO", {
        {"Noite do Capim", "96688874266744"}, {"Aggressive Brazilian Phonk", "102892380593258"},
        {"Aura Saiyan Drop", "124170748342120"}, {"AURA = ∞", "76503495566299"},
        {"Brazilian Phonk Fiesta", "129276852097746"}, {"Brazilian Phonk", "108621585736031"},
        {"Montagem Panama", "110817176848617"}, {"Funk Azulejo", "81457346687617"},
        {"Toma Funk Phonk", "129098116998483"}, {"Phonk Da Rua", "104596909675653"},
        {"Batida Selvagem", "104603824839639"}, {"Spain vs Argentina", "139769280318833"},
        {"Happy Birthday (BR Phonk)", "94935794334796"}, {"Brazil Fiesta", "125498129824026"},
        {"Funk Fiesta", "139959590610806"}, {"Redline Brazilian Phonk", "133933510969921"},
        {"COBRA SA DUGO", "91707473577838"},
    }},
    {"🎤 FUNK", {
        {"Pavao Vandalo (Baile Drift)", "87624905430387"}, {"NIXHT FUNK", "87337128967086"},
        {"GENESIS FUNK", "108224715633346"}, {"Famino Funk", "106317184644394"},
        {"Funk Festa", "103409297553965"}, {"Brazilian F", "128275554636610"},
        {"Funk da Favela", "1837196820"}, {"Ready to Funk", "1836681101"},
        {"Tocatta Funk", "1840281557"}, {"Welcome Brazil", "1839555607"},
        {"Getting Loco", "1837255830"}, {"Massa", "1842497736"},
        {"F-360", "1841682637"}, {"Clap", "1845351312"},
        {"Dropskit", "5280905113"}, {"Waka Waka", "5506713323"},
    }},
    {"🐌 SLOWED / DARK", {
        {"OASIS PHONK (Slowed)", "127096476530496"}, {"Mano Mama Funk Phonk (Slowed)", "102827114027930"},
        {"Funk Inferna V2 (Deep Slowed)", "86375151296706"}, {"Chill Phonk", "136974179670066"},
        {"Toxic Smoke (Slowed 8D)", "139719375902695"}, {"Big Bad Wolf (Super Slowed)", "134108795864875"},
        {"Phonk of Darkness", "116896498238234"},
    }},
    {"🎧 LOFI / CHILL", {
        {"Lo-fi Chill A", "9043887091"}, {"Studying Alone Lofi", "74137426221090"},
        {"Clair de Lune", "1846051682"}, {"Chill Jazz", "926493242"}, {"Island Beach", "1839638511"},
    }},
    {"😂 VIRAIS / MEMES", {
        {"Old Town Road", "2862170886"}, {"Esketit", "1212786666"}, {"Banana Song", "169360242"},
        {"Caillou Trap Remix", "212675193"}, {"Harlem Shake", "131154740"}, {"BTS - Fire", "591276362"},
    }},
}

function X.musicBlock(page)
    UI.Section(page, "MUSICA")
    X.Music.labels = X.Music.labels or {}
    table.insert(X.Music.labels, UI.Label(page, "Nada tocando.", 16))
    UI.Label(page, "A musica toca so para voce. O botao da boombox e experimental: o Brookhaven atual pode nao aceitar IDs customizados.", 40)
    local box = UI.TextInput(page, "ID da musica (so numeros)...", "", nil)
    UI.Button(page, "▶  Tocar ID", function()
        X.Music.Queue = nil
        X.musicPlay(box.Text)
    end)
    UI.Button(page, "📻  Tentar enviar para a boombox (experimental)", function()
        X.boomboxSend(box.Text)
    end)
    UI.Button(page, "⏯  Pausar / Continuar", function()
        local snd = X.MusicSound
        if snd.IsPlaying then snd:Pause() else snd:Resume() end
    end)
    UI.Button(page, "⏭  Proxima da playlist", function() X.musicNext() end)
    UI.Button(page, "⏹  Parar", function() X.musicStop() end)
    UI.Slider(page, "Volume", 0, 100, X.Music.Vol, function(v)
        X.Music.Vol = v
        X.MusicSound.Volume = v / 20
    end)
    UI.Slider(page, "Velocidade % (menor = slowed)", 50, 150, X.Music.Speed, function(v)
        X.Music.Speed = v
        X.MusicSound.PlaybackSpeed = v / 100
    end)
    UI.Toggle(page, "Repetir musica", false, function(on)
        X.Music.Loop = on
        X.MusicSound.Looped = on and not X.Music.Queue
    end)

    UI.Section(page, "FAVORITOS")
    UI.Button(page, "⭐  Salvar ID atual nos favoritos", function()
        local id = (X.Music.Cur and X.Music.Cur.id) or tostring(box.Text):gsub("%D", "")
        if id and #id > 0 and not table.find(X.Music.Fav, id) then
            table.insert(X.Music.Fav, id)
            X.saveFavs()
            notify("Favoritos", "ID " .. id .. " salvo.", 2, "ok")
        else
            notify("Favoritos", "Nada para salvar (ou ja salvo).", 2, "err")
        end
    end)
    UI.Dropdown(page, "Favoritos", function()
        if #X.Music.Fav == 0 then return {"(vazio)"} end
        return X.Music.Fav
    end, function(opt)
        if opt ~= "(vazio)" then
            X.Music.Queue = nil
            X.musicPlay(opt)
        end
    end)
    UI.Button(page, "🗑  Limpar favoritos", function()
        X.Music.Fav = {}
        X.saveFavs()
    end)

    for _, list in ipairs(X.MusicLists) do
        UI.Section(page, list[1] .. " (" .. #list[2] .. ")")
        UI.Button(page, "🔀  Tocar tudo (aleatorio)", function()
            X.musicQueue(list[2], true)
        end)
        UI.Button(page, "▶  Tocar tudo (em ordem)", function()
            X.musicQueue(list[2], false)
        end)
        UI.Dropdown(page, "Escolher musica", function()
            local names = {}
            for _, s in ipairs(list[2]) do table.insert(names, s[1]) end
            return names
        end, function(name)
            for _, s in ipairs(list[2]) do
                if s[1] == name then
                    X.Music.Queue = nil
                    X.musicPlay(s[2], s[1])
                    return
                end
            end
        end)
    end
end
--==================================================
-- ABA: PRINCIPAL
--==================================================
do
    UI.Section(Principal, "PLAYER")
    UI.Toggle(Principal, "Speed", false, function(on) State.SpeedOn = on end, "speed")
    UI.Slider(Principal, "Velocidade", 16, 250, State.Speed, function(v) State.Speed = v end, "speedv")
    UI.Cycle(Principal, "Modo de velocidade", {"WalkSpeed", "CFrame"}, "WalkSpeed", function(v) State.SpeedMode = v end)
    UI.Toggle(Principal, "Jump", false, function(on) State.JumpOn = on end, "jump")
    UI.Slider(Principal, "Pulo", 50, 350, State.Jump, function(v) State.Jump = v end, "jumpv")
    UI.Toggle(Principal, "Infinite Jump", false, function(on) State.InfJump = on end, "infjump")
    UI.Toggle(Principal, "Bunny Hop (auto pulo ao andar)", false, function(on) State.Bhop = on end, "bhop")
    UI.Toggle(Principal, "Noclip", false, function(on) State.Noclip = on end, "noclip")

    UI.Section(Principal, "VOO")
    UI.Toggle(Principal, "Fly (WASD + Espaco / Shift)", false, function(on) State.Fly = on end, "fly")
    UI.Slider(Principal, "Fly Speed", 10, 300, State.FlySpeed, function(v) State.FlySpeed = v end, "flyv")

    UI.Section(Principal, "PROTECAO / UTIL")
    UI.Toggle(Principal, "Anti AFK", false, function(on) State.AntiAFK = on end, "antiafk")
    UI.Toggle(Principal, "Anti Fling (ignora colisao dos outros)", false, function(on) State.AntiFling = on end, "antifling")
    UI.Toggle(Principal, "Anti Void (volta se cair do mapa)", false, function(on) State.AntiVoid = on end, "antivoid")
    UI.Toggle(Principal, "Protecao de queda (reduz velocidade)", false, function(on) State.FallGuard = on end, "fallguard")
    UI.Toggle(Principal, "Auto Rejoin ao ser desconectado", false, function(on) State.AutoRejoin = on end, "autorejoin")
    UI.Toggle(Principal, "Renascer onde morreu", false, function(on) State.RespawnBack = on end, "respawnback")
    UI.Toggle(Principal, "Ctrl + Clique = Teleportar", false, function(on) State.TPClick = on end, "tpclick")
    UI.Toggle(Principal, "Camera atravessa paredes", false, function(on)
        State.CamNoclip = on
        pcall(function()
            LocalPlayer.DevCameraOcclusionMode = on and Enum.DevCameraOcclusionMode.Invisicam or Enum.DevCameraOcclusionMode.Zoom
        end)
    end, "camnoclip")

    UI.Section(Principal, "ACOES")
    UI.Button(Principal, "💀  Reset Character", function()
        local hum = getHum()
        if hum then hum.Health = 0 end
    end)
    UI.Button(Principal, "🪑  Sentar", function()
        local hum = getHum()
        if hum then hum.Sit = true end
    end)
    UI.Button(Principal, "🛑  Parar tudo (zerar velocidade)", function()
        local r = getRoot()
        if r then
            r.AssemblyLinearVelocity = Vector3.zero
            r.AssemblyAngularVelocity = Vector3.zero
        end
    end)
    UI.Button(Principal, "🔁  Rejoin (mesmo servidor)", function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
    UI.Label(Principal, "Atalho: RightShift mostra/esconde o menu (mude em CONFIG).")
end

--==================================================
-- ABA: VISUAL
--==================================================
local LightSave = {
    Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
}

do
    UI.Section(Visual, "ESP DE JOGADORES")
    UI.Toggle(Visual, "Chams (brilho atraves da parede)", false, function(on) ESP.Chams = on end, "esp_chams")
    UI.Toggle(Visual, "Caixa 2D", false, function(on) ESP.Box = on end, "esp_box")
    UI.Toggle(Visual, "Nome + distancia + item", false, function(on) ESP.Names = on end, "esp_name")
    UI.Toggle(Visual, "Barra de vida", false, function(on) ESP.Health = on end, "esp_health")
    UI.Toggle(Visual, "Tracers (linhas)", false, function(on) ESP.Tracers = on end, "esp_trace")
    UI.Cycle(Visual, "Origem do tracer", {"Baixo", "Centro", "Mouse"}, "Baixo", function(v) ESP.TracerFrom = v end)
    UI.Toggle(Visual, "Cor por time", false, function(on) ESP.TeamColor = on end, "esp_team")
    UI.Toggle(Visual, "Esconder meu time", false, function(on) ESP.TeamCheck = on end, "esp_teamcheck")
    UI.Slider(Visual, "Distancia maxima do ESP", 100, 5000, ESP.MaxDist, function(v) ESP.MaxDist = v end, "esp_dist")
    UI.Button(Visual, "✨  Ativar ESP completo", function()
        preset({esp_chams = true, esp_box = true, esp_name = true, esp_health = true, esp_trace = true})
    end)
    UI.Button(Visual, "⛔  Desligar ESP", function()
        preset({esp_chams = false, esp_box = false, esp_name = false, esp_health = false, esp_trace = false})
    end)

    UI.Section(Visual, "CAMERA")
    UI.Toggle(Visual, "Alterar FOV da camera", false, function(on)
        State.CamFov = on
        if not on then
            pcall(function() workspace.CurrentCamera.FieldOfView = 70 end)
        end
    end, "fovcam")
    UI.Slider(Visual, "FOV", 40, 120, State.CamFovVal, function(v) State.CamFovVal = v end, "fovcamv")
    UI.Toggle(Visual, "Zoom ilimitado (scroll)", false, function(on)
        pcall(function()
            LocalPlayer.CameraMaxZoomDistance = on and 5000 or 128
        end)
    end, "zoom")
    UI.Toggle(Visual, "Mira customizada", false, function(on) State.Crosshair = on end, "crosshair")
    UI.Toggle(Visual, "Zoom segurando a tecla C", false, function(on) X.zoomC = on end, "zoomc")

    UI.Section(Visual, "ILUMINACAO / MUNDO")
    UI.Toggle(Visual, "Fullbright", false, function(on)
        State.Fullbright = on
        if not on then
            for k, v in pairs(LightSave) do
                pcall(function() Lighting[k] = v end)
            end
        end
    end, "fullbright")
    UI.Toggle(Visual, "Sem neblina", false, function(on)
        State.NoFog = on
        if not on then
            pcall(function() Lighting.FogEnd = LightSave.FogEnd end)
        end
    end, "nofog")
    UI.Toggle(Visual, "X-Ray (paredes transparentes)", false, function(on)
        State.XRay = on
        setXray(on)
    end, "xray")
    UI.Slider(Visual, "Hora do dia", 0, 24, math.floor(Lighting.ClockTime), function(v)
        Lighting.ClockTime = v
        LightSave.ClockTime = v
    end)
    UI.Button(Visual, "🧹  Remover efeitos (blur/bloom/etc)", function()
        for _, d in ipairs(Lighting:GetChildren()) do
            if d:IsA("PostEffect") or d:IsA("Atmosphere") then
                pcall(function() d.Enabled = false end)
            end
        end
        notify("Visual", "Efeitos desligados.", 2, "ok")
    end)
end

--==================================================
-- ABA: COMBATE
--==================================================
do
    UI.Section(Combate, "AIMBOT")
    UI.Toggle(Combate, "Aimbot", false, function(on) Aim.On = on end, "aim")
    UI.Cycle(Combate, "Tecla de mira", {"Botao direito", "Botao esquerdo", "Shift", "Q", "E"}, Aim.Key, function(v) Aim.Key = v end)
    UI.Toggle(Combate, "Travar sem segurar tecla", false, function(on) Aim.Always = on end, "aim_always")
    UI.Toggle(Combate, "Alvo fixo (nao troca ate soltar)", true, function(on) Aim.Sticky = on end, "aim_sticky")
    UI.Cycle(Combate, "Prioridade do alvo", {"Cursor", "Distancia", "Vida"}, Aim.Mode, function(v) Aim.Mode = v end)
    UI.Cycle(Combate, "Parte do corpo", {"Head", "UpperTorso", "HumanoidRootPart", "Torso"}, Aim.Part, function(v) Aim.Part = v end)
    UI.Slider(Combate, "FOV do Aimbot", 30, 500, Aim.FOV, function(v) Aim.FOV = v end, "aim_fov")
    UI.Slider(Combate, "Suavidade (100 = instantaneo)", 1, 100, Aim.Smooth, function(v) Aim.Smooth = v end, "aim_smooth")
    UI.Slider(Combate, "Predicao de movimento", 0, 30, Aim.Predict, function(v) Aim.Predict = v end, "aim_pred")
    UI.Slider(Combate, "Distancia maxima", 50, 3000, Aim.MaxDist, function(v) Aim.MaxDist = v end, "aim_maxdist")
    UI.Toggle(Combate, "Team Check", true, function(on) Aim.TeamCheck = on end, "aim_team")
    UI.Toggle(Combate, "Wall Check", true, function(on) Aim.WallCheck = on end, "aim_wall")
    UI.Toggle(Combate, "Mostrar circulo de FOV", true, function(on) Aim.ShowFOV = on end)
    UI.Toggle(Combate, "Marcar alvo travado", true, function(on) Aim.ShowTarget = on end)

    UI.Section(Combate, "EXTRAS")
    UI.Toggle(Combate, "Triggerbot (atira ao mirar)", false, function(on) State.Trigger = on end, "trigger")
    UI.Toggle(Combate, "Hitbox Expander (depende do jogo)", false, function(on)
        State.Hitbox = on
        if not on then restoreHitbox() end
    end, "hitbox")
    UI.Slider(Combate, "Tamanho da Hitbox", 2, 30, State.HitSize, function(v) State.HitSize = v end, "hitbox_size")
    UI.Toggle(Combate, "Auto Clicker", false, function(on) State.AutoClick = on end, "autoclick")
    UI.Slider(Combate, "Cliques por segundo", 1, 40, State.CPS, function(v) State.CPS = v end)

    X.nearbyBlock(Combate)

    UI.Section(Combate, "PRESETS")
    UI.Button(Combate, "🎯  Legit (suave, FOV pequeno)", function()
        preset({aim = true, aim_always = false, aim_wall = true, aim_team = true, aim_sticky = true},
            {aim_fov = 80, aim_smooth = 12, aim_pred = 0})
        notify("Preset", "Legit aplicado.", 2, "ok")
    end)
    UI.Button(Combate, "⚖  Semi-rage (medio)", function()
        preset({aim = true, aim_always = false, aim_wall = true, aim_sticky = true},
            {aim_fov = 160, aim_smooth = 40, aim_pred = 4})
        notify("Preset", "Semi-rage aplicado.", 2, "ok")
    end)
    UI.Button(Combate, "🔥  Rage (trava forte, FOV grande)", function()
        preset({aim = true, aim_always = true, aim_wall = false, aim_sticky = true},
            {aim_fov = 300, aim_smooth = 100, aim_pred = 8})
        notify("Preset", "Rage aplicado.", 2, "ok")
    end)
    UI.Button(Combate, "⛔  Desligar tudo de combate", function()
        preset({aim = false, aim_always = false, trigger = false, hitbox = false, autoclick = false})
    end)
end

--==================================================
-- ABA: TROLL
--==================================================
do
    ------------------------------------------------------------------
    -- LOST INFOS (menu de informacoes do jogador, fechavel e arrastavel)
    ------------------------------------------------------------------
    local Panel = new("Frame", {
        Name = "LostInfos",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(310, 404),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 20,
    }, Gui)
    corner(Panel, 14)
    local PanelStroke = stroke(Panel, C.accent, 1.5, 0.2)
    onAccent(function(col) PanelStroke.Color = col end)
    local PanelScale = new("UIScale", {Scale = 1}, Panel)

    local Head = new("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
    }, Panel)
    new("TextLabel", {
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(1, -60, 1, 0),
        BackgroundTransparency = 1,
        Text = "🎃  LOST INFOS",
        TextColor3 = C.white,
        TextSize = 15,
        Font = Enum.Font.GothamBlack,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Head)
    local PClose = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = C.item,
        Text = "×",
        TextColor3 = C.text,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, Head)
    corner(PClose, 8)
    PClose.MouseEnter:Connect(function() tween(PClose, 0.15, {BackgroundColor3 = Color3.fromRGB(110, 35, 40)}) end)
    PClose.MouseLeave:Connect(function() tween(PClose, 0.15, {BackgroundColor3 = C.item}) end)
    new("Frame", {
        Position = UDim2.new(0, 14, 0, 44),
        Size = UDim2.new(1, -28, 0, 1),
        BackgroundColor3 = C.line,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
    }, Panel)

    local Avatar = new("ImageLabel", {
        Position = UDim2.new(0, 16, 0, 58),
        Size = UDim2.fromOffset(62, 62),
        BackgroundColor3 = C.off,
        BorderSizePixel = 0,
    }, Panel)
    corner(Avatar, 31)
    local AvStroke = stroke(Avatar, C.accent, 2, 0.2)
    onAccent(function(col) AvStroke.Color = col end)

    local PName = new("TextLabel", {
        Position = UDim2.new(0, 92, 0, 62),
        Size = UDim2.new(1, -106, 0, 24),
        BackgroundTransparency = 1,
        Text = "-",
        TextColor3 = C.white,
        TextSize = 16,
        Font = Enum.Font.GothamBlack,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, Panel)
    local PUser = new("TextLabel", {
        Position = UDim2.new(0, 92, 0, 88),
        Size = UDim2.new(1, -106, 0, 18),
        BackgroundTransparency = 1,
        Text = "@-",
        TextColor3 = C.sub,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, Panel)

    local rowDefs = {
        {"created", "Conta criada em"}, {"age", "Idade da conta"}, {"id", "User ID"},
        {"member", "Membership"}, {"team", "Time"}, {"hp", "Vida"},
        {"dist", "Distancia"}, {"tool", "Item na mao"}, {"verified", "Verificado"},
    }
    local rows = {}
    for i, def in ipairs(rowDefs) do
        local y = 134 + (i - 1) * 25
        new("TextLabel", {
            Position = UDim2.new(0, 16, 0, y),
            Size = UDim2.fromOffset(112, 20),
            BackgroundTransparency = 1,
            Text = def[2],
            TextColor3 = C.sub,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, Panel)
        rows[def[1]] = new("TextLabel", {
            Position = UDim2.new(0, 134, 0, y),
            Size = UDim2.new(1, -150, 0, 20),
            BackgroundTransparency = 1,
            Text = "-",
            TextColor3 = C.white,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, Panel)
    end

    local infoPlayer
    local function refreshLive()
        local pl = infoPlayer
        if not pl or pl.Parent ~= Players then
            rows.hp.Text = "saiu do servidor"
            rows.dist.Text = "-"
            return
        end
        local c = pl.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        local root = c and c:FindFirstChild("HumanoidRootPart")
        local mine = getRoot()
        rows.hp.Text = hum and (math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)) or "-"
        rows.dist.Text = (root and mine) and (math.floor((root.Position - mine.Position).Magnitude) .. " studs") or "-"
        local tool = c and c:FindFirstChildOfClass("Tool")
        rows.tool.Text = tool and tool.Name or "nenhum"
        rows.team.Text = pl.Team and pl.Team.Name or "sem time"
    end

    function X.showInfo(pl)
        if not pl or pl.Parent ~= Players then return end
        infoPlayer = pl
        PName.Text = pl.DisplayName
        PUser.Text = "@" .. pl.Name
        Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. pl.UserId .. "&w=150&h=150"
        local days = pl.AccountAge
        rows.created.Text = os.date("!%d/%m/%Y", os.time() - days * 86400)
        rows.age.Text = ("%d dias (%d anos, %d meses)"):format(days, math.floor(days / 365), math.floor((days % 365) / 30))
        rows.id.Text = tostring(pl.UserId)
        local mt = "Normal"
        pcall(function()
            local n = pl.MembershipType.Name
            if n ~= "None" then mt = n end
        end)
        rows.member.Text = mt
        local ver = false
        pcall(function() ver = pl.HasVerifiedBadge end)
        rows.verified.Text = ver and "Sim" or "Nao"
        refreshLive()
        if not Panel.Visible then
            Panel.Visible = true
            PanelScale.Scale = 0.85
            tween(PanelScale, 0.3, {Scale = 1}, Enum.EasingStyle.Back)
        end
    end

    local function closeInfo()
        tween(PanelScale, 0.15, {Scale = 0.85})
        task.delay(0.15, function() Panel.Visible = false end)
    end
    PClose.MouseButton1Click:Connect(closeInfo)

    local function panelButton(text, x, w, fn)
        local b = new("TextButton", {
            Position = UDim2.new(0, x, 1, -48),
            Size = UDim2.fromOffset(w, 34),
            BackgroundColor3 = C.item,
            Text = text,
            TextColor3 = C.text,
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            BorderSizePixel = 0,
            AutoButtonColor = false,
        }, Panel)
        corner(b, 8)
        b.MouseEnter:Connect(function() tween(b, 0.12, {BackgroundColor3 = C.hover, TextColor3 = C.white}) end)
        b.MouseLeave:Connect(function() tween(b, 0.12, {BackgroundColor3 = C.item, TextColor3 = C.text}) end)
        b.MouseButton1Click:Connect(fn)
    end
    panelButton("📋 ID", 16, 84, function()
        if infoPlayer and setclipboard then
            setclipboard(tostring(infoPlayer.UserId))
            notify("Copiado", "ID de " .. infoPlayer.Name, 2, "ok")
        end
    end)
    panelButton("📍 Ir", 108, 90, function()
        local r = infoPlayer and infoPlayer.Character and infoPlayer.Character:FindFirstChild("HumanoidRootPart")
        if r then tpTo(r.Position) end
    end)
    panelButton("👁 Observar", 206, 88, function()
        local h = infoPlayer and infoPlayer.Character and infoPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then workspace.CurrentCamera.CameraSubject = h end
    end)

    -- atualiza vida/distancia enquanto aberto
    local lastRefresh = 0
    table.insert(Ticks, function()
        if Panel.Visible and os.clock() - lastRefresh > 0.5 then
            lastRefresh = os.clock()
            refreshLive()
        end
    end)

    -- arrastar o menu pelo cabecalho
    local pDrag, pStart, pPos = false, nil, nil
    Head.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            pDrag, pStart, pPos = true, input.Position, Panel.Position
        end
    end)
    bind(UserInputService.InputChanged, function(input)
        if pDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - pStart
            Panel.Position = UDim2.new(pPos.X.Scale, pPos.X.Offset + d.X, pPos.Y.Scale, pPos.Y.Offset + d.Y)
        end
    end)
    bind(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            pDrag = false
        end
    end)

    -- clicar num jogador no mundo abre o menu
    local clickOpen = false
    bind(UserInputService.InputBegan, function(input, processed)
        if processed or not clickOpen then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local t = Mouse.Target
            local m = t and t:FindFirstAncestorOfClass("Model")
            local pl = m and Players:GetPlayerFromCharacter(m)
            if pl and pl ~= LocalPlayer then
                TS.Sel = pl
                X.showInfo(pl)
            end
        end
    end)

    UI.Section(Troll, "LOST INFOS")
    UI.Toggle(Troll, "Clicar num jogador abre o Lost Infos", false, function(on) clickOpen = on end, "clickinfo")
    UI.Button(Troll, "🪪  Abrir Lost Infos do jogador escolhido", function()
        local p = selPlayer()
        if p then X.showInfo(p) else notify("Lost Infos", "Escolha um jogador primeiro.", 3, "err") end
    end)

    UI.Section(Troll, "ALVO")
    UI.Dropdown(Troll, "Escolher jogador", playerNames, function(name)
        TS.Sel = Players:FindFirstChild(name)
        if TS.Sel then
            notify("Alvo", TS.Sel.DisplayName .. " (@" .. TS.Sel.Name .. ")", 2, "ok")
            X.showInfo(TS.Sel)
        end
    end)
    UI.Button(Troll, "ℹ  Info do jogador", function()
        local p = selPlayer()
        if not p then notify("Info", "Escolha um jogador.", 3, "err") return end
        notify(p.DisplayName, ("ID %d • conta %d dias • %s"):format(p.UserId, p.AccountAge, p.Team and p.Team.Name or "sem time"), 6)
    end)
    UI.Button(Troll, "📋  Copiar nome / ID", function()
        local p = selPlayer()
        if not p then notify("Copiar", "Escolha um jogador.", 3, "err") return end
        if setclipboard then
            setclipboard(p.Name .. " | " .. p.UserId)
            notify("Copiado", p.Name, 2, "ok")
        else
            notify(p.Name, tostring(p.UserId), 5)
        end
    end)

    UI.Section(Troll, "TELEPORTE / OBSERVAR")
    UI.Button(Troll, "📍  Teleportar ate o jogador", function()
        local r = selRoot()
        if r then
            tpTo(r.Position)
        else
            notify("Teleporte", "Escolha um jogador valido.", 3, "err")
        end
    end)
    UI.Button(Troll, "🚀  Ir ate o jogador (voo suave)", function()
        local r = selRoot()
        if r then
            smoothTeleport(r.Position)
        else
            notify("Teleporte", "Escolha um jogador valido.", 3, "err")
        end
    end)
    UI.Button(Troll, "👁  Observar jogador", function()
        local p = selPlayer()
        local h = p and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if h then
            workspace.CurrentCamera.CameraSubject = h
        else
            notify("Spectate", "Escolha um jogador valido.", 3, "err")
        end
    end)
    UI.Button(Troll, "⏹  Parar de observar", function()
        local h = getHum()
        if h then workspace.CurrentCamera.CameraSubject = h end
    end)

    UI.Section(Troll, "GRUDAR NO JOGADOR")
    UI.Toggle(Troll, "Grudar / seguir jogador", false, function(on)
        if on then
            if not selRoot() then
                notify("Grudar", "Escolha um jogador valido.", 3, "err")
                Toggles.stick.Set(false, true)
                return
            end
            local r = getRoot()
            TS.Origin = r and r.CFrame
            TS.Stick = true
        else
            TS.Stick = false
            local r = getRoot()
            if r and TS.Origin then
                r.CFrame = TS.Origin
                r.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end, "stick")
    UI.Cycle(Troll, "Modo", {"Atras", "Frente", "Em cima", "Orbitar"}, TS.Mode, function(v) TS.Mode = v end)
    UI.Slider(Troll, "Distancia", 2, 30, TS.Dist, function(v) TS.Dist = v end, "stickdist")
    UI.Slider(Troll, "Velocidade da orbita", 1, 20, TS.OrbitSpeed, function(v) TS.OrbitSpeed = v end)
    UI.Label(Troll, "Dica: 'Em cima' com distancia 3 vira headsit. Ao desligar, voce volta onde estava.", 28)

    UI.Section(Troll, "FLING")
    UI.Button(Troll, "💥  Fling no jogador escolhido", function()
        local p = selPlayer()
        if not p then notify("Fling", "Escolha um jogador.", 3, "err") return end
        flingPlayer(p)
    end)
    UI.Button(Troll, "🌪  Fling em todos (um por vez)", function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and alive then
                flingPlayer(p)
                task.wait(0.4)
            end
        end
    end)
    UI.Label(Troll, "O fling usa a fisica do seu personagem; funciona melhor com Noclip desligado e depende do jogo.", 28)

    UI.Section(Troll, "EU (VISUAL / BRINCADEIRAS)")
    UI.Toggle(Troll, "Girar (spin)", false, function(on) State.Spin = on end, "spin")
    UI.Slider(Troll, "Velocidade do giro", 1, 80, State.SpinSpeed, function(v) State.SpinSpeed = v end)
    UI.Toggle(Troll, "Corpo neon arco-iris (so voce ve)", false, function(on)
        State.Neon = on
        if not on then restoreNeon() end
    end, "neon")
    UI.Button(Troll, "🪑  Sentar", function()
        local hum = getHum()
        if hum then hum.Sit = true end
    end)

    UI.Section(Troll, "CHAT")
    UI.TextInput(Troll, "Mensagem do chat...", State.ChatMsg, function(txt) State.ChatMsg = txt end)
    UI.Button(Troll, "💬  Enviar mensagem agora", function()
        sendChat(State.ChatMsg)
    end)
    UI.Slider(Troll, "Intervalo do spam (seg, min 3)", 3, 30, State.ChatDelay, function(v) State.ChatDelay = v end)
    UI.Toggle(Troll, "Spam de chat", false, function(on) State.ChatSpam = on end, "chatspam")
end

--==================================================
-- ABA: MUNDO
--==================================================
local OrigGravity = workspace.Gravity
do
    UI.Section(Mundo, "TELEPORTE POR COORDENADAS")
    local cx, cy, cz = 0, 0, 0
    UI.Input(Mundo, "X", 0, function(v) cx = v end)
    UI.Input(Mundo, "Y", 0, function(v) cy = v end)
    UI.Input(Mundo, "Z", 0, function(v) cz = v end)
    UI.Button(Mundo, "📍  Teleportar para X, Y, Z", function()
        smoothTeleport(Vector3.new(cx, cy, cz))
    end)
    local tpName = ""
    UI.TextInput(Mundo, "Nome do jogador (ou parte do nome)...", "", function(txt) tpName = txt end)
    UI.Button(Mundo, "👤  Teleportar para o jogador digitado", function()
        local q = tpName:lower()
        if #q == 0 then notify("Teleporte", "Digite um nome primeiro.", 3, "err") return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and (p.Name:lower():find(q, 1, true) or p.DisplayName:lower():find(q, 1, true)) then
                local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                if r then
                    tpTo(r.Position)
                    notify("Teleporte", "Voce foi ate " .. p.DisplayName .. ".", 3, "ok")
                    return
                end
            end
        end
        notify("Teleporte", "Jogador nao encontrado.", 3, "err")
    end)
    UI.Button(Mundo, "📋  Copiar minha posicao", function()
        local r = getRoot()
        if not r then return end
        local p = r.Position
        local s = ("Vector3.new(%d, %d, %d)"):format(math.floor(p.X), math.floor(p.Y), math.floor(p.Z))
        if setclipboard then
            setclipboard(s)
            notify("Copiado", s, 3, "ok")
        else
            notify("Posicao", s, 6)
        end
    end)

    UI.Section(Mundo, "AMBIENTE")
    UI.Slider(Mundo, "Gravidade", 10, 400, math.floor(workspace.Gravity), function(v)
        workspace.Gravity = v
    end, "gravity")
    UI.Button(Mundo, "Restaurar gravidade", function()
        workspace.Gravity = OrigGravity
        if Sliders.gravity then Sliders.gravity.Set(OrigGravity, true) end
    end)
    UI.Button(Mundo, "🚀  FPS Boost (reduz graficos)", fpsBoost)
    UI.Slider(Mundo, "Limite de FPS (0 = livre)", 0, 240, 0, function(v)
        if setfpscap then
            pcall(setfpscap, v)
        else
            notify("Aviso", "Seu executor nao suporta setfpscap.", 3, "err")
        end
    end)

    UI.Section(Mundo, "AUTOMACAO")
    UI.Toggle(Mundo, "Instant Prompt (E sem segurar)", false, function(on) State.InstaPrompt = on end, "instaprompt")
    UI.Toggle(Mundo, "Auto Prompt (interage ao chegar perto)", false, function(on)
        State.AutoPrompt = on
        if on and not fireproximityprompt then
            notify("Aviso", "Seu executor nao suporta fireproximityprompt.", 4, "err")
        end
    end, "autoprompt")

    UI.Section(Mundo, "SCANNER DE OBJETOS")
    UI.Label(Mundo, "Digite palavras separadas por virgula (ex: coin, chest, fruit). Procura no mapa pelo nome.", 30)
    UI.TextInput(Mundo, "Palavras-chave...", "", function(txt)
        local list = {}
        for w in string.gmatch(txt, "[^,]+") do
            table.insert(list, w)
        end
        setKeywords(list)
        notify("Scanner", #Obj.Keywords .. " palavra(s) definida(s).", 2)
    end)
    UI.Toggle(Mundo, "ESP de objetos (25 mais proximos)", false, function(on) Obj.On = on end, "obj_esp")
    UI.Toggle(Mundo, "Auto Coletar (firetouchinterest)", false, function(on)
        State.AutoCollect = on
        if on and not firetouchinterest then
            notify("Aviso", "Seu executor nao suporta firetouchinterest.", 4, "err")
        end
    end, "autocollect")
    UI.Slider(Mundo, "Alcance da coleta", 10, 300, State.CollectRange, function(v) State.CollectRange = v end)
    UI.Button(Mundo, "📍  Ir ate o objeto mais proximo do scanner", function()
        local kws = Obj.Keywords
        if #kws == 0 then notify("Scanner", "Defina palavras-chave primeiro.", 3, "err") return end
        local p = nearestObj(function(d) return nameHas(d, kws) end)
        if p then tpTo(p.Position) else notify("Scanner", "Nada encontrado.", 3, "err") end
    end)

    UI.Section(Mundo, "SERVIDOR")
    UI.Button(Mundo, "🔄  Rejoin Server", function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
    UI.Button(Mundo, "🌐  Server Hop (menos jogadores)", serverHop)
    UI.Toggle(Mundo, "Server Hop automatico", false, function(on) State.AutoHop = on end, "autohop")
    UI.Slider(Mundo, "Intervalo do hop (minutos)", 3, 60, State.HopMin, function(v) State.HopMin = v end)
    UI.Button(Mundo, "📋  Copiar PlaceId", function()
        if setclipboard then
            setclipboard(tostring(game.PlaceId))
            notify("Copiado", "PlaceId: " .. game.PlaceId, 3, "ok")
        else
            notify("PlaceId", tostring(game.PlaceId), 5)
        end
    end)
    UI.Button(Mundo, "📋  Copiar JobId", function()
        if setclipboard then
            setclipboard(game.JobId)
            notify("Copiado", "JobId copiado.", 3, "ok")
        else
            notify("JobId", game.JobId, 5)
        end
    end)
end

--==================================================
-- ABA: OTIMIZAÇÃO (mais FPS)
--==================================================
X.Opt = {On = {}, Saved = {}, G = {}, FogV = 600, count = 0}

local function optChunked(list, fn)
    local n = 0
    for _, d in ipairs(list) do
        pcall(fn, d)
        n = n + 1
        if n % 600 == 0 then task.wait() end
    end
end

local function isOtherPlayerPart(d)
    local m = d:FindFirstAncestorOfClass("Model")
    return m ~= nil and m ~= LocalPlayer.Character and Players:GetPlayerFromCharacter(m) ~= nil
end

local OPT_TERRAIN = workspace.Terrain

-- recursos aplicados em cada objeto do mapa (guardam o valor original para restaurar)
X.OptFeat = {
    textures = {
        match = function(d) return d:IsA("Decal") or d:IsA("Texture") or d:IsA("MeshPart") end,
        props = function(d)
            if d:IsA("MeshPart") then return {TextureID = ""} end
            return {Transparency = 1}
        end,
    },
    meshes = {
        match = function(d) return d:IsA("MeshPart") end,
        props = function() return {RenderFidelity = Enum.RenderFidelity.Performance} end,
    },
    materials = {
        match = function(d) return d:IsA("BasePart") and d ~= OPT_TERRAIN end,
        props = function() return {Material = Enum.Material.SmoothPlastic, Reflectance = 0} end,
    },
    shadows = {
        match = function(d) return d:IsA("BasePart") and d ~= OPT_TERRAIN end,
        props = function() return {CastShadow = false} end,
    },
    effects = {
        match = function(d)
            return d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Smoke")
                or d:IsA("Fire") or d:IsA("Sparkles")
        end,
        props = function() return {Enabled = false} end,
    },
    lights = {
        match = function(d) return d:IsA("Light") end,
        props = function() return {Enabled = false} end,
    },
    mute = {
        match = function(d) return d:IsA("Sound") and d.Name ~= "LostHubMusic" end,
        props = function() return {Volume = 0} end,
    },
    hide = {
        match = function(d) return (d:IsA("BasePart") or d:IsA("Decal")) and isOtherPlayerPart(d) end,
        props = function(d)
            if d:IsA("Decal") then return {Transparency = 1} end
            return {LocalTransparencyModifier = 1}
        end,
    },
}

local function optApply(key, inst, props)
    if not props then return end
    local sv = X.Opt.Saved[key]
    if not sv then
        sv = setmetatable({}, {__mode = "k"})
        X.Opt.Saved[key] = sv
    end
    local rec = sv[inst]
    if not rec then
        rec = {}
        sv[inst] = rec
    end
    for p, v in pairs(props) do
        if rec[p] == nil then
            local ok, old = pcall(function() return inst[p] end)
            if ok then rec[p] = old end
        end
        pcall(function() inst[p] = v end)
    end
end

local function optRestore(key)
    local sv = X.Opt.Saved[key]
    if sv then
        for inst, rec in pairs(sv) do
            for p, v in pairs(rec) do
                pcall(function() inst[p] = v end)
            end
        end
        X.Opt.Saved[key] = nil
    end
end

function X.optSet(key, on)
    local f = X.OptFeat[key]
    if not f then return end
    if (X.Opt.On[key] or false) ~= on then
        X.Opt.count = X.Opt.count + (on and 1 or -1)
    end
    X.Opt.On[key] = on
    if on then
        task.spawn(function()
            optChunked(workspace:GetDescendants(), function(d)
                if X.Opt.On[key] and f.match(d) then
                    optApply(key, d, f.props(d))
                end
            end)
        end)
    else
        optRestore(key)
    end
end

-- objetos que aparecem depois de ligar
bind(workspace.DescendantAdded, function(d)
    if X.Opt.count <= 0 then return end
    for key, f in pairs(X.OptFeat) do
        if X.Opt.On[key] then
            local ok, m = pcall(f.match, d)
            if ok and m then
                optApply(key, d, f.props(d))
            end
        end
    end
end)

-- manter outros jogadores escondidos (personagens novos / respawn)
task.spawn(function()
    while alive do
        if X.Opt.On.hide then
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= LocalPlayer and pl.Character then
                    for _, d in ipairs(pl.Character:GetDescendants()) do
                        if d:IsA("BasePart") or d:IsA("Decal") then
                            optApply("hide", d, X.OptFeat.hide.props(d))
                        end
                    end
                end
            end
        end
        task.wait(2)
    end
end)

-- recursos globais (iluminacao, terreno, qualidade...)
local function gsave(name, inst, prop, value)
    local l = X.Opt.G[name]
    if not l then
        l = {}
        X.Opt.G[name] = l
    end
    local ok, old = pcall(function() return inst[prop] end)
    if ok then
        table.insert(l, {inst, prop, old})
        pcall(function() inst[prop] = value end)
    end
end
local function grestore(name)
    local l = X.Opt.G[name]
    if not l then return end
    for i = #l, 1, -1 do
        local e = l[i]
        pcall(function() e[1][e[2]] = e[3] end)
    end
    X.Opt.G[name] = nil
end

X.OptGlobal = {
    lighting = function(on)
        if on then
            gsave("lighting", Lighting, "GlobalShadows", false)
            gsave("lighting", Lighting, "ShadowSoftness", 0)
            gsave("lighting", Lighting, "EnvironmentDiffuseScale", 0)
            gsave("lighting", Lighting, "EnvironmentSpecularScale", 0)
        else
            grestore("lighting")
        end
    end,
    post = function(on)
        if on then
            for _, d in ipairs(Lighting:GetChildren()) do
                if d:IsA("PostEffect") then
                    gsave("post", d, "Enabled", false)
                elseif d:IsA("Atmosphere") then
                    gsave("post", d, "Density", 0)
                    gsave("post", d, "Haze", 0)
                    gsave("post", d, "Glare", 0)
                end
            end
            for _, d in ipairs(OPT_TERRAIN:GetChildren()) do
                if d:IsA("Clouds") then gsave("post", d, "Enabled", false) end
            end
        else
            grestore("post")
        end
    end,
    terrain = function(on)
        if on then
            gsave("terrain", OPT_TERRAIN, "WaterWaveSize", 0)
            gsave("terrain", OPT_TERRAIN, "WaterWaveSpeed", 0)
            gsave("terrain", OPT_TERRAIN, "WaterReflectance", 0)
            gsave("terrain", OPT_TERRAIN, "Decoration", false)
        else
            grestore("terrain")
        end
    end,
    quality = function(on)
        if on then
            pcall(function() gsave("quality", settings().Rendering, "QualityLevel", Enum.QualityLevel.Level01) end)
        else
            grestore("quality")
        end
    end,
    fog = function(on)
        if on then
            gsave("fog", Lighting, "FogEnd", X.Opt.FogV)
            gsave("fog", Lighting, "FogStart", X.Opt.FogV * 0.4)
        else
            grestore("fog")
        end
    end,
}

function X.optToggle(key, on)
    if X.OptFeat[key] then
        X.optSet(key, on)
    elseif X.OptGlobal[key] then
        X.OptGlobal[key](on)
    end
end

function X.optRestoreAll()
    for k in pairs(X.OptFeat) do X.optSet(k, false) end
    for k, fn in pairs(X.OptGlobal) do fn(false) end
end

do
    local P = Otimizacao
    local keys = {"shadows", "effects", "post", "lighting", "lights", "materials", "terrain", "quality", "textures", "meshes", "fog", "hide", "mute"}
    local function allOff()
        local t = {}
        for _, k in ipairs(keys) do t["opt_" .. k] = false end
        return t
    end
    local function on(list)
        local t = {}
        for _, k in ipairs(list) do t["opt_" .. k] = true end
        return t
    end

    UI.Label(P, "Cada opcao guarda o valor original e volta ao normal quando desligada. Se algo ficar estranho, use 'Restaurar tudo'.", 40)

    UI.Section(P, "PRESETS")
    UI.Button(P, "🍃  Boost leve (sombras, efeitos, pos-processamento)", function()
        preset(on({"shadows", "effects", "post", "lighting"}))
        notify("Otimização", "Boost leve ligado.", 3, "ok")
    end)
    UI.Button(P, "⚡  Boost medio (+ luzes, materiais, terreno, qualidade)", function()
        preset(on({"shadows", "effects", "post", "lighting", "lights", "materials", "terrain", "quality"}))
        notify("Otimização", "Boost medio ligado.", 3, "ok")
    end)
    UI.Button(P, "💀  Boost extremo (+ texturas e malhas simples)", function()
        preset(on({"shadows", "effects", "post", "lighting", "lights", "materials", "terrain", "quality", "textures", "meshes"}))
        notify("Otimização", "Boost extremo ligado. O visual fica bem simples.", 4, "ok")
    end)
    UI.Button(P, "↩  Restaurar tudo", function()
        preset(allOff())
        X.optRestoreAll()
        notify("Otimização", "Tudo restaurado.", 3, "ok")
    end)

    UI.Section(P, "GRAFICOS")
    UI.Toggle(P, "Remover texturas e decals", false, function(v) X.optToggle("textures", v) end, "opt_textures")
    UI.Toggle(P, "Malhas simples (menos detalhe)", false, function(v) X.optToggle("meshes", v) end, "opt_meshes")
    UI.Toggle(P, "Materiais lisos (SmoothPlastic, sem reflexo)", false, function(v) X.optToggle("materials", v) end, "opt_materials")
    UI.Toggle(P, "Remover sombras das pecas", false, function(v) X.optToggle("shadows", v) end, "opt_shadows")
    UI.Toggle(P, "Iluminacao simples (sem sombras globais)", false, function(v) X.optToggle("lighting", v) end, "opt_lighting")
    UI.Toggle(P, "Desligar luzes (Point / Spot / Surface)", false, function(v) X.optToggle("lights", v) end, "opt_lights")
    UI.Toggle(P, "Desligar efeitos (particulas, rastros, fogo)", false, function(v) X.optToggle("effects", v) end, "opt_effects")
    UI.Toggle(P, "Desligar pos-processamento e atmosfera", false, function(v) X.optToggle("post", v) end, "opt_post")
    UI.Toggle(P, "Agua e terreno simples (sem ondas e grama)", false, function(v) X.optToggle("terrain", v) end, "opt_terrain")
    UI.Toggle(P, "Qualidade grafica minima", false, function(v) X.optToggle("quality", v) end, "opt_quality")

    UI.Section(P, "DISTANCIA DE VISAO")
    UI.Toggle(P, "Cortar distancia com neblina", false, function(v) X.optToggle("fog", v) end, "opt_fog")
    UI.Slider(P, "Distancia de visao (studs)", 100, 3000, X.Opt.FogV, function(v)
        X.Opt.FogV = v
        if X.Opt.G.fog then
            pcall(function()
                Lighting.FogEnd = v
                Lighting.FogStart = v * 0.4
            end)
        end
    end, "opt_fogv")

    UI.Section(P, "OUTROS JOGADORES E SOM")
    UI.Toggle(P, "Esconder outros jogadores (so no seu cliente)", false, function(v) X.optToggle("hide", v) end, "opt_hide")
    UI.Button(P, "👕  Remover roupas e acessorios dos outros (ate rejoin)", function()
        local n = 0
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer and pl.Character then
                for _, d in ipairs(pl.Character:GetDescendants()) do
                    if d:IsA("Accessory") or d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") or d:IsA("CharacterMesh") then
                        pcall(function() d:Destroy() end)
                        n = n + 1
                    end
                end
            end
        end
        notify("Otimização", n .. " itens removidos.", 3, "ok")
    end)
    UI.Toggle(P, "Mutar sons do mapa", false, function(v) X.optToggle("mute", v) end, "opt_mute")

    UI.Section(P, "FPS")
    UI.Button(P, "🔓  Desbloquear limite de FPS (999)", function()
        if setfpscap then
            pcall(setfpscap, 999)
            notify("FPS", "Limite removido.", 2, "ok")
        else
            notify("FPS", "Seu executor nao suporta setfpscap.", 3, "err")
        end
    end)
    UI.Slider(P, "Limite de FPS (0 = livre)", 0, 240, 0, function(v)
        if setfpscap then pcall(setfpscap, v) else notify("FPS", "Seu executor nao suporta setfpscap.", 3, "err") end
    end)

    UI.Section(P, "MENU DO HUB")
    UI.Toggle(P, "Desligar particulas e glitch do menu", false, function(v)
        State.Particles = not v
        ParticleLayer.Visible = not v
        State.TitleGlitch = not v
    end, "opt_menu")
end

--==================================================
-- ABA: HALLOWEEN
--==================================================
X.HW = {atmos = false, rain = false, lightning = false, body = false, ghost = false,
    saved = nil, bodySaved = {}, nextFlash = 0, ghostApplied = false}

X.HWGui = new("ScreenGui", {
    Name = "LostHubFX",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 5,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, guiParent)

X.HWFlash = new("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 50,
}, X.HWGui)

-- chuva de emojis
X.HWRain = {}
do
    local list = {"🎃", "🦇", "👻", "🍬", "🕷", "🕸", "💀"}
    for i = 1, 26 do
        local l = new("TextLabel", {
            Size = UDim2.fromOffset(30, 30),
            BackgroundTransparency = 1,
            Text = list[math.random(1, #list)],
            TextSize = math.random(16, 28),
            TextTransparency = 0.1,
            Visible = false,
            ZIndex = 10,
        }, X.HWGui)
        X.HWRain[i] = {l = l, x = math.random(), y = math.random(), v = 0.08 + math.random() * 0.12, ph = math.random() * 6}
    end
end

function X.hwAtmos(on)
    local hw = X.HW
    if on == hw.atmos then return end
    hw.atmos = on
    if on then
        hw.saved = {
            Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, ClockTime = Lighting.ClockTime,
            FogColor = Lighting.FogColor, FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart,
            Brightness = Lighting.Brightness,
        }
        hw.cc = new("ColorCorrectionEffect", {Name = "LostHubHW", TintColor = Color3.fromRGB(255, 190, 150), Saturation = 0.15, Contrast = 0.08}, Lighting)
        hw.bloom = new("BloomEffect", {Name = "LostHubHWBloom", Intensity = 0.4, Size = 24, Threshold = 0.9}, Lighting)
    else
        if hw.saved then
            for k, v in pairs(hw.saved) do
                pcall(function() Lighting[k] = v end)
            end
        end
        pcall(function() hw.cc:Destroy() end)
        pcall(function() hw.bloom:Destroy() end)
    end
end

X.HWAuras = {
    bats = {emoji = "🦇", n = 5, speed = 2.2, items = {}, on = false},
    ghosts = {emoji = "👻", n = 4, speed = 1.4, items = {}, on = false},
    pumpkins = {emoji = "🎃", n = 4, speed = 1.8, items = {}, on = false},
}
function X.hwAura(kind, on)
    local a = X.HWAuras[kind]
    a.on = on
    if not on then
        for _, b in ipairs(a.items) do pcall(function() b:Destroy() end) end
        a.items = {}
    end
end

function X.hwBodyRestore()
    for p, d in pairs(X.HW.bodySaved) do
        pcall(function()
            p.Color, p.Material = d[1], d[2]
        end)
        X.HW.bodySaved[p] = nil
    end
end

function X.hwOff()
    local hw = X.HW
    hw.rain, hw.lightning, hw.body, hw.ghost = false, false, false, false
    X.hwAtmos(false)
    X.hwBodyRestore()
    for kind in pairs(X.HWAuras) do X.hwAura(kind, false) end
    local c = getChar()
    if c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.LocalTransparencyModifier = 0 end) end
        end
    end
end

table.insert(Ticks, function(dt, t)
    local hw = X.HW

    for _, it in ipairs(X.HWRain) do
        if hw.rain then
            it.l.Visible = true
            it.y = it.y + it.v * dt
            if it.y > 1.05 then
                it.y = -0.05
                it.x = math.random()
            end
            it.l.Position = UDim2.fromScale(it.x + math.sin(t * 1.5 + it.ph) * 0.01, it.y)
            it.l.Rotation = math.sin(t * 2 + it.ph) * 20
        elseif it.l.Visible then
            it.l.Visible = false
        end
    end

    if hw.lightning and t > hw.nextFlash then
        hw.nextFlash = t + 6 + math.random() * 9
        task.spawn(function()
            for _ = 1, math.random(1, 3) do
                X.HWFlash.BackgroundTransparency = 0.55
                tween(X.HWFlash, 0.3, {BackgroundTransparency = 1})
                task.wait(0.18 + math.random() * 0.15)
            end
        end)
    end

    if hw.atmos then
        Lighting.ClockTime = 0
        Lighting.Ambient = Color3.fromRGB(86, 40, 104)
        Lighting.OutdoorAmbient = Color3.fromRGB(64, 28, 84)
        Lighting.FogColor = Color3.fromRGB(58, 22, 8)
        Lighting.FogStart = 30
        Lighting.FogEnd = 450
        Lighting.Brightness = 1.3
    end

    for _, a in pairs(X.HWAuras) do
        if a.on then
            local root = getRoot()
            if root then
                local stale = #a.items ~= a.n
                for _, b in ipairs(a.items) do
                    if b.Parent ~= root then stale = true end
                end
                if stale then
                    for _, b in ipairs(a.items) do pcall(function() b:Destroy() end) end
                    a.items = {}
                    for i = 1, a.n do
                        local bb = new("BillboardGui", {
                            Name = "LostHubAura",
                            Size = UDim2.fromOffset(30, 30),
                            AlwaysOnTop = true,
                            Adornee = root,
                        }, root)
                        new("TextLabel", {
                            Size = UDim2.new(1, 0, 1, 0),
                            BackgroundTransparency = 1,
                            Text = a.emoji,
                            TextSize = 22,
                        }, bb)
                        a.items[i] = bb
                    end
                end
                for i, b in ipairs(a.items) do
                    local ang = t * a.speed + i * math.pi * 2 / a.n
                    b.StudsOffset = Vector3.new(math.cos(ang) * 3.2, 2.2 + math.sin(t * 3 + i) * 0.7, math.sin(ang) * 3.2)
                end
            end
        end
    end

    local char = getChar()
    if char then
        if hw.body then
            local col = Color3.fromRGB(255, 110 + math.floor(math.sin(t * 3) * 30), 10)
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                    if not hw.bodySaved[p] then hw.bodySaved[p] = {p.Color, p.Material} end
                    p.Material = Enum.Material.Neon
                    p.Color = col
                end
            end
        end
        if hw.ghost then
            hw.ghostApplied = true
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.LocalTransparencyModifier = 0.6 end
            end
        elseif hw.ghostApplied then
            hw.ghostApplied = false
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.LocalTransparencyModifier = 0 end
            end
        end
    end
end)

-- blocos de ESP/atalhos de evento (usado na aba Halloween e no modulo Universal)
function X.hwEventBlock(page)
    UI.Section(page, "EVENTO DE HALLOWEEN")
    local groups = {
        {"🎃 Aboboras", {"pumpkin", "abobora", "jack", "gourd"}},
        {"🍬 Doces / Trick or Treat", {"candy", "sweet", "treat", "doce", "lollipop", "bag", "sack"}},
        {"👻 Fantasmas / Monstros", {"ghost", "zombie", "skeleton", "vampire", "witch", "monster", "bat", "spider"}},
        {"🎁 Baus / Presentes de evento", {"chest", "crate", "loot", "gift", "present"}},
    }
    local all = {}
    for _, g in ipairs(groups) do
        for _, k in ipairs(g[2]) do table.insert(all, k) end
        UI.Button(page, "👁  ESP: " .. g[1], function()
            setKeywords(g[2])
            preset({obj_esp = true})
            notify("ESP", g[1] .. " ligado.", 2, "ok")
        end)
        UI.Button(page, "📍  Ir ate: " .. g[1], function()
            local p = nearestObj(function(d) return nameHas(d, g[2]) end)
            if p then tpTo(p.Position) else notify(g[1], "Nada encontrado.", 3, "err") end
        end)
    end
    UI.Button(page, "🧲  ESP + auto coletar tudo (aboboras, doces, baus)", function()
        setKeywords(all)
        preset({obj_esp = true, autocollect = true, antiafk = true})
        notify("Evento", "ESP e auto coleta ligados.", 3, "ok")
    end)
    UI.Button(page, "🤏  Prompts instantaneos + automaticos", function()
        preset({instaprompt = true, autoprompt = true})
    end)
    UI.Button(page, "⛔  Desligar ESP / coleta", function()
        preset({obj_esp = false, autocollect = false, instaprompt = false, autoprompt = false})
    end)
    UI.Label(page, "Nomes de objetos mudam de jogo para jogo. Se algo nao aparecer, use o SCANNER na aba MUNDO.", 28)
end

do
    local P = Halloween

    local function countdownText()
        local d = os.date("!*t")
        if d.month == 10 and d.day == 31 then
            return "🎃 HOJE E HALLOWEEN! Feliz Halloween!"
        end
        local y = d.year
        local today = os.time({year = d.year, month = d.month, day = d.day, hour = 12})
        local target = os.time({year = y, month = 10, day = 31, hour = 12})
        if target < today then
            target = os.time({year = y + 1, month = 10, day = 31, hour = 12})
        end
        local days = math.floor((target - today) / 86400 + 0.5)
        return "🎃 Faltam " .. days .. (days == 1 and " dia" or " dias") .. " para o Halloween (31/10)!"
    end
    local cd = UI.Label(P, countdownText(), 18)
    cd.TextColor3 = C.accent
    cd.TextSize = 12
    cd.Font = Enum.Font.GothamBold
    onAccent(function(col) cd.TextColor3 = col end)

    UI.Section(P, "ATMOSFERA ASSOMBRADA (so no seu cliente)")
    UI.Toggle(P, "🌙 Noite assombrada (ceu escuro, nevoa laranja)", false, function(on) X.hwAtmos(on) end, "hw_atmos")
    UI.Toggle(P, "🎃 Chuva de Halloween (emojis caindo na tela)", false, function(on) X.HW.rain = on end, "hw_rain")
    UI.Toggle(P, "⚡ Relampagos (flashes na tela)", false, function(on) X.HW.lightning = on end, "hw_light")
    UI.Button(P, "🕯  Clima completo (noite + chuva + relampagos)", function()
        preset({hw_atmos = true, hw_rain = true, hw_light = true})
        notify("Halloween", "Clima assombrado ligado!", 3, "ok")
    end)
    UI.Button(P, "☀  Desligar clima", function()
        preset({hw_atmos = false, hw_rain = false, hw_light = false})
    end)

    UI.Section(P, "MEU PERSONAGEM")
    UI.Toggle(P, "🎃 Corpo abobora (neon laranja pulsando)", false, function(on)
        X.HW.body = on
        if not on then X.hwBodyRestore() end
    end, "hw_body")
    UI.Toggle(P, "👻 Fantasma (meio transparente, so voce ve)", false, function(on) X.HW.ghost = on end, "hw_ghost")
    UI.Toggle(P, "🦇 Aura de morcegos (orbitam voce)", false, function(on) X.hwAura("bats", on) end, "hw_bats")
    UI.Toggle(P, "👻 Aura de fantasmas", false, function(on) X.hwAura("ghosts", on) end, "hw_ghosts")
    UI.Toggle(P, "🎃 Aura de aboboras", false, function(on) X.hwAura("pumpkins", on) end, "hw_pumpkins")
    UI.Button(P, "👻  Modo Fantasma (fly + noclip + transparente)", function()
        preset({hw_ghost = true, fly = true, noclip = true}, {flyv = 40})
    end)
    UI.Button(P, "🧹  Modo Vassoura (fly + speed)", function()
        preset({fly = true, speed = true}, {flyv = 70, speedv = 40})
        notify("Vassoura", "Voe com WASD, Espaco e Shift.", 3, "ok")
    end)
    UI.Button(P, "🧟  Modo Zumbi (speed baixo + pulo baixo)", function()
        preset({speed = true, jump = true}, {speedv = 12, jumpv = 35})
    end)
    UI.Button(P, "⛔  Desligar modos", function()
        preset({hw_ghost = false, hw_body = false, hw_bats = false, hw_ghosts = false, hw_pumpkins = false, fly = false, noclip = false, speed = false, jump = false})
    end)

    UI.Section(P, "VISUAL")
    UI.Button(P, "👁  ESP completo laranja (jogadores)", function()
        preset({esp_chams = true, esp_box = true, esp_name = true, esp_health = true, esp_trace = true})
    end)
    for _, th in ipairs({
        {"🎃 Tema Abobora", Color3.fromRGB(255, 122, 24)},
        {"🔮 Tema Roxo bruxa", Color3.fromRGB(170, 96, 255)},
        {"🧪 Tema Verde slime", Color3.fromRGB(110, 235, 70)},
        {"🩸 Tema Sangue", Color3.fromRGB(226, 50, 56)},
        {"👻 Tema Fantasma", Color3.fromRGB(235, 235, 245)},
    }) do
        UI.Button(P, th[1], function()
            State.Rainbow = false
            if Toggles.rainbow then Toggles.rainbow.Set(false, true) end
            setAccent(th[2])
        end)
    end

    X.hwEventBlock(P)
    X.musicBlock(P)
end

--==================================================
-- JOGOS: BUILDERS + REGISTRO
--==================================================
local Games = {}
local detected

do
    local PrisonSpots = {
        {"Celas",               Vector3.new(917, 100, 2448)},
        {"Patio",               Vector3.new(791, 98, 2498)},
        {"Refeitorio",          Vector3.new(930, 99, 2289)},
        {"Sala dos Guardas",    Vector3.new(836, 99, 2310)},
        {"Base dos Criminosos", Vector3.new(-943, 94, 2055)},
    }

    local function giveItem(name)
        local ok = pcall(function()
            local items = workspace:FindFirstChild("Prison_ITEMS")
            local pickup
            for _, folder in ipairs({items.giver, items.single}) do
                local item = folder:FindFirstChild(name)
                if item and item:FindFirstChild("ITEMPICKUP") then
                    pickup = item.ITEMPICKUP
                    break
                end
            end
            workspace.Remote.ItemHandler:InvokeServer(pickup)
        end)
        if ok then
            notify("Armas", name .. " solicitada.", 2, "ok")
        else
            notify("Armas", "Nao foi possivel pegar " .. name .. ".", 3, "err")
        end
    end

    local function moveModeButtons(page)
        UI.Section(page, "MODOS RAPIDOS")
        UI.Button(page, "🧭  Modo Explorar (fly + speed + noclip)", function()
            preset({fly = true, speed = true, noclip = true}, {speedv = 60, flyv = 80})
            notify("Modo Explorar", "Fly, Speed e Noclip ligados.", 3, "ok")
        end)
        UI.Button(page, "🏃  Speed seguro (28) + pulo alto", function()
            preset({speed = true, jump = true}, {speedv = 28, jumpv = 80})
        end)
        UI.Button(page, "👻  Modo Fantasma (noclip + fly lento)", function()
            preset({fly = true, noclip = true}, {flyv = 30})
        end)
        UI.Button(page, "⛔  Desligar movimento", function()
            preset({fly = false, speed = false, noclip = false, jump = false, infjump = false, bhop = false})
        end)
    end

    -- utilidades que TODO jogo ganha
    local function utilBlock(page)
        UI.Section(page, "UTILIDADES")
        UI.Button(page, "💡  Fullbright + sem neblina", function()
            preset({fullbright = true, nofog = true})
        end)
        UI.Button(page, "🛡  Modo seguro (anti AFK + anti void + auto rejoin)", function()
            preset({antiafk = true, antivoid = true, autorejoin = true})
            notify("Modo seguro", "Protecoes ligadas.", 3, "ok")
        end)
        UI.Button(page, "🧱  X-Ray ligado / desligado", function()
            if Toggles.xray then Toggles.xray.Set(not Toggles.xray.Get()) end
        end)
        UI.Button(page, "🌐  Server Hop", serverHop)
        UI.Button(page, "🔁  Rejoin", function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
        X.slotButtons(page)
    end

    local function shooterBlock(page)
        UI.Section(page, "PRESETS DE COMBATE")
        UI.Button(page, "🎯  Legit (aimbot suave + ESP)", function()
            preset({aim = true, aim_always = false, aim_wall = true, aim_team = true, esp_box = true, esp_name = true, esp_health = true},
                {aim_fov = 80, aim_smooth = 12, aim_pred = 0})
            notify("Preset", "Legit aplicado.", 2, "ok")
        end)
        UI.Button(page, "🕶  Streamer-safe (FOV 60, bem suave)", function()
            preset({aim = true, aim_always = false, aim_wall = true, aim_team = true, esp_name = true},
                {aim_fov = 60, aim_smooth = 6, aim_pred = 0})
            notify("Preset", "Streamer-safe aplicado.", 2, "ok")
        end)
        UI.Button(page, "🔥  Rage (trava forte + ESP + trigger)", function()
            preset({aim = true, aim_always = true, aim_wall = false, esp_box = true, esp_name = true,
                esp_health = true, esp_trace = true, trigger = true}, {aim_fov = 300, aim_smooth = 100, aim_pred = 8})
            notify("Preset", "Rage aplicado.", 2, "ok")
        end)
        UI.Button(page, "👁  So ESP completo", function()
            preset({esp_chams = true, esp_box = true, esp_name = true, esp_health = true, esp_trace = true})
        end)
        UI.Button(page, "💡  Fullbright + FOV 100", function()
            preset({fullbright = true, fovcam = true}, {fovcamv = 100})
        end)
        UI.Button(page, "🎯  Hitbox grande (12) + Trigger", function()
            preset({hitbox = true, trigger = true}, {hitbox_size = 12})
        end)
        UI.Button(page, "🧠  Mirar na cabeca", function()
            Aim.Part = "Head"
            notify("Aimbot", "Parte: cabeca.", 2, "ok")
        end)
        UI.Button(page, "🫀  Mirar no tronco (mais estavel)", function()
            Aim.Part = "UpperTorso"
            notify("Aimbot", "Parte: tronco.", 2, "ok")
        end)
        UI.Button(page, "⛔  Desligar tudo", function()
            preset({aim = false, aim_always = false, trigger = false, hitbox = false,
                esp_chams = false, esp_box = false, esp_name = false, esp_health = false, esp_trace = false})
        end)
        X.nearbyBlock(page, true)
        UI.Label(page, "Opcoes finas nas abas COMBATE e VISUAL.", 20)
    end

    local function farmBlock(page, kws)
        UI.Section(page, "FARM")
        UI.Button(page, "💤  Modo AFK Farm (clicker + prompts + antiAFK)", function()
            preset({autoclick = true, instaprompt = true, autoprompt = true, antiafk = true})
            if kws and #kws > 0 then setKeywords(kws) end
            notify("AFK Farm", "Automacoes ligadas.", 3, "ok")
        end)
        UI.Button(page, "🌙  AFK Farm longo (+ auto rejoin + anti void)", function()
            preset({autoclick = true, instaprompt = true, autoprompt = true, antiafk = true, autorejoin = true, antivoid = true})
            if kws and #kws > 0 then setKeywords(kws) end
            notify("AFK Farm", "Modo longo ligado.", 3, "ok")
        end)
        UI.Button(page, "⚡  Clicker rapido (CPS 25)", function()
            preset({autoclick = true}, {})
            State.CPS = 25
            notify("Clicker", "25 cliques/seg.", 2, "ok")
        end)
        UI.Button(page, "⛔  Desligar farm", function()
            preset({autoclick = false, instaprompt = false, autoprompt = false, autocollect = false, obj_esp = false})
        end)
    end

    local function exploreBlock(page)
        UI.Section(page, "SOCIAL / EXPLORAR")
        UI.Button(page, "👁  ESP de jogadores", function()
            preset({esp_box = true, esp_name = true, esp_health = true})
        end)
        UI.Button(page, "💤  Anti AFK", function()
            preset({antiafk = true})
        end)
        X.nearbyBlock(page, true)
        UI.Label(page, "Use a aba TROLL para teleportar, observar e grudar em jogadores.", 20)
    end

    local function groupButtons(page, groups)
        UI.Section(page, "OBJETOS DO MAPA")
        local all = {}
        for _, g in ipairs(groups) do
            for _, k in ipairs(g[2]) do
                table.insert(all, k)
            end
            UI.Button(page, "👁  ESP: " .. g[1], function()
                setKeywords(g[2])
                preset({obj_esp = true})
                notify("ESP", g[1] .. " ligado.", 2, "ok")
            end)
            UI.Button(page, "📍  Ir ate: " .. g[1], function()
                local p = nearestObj(function(d) return nameHas(d, g[2]) end)
                if p then
                    tpTo(p.Position)
                else
                    notify(g[1], "Nada encontrado.", 3, "err")
                end
            end)
        end
        UI.Button(page, "🧲  ESP + Auto coletar tudo acima", function()
            setKeywords(all)
            preset({obj_esp = true, autocollect = true, antiafk = true})
            notify("Coleta", "ESP e auto coleta ligados.", 3, "ok")
        end)
        UI.Button(page, "👀  ESP em tudo acima (sem coletar)", function()
            setKeywords(all)
            preset({obj_esp = true})
        end)
        UI.Button(page, "⛔  Desligar ESP / coleta", function()
            preset({obj_esp = false, autocollect = false})
        end)
        UI.Label(page, "Nomes de objetos mudam com updates. Ajuste pelo SCANNER na aba MUNDO se algo nao aparecer.", 28)
    end

    -- opts: info, custom(page), groups, shooter, farm, explore, nomove
    local function builder(opts)
        return function(page)
            if opts.info then UI.Label(page, opts.info, opts.infoH or 30) end
            if opts.custom then opts.custom(page) end
            if opts.shooter then shooterBlock(page) end
            if opts.groups then groupButtons(page, opts.groups) end
            if opts.farm then
                local all = {}
                for _, g in ipairs(opts.groups or {}) do
                    for _, k in ipairs(g[2]) do table.insert(all, k) end
                end
                farmBlock(page, all)
            end
            if not opts.nomove then moveModeButtons(page) end
            if opts.explore then exploreBlock(page) end
            utilBlock(page)
        end
    end

    -- notificador generico de objetos novos no workspace
    local function watchSpawn(names, title, flagGet, kind)
        bind(workspace.ChildAdded, function(c)
            if not flagGet() then return end
            local n = c.Name:lower()
            for _, k in ipairs(names) do
                if n:find(k, 1, true) then
                    notify(title, c.Name, 4, kind or "err")
                    return
                end
            end
        end)
    end

    -- PRISON LIFE ------------------------------------------------------
    local function buildPrison(page)
        UI.Section(page, "FUGA")
        UI.Button(page, "🚪  Fugir da Prison (voo suave)", function()
            notify("Prison Life", "Fugindo para a Base dos Criminosos...", 3)
            smoothTeleport(PrisonSpots[5][2])
            notify("Prison Life", "Voce esta fora da prison!", 3, "ok")
        end)
        UI.Button(page, "⚡  Fugir da Prison (instantaneo)", function()
            tpTo(PrisonSpots[5][2])
        end)
        UI.Button(page, "🧰  Fuga completa (pega M9 + AK-47 e foge)", function()
            giveItem("M9")
            task.wait(0.5)
            giveItem("AK-47")
            task.wait(0.5)
            smoothTeleport(PrisonSpots[5][2])
        end)
        UI.Button(page, "🔪  Fuga furtiva (faca + speed + fly baixo)", function()
            giveItem("Crude Knife")
            preset({speed = true, fly = true}, {speedv = 24, flyv = 35})
            smoothTeleport(PrisonSpots[5][2])
            preset({fly = false})
        end)

        UI.Section(page, "TELEPORTES")
        for _, spot in ipairs(PrisonSpots) do
            UI.Button(page, "📍  " .. spot[1], function()
                smoothTeleport(spot[2])
            end)
        end
        UI.Button(page, "🎲  Teleporte aleatorio entre os pontos", function()
            smoothTeleport(PrisonSpots[math.random(1, #PrisonSpots)][2])
        end)
        X.slotButtons(page)

        UI.Section(page, "ARMAS E ITENS")
        local guns = {"Remington 870", "M9", "AK-47", "M4A1"}
        for _, gun in ipairs(guns) do
            UI.Button(page, "🔫  Pegar " .. gun, function()
                giveItem(gun)
            end)
        end
        UI.Button(page, "🔫  Pegar todas", function()
            for _, gun in ipairs(guns) do
                giveItem(gun)
                task.wait(0.4)
            end
        end)
        for _, it in ipairs({{"Crude Knife", "🔪"}, {"Hammer", "🔨"}, {"Key card", "🗝"}}) do
            UI.Button(page, it[2] .. "  Pegar " .. it[1], function()
                giveItem(it[1])
            end)
        end
        local autoGear = false
        UI.Toggle(page, "Reequipar M9 + Remington ao renascer", false, function(on) autoGear = on end)
        bind(LocalPlayer.CharacterAdded, function()
            if not autoGear then return end
            task.wait(2.5)
            for _, g in ipairs({"M9", "Remington 870"}) do
                if not autoGear then break end
                giveItem(g)
                task.wait(0.5)
            end
        end)

        UI.Section(page, "TIMES")
        local function team(name, label)
            UI.Button(page, label, function()
                local ok = pcall(function()
                    workspace.Remote.TeamEvent:FireServer(name)
                end)
                notify("Time", ok and "Troca solicitada." or "Falhou ao trocar.", 2, ok and "ok" or "err")
            end)
        end
        team("Bright orange", "🟧  Virar Prisioneiro")
        team("Bright blue", "🟦  Virar Guarda")
        team("Medium stone grey", "⬜  Virar Neutro")

        UI.Section(page, "ESP POR TIME")
        UI.Button(page, "🎨  ESP colorido por time (guarda / preso / criminoso)", function()
            preset({esp_team = true, esp_chams = true, esp_name = true, esp_health = true})
        end)
        UI.Button(page, "🚨  Alerta de guarda perto (60 studs)", function()
            preset({enemyalert = true}, {alertdist = 60})
        end)

        UI.Section(page, "COMBATE / EXTRAS")
        UI.Button(page, "🎯  Aimbot Legit + ESP", function()
            preset({aim = true, aim_always = false, esp_box = true, esp_name = true, esp_health = true}, {aim_fov = 100, aim_smooth = 20})
        end)
        UI.Button(page, "🔥  Aimbot forte + Trigger", function()
            preset({aim = true, aim_always = true, trigger = true}, {aim_fov = 220, aim_smooth = 70})
        end)
        UI.Button(page, "💀  Renascer onde morreu (ligar)", function()
            preset({respawnback = true})
            notify("Prison Life", "Voce volta onde morreu.", 3, "ok")
        end)
        UI.Button(page, "🏃  Speed 28 + pulo 70 (seguro)", function()
            preset({speed = true, jump = true}, {speedv = 28, jumpv = 70})
        end)
        UI.Button(page, "🛡  Anti fling + anti void", function()
            preset({antifling = true, antivoid = true})
        end)
        X.nearbyBlock(page, true)
        UI.Button(page, "⛔  Desligar tudo", function()
            preset({aim = false, esp_box = false, esp_name = false, esp_health = false, esp_chams = false,
                esp_team = false, enemyalert = false, speed = false, jump = false, respawnback = false, trigger = false})
        end)
    end

    -- MURDER MYSTERY 2 --------------------------------------------------
    local function mm2HasTool(pl, name)
        local c = pl.Character
        local bp = pl:FindFirstChild("Backpack")
        return (c and c:FindFirstChild(name)) or (bp and bp:FindFirstChild(name))
    end
    local function mm2Find(tool)
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer and mm2HasTool(pl, tool) then
                return pl
            end
        end
    end

    local function buildMM2(page)
        UI.Label(page, "Roles detectadas pelas ferramentas (Knife / Gun). Vermelho = assassino, azul = xerife, verde = inocente.", 30)
        UI.Section(page, "ROLES")
        UI.Toggle(page, "ESP por Role", false, function(on)
            if on then
                ESP.ColorFn = function(pl)
                    if mm2HasTool(pl, "Knife") then
                        return Color3.fromRGB(255, 60, 60)
                    elseif mm2HasTool(pl, "Gun") then
                        return Color3.fromRGB(70, 140, 255)
                    end
                    return Color3.fromRGB(90, 230, 120)
                end
                preset({esp_chams = true, esp_name = true, esp_box = true})
            else
                ESP.ColorFn = nil
            end
        end)
        local announce, lastK = false, nil
        UI.Toggle(page, "Avisar quando aparecer o assassino", false, function(on) announce = on end)
        local nearWarn, lastNear = false, 0
        UI.Toggle(page, "Alerta: assassino a menos de 35 studs", false, function(on) nearWarn = on end)
        local gunWatch, lastGun = false, nil
        UI.Toggle(page, "Avisar quando a arma cair", false, function(on) gunWatch = on end)
        task.spawn(function()
            while alive do
                if announce then
                    local k = mm2Find("Knife")
                    if k and k ~= lastK then
                        notify("Assassino", k.DisplayName .. " (@" .. k.Name .. ")", 5, "err")
                    end
                    lastK = k
                end
                if nearWarn and os.clock() - lastNear > 2 then
                    local k, r = mm2Find("Knife"), getRoot()
                    local kr = k and k.Character and k.Character:FindFirstChild("HumanoidRootPart")
                    if kr and r and (kr.Position - r.Position).Magnitude < 35 then
                        lastNear = os.clock()
                        notify("PERIGO", "Assassino perto de voce!", 2, "err")
                    end
                end
                if gunWatch then
                    local drop = workspace:FindFirstChild("GunDrop", true)
                    if drop and drop ~= lastGun then
                        notify("MM2", "A arma caiu no chao!", 4, "ok")
                    end
                    lastGun = drop
                end
                task.wait(1)
            end
        end)
        UI.Button(page, "🔪  Quem e o assassino?", function()
            local k = mm2Find("Knife")
            if k then
                notify("Assassino", k.DisplayName .. " (@" .. k.Name .. ")", 5, "err")
            else
                notify("MM2", "Ninguem com faca agora.", 3)
            end
        end)
        UI.Button(page, "🔫  Quem e o xerife?", function()
            local g = mm2Find("Gun")
            if g then
                notify("Xerife", g.DisplayName .. " (@" .. g.Name .. ")", 5)
            else
                notify("MM2", "Ninguem com arma agora.", 3)
            end
        end)
        UI.Button(page, "👁  Observar o assassino", function()
            local k = mm2Find("Knife")
            local h = k and k.Character and k.Character:FindFirstChildOfClass("Humanoid")
            if h then workspace.CurrentCamera.CameraSubject = h else notify("MM2", "Ninguem com faca.", 3, "err") end
        end)
        UI.Button(page, "👁  Observar o xerife", function()
            local g = mm2Find("Gun")
            local h = g and g.Character and g.Character:FindFirstChildOfClass("Humanoid")
            if h then workspace.CurrentCamera.CameraSubject = h else notify("MM2", "Ninguem com arma.", 3, "err") end
        end)
        UI.Button(page, "⏹  Parar de observar", function()
            local h = getHum()
            if h then workspace.CurrentCamera.CameraSubject = h end
        end)
        UI.Button(page, "🎯  Selecionar assassino como alvo (aba TROLL)", function()
            local k = mm2Find("Knife")
            if k then
                TS.Sel = k
                notify("Alvo", k.DisplayName .. " selecionado.", 3, "ok")
            else
                notify("MM2", "Ninguem com faca.", 3, "err")
            end
        end)

        UI.Section(page, "ITENS")
        UI.Button(page, "🔫  Teleportar ate arma caida", function()
            local drop = workspace:FindFirstChild("GunDrop", true)
            local p = drop and partOf(drop)
            if p then
                tpTo(p.Position)
                notify("MM2", "Arma encontrada!", 2, "ok")
            else
                notify("MM2", "Nenhuma arma caida.", 3, "err")
            end
        end)
        UI.Button(page, "🔫  Pegar arma e voltar (ida e volta)", function()
            local r = getRoot()
            local drop = workspace:FindFirstChild("GunDrop", true)
            local p = drop and partOf(drop)
            if r and p then
                local back = r.CFrame
                r.CFrame = CFrame.new(p.Position + Vector3.new(0, 2, 0))
                task.wait(0.35)
                r.CFrame = back
                notify("MM2", "Voltou ao ponto de origem.", 2, "ok")
            else
                notify("MM2", "Nenhuma arma caida.", 3, "err")
            end
        end)
        UI.Button(page, "🪙  Teleportar ate moeda mais proxima", function()
            local p = nearestObj(function(d) return d.Name == "Coin_Server" or d.Name:lower() == "coin" end)
            if p then tpTo(p.Position) else notify("MM2", "Nenhuma moeda achada.", 3, "err") end
        end)
        UI.Button(page, "🧲  Auto coletar moedas (ligar)", function()
            setKeywords({"coin"})
            preset({autocollect = true, obj_esp = true})
        end)
        UI.Button(page, "⛔  Parar de coletar", function()
            preset({autocollect = false, obj_esp = false})
        end)

        UI.Section(page, "SOBREVIVENCIA")
        UI.Button(page, "🧗  Esconder no ponto mais alto", function()
            local part = highestPart(workspace)
            if part then
                tpTo(Vector3.new(part.Position.X, part.Position.Y + part.Size.Y / 2 + 4, part.Position.Z))
            end
        end)
        UI.Button(page, "🏃  Speed 24 + Infinite Jump", function()
            preset({speed = true, infjump = true}, {speedv = 24})
        end)
        UI.Button(page, "🥷  Modo Fugitivo (speed 26 + anti fling + void)", function()
            preset({speed = true, infjump = true, antifling = true, antivoid = true}, {speedv = 26})
        end)
        moveModeButtons(page)
        utilBlock(page)
    end

    -- NATURAL DISASTER SURVIVAL -----------------------------------------
    local ndsTop, ndsTopAt = nil, 0
    local function ndsHighest()
        if ndsTop and ndsTop.Parent and os.clock() - ndsTopAt < 60 then
            return ndsTop
        end
        ndsTop = highestPart(workspace)
        ndsTopAt = os.clock()
        return ndsTop
    end

    local function buildNDS(page)
        UI.Label(page, "Fique no ponto mais alto do mapa ou voando durante os desastres.", 30)
        UI.Section(page, "SOBREVIVER")
        UI.Button(page, "⛰  Ir ao ponto mais alto do mapa", function()
            local part = ndsHighest()
            if part then
                tpTo(Vector3.new(part.Position.X, part.Position.Y + part.Size.Y / 2 + 4, part.Position.Z))
                notify("NDS", "Teleportado ao ponto mais alto.", 3, "ok")
            else
                notify("NDS", "Nenhum ponto encontrado.", 3, "err")
            end
        end)
        local autoTop = false
        UI.Toggle(page, "Ir ao ponto mais alto ao renascer", false, function(on) autoTop = on end)
        bind(LocalPlayer.CharacterAdded, function(c)
            if not autoTop then return end
            local r = c:WaitForChild("HumanoidRootPart", 5)
            task.wait(1.2)
            local part = ndsHighest()
            if r and part then
                r.CFrame = CFrame.new(part.Position + Vector3.new(0, part.Size.Y / 2 + 5, 0))
            end
        end)
        local plat
        UI.Button(page, "🛸  Plataforma segura (+120 studs)", function()
            local r = getRoot()
            if not r then return end
            if plat then plat:Destroy() end
            plat = new("Part", {
                Anchored = true, Size = Vector3.new(30, 2, 30), Material = Enum.Material.Neon,
                Color = C.accent, Position = r.Position + Vector3.new(0, 120, 0),
            }, workspace)
            tpTo(plat.Position + Vector3.new(0, 2, 0))
        end)
        UI.Button(page, "🛸  Plataforma gigante (+250 studs)", function()
            local r = getRoot()
            if not r then return end
            if plat then plat:Destroy() end
            plat = new("Part", {
                Anchored = true, Size = Vector3.new(60, 2, 60), Material = Enum.Material.Neon,
                Color = C.accent, Position = r.Position + Vector3.new(0, 250, 0),
            }, workspace)
            tpTo(plat.Position + Vector3.new(0, 2, 0))
        end)
        UI.Button(page, "🗑  Remover plataforma", function()
            if plat then plat:Destroy() plat = nil end
        end)
        UI.Button(page, "☁  Modo Seguro (fly ligado)", function()
            preset({fly = true, speed = true}, {flyv = 60, speedv = 40})
        end)
        UI.Button(page, "🪂  Sem dano de queda + anti void", function()
            preset({fallguard = true, antivoid = true})
            notify("NDS", "Protecao de queda ligada.", 3, "ok")
        end)
        UI.Toggle(page, "Gravidade baixa (30)", false, function(on)
            workspace.Gravity = on and 30 or OrigGravity
        end)
        UI.Button(page, "💀  Renascer onde morreu (ligar)", function()
            preset({respawnback = true})
        end)
        UI.Button(page, "👥  ESP de jogadores (ver quem ainda vive)", function()
            preset({esp_name = true, esp_health = true})
        end)
        moveModeButtons(page)
        utilBlock(page)
    end

    -- TOWER OF HELL ------------------------------------------------------
    local function buildToH(page)
        UI.Label(page, "Teleporta ao topo da torre e libera movimentacao.", 30)
        UI.Section(page, "TORRE")
        local function topOfTower()
            local container = workspace:FindFirstChild("tower") or workspace
            local part = highestPart(container)
            return part
        end
        UI.Button(page, "🏁  Ir ao topo da torre", function()
            local part = topOfTower()
            if part then
                tpTo(Vector3.new(part.Position.X, part.Position.Y + part.Size.Y / 2 + 4, part.Position.Z))
                notify("Tower", "Teleportado ao topo.", 3, "ok")
            else
                notify("Tower", "Torre nao encontrada.", 3, "err")
            end
        end)
        local autoTop = false
        UI.Toggle(page, "Ir ao topo ao renascer", false, function(on) autoTop = on end)
        bind(LocalPlayer.CharacterAdded, function(c)
            if not autoTop then return end
            local r = c:WaitForChild("HumanoidRootPart", 5)
            task.wait(1)
            local part = topOfTower()
            if r and part then
                r.CFrame = CFrame.new(part.Position + Vector3.new(0, part.Size.Y / 2 + 5, 0))
            end
        end)
        for _, h in ipairs({25, 50, 100, 200}) do
            UI.Button(page, "🪜  Subir " .. h .. " studs", function()
                local r = getRoot()
                if r then r.CFrame = r.CFrame + Vector3.new(0, h, 0) end
            end)
        end
        UI.Button(page, "☠  Neutralizar kill parts (so no seu cliente)", function()
            local n = 0
            for _, d in ipairs(workspace:GetDescendants()) do
                if d:IsA("BasePart") and (d.Name:lower():find("kill") or d.Name:lower():find("lava")) then
                    pcall(function() d.CanTouch = false end)
                    n = n + 1
                end
                if n % 400 == 0 then task.wait() end
            end
            notify("Tower", n .. " partes neutralizadas (depende do jogo).", 3, "ok")
        end)
        UI.Button(page, "🧗  Modo Escalada (speed + infjump)", function()
            preset({speed = true, infjump = true}, {speedv = 40})
        end)
        UI.Button(page, "🪂  Anti void + protecao de queda", function()
            preset({antivoid = true, fallguard = true})
        end)
        UI.Toggle(page, "Gravidade baixa (40)", false, function(on)
            workspace.Gravity = on and 40 or OrigGravity
        end)
        moveModeButtons(page)
        utilBlock(page)
    end

    -- REGISTRO ------------------------------------------------------------
    local fruitWatch, entityWatch = false, false

    local function soccerCustom(page)
                    local ball, goals = nil, {}
                    local cfg = {follow = false, kick = false, face = true, reach = 9, goalMode = "Mais longe de mim", lastKick = 0}

                    local function isBall(d)
                        if not d:IsA("BasePart") or d.Anchored then return false end
                        local n = d.Name:lower()
                        if not (n:find("ball", 1, true) or n:find("bola", 1, true)) then return false end
                        local m = d.Size.Magnitude
                        if m > 20 or m < 1 then return false end
                        local model = d:FindFirstAncestorOfClass("Model")
                        if model and Players:GetPlayerFromCharacter(model) then return false end
                        return true
                    end

                    local function refresh()
                        local b, gl, n = nil, {}, 0
                        for _, d in ipairs(workspace:GetDescendants()) do
                            n = n + 1
                            if n % 5000 == 0 then task.wait() end
                            if d:IsA("BasePart") then
                                if not b and isBall(d) then b = d end
                                local ln = d.Name:lower()
                                if (ln:find("goal", 1, true) or ln:find("trave", 1, true)) and not ln:find("gold", 1, true) then
                                    table.insert(gl, d)
                                end
                            end
                        end
                        ball, goals = b, gl
                    end

                    local function targetGoal()
                        local r = getRoot()
                        if not r or #goals == 0 then return end
                        local best, bd
                        for _, g in ipairs(goals) do
                            if g.Parent then
                                local d = (g.Position - r.Position).Magnitude
                                local better = bd == nil or (cfg.goalMode == "Mais perto de mim" and d < bd)
                                    or (cfg.goalMode ~= "Mais perto de mim" and d > bd)
                                if better then best, bd = g, d end
                            end
                        end
                        return best
                    end

                    task.spawn(function()
                        local lastRefresh = 0
                        while alive do
                            if cfg.follow or cfg.kick then
                                if not ball or not ball.Parent or os.clock() - lastRefresh > 4 then
                                    lastRefresh = os.clock()
                                    refresh()
                                end
                                local r, h = getRoot(), getHum()
                                if ball and ball.Parent and r and h then
                                    local dist = (ball.Position - r.Position).Magnitude
                                    if cfg.follow and dist > 3 then
                                        h:MoveTo(ball.Position)
                                    end
                                    if cfg.kick and dist <= cfg.reach and os.clock() - cfg.lastKick > 0.7 then
                                        cfg.lastKick = os.clock()
                                        if cfg.face then
                                            local g = targetGoal()
                                            if g then
                                                r.CFrame = CFrame.lookAt(r.Position, Vector3.new(g.Position.X, r.Position.Y, g.Position.Z))
                                            end
                                        end
                                        pcall(function()
                                            if mouse1click then mouse1click() else VirtualUser:ClickButton1(Vector2.new()) end
                                        end)
                                    end
                                end
                            end
                            task.wait(0.1)
                        end
                    end)

                    UI.Section(page, "BOLA E GOL")
                    UI.Button(page, "🔄  Atualizar bola e gols", function()
                        refresh()
                        notify("Futebol", (ball and "Bola achada" or "Bola NAO achada") .. " • " .. #goals .. " gol(s)", 3, ball and "ok" or "err")
                    end)
                    UI.Toggle(page, "Seguir a bola (corre ate ela)", false, function(v) cfg.follow = v end)
                    UI.Toggle(page, "Auto chute (clica quando a bola esta perto)", false, function(v) cfg.kick = v end)
                    UI.Slider(page, "Alcance do chute (studs)", 4, 25, cfg.reach, function(v) cfg.reach = v end)
                    UI.Toggle(page, "Virar para o gol antes de chutar", true, function(v) cfg.face = v end)
                    UI.Cycle(page, "Gol alvo", {"Mais longe de mim", "Mais perto de mim"}, cfg.goalMode, function(v) cfg.goalMode = v end)
                    UI.Button(page, "⚽  Teleportar na bola", function()
                        if not ball or not ball.Parent then refresh() end
                        if ball then tpTo(ball.Position + Vector3.new(0, 2, 0)) else notify("Futebol", "Bola nao encontrada.", 3, "err") end
                    end)
                    UI.Button(page, "🥅  Teleportar no gol alvo", function()
                        if #goals == 0 then refresh() end
                        local g = targetGoal()
                        if g then tpTo(g.Position + Vector3.new(0, 3, 0)) else notify("Futebol", "Gol nao encontrado.", 3, "err") end
                    end)
                    UI.Button(page, "👁  ESP da bola e dos gols", function()
                        setKeywords({"ball", "bola", "goal", "trave"})
                        preset({obj_esp = true})
                    end)

                    UI.Section(page, "JOGADOR")
                    UI.Button(page, "🏃  Speed 28 + anti void", function()
                        preset({speed = true, antivoid = true}, {speedv = 28})
                    end)
                    UI.Button(page, "🛡  Anti fling (muito util no futebol)", function()
                        preset({antifling = true, antivoid = true})
                    end)
                    UI.Button(page, "👁  ESP de jogadores por time + nome", function()
                        preset({esp_team = true, esp_name = true, esp_chams = true})
                    end)
                    UI.Button(page, "🚨  Alerta de adversario perto (40 studs)", function()
                        preset({enemyalert = true}, {alertdist = 40})
                    end)
    end

    local function animalCustom(page)
        local cfg = {on = false, tp = false, word = ""}
        local prompts, refreshedAt = {}, 0
        local function refreshPrompts()
            local list, n = {}, 0
            for _, d in ipairs(workspace:GetDescendants()) do
                n = n + 1
                if n % 5000 == 0 then task.wait() end
                if d:IsA("ProximityPrompt") then table.insert(list, d) end
            end
            prompts, refreshedAt = list, os.clock()
        end
        local function promptPos(p)
            if p.Parent:IsA("BasePart") then return p.Parent.Position end
            if p.Parent:IsA("Attachment") then return p.Parent.WorldPosition end
        end
        task.spawn(function()
            while alive do
                if cfg.on and fireproximityprompt then
                    if os.clock() - refreshedAt > 3 then refreshPrompts() end
                    local r = getRoot()
                    if r then
                        local best, bd, bpos
                        for _, p in ipairs(prompts) do
                            if p.Parent and p.Enabled then
                                local txt = ((p.ActionText or "") .. " " .. (p.ObjectText or "")):lower()
                                if cfg.word == "" or txt:find(cfg.word, 1, true) then
                                    local pos = promptPos(p)
                                    if pos then
                                        local d = (pos - r.Position).Magnitude
                                        if not bd or d < bd then best, bd, bpos = p, d, pos end
                                    end
                                end
                            end
                        end
                        if best then
                            if bd <= best.MaxActivationDistance then
                                pcall(fireproximityprompt, best)
                            elseif cfg.tp and bd < 400 then
                                r.CFrame = CFrame.new(bpos + Vector3.new(0, 3, 0))
                                task.wait(0.2)
                                pcall(fireproximityprompt, best)
                            end
                        end
                    end
                    task.wait(0.5)
                else
                    task.wait(0.4)
                end
            end
        end)

        UI.Section(page, "ATENDIMENTO AUTOMATICO")
        UI.Toggle(page, "Auto interagir (prompt mais proximo)", false, function(v)
            cfg.on = v
            if v and not fireproximityprompt then
                notify("Aviso", "Seu executor nao suporta fireproximityprompt.", 4, "err")
            end
        end)
        UI.Toggle(page, "Teleportar ate o prompt (agressivo)", false, function(v) cfg.tp = v end)
        UI.TextInput(page, "Filtrar prompts por texto (ex: curar, atender)...", "", function(t) cfg.word = t:lower() end)
        UI.Button(page, "🤏  Prompts instantaneos + automaticos", function()
            preset({instaprompt = true, autoprompt = true})
        end)
        UI.Button(page, "💰  Coletar dinheiro / gorjetas automaticamente", function()
            setKeywords({"cash", "money", "coin", "tip", "gorjeta"})
            preset({autocollect = true, obj_esp = true})
        end)
        UI.Button(page, "🐾  Ir ate o animal / paciente mais proximo", function()
            local p = nearestObj(function(d)
                return nameHas(d, {"patient", "paciente", "animal", "pet", "dog", "cat", "puppy", "kitten", "bunny"})
                    and not (d:FindFirstAncestorOfClass("Model") and Players:GetPlayerFromCharacter(d:FindFirstAncestorOfClass("Model")))
            end)
            if p then tpTo(p.Position) else notify("Hospital", "Nenhum animal encontrado.", 3, "err") end
        end)
        UI.Button(page, "🏃  Speed 28 + anti void + anti AFK", function()
            preset({speed = true, antivoid = true, antiafk = true}, {speedv = 28})
        end)
    end

    Games = {
        {Name = "Prison Life", Desc = "Fuga, teleportes, armas, itens, times, ESP por time e aimbot",
            Ids = {155615604, 4669040}, Keys = {"prison life"}, Build = buildPrison},
        {Name = "Murder Mystery 2", Desc = "ESP de roles, alertas, arma, moedas, observar assassino",
            Ids = {142823291}, Keys = {"murder mystery"}, Build = buildMM2},
        {Name = "Blox Fruits", Desc = "Frutas, aviso de fruta, baus, bosses e auto coletar",
            Ids = {2753915549, 4442272183, 7449423635}, Keys = {"blox fruits"},
            Build = builder({
                info = "Ferramentas client-side: achar frutas e baus. Auto farm exige remotes especificos e nao esta incluso.", infoH = 40,
                groups = {{"Frutas", {"fruit"}}, {"Baus", {"chest"}}, {"NPCs / Bosses", {"boss", "quest"}}, {"Espadas / Itens", {"sword", "material"}}},
                custom = function(page)
                    UI.Section(page, "FRUTAS")
                    UI.Toggle(page, "Avisar quando uma fruta aparecer", false, function(on) fruitWatch = on end)
                    watchSpawn({"fruit"}, "Fruta apareceu", function() return fruitWatch end, "ok")
                    UI.Button(page, "🍎  Teleportar na fruta mais proxima", function()
                        local p = nearestObj(function(d) return d.Name:lower():find("fruit") ~= nil end)
                        if p then tpTo(p.Position) else notify("Fruta", "Nenhuma fruta no mapa.", 3, "err") end
                    end)
                    UI.Button(page, "🌐  Procurar fruta em outro servidor (hop)", serverHop)
                    UI.Section(page, "SEA EXPLORER")
                    UI.Button(page, "🎯  ESP de jogadores + Anti AFK", function()
                        preset({esp_box = true, esp_name = true, esp_health = true, antiafk = true})
                    end)
                    UI.Button(page, "🦘  Sky Jump (Infinite Jump + pulo alto)", function()
                        preset({infjump = true, jump = true}, {jumpv = 120})
                    end)
                    UI.Button(page, "🌊  Modo Navegar (fly baixo + noclip)", function()
                        preset({fly = true, noclip = true}, {flyv = 70})
                    end)
                end,
            })},
        {Name = "Doors", Desc = "ESP de portas/itens, aviso de entidades, prompts instantaneos",
            Ids = {6516141723, 6839171747}, Keys = {"doors"},
            Build = builder({
                info = "ESP de portas, chaves e itens usando o scanner por nome.",
                groups = {
                    {"Portas", {"door"}}, {"Chaves", {"key"}}, {"Alavancas", {"lever"}},
                    {"Livros", {"book"}}, {"Itens", {"lighter", "flashlight", "vitamin", "lockpick", "battery", "bandage", "crucifix", "gold"}},
                    {"Gavetas / Armarios", {"drawer", "locker", "wardrobe"}},
                },
                custom = function(page)
                    UI.Section(page, "ENTIDADES")
                    UI.Toggle(page, "Avisar entidades (Rush, Ambush, Seek...)", false, function(on) entityWatch = on end)
                    watchSpawn({"rush", "ambush", "a60", "a120", "eyes", "screech", "halt", "seek", "figure", "jeff"},
                        "Entidade!", function() return entityWatch end, "err")
                    UI.Section(page, "ATALHOS")
                    UI.Button(page, "🤏  Prompts instantaneos + automaticos", function()
                        preset({instaprompt = true, autoprompt = true})
                    end)
                    UI.Button(page, "💡  Fullbright + sem neblina", function()
                        preset({fullbright = true, nofog = true})
                    end)
                    UI.Button(page, "🏃  Speed 25 (seguro)", function()
                        preset({speed = true}, {speedv = 25})
                    end)
                    UI.Button(page, "📖  ESP de tudo importante (portas, chaves, livros)", function()
                        setKeywords({"door", "key", "book", "lever"})
                        preset({obj_esp = true})
                    end)
                end,
                nomove = true,
            })},
        {Name = "Natural Disaster Survival", Desc = "Ponto mais alto, plataformas, queda segura, fly e gravidade",
            Ids = {189707}, Keys = {"natural disaster"}, Build = buildNDS},
        {Name = "Tower of Hell", Desc = "Topo, auto topo, kill parts, escalada e gravidade",
            Ids = {1962086868}, Keys = {"tower of hell"}, Build = buildToH},
        {Name = "Arsenal", Desc = "Presets de aimbot, ESP, trigger, hitbox e alertas",
            Ids = {286090429}, Keys = {"arsenal"},
            Build = builder({info = "FPS: presets de mira e ESP.", shooter = true})},
        {Name = "Rivals", Desc = "Presets de aimbot, ESP, trigger e alertas",
            Ids = {17625359962}, Keys = {"rivals"},
            Build = builder({info = "FPS competitivo: presets prontos.", shooter = true, nomove = true})},
        {Name = "Phantom Forces", Desc = "Presets de aimbot, ESP e trigger (cuidado)",
            Ids = {292439477, 299659045}, Keys = {"phantom forces"},
            Build = builder({info = "FPS tatico: presets prontos. Anti-cheat forte, evite Rage.", shooter = true, nomove = true})},
        {Name = "Da Hood", Desc = "Camlock com predicao, ESP, trigger, cash e armas",
            Ids = {2788229376}, Keys = {"da hood"},
            Build = builder({
                info = "Dica: predicao 8-12 no Rage.",
                custom = function(page)
                    UI.Section(page, "CAMLOCK")
                    UI.Button(page, "🔒  Camlock (trava e segue, predicao 9)", function()
                        preset({aim = true, aim_always = true, aim_sticky = true, aim_wall = false},
                            {aim_pred = 9, aim_smooth = 60, aim_fov = 250})
                        notify("Camlock", "Ligado. Troque a parte do corpo em COMBATE.", 3, "ok")
                    end)
                    UI.Button(page, "🔓  Desligar camlock", function()
                        preset({aim = false, aim_always = false})
                    end)
                    UI.Button(page, "🎚  Camlock suave (predicao 6)", function()
                        preset({aim = true, aim_always = false, aim_sticky = true}, {aim_pred = 6, aim_smooth = 35, aim_fov = 180})
                    end)
                end,
                shooter = true,
                groups = {{"Dinheiro", {"cash", "money"}}, {"Armas", {"revolver", "shotty", "glock", "tactical", "uzi"}}},
            })},
        {Name = "The Strongest Battlegrounds", Desc = "ESP, camera, speed, orbitar/grudar em alvo",
            Ids = {10449761463}, Keys = {"strongest battlegrounds"},
            Build = builder({
                info = "Battleground: ESP + FOV ajudam. Use a aba TROLL para orbitar/grudar no alvo.",
                shooter = true,
                custom = function(page)
                    UI.Section(page, "MOVIMENTO")
                    UI.Button(page, "⚡  Speed 45 + Infinite Jump", function()
                        preset({speed = true, infjump = true}, {speedv = 45})
                    end)
                    UI.Button(page, "🛡  Anti fling + anti void", function()
                        preset({antifling = true, antivoid = true})
                    end)
                    UI.Button(page, "🎥  FOV 100 + zoom livre", function()
                        preset({fovcam = true, zoom = true}, {fovcamv = 100})
                    end)
                end,
            })},
        {Name = "Slap Battles", Desc = "ESP, luvas, slapples, movimentacao e anti void",
            Ids = {9431156611}, Keys = {"slap battles"},
            Build = builder({info = "Arena de slaps: ESP, luvas e modo explorar.", explore = true,
                custom = function(page)
                    UI.Section(page, "ARENA")
                    UI.Button(page, "🛡  Anti void + anti fling (nao cair da arena)", function()
                        preset({antivoid = true, antifling = true})
                    end)
                    UI.Button(page, "⚡  Speed 30 + Infinite Jump", function()
                        preset({speed = true, infjump = true}, {speedv = 30})
                    end)
                end,
                groups = {{"Luvas", {"glove"}}, {"Slapples", {"slapple"}}}})},
        {Name = "Blade Ball", Desc = "ESP, bola, seguir bola, speed e anti AFK",
            Ids = {13772394625}, Keys = {"blade ball"},
            Build = builder({info = "Sem auto-parry (exige remotes). Foco em ESP da bola e movimento.", explore = true,
                custom = function(page)
                    UI.Section(page, "BOLA")
                    UI.Button(page, "⚽  Teleportar perto da bola", function()
                        local p = nearestObj(function(d) return d.Name:lower() == "ball" or d.Name:lower():find("ball") ~= nil end)
                        if p then tpTo(p.Position + Vector3.new(0, 4, 8)) else notify("Bola", "Bola nao encontrada.", 3, "err") end
                    end)
                    UI.Button(page, "🛡  Anti void + anti AFK", function()
                        preset({antivoid = true, antiafk = true})
                    end)
                end,
                groups = {{"Bola", {"ball"}}}})},
        {Name = "BedWars", Desc = "ESP, camas, geradores, aimbot e presets",
            Ids = {6872265039, 6872274481}, Keys = {"bedwars"},
            Build = builder({info = "BedWars: ESP, aimbot e atalhos para camas/geradores.", shooter = true,
                custom = function(page)
                    UI.Section(page, "ESTRATEGIA")
                    UI.Button(page, "🛏  ESP de camas + jogadores", function()
                        setKeywords({"bed"})
                        preset({obj_esp = true, esp_box = true, esp_name = true})
                    end)
                    UI.Button(page, "💎  Speed 24 + anti void (pontes)", function()
                        preset({speed = true, antivoid = true}, {speedv = 24})
                    end)
                end,
                groups = {{"Camas", {"bed"}}, {"Diamantes", {"diamond"}}, {"Esmeraldas", {"emerald"}}, {"Geradores", {"generator", "spawner"}}}})},
        {Name = "Jailbreak", Desc = "ESP, fly, cash, airdrop, joias e anti void",
            Ids = {606849621}, Keys = {"jailbreak"},
            Build = builder({info = "Anti-cheat forte: use com cuidado.", explore = true,
                custom = function(page)
                    UI.Section(page, "ASSALTOS")
                    UI.Button(page, "💰  ESP de dinheiro + airdrop + joias", function()
                        setKeywords({"cash", "money", "airdrop", "jewel", "diamond"})
                        preset({obj_esp = true})
                    end)
                    UI.Button(page, "🚓  ESP por time (policia / criminoso)", function()
                        preset({esp_team = true, esp_name = true, esp_chams = true})
                    end)
                end,
                groups = {{"Dinheiro", {"cash", "money"}}, {"Airdrop", {"airdrop"}}, {"Joias", {"jewel", "diamond"}}, {"Cofres", {"safe", "vault"}}}})},
        {Name = "Brookhaven RP", Desc = "Musica por ID (phonk, funk, lofi), explorar, teleporte e brincadeiras",
            Ids = {4924922222}, Keys = {"brookhaven"},
            Build = builder({info = "RP: modo explorar. A aba TROLL tem teleporte, observar, grudar e fling.", explore = true,
                custom = function(page)
                    X.musicBlock(page)
                    UI.Section(page, "BRINCADEIRAS")
                    UI.Button(page, "🌈  Modo Festa (spin + neon)", function()
                        preset({spin = true, neon = true})
                    end)
                    UI.Button(page, "🛑  Parar brincadeiras", function()
                        preset({spin = false, neon = false})
                    end)
                    UI.Button(page, "🛡  Anti fling (muito util em RP)", function()
                        preset({antifling = true})
                    end)
                end})},
        {Name = "Adopt Me!", Desc = "Auto prompt, clicker, moedas, estrelas e AFK",
            Ids = {920587237}, Keys = {"adopt me"},
            Build = builder({info = "Tarefas repetitivas com prompts e cliques.", farm = true,
                groups = {{"Moedas", {"coin", "bucks"}}, {"Estrelas", {"star"}}, {"Ovos", {"egg"}}, {"Presentes", {"gift", "present"}}}})},
        {Name = "Royale High", Desc = "Auto coletar diamantes, baus, explorar",
            Ids = {735030788}, Keys = {"royale high"},
            Build = builder({info = "Coleta de itens do mapa.", farm = true,
                groups = {{"Diamantes", {"diamond", "gem", "crystal"}}, {"Baus", {"chest"}}, {"Halos", {"halo"}}}})},
        {Name = "Pet Simulator 99", Desc = "Auto click, moedas, orbs, gems, baus e ovos",
            Ids = {8737899170}, Keys = {"pet simulator"},
            Build = builder({info = "Simulator: clicker e coleta por scanner.", farm = true,
                groups = {{"Moedas", {"coin"}}, {"Orbs", {"orb"}}, {"Gems", {"gem", "diamond"}}, {"Baus", {"chest"}}, {"Ovos", {"egg"}}, {"Presentes", {"gift"}}}})},
        {Name = "Grow a Garden", Desc = "Auto prompt, colheita, ovos, sementes e AFK",
            Ids = {126884695634066}, Keys = {"grow a garden"},
            Build = builder({info = "Colheita via prompts instantaneos e automaticos.", farm = true,
                groups = {{"Frutas", {"fruit"}}, {"Plantas", {"plant", "crop", "seed"}}, {"Ovos", {"egg"}}, {"Lojas", {"shop", "stand"}}}})},
        {Name = "Fisch", Desc = "Auto click, AFK, prompts, peixes e baus",
            Ids = {16732694052}, Keys = {"fisch"},
            Build = builder({info = "Pesca: clicker + anti AFK + prompts.", farm = true,
                groups = {{"Peixes", {"fish"}}, {"Baus / Tesouros", {"chest", "treasure"}}, {"NPCs", {"npc", "merchant"}}}})},
        {Name = "Steal a Brainrot", Desc = "Roubar e voltar, auto comprar/roubar, ESP, bases, cash e explorar",
            Ids = {109983668079237}, Keys = {"brainrot"},
            Build = builder({info = "Prompts automaticos, roubo rapido e ESP de itens. Nomes de textos/objetos podem mudar com updates.", infoH = 30, farm = true,
                custom = function(page)
                    local function scanPrompts()
                        local list, n = {}, 0
                        for _, d in ipairs(workspace:GetDescendants()) do
                            n = n + 1
                            if n % 5000 == 0 then task.wait() end
                            if d:IsA("ProximityPrompt") then table.insert(list, d) end
                        end
                        return list
                    end
                    local function promptHas(p, words)
                        local t = ((p.ActionText or "") .. " " .. (p.ObjectText or "") .. " " .. p.Name):lower()
                        for _, w in ipairs(words) do
                            if t:find(w, 1, true) then return true end
                        end
                        return false
                    end
                    local function promptPos(p)
                        local par = p.Parent
                        if par and par:IsA("BasePart") then return par.Position end
                        if par and par:IsA("Attachment") then return par.WorldPosition end
                        local part = par and partOf(par)
                        return part and part.Position
                    end
                    local STEAL, BUY = {"steal", "roubar"}, {"purchase", "buy", "comprar"}

                    UI.Section(page, "BASE E ROUBO")
                    UI.Button(page, "🏠  Salvar minha base (slot 1)", function()
                        local r = getRoot()
                        if r then
                            X.Slots[1] = r.Position
                            notify("Base", "Slot 1 = sua base.", 3, "ok")
                        end
                    end)
                    UI.Button(page, "🏃  Ir para minha base (slot 1)", function()
                        if X.Slots[1] then smoothTeleport(X.Slots[1]) else notify("Base", "Salve a base primeiro.", 3, "err") end
                    end)
                    UI.Button(page, "🥷  Roubar o mais proximo e voltar para a base", function()
                        local r = getRoot()
                        if not r or not X.Slots[1] then notify("Roubo", "Salve a base (slot 1) primeiro.", 3, "err") return end
                        if not fireproximityprompt then notify("Roubo", "Executor sem fireproximityprompt.", 4, "err") return end
                        local best, bd, bpos
                        for _, p in ipairs(scanPrompts()) do
                            if p.Enabled and promptHas(p, STEAL) then
                                local pos = promptPos(p)
                                if pos then
                                    local d = (pos - r.Position).Magnitude
                                    if not bd or d < bd then best, bd, bpos = p, d, pos end
                                end
                            end
                        end
                        if not best then notify("Roubo", "Nenhum prompt de roubo achado.", 3, "err") return end
                        pcall(function() best.HoldDuration = 0 end)
                        r.CFrame = CFrame.new(bpos + Vector3.new(0, 3, 0))
                        task.wait(0.25)
                        pcall(fireproximityprompt, best)
                        task.wait(0.35)
                        r.CFrame = CFrame.new(X.Slots[1] + Vector3.new(0, 3, 0))
                        notify("Roubo", "Tentativa feita. Voltou para a base.", 3, "ok")
                    end)
                    UI.Button(page, "📍  Ir ate o prompt de roubo mais proximo", function()
                        local r = getRoot()
                        if not r then return end
                        local bd, bpos
                        for _, p in ipairs(scanPrompts()) do
                            if promptHas(p, STEAL) then
                                local pos = promptPos(p)
                                if pos then
                                    local d = (pos - r.Position).Magnitude
                                    if not bd or d < bd then bd, bpos = d, pos end
                                end
                            end
                        end
                        if bpos then tpTo(bpos) else notify("Roubo", "Nenhum prompt de roubo achado.", 3, "err") end
                    end)

                    UI.Section(page, "AUTOMATICO")
                    local autoBuy, autoSteal = false, false
                    UI.Toggle(page, "Auto comprar (prompts de compra no alcance)", false, function(v) autoBuy = v end)
                    UI.Toggle(page, "Auto roubar (prompts de roubo no alcance)", false, function(v) autoSteal = v end)
                    task.spawn(function()
                        local cache, last = {}, 0
                        while alive do
                            if (autoBuy or autoSteal) and fireproximityprompt then
                                if os.clock() - last > 3 then
                                    last = os.clock()
                                    cache = scanPrompts()
                                end
                                local r = getRoot()
                                if r then
                                    for _, p in ipairs(cache) do
                                        if p.Parent and p.Enabled and ((autoBuy and promptHas(p, BUY)) or (autoSteal and promptHas(p, STEAL))) then
                                            local pos = promptPos(p)
                                            if pos and (pos - r.Position).Magnitude <= p.MaxActivationDistance then
                                                pcall(function() p.HoldDuration = 0 end)
                                                pcall(fireproximityprompt, p)
                                            end
                                        end
                                    end
                                end
                            end
                            task.wait(0.4)
                        end
                    end)

                    UI.Section(page, "MOVIMENTO / DEFESA")
                    UI.Button(page, "🏃  Speed 40 + Infinite Jump + anti void", function()
                        preset({speed = true, infjump = true, antivoid = true}, {speedv = 40})
                    end)
                    UI.Button(page, "🛡  Anti fling + anti void (contra empurrao)", function()
                        preset({antifling = true, antivoid = true})
                    end)
                    UI.Button(page, "👁  ESP de jogadores + alerta (80 studs)", function()
                        preset({esp_name = true, esp_box = true, enemyalert = true}, {alertdist = 80})
                    end)
                    UI.Button(page, "💤  AFK seguro (anti AFK + rejoin + anti void)", function()
                        preset({antiafk = true, autorejoin = true, antivoid = true})
                    end)
                end,
                groups = {
                    {"Brainrots", {"brainrot"}}, {"Dinheiro", {"cash", "money"}}, {"Bases", {"base", "plot"}},
                    {"Esteira", {"conveyor", "belt"}}, {"Raros", {"secret", "mythic", "legendary", "cosmic", "divine"}},
                }})},
        {Name = "Dead Rails", Desc = "ESP de bonds, baus, armas, trem, noite e AFK",
            Ids = {116495829188952}, Keys = {"dead rails"},
            Build = builder({info = "Coleta de itens e ESP de objetos.", farm = true,
                custom = function(page)
                    UI.Section(page, "SOBREVIVENCIA")
                    UI.Button(page, "💡  Fullbright + sem neblina", function()
                        preset({fullbright = true, nofog = true})
                    end)
                    UI.Button(page, "🤏  Prompts instantaneos + automaticos", function()
                        preset({instaprompt = true, autoprompt = true})
                    end)
                    UI.Button(page, "🏃  Speed 30 + Infinite Jump", function()
                        preset({speed = true, infjump = true}, {speedv = 30})
                    end)
                end,
                groups = {
                    {"Bonds", {"bond"}}, {"Baus / Cofres", {"chest", "safe"}},
                    {"Armas", {"rifle", "revolver", "shotgun", "mauser", "sawed"}},
                    {"Municao / Ouro", {"ammo", "gold"}}, {"Trem", {"train", "locomotive"}},
                    {"Inimigos", {"zombie", "outlaw", "vampire", "werewolf"}},
                }})},
        {Name = "99 Nights in the Forest", Desc = "ESP de itens, criancas, fogueira, baus, noite e prompts",
            Ids = {126509999114328}, Keys = {"99 nights"},
            Build = builder({
                info = "Sobrevivencia: ESP de itens, criancas perdidas, fogueira e coleta automatica.", infoH = 30,
                farm = true,
                groups = {
                    {"Baus", {"chest"}}, {"Diamantes", {"diamond"}},
                    {"Sucata / Madeira", {"scrap", "log", "stick", "coal", "fuel"}},
                    {"Criancas perdidas", {"child", "kid", "lost"}},
                    {"Fogueira", {"campfire", "bonfire", "maincampfire"}},
                    {"Comida", {"carrot", "berry", "apple", "meat", "food"}},
                    {"Armas / Ferramentas", {"axe", "sword", "rifle", "bow", "spear"}},
                    {"Inimigos", {"wolf", "bear", "cultist", "deer"}},
                },
                custom = function(page)
                    UI.Section(page, "NOITE")
                    UI.Button(page, "💡  Fullbright (enxergar a noite)", function()
                        preset({fullbright = true, nofog = true})
                    end)
                    UI.Button(page, "🤏  Prompts instantaneos + automaticos", function()
                        preset({instaprompt = true, autoprompt = true})
                    end)
                    UI.Button(page, "🏃  Speed 30 (fugir de monstros)", function()
                        preset({speed = true}, {speedv = 30})
                    end)
                    UI.Button(page, "🔥  Ir ate a fogueira", function()
                        local p = nearestObj(function(d) return nameHas(d, {"campfire", "bonfire"}) end)
                        if p then tpTo(p.Position + Vector3.new(0, 2, 4)) else notify("Fogueira", "Nao encontrada.", 3, "err") end
                    end)
                    UI.Button(page, "🧒  Ir ate a crianca mais proxima", function()
                        local p = nearestObj(function(d) return nameHas(d, {"child", "kid"}) end)
                        if p then tpTo(p.Position) else notify("Crianca", "Nenhuma encontrada.", 3, "err") end
                    end)
                end,
            })},
        -- NOVOS NA v5 -------------------------------------------------------
        {Name = "Booga Booga", Desc = "ESP de arvores, pedras, ferro, ouro, cristais e auto coletar",
            Ids = {11729688377}, Keys = {"booga booga"},
            Build = builder({
                info = "Sobrevivencia: ESP de recursos e coleta. Nomes podem variar; ajuste pelo SCANNER se preciso.", infoH = 30,
                farm = true,
                groups = {
                    {"Arvores", {"tree"}}, {"Pedras", {"stone", "rock"}}, {"Ferro", {"iron"}},
                    {"Ouro", {"gold"}}, {"Cristais / Gemas", {"crystal", "emerald", "ruby", "diamond"}},
                    {"Arbustos / Frutas", {"bush", "berry", "fruit"}}, {"Itens no chao", {"raw", "coin", "log"}},
                    {"Baus", {"chest"}},
                },
                custom = function(page)
                    UI.Section(page, "SOBREVIVER")
                    UI.Button(page, "🥷  Modo Coleta (speed 28 + anti void + AFK)", function()
                        preset({speed = true, antivoid = true, antiafk = true}, {speedv = 28})
                    end)
                    UI.Button(page, "👁  ESP de jogadores + alerta (70 studs)", function()
                        preset({esp_name = true, esp_box = true, esp_health = true, enemyalert = true}, {alertdist = 70})
                    end)
                    UI.Button(page, "💡  Fullbright (noite)", function()
                        preset({fullbright = true, nofog = true})
                    end)
                end,
            })},
        {Name = "Bee Swarm Simulator", Desc = "ESP de tokens, flores, bolhas e auto coletar",
            Ids = {1537690962}, Keys = {"bee swarm"},
            Build = builder({
                info = "Coleta de tokens e itens do campo via scanner.", farm = true,
                groups = {
                    {"Tokens", {"token"}}, {"Flores", {"flower"}}, {"Bolhas", {"bubble"}},
                    {"Baus", {"chest"}}, {"Mobs", {"mob", "bug", "ladybug", "rhino"}},
                },
                custom = function(page)
                    UI.Section(page, "CAMPO")
                    UI.Button(page, "🐝  Modo Campo (speed 40 + AFK + coletar tokens)", function()
                        setKeywords({"token"})
                        preset({speed = true, antiafk = true, autocollect = true, obj_esp = true}, {speedv = 40})
                    end)
                end,
            })},
        {Name = "Build A Boat", Desc = "Baus de tesouro, ouro, voo, anti void e atalhos",
            Ids = {537413528}, Keys = {"build a boat"},
            Build = builder({
                info = "Atalhos de movimento e ESP de tesouros. Auto farm exige remotes especificos.", infoH = 30,
                groups = {{"Bau de tesouro", {"chest", "treasure"}}, {"Ouro", {"gold"}}},
                custom = function(page)
                    UI.Section(page, "TRAVESSIA")
                    UI.Button(page, "🌊  Modo Travessia (fly + noclip)", function()
                        preset({fly = true, noclip = true}, {flyv = 90})
                    end)
                    UI.Button(page, "🛡  Anti void + anti AFK", function()
                        preset({antivoid = true, antiafk = true})
                    end)
                    UI.Toggle(page, "Gravidade baixa (50)", false, function(on)
                        workspace.Gravity = on and 50 or OrigGravity
                    end)
                end,
            })},
        {Name = "Flee the Facility", Desc = "ESP da Fera, computadores, saidas, alertas e sobrevivencia",
            Ids = {893973440}, Keys = {"flee the facility"},
            Build = builder({
                info = "Ache a Fera (quem esta com o Hammer), hackeie computadores e fuja. Nomes de objetos podem variar.", infoH = 30,
                groups = {
                    {"Computadores", {"computer"}}, {"Saidas", {"exit"}},
                    {"Cabines de congelamento", {"freezepod", "freeze pod", "pod"}},
                },
                custom = function(page)
                    local function findBeast()
                        for _, pl in ipairs(Players:GetPlayers()) do
                            local c = pl.Character
                            local bp = pl:FindFirstChild("Backpack")
                            if pl ~= LocalPlayer and ((c and c:FindFirstChild("Hammer")) or (bp and bp:FindFirstChild("Hammer"))) then
                                return pl
                            end
                        end
                    end
                    UI.Section(page, "FERA")
                    UI.Toggle(page, "ESP por role (Fera vermelha / sobreviventes verdes)", false, function(on)
                        if on then
                            ESP.ColorFn = function(pl)
                                if findBeast() == pl then return Color3.fromRGB(255, 60, 60) end
                                return Color3.fromRGB(90, 230, 120)
                            end
                            preset({esp_chams = true, esp_name = true})
                        else
                            ESP.ColorFn = nil
                        end
                    end)
                    local warn, announce, lastB, lastWarn = false, false, nil, 0
                    UI.Toggle(page, "Alerta: Fera a menos de 40 studs", false, function(on) warn = on end)
                    UI.Toggle(page, "Avisar quem e a Fera", false, function(on) announce = on end)
                    task.spawn(function()
                        while alive do
                            local b = findBeast()
                            if announce and b and b ~= lastB then
                                notify("Fera", b.DisplayName .. " (@" .. b.Name .. ")", 5, "err")
                            end
                            lastB = b
                            local r = getRoot()
                            local br = b and b.Character and b.Character:FindFirstChild("HumanoidRootPart")
                            if warn and r and br and os.clock() - lastWarn > 2 and (br.Position - r.Position).Magnitude < 40 then
                                lastWarn = os.clock()
                                notify("PERIGO", "A Fera esta perto!", 2, "err")
                            end
                            task.wait(1)
                        end
                    end)
                    UI.Button(page, "👁  Observar a Fera", function()
                        local b = findBeast()
                        local h = b and b.Character and b.Character:FindFirstChildOfClass("Humanoid")
                        if h then workspace.CurrentCamera.CameraSubject = h else notify("Fera", "Fera nao encontrada.", 3, "err") end
                    end)
                    UI.Section(page, "SOBREVIVER")
                    UI.Button(page, "🏃  Speed 24 + anti void", function()
                        preset({speed = true, antivoid = true}, {speedv = 24})
                    end)
                    UI.Button(page, "🥷  Modo Fugitivo (speed 26 + infjump + anti fling)", function()
                        preset({speed = true, infjump = true, antifling = true, antivoid = true}, {speedv = 26})
                    end)
                end,
            })},
        {Name = "Combat Warriors", Desc = "ESP, aimbot legit, alerta de inimigo, armas e movimentacao",
            Ids = {4282985734}, Keys = {"combat warriors"},
            Build = builder({
                info = "Luta com armas brancas e distancia: ESP, alertas e presets. Anti-cheat ativo, prefira Legit.", infoH = 30,
                shooter = true,
                groups = {{"Armas no chao", {"sword", "pistol", "rifle", "shotgun", "bow", "axe"}}, {"Baus", {"chest", "crate"}}},
                custom = function(page)
                    UI.Section(page, "DUELO")
                    UI.Button(page, "👁  ESP de jogadores + alerta (50 studs)", function()
                        preset({esp_name = true, esp_health = true, esp_box = true, enemyalert = true}, {alertdist = 50})
                    end)
                    UI.Button(page, "⚡  Speed 28 + Infinite Jump", function()
                        preset({speed = true, infjump = true}, {speedv = 28})
                    end)
                    UI.Button(page, "🛡  Anti fling + anti void", function()
                        preset({antifling = true, antivoid = true})
                    end)
                end,
            })},
        {Name = "Futebol de Rua", Desc = "Bola, gols, seguir bola, auto chute, mira no gol, ESP e alertas",
            Ids = {4949420752}, Keys = {"futebol de rua", "street soccer", "futebol"},
            Build = builder({
                info = "Futebol de rua: acha a bola e os gols pelo nome dos objetos. Se o jogo usar outros nomes, ajuste pelo SCANNER na aba MUNDO.", infoH = 40,
                explore = true,
                groups = {{"Bola", {"ball", "bola"}}, {"Gols", {"goal", "trave"}}},
                custom = soccerCustom,
            })},
        {Name = "Hospital de Animais", Desc = "Auto atender, ESP de animais e estacoes, dinheiro e AFK farm",
            Ids = {}, Keys = {"hospital de animais", "animal hospital", "pet hospital", "veterinar", "vet clinic"},
            Build = builder({
                info = "Modulo generico para jogos de hospital/clinica de animais. Acha animais e estacoes pelo nome dos objetos; ajuste pelo SCANNER na aba MUNDO se algo nao aparecer.", infoH = 40,
                farm = true,
                groups = {
                    {"Animais / Pacientes", {"patient", "paciente", "animal", "pet", "dog", "cat", "puppy", "kitten", "bunny"}},
                    {"Dinheiro / Gorjetas", {"cash", "money", "coin", "tip", "gorjeta"}},
                    {"Estacoes de tratamento", {"bed", "cama", "surgery", "cirurgia", "xray", "x-ray", "medicine", "remedio", "vaccine", "vacina", "bath", "banho", "feed", "comida"}},
                    {"Recepcao / Caixa", {"register", "reception", "recepcao", "desk", "counter"}},
                    {"Baus / Presentes", {"chest", "gift", "crate"}},
                },
                custom = animalCustom,
            })},
        {Name = "Futebol Proibido", Desc = "Bola, gols, seguir bola, auto chute, mira no gol, ESP e alertas",
            Ids = {}, Keys = {"futebol proibido", "forbidden football", "forbidden soccer", "proibido"},
            Build = builder({
                info = "Mesmo kit do Futebol de Rua: acha a bola e os gols pelo nome dos objetos. Se o jogo usar outros nomes, ajuste pelo SCANNER na aba MUNDO.", infoH = 40,
                explore = true,
                groups = {{"Bola", {"ball", "bola"}}, {"Gols", {"goal", "trave"}}},
                custom = soccerCustom,
            })},
        {Name = "Universal", Desc = "Funciona em qualquer jogo",
            Ids = {}, Keys = {},
            Build = builder({
                info = "Tudo do hub funciona aqui: veja as abas PRINCIPAL, HALLOWEEN, VISUAL, COMBATE, TROLL e MUNDO.",
                custom = function(page) X.hwEventBlock(page) end,
                shooter = true, explore = true,
            })},
    }

    local placeName = (game.Name or ""):lower()
    pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        if info and info.Name then
            placeName = (info.Name .. " " .. placeName):lower()
        end
    end)

    local function isCurrentGame(g)
        if table.find(g.Ids, game.PlaceId) or table.find(g.Ids, game.GameId) then
            return true
        end
        for _, k in ipairs(g.Keys) do
            if placeName:find(k, 1, true) then
                return true
            end
        end
        return false
    end

    local cardList = {}

    UI.Section(Scripts, "JOGOS")
    local SearchBox = UI.TextInput(Scripts, "🔎 Buscar jogo...", "", nil)
    UI.Label(Scripts, #Games .. " modulos • o jogo atual aparece como DETECTADO.", 16)

    for i, g in ipairs(Games) do
        local pageName = "Game_" .. g.Name
        local gamePage = createPage(pageName)

        UI.Button(gamePage, "←  Voltar", function()
            showPage("Scripts", "Scripts")
        end)
        UI.Section(gamePage, string.upper(g.Name))
        g.Build(gamePage)

        local isHere = isCurrentGame(g) and g.Name ~= "Universal"
        if isHere and not detected then
            detected = g
        end

        local card = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 56),
            BackgroundColor3 = C.item,
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
            LayoutOrder = isHere and 1 or (i + 10),
            ClipsDescendants = true,
        }, Scripts)
        corner(card, 10)
        enterScale(card)
        local cardStroke = stroke(card, C.line, 1, 0.6)
        local cardScale = new("UIScale", {Scale = 1}, card)

        new("TextLabel", {
            Position = UDim2.new(0, 14, 0, 9),
            Size = UDim2.new(1, -120, 0, 18),
            BackgroundTransparency = 1,
            Text = g.Name,
            TextColor3 = C.white,
            TextSize = 13,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, card)

        new("TextLabel", {
            Position = UDim2.new(0, 14, 0, 28),
            Size = UDim2.new(1, -120, 0, 16),
            BackgroundTransparency = 1,
            Text = g.Desc,
            TextColor3 = C.sub,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, card)

        if isHere then
            local badge = new("TextLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -12, 0.5, 0),
                Size = UDim2.new(0, 78, 0, 20),
                BackgroundColor3 = C.white,
                Text = "DETECTADO",
                TextColor3 = C.bg,
                TextSize = 9,
                Font = Enum.Font.GothamBold,
                BorderSizePixel = 0,
            }, card)
            corner(badge, 6)
            task.spawn(function()
                while alive do
                    tween(badge, 0.8, {BackgroundTransparency = 0.35}, Enum.EasingStyle.Sine)
                    task.wait(0.8)
                    tween(badge, 0.8, {BackgroundTransparency = 0}, Enum.EasingStyle.Sine)
                    task.wait(0.8)
                end
            end)
        else
            new("TextLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -14, 0.5, 0),
                Size = UDim2.new(0, 20, 0, 20),
                BackgroundTransparency = 1,
                Text = "›",
                TextColor3 = C.sub,
                TextSize = 20,
                Font = Enum.Font.GothamBold,
            }, card)
        end

        card.MouseEnter:Connect(function()
            tween(card, 0.15, {BackgroundColor3 = C.hover})
            tween(cardStroke, 0.15, {Transparency = 0})
            tween(cardScale, 0.2, {Scale = 1.015}, Enum.EasingStyle.Back)
        end)
        card.MouseLeave:Connect(function()
            tween(card, 0.15, {BackgroundColor3 = C.item})
            tween(cardStroke, 0.15, {Transparency = 0.6})
            tween(cardScale, 0.15, {Scale = 1})
        end)
        card.MouseButton1Click:Connect(function()
            ripple(card)
            task.wait(0.12)
            showPage(pageName, "Scripts")
        end)

        table.insert(cardList, {card = card, text = (g.Name .. " " .. g.Desc):lower()})
    end

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = SearchBox.Text:lower()
        for _, c in ipairs(cardList) do
            c.card.Visible = q == "" or c.text:find(q, 1, true) ~= nil
        end
    end)

    if detected then
        GameLabel.Text = "Jogo detectado: " .. detected.Name
    else
        GameLabel.Text = "Jogo nao listado • use Universal"
    end
end

--==================================================
-- ABA: CONFIG
--==================================================
local MenuKey = Enum.KeyCode.RightShift
local MenuKeys = {
    RightShift = Enum.KeyCode.RightShift, RightControl = Enum.KeyCode.RightControl,
    Insert = Enum.KeyCode.Insert, Delete = Enum.KeyCode.Delete, K = Enum.KeyCode.K,
}

local unload  -- definida mais abaixo

do
    local Themes = {
        {"Abobora",      Color3.fromRGB(255, 122, 24)},
        {"Roxo bruxa",   Color3.fromRGB(170, 96, 255)},
        {"Verde slime",  Color3.fromRGB(110, 235, 70)},
        {"Sangue",       Color3.fromRGB(226, 50, 56)},
        {"Fantasma",     Color3.fromRGB(235, 235, 245)},
        {"Cobre",        Color3.fromRGB(205, 120, 70)},
        {"Meia-noite",   Color3.fromRGB(90, 120, 255)},
        {"Doce rosa",    Color3.fromRGB(255, 110, 190)},
        {"Ouro",         Color3.fromRGB(240, 200, 90)},
        {"Cinza",        Color3.fromRGB(185, 185, 190)},
    }
    local ThemeNames = {}
    for _, t in ipairs(Themes) do table.insert(ThemeNames, t[1]) end

    UI.Section(Config, "APARENCIA")
    UI.Cycle(Config, "Tema", ThemeNames, "Abobora", function(name)
        for _, t in ipairs(Themes) do
            if t[1] == name then
                State.Rainbow = false
                if Toggles.rainbow then Toggles.rainbow.Set(false, true) end
                setAccent(t[2])
                notify("Tema", name .. " aplicado.", 2, "ok")
            end
        end
    end)
    UI.Toggle(Config, "Tema Arco-iris", false, function(on) State.Rainbow = on end, "rainbow")
    UI.Toggle(Config, "Particulas de fundo", true, function(on)
        State.Particles = on
        ParticleLayer.Visible = on
    end)
    UI.Toggle(Config, "Efeito glitch no titulo", true, function(on) State.TitleGlitch = on end)
    UI.Slider(Config, "Tamanho da interface (%)", 60, 130, 100, function(v)
        UIBase = v / 100
        MainScale.Scale = UIBase
    end)
    UI.Slider(Config, "Transparencia da interface (%)", 0, 40, 0, function(v)
        Main.BackgroundTransparency = v / 100
    end)

    UI.Section(Config, "ATALHO")
    local keyNames = {}
    for k in pairs(MenuKeys) do table.insert(keyNames, k) end
    table.sort(keyNames)
    UI.Cycle(Config, "Tecla do menu", keyNames, "RightShift", function(name)
        MenuKey = MenuKeys[name]
        notify("Atalho", "Tecla do menu: " .. name, 2, "ok")
    end)

    UI.Section(Config, "PERFIL")
    local CFG_FILE = "LostHub_HW.json"
    UI.Button(Config, "💾  Salvar configuracao", function()
        if not writefile then
            notify("Config", "Seu executor nao suporta writefile.", 4, "err")
            return
        end
        local data = {t = {}, s = {}}
        for k, v in pairs(Toggles) do data.t[k] = v.Get() end
        for k, v in pairs(Sliders) do data.s[k] = v.Get() end
        local ok = pcall(function() writefile(CFG_FILE, HttpService:JSONEncode(data)) end)
        notify("Config", ok and "Configuracao salva." or "Falha ao salvar.", 3, ok and "ok" or "err")
    end)
    UI.Button(Config, "📂  Carregar configuracao", function()
        if not (readfile and isfile) then
            notify("Config", "Seu executor nao suporta readfile.", 4, "err")
            return
        end
        if not isfile(CFG_FILE) then
            notify("Config", "Nenhuma configuracao salva.", 3, "err")
            return
        end
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CFG_FILE)) end)
        if not ok or type(data) ~= "table" then
            notify("Config", "Arquivo invalido.", 3, "err")
            return
        end
        for k, v in pairs(data.s or {}) do
            if Sliders[k] then Sliders[k].Set(v) end
        end
        for k, v in pairs(data.t or {}) do
            if Toggles[k] and Toggles[k].Get() ~= v then Toggles[k].Set(v) end
        end
        notify("Config", "Configuracao carregada.", 3, "ok")
    end)
    UI.Button(Config, "🔑  Esquecer key salva", function()
        if isfile and delfile and isfile("LostHub_key.txt") then
            pcall(delfile, "LostHub_key.txt")
            notify("Key", "Key salva removida.", 3, "ok")
        else
            notify("Key", "Nenhuma key salva.", 3, "err")
        end
    end)

    UI.Button(Config, "🎯  Centralizar menu e bolinha", function()
        Main.Position = UDim2.new(0.5, 0, 0.5, 0)
        local mini = Gui:FindFirstChild("Mini")
        if mini then mini.Position = UDim2.new(0.5, 0, 0.5, 0) end
        notify("Menu", "Menu centralizado.", 2, "ok")
    end)
    local hotkeys = false
    UI.Toggle(Config, "Atalhos de teclado: F = Fly, N = Noclip, V = Speed", false, function(on) hotkeys = on end)
    bind(UserInputService.InputBegan, function(input, processed)
        if processed or not hotkeys then return end
        local map = {[Enum.KeyCode.F] = "fly", [Enum.KeyCode.N] = "noclip", [Enum.KeyCode.V] = "speed"}
        local k = map[input.KeyCode]
        if k and Toggles[k] then Toggles[k].Set(not Toggles[k].Get()) end
    end)

    UI.Section(Config, "COMPATIBILIDADE DO EXECUTOR")
    local function yn(f) return f and "✓" or "✕" end
    UI.Label(Config, ("firetouchinterest %s • fireproximityprompt %s • mouse1click %s\nsetclipboard %s • writefile %s • readfile %s • gethui %s • setfpscap %s"):format(
        yn(firetouchinterest), yn(fireproximityprompt), yn(mouse1click),
        yn(setclipboard), yn(writefile), yn(readfile), yn(gethui), yn(setfpscap)), 30)

    UI.Section(Config, "EDICAO HALLOWEEN")
    UI.Label(Config, "• Tema laranja e roxo, abobora na tela de carregamento e portal da key\n• Aba HALLOWEEN: noite assombrada, chuva de emojis, relampagos, corpo abobora e fantasma\n• ESP de aboboras e doces + playlists de terror\n• Tudo da v5.1 incluso (30 jogos, otimizacao, musica)", 70)

    UI.Section(Config, "SOBRE")
    UI.Label(Config, "Lost Hub Halloween 🎃 • " .. #Games .. " modulos de jogos • key: Lost", 16)
    UI.Label(Config, "Modulos especificos usam nomes de objetos do jogo. Se o jogo atualizar, algo pode parar de funcionar.", 40)
    UI.Button(Config, "🗑  Descarregar Lost Hub (restaura tudo)", function() unload() end)
end

--==================================================
-- LOOPS DAS FUNCOES
--==================================================
local wasSpeed, wasJump = false, false
bind(RunService.Heartbeat, function(dt)
    local hum = getHum()
    if not hum then return end

    if State.SpeedOn then
        if State.SpeedMode == "CFrame" then
            if wasSpeed then
                hum.WalkSpeed = 16
                wasSpeed = false
            end
            local root = getRoot()
            if root and hum.MoveDirection.Magnitude > 0 then
                root.CFrame = root.CFrame + hum.MoveDirection * (State.Speed - 16) * dt
            end
        else
            hum.WalkSpeed = State.Speed
            wasSpeed = true
        end
    elseif wasSpeed then
        hum.WalkSpeed = 16
        wasSpeed = false
    end

    if State.JumpOn then
        hum.UseJumpPower = true
        hum.JumpPower = State.Jump
        wasJump = true
    elseif wasJump then
        hum.JumpPower = 50
        wasJump = false
    end

    if State.Bhop and hum.MoveDirection.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

bind(UserInputService.JumpRequest, function()
    if State.InfJump then
        local hum = getHum()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

bind(RunService.Stepped, function()
    if not State.Noclip then return end
    local char = getChar()
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Ctrl + clique teleporta
bind(UserInputService.InputBegan, function(input, processed)
    if processed or not State.TPClick then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1
        and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        local hit = Mouse.Hit
        if hit then
            tpTo(hit.Position)
        end
    end
end)

-- FLY
local FlyVelocity, FlyGyro
local function clearFly()
    if FlyVelocity then FlyVelocity:Destroy() FlyVelocity = nil end
    if FlyGyro then FlyGyro:Destroy() FlyGyro = nil end
end

table.insert(Ticks, function()
    if not State.Fly then
        clearFly()
        return
    end
    local root = getRoot()
    if not root then return end

    if not FlyVelocity or FlyVelocity.Parent ~= root then
        clearFly()
        FlyVelocity = new("BodyVelocity", {
            MaxForce = Vector3.new(math.huge, math.huge, math.huge),
            Velocity = Vector3.zero,
        }, root)
        FlyGyro = new("BodyGyro", {
            MaxTorque = Vector3.new(math.huge, math.huge, math.huge),
            P = 90000,
        }, root)
    end

    local camera = workspace.CurrentCamera
    local direction = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then direction -= Vector3.new(0, 1, 0) end

    if direction.Magnitude > 0 then
        direction = direction.Unit * State.FlySpeed
    end
    FlyVelocity.Velocity = direction
    FlyGyro.CFrame = camera.CFrame
end)

-- camera FOV + fullbright + sem neblina
table.insert(Ticks, function()
    if State.CamFov then
        pcall(function() workspace.CurrentCamera.FieldOfView = State.CamFovVal end)
    end
    if State.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
    end
    if State.NoFog then
        Lighting.FogEnd = 1e6
    end
end)

-- zoom segurando C
table.insert(Ticks, function()
    if not X.zoomC then return end
    local cam = workspace.CurrentCamera
    if UserInputService:IsKeyDown(Enum.KeyCode.C) and not UserInputService:GetFocusedTextBox() then
        cam.FieldOfView = 25
        X.zoomActive = true
    elseif X.zoomActive then
        X.zoomActive = false
        cam.FieldOfView = State.CamFov and State.CamFovVal or 70
    end
end)

-- ANTI AFK
bind(LocalPlayer.Idled, function()
    if not State.AntiAFK then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- animacoes continuas + FPS/ping + arco-iris
local t0 = os.clock()
local fpsAcc, fpsFrames = 0, 0
local lastFrame = os.clock()
bind(RunService.RenderStepped, function()
    local now = os.clock()
    local dt = now - lastFrame
    lastFrame = now
    local t = now - t0

    StrokeGrad.Rotation = (t * 60) % 360
    TitleGrad.Offset = Vector2.new(math.sin(t * 1.5) * 0.6, 0)

    if State.Rainbow then
        setAccent(Color3.fromHSV((t * 0.08) % 1, 0.65, 1))
    end

    for _, fn in ipairs(Ticks) do
        pcall(fn, dt, now)
    end

    fpsAcc = fpsAcc + dt
    fpsFrames = fpsFrames + 1
    if fpsAcc >= 0.5 then
        local ping = 0
        pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        FPSLabel.Text = math.floor(fpsFrames / fpsAcc + 0.5) .. " FPS  •  " .. ping .. " ms  •  " .. #Players:GetPlayers() .. " jogadores"
        fpsAcc, fpsFrames = 0, 0
    end
end)

-- glitch do titulo
task.spawn(function()
    while alive do
        task.wait(3 + math.random() * 3)
        if State.TitleGlitch and Main.Visible then
            for _ = 1, 5 do
                Title.Position = UDim2.new(0, 20 + math.random(-3, 3), 0, 10 + math.random(-2, 2))
                Title.TextColor3 = (math.random() > 0.5) and C.accent or C.white
                task.wait(0.04)
            end
            Title.Position = UDim2.new(0, 20, 0, 10)
            Title.TextColor3 = C.white
        end
    end
end)

--==================================================
-- ARRASTAR
--==================================================
local dragging, dragStart, startPos = false, nil, nil

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

bind(UserInputService.InputChanged, function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        local vp = workspace.CurrentCamera.ViewportSize
        local mx, my = math.max(vp.X / 2 - 90, 0), math.max(vp.Y / 2 - 40, 0)
        Main.Position = UDim2.new(
            0.5, math.clamp(startPos.X.Offset + delta.X, -mx, mx),
            0.5, math.clamp(startPos.Y.Offset + delta.Y, -my, my)
        )
    end
end)

bind(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

--==================================================
-- MINIMIZAR / MOSTRAR / FECHAR
--==================================================
local Mini = new("TextButton", {
    Name = "Mini",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = Main.Position,
    Size = UDim2.new(0, 52, 0, 52),
    BackgroundColor3 = C.panel,
    Text = "L",
    TextColor3 = C.white,
    TextSize = 22,
    Font = Enum.Font.GothamBlack,
    BorderSizePixel = 0,
    Visible = false,
}, Gui)
corner(Mini, 26)
local MiniStroke = stroke(Mini, C.accent, 2, 0.2)
onAccent(function(col) MiniStroke.Color = col end)
local MiniScale = new("UIScale", {Scale = 1}, Mini)

task.spawn(function()
    while alive do
        if Mini.Visible then
            tween(MiniStroke, 0.9, {Thickness = 4, Transparency = 0.6}, Enum.EasingStyle.Sine)
            task.wait(0.9)
            tween(MiniStroke, 0.9, {Thickness = 2, Transparency = 0.2}, Enum.EasingStyle.Sine)
            task.wait(0.9)
        else
            task.wait(0.5)
        end
    end
end)

local shown = true
local function setVisible(v)
    if v == shown then return end
    shown = v

    if v then
        Main.Position = UDim2.new(0.5, 0, 0.5, 0)
        Mini.Visible = false
        Main.Visible = true
        MainScale.Scale = 0.8
        tween(MainScale, 0.4, {Scale = UIBase}, Enum.EasingStyle.Back)
    else
        local vp = workspace.CurrentCamera.ViewportSize
        Mini.Position = UDim2.new(
            0.5, math.clamp(Main.Position.X.Offset, -(vp.X / 2 - 30), vp.X / 2 - 30),
            0.5, math.clamp(Main.Position.Y.Offset, -(vp.Y / 2 - 30), vp.Y / 2 - 30)
        )
        tween(MainScale, 0.2, {Scale = 0.8})
        task.delay(0.2, function()
            if not shown then Main.Visible = false end
        end)
        Mini.Visible = true
        MiniScale.Scale = 0
        tween(MiniScale, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
    end
end

Minimize.MouseButton1Click:Connect(function()
    setVisible(false)
end)

local miniDragging, miniMoved = false, false
local miniStart, miniStartPos

Mini.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        miniDragging = true
        miniMoved = false
        miniStart = input.Position
        miniStartPos = Mini.Position
        tween(MiniScale, 0.1, {Scale = 0.92})
    end
end)

bind(UserInputService.InputChanged, function(input)
    if miniDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - miniStart
        if delta.Magnitude > 4 then miniMoved = true end
        if miniMoved then
            local vp = workspace.CurrentCamera.ViewportSize
            local mx, my = math.max(vp.X / 2 - 30, 0), math.max(vp.Y / 2 - 30, 0)
            Mini.Position = UDim2.new(
                0.5, math.clamp(miniStartPos.X.Offset + delta.X, -mx, mx),
                0.5, math.clamp(miniStartPos.Y.Offset + delta.Y, -my, my)
            )
        end
    end
end)

bind(UserInputService.InputEnded, function(input)
    if miniDragging and (input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch) then
        miniDragging = false
        tween(MiniScale, 0.15, {Scale = 1}, Enum.EasingStyle.Back)
    end
end)

Mini.MouseButton1Click:Connect(function()
    if miniMoved then
        miniMoved = false
        return
    end
    setVisible(true)
end)

bind(UserInputService.InputBegan, function(input, processed)
    if processed then return end
    if input.KeyCode == MenuKey then
        setVisible(not shown)
    end
end)

unload = function()
    alive = false
    for k, v in pairs(State) do
        if type(v) == "boolean" then
            State[k] = false
        end
    end
    Aim.On = false
    ESP.Chams, ESP.Box, ESP.Names, ESP.Health, ESP.Tracers = false, false, false, false, false
    ESP.ColorFn = nil
    Obj.On = false
    TS.Stick = false

    pcall(function() X.musicStop() X.MusicSound:Destroy() end)
    pcall(X.optRestoreAll)
    pcall(X.hwOff)
    pcall(function() X.HWGui:Destroy() end)
    pcall(clearFly)
    pcall(restoreHitbox)
    pcall(clearObj)
    pcall(restoreNeon)
    pcall(setXray, false)
    for pl in pairs(ESPData) do
        clearESP(pl)
    end
    pcall(function()
        for k, v in pairs(LightSave) do Lighting[k] = v end
        workspace.Gravity = OrigGravity
        workspace.CurrentCamera.FieldOfView = 70
        LocalPlayer.CameraMaxZoomDistance = 128
        LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
    end)

    local hum = getHum()
    if hum then
        pcall(function()
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            workspace.CurrentCamera.CameraSubject = hum
        end)
    end

    for _, c in ipairs(Conns) do
        pcall(function() c:Disconnect() end)
    end

    tween(MainScale, 0.3, {Scale = 0}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    task.wait(0.35)
    pcall(function() Gui:Destroy() end)
    pcall(function() FOVGui:Destroy() end)
    pcall(function() ToastGui:Destroy() end)
    pcall(function() ESPGui:Destroy() end)
end

Close.MouseButton1Click:Connect(function() unload() end)

--==================================================
-- INICIAR
--==================================================
showPage("Halloween", "Halloween")

task.delay(0.8, function()
    if detected then
        notify("Lost Hub 🎃", "Jogo detectado: " .. detected.Name .. ". Veja a aba SCRIPTS.", 4, "ok")
    else
        notify("Lost Hub 🎃", "Feliz Halloween! Veja a aba HALLOWEEN.", 3, "ok")
    end
end)

print("================================")
print("     LOST HUB HALLOWEEN CARREGADO")
print("================================")
