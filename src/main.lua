-- src/main.lua
local Loader = require("systems.touge_loader")
local Menu = require("ui.menu")
local SaveModule = require("save.save")

local Game = {}

-- Состояние игры
local gameState = {
    sessionData = nil,
    menuInitialized = false
}

-- Хук для рендеринга UI
local function onRender()
    if Menu.isVisible() then
        Menu.render()
    end
end

-- Хук для обработки мыши
local function onMouseMoved(x, y)
    if Menu.isVisible() then
        Menu.mouseMoved(x, y)
    end
end

local function onMousePressed(x, y, button)
    if Menu.isVisible() then
        Menu.mousePressed(x, y, button)
    end
end

-- Хук клавиатуры (для выхода по ESC)
local function onKeyPressed(key)
    if key == 283 and Menu.isVisible() then -- ESC key
        Menu.hide()
    end
end

function Game.init()
    print("=== Touge Battles Started ===")

    -- Инициализация загрузчика для трассы Akina
    local sessionData = Loader.init("akina")

    if not sessionData then
        print("Critical Error: Failed to load session data.")
        return
    end

    -- Сохраняем данные сессии
    gameState.sessionData = sessionData

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

    -- Инициализация меню (передаем ссылку на Game модуль)
    Menu.show(sessionData, Game)
    gameState.menuInitialized = true

    -- Регистрация хуков
    ac.registerRenderCallback(onRender)
    ac.registerMouseMovedCallback(onMouseMoved)
    ac.registerMousePressedCallback(onMousePressed)
    ac.registerKeyPressedCallback(onKeyPressed)

    print("\n=== Menu Initialized ===")
    print("Press ESC to toggle menu")
end

-- Функция для запуска гонки (будет вызываться из меню)
function Game.startRace(opponent, raceType)
    if not gameState.sessionData then
        print("Error: No session data!")
        return
    end

    print(string.format("\n=== STARTING %s RACE ===", raceType:upper()))
    print(string.format("Opponent: %s", opponent.name))
    print(string.format("Car: %s", opponent.car_id))
    
    -- Здесь будет логика запуска гонки
    -- RaceModule.start(opponent, raceType)
    
    -- Для теста скрываем меню
    Menu.hide()
end

return Game