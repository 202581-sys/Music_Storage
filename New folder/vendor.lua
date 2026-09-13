local vendOne = peripheral.wrap("redstone_relay_46")
local vendTwo = peripheral.wrap("redstone_relay_47")
local vendThree = peripheral.wrap("redstone_relay_48")
local vendFour = peripheral.wrap("redstone_relay_49")
local turtle = peripheral.wrap("turtle_13")
local credits = 0
rednet.open("back")
turtle.reboot()
while true do
    print("Welcome to Trade Station Alpha!")
    print("Insert Credits, Then Type the Item ID.")
    local selection = math.ceil(tonumber(read()))
    if selection>4 or selection<1 then
        print("Error: Enter a valid order ID")
        os.sleep(2)
        os.reboot()
    end
    if selection==1 then
        rednet.send(2806,"count")
        local id, result=rednet.receive()
        if result<2000 then
            print("Insufficient Funds.")
        else
            vendOne.setOutput("bottom",true)
            os.sleep(0.1)
            vendOne.setOutput("bottom",false)
            print("Item Dispensed!")
            result=result-2000
        end
        while true do
            if result==0 then
                break
            else
                vendFour.setOutput("bottom",true)
                os.sleep(0.1)
                vendFour.setOutput("bottom",false)
                result=result-1000
            end
        end
    elseif selection==2 then
        rednet.send(2806,"count")
        local id, result=rednet.receive()
        if result<2000 then
            print("Insufficient Funds.")
        else
            vendTwo.setOutput("bottom",true)
            os.sleep(0.1)
            vendTwo.setOutput("bottom",false)
            print("Item Dispensed!")
            result=result-2000
        end
        while true do
            if result==0 then
                break
            else
                vendFour.setOutput("bottom",true)
                os.sleep(0.1)
                vendFour.setOutput("bottom",false)
                result=result-1000
            end
        end
    elseif selection==3 then
        rednet.send(2806,"count")
            local id, result=rednet.receive()
            if result<2000 then
                print("Insufficient Funds.")
            else
                vendThree.setOutput("bottom",true)
                os.sleep(0.1)
                vendThree.setOutput("bottom",false)
                print("Item Dispensed!")
                result=result-2000
            end
            while true do
                if result==0 then
                    break
                else
                    vendFour.setOutput("bottom",true)
                    os.sleep(0.1)
                    vendFour.setOutput("bottom",false)
                    result=result-1000
                end
            end
        
    end
end
    


