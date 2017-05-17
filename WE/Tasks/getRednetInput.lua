local function getRednetInput()
    --- Gets commands from rednet messages sent by trusted IDs.
    peripheral.find("modem", rednet.open) --Open all rednet modems
    local event = { os.pullEvent "rednet_message" } --Listen for the initial message
    while true do
        if event[4]:sub(1, 8) == "WE_Input" then
            --Listen for the protocol
            if tablex.find(WE.trustedIDs, event[2]) == nil then
                --If the ID is not trusted
                WE.sendChat(("Computer with ID %s is trying to connect for remote input. Allow? (Y/N)"):format(event[2])) --Prompt the user to trust it
                WE.username, WE.message = WE.getCommand() --Get the user's response
                if WE.message:lower() == "t" or WE.message:lower() == "true" or WE.message:lower() == "y" or WE.message:lower() == "yes" then
                    table.insert(WE.trustedIDs, event[2]) --Trust the IDs
                    WE.writeIDs() --Update the IDs file
                    WE.sendChat(("Allowing pocket computer with ID %s to control this computer remotely."):format(event[2]))
                else
                    WE.sendChat(("Not allowing computer with ID %s."):format(event[2]))
                end
            end
        end
        if tablex.find(WE.trustedIDs, event[2]) ~= nil then
            --If it's already trusted, run the command.
            os.queueEvent("chatFromRednet", event[4]:sub(9), event[3])
        end
        event = { os.pullEvent "rednet_message" } --Listen for the next message.
    end
end

return { name = "getRednetInput", getRednetInput }