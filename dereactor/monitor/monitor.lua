rednet.open("right")
os.loadAPI("lib/f")
-- reactor information
local ri
local outgate
local ingate
-- monitor 
local mon, monitor, monX, monY
local activateOnCharged = 1

local targetStrength = 20
local maxTemperature = 8000
local safeTemperature = 3000
local lowestFieldPercent = 3

monitor_peripheral = f.periphSearch("monitor")
monitor = window.create(monitor_peripheral, 1, 1, monitor_peripheral.getSize()) -- create a window on the monitor

function update()
  while true do 

    monitor.setVisible(false) -- disable updating the screen.
    f.clear(mon)

    rinfo = rednet.recieve()
    
    ri = rinfo[1]
    outgate = rinfo[2]
    ingate = rinfo[3]

    

    -- print out all the infos from .getReactorInfo() to term

    if ri == nil then
      error("reactor has an invalid setup")
    end

    for k, v in pairs (ri) do
      print(k.. ": "..tostring(v))			
    end
    print("Output Gate: ", outgate)
    print("Input Gate: ", ingate)

    -- monitor output

    local statusColor
    statusColor = colors.red

    if ri.status == "running" or ri.status == "warming_up" and ri.temperature > 2000 then
      statusColor = colors.green
    elseif ri.status == "cold" then
      statusColor = colors.gray
    elseif ri.status == "warming_up" then
      statusColor = colors.orange
    end
		
    f.draw_text_lr(mon, 2, 2, 1, "Draconic Reactor", string.upper(ri.status), colors.white, statusColor, colors.black)

    f.draw_text_lr(mon, 2, 4, 1, "Generation", f.format_int(ri.generationRate) .. " rf/t", colors.white, colors.lime, colors.black)

    local tempColor = colors.red
    if ri.temperature <= 5000 then tempColor = colors.green end
    if ri.temperature >= 5000 and ri.temperature <= 6500 then tempColor = colors.orange end
    f.draw_text_lr(mon, 2, 6, 1, "Temperature", f.format_int(ri.temperature) .. "C", colors.white, tempColor, colors.black)

    f.draw_text_lr(mon, 2, 7, 1, "Output Gate", f.format_int(outgate) .. " rf/t", colors.white, colors.blue, colors.black)

    -- buttons
    drawButtons(8)

    f.draw_text_lr(mon, 2, 9, 1, "Input Gate", f.format_int(ingate) .. " rf/t", colors.white, colors.blue, colors.black)

    if autoInputGate == 1 then
      f.draw_text(mon, 14, 10, "AU", colors.white, colors.gray)
    else
      f.draw_text(mon, 14, 10, "MA", colors.white, colors.gray)
      drawButtons(10)
    end

    local satPercent
    satPercent = math.ceil(ri.energySaturation / ri.maxEnergySaturation * 10000)*.01

    f.draw_text_lr(mon, 2, 11, 1, "Energy Saturation", satPercent .. "%", colors.white, colors.white, colors.black)
    f.progress_bar(mon, 2, 12, mon.X-2, satPercent, 100, colors.blue, colors.gray)

    local fieldPercent, fieldColor
    fieldPercent = math.ceil(ri.fieldStrength / ri.maxFieldStrength * 10000)*.01

    fieldColor = colors.red
    if fieldPercent >= 50 then fieldColor = colors.green end
    if fieldPercent < 50 and fieldPercent > 30 then fieldColor = colors.orange end

    if autoInputGate == 1 then 
      f.draw_text_lr(mon, 2, 14, 1, "Field Strength T:" .. targetStrength, fieldPercent .. "%", colors.white, fieldColor, colors.black)
    else
      f.draw_text_lr(mon, 2, 14, 1, "Field Strength", fieldPercent .. "%", colors.white, fieldColor, colors.black)
    end
    f.progress_bar(mon, 2, 15, mon.X-2, fieldPercent, 100, fieldColor, colors.gray)

    local fuelPercent, fuelColor

    fuelPercent = 100 - math.ceil(ri.fuelConversion / ri.maxFuelConversion * 10000)*.01

    fuelColor = colors.red

    if fuelPercent >= 70 then fuelColor = colors.green end
    if fuelPercent < 70 and fuelPercent > 30 then fuelColor = colors.orange end

    f.draw_text_lr(mon, 2, 17, 1, "Fuel ", fuelPercent .. "%", colors.white, fuelColor, colors.black)
    f.progress_bar(mon, 2, 18, mon.X-2, fuelPercent, 100, fuelColor, colors.gray)

    f.draw_text_lr(mon, 2, 19, 1, "Action ", action, colors.gray, colors.gray, colors.black)

    monitor.setVisible(true) -- draw the screen.

    sleep(0)
  end
end