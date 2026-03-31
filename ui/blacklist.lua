-- ui/blacklist.lua
-- UI для отображения блэклиста и прогресса

local BlacklistUI = {}

local screenWidth = 1920
local screenHeight = 1080

-- Цвета
local colors = {
    bg = {0.05, 0.05, 0.08, 0.95},
    panel = {0.1, 0.1, 0.15, 0.9},
    text = {1, 1, 1, 1},
    textDim = {0.6, 0.6, 0.6, 1},
    accent = {0.95, 0.2, 0.2, 1},
    green = {0.2, 0.8, 0.2, 1},
    locked = {0.4, 0.4, 0.4, 1}
}

-- Состояние
local uiState = {
    visible = false,
    sessionData = nil,
    hoveredRacer = nil
}

-- Инициализация
function BlacklistUI.init(sessionData)
    uiState.sessionData = sessionData
    uiState.visible = true
end

-- Отрисовка
function BlacklistUI.render()
    if not uiState.visible then return end
    
    local sessionData = uiState.sessionData
    if not sessionData then return end
    
    -- Фон
    ac.renderRect(0, 0, screenWidth, screenHeight, colors.bg)
    
    -- Заголовок
    ac.renderText("BLACKLIST - AKINA", 100, 50, 36, "bold", colors.accent)
    
    -- Список гонщиков
    local startY = 150
    local rowHeight = 70
    local col1X = 150  -- Ранг
    local col2X = 250  -- Имя
    local col3X = 600  -- Авто
    local col4X = 900  -- Статус
    
    -- Заголовки колонок
    ac.renderText("#", col1X, startY - 30, 20, "bold", colors.textDim)
    ac.renderText("ГОНЩИК", col2X, startY - 30, 20, "bold", colors.textDim)
    ac.renderText("АВТОМОБИЛЬ", col3X, startY - 30, 20, "bold", colors.textDim)
    ac.renderText("СТАТУС", col4X, startY - 30, 20, "bold", colors.textDim)
    
    -- Блэклист гонщики
    local allBlacklist = sessionData.unlockedBlacklist or {}
    
    for i, racer in ipairs(allBlacklist) do
        local y = startY + (i - 1) * rowHeight
        local isDefeated = false
        
        -- Проверка на победу (если есть в defeated_drivers)
        if sessionData.player and sessionData.player.defeated_drivers then
            for _, defeatedId in ipairs(sessionData.player.defeated_drivers) do
                if defeatedId == racer.id then
                    isDefeated = true
                    break
                end
            end
        end
        
        -- Фон строки
        local rowColor = isDefeated and {0.1, 0.3, 0.1, 0.5} or colors.panel
        ac.renderRect(100, y - 10, screenWidth - 200, rowHeight, rowColor)
        
        -- Ранг
        ac.renderText(string.format("#%d", racer.blacklist_position or i), col1X, y + 10, 24, "bold", colors.accent)
        
        -- Имя
        ac.renderText(racer.name, col2X, y + 10, 24, "normal", colors.text)
        if racer.nickname then
            ac.renderText(string.format("\"%s\"", racer.nickname), col2X, y + 35, 16, "italic", colors.textDim)
        end
        
        -- Авто
        ac.renderText(racer.car_id, col3X, y + 10, 24, "normal", colors.text)
        
        -- Статус
        local statusText = isDefeated and "ПОБЕЖДЕН" or "ДОСТУПЕН"
        local statusColor = isDefeated and colors.green or colors.accent
        ac.renderText(statusText, col4X, y + 10, 24, "bold", statusColor)
    end
    
    -- Информация о прогрессе
    if sessionData.player then
        local player = sessionData.player
        local statsInfoY = screenHeight - 150
        
        ac.renderRect(100, statsInfoY - 10, screenWidth - 200, 100, colors.panel)
        ac.renderText("ПРОГРЕСС", 150, statsInfoY, 20, "bold", colors.textDim)
        ac.renderText(string.format("Текущий ранг: #%d", player.stats.blacklist_rank), 150, statsInfoY + 30, 18, "normal", colors.text)
        ac.renderText(string.format("Побеждено боссов: %d/%d", #player.defeated_drivers, 10), 400, statsInfoY + 30, 18, "normal", colors.green)
        ac.renderText(string.format("Репутация: %d", player.reputation), 150, statsInfoY + 60, 18, "normal", colors.text)
        ac.renderText(string.format("Деньги: $%d", player.money), 400, statsInfoY + 60, 18, "normal", colors.green)
    end
    
    -- Кнопка назад
    ac.renderRect(screenWidth - 200, screenHeight - 80, 150, 50, colors.button)
    ac.renderText("НАЗАД", screenWidth - 175, screenHeight - 60, 20, "normal", colors.text, "center")
end

-- Обработка мыши
function BlacklistUI.mouseMoved(x, y)
    -- Можно добавить ховер эффекты
end

function BlacklistUI.mousePressed(x, y, button)
    if button ~= 1 then return end
    
    -- Кнопка назад
    if x >= screenWidth - 200 and x <= screenWidth - 50 and 
       y >= screenHeight - 80 and y <= screenHeight - 30 then
        BlacklistUI.hide()
    end
end

function BlacklistUI.show(sessionData)
    BlacklistUI.init(sessionData)
end

function BlacklistUI.hide()
    uiState.visible = false
end

function BlacklistUI.isVisible()
    return uiState.visible
end

return BlacklistUI