local API = require("api")

CreationInterface = {}

local COMBO_BOX = 893 --this changes quite often

local function getItemIC(container_index)
    return API.ScanForInterfaceTest2Get(false, {
        {1371,7,-1,-1,-1},
        {1371,0,-1,7,-1},
        {1371,15,-1,0,-1},
        {1371,21,-1,15,-1},
        {1371,22,-1,21,-1},
        {1371,22,container_index,22,-1},
    })
end

local function getDropdownIC(index)
    return API.ScanForInterfaceTest2Get(false, {
        {1477,887,-1,-1,-1},
        {1477,890,-1,887,-1},
        {1477,892,-1,890,-1},
        {1477,892,index,892,-1},
    })
end

function CreationInterface.getSelectedItemId()
    return API.VB_FindPSettinOrder(1170, 0).state
end

function CreationInterface.isCreationInterfaceOpen()
    return CreationInterface.getSelectedItemId() ~= -1 and (API.Compare2874Status(18, false) or API.Compare2874Status(40, false))
end

---@return table --list of item ids
function CreationInterface.getItems()
    local items = {}

    for i = 0, 99 do --increase if there's more items
        local container_index = 2 + i * 4
        local ic = getItemIC(container_index)

        if (#ic > 0 and ic[1].itemid1 > 0) then
            table.insert(items, ic[1].itemid1)
        else
            break
        end
    end
    return items
end

---@return string|nil
function CreationInterface.getCurrentCategory()
    local ic = API.ScanForInterfaceTest2Get(false, {
        {1371,7,-1,-1,-1},
        {1371,0,-1,7,-1},
        {1371,15,-1,0,-1},
        {1371,25,-1,15,-1},
        {1371,10,-1,25,-1},
        {1371,11,-1,10,-1},
        {1371,27,-1,11,-1},
        {1371,27,3,27,-1},
    })
    if #ic > 0 then
        return API.ReadCharsPointer(ic[1].memloc + API.I_itemids3)
    end
end

---@param name string
---@return boolean
function CreationInterface.selectCategory(name)
    API.DoAction_Interface(0x2e,0xffffffff,1,1371,28,-1,API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(300, 50, 50)
    for i = 0, 15 do
        local ic = getDropdownIC(i)
        if #ic > 0 then
            local optionText = string.sub(API.ReadCharsPointer(ic[1].memloc + API.I_itemids3), 1, 50)
            if optionText == name then
                print("Selecting category: " .. name)
                API.DoAction_Interface(0xffffffff,0xffffffff,1,1477,COMBO_BOX,i * 2 + 1,API.OFF_ACT_GeneralInterface_route)
                return true
            end
        end
    end
    return false
end

---@param item_id number
--Warning: the item id returned by `CreationInterface.getSelectedItemId` may be different than the item id of the component
--<br>i.e. for Sign of the porter IV, `CreationInterface.getSelectedItemId` returns 39493, but the component item id is 29281
function CreationInterface.selectItem(item_id)
    if type(item_id) ~= "number" then
        print("Invalid argument for CreationInterface.selectItem: expected number but found " .. type(item_id))
        return
    end

    for i = 0, 99 do --increase if there's more items
        local container_index = 2 + i * 4
        local ic = getItemIC(container_index)

        if (#ic > 0) then
            if ic[1].itemid1 == item_id then
                print("Selecting item: " .. item_id)
                return API.DoAction_Interface(0xffffffff,0xffffffff,1,1371,22,container_index - 1,API.OFF_ACT_GeneralInterface_route)
            end
        else
            break
        end
    end
    print("Unable to find item: " .. item_id)
end

--use for items that `CreationInterface.selectItem` doesn't work for
function CreationInterface.selectByIndex(index)
    return API.DoAction_Interface(0xffffffff,0xffffffff,1,1371,22,index,API.OFF_ACT_GeneralInterface_route)
end

--Interacts with the "craft" button
function CreationInterface.process()
    return API.DoAction_Interface(0xffffffff,0xffffffff,0,1370,30,-1,API.OFF_ACT_GeneralInterface_Choose_option)
end

--This only works for items that `CreationInterface.selectItem` supports
---@param item_id number
---@param category string --optional
function CreationInterface.selectAndProcess(item_id, category)
    if category and CreationInterface.getCurrentCategory() ~= category then
        CreationInterface.selectCategory(category)
    else
        if CreationInterface.getSelectedItemId() == item_id then
            return CreationInterface.process()
        else
            CreationInterface.selectItem(item_id)
        end
    end
end

return CreationInterface
