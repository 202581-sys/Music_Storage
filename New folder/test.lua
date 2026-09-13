turtle.select(1)

-- Force check what is directly in front
local has_block, data = turtle.inspect()
if has_block then
    print("Block in front: " .. data.name)
else
    print("No block detected in front!")
end

-- Attempt to suck 1 item
local success, err = turtle.suck(1)
if success then
    print("SUCCESS: Picked up item!")
else
    print("FAILED: " .. tostring(err or "Chest empty or blocked"))
end
