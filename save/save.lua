-- save/save.lua
local SaveModule = {}

local savePath = "_touge_save.json"

-- Дефолтные данные, если файл не найден
local defaultData = {
    name = "Toru Massato",
    money = 5000,
    reputation = 0,
    owned_cars = {}, -- Пустой гараж на старте
    active_car = nil, -- Нет активной машины пока не куплена
    defeated_drivers = {}, -- Изначально пустой
    current_track = "akina",
    -- Статистика
    stats = {
        wins = 0,
        total_races = 0,
        blacklist_rank = 10, -- Текущий ранг в блэклисте (10 - самый низкий)
        area_unlocked = "akina" -- Текущая разблокированная область
    }
}

local savedData = nil

-- Вспомогательная функция для глубокого копирования
local function deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function SaveModule.load(path)
    local file = io.open(savePath, "r")
    if file then
        local content = file:read("*all")
        file:close()
        local ok, data = pcall(json.decode, content)
        if ok and data then
            -- Миграция данных: добавляем отсутствующие поля
            if not data.money then data.money = defaultData.money end
            if not data.owned_cars then data.owned_cars = {} end
            if not data.active_car then data.active_car = nil end
            if not data.defeated_drivers then data.defeated_drivers = {} end
            if not data.stats then 
                data.stats = {
                    wins = 0,
                    total_races = 0,
                    blacklist_rank = 10,
                    area_unlocked = "akina"
                }
            end
            if not data.stats.wins then data.stats.wins = 0 end
            if not data.stats.total_races then data.stats.total_races = 0 end
            if not data.stats.blacklist_rank then data.stats.blacklist_rank = 10 end
            if not data.stats.area_unlocked then data.stats.area_unlocked = "akina" end
            
            savedData = data
            return deepCopy(savedData)
        end
    end
    
    -- Если файла нет или ошибка, создаем новый с дефолтными данными
    savedData = deepCopy(defaultData)
    SaveModule.save(savePath, savedData)
    return deepCopy(savedData)
end

function SaveModule.save(path, data)
    if not data then 
        if not savedData then return end
        data = savedData
    end
    
    local file = io.open(savePath, "w")
    if file then
        file:write(json.encode(data))
        file:close()
        print("Progress saved.")
    end
end

function SaveModule.addWin(data)
    data.stats.wins = data.stats.wins + 1
    data.stats.total_races = data.stats.total_races + 1
    SaveModule.save(savePath, data)
end

function SaveModule.addLoss(data)
    data.stats.total_races = data.stats.total_races + 1
    SaveModule.save(savePath, data)
end

function SaveModule.getWR(data)
    if data.stats.total_races == 0 then
        return "0/0 (0%)"
    end
    local percentage = math.floor((data.stats.wins / data.stats.total_races) * 100)
    return string.format("%d/%d (%d%%)", data.stats.wins, data.stats.total_races, percentage)
end

-- Управление деньгами
function SaveModule.addMoney(data, amount)
    data.money = data.money + amount
    SaveModule.save(savePath, data)
end

function SaveModule.removeMoney(data, amount)
    if data.money >= amount then
        data.money = data.money - amount
        SaveModule.save(savePath, data)
        return true
    end
    return false
end

function SaveModule.getMoney(data)
    return data.money or 0
end

-- Управление гаражом
function SaveModule.buyCar(data, carId)
    -- Проверка, есть ли уже машина
    for _, owned in ipairs(data.owned_cars) do
        if owned == carId then
            return false -- Уже куплена
        end
    end
    
    table.insert(data.owned_cars, carId)
    SaveModule.save(savePath, data)
    return true
end

function SaveModule.hasCar(data, carId)
    for _, owned in ipairs(data.owned_cars) do
        if owned == carId then
            return true
        end
    end
    return false
end

function SaveModule.setActiveCar(data, carId)
    if SaveModule.hasCar(data, carId) then
        data.active_car = carId
        SaveModule.save(savePath, data)
        return true
    end
    return false
end

function SaveModule.getActiveCar(data)
    return data.active_car
end

function SaveModule.getOwnedCars(data)
    return data.owned_cars or {}
end

-- Управление блэклистом
function SaveModule.setBlacklistRank(data, rank)
    data.stats.blacklist_rank = rank
    SaveModule.save(savePath, data)
end

function SaveModule.getBlacklistRank(data)
    return data.stats.blacklist_rank or 10
end

-- Проверка победы над гонщиком
function SaveModule.defeatDriver(data, driverId)
    for _, id in ipairs(data.defeated_drivers) do
        if id == driverId then
            return false -- Уже побежден
        end
    end
    table.insert(data.defeated_drivers, driverId)
    SaveModule.save(savePath, data)
    return true
end

function SaveModule.hasDefeatedDriver(data, driverId)
    for _, id in ipairs(data.defeated_drivers) do
        if id == driverId then
            return true
        end
    end
    return false
end

return SaveModule