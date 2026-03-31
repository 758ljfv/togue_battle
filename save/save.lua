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
    current_track = "akina",
    -- Статистика
    stats = {
        wins = 0,
        total_races = 0,
        blacklist_rank = 10, -- Текущий ранг в блэклисте (10 - самый низкий)
        area_unlocked = "akina" -- Текущая разблокированная область
    }
}

function SaveModule.load(path)
    -- Здесь должна быть логика чтения реального файла
    -- Для примера возвращаем хардкод, но в реальности тут io.open
    local data = defaultData
    -- Клонируем таблицу чтобы избежать ссылочных проблем
    local clonedData = {
        name = data.name,
        money = data.money,
        reputation = data.reputation,
        owned_cars = {},
        active_car = data.active_car,
        defeated_drivers = {},
        current_track = data.current_track,
        stats = {
            wins = data.stats.wins,
            total_races = data.stats.total_races,
            blacklist_rank = data.stats.blacklist_rank,
            area_unlocked = data.stats.area_unlocked
        }
    }
    for _, car in ipairs(data.owned_cars) do
        table.insert(clonedData.owned_cars, car)
    end
    for _, id in ipairs(data.defeated_drivers) do
        table.insert(clonedData.defeated_drivers, id)
    end
    return clonedData
end

function SaveModule.save(path, data)
    -- Логика записи (сериализация в JSON)
    print("Saving progress...")
    -- В реальной реализации: json.encode и запись в файл
end

function SaveModule.addWin(data)
    data.stats.wins = data.stats.wins + 1
    data.stats.total_races = data.stats.total_races + 1
end

function SaveModule.addLoss(data)
    data.stats.total_races = data.stats.total_races + 1
end

function SaveModule.getWR(data)
    if data.stats.total_races == 0 then
        return "0/0 (0%)"
    end
    local percentage = math.floor((data.stats.wins / data.stats.total_races) * 100)
    return string.format("%d/%d (%d%%)", data.stats.wins, data.stats.total_races, percentage)
end

return SaveModule