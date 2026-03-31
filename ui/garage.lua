local GarageUI = {}

local activeTab = "garage" -- "garage" или "shop"
local scrollOffset = 0
local selectedCarIndex = 1

-- Вспомогательная функция для отрисовки кнопки
local function drawButton(x, y, w, h, text, isActive, isDisabled)
    local r, g, b = 0.1, 0.1, 0.1
    if isActive then r, g, b = 0.2, 0.4, 0.6 end
    if isDisabled then r, g, b = 0.15, 0.15, 0.15 end
    
    ui_push_rect(x, y, w, h, r, g, b, 0.8)
    
    local color = isDisabled and {0.5, 0.5, 0.5} or {1, 1, 1}
    ui_push_text(x + w/2, y + h/2, text, 0, 1, 0.5, 0.5, unpack(color))
end

-- Отрисовка списка автомобилей
local function drawCarList(cars, startX, startY, width, height, isShop)
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
                for _, owned in ipairs(Save.data.garage) do
                    if owned.id == car.id then
                        isOwned = true
                        if Save.data.current_car and Save.data.current_car.id == car.id then
                            isSelected = true
                        end
                        break
                    end
                end
            else
                -- Проверка владения для магазина (чтобы не купить дважды)
                for _, owned in ipairs(Save.data.garage) do
                    if owned.id == car.id then
                        isOwned = true
                        break
                    end
                end
            end
            
            if i == selectedCarIndex then
                ui_push_rect(startX, y, width, itemHeight - 2, 0.2, 0.4, 0.6, 0.5)
            end
            
            -- Название и цена
            local priceText = isShop and (isOwned and "Куплено" or string.format("%d$", car.price)) or "В гараже"
            if isOwned and not isShop then priceText = isSelected and "Выбрано" or "В наличии" end
            
            ui_push_text(startX + 10, y + 15, car.name, 0, 0, 0, 0, 1, 1, 1)
            ui_push_text(startX + 10, y + 35, string.format("HP: %d | Вес: %d", car.hp or 100, car.weight or 1000), 0, 0, 0, 0, 0.7, 0.7, 0.7)
            ui_push_text(startX + width - 10, y + 20, priceText, 0, 1, 0, 0, 1, 1, 1)
            
            if isShop and not isOwned then
                drawButton(startX + width - 100, y + 10, 90, 40, "Купить", false, false)
            elseif not isShop and not isSelected then
                drawButton(startX + width - 100, y + 10, 90, 40, "Выбрать", false, false)
            end
        end
    end
end

function GarageUI.update(dt, input)
    local cars = (activeTab == "shop") and Cars.new_cars or Save.data.garage
    
    -- Навигация
    if input then
        -- Табы
        if ui_button(100, 50, 150, 40, "Гараж") then activeTab = "garage" end
        if ui_button(260, 50, 150, 40, "Салон") then activeTab = "shop" end
        
        -- Кнопка назад
        if ui_button(20, 20, 100, 40, "< Назад") then
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
            if input.confirm then
                local car = cars[selectedCarIndex]
                if activeTab == "shop" then
                    -- Покупка
                    local owned = false
                    for _, c in ipairs(Save.data.garage) do if c.id == car.id then owned = true break end end
                    
                    if not owned then
                        if Save.data.money >= car.price then
                            Save.add_car(car)
                            Save.data.money = Save.data.money - car.price
                            Save.save()
                            -- Звук покупки?
                        end
                    end
                else
                    -- Выбор авто
                    if car then
                        Save.set_current_car(car)
                        Save.save()
                    end
                end
            end
        end
        
        -- Скролл колесиком (эмуляция)
        if input.scroll then
            scrollOffset = scrollOffset + input.scroll * 20
        end
    end
    
    return "garage"
end

function GarageUI.render()
    local w, h = ui_screen_size()
    
    -- Фон
    ui_push_rect(0, 0, w, h, 0.05, 0.05, 0.05, 0.95)
    
    -- Заголовок
    ui_push_text(w/2, 40, activeTab == "shop" and "АВТОСАЛОН" or "ГАРАЖ", 0, 0.5, 0, 0, 1.2, 1.2, 1, 1, 1)
    
    -- Баланс
    ui_push_text(w - 20, 40, string.format("%d $", Save.data.money), 0, 1, 0, 0, 1, 1, 0, 1, 0)
    
    -- Табы
    local tabY = 100
    ui_push_rect(0, tabY, w, 2, 0.3, 0.3, 0.3, 1)
    
    -- Список
    local listX, listY, listW, listH = 50, 150, w - 100, h - 200
    
    if activeTab == "shop" then
        drawCarList(Cars.new_cars, listX, listY, listW, listH, true)
    else
        if #Save.data.garage == 0 then
            ui_push_text(w/2, h/2, "У вас нет автомобилей. Купите первый в салоне!", 0, 0.5, 0.5, 0, 1, 1, 1, 0.5, 0.5)
        else
            drawCarList(Save.data.garage, listX, listY, listW, listH, false)
        end
    end
    
    -- Подсказки
    ui_push_text(20, h - 30, "Стрелки: Выбор | Enter: Действие | Esc: Назад", 0, 0, 0, 0, 0.7, 0.7, 0.7)
end

return GarageUI
