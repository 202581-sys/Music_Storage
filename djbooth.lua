-- Wireless Radio Stream Transmitter with Queue System & Monitor UI
local modem = peripheral.find("modem") or error("No Ender Modem attached!")
local mon = peripheral.find("monitor") or error("No Advanced Monitor found!")

-- 1. Prompt user for the broadcasting frequency
term.clear()
term.setCursorPos(1, 1)
print("====================================")
print("   TUNABLE STREAM TRANSMITTER       ")
print("====================================")
write("Enter transmission channel (e.g. 99): ")
local CHANNEL = tonumber(read())
if not CHANNEL or CHANNEL < 1 or CHANNEL > 65535 then
    error("Invalid channel! Please enter a number between 1 and 65535.")
end

-- Redirect terminal output to the monitor
term.redirect(mon)
mon.setTextScale(0.5)

-- ========== SONG LIST ==========

local songs = {
    {
        name = "Akon - Ghetto",
        url = "https://raw.githubusercontent.com/iChronixz-git/Music/main/1nryuu.dfpwm"
    },
    {
        name = "Post Malone - Wasting Angels ft Kid Laroi",
        url = "https://raw.githubusercontent.com/202581-sys/Music_Storage/main/Post%20Malone%20-%20Wasting%20Angels%20w.%20The%20Kid%20LAROI%20(Official%20Lyric%20Video)%20%5BLBbHPn-7v1I%5D.dfpwm"
    },
    {
        name = "Queen - Bohemian Rhapsody",
        url = "https://raw.githubusercontent.com/202581-sys/Music_Storage/main/Queen%20%E2%80%93%20Bohemian%20Rhapsody%20(Official%20Video%20Remastered)%20%5BfJ9rUzIMcZQ%5D.dfpwm"
    },
    {
        name = "Bad Bunny - DtMF",
        url = "https://raw.githubusercontent.com/iChronixz-git/Music/main/BAD%20BUNNY%20-%20DtMF%20(Visualizer)%20DeB%C3%8D%20TiRAR%20M%C3%A1S%20FOToS.dfpwm"
    },
    {
        name = "XS Project - Bochka, Bass, Kolbaser",
        url = "https://raw.githubusercontent.com/iChronixz-git/Music/main/XS%20Project%20-%20Bochka,%20Bass,%20Kolbaser%20%5BBass%20Boosted%5D%20(Russian%20Special)%20-%20(256%20Kbps).dfpwm"
    },
}

-- ===============================

local scroll = 0
local selected = 1

-- Playback state
local playing = false
local paused = false
local stopFlag = false
local currentSong = nil
local response = nil

-- Queue System
local queue = {}

-- Modem streaming configuration
local chunk_size = 1024 
local delay = chunk_size / (48000 / 8) 

-- ========== UI HELPERS ==========

local function centerWrite(text, y, color)
    local w = select(1, term.getSize())
    term.setTextColor(color or colors.white)
    local x = math.floor((w - #tostring(text)) / 2) + 1
    if x < 1 then x = 1 end
    term.setCursorPos(x, y)
    term.write(tostring(text))
end

local function drawButton(x, y, w, text, bg)
    term.setBackgroundColor(bg or colors.gray)
    term.setTextColor(colors.white)
    term.setCursorPos(x, y)
    term.write(string.rep(" ", w))
    local tx = x + math.floor((w - #text) / 2)
    term.setCursorPos(tx, y)
    term.write(text)
end

-- ========== DRAW ==========

local function draw()
    local w, h = term.getSize()

    term.setBackgroundColor(colors.black)
    term.clear()

    centerWrite("=== RADIO TRANSMITTER (CH: " .. CHANNEL .. ") ===", 1, colors.yellow)

    local listHeight = h - 9
    local maxScroll = math.max(0, #songs - listHeight)
    scroll = math.max(0, math.min(scroll, maxScroll))

    for i = 1, listHeight do
        local idx = i + scroll
        local y = 2 + i

        if songs[idx] then
            if idx == selected then
                term.setBackgroundColor(colors.blue)
                term.setTextColor(colors.white)
            else
                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.lime)
            end

            term.setCursorPos(2, y)
            term.write(string.rep(" ", w - 2))
            term.setCursorPos(3, y)

            local name = songs[idx].name
            if #name > w - 4 then
                name = name:sub(1, w - 7) .. "..."
            end

            term.write(name)
        end
    end

    term.setBackgroundColor(colors.black)
    centerWrite("------------------------------", h - 5, colors.gray)

    if playing and currentSong then
        centerWrite("Broadcasting: " .. currentSong, h - 4, colors.lightBlue)
        if paused then
            centerWrite("[ PAUSED ] | Queue: " .. #queue .. " queued", h - 3, colors.orange)
        else
            centerWrite("[ BROADCASTING ] | Queue: " .. #queue .. " queued", h - 3, colors.lime)
        end
    else
        centerWrite("Broadcasting: Idle", h - 4, colors.gray)
        centerWrite("Queue: " .. #queue .. " queued", h - 3, colors.gray)
    end

    -- Control Buttons
    drawButton(2, h, 6, "Play", colors.green)
    drawButton(9, h, 6, "Pause", colors.orange)
    drawButton(16, h, 6, "Stop", colors.red)
    drawButton(23, h, 8, "+Queue", colors.purple)
    drawButton(32, h, 8, "Clear Q", colors.gray)
end

-- ========== START STREAM ==========

function startStream(song)
    -- Stop previous stream safely
    stopFlag = true

    if response then
        pcall(function() response.close() end)
        response = nil
    end

    sleep(0.2)

    -- Reset playback state
    stopFlag = false
    paused = false
    playing = true
    currentSong = song.name

    draw()

    -- Request file
    http.request({
        url = song.url,
        binary = true,
        headers = { ["User-Agent"] = "CC-Tweaked" }
    })

    local timeout = os.startTimer(20)

    while true do
        local ev, p1, p2 = os.pullEvent()

        if ev == "http_success" and p1 == song.url then
            response = p2
            break
        elseif ev == "http_failure" and p1 == song.url then
            playing = false
            currentSong = "Load failed"
            draw()
            return false
        elseif ev == "timer" and p1 == timeout then
            playing = false
            currentSong = "Timeout"
            draw()
            return false
        end
    end

    return true
end

-- ========== HANDLE MONITOR INPUT ==========

local function handleTouch(x, y)
    local w, h = term.getSize()
    local listHeight = h - 9

    -- Select song
    if y >= 3 and y <= 2 + listHeight then
        local idx = (y - 2) + scroll
        if songs[idx] then
            selected = idx
            draw()
        end
    end

    -- PLAY
    if y == h and x >= 2 and x <= 7 then
        if songs[selected] then
            startStream(songs[selected])
        end
    end

    -- PAUSE
    if y == h and x >= 9 and x <= 14 then
        if playing then
            paused = not paused
            draw()
        end
    end

    -- STOP
    if y == h and x >= 16 and x <= 21 then
        stopFlag = true
        queue = {} -- Clear queue on manual stop
        if response then
            pcall(function() response.close() end)
            response = nil
        end
        playing = false
        paused = false
        currentSong = nil
        draw()
    end

    -- +QUEUE
    if y == h and x >= 23 and x <= 30 then
        if songs[selected] then
            table.insert(queue, songs[selected])
            draw()

            -- If nothing is currently playing, start playing the queued song immediately
            if not playing then
                local nextSong = table.remove(queue, 1)
                startStream(nextSong)
            end
        end
    end

    -- CLEAR QUEUE
    if y == h and x >= 32 and x <= 39 then
        queue = {}
        draw()
    end
end

-- ========== MAIN LOOP ==========

draw()

while true do
    if playing and not paused and response and not stopFlag then
        -- Read chunk for radio transmission
        local chunk = response.read(chunk_size)

        if chunk then
            -- Broadcast over chosen channel
            modem.transmit(CHANNEL, CHANNEL, chunk)
            
            -- Sleep brief delay to match timing and handle events
            local timerID = os.startTimer(delay)
            while true do
                local event, p1, p2, p3 = os.pullEvent()
                if event == "timer" and p1 == timerID then
                    break
                elseif event == "monitor_touch" then
                    handleTouch(p2, p3)
                    if stopFlag or paused then break end
                elseif event == "mouse_scroll" then
                    scroll = scroll - p1
                    draw()
                end
            end
        else
            -- End of current track
            pcall(function() response.close() end)
            response = nil

            -- Check if there are queued songs remaining
            if #queue > 0 then
                local nextSong = table.remove(queue, 1)
                startStream(nextSong)
            else
                playing = false
                paused = false
                currentSong = nil
                draw()
            end
        end
    else
        -- Idle loop listening for monitor interaction
        local event, p1, p2, p3 = os.pullEvent()
        if event == "monitor_touch" then
            handleTouch(p2, p3)
        elseif event == "mouse_scroll" then
            scroll = scroll - p1
            draw()
        end
    end
end