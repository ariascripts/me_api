local API = require("api")

Equipment = {}

local MIN_SLOT, MAX_SLOT = 0, 12

--slot = equip slot number for API.GetEquipSlot
--index = interface index for interacting with the item
local SLOTS = {
    HELM = {slot = 0, index = 0},
    CAPE = {slot = 1, index = 1},
    AMULET = {slot = 2, index = 2},
    WEAPON = {slot = 3, index = 3},
    BODY = {slot = 4, index = 4},
    OFFHAND = {slot = 5, index = 5},
    BOTTOM = {slot = 6, index = 7},
    GLOVES = {slot = 7, index = 9},
    BOOTS = {slot = 8, index = 10},
    RING = {slot = 9, index = 12},
    AMMO = {slot = 10, index = 13},
    AURA = {slot = 11, index = 14},
    POCKET = {slot = 12, index = 17},
}

--This function will always return false if the GE is open
---@param id number
function Equipment.contains(id)
    for i = MIN_SLOT, MAX_SLOT do
        local item = API.GetEquipSlot(i)
        if item ~= nil then
            if item.itemid1 > 0 and item.itemid1 == id then return true end
        end
    end
    return false
end

---@param ids table --list of ids
function Equipment.containsAllOf(ids)
    for _, id in ipairs(ids) do
        if not Equipment.contains(id) then return false end
    end
    return true
end

---@param ids table --list of ids
function Equipment.containsAnyOf(ids)
    for _, id in ipairs(ids) do
        if Equipment.contains(id) then return true end
    end
    return false
end

---@param ids table --list of ids, must be an exact match
function Equipment.containsOnly(ids)
    local equips = {}
    local count = 0
    for i = MIN_SLOT, MAX_SLOT do
        local item = API.GetEquipSlot(i)
        if item.itemid1 > 0 then
            equips[item.itemid1] = true
            count = count + 1
        end
    end

    for _, id in ipairs(ids) do
        if equips[id] == nil then
            return false
        elseif equips[id] then --ignore duplicate ids
            equips[id] = false
            count = count - 1
        end
    end
    return count == 0 --if count > 0, that means there were other equips not in `ids`
end

---@param ids table|nil
function Equipment.getQuantity(ids)
    local equips = {}
    local count = 0
    for i = MIN_SLOT, MAX_SLOT do
        local item = API.GetEquipSlot(i)
        if item.itemid1 > 0 then
            equips[item.itemid1] = true
            count = count + 1
        end
    end
    if not ids then
        return count
    end

    local res = 0
    for _, id in ipairs(ids) do
        if equips[id] then --ignore duplicate ids
            equips[id] = false
            res = res + 1
        end
    end
    return res
end

function Equipment.isEmpty()
    for i = MIN_SLOT, MAX_SLOT do
        local item = API.GetEquipSlot(i)
        if item.itemid1 > 0 then return false end
    end
    return true
end

local function getId(slot) return API.GetEquipSlot(slot.slot).itemid1 end

function Equipment.getHelm() return getId(SLOTS.HELM) end
function Equipment.getCape() return getId(SLOTS.CAPE) end
function Equipment.getAmulet() return getId(SLOTS.AMULET) end
function Equipment.getWeapon() return getId(SLOTS.WEAPON) end
function Equipment.getBody() return getId(SLOTS.BODY) end
function Equipment.getOffhand() return getId(SLOTS.OFFHAND) end
function Equipment.getBottom() return getId(SLOTS.BOTTOM) end
function Equipment.getGloves() return getId(SLOTS.GLOVES) end
function Equipment.getBoots() return getId(SLOTS.BOOTS) end
function Equipment.getRing() return getId(SLOTS.RING) end
function Equipment.getAmmo() return getId(SLOTS.AMMO) end
function Equipment.getAura() return getId(SLOTS.AURA) end
function Equipment.getPocket() return getId(SLOTS.POCKET) end

local function unequip(slot)
    local itemID = getId(slot)
    if itemID > 0 then
        return API.DoAction_Interface(0xffffffff,itemID,1,1464,15,slot.index,API.OFF_ACT_GeneralInterface_route)
    end
end

function Equipment.unequipHelm() return unequip(SLOTS.HELM) end
function Equipment.unequipCape() return unequip(SLOTS.CAPE) end
function Equipment.unequipAmulet() return unequip(SLOTS.AMULET) end
function Equipment.unequipWeapon() return unequip(SLOTS.WEAPON) end
function Equipment.unequipBody() return unequip(SLOTS.BODY) end
function Equipment.unequipOffhand() return unequip(SLOTS.OFFHAND) end
function Equipment.unequipBottom() return unequip(SLOTS.BOTTOM) end
function Equipment.unequipGloves() return unequip(SLOTS.GLOVES) end
function Equipment.unequipBoots() return unequip(SLOTS.BOOTS) end
function Equipment.unequipRing() return unequip(SLOTS.RING) end
function Equipment.unequipAmmo() return unequip(SLOTS.AMMO) end
function Equipment.unequipPocket() return unequip(SLOTS.POCKET) end

return Equipment
