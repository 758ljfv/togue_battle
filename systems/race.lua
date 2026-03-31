-- systems/race.lua
local SaveModule = require("save.save")
local Cars = require("cars")

local Race = {}

-- Текущая активная гонка
local activeRace = nil

-- Конфигурация сложности
local difficultyModifiers = {
    street = { skillBonus = 0, moneyMultiplier = 1.0, repMultiplier = 1.0 },
    blacklist = { skillBonus = 10, moneyMultiplier = 2.0, repMultiplier = 3.0 }
}

-- Проверка наличия автомобиля у игрока перед гонкой
function Race.canStartRace(playerData)
    if not playerData then
        return false, "Данные игрока не загружены"
    end
    
    local owned_cars = playerData.owned_cars or {}
    if #owned_cars == 0 then
        return false, "У вас нет автомобилей! Купите машину в салоне."
    end
    
    if not playerData.active_car then
        return false, "Выберите автомобиль в гараже!"
    end
    
    -- Проверяем, существует ли активный автомобиль
    local car = Cars.get_car_by_id(playerData.active_car)
    if not car then
        return false, "Выбранный автомобиль не найден!"
    end
    
    return true, "Готов к гонке"
end

-- Инициализация гонки
function Race.start(opponent, raceType, playerData)
    -- Проверка возможности начать гонку
    local canStart, message = Race.canStartRace(playerData)
    if not canStart then
        print("Ошибка: " .. message)
        return false, message
    end
    
    if not opponent then
        print("Ошибка: соперник не указан!")
        return false, "Соперник не указан"
    end
    
    activeRace = {
        opponent = opponent,
        type = raceType or "street",
        startTime = os.time(),
        status = "active",
        playerData = playerData
    }
    
    print(string.format("=== ГОНКА НАЧАЛАСЬ ==="))
    print(string.format("Тип: %s", raceType))
    print(string.format("Соперник: %s", opponent.name))
    print(string.format("Трасса: %s", opponent.home_track or "akina"))
    print(string.format("Маршрут: %s", opponent.route or "downhill"))
    
    -- Здесь будет логика запуска гонки в Assetto Corsa
    -- contentManager.launchRace(...)
    
    return true, "Гонка началась"
end

-- Завершение гонки (вызывается после финиша)
function Race.finish(playerPosition, playerTime, opponentTime)
    if not activeRace then
        print("Ошибка: активная гонка не найдена!")
        return nil
    end
    
    local opponent = activeRace.opponent
    local raceType = activeRace.type
    local isWin = playerPosition == 1
    
    print(string.format("=== ГОНКА ЗАВЕРШЕНА ==="))
    print(string.format("Позиция: %d", playerPosition))
    print(string.format("Время игрока: %.3f", playerTime or 0))
    print(string.format("Время соперника: %.3f", opponentTime or 0))
    
    -- Обновление статистики
    local playerData = activeRace.playerData
    if isWin then
        SaveModule.addWin(playerData)
        
        -- Награды
        local diffMod = difficultyModifiers[raceType] or difficultyModifiers.street
        local moneyReward = math.floor((opponent.money_reward or 500) * diffMod.moneyMultiplier)
        local repReward = math.floor((opponent.reputation_reward or 1) * diffMod.repMultiplier)
        
        playerData.money = playerData.money + moneyReward
        playerData.reputation = playerData.reputation + repReward
        
        print(string.format("ПОБЕДА! +%d репутации, +$%d", repReward, moneyReward))
        
        -- Если это блэклист гонка - добавляем в побежденные
        if raceType == "blacklist" then
            table.insert(playerData.defeated_drivers, opponent.id)
            print(string.format("Босс %s побежден!", opponent.name))
            
            -- Проверка на разблокировку следующего ранга
            Race.checkBlacklistProgress(playerData)
        end
    else
        SaveModule.addLoss(playerData)
        print("ПОРАЖЕНИЕ. Попробуй еще раз!")
    end
    
    -- Сохранение прогресса
    SaveModule.save("save/player_data.json", playerData)
    
    activeRace = nil
    return {
        win = isWin,
        moneyEarned = isWin and math.floor((opponent.money_reward or 500) * difficultyModifiers[raceType].moneyMultiplier) or 0,
        repEarned = isWin and math.floor((opponent.reputation_reward or 1) * difficultyModifiers[raceType].repMultiplier) or 0
    }
end

-- Проверка прогресса в блэклисте
function Race.checkBlacklistProgress(playerData)
    local currentRank = playerData.stats.blacklist_rank
    
    -- Если победили текущего босса, повышаем ранг
    if currentRank > 1 then
        playerData.stats.blacklist_rank = currentRank - 1
        print(string.format("Новый ранг в блэклисте: #%d", playerData.stats.blacklist_rank))
        
        -- Проверка на разблокировку новой области при достижении 1 места
        if playerData.stats.blacklist_rank == 1 then
            print("!!! РАЗБЛОКИРОВАНА НОВАЯ ОБЛАСТЬ !!!")
            -- Используем систему Areas для разблокировки
            local Areas = require("systems.areas")
            Areas.setSaveData(playerData)
            Areas.unlockNextArea()
        end
    end
end

-- Отмена гонки (если игрок вышел)
function Race.cancel()
    if activeRace then
        print("Гонка отменена")
        activeRace = nil
    end
end

-- Получение активной гонки
function Race.getActive()
    return activeRace
end

return Race