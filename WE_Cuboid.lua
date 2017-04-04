cuboid = {}

function cuboid.expand() --http://wiki.sk89q.com/wiki/WorldEdit/Selection#Expanding_the_selection
    local args2
    local isVert, amt, direction, beforeComma, afterComma
    for i = 1, #normalArgs do
        local currentArg = normalArgs[i]
        if currentArg == "vert" then
            isVert = true
        elseif isDirection(currentArg) then
            direction = currentArg
        elseif currentArg:find(",", nil, true) then
            args2 = stringx.split(currentArg, ",")
            if #args2 == 2 and tonumber(args2[1]) and tonumber(args2[2]) then
                beforeComma = tonumber(args2[1])
                afterComma = tonumber(args2[2])
            end
        elseif tonumber(currentArg) then
            amt = tonumber(currentArg)
        end
    end
    if isVert then
        pos[1].y = 1
        pos[2].y = 256
        makeCuboidSelection()
        sendChat(("Region expanded vertically. (%d)"):format(#Selection))
        return
    end
    direction = direction or getDirection(true):lower()
    if not isDirection(direction) then return end
    if args2 then
        if not tonumber(args2[1]) and not tonumber(args2[2]) then
            sendChat(("\"%s\" and \"%s\" are not numbers!"):format(tostring(args2[1] or nil), tostring(args2[2] or nil)))
            return
        elseif not tonumber(args2[1]) then
            sendChat(("\"%s\" is not a number!"):format(tostring(args2[1])))
            return
        elseif not tonumber(args2[2]) then
            sendChat(("\"%s\" is not a number!"):format(tostring(args2[2])))
            return
        end
    end
    if beforeComma and afterComma then
        if Direction == "east" then
            if pos[1].x >= pos[2].x then
                pos[1].x = pos[1].x + beforeComma
                pos[2].x = pos[2].x - afterComma
            else
                pos[1].x = pos[1].x - afterComma
                pos[2].x = pos[2].x + beforeComma
            end
        elseif Direction == "west" then
            if pos[1].x >= pos[2].x then
                pos[1].x = pos[1].x + afterComma
                pos[2].x = pos[2].x - beforeComma
            else
                pos[1].x = pos[1].x - beforeComma
                pos[2].x = pos[2].x + afterComma
            end
        elseif Direction == "up" then
            if pos[1].y >= pos[2].y then
                pos[1].y = pos[1].y + beforeComma
                pos[2].y = pos[2].y - afterComma
            else
                pos[1].y = pos[1].y - afterComma
                pos[2].y = pos[2].y + beforeComma
            end
        elseif Direction == "down" then
            if pos[1].y >= pos[2].y then
                pos[1].y = pos[1].y + afterComma
                pos[2].y = pos[2].y - beforeComma
            else
                pos[1].y = pos[1].y - beforeComma
                pos[2].y = pos[2].y + afterComma
            end
        elseif Direction == "north" then
            if pos[1].z >= pos[2].z then
                pos[1].z = pos[1].z + afterComma
                pos[2].z = pos[2].z - beforeComma
            else
                pos[1].z = pos[1].z - beforeComma
                pos[2].z = pos[2].z + afterComma
            end
        elseif Direction == "south" then
            if pos[1].z >= pos[2].z then
                pos[1].z = pos[1].z + beforeComma
                pos[2].z = pos[2].z - afterComma
            else
                pos[1].z = pos[1].z - afterComma
                pos[2].z = pos[2].z + beforeComma
            end
        else
            sendChat "Invalid direction."
            return
        end
        makeCuboidSelection()
        sendChat("Region expanded " .. beforeComma .. " block" .. ((tonumber(beforeComma) > 1 and "s") or "") .. " " .. Direction .. " and " .. afterComma .. " block" .. ((tonumber(afterComma) > 1 and "s") or "") .. " " .. oppositeDirection(Direction) .. "." .. " (" .. #Selection .. ")")
    else
        if not tonumber(amt) then
            sendChat("\"" .. amt .. "\" is not a number!")
            return
        else
            amt = tonumber(amt)
        end
        if Direction == "east" then
            if pos[1].x > pos[2].x then
                pos[1].x = pos[1].x + amt
            else
                pos[2].x = pos[2].x + amt
            end
        elseif Direction == "west" then
            if pos[1].x > pos[2].x then
                pos[2].x = pos[2].x - amt
            else
                pos[1].x = pos[1].x - amt
            end
        elseif Direction == "up" then
            if pos[1].y > pos[2].y then
                pos[1].y = pos[1].y + amt
            else
                pos[2].y = pos[2].y + amt
            end
        elseif Direction == "down" then
            if pos[1].y > pos[2].y then
                pos[2].y = pos[2].y - amt
            else
                pos[1].y = pos[1].y - amt
            end
        elseif Direction == "north" then
            if pos[1].z > pos[2].z then
                pos[2].z = pos[2].z - amt
            else
                pos[1].z = pos[1].z - amt
            end
        elseif Direction == "south" then
            if pos[1].z > pos[2].z then
                pos[1].z = pos[1].z + amt
            else
                pos[2].z = pos[2].z + amt
            end
        else
            sendChat "Invalid direction."
            return
        end
        makeCuboidSelection()
        sendChat("Region expanded " .. tonumber(amt) .. " block" .. ((tonumber(amt) > 1 and "s") or "") .. " " .. Direction .. "." .. " (" .. #Selection .. ")")
    end
end

function cuboid.contract() --http://wiki.sk89q.com/wiki/WorldEdit/Selection#Contracting_the_selection
    local args2, beforeComma, afterComma, amt
    local direction = direction or getDirection(true):lower()
    if not isDirection(direction) then return end
    for i = 1, #normalArgs do
        local currentArg = normalArgs[i]
        if isDirection(currentArg) then
            direction = currentArg
        elseif currentArg:find(",", nil, true) then
            args2 = stringx.split(currentArg, ",")
            if #args2 == 2 and tonumber(args2[1]) and tonumber(args2[2]) then
                beforeComma = tonumber(args2[1])
                afterComma = tonumber(args2[2])
            end
        elseif tonumber(currentArg) then
            amt = tonumber(currentArg)
        end
    end
    if args2 then
        if not tonumber(args2[1]) and not tonumber(args2[2]) then
            sendChat(("\"%s\" and \"%s\" are not numbers!"):format(tostring(args2[1] or nil), tostring(args2[2] or nil)))
            return
        elseif not tonumber(args2[1]) then
            sendChat(("\"%s\" is not a number!"):format(tostring(args2[1])))
            return
        elseif not tonumber(args2[2]) then
            sendChat(("\"%s\" is not a number!"):format(tostring(args2[2])))
            return
        end
    end
    if beforeComma and afterComma then
        if Direction == "west" then
            if pos[1].x >= pos[2].x then
                pos[1].x = pos[1].x - beforeComma
                pos[2].x = pos[2].x + afterComma
            else
                pos[1].x = pos[1].x + afterComma
                pos[2].x = pos[2].x - beforeComma
            end
        elseif Direction == "east" then
            if pos[1].x >= pos[2].x then
                pos[1].x = pos[1].x + afterComma
                pos[2].x = pos[2].x - beforeComma
            else
                pos[1].x = pos[1].x - beforeComma
                pos[2].x = pos[2].x + afterComma
            end
        elseif Direction == "north" then
            if pos[1].z >= pos[2].z then
                pos[1].z = pos[1].z - afterComma
                pos[2].z = pos[2].z + beforeComma
            else
                pos[1].z = pos[1].z + beforeComma
                pos[2].z = pos[2].z - afterComma
            end
        elseif Direction == "south" then
            if pos[1].z >= pos[2].z then
                pos[1].z = pos[1].z - beforeComma
                pos[2].z = pos[2].z + afterComma
            else
                pos[1].z = pos[1].z + afterComma
                pos[2].z = pos[2].z - beforeComma
            end
        elseif Direction == "up" then
            if pos[1].y >= pos[2].y then
                pos[1].y = math.max(0, math.min(pos[1].y - beforeComma, 256))
                pos[2].y = math.max(0, math.min(pos[2].y + afterComma, 256))
            else
                pos[1].y = math.max(0, math.min(pos[1].y + afterComma, 256))
                pos[2].y = math.max(0, math.min(pos[2].y - beforeComma, 256))
            end
        elseif pos[1].y >= pos[2].y then
            pos[1].y = math.max(0, math.min(pos[1].y - afterComma, 256))
            pos[2].y = math.max(0, math.min(pos[2].y + beforeComma, 256))
        else
            pos[1].y = math.max(0, math.min(pos[1].y + beforeComma, 256))
            pos[2].y = math.max(0, math.min(pos[2].y - afterComma, 256))
        end
        makeCuboidSelection()
        sendChat("Region contracted " .. beforeComma .. " block" .. ((tonumber(beforeComma) > 1 and "s") or "") .. " " .. Direction .. " and " .. afterComma .. " block" .. ((tonumber(afterComma) > 1 and "s") or "") .. " " .. oppositeDirection(Direction) .. ".")
    else
        if not tonumber(command) then
            sendChat(("\"%s\" is not a number!"):format(amt))
            return
        else
            amt = tonumber(amt)
        end
        if Direction == "west" then
            if pos[1].x > pos[2].x then
                pos[1].x = pos[1].x - amt
            else
                pos[2].x = pos[2].x - amt
            end
        elseif Direction == "east" then
            if pos[1].x > pos[2].x then
                pos[2].x = pos[2].x + amt
            else
                pos[1].x = pos[1].x + amt
            end
        elseif Direction == "north" then
            if pos[1].z > pos[2].z then
                pos[2].z = pos[2].z + amt
            else
                pos[1].z = pos[1].z + amt
            end
        elseif Direction == "south" then
            if pos[1].z > pos[2].z then
                pos[1].z = pos[1].z - amt
            else
                pos[2].z = pos[2].z - amt
            end
        elseif Direction == "up" then
            if pos[1].y > pos[2].y then
                pos[1].y = math.max(0, math.min(pos[1].y - amt, 256))
            else
                pos[2].y = math.max(0, math.min(pos[2].y - amt, 256))
            end
        elseif Direction == "down" then
            if pos[1].y > pos[2].y then
                pos[2].y = math.max(0, math.min(pos[2].y + amt, 256))
            else
                pos[1].y = math.max(0, math.min(pos[1].y + amt, 256))
            end
        else
            sendChat "Incorrect direction."
            return
        end
        makeCuboidSelection()
        sendChat("Region contracted " .. amt .. " block" .. ((amt > 1 and "s") or "") .. " " .. Direction .. "." .. " (" .. #Selection .. ")")
    end
end

function cuboid.inset() --http://wiki.sk89q.com/wiki/WorldEdit/Selection#Contracting_2_axes_simultaneously_.28inset.29
    local amt = normalArgs[1]
    if tonumber(amt) then
        amt = tonumber(amt)
        if pos[1].x > pos[2].x then
            pos[1].x = pos[1].x - amt
            pos[2].x = pos[2].x + amt
        else
            pos[1].x = pos[1].x + amt
            pos[2].x = pos[2].x - amt
        end
        if pos[1].z > pos[2].z then
            pos[1].z = pos[1].z - amt
            pos[2].z = pos[2].z + amt
        else
            pos[1].z = pos[1].z + amt
            pos[2].z = pos[2].z - amt
        end
        if pos[1].y > pos[2].y then
            pos[1].y = pos[1].y - amt
            pos[2].y = pos[2].y + amt
        else
            pos[1].y = pos[1].y + amt
            pos[2].y = pos[2].y - amt
        end
    else
        sendChat("\"" .. amt .. "\" is not a number!")
        return
    end
    makeCuboidSelection()
    sendChat("Selection inset " .. amt .. " block" .. ((tonumber(amt) > 1 and "s") or "") .. ".")
end

function cuboid.outset() --http://wiki.sk89q.com/wiki/WorldEdit/Selection#Contracting_2_axes_simultaneously_.28inset.29
    local amt = normalArgs[1]
    if tonumber(amt) then
        amt = tonumber(amt)
        if pos[1].x > pos[2].x then
            pos[1].x = pos[1].x + amt
            pos[2].x = pos[2].x - amt
        else
            pos[1].x = pos[1].x - amt
            pos[2].x = pos[2].x + amt
        end
        if pos[1].z > pos[2].z then
            pos[1].z = pos[1].z + amt
            pos[2].z = pos[2].z - amt
        else
            pos[1].z = pos[1].z - amt
            pos[2].z = pos[2].z + amt
        end
        if pos[1].y > pos[2].y then
            pos[1].y = math.max(0, math.min(pos[1].y + amt, 256))
            pos[2].y = math.max(0, math.min(pos[2].y - amt, 256))
        else
            pos[1].y = math.max(0, math.min(pos[1].y - amt, 256))
            pos[2].y = math.max(0, math.min(pos[2].y + amt, 256))
        end
    end
    makeCuboidSelection()
    sendChat("Selection outset " .. amt .. " block" .. ((tonumber(amt) > 1 and "s") or "") .. ".")
end
