local Shop = {}

local ui_active = false
local current_tab = "new" -- "new" или "used"
local scroll_offset = 0
local selected_car_index = 1

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
end

function Shop.update(dt)
    if not ui_active then return end

    -- Управление клавиатурой (стрелки вверх/вниз, энтер, таб)
    if ac.getKeyDown("up") then
        selected_car_index = math.max(1, selected_car_index - 1)
        ac.sleep(0.15) -- задержка для удобства
    end
    if ac.getKeyDown("down") then
        local list = (current_tab == "new") and Cars.get_new_cars() or Cars.get_used_cars()
        selected_car_index = math.min(#list, selected_car_index + 1)
        ac.sleep(0.15)
    end
    
    -- Переключение вкладок (клавиши 1 и 2 или табуляция, пока сделаем просто кнопки в UI)
    -- Для простоты пока оставим выбор мышкой в рендере
    
    if ac.getKeyDown("return") then
        local list = (current_tab == "new") and Cars.get_new_cars() or Cars.get_used_cars()
        if #list > 0 then
            local car = list[selected_car_index]
            Shop.try_buy_car(car, current_tab)
        end
        ac.sleep(0.2)
    end
    
    if ac.getKeyDown("escape") then
        ui_active = false
        -- Если это первый запуск и нет машин, нельзя просто выйти, но пока оставим так
        if Save.get_garage_count() == 0 then
            ui_active = true -- Блокируем выход если нет машин
        end
    end
end

function Shop.try_buy_car(car, type)
    local save_data = Save.get_data()
    
    -- Проверка, есть ли уже такая машина (опционально, можно разрешить покупку нескольких)
    -- Пока разрешаем покупать сколько угодно
    
    local result = Cars.buy_car(car.id, type, save_data.money)
    
    if result.success then
        -- Обновляем сохранение
        Save.add_money(result.remaining_money - save_data.money) -- Разница
        Save.add_to_garage({
            id = car.id,
            name = car.name,
            price = car.price,
            stats = {
                max_speed = car.max_speed,
                acceleration = car.acceleration,
                handling = car.handling
            }
        })
        
        -- Если это первая покупка, ставим её активной
        if Save.get_garage_count() == 1 then
            Save.set_active_car(1)
        end
        
        ui_active = false
        -- Тут можно показать сообщение об успехе, но пока просто закрываем
        print("Машина куплена: " .. car.name)
    else
        print("Ошибка покупки: " .. result.error)
        -- Можно добавить визуальное отображение ошибки
    end
end

function Shop.render()
    if not ui_active then return end

    local W, H = ac.getScreenWidth(), ac.getScreenHeight()
    local cx, cy = W / 2, H / 2
    
    -- Фон затемнения
    draw_rect(0, 0, W, H, {0, 0, 0, 0.7})
    
    -- Основное окно
    local win_w, win_h = 800, 600
    local win_x, win_y = cx - win_w / 2, cy - win_h / 2
    
    draw_rect(win_x, win_y, win_w, win_h, {0.05, 0.05, 0.05, 0.95})
    draw_rect(win_x, win_y, win_w, 4, {1, 1, 1, 1}) -- Верхняя граница
    
    -- Заголовок
    draw_text(cx, win_y + 30, 24, "АВТОСАЛОН", {1, 1, 1, 1}, 1)
    
    -- Баланс
    local money = Save.get_data().money
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
    
    -- Обработка кликов по вкладкам (простая реализация)
    -- В реальном проекте нужно использовать input.is_mouse_over и т.д.
    -- Пока переключение через горячие клавиши или просто логика в update
    
    -- Список автомобилей
    local list = (current_tab == "new") and Cars.get_new_cars() or Cars.get_used_cars()
    local start_y = win_y + 130
    local item_h = 80
    local visible_items = 5
    
    -- Отрисовка списка
    for i = 1, math.min(#list, visible_items) do
        local global_index = i + scroll_offset
        if global_index <= #list then
            local car = list[global_index]
            local is_selected = (global_index == selected_car_index)
            
            local bg_color = is_selected and {0.2, 0.2, 0.2, 1} or {0.1, 0.1, 0.1, 0.5}
            if is_selected then
                draw_rect(win_x + 20, start_y + (i-1)*item_h, win_w - 40, item_h - 10, bg_color)
                draw_rect(win_x + 20, start_y + (i-1)*item_h, 4, item_h - 10, {0, 0.8, 1, 1}) -- Индикатор выбора
            else
                draw_rect(win_x + 20, start_y + (i-1)*item_h, win_w - 40, item_h - 10, bg_color)
            end
            
            -- Название
            draw_text(win_x + 40, start_y + (i-1)*item_h + 20, 18, car.name, {1, 1, 1, 1}, 0)
            -- Цена
            draw_text(win_x + win_w - 120, start_y + (i-1)*item_h + 20, 18, string.format("%d ¥", car.price), {1, 1, 0, 1}, 2)
            -- Описание
            draw_text(win_x + 40, start_y + (i-1)*item_h + 45, 14, car.description or "", {0.7, 0.7, 0.7, 1}, 0)
            
            -- Характеристики (мини)
            local stats = string.format("MAX: %d | ACC: %.1f | HND: %.1f", car.max_speed, car.acceleration, car.handling)
            draw_text(win_x + 40, start_y + (i-1)*item_h + 62, 12, stats, {0.5, 0.8, 1, 1}, 0)
        end
    end
    
    -- Подсказки
    draw_text(cx, win_y + win_h - 40, 14, "↑/↓ : Выбор | ENTER : Купить | ESC : Назад", {0.8, 0.8, 0.8, 1}, 1)
    
    -- Логика переключения вкладок кликом (упрощенно через координаты мыши если нужно, пока через клавиши 1/2)
    if ac.getKeyDown("1") then current_tab = "new" end
    if ac.getKeyDown("2") then current_tab = "used" end
end

return Shop
