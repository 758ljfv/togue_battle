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
    buttonHover = {0.25, 0.25, 0.35, 1},
    blue = {0.2, 0.6, 1, 1}
}

-- Состояние меню
local menuState = {
    visible = false,
    hoveredButton = nil,
    sessionData = nil,
    gameModule = nil,
    currentScreen = "main" -- main, shop, garage
}

-- Кнопки меню
local buttons = {}
local shopModule = nil
local garageModule = nil

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
function Menu.init(sessionData, gameModule)
    menuState.sessionData = sessionData
    menuState.gameModule = gameModule
    menuState.visible = true
    menuState.currentScreen = "main"
    
    local centerX = screenWidth / 2
    local startY = 280
    local buttonWidth = 400
    local buttonHeight = 55
    local spacing = 18
    
    -- Заголовок
    buttons.title = {
        id = "title",
        text = "TOUGE BATTLES",
        x = centerX - 200,
        y = 180,
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
    
    -- Кнопка автосалона
    buttons.shop = createButton(
        "shop",
        "АВТОСАЛОН",
        centerX - buttonWidth/2,
        startY + (buttonHeight + spacing) * 2,
        buttonWidth,
        buttonHeight,
        function() Menu.openShop() end
    )
    
    -- Кнопка гаража
    buttons.garage = createButton(
        "garage",
        "ГАРАЖ",
        centerX - buttonWidth/2,
        startY + (buttonHeight + spacing) * 3,
        buttonWidth,
        buttonHeight,
        function() Menu.openGarage() end
    )
    
    -- Статистика
    buttons.stats = {
        id = "stats",
        isStats = true,
        x = centerX - 200,
        y = startY + (buttonHeight + spacing) * 4 + 20,
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
    
    -- Загрузка модулей магазина и гаража
    shopModule = require("ui.shop")
    garageModule = require("ui.garage")
end

-- Отрисовка меню
function Menu.render()
    if not menuState.visible then return end
    
    -- Рендер в зависимости от текущего экрана
    if menuState.currentScreen == "main" then
        Menu.renderMain()
    elseif menuState.currentScreen == "shop" and shopModule then
        shopModule.render()
    elseif menuState.currentScreen == "garage" and garageModule then
        garageModule.render()
    end
end

-- Отрисовка главного меню
function Menu.renderMain()
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
        
        local save_module = require("save.save")
        local wr = save_module.getWR(player)
        
        ac.renderText("СТАТИСТИКА", statsPanel.x, statsPanel.y, 18, "bold", colors.textDim)
        ac.renderText(string.format("Имя: %s", player.name), statsPanel.x, statsPanel.y + 25, 16, "normal", colors.text)
        ac.renderText(string.format("Репутация: %d", player.reputation), statsPanel.x, statsPanel.y + 45, 16, "normal", colors.text)
        ac.renderText(string.format("Деньги: $%d", player.money), statsPanel.x, statsPanel.y + 65, 16, "normal", colors.green)
        ac.renderText(string.format("Побед/Всего: %s", wr), statsPanel.x + statsPanel.width/2, statsPanel.y + 25, 16, "normal", colors.text)
        ac.renderText(string.format("Ранг: #%d", player.stats.blacklist_rank), statsPanel.x + statsPanel.width/2, statsPanel.y + 45, 16, "normal", colors.accent)
        
        -- Текущая машина
        local activeCar = save_module.getActiveCar(player)
        if activeCar then
            ac.renderText(string.format("Авто: %s", activeCar), statsPanel.x + statsPanel.width/2, statsPanel.y + 65, 16, "normal", colors.blue)
        else
            ac.renderText("Авто: Нет", statsPanel.x + statsPanel.width/2, statsPanel.y + 65, 16, "normal", colors.textDim)
        end
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
    
    -- Если мы в главном меню, обрабатываем наведение на кнопки
    if menuState.currentScreen == "main" then
        for _, btn in pairs(buttons) do
            if not btn.isTitle and not btn.isStats then
                btn.hovered = (x >= btn.x and x <= btn.x + btn.width and y >= btn.y and y <= btn.y + btn.height)
            end
        end
    end
    -- Для shop и garage обработка внутри их модулей
end

function Menu.mousePressed(x, y, button)
    if not menuState.visible or button ~= 1 then return end
    
    -- Если мы в главном меню, обрабатываем клики по кнопкам
    if menuState.currentScreen == "main" then
        for _, btn in pairs(buttons) do
            if not btn.isTitle and not btn.isStats and btn.hovered then
                if btn.onClick then btn.onClick() end
                break
            end
        end
    -- Для shop и garage обработка внутри их модулей
    elseif menuState.currentScreen == "shop" and shopModule then
        shopModule.mousePressed(x, y, button)
        -- Обработка клика по автомобилю для покупки
        local screen_w, screen_h = ac.getScreenResolution()
        local panel_w, panel_h = 900, 650
        local panel_x, panel_y = (screen_w - panel_w) / 2, (screen_h - panel_h) / 2
        local list_x = panel_x + 20
        local list_y = panel_y + 130
        local list_w = panel_w - 40
        local list_h = panel_h - 160
        shopModule.handle_car_click(x, y, list_x, list_y, list_w, list_h)
    elseif menuState.currentScreen == "garage" and garageModule then
        -- Garage module handles its own input via update()
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
    
    -- Запуск гонки через Game модуль
    if menuState.gameModule then
        menuState.gameModule.startRace(rival, "street")
    end
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
    
    -- Запуск гонки через Game модуль
    if menuState.gameModule then
        menuState.gameModule.startRace(boss, "blacklist")
    end
end

function Menu.openShop()
    menuState.currentScreen = "shop"
    if shopModule then
        shopModule.init()
    end
end

function Menu.openGarage()
    menuState.currentScreen = "garage"
    if garageModule then
        garageModule.init()
    end
end

function Menu.backToMain()
    menuState.currentScreen = "main"
end

function Menu.show(sessionData, gameModule)
    Menu.init(sessionData, gameModule)
end

function Menu.hide()
    menuState.visible = false
end

function Menu.isVisible()
    return menuState.visible
end

return Menu