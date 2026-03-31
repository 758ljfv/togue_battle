-- src/main.lua
local Loader = require("systems.touge_loader")

local Game = {}

function Game.init()
    print("=== Touge Battles Started ===")

    -- Инициализация загрузчика для трассы Akina
    local sessionData = Loader.init("akina")

    if not sessionData then
        print("Critical Error: Failed to load session data.")
        return
    end

    local player = sessionData.player
    print("Player: " .. player.name .. " | Money: " .. player.money)

    -- Вывод доступных соперников
    print("\n=== Available Blacklist ===")
    for _, d in ipairs(sessionData.unlockedBlacklist) do
        print(string.format("[%d] %s (%s)", d.blacklist_position, d.name, d.car_id))
    end

    print("\n=== Street Drivers ===")
    for _, d in ipairs(sessionData.streetDrivers) do
        print(string.format("[-] %s (%s)", d.name, d.car_id))
    end

    -- Пример выбора случайного
    if #sessionData.streetDrivers > 0 then
        local randomIdx = math.random(1, #sessionData.streetDrivers)
        local rival = sessionData.streetDrivers[randomIdx]
        print("\nTraining Rival Selected: " .. rival.name)
    end
end

return Game