-- ui/menu.lua
-- Минималистичное UI в стиле Nightrunner

local Menu = {}

local screenWidth = 1920
local screenHeight = 1080

-- Цвета (RGBA)
local colors = {
    bg = {0.05, 0.05, 0.08, 0.95},
    panel = {0.1, 0.1, 0.15, 0.9},
    text = {1, 1, 1, 1},
    textDim = {0.6, 0.6, 0.6, 1},
    accent = {0.95, 0.2, 0.2, 1}, -- красный акцент
    green = {0.2, 0.8, 0.2, 1},
    button = {0.15, 0.15, 0.2, 1},
    buttonHover = {0.25, 0.25, 0.35, 1}
}

-- Состояние меню
local menuState = {
    visible = false,
    hoveredButton = nil,
    sessionData = nil
}

-- Кнопки меню
local buttons = {}

local function createButton(id, text, x, y, width, height, onClick)
    return {
        id = id,
        text = text,
        x = x,
        y = y,
        width = width,
        height = height,
        onClick = onClick,
        hovered = false
    }
end

-- Инициализация меню
function Menu.init(sessionData)
    menuState.sessionData = sessionData
    menuState.visible = true
    
    local centerX = screenWidth / 2
    local startY = 300
    local buttonWidth = 400
    local buttonHeight = 60
    local spacing = 20
    
    -- Заголовок
    buttons.title = {
        id = "title",
        text = "TOUGE BATTLES",
        x = centerX - 200,
        y = 200,
        width = 400,
        height = 50,
        isTitle = true
    }
    
    -- Кнопка случайной гонки
    buttons.randomRace = createButton(
        "randomRace",
        "СЛУЧАЙНАЯ ГОНКА",
        centerX - buttonWidth/2,
        startY,
        buttonWidth,
        buttonHeight,
        function() Menu.startRandomRace() end
    )
    
    -- Кнопка вызова босса
    buttons.bossChallenge = createButton(
        "bossChallenge", 
        "ВЫЗОВ БОССА",
        centerX - buttonWidth/2,
        startY + buttonHeight + spacing,
        buttonWidth,
        buttonHeight,
        function() Menu.challengeBoss() end
    )
    
    -- Статистика
    buttons.stats = {
        id = "stats",
        isStats = true,
        x = centerX - 200,
        y = startY + (buttonHeight + spacing) * 2 + 30,
        width = 400,
        height = 100
    }
    
    -- Кнопка выхода
    buttons.exit = createButton(
        "exit",
        "ВЫХОД",
        centerX - buttonWidth/2,
        screenHeight - 150,
        buttonWidth,
        buttonHeight,
        function() Menu.hide() end
    )
end

-- Отрисовка меню
function Menu.render()
    if not menuState.visible then return end
    
    -- Фон
    ac.renderRect(0, 0, screenWidth, screenHeight, colors.bg)
    
    -- Заголовок
    local title = buttons.title
    ac.renderText(title.text, title.x, title.y, 32, "bold", colors.accent)
    
    -- Кнопки
    for _, btn in pairs(buttons) do
        if not btn.isTitle and not btn.isStats then
            local color = btn.hovered and colors.buttonHover or colors.button
            ac.renderRect(btn.x, btn.y, btn.width, btn.height, color)
            ac.renderText(btn.text, btn.x + btn.width/2, btn.y + btn.height/2 - 5, 20, "normal", colors.text, "center")
        end
    end
    
    -- Статистика
    if menuState.sessionData then
        local player = menuState.sessionData.player
        local statsPanel = buttons.stats
        
        -- Панель статистики
        ac.renderRect(statsPanel.x - 10, statsPanel.y - 10, statsPanel.width + 20, statsPanel.height + 20, colors.panel)
        
        local stats = require("save.save")
        local wr = stats.getWR(player)
        
        ac.renderText("СТАТИСТИКА", statsPanel.x, statsPanel.y, 18, "bold", colors.textDim)
        ac.renderText(string.format("Имя: %s", player.name), statsPanel.x, statsPanel.y + 25, 16, "normal", colors.text)
        ac.renderText(string.format("Репутация: %d", player.reputation), statsPanel.x, statsPanel.y + 45, 16, "normal", colors.text)
        ac.renderText(string.format("Деньги: $%d", player.money), statsPanel.x, statsPanel.y + 65, 16, "normal", colors.green)
        ac.renderText(string.format("Побед/Всего: %s", wr), statsPanel.x + statsPanel.width/2, statsPanel.y + 25, 16, "normal", colors.text)
        ac.renderText(string.format("Ранг: #%d", player.stats.blacklist_rank), statsPanel.x + statsPanel.width/2, statsPanel.y + 45, 16, "normal", colors.accent)
    end
    
    -- Доступные боссы
    if menuState.sessionData and #menuState.sessionData.unlockedBlacklist > 0 then
        local boss = menuState.sessionData.unlockedBlacklist[1]
        ac.renderText("ДОСТУПНЫЙ БОСС:", screenWidth - 400, 100, 20, "bold", colors.accent)
        ac.renderText(string.format("%s - %s (%s)", boss.name, boss.nickname or "", boss.car_id), screenWidth - 400, 130, 16, "normal", colors.text)
    end
end

-- Обработка мыши
function Menu.mouseMoved(x, y)
    if not menuState.visible then return end
    
    for _, btn in pairs(buttons) do
        if not btn.isTitle and not btn.isStats then
            btn.hovered = (x >= btn.x and x <= btn.x + btn.width and y >= btn.y and y <= btn.y + btn.height)
        end
    end
end

function Menu.mousePressed(x, y, button)
    if not menuState.visible or button ~= 1 then return end
    
    for _, btn in pairs(buttons) do
        if not btn.isTitle and not btn.isStats and btn.hovered then
            if btn.onClick then btn.onClick() end
            break
        end
    end
end

-- Действия кнопок
function Menu.startRandomRace()
    if not menuState.sessionData then return end
    
    local streetDrivers = menuState.sessionData.streetDrivers
    if #streetDrivers == 0 then
        print("Нет доступных уличных гонщиков!")
        return
    end
    
    -- Выбор случайного соперника
    local randomIdx = math.random(1, #streetDrivers)
    local rival = streetDrivers[randomIdx]
    
    print(string.format("=== СЛУЧАЙНАЯ ГОНКА ==="))
    print(string.format("Соперник: %s", rival.name))
    print(string.format("Авто: %s", rival.car_id))
    print(string.format("Навык: %d", rival.skill or 50))
    print(string.format("Награда: $%d | +%d репутации", rival.money_reward or 500, rival.reputation_reward or 1))
    
    -- Здесь будет запуск гонки
    -- RaceModule.start(rival, "street")
    
    menuState.visible = false
end

function Menu.challengeBoss()
    if not menuState.sessionData then return end
    
    local unlockedBosses = menuState.sessionData.unlockedBlacklist
    if #unlockedBosses == 0 then
        print("Нет доступных боссов!")
        return
    end
    
    -- Берем первого доступного (самый высокий ранг который открыт)
    local boss = unlockedBosses[1]
    
    print(string.format("=== ВЫЗОВ БОССА ==="))
    print(string.format("%s - \"%s\"", boss.name, boss.nickname or "Unknown"))
    print(string.format("Авто: %s", boss.car_id))
    print(string.format("Стиль: %s", boss.battle_style or "balanced"))
    print(string.format("Награда: $%d | +%d репутации", boss.money_reward or 1000, boss.reputation_reward or 5))
    
    -- Проверка разблокировки
    if not boss.unlocked then
        print("Этот босс еще не разблокирован!")
        return
    end
    
    -- Здесь будет запуск гонки
    -- RaceModule.start(boss, "blacklist")
    
    menuState.visible = false
end

function Menu.show(sessionData)
    Menu.init(sessionData)
end

function Menu.hide()
    menuState.visible = false
end

function Menu.isVisible()
    return menuState.visible
end

return Menu