-- systems/areas.lua
local Areas = {}

local areasData = nil
local saveData = nil

function Areas.load()
    local file = io.open("data/areas.json", "r")
    if file then
        local content = file:read("*all")
        file:close()
        areasData = json.decode(content)
        print("Areas loaded: " .. #areasData.areas .. " areas")
    else
        print("Error: Could not load data/areas.json")
        areasData = { areas = {} }
    end
end

function Areas.setSaveData(data)
    saveData = data
end

function Areas.getAllAreas()
    return areasData.areas or {}
end

function Areas.getAreaById(areaId)
    for _, area in ipairs(areasData.areas) do
        if area.id == areaId then
            return area
        end
    end
    return nil
end

function Areas.isAreaUnlocked(areaId)
    if not saveData then return false end
    
    local currentUnlocked = saveData.stats.area_unlocked or "akina"
    local area = Areas.getAreaById(areaId)
    if not area then return false end
    
    -- Область разблокирована, если её порядок <= порядку текущей разблокированной
    local currentArea = Areas.getAreaById(currentUnlocked)
    if currentArea then
        return area.order <= currentArea.order
    end
    
    return areaId == "akina"
end

function Areas.unlockNextArea()
    if not saveData then return false end
    
    local currentUnlocked = saveData.stats.area_unlocked or "akina"
    local currentArea = Areas.getAreaById(currentUnlocked)
    
    if not currentArea then return false end
    
    -- Найти следующую область
    local nextOrder = currentArea.order + 1
    for _, area in ipairs(areasData.areas) do
        if area.order == nextOrder then
            -- Разблокировать следующую область
            saveData.stats.area_unlocked = area.id
            SaveModule.save(nil, saveData)
            print("Area unlocked: " .. area.name)
            return true
        end
    end
    
    return false -- Нет следующей области
end

function Areas.getCurrentArea()
    if not saveData then return nil end
    local currentUnlocked = saveData.stats.area_unlocked or "akina"
    return Areas.getAreaById(currentUnlocked)
end

function Areas.getRacersForArea(areaId, includeLocked)
    local area = Areas.getAreaById(areaId)
    if not area then return {} end
    
    -- Проверка на разблокировку
    if not includeLocked and not Areas.isAreaUnlocked(areaId) then
        return {}
    end
    
    return area.racers or {}
end

function Areas.getBossForArea(areaId)
    local area = Areas.getAreaById(areaId)
    if not area then return nil end
    return area.boss_id
end

return Areas
