local API = require("api")
local InputText = require("libraries.InputText")

Bank = {}

function Bank.isOpen()
    return API.BankOpen2()
end

function Bank.depositInventory()
    return API.DoAction_Interface(0xffffffff,0xffffffff,1,517,39,-1,API.OFF_ACT_GeneralInterface_route)
end

function Bank.depositEquipment()
    return API.DoAction_Interface(0xffffffff,0xffffffff,1,517,42,-1,API.OFF_ACT_GeneralInterface_route)
end

function Bank.depositFamiliar()
    return API.DoAction_Interface(0xffffffff,0xffffffff,1,517,45,-1,API.OFF_ACT_GeneralInterface_route)
end

local function split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function Bank.getCleanName(name)
    local parts = split(name, ">")
    if #parts >= 2 then
        name = parts[2]
    end
    return name
end

local function itemNameMatches(item, name, contains)
    local __name = Bank.getCleanName(item.textitem)
    if __name == name or (contains and string.find(__name, name)) then
        return true
    end
end

local function itemMatches(item, nameOrId, contains)
    if item.itemid1_size > 0 and item.itemid1 > 0 then
        if item.itemid1 == nameOrId then
            return true
        elseif type(nameOrId) == "string" then
            return itemNameMatches(item, nameOrId, contains)
        end
    end
end

local function itemMatchesSet(item, set)
    return item.itemid1_size > 0 and (set[item.itemid1] or set[Bank.getCleanName(item.textitem)])
end

local function getCount_id(id)
    return API.BankGetItemStack1(id)
end

---@param arg string|number|nil
---@param contains boolean optional
---@return integer --ignores placeholders
function Bank.getCount(arg, contains)
    if type(arg) == "number" then
        return getCount_id(arg)
    end
    local count = 0
    local items = API.FetchBankArray()
    for _, item in ipairs(items) do
        if item.itemid1 > 0 and item.itemid1_size > 0 then
            if arg == nil then
                count = count + 1
            elseif itemNameMatches(item, arg, contains) then
                count = count + item.itemid1_size
            end
        end
    end
    return count
end

---@param arg string|number
---@param contains boolean optional
function Bank.contains(arg, contains)
    return Bank.getCount(arg, contains) > 0
end

---@param list table --list of strings or numbers
function Bank.containsAny(list)
    for _, nameOrId in ipairs(list) do
        if Bank.contains(nameOrId) then return true end
    end
end

---@param list table --list of strings or numbers
function Bank.containsAll(list)
    for _, nameOrId in ipairs(list) do
        if not Bank.contains(nameOrId) then return false end
    end
    return true
end

---@param nameOrId string|number
---@param contains boolean optional
function Bank.getInvCount(nameOrId, contains)
    local items = API.FetchBankInvArray()
    local count = 0
    for _, item in ipairs(items) do
        if item.itemid1_size > 0 and item.itemid1 > 0 then
            if nameOrId == nil then
                count = count + 1
            elseif item.itemid1 == nameOrId then
                count = count + item.itemid1_size
            elseif type(nameOrId) == "string" and itemNameMatches(item, nameOrId, contains) then
                count = count + item.itemid1_size
            end
        end
    end
    return count
end

local function doActionBankIfMatch(nameOrId, item, contains, index, route)
    if itemMatches(item, nameOrId, contains) then
        return API.DoAction_Bank(item.itemid1, index, route)
    end
end

local function doActionBankInvIfMatch(nameOrId, item, contains, index, route)
    if itemMatches(item, nameOrId, contains) then
        return API.DoAction_Bank_Inv(item.itemid1, index, route)
    end
end

local function withdraw(nameOrId, contains, index)
    local items = API.FetchBankArray()
    for _, item in ipairs(items) do
        local ret = doActionBankIfMatch(nameOrId, item, contains, index, API.OFF_ACT_GeneralInterface_route)
        if ret ~= nil then
            return ret
        end
    end
end

function Bank.withdrawOne(nameOrId, contains)
    print("Withdrawing one:", nameOrId)
    return withdraw(nameOrId, contains, 2)
end

function Bank.withdrawFive(nameOrId, contains)
    print("Withdrawing five:", nameOrId)
    return withdraw(nameOrId, contains, 3)
end

function Bank.withdrawTen(nameOrId, contains)
    print("Withdrawing 10:", nameOrId)
    return withdraw(nameOrId, contains, 4)
end

function Bank.withdrawFifty(nameOrId, contains)
    print("Withdrawing 50:", nameOrId)
    return withdraw(nameOrId, contains, 5)
end

function Bank.withdrawX(nameOrId, quantity, contains)
    print("Withdrawing " .. quantity .. " of: " .. nameOrId)
    if InputText.isOpen() then
        return InputText.enterText(tostring(quantity))
    else
        if withdraw(nameOrId, contains, 6) then
            API.RandomSleep2(2400, 1200, 1200)
            if InputText.isOpen() then
                return InputText.enterText(tostring(quantity))
            end
        end
    end
    return withdraw(nameOrId, contains, 6)
end

function Bank.withdrawAll(nameOrId, contains)
    print("Withdrawing all:", nameOrId)
    return withdraw(nameOrId, contains, 7)
end

---@param nameOrId string|number
---@param quantity number optional
---@param contains boolean optional
function Bank.withdraw(nameOrId, quantity, contains)
    if quantity == nil or quantity <= 0 then
        return Bank.withdrawAll(nameOrId, contains)
    elseif quantity == 1 then
        return Bank.withdrawOne(nameOrId, contains)
    elseif quantity == 5 then
        return Bank.withdrawFive(nameOrId, contains)
    elseif quantity == 10 then
        return Bank.withdrawTen(nameOrId, contains)
    elseif quantity == 50 then
        return Bank.withdrawFifty(nameOrId, contains)
    else
        return Bank.withdrawX(nameOrId, quantity, contains)
    end
end

---@param nameOrId string|number
---@param contains boolean optional
function Bank.deposit(nameOrId, contains)
    print("Depositing:", nameOrId)

    local items = API.FetchBankInvArray()
    for _, item in ipairs(items) do
        local ret = doActionBankInvIfMatch(nameOrId, item, contains, 7, API.OFF_ACT_GeneralInterface_route2)
        if ret ~= nil then
            return ret
        end
    end
end

---@param list table --list of strings or numbers
function Bank.depositAll(list)
    for _, nameOrId in ipairs(list) do
        Bank.deposit(nameOrId)
    end
end

---@param list table --list of strings or numbers
function Bank.depositAllExcept(list)
    local set = {}
    for _, value in ipairs(list) do
        set[value] = true
    end

    local items = API.FetchBankInvArray()
    for _, item in ipairs(items) do
        if not itemMatchesSet(item, set) then
            doActionBankInvIfMatch(item.itemid1, item, false, 7, API.OFF_ACT_GeneralInterface_route2)
        end
    end
end

---@param nameOrId string|number
---@param contains boolean optional
function Bank.equip(nameOrId, contains)
    print("Equipping:", nameOrId)

    local items = API.FetchBankArray()
    for _, item in ipairs(items) do
        local ret = doActionBankIfMatch(nameOrId, item, contains, 9, API.OFF_ACT_GeneralInterface_route2)
        if ret ~= nil then
            return ret
        end
    end
end

---@param nameOrId string|number
---@param contains boolean optional
function Bank.equipFromInventory(nameOrId, contains)
    print("Equipping:", nameOrId)

    local items = API.FetchBankInvArray()
    for _, item in ipairs(items) do
        local ret = doActionBankInvIfMatch(nameOrId, item, contains, 8, API.OFF_ACT_GeneralInterface_route2)
        if ret ~= nil then
            return ret
        end
    end
end

function Bank.close()
    return API.DoAction_Interface(0x24,0xffffffff,1,517,306,-1,API.OFF_ACT_GeneralInterface_route)
end

--#region bank presets

function Bank.isPresetTabSelected()
    return (API.VB_FindPSettinOrder(6680, -1).state & 4096) == 4096 --vb 45223
end

function Bank.selectPresetTab()
    return API.DoAction_Interface(0x2e,0xffffffff,1,517,145,-1,API.OFF_ACT_GeneralInterface_route)
end

function Bank.selectTransferTab()
    return API.DoAction_Interface(0x2e,0xffffffff,1,517,144,-1,API.OFF_ACT_GeneralInterface_route)
end

function Bank.loadPreset(num) --supports 1 to 9
    return API.DoAction_Interface(0x24,0xffffffff,1,517,119,num,API.OFF_ACT_GeneralInterface_route)
end

function Bank.savePreset(num)
    if Bank.isPresetTabSelected() then
        print("Saving preset " .. num)
        API.DoAction_Interface(0xffffffff,0xffffffff,2,517,119,num,API.OFF_ACT_GeneralInterface_route)
    else
        print("Selecting preset tab")
        Bank.selectPresetTab()
    end
end

function Bank.saveFamiliarPreset()
    API.DoAction_Interface(0xffffffff,0xffffffff,2,517,119,10,API.OFF_ACT_GeneralInterface_route)
end
--#endregion

--#region Bank mini tabs (the tabs at the top right of the bank interface, not the tabs in the item viewport)
--idk what the "proper" name for them is I just call them mini tabs because they're smaller than regular tabs

function Bank.selectInventoryTab()
    return API.DoAction_Interface(0x24,0xffffffff,1,517,56,-1,API.OFF_ACT_GeneralInterface_route)
end

function Bank.selectEquipmentTab()
    return API.DoAction_Interface(0x24,0xffffffff,1,517,60,-1,API.OFF_ACT_GeneralInterface_route)
end

function Bank.selectSummonTab()
    return API.DoAction_Interface(0x24,0xffffffff,1,517,64,-1,API.OFF_ACT_GeneralInterface_route)
end

function Bank.getCurrentMiniTab() --0 = inventory, 1 = summoning, 2 = equipment
    return API.VB_FindPSettinOrder(6680, -1).state & 3
end
--#endregion

--#region Withdraw mode

function Bank.isWithdrawModeNoted()
    return API.VB_FindPSettinOrder(160, -1).state & 1 == 1
end

function Bank.setWithdrawMode(noted)
    if Bank.isWithdrawModeNoted() ~= noted then
        return API.DoAction_Interface(0xffffffff,0xffffffff,1,517,127,-1,API.OFF_ACT_GeneralInterface_route)
    end
    return true
end
--#endregion

return Bank