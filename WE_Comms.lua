local fileStoragePath = ".WE_Username"

local function getUsernameFromFile()
    if not fs.exists(fileStoragePath) then
        fs.open(fileStoragePath, "w").close() --Make sure the file exists
    end
    local f = fs.open(fileStoragePath, "r")
    local username = f.readAll()
    f.close()
    return username
end

--lsh, created by Lyqyd, with only a few tweaks by me (mostly bugfixes to get it working without the entirety of the file, and changing the history path)
local runHistory = {}
if fs.exists(".history") then
    local histFile = io.open(".history", "r")
    if histFile then
        for line in histFile:lines() do
            table.insert(runHistory, line)
        end
        histFile:close()
    end
end
local sizeOfHistory = #runHistory

local function saveHistory()
    if #runHistory > sizeOfHistory then
        local histFile = io.open(".history", "a")
        if histFile then
            for i = sizeOfHistory + 1, #runHistory do
                histFile:write(runHistory[i] .. "\n")
            end
            histFile:close()
        end
    end
end

local function customRead(history)
    term.setCursorBlink(true)

    local line = ""
    local nHistoryPos = nil
    local nPos = 0

    local w, h = term.getSize()
    local sx, sy = term.getCursorPos()

    local function redraw()
        local nScroll = 0
        if sx + nPos >= w then
            nScroll = (sx + nPos) - w
        end

        term.setCursorPos(sx, sy)
        term.write(string.sub(line, nScroll + 1))
        term.write(string.rep(" ", w - (#line - nScroll) - sx))
        term.setCursorPos(sx + nPos - nScroll, sy)
    end

    while true do
        local sEvent, param = os.pullEvent()
        if sEvent == "char" then
            line = string.sub(line, 1, nPos) .. param .. string.sub(line, nPos + 1)
            nPos = nPos + 1
            redraw()

        elseif sEvent == "key" then
            if param == keys.enter then
                table.insert(runHistory, line)
                saveHistory()
                -- Enter
                break

            elseif param == keys.left then
                -- Left
                if nPos > 0 then
                    nPos = nPos - 1
                    redraw()
                end

            elseif param == keys.right then
                -- Right
                if nPos < string.len(line) then
                    nPos = nPos + 1
                    redraw()
                end

            elseif param == keys.up or param == keys.down then
                -- Up or down
                if history then
                    if param == keys.up then
                        -- Up
                        if nHistoryPos == nil then
                            if #history > 0 then
                                nHistoryPos = #history
                            end
                        elseif nHistoryPos > 1 then
                            nHistoryPos = nHistoryPos - 1
                        end
                    else
                        -- Down
                        if nHistoryPos == #history then
                            nHistoryPos = nil
                        elseif nHistoryPos ~= nil then
                            nHistoryPos = nHistoryPos + 1
                        end
                    end

                    if nHistoryPos then
                        line = history[nHistoryPos]
                        nPos = string.len(line)
                    else
                        line = ""
                        nPos = 0
                    end
                    redraw()
                end
            elseif param == keys.backspace then
                -- Backspace
                if nPos > 0 then
                    line = string.sub(line, 1, nPos - 1) .. string.sub(line, nPos + 1)
                    nPos = nPos - 1
                    redraw()
                end
            elseif param == keys.home then
                -- Home
                nPos = 0
                redraw()
            elseif param == keys.delete then
                if nPos < string.len(line) then
                    line = string.sub(line, 1, nPos) .. string.sub(line, nPos + 2)
                    redraw()
                end
            elseif param == keys["end"] then
                -- End
                nPos = string.len(line)
                redraw()
            elseif param == keys.tab then
                --tab autocomplete.
            end
        end
    end

    term.setCursorBlink(false)
    term.setCursorPos(w + 1, sy)
    print()

    return line
end

--End of lsh

local function getUsername(username) --Prompts the user for their username.
    if username ~= "" then
        print("Is the name \"" .. username .. "\" correct? (Y/N)")
        while true do
            local input = io.read():lower()
            if input == "t" or input == "true" or input == "y" or input == "yes" then
                return username
            elseif input == "f" or input == "false" or input == "n" or input == "no" then
                break
            else
                print("That's not a yes or no answer!")
            end
        end
    end
    while true do
        print "What is your username, exactly as it appears in-game? (case sensitive!)"
        username = io.read()
        print("Is the name \"" .. username .. "\" correct? (Y/N)")
        if input == "t" or input == "true" or input == "y" or input == "yes" then
            break
        elseif input == "f" or input == "false" or input == "n" or input == "no" then
            --Do nothing
        else
            print("That's not a yes or no answer!")
        end
    end
    local f = fs.open(fileStoragePath, "w")
    f.write(username)
    f.close()
    return username
end

local username = getUsername(getUsernameFromFile())
local function sendMessage(message, username)
    local modem = false
    while true do
        for k, v in pairs(peripheral.getNames()) do
            if peripheral.getType(v) == "modem" then
                modem = true
                rednet.open(v)
            end
        end
        if modem then
            rednet.broadcast(message, "WE_Input" .. username)
            return
        end
        print "Connect a modem and press enter to continue."
        io.read()
    end
end

print "Type your command:"
local message
while true do --Main loop
    message = customRead(runHistory)
    if message:lower() == "changeusername" or message:lower() == "change username" then
        username = getUsername(username)
    elseif message ~= "" then
        sendMessage(message, username)
    end
end