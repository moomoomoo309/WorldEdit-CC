local function serpentProgress()
    while true do
        local _, progress = os.pullEvent "SerpentProgress"
        progress = tostring(progress)
        WE.sendChat(("Table serialization %s%% complete."):format(progress:sub(1, progress:find(".", nil, true) + 2)))
    end
end

return { name = "CheckSerpentProgress", serpentProgress }