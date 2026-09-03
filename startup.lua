local printer = peripheral.find("printer")
local strings = require("cc.strings")
local hostname = "Fax_" .. os.getComputerID()

-- Open all attached modems automatically
for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" then
        rednet.open(side)
    end
end

print("Ready (ID: " .. os.getComputerID() + ")")

-- Function to receive faxes in the background (with self/ack filters)
function receiveFax()
    while true do
        local id, message = rednet.receive()
        local myID = os.getComputerID()
        
        -- Ignore messages from self and ignore ack confirmations
        if id and id ~= myID and message ~= "ack" then
            -- Send an acknowledgment back to the sender
            rednet.send(id, "ack")
            
            if printer then
                local wrappedLines = strings.wrap(tostring(message), 25)
                local totalPages = math.ceil(#wrappedLines / 21)
                
                for i = 1, totalPages do
                    if not printer.newPage() then
                        break
                    end
                    
                    printer.setPageTitle("Fax from #" .. id .. " Pg " .. i)
                    
                    for r = 1, 20 do
                        local currentLine = ((i - 1) * 21) + r
                        if wrappedLines[currentLine] then
                            printer.write(wrappedLines[currentLine])
                            local _, py = printer.getCursorPos()
                            printer.setCursorPos(1, py + 1)
                        end
                    end
                    printer.endPage()
                end
            end
        end
    end
end

-- Function to write and send faxes
function sendFax()
    while true do
        print("\nPress 'L' to write a fax.")
        local event, key = os.pullEvent("key")
        
        if keys.getName(key) == "l" then
            print("Enter Target Computer ID:")
            local targetInput = read()
            local target = tonumber(targetInput)
            
            if not target then
                print("Invalid ID number!")
            else
                print("Enter Message. Type '!send' on a new line when finished.")
                local message = {}
                
                -- Format header
                local header = "Fax From #" .. os.getComputerID()
                local spaces = 25 - #header
                if spaces > 0 then
                    header = string.rep(" ", math.floor(spaces / 2)) .. header .. string.rep(" ", math.ceil(spaces / 2))
                end
                message[1] = header
                message[2] = string.rep(" ", 25)
                
                -- Read body lines
                local idx = 3
                while true do
                    local line = read()
                    if line == "!send" then
                        break
                    end
                    
                    local linebatch = strings.wrap(line, 25)
                    for r = 1, #linebatch do
                        local text = linebatch[r]
                        message[idx] = text .. string.rep(" ", 25 - #text)
                        idx = idx + 1
                    end
                end
                
                local messageToSend = table.concat(message)
                print("Sending fax to Computer #" .. target .. "...")
                
                local success = false
                for attempt = 1, 5 do
                    rednet.send(target, messageToSend)
                    local ackId = rednet.receive(nil, 1)
                    if ackId == target then
                        print("Fax delivered successfully!")
                        success = true
                        break
                    end
                end
                
                if not success then
                    print("Failed: No response from target ID.")
                end
            end
        end
    end
end

-- Run receiver and sender simultaneously
parallel.waitForAll(receiveFax, sendFax)