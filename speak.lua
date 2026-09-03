local detector = peripheral.wrap("top")
local function doFileURL(url)
    local response = assert(http.get(url), "Failed to connect to URL")
    local code = response.readAll()
    response.close()
    
    -- loadstring converts the string into a runnable function chunk
    local chunk, err = loadstring(code, url)
    if not chunk then error(err) end
    
    return chunk() -- Run it and return whatever the script returns
end
local tts=doFileURL("https://github.com/GabrielVicini/Sandbox/raw/refs/heads/main/cc-flite/tts.lua")
while true do
    print("Enter Text To Read")
    tts.play(read())
end