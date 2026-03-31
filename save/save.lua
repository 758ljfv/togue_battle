-- save/save.lua
local SaveModule = {}

-- Дефолтные данные, если файл не найден
local defaultData = {
    name = "Toru Massato",
    money = 5000,
    reputation = 0,
    owned_cars = {"ae86_stock"},
    active_car = "ae86_stock",
    defeated_drivers = {}, -- Изначально пустой
    current_track = "akina"
}

function SaveModule.load(path)
    -- Здесь должна быть логика чтения реального файла
    -- Для примера возвращаем хардкод, но в реальности тут io.open
    return defaultData 
end

function SaveModule.save(path, data)
    -- Логика записи (сериализация в JSON)
    print("Saving progress...")
end

return SaveModule