-- modifiable variables
local reactorSide = "back"
local fluxgateSide = "right"
rednet.open("top")

local targetStrength = 20
local maxTemperature = 8000
local safeTemperature = 3000
local lowestFieldPercent = 3

local activateOnCharged = 1

-- please leave things untouched from here on
os.loadAPI("lib/f")

local version = "0.25"
-- toggleable via the monitor, use our algorithm to achieve our target field strength or let the user tweak it
local autoInputGate = 1
local curInputGate = 222000



-- peripherals
local reactor
local fluxgate
local inputfluxgate

-- reactor information
local ri

-- last performed action
local action = "None since reboot"
local emergencyCharge = false
local emergencyTemp = false

inputfluxgate = f.periphSearch("flow_gate")
fluxgate = peripheral.wrap(fluxgateSide)
reactor = peripheral.wrap(reactorSide)


if fluxgate == nil then
	error("No valid fluxgate was found")
end

if reactor == nil then
	error("No valid reactor was found")
end

if inputfluxgate == nil then
	error("No valid flux gate was found")
end


--write settings to config file
function save_config()
  sw = fs.open("config.txt", "w")   
  sw.writeLine(version)
  sw.writeLine(autoInputGate)
  sw.writeLine(curInputGate)
  sw.close()
end

--read settings from file
function load_config()
  sr = fs.open("config.txt", "r")
  version = sr.readLine()
  autoInputGate = tonumber(sr.readLine())
  curInputGate = tonumber(sr.readLine())
  sr.close()
end


-- 1st time? save our settings, if not, load our settings
if fs.exists("config.txt") == false then
  save_config()
else
  load_config()
end

function listenForCommands()
  while true do
    local senderID, message = rednet.receive() -- Wait for incoming commands[cite: 3]

    -- Verify message is a valid table payload
    if type(message) == "table" and message.type then

      if message.type == "adjust_output" then
        local cFlow = fluxgate.getSignalLowFlow()[cite: 1]
        fluxgate.setSignalLowFlow(cFlow + message.value)[cite: 1]

      elseif message.type == "adjust_input" and autoInputGate == 0 then
        curInputGate = curInputGate + message.value[cite: 1]
        inputfluxgate.setSignalLowFlow(curInputGate)[cite: 1]
        save_config()[cite: 1]

      elseif message.type == "toggle_auto" then
        autoInputGate = (autoInputGate == 1) and 0 or 1[cite: 1]
        save_config()[cite: 1]
      end

    end
  end
end





function update()
  while true do 

    ri = reactor.getReactorInfo()

    local message = {ri,fluxgate.getSignalLowFlow(),inputfluxgate.getSignalLowFlow(),autoInputGate,action}
    rednet.send(2859,message)

      -- print out all the infos from .getReactorInfo() to term

    if ri == nil then
      error("reactor has an invalid setup")
    end

    for k, v in pairs (ri) do
      print(k.. ": "..tostring(v))			
    end

    -- actual reactor interaction
    --
    if emergencyCharge == true then
      reactor.chargeReactor()
    end
    
    -- are we charging? open the floodgates
    if ri.status == "warming_up" and ri.temperature <= 2000 then
      inputfluxgate.setSignalLowFlow(900000)
      emergencyCharge = false
    end

    -- are we stopping from a shutdown and our temp is better? activate
    if emergencyTemp == true and ri.status == "stopping" and ri.temperature < safeTemperature then
      reactor.activateReactor()
      emergencyTemp = false
    end

    -- are we charged? lets activate
    if ri.status == "warming_up" and ri.temperature > 2000 and activateOnCharged == 1 then
      reactor.activateReactor()
    end

    -- are we on? regulate the input fludgate to our target field strength
    -- or set it to our saved setting since we are on manual
    if ri.status == "running" then
      if autoInputGate == 1 then 
        fluxval = ri.fieldDrainRate / (1 - (targetStrength/100) )
        print("Target Gate: ".. fluxval)
        inputfluxgate.setSignalLowFlow(fluxval)
      else
        inputfluxgate.setSignalLowFlow(curInputGate)
      end
    end

    -- safeguards
    --
    fuelPercent = 100 - math.ceil(ri.fuelConversion / ri.maxFuelConversion * 10000)*.01

    local fieldPercent, fieldColor
    fieldPercent = math.ceil(ri.fieldStrength / ri.maxFieldStrength * 10000)*.01

    -- out of fuel, kill it
    if fuelPercent <= 10 then
      reactor.stopReactor()
      action = "Fuel below 10%, refuel"
    end

    -- field strength is too dangerous, kill and it try and charge it before it blows
    if fieldPercent <= lowestFieldPercent and ri.status == "running" then
      action = "Field Str < " ..lowestFieldPercent.."%"
      reactor.stopReactor()
      reactor.chargeReactor()
      emergencyCharge = true
    end

    -- temperature too high, kill it and activate it when its cool
    if ri.temperature > maxTemperature then
      reactor.stopReactor()
      action = "Temp > " .. maxTemperature
      emergencyTemp = true
    end

    sleep(0)
  end
end

parallel.waitForAny(listenForCommands, update)