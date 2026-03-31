local GarageUI = {}

local activeTab = "garage" -- "garage" или "shop"
local scrollOffset = 0
local selectedCarIndex = 1
local hoveredButton = nil
local saveData = nil -- Кэшированные данные сохранения

-- Загрузка данных сохранения
local function getSaveData()
    if not saveData then
        local SaveModule = require('save.save')
        saveData = SaveModule.load()
    end
    return saveData
end

-- Сброс кэша при необходимости
function GarageUI.refreshData()
    saveData = nil
end

-- Вспомогательная функция для отрисовки кнопки
local function drawButton(id, x, y, w, h, text, isActive, isDisabled)
    local r, g, b = 0.1, 0.1, 0.1
    if isActive then r, g, b = 0.2, 0.4, 0.6 end
    if isDisabled then r, g, b = 0.15, 0.15, 0.15 end
    
    -- Проверка наведения мыши
    local mx, my = ac.getMousePosition()
    local isHovered = mx >= x and mx <= x + w and my >= y and my <= y + h
    if isHovered and not isDisabled then
        r, g, b = r + 0.1, g + 0.1, b + 0.1
        hoveredButton = id
    end
    
    ac.renderRect(x, y, w, h, r, g, b, 0.8)
    
    local color = isDisabled and {0.5, 0.5, 0.5} or {1, 1, 1}
    ac.renderText(text, x + w/2, y + h/2, 0, 1, 0.5, 0.5, unpack(color))
end

-- Отрисовка списка автомобилей
local function drawCarList(cars, startX, startY, width, height, isShop)
    local SaveModule = require('save.save')
    local data = getSaveData()
    local itemHeight = 60
    local visibleItems = math.floor(height / itemHeight)
    
    -- Ограничение скролла
    local maxScroll = math.max(0, (#cars - visibleItems) * itemHeight)
    scrollOffset = math.min(math.max(0, scrollOffset), maxScroll)
    
    for i = 1, #cars do
        local y = startY + (i - 1) * itemHeight - scrollOffset
        if y > startY - itemHeight and y < startY + height then
            local car = cars[i]
            local isOwned = false
            local isSelected = false
            
            if not isShop then
                -- Проверка владения для гаража
                for _, owned_id in ipairs(data.owned_cars or {}) do
                    if owned_id == car.id then
                        isOwned = true
                        if data.active_car and data.active_car == car.id then
                            isSelected = true
                        end
                        break
                    end
                end
            else
                -- Проверка владения для магазина (чтобы не купить дважды)
                for _, owned_id in ipairs(data.owned_cars or {}) do
                    if owned_id == car.id then
                        isOwned = true
                        break
                    end
                end
            end
            
            if i == selectedCarIndex then
                ac.renderRect(startX, y, width, itemHeight - 2, 0.2, 0.4, 0.6, 0.3)
            end
            
            -- Название и цена
            local priceText = isShop and (isOwned and "Куплено" or string.format("%d$", car.price)) or "В гараже"
            if isOwned and not isShop then priceText = isSelected and "Выбрано" or "В наличии" end
            
            ac.renderText(car.name, startX + 10, y + 15, 0, 0, 0, 0, 1, 1, 1)
            ac.renderText(string.format("HP: %d | Вес: %d", car.hp or 100, car.weight or 1000), startX + 10, y + 35, 0, 0, 0, 0, 0.7, 0.7, 0.7)
            ac.renderText(priceText, startX + width - 10, y + 20, 0, 1, 0, 0, 1, 1, 1)
            
            if isShop and not isOwned then
                drawButton("buy_"..i, startX + width - 100, y + 10, 90, 40, "Купить", false, false)
            elseif not isShop and not isSelected then
                drawButton("select_"..i, startX + width - 100, y + 10, 90, 40, "Выбрать", false, false)
            end
        end
    end
end

function GarageUI.update(dt, input)
    local SaveModule = require('save.save')
    local data = getSaveData()
    local cars = (activeTab == "shop") and Cars.new_cars or (data.owned_cars or {})
    
    -- Сброс наведения
    hoveredButton = nil
    
    -- Навигация
    if input then
        -- Табы
        if ac.getMousePosition() then
            local mx, my = ac.getMousePosition()
            local isClicked = input.mouse_left or false
            
            -- Клик по табам
            if mx >= 100 and mx <= 250 and my >= 50 and my <= 90 and isClicked then
                activeTab = "garage"
            elseif mx >= 260 and mx <= 410 and my >= 50 and my <= 90 and isClicked then
                activeTab = "shop"
            end
        end
        
        if input.key_1 then activeTab = "garage" end
        if input.key_2 then activeTab = "shop" end
        
        -- Кнопка назад
        local mx, my = ac.getMousePosition()
        if mx and mx >= 20 and mx <= 120 and my >= 20 and my <= 60 and input.mouse_left then
            return "menu"
        end
        if input.key_escape then
            return "menu"
        end
        
        -- Скролл и выбор
        if #cars > 0 then
            if input.key_up then
                selectedCarIndex = math.max(1, selectedCarIndex - 1)
            elseif input.key_down then
                selectedCarIndex = math.min(#cars, selectedCarIndex + 1)
            end
            
            -- Обработка действий (Enter/Click)
            if input.confirm or input.mouse_left then
                local car = cars[selectedCarIndex]
                if car then
                    local carY = 150 + (selectedCarIndex - 1) * 60 - scrollOffset
                    local btnX = 50 + (ac.getScreenResolution().x - 100) - 100
                    local btnY = carY + 10
                    
                    if mx and my and mx >= btnX and mx <= btnX + 90 and my >= btnY and my <= btnY + 40 then
                        if activeTab == "shop" then
                            -- Покупка
                            local owned = false
                            for _, owned_id in ipairs(data.owned_cars or {}) do 
                                if owned_id == car.id then 
                                    owned = true 
                                    break 
                                end 
                            end
                            
                            if not owned then
                                if data.money >= car.price then
                                    -- Используем правильный API
                                    data.money = data.money - car.price
                                    SaveModule.buyCar(data, car.id)
                                    saveData = data -- Обновляем кэш
                                end
                            end
                        else
                            -- Выбор авто
                            SaveModule.setActiveCar(data, car.id)
                            saveData = data -- Обновляем кэш
                        end
                    end
                end
            end
        end
        
        -- Скролл колесиком
        if input.scroll then
            scrollOffset = scrollOffset - input.scroll * 30
        end
    end
    
    return "garage"
end

function GarageUI.render()
    local SaveModule = require('save.save')
    local data = getSaveData()
    local w, h = ac.getScreenResolution()
    
    -- Фон
    ac.renderRect(0, 0, w, h, 0.05, 0.05, 0.05, 0.95)
    
    -- Заголовок
    ac.renderText(activeTab == "shop" and "АВТОСАЛОН" or "ГАРАЖ", w/2, 40, 0, 0.5, 0, 0, 1.2, 1.2, 1, 1, 1)
    
    -- Баланс
    ac.renderText(string.format("%d $", data.money or 0), w - 20, 40, 0, 1, 0, 0, 1, 1, 0, 1, 0)
    
    -- Табы
    local tabY = 100
    ac.renderRect(0, tabY, w, 2, 0.3, 0.3, 0.3, 1)
    
    -- Кнопки табов
    local garageActive = activeTab == "garage"
    local shopActive = activeTab == "shop"
    
    ac.renderRect(100, 50, 150, 40, garageActive and 0.2 or 0.1, garageActive and 0.4 or 0.1, garageActive and 0.6 or 0.1, 0.8)
    ac.renderText("Гараж [1]", 175, 70, 0, 0.5, 0.5, 0, 1, 1, 1)
    
    ac.renderRect(260, 50, 150, 40, shopActive and 0.2 or 0.1, shopActive and 0.4 or 0.1, shopActive and 0.6 or 0.1, 0.8)
    ac.renderText("Салон [2]", 335, 70, 0, 0.5, 0.5, 0, 1, 1, 1)
    
    -- Кнопка назад
    ac.renderRect(20, 20, 100, 40, 0.15, 0.15, 0.15, 0.8)
    ac.renderText("< Назад", 70, 40, 0, 0.5, 0.5, 0, 1, 1, 1)
    
    -- Список
    local listX, listY, listW, listH = 50, 150, w - 100, h - 200
    
    if activeTab == "shop" then
        drawCarList(Cars.new_cars, listX, listY, listW, listH, true)
    else
        local owned_cars = data.owned_cars or {}
        if #owned_cars == 0 then
            ac.renderText("У вас нет автомобилей. Купите первый в салоне!", w/2, h/2, 0, 0.5, 0.5, 0, 1, 1, 1, 0.5, 0.5)
        else
            -- Преобразуем ID автомобилей в объекты для отображения
            local garageCars = {}
            for _, car_id in ipairs(owned_cars) do
                local car = Cars.get_car_by_id(car_id)
                if car then
                    table.insert(garageCars, car)
                end
            end
            drawCarList(garageCars, listX, listY, listW, listH, false)
        end
    end
    
    -- Подсказки
    ac.renderText("Стрелки: Выбор | Enter/Клик: Действие | Esc: Назад", 20, h - 30, 0, 0, 0, 0, 0.7, 0.7, 0.7)
end

return GarageUI
