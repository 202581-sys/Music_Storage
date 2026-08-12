local printer = peripheral.find("printer")
local strings = require("cc.strings")
local hostname
function newLine()
    setCursorPos(1, (getCursorPos()-1))
end
function getHostname()
    hostname=read()
end
function checkIfPresent()
    os.sleep(20)
    print("No User Detected, no Hostname Assigned")
    hostname=nil
end
peripheral.find("modem", rednet.open)
print("Enter Hostname")
parallel.waitForAny(getHostName(),checkIfPresent())
rednet.host("Fax",hostname)
local machines=rednet.lookup("Fax",nil,5)
print("Fax IDs:")
for i=1,#machines do
    print(machines[i])
end
function receiveFax()
    while true do
        local id, message=rednet.receive("Fax",5)
        if id then 
            rednet.send(id,"ack")
            local wrappedLines=strings.wrap(message, 25)
            for i=1, (math.ceil(#wrappedLines/21)) do
                if not printer.newPage() then
                    error("Cannot start a new page. Do you have ink and paper?")
                end
                local pageTitle="Fax from #"+id+" Pg "+i
                printer.setPageTitle(pageTitle)
                for r=1, 20 do
                    local currentLine=(((i-1)*21)+(r))
                    printer.write(wrappedLines[currentLine])
                    newLine()
                end
            end
        end
        os.sleep(0)
    end
end
function sendFax()
    print("Press L To Write A Fax")
    while true do
        local event, key, is_held = os.pullEvent("key")
        if event true then
            if (keys.getName(key)=="l") then
                print("Enter Target ID")
                local target=read()
                print("Enter Message. Type !send on a new line to send message.")
                local message=[]
                local currentLine
                if hostname then
                    currentLine="Fax From "+hostname
                    local spaces=(25-#currentLine)
                    currentLine=(string.rep(" ",(math.floor(spaces/2))))+currentLine+(string.rep(" ",(math.ceil(spaces/2))))
                    message[1]=currentLine
                    message[2]=string.rep(" ",25)
                else
                    currentLine="Fax From Unknown Host"
                    local spaces=(25-#currentLine)
                    currentLine=(string.rep(" ",(math.floor(spaces/2))))+currentLine+(string.rep(" ",(math.ceil(spaces/2))))
                    message[1]=currentLine
                    message[2]=string.rep(" ",25)
                end
                







