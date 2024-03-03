local API = require("api")

InputText = {}

--credit to Pizzanova for much of the typing code
local function typeString(inputString)
    for i = 1, #inputString do
        local char = inputString:sub(i, i)
        API.KeyboardPress(char, 50, 100)
    end
end

local function getInputText()
    local inputTextIc = API.ScanForInterfaceTest2Get(false, {
        InterfaceComp5.new(1469,0,-1,-1,0),
        InterfaceComp5.new(1469,1,-1,0,0),
        InterfaceComp5.new(1469,4,-1,1,0)
    })
    if #inputTextIc > 0 then
        return API.ReadChars(inputTextIc[1].memloc + API.I_itemids3, 100)
    end
end

function InputText.isOpen()
    return API.Compare2874Status(10, false) or (API.VB_FindPSettinOrder(2873, -1).state == 10 and API.VB_FindPSettinOrder(2874, -1).state > 0)
end

function InputText.enterText(textToType)
    if InputText.isOpen() then
        local inputText = getInputText()
        print("inputText:", inputText)

        if inputText ~= nil and string.lower(inputText) == string.lower(textToType) then
            print("Confirming input")
            API.KeyboardPress2(13, 200, 50)
            API.RandomSleep2(3600, 1200, 1200)
            return true
        elseif inputText == "" then
            print("Typing string:", textToType)
            typeString(textToType)
            API.RandomSleep2(600, 50, 50)
        elseif inputText ~= "" and string.lower(inputText) ~= string.lower(textToType) then
            print("Incorrect input detected, pressing backspace:", inputText)
            API.KeyboardPress2(0x31, .6, .2) --type something random first because there's sometimes a glitched string
            for i = 1, 40 do
                API.KeyboardPress2(8, .6, .2) --8 = backspace key
            end
            API.RandomSleep2(5, 0, 0)

            print("Typing string:", string.lower(textToType))
            typeString(string.lower(textToType))
            API.RandomSleep2(600, 50, 50)
        else
            print("typing broke")
        end
    end
end

return InputText
