--- lsh, created by Lyqyd, with only a few tweaks by me
-- (mostly bugfixes to get it working without the entirety of the file, and changing the history path)
-- Used for the console input (and on the rednet companion as well)
local runHistory = {}
if fs.exists ".history" then
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
    local nHistoryPos
    local nPos = 0

    local w, h = term.getSize()
    local sx, sy = term.getCursorPos()

    local function redraw()
        local nScroll = 0
        if sx + nPos >= w then
            nScroll = (sx + nPos) - w
        end

        term.setCursorPos(sx, sy)
        term.write(line:sub(nScroll + 1))
        term.write((" "):rep(math.max(0, w - (#line - nScroll) - sx)))
        term.setCursorPos(sx + nPos - nScroll, sy)
    end

    while true do
        local sEvent, param = os.pullEvent()
        if sEvent == "char" then
            line = line:sub(1, nPos) .. param .. line:sub(nPos + 1)
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
                if nPos < #line then
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
                        nPos = #line
                    else
                        line = ""
                        nPos = 0
                    end
                    redraw()
                end
            elseif param == keys.backspace then
                -- Backspace
                if nPos > 0 then
                    line = line:sub(1, nPos - 1) .. line:sub(nPos + 1)
                    nPos = nPos - 1
                    redraw()
                end
            elseif param == keys.home then
                -- Home
                nPos = 0
                redraw()
            elseif param == keys.delete then
                if nPos < #line then
                    line = line:sub(1, nPos) .. line:sub(nPos + 2)
                    redraw()
                end
            elseif param == keys["end"] then
                -- End
                nPos = #line
                redraw()
            elseif param == keys.tab then
                --tab autocomplete.
                if #line > 0 then
                    local startsWithCurrentInput, results = false, {}
                    for _, v in pairs(sortedHelpKeys) do
                        if v ~= "blockpatterns" then
                            local lineLen = #line
                            if lineLen < #v and not line:find(" ", nil, true) and line == v:sub(1, #line) then
                                startsWithCurrentInput = true
                                results[#results + 1] = v
                            elseif v > line then
                                break
                            end
                        end
                    end
                    if #results == 1 then
                        line = results[1]
                        nPos = #line
                        redraw()
                    elseif #results > 1 then
                        print ""
                        print(unpack(results))
                        io.write "> "
                        line = ""
                        nPos = 0
                        sy = sy + 2
                    end
                end
            end
        end
    end

    term.setCursorBlink(false)
    term.setCursorPos(w + 1, sy)
    io.write "\n> "
    return line
end

--End of lsh


local function getConsoleInput()
    --- Gets commands from typing on the computer itself.
    while true do
        local str = customRead(runHistory)
        local username = WE.getPlayerName()
        os.queueEvent("chatFromConsole", username, str) --As long as the event starts with "chat", it works!
    end
end

return { name = "getConsoleInput", getConsoleInput }