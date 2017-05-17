local taskAmt = 0
local function countCommands()
    --- Makes sure when setting blocks that the command limit is not exceeded.
    while true do
        os.pullEvent "task_complete"
        taskAmt = taskAmt and taskAmt - 1 or 0
        os.queueEvent "taskCount"
    end
end

return { name = "CountCommands", countCommands }