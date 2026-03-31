local Cars = {}

Cars.new_cars = {} -- Плоский список всех новых авто
Cars.used_cars = {} -- Плоский список всех б/у авто
Cars.brands = {} -- Структура по маркам

-- Загрузка данных об автомобилях из JSON файлов
function Cars.load_data()
    -- Загрузка новых авто (структура по маркам)
    local file = io.open("data/cars.json", "r")
    if file then
        local content = file:read("*all")
        file:close()
        local data = json.decode(content)
        
        Cars.brands = data or {}
        
        -- Преобразуем в плоский список для удобства
        Cars.new_cars = {}
        for brand, cars in pairs(Cars.brands) do
            for _, car in ipairs(cars) do
                car.brand = brand -- Добавляем марку к каждому авто
                table.insert(Cars.new_cars, car)
            end
        end
        
        print(string.format("[Cars] Loaded %d new cars from %d brands", #Cars.new_cars, #Cars.brands))
    else
        print("[Cars] Warning: data/cars.json not found")
        Cars.new_cars = {}
        Cars.brands = {}
    end

    -- Загрузка б/у авто
    local used_file = io.open("data/used_cars.json", "r")
    if used_file then
        local content = used_file:read("*all")
        used_file:close()
        local data = json.decode(content)
        if data and data.cars then
            Cars.used_cars = data.cars
            print(string.format("[Cars] Loaded %d used cars", #Cars.used_cars))
        end
    else
        print("[Cars] Warning: data/used_cars.json not found (optional)")
        Cars.used_cars = {}
    end
end

-- Получение списка новых автомобилей (плоский список)
function Cars.get_new_cars()
    return Cars.new_cars
end

-- Получение списка новых автомобилей по марке
function Cars.get_cars_by_brand(brand)
    return Cars.brands[brand] or {}
end

-- Получение списка доступных марок
function Cars.get_brands()
    local brands = {}
    for brand in pairs(Cars.brands) do
        table.insert(brands, brand)
    end
    return brands
end

-- Получение списка подержанных автомобилей
function Cars.get_used_cars()
    return Cars.used_cars
end

-- Получение автомобиля по ID
function Cars.get_car_by_id(car_id)
    -- Поиск среди новых
    for _, car in ipairs(Cars.new_cars) do
        if car.id == car_id then
            return car
        end
    end
    
    -- Поиск среди б/у
    for _, car in ipairs(Cars.used_cars) do
        if car.id == car_id then
            return car
        end
    end
    
    return nil
end

-- Покупка автомобиля
-- Возвращает: {success = true/false, car = table, remaining_money = number, error = string}
function Cars.buy_car(car_id, car_type, player_money)
    local car_list = (car_type == "used") and Cars.used_cars or Cars.new_cars
    
    for i, car in ipairs(car_list) do
        if car.id == car_id then
            if player_money >= car.price then
                return {
                    success = true, 
                    car = car, 
                    remaining_money = player_money - car.price
                }
            else
                return {
                    success = false, 
                    error = "Недостаточно средств"
                }
            end
        end
    end
    
    return {
        success = false, 
        error = "Автомобиль не найден"
    }
end

-- Инициализация при загрузке модуля
Cars.load_data()

return Cars
