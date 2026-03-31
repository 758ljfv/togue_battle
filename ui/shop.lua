local ac = require('ac')
local Cars = require('cars')
local SaveModule = require('save')

local Shop = {}

Shop.brands = {'Все', 'Toyota', 'Mazda', 'Nissan'}
Shop.current_brand = 1
Shop.scroll_offset = 0
Shop.hovered_button = nil
Shop.brand_buttons = {} -- Храним координаты кнопок брендов

function Shop.draw()
    local screen_w, screen_h = ac.getScreenResolution()
    local panel_w, panel_h = 900, 650
    local panel_x, panel_y = (screen_w - panel_w) / 2, (screen_h - panel_h) / 2

    -- Фон панели
    ac.renderRect(panel_x, panel_y, panel_w, panel_h, {r = 20, g = 20, b = 25, a = 230})

    -- Заголовок
    ac.renderText(panel_x + 20, panel_y + 20, 'Автосалон', 28, {r = 255, g = 255, b = 255})

    -- Баланс
    local money_text = string.format('Баланс: $%d', SaveModule.data.money or 0)
    ac.renderText(panel_x + panel_w - 200, panel_y + 25, money_text, 22, {r = 100, g = 255, b = 100})

    -- Кнопки брендов
    local brand_y = panel_y + 70
    local brand_x_start = panel_x + 20
    local brand_w, brand_h = 100, 40
    Shop.brand_buttons = {} -- Очищаем перед перерисовкой

    for i, brand in ipairs(Shop.brands) do
        local bx = brand_x_start + (i - 1) * (brand_w + 10)
        local is_hovered = Shop.is_mouse_over(bx, brand_y, brand_w, brand_h)
        local color = {r = 50, g = 50, b = 60, a = 255}

        if is_hovered then
            color = {r = 80, g = 80, b = 100, a = 255}
            Shop.hovered_button = {'brand', i}
            if ac.getMouseState().left then
                Shop.current_brand = i
            end
        elseif Shop.current_brand == i then
            color = {r = 100, g = 150, b = 255, a = 255}
        end

        ac.renderRect(bx, brand_y, brand_w, brand_h, color)
        ac.renderText(bx + 10, brand_y + 10, brand, 18, {r = 255, g = 255, b = 255})

        -- Сохраняем координаты для обработки
        table.insert(Shop.brand_buttons, {x = bx, y = brand_y, w = brand_w, h = brand_h, brand = brand})
    end

    -- Горячие клавиши для брендов
    for i = 1, #Shop.brands do
        if ac.getKeyboardState()['d' .. i] then
            Shop.current_brand = i
        end
    end

    -- Список автомобилей
    local list_x = panel_x + 20
    local list_y = panel_y + 130
    local list_w = panel_w - 40
    local list_h = panel_h - 160

    -- Фон списка
    ac.renderRect(list_x, list_y, list_w, list_h, {r = 30, g = 30, b = 35, a = 200})

    Shop.draw_car_list(list_x, list_y, list_w, list_h)

    -- Подсказка
    ac.renderText(panel_x + 20, panel_y + panel_h - 30, 'ЛКМ - Купить/Выбрать бренд | Колесо - Прокрутка | 1-4 - Бренд', 16, {r = 200, g = 200, b = 200})
end

function Shop.is_mouse_over(x, y, w, h)
    local mouse_x, mouse_y = ac.getMousePosition()
    return mouse_x >= x and mouse_x <= x + w and mouse_y >= y and mouse_y <= y + h
end

function Shop.draw_car_list(x, y, w, h)
    local cars = Cars.get_cars_by_brand(Shop.brands[Shop.current_brand])
    local owned_cars = SaveModule.data.cars or {}
    local max_visible = 7
    local item_height = 70

    -- Ограничиваем скролл
    if #cars <= max_visible then
        Shop.scroll_offset = 0
    elseif Shop.scroll_offset > #cars - max_visible then
        Shop.scroll_offset = #cars - max_visible
    end
    if Shop.scroll_offset < 0 then Shop.scroll_offset = 0 end

    for i = 1, math.min(#cars, max_visible) do
        local car_index = Shop.scroll_offset + i
        if car_index > #cars then break end

        local car = cars[car_index]
        local item_y = y + (i - 1) * item_height
        local is_hovered = Shop.is_mouse_over(x, item_y, w, item_height)

        -- Проверка владения
        local is_owned = false
        for _, owned in ipairs(owned_cars) do
            if owned.id == car.id then
                is_owned = true
                break
            end
        end

        -- Цвет фона
        local bg_color = {r = 40, g = 40, b = 45, a = 255}
        if is_hovered then
            bg_color = {r = 60, g = 60, b = 70, a = 255}
            Shop.hovered_button = {'car', car, car_index}

            -- Обработка клика покупки
            if ac.getMouseState().left then
                if not is_owned then
                    if SaveModule.data.money >= car.price then
                        SaveModule.data.money = SaveModule.data.money - car.price
                        table.insert(SaveModule.data.cars, {
                            id = car.id,
                            name = car.name,
                            brand = car.brand,
                            price = car.price,
                            type = car.type
                        })
                        SaveModule.save()
                    else
                        -- Можно добавить сообщение об ошибке
                    end
                end
            end
        end

        ac.renderRect(x, item_y, w, item_height, bg_color)

        -- Название авто
        local name_color = {r = 255, g = 255, b = 255}
        if is_owned then
            name_color = {r = 100, g = 255, b = 100}
        end
        ac.renderText(x + 15, item_y + 10, car.name, 20, name_color)

        -- Цена
        local price_color = {r = 255, g = 200, b = 50}
        if is_owned then
            price_color = {r = 150, g = 150, b = 150}
        end
        ac.renderText(x + w - 150, item_y + 10, string.format('$%d', car.price), 20, price_color)

        -- Статус
        local status = is_owned and 'В ГАРАЖЕ' or 'ДОСТУПЕН'
        local status_color = is_owned and {r = 100, g = 255, b = 100} or {r = 255, g = 255, b = 255}
        ac.renderText(x + w - 150, item_y + 35, status, 16, status_color)

        -- Характеристики
        local stats_text = string.format('Скорость: %d | Ускорение: %.1f | Управление: %.1f',
            car.max_speed or 0, car.acceleration or 0, car.handling or 0)
        ac.renderText(x + 15, item_y + 35, stats_text, 14, {r = 200, g = 200, b = 200})
    end

    -- Обработка скролла колеса
    local scroll = ac.getMouseScroll()
    if scroll ~= 0 and #cars > max_visible then
        Shop.scroll_offset = Shop.scroll_offset + (scroll > 0 and -1 or 1)
        if Shop.scroll_offset < 0 then Shop.scroll_offset = 0 end
        if Shop.scroll_offset > #cars - max_visible then
            Shop.scroll_offset = #cars - max_visible
        end
    end
end

return Shop