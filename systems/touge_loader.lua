-- systems/touge_loader.lua
local json = require("dkjson") -- Убедись, что файл dkjson.lua доступен
local SaveModule = require("save.save") -- Правильный импорт

local TougeLoader = {}

-- Вспомогательная функция для чтения файла
local function readFile(path)
    local file, err = io.open(path, "r")
    if not file then return nil, err end
    local content = file:read("*a")
    file:close()
    return content
end

function TougeLoader.init(trackName)
    -- 1. Загружаем профиль игрока
    local player = SaveModule.load("save/player_data.json")

    -- 2. Загружаем данные гонщиков для трассы
    local jsonPath = string.format("data/drivers/%s.json", trackName)
    local content, err = readFile(jsonPath)

    if not content then
        print("Ошибка загрузки трассы " .. trackName .. ": " .. tostring(err))
        return nil
    end

    local data, pos, jsonErr = json.decode(content, 1, nil)
    if jsonErr then
        print("Ошибка JSON: " .. jsonErr)
        return nil
    end

    local drivers = data.drivers
    local unlockedBlacklist = {}
    local streetDrivers = {}

    -- 3. Логика разблокировки Blacklist
    -- Сортируем блеклист по позиции (на всякий случай), если в JSON порядок нарушен
    local blacklistTable = {}
    for _, d in ipairs(drivers) do
        if d.type == "blacklist" then
            table.insert(blacklistTable, d)
        elseif d.type == "street" then
            table.insert(streetDrivers, d)
        end
    end

    -- Сортируем от 10 к 1 (или от 1 к 10, зависит от твоей логики)
    -- В твоем примере 10 - это первый соперник.
    table.sort(blacklistTable, function(a, b) return a.blacklist_position > b.blacklist_position end)

    for i, driver in ipairs(blacklistTable) do
        local canUnlock = false

        -- Первый в списке (позиция 10) открыт всегда
        if i == 1 then
            canUnlock = true
        else
            -- Проверяем, побежден ли предыдущий (который был выше в таблице, т.е. позиция +1)
            local prevDriver = blacklistTable[i-1]
            if prevDriver then
                -- Проверяем, есть ли ID предыдущего гонщика в побежденных
                for _, defeatedId in ipairs(player.defeated_drivers) do
                    if defeatedId == prevDriver.id then
                        canUnlock = true
                        break
                    end
                end
            end
        end

        if canUnlock then
            table.insert(unlockedBlacklist, driver)
        end
    end

    return {
        unlockedBlacklist = unlockedBlacklist,
        streetDrivers = streetDrivers,
        player = player
    }
end

return TougeLoader