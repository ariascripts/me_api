local API = require("api")

local Auras = {}

Auras.AURA = {
    DARK_MAGIC = {id = 22891, offset = 30},
    FESTIVE = {id = 26120, offset = 88},
    VAMPYRISM = {id = 22298, offset = 25},
}

function Auras.hasAura()
    return API.Buffbar_GetIDstatus(26098, false).id > 0
end

---@return number --time remaining in seconds, rounded down to the nearest minute/hour if the time remaining >= 1 minute/1 hour, respectively
function Auras.getTimeRemaining()
    local time = API.Buffbar_GetIDstatus(26098, false).conv_text
    local text = API.Buffbar_GetIDstatus(26098, false).text
    if string.find(text, "m") then
        return time * 60
    elseif string.find(text, "hr") then
        return time * 3600
    end
    return time
end

function Auras.isOpen()
    return API.VB_FindPSettinOrder(7647, 0).state ~= 2147483647 and API.VB_FindPSettinOrder(7647, 0).state > 0
end

function Auras.open()
    API.DoAction_Interface(0xffffffff,0xffffffff,1,1464,15,14,API.OFF_ACT_GeneralInterface_route)
end

function Auras.activate(aura)
    if aura ~= nil then
        print("Activating aura:", aura.id)
        Auras.open()
        API.DoAction_Interface(0xffffffff,aura.id,2,1929,95,aura.offset,API.OFF_ACT_GeneralInterface_route) --right click activate
        API.RandomSleep2(1000, 100, 100)
    else
        print("Aura is null")
    end
end

function Auras.deactivate(id)
    id = id or 22891 --I don't think the id matters, deactivating auras still worked even when the aura's id wasn't 22891
    API.DoAction_Interface(0xffffffff,id,6,1464,15,14,API.OFF_ACT_GeneralInterface_route2) --right click aura
    API.RandomSleep2(1000, 100, 100)
    API.DoAction_Interface(0xffffffff,0xffffffff,0,1188,8,-1,API.OFF_ACT_GeneralInterface_Choose_option) --select yes
end

return Auras