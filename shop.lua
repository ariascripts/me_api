local API = require("api")
local SHOP = {}

local SHOP_CONTAINER = 1265

SHOP.BUY_OPTIONS = {
  ONE = 2,
  FIVE = 3,
  TEN = 4,
  FIFTY = 5,
  FIVE_HUNDRED = 6,
  ALL = 7 
}

--- `shop_index` = index of the item in the shop's list of items (0 based)
--- i.e. the first item in the shop has an shop_index of 0
local function getItemIC(shop_index)
  return API.ScanForInterfaceTest2Get(false, {
    InterfaceComp5.new(SHOP_CONTAINER,7,-1,-1,0), 
    InterfaceComp5.new(SHOP_CONTAINER,9,-1,7,0), 
    InterfaceComp5.new(SHOP_CONTAINER,10,-1,9,0), 
    InterfaceComp5.new(SHOP_CONTAINER,12,-1,10,0), 
    InterfaceComp5.new(SHOP_CONTAINER,19,-1,12,0),
    InterfaceComp5.new(SHOP_CONTAINER,24,-1,19,0),
    InterfaceComp5.new(SHOP_CONTAINER,24,shop_index,24,0),
  }) 
end

--- `sample_index` = index of the item in the shop's list of free samples (0 based)
local function getFreeSampleItemIC(sample_index)
  return API.ScanForInterfaceTest2Get(false, {
    InterfaceComp5.new(SHOP_CONTAINER,7,-1,-1,0), 
    InterfaceComp5.new(SHOP_CONTAINER,9,-1,7,0), 
    InterfaceComp5.new(SHOP_CONTAINER,10,-1,9,0), 
    InterfaceComp5.new(SHOP_CONTAINER,12,-1,10,0), 
    InterfaceComp5.new(SHOP_CONTAINER,13,-1,12,0),
    InterfaceComp5.new(SHOP_CONTAINER,17,-1,13,0),
    InterfaceComp5.new(SHOP_CONTAINER,17,sample_index,17,0),
  }) 
end

function SHOP.isOpen() 
  return API.VB_FindPSett(2874, 0).SumOfstate == 18 --Value of varbit was 18 when the shops I tried are open, this varbit is also used for the lodestone interface
end

---@param shop_index number
---@return number
function SHOP.getItemId(shop_index)
  ic = getItemIC(shop_index)
    
  if (#ic > 0 and ic[1].itemid1 > 0) then
    return ic[1].itemid1
  end
  return -1
end

---@param shop_index number
---@return number
function SHOP.getStackSize(shop_index)
  ic = getItemIC(shop_index) 
    
  if (#ic > 0 and ic[1].itemid1 > 0) then
    return ic[1].itemid1_size
  end
  return -1
end

---price of the item may contain a non numeric char i.e. K or M
---@param shop_index number
---@return string
function SHOP.getPrice(shop_index)
  ic = API.ScanForInterfaceTest2Get(false, {
    InterfaceComp5.new(SHOP_CONTAINER,7,-1,-1,0), 
    InterfaceComp5.new(SHOP_CONTAINER,9,-1,7,0), 
    InterfaceComp5.new(SHOP_CONTAINER,10,-1,9,0), 
    InterfaceComp5.new(SHOP_CONTAINER,12,-1,10,0), 
    InterfaceComp5.new(SHOP_CONTAINER,19,-1,12,0),
    InterfaceComp5.new(SHOP_CONTAINER,21,-1,19,0),
    InterfaceComp5.new(SHOP_CONTAINER,21,shop_index,21,0),
  }) 
    
  if (#ic > 0) then
    text = string.sub(API.ReadCharsPointer(ic[1].memloc + API.I_itemids3), 1, 8)
    return text
  end
  return nil
end

---@param sample_index number
---@return number
function SHOP.getFreeSampleItemId(sample_index)
  ic = getFreeSampleItemIC(sample_index)
    
  if (#ic > 0 and ic[1].itemid1 > 0) then
    return ic[1].itemid1
  end
  return -1
end

---@param sample_index number
---@return number
function SHOP.getFreeSampleStackSize(sample_index)
  ic = getFreeSampleItemIC(sample_index) 
    
  if (#ic > 0 and ic[1].itemid1 > 0) then
    return ic[1].itemid1_size
  end
  return -1
end

---Returns the items the shop has for sale
---@return vector<number, number, string>
function SHOP.getItems()
  items = {}

  for i = 0, 99 do --99 was chosen arbitrarily, I don't think any store in RS has that many items in stock
    ic = getItemIC(i)

    if (#ic > 0 and ic[1].itemid1 > 0) then
      table.insert(items, {
        itemid1 = ic[1].itemid1,
        itemid1_size = ic[1].itemid1_size,
        price = SHOP.getPrice(i)
      })
    else
      break
    end   
  end

  return items
end

---Returns the free samples available from the shop
---@return vector<number, number>
function SHOP.getFreeSamples()
  items = {}

  for i = 0, 10 do --10 was chosen arbitrarily, I don't think any store in RS has that many free samples available
    ic = getFreeSampleItemIC(i)

    if (#ic > 0 and ic[1].itemid1 > 0) then
      table.insert(items, {
        itemid1 = ic[1].itemid1,
        itemid1_size = ic[1].itemid1_size
      })
    else
      break
    end   
  end

  return items
end

---The position of the "All" option changes based on the number of items in stock
---@return number
local function getAllOptionIndex(index, is_free_sample)
  stackSize = 0
  if is_free_sample then
    stackSize = SHOP.getFreeSampleStackSize(index)
  else
    stackSize = SHOP.getStackSize(index)
  end
  
  if stackSize <= 0 then
    return -1
  elseif stackSize == 1 then
    return 2
  elseif stackSize < 5 then
    return 3
  elseif stackSize < 10 then
    return 4
  elseif stackSize < 50 then
    return 5
  elseif stackSize < 500 then
    return 6
  end
  return 7
end

---@param shop_index number
---@param buy_option number
---@return boolean
function SHOP.buyItem(shop_index, buy_option)
  if buy_option > SHOP.BUY_OPTIONS.ALL or buy_option < SHOP.BUY_OPTIONS.ONE then
    print("Invalid value provided for `buy_option`")
    return false
  end
  
  if buy_option == SHOP.BUY_OPTIONS.ALL then
    buy_option = getAllOptionIndex(shop_index, false)
    if buy_option == -1 then
      print("Unable to find item at index:", shop_index)
      return false
    end
  end
  return API.DoAction_Interface(0xffffffff,0xffffffff,buy_option,SHOP_CONTAINER,20,shop_index,5392)
end

---@param sample_index number
---@return boolean
function SHOP.takeFreeSample(sample_index)
  optionIndex = getAllOptionIndex(sample_index, true)
  if optionIndex == -1 then
    print("Unable to find free sample at index:", sample_index)
    return false
  end
  return API.DoAction_Interface(0xffffffff,0xffffffff,optionIndex,SHOP_CONTAINER,14,sample_index,5392)
end

---Claims all free samples available
function SHOP.takeFreeSamples()
  for i = 0, 10 do --10 was chosen arbitrarily, I don't think any store in RS has that many free samples available
    if SHOP.getFreeSampleStackSize(i) > 0 then
      SHOP.takeFreeSample(i)
    end
  end
end

return SHOP
