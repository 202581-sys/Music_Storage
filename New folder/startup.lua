-- startup.lua (Turtle)

-- Open Rednet on connected modem
peripheral.find("modem", rednet.open)

-- Wrap input and output containers
local chest = peripheral.wrap("front")
local barrel = peripheral.wrap("back")

if not chest then
    print("Warning: No chest found on FRONT!")
end

if not barrel then
    print("Warning: No barrel found on BACK!")
end

print("Turtle Ready. Listening for Vendor commands...")

while true do
    -- Wait for count request from vendor
    local senderID, message = rednet.receive()

    if message == "count" then
        local credits = 0
        
        -- Re-wrap inventories in case blocks were replaced
        chest = peripheral.wrap("front")
        barrel = peripheral.wrap("back")

        if chest and barrel then
            local barrelName = peripheral.getName(barrel)
            
            -- Transfer items from Chest directly into Barrel
            for slot, item in pairs(chest.list()) do
                local moved = chest.pushItems(barrelName, slot)
                credits = credits + (moved * 1000)
            end
        else
            print("Error: Chest or Barrel missing during count.")
        end

        -- Send total credits back to the vendor
        rednet.send(senderID, credits)
        print("Count complete. Sent " .. credits .. " credits to Computer " .. senderID)
    end
end