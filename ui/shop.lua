local Shop = {}

local ui_active = false
local current_tab = "new" -- "new" или "used"
local scroll_offset = 0
local selected_car_index = 1
local selected_brand = nil -- Для фильтрации по марке

-- Вспомогательные функции для отрисовки
local function draw_rect(x, y, w, h, color)
    ac.renderQuad(x, y, w, h, color)
end

local function draw_text(x, y, size, text, color, align)
    ac.renderText(text, x, y, size, color, align or 0)
end

function Shop.init()
    ui_active = true
    current_tab = "new"
    selected_car_index = 1
    scroll_offset = 0
    selected_brand = nil
end

function Shop.update(dt)
    if not ui_active then return end

    -- Управление клавиатурой (стрелки вверх/вниз, энтер, таб)
    if ac.getKeyDown("up") then
        selected_car_index = math.max(1, selected_car_index - 1)
        ac.sleep(0.15) -- задержка для удобства
    end
    if ac.getKeyDown("down") then
        local list = Shop.get_current_list()
        selected_car_index = math.min(#list, selected_car_index + 1)
        ac.sleep(0.15)
    end
    
    if ac.getKeyDown("return") then
        local list = Shop.get_current_list()
        if #list > 0 then
            local car = list[selected_car_index]
            Shop.try_buy_car(car, current_tab)
        end
        ac.sleep(0.2)
    end
    
    if ac.getKeyDown("escape") then
        ui_active = false
        -- Возврат в главное меню через Menu.backToMain()
        local menu = require("ui.menu")
        menu.backToMain()
    end
    
    -- Переключение вкладок цифрами
    if ac.getKeyDown("1") then 
        current_tab = "new" 
        selected_car_index = 1
    end
    if ac.getKeyDown("2") then 
        current_tab = "used" 
        selected_car_index = 1
    end
end

-- Получение текущего списка автомобилей
function Shop.get_current_list()
    if current_tab == "new" then
        if selected_brand then
            return Cars.get_cars_by_brand(selected_brand)
        else
            return Cars.get_new_cars()
        end
    else
        return Cars.get_used_cars()
    end
end

function Shop.try_buy_car(car, type)
    local save_module = require("save.save")
    local data = save_module.load()
    
    -- Проверка, есть ли уже такая машина
    if save_module.hasCar(data, car.id) then
        print("Эта машина уже у вас!")
        return
    end
    
    local result = Cars.buy_car(car.id, type, data.money)
    
    if result.success then
        -- Обновляем сохранение
        save_module.addMoney(data, result.remaining_money - data.money)
        save_module.buyCar(data, car.id)
        
        -- Если это первая покупка, ставим её активной
        if #save_module.getOwnedCars(data) == 1 then
            save_module.setActiveCar(data, car.id)
        end
        
        ui_active = false
        print("Машина куплена: " .. car.name)
        
        -- Возврат в главное меню
        local menu = require("ui.menu")
        menu.backToMain()
    else
        print("Ошибка покупки: " .. result.error)
    end
end

function Shop.render()
    if not ui_active then return end

    local W, H = ac.getScreenWidth(), ac.getScreenHeight()
    local cx, cy = W / 2, H / 2
    
    -- Фон затемнения
    draw_rect(0, 0, W, H, {0, 0, 0, 0.7})
    
    -- Основное окно
    local win_w, win_h = 900, 650
    local win_x, win_y = cx - win_w / 2, cy - win_h / 2
    
    draw_rect(win_x, win_y, win_w, win_h, {0.05, 0.05, 0.05, 0.95})
    draw_rect(win_x, win_y, win_w, 4, {1, 1, 1, 1}) -- Верхняя граница
    
    -- Заголовок
    draw_text(cx, win_y + 30, 24, "АВТОСАЛОН", {1, 1, 1, 1}, 1)
    
    -- Баланс
    local save_module = require("save.save")
    local data = save_module.load()
    local money = save_module.getMoney(data)
    draw_text(win_x + 20, win_y + 30, 18, string.format("Баланс: %d ¥", money), {0, 1, 0, 1}, 0)
    
    -- Вкладки
    local tab_y = win_y + 70
    local tab_h = 40
    local new_tab_x = cx - 150
    local used_tab_x = cx + 50
    
    -- Кнопка "Новые"
    local new_color = (current_tab == "new") and {0, 0.8, 1, 1} or {0.3, 0.3, 0.3, 1}
    draw_rect(new_tab_x - 80, tab_y, 140, tab_h, new_color)
    draw_text(new_tab_x, tab_y + 20, 16, "Салон", {1, 1, 1, 1}, 1)
    
    -- Кнопка "Б/У"
    local used_color = (current_tab == "used") and {0, 0.8, 1, 1} or {0.3, 0.3, 0.3, 1}
    draw_rect(used_tab_x - 80, tab_y, 140, tab_h, used_color)
    draw_text(used_tab_x, tab_y + 20, 16, "Б/У Рынок", {1, 1, 1, 1}, 1)
    
    -- Список брендов (только для новых авто)
    if current_tab == "new" then
        local brands = Cars.get_brands()
        local brand_y = win_y + 125
        local all_brands_x = win_x + 30
        
        -- Кнопка "Все"
        local all_color = (selected_brand == nil) and {0, 0.8, 1, 1} or {0.2, 0.2, 0.2, 1}
        draw_rect(all_brands_x, brand_y, 80, 30, all_color)
        draw_text(all_brands_x + 40, brand_y + 15, 14, "Все", {1, 1, 1, 1}, 1)
        
        -- Остальные бренды
        local brand_x = all_brands_x + 90
        for i, brand in ipairs(brands) do
            local brand_color = (selected_brand == brand) and {0, 0.8, 1, 1} or {0.2, 0.2, 0.2, 1}
            draw_rect(brand_x, brand_y, 100, 30, brand_color)
            draw_text(brand_x + 50, brand_y + 15, 14, brand:upper(), {1, 1, 1, 1}, 1)
            brand_x = brand_x + 110
        end
    end
    
    -- Список автомобилей
    local list = Shop.get_current_list()
    local start_y = win_y + 175
    local item_h = 85
    local visible_items = 5
    
    -- Отрисовка списка
    for i = 1, math.min(#list, visible_items) do
        local global_index = i + scroll_offset
        if global_index <= #list then
            local car = list[global_index]
            local is_selected = (global_index == selected_car_index)
            
            -- Проверка владения
            local owned = save_module.hasCar(data, car.id)
            
            local bg_color = is_selected and {0.2, 0.2, 0.2, 1} or {0.1, 0.1, 0.1, 0.5}
            if owned then
                bg_color = {0.1, 0.15, 0.1, 0.5} -- Зеленоватый оттенок для купленных
            end
            
            if is_selected then
                draw_rect(win_x + 20, start_y + (i-1)*item_h, win_w - 40, item_h - 10, bg_color)
                draw_rect(win_x + 20, start_y + (i-1)*item_h, 4, item_h - 10, {0, 0.8, 1, 1}) -- Индикатор выбора
            else
                draw_rect(win_x + 20, start_y + (i-1)*item_h, win_w - 40, item_h - 10, bg_color)
            end
            
            -- Название и бренд
            local displayName = car.name
            if car.brand then
                displayName = string.format("%s (%s)", car.name, car.brand:upper())
            end
            draw_text(win_x + 40, start_y + (i-1)*item_h + 20, 18, displayName, {1, 1, 1, 1}, 0)
            
            -- Цена
            local priceColor = owned and {0.5, 0.5, 0.5, 1} or {1, 1, 0, 1}
            local priceText = owned and "КУПЛЕНО" or string.format("%d ¥", car.price)
            draw_text(win_x + win_w - 140, start_y + (i-1)*item_h + 20, 18, priceText, priceColor, 2)
            
            -- Описание
            draw_text(win_x + 40, start_y + (i-1)*item_h + 45, 14, car.description or "", {0.7, 0.7, 0.7, 1}, 0)
            
            -- Характеристики (мини)
            local stats = ""
            if car.stats then
                stats = string.format("PWR: %d | WGT: %d | GRP: %d", 
                    car.stats.power or 0, 
                    car.stats.weight or 0, 
                    car.stats.grip or 0)
            end
            draw_text(win_x + 40, start_y + (i-1)*item_h + 65, 12, stats, {0.5, 0.8, 1, 1}, 0)
        end
    end
    
    -- Подсказки
    draw_text(cx, win_y + win_h - 50, 14, "↑/↓ : Выбор | ENTER : Купить | 1/2 : Вкладки | ESC : Назад", {0.8, 0.8, 0.8, 1}, 1)
    if current_tab == "new" then
        draw_text(cx, win_y + win_h - 30, 12, "Клик по названию бренда для фильтрации", {0.6, 0.6, 0.6, 1}, 1)
    end
end

return Shop
