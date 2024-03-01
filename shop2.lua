--This is for special shops like the one in War's Retreat, they usually use special currency
local API = require("api")

local Shop2 = {}

Shop2.BUY_OPTIONS = {
  ONE = 1,
  FIVE = 2,
  TEN = 3,
  BUY_X = 4,
}

--only tested for shops with up to four tabs
local function getTabVal(tab_num)
    return 19 - (tab_num * 2)
end

---@return number --zero indexed
function Shop2.getCurrentTab()
    return API.VB_FindPSettinOrder(5147, 0).state
end

---@return boolean
function Shop2.isOpen()
    return API.Compare2874Status(18, false) and API.VB_FindPSettinOrder(5147, 0).state > 0
end

---comment
---@param tab_num number --zero indexed
---@param index number --zero indexed
---@param tab_val number|nil --this changes based on tab
---@param option number|nil --buy option, this may vary based on shop
function Shop2.buyItem(tab_num, index, tab_val, option)
    option = option or 1
    tab_val = tab_val or getTabVal(tab_num)
    if Shop2.getCurrentTab() == tab_num then
        API.DoAction_Interface(0x24,0xffffffff,option,1594,tab_val,index,API.OFF_ACT_GeneralInterface_route) --purchase item
        API.RandomSleep2(1200, 100, 100)
        API.DoAction_Interface(0x24,0xffffffff,1,1594,54,-1,API.OFF_ACT_GeneralInterface_route) --confirm
        API.RandomSleep2(1200, 100, 100)
    else
        API.DoAction_Interface(0x2e,0xffffffff,1,1594,tab_num,-1,API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(600, 100, 100)
    end
end

return Shop2
