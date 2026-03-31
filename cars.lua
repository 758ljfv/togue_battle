local Cars = {}

Cars.new_cars = {}
Cars.used_cars = {}

-- Загрузка данных об автомобилях из JSON файлов
function Cars.load_data()
    -- Загрузка новых авто
    local file = io.open("content/data/cars.json", "r")
    if file then
        local content = file:read("*all")
        file:close()
        local data = json.decode(content)
        if data and data.cars then
            Cars.new_cars = data.cars
        end
    else
        print("[Cars] Warning: content/data/cars.json not found")
        Cars.new_cars = {}
    end

    -- Загрузка б/у авто
    local used_file = io.open("content/data/used_cars.json", "r")
    if used_file then
        local content = used_file:read("*all")
        used_file:close()
        local data = json.decode(content)
        if data and data.cars then
            Cars.used_cars = data.cars
        end
    else
        print("[Cars] Warning: content/data/used_cars.json not found (optional)")
        Cars.used_cars = {}
    end
    
    print(string.format("[Cars] Loaded %d new cars and %d used cars", #Cars.new_cars, #Cars.used_cars))
end

-- Получение списка новых автомобилей
function Cars.get_new_cars()
    return Cars.new_cars
end

-- Получение списка подержанных автомобилей
function Cars.get_used_cars()
    return Cars.used_cars
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
