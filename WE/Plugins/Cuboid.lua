local cuboid = {name = "cuboid"}

function cuboid.expand() --http://wiki.sk89q.com/wiki/WorldEdit/Selection#Expanding_the_selection
    local args2
    local isVert, amt, direction, beforeComma, afterComma
    for i = 1, #WE.normalArgs do
        local currentArg = WE.normalArgs[i]
        if currentArg == "vert" then
            isVert = true
        elseif WE.isDirection(currentArg) then
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
        WE.pos[1].y = 1
        WE.pos[2].y = 256
        if WE.makeSelection[WE.selection.type] then
            WE.makeSelection[WE.selection.type]()
        else
            WE.sendChat(("Selection mode %s not implemented correctly!"):format(WE.selection.type))
            return
        end
        WE.sendChat(("Region expanded vertically. (%d)"):format(#WE.selection))
        return
    end
    direction = direction or WE.getDirection(true):lower()
    if not WE.isDirection(direction) then return end
    if args2 then
        if not tonumber(args2[1]) and not tonumber(args2[2]) then
            WE.sendChat(("\"%s\" and \"%s\" are not numbers!"):format(tostring(args2[1] or nil), tostring(args2[2] or nil)))
            return
        elseif not tonumber(args2[1]) then
            WE.sendChat(("\"%s\" is not a number!"):format(tostring(args2[1])))
            return
        elseif not tonumber(args2[2]) then
            WE.sendChat(("\"%s\" is not a number!"):format(tostring(args2[2])))
            return
        end
    end
    if beforeComma and afterComma then
        if WE.direction == "east" then
            if WE.pos[1].x >= WE.pos[2].x then
                WE.pos[1].x = WE.pos[1].x + beforeComma
                WE.pos[2].x = WE.pos[2].x - afterComma
            else
                WE.pos[1].x = WE.pos[1].x - afterComma
                WE.pos[2].x = WE.pos[2].x + beforeComma
            end
        elseif WE.direction == "west" then
            if WE.pos[1].x >= WE.pos[2].x then
                WE.pos[1].x = WE.pos[1].x + afterComma
                WE.pos[2].x = WE.pos[2].x - beforeComma
            else
                WE.pos[1].x = WE.pos[1].x - beforeComma
                WE.pos[2].x = WE.pos[2].x + afterComma
            end
        elseif WE.direction == "up" then
            if WE.pos[1].y >= WE.pos[2].y then
                WE.pos[1].y = WE.pos[1].y + beforeComma
                WE.pos[2].y = WE.pos[2].y - afterComma
            else
                WE.pos[1].y = WE.pos[1].y - afterComma
                WE.pos[2].y = WE.pos[2].y + beforeComma
            end
        elseif WE.direction == "down" then
            if WE.pos[1].y >= WE.pos[2].y then
                WE.pos[1].y = WE.pos[1].y + afterComma
                WE.pos[2].y = WE.pos[2].y - beforeComma
            else
                WE.pos[1].y = WE.pos[1].y - beforeComma
                WE.pos[2].y = WE.pos[2].y + afterComma
            end
        elseif WE.direction == "north" then
            if WE.pos[1].z >= WE.pos[2].z then
                WE.pos[1].z = WE.pos[1].z + afterComma
                WE.pos[2].z = WE.pos[2].z - beforeComma
            else
                WE.pos[1].z = WE.pos[1].z - beforeComma
                WE.pos[2].z = WE.pos[2].z + afterComma
            end
        elseif WE.direction == "south" then
            if WE.pos[1].z >= WE.pos[2].z then
                WE.pos[1].z = WE.pos[1].z + beforeComma
                WE.pos[2].z = WE.pos[2].z - afterComma
            else
                WE.pos[1].z = WE.pos[1].z - afterComma
                WE.pos[2].z = WE.pos[2].z + beforeComma
            end
        else
            WE.sendChat "Invalid direction."
            return
        end
        if WE.makeSelection[WE.selection.type] then
            WE.makeSelection[WE.selection.type]()
        else
            WE.sendChat(("Selection mode %s not implemented correctly!"):format(WE.selection.type))
            return
        end
        WE.sendChat("Region expanded " .. beforeComma .. " block" .. ((tonumber(beforeComma) > 1 and "s") or "") .. " " .. WE.direction .. " and " .. afterComma .. " block" .. ((tonumber(afterComma) > 1 and "s") or "") .. " " .. WE.oppositeDirection(WE.direction) .. "." .. " (" .. #WE.selection .. ")")
    else
        if not tonumber(amt) then
            WE.sendChat("\"" .. amt .. "\" is not a number!")
            return
        else
            amt = tonumber(amt)
        end
        if WE.direction == "east" then
            if WE.pos[1].x > WE.pos[2].x then
                WE.pos[1].x = WE.pos[1].x + amt
            else
                WE.pos[2].x = WE.pos[2].x + amt
            end
        elseif WE.direction == "west" then
            if WE.pos[1].x > WE.pos[2].x then
                WE.pos[2].x = WE.pos[2].x - amt
            else
                WE.pos[1].x = WE.pos[1].x - amt
            end
        elseif WE.direction == "up" then
            if WE.pos[1].y > WE.pos[2].y then
                WE.pos[1].y = WE.pos[1].y + amt
            else
                WE.pos[2].y = WE.pos[2].y + amt
            end
        elseif WE.direction == "down" then
            if WE.pos[1].y > WE.pos[2].y then
                WE.pos[2].y = WE.pos[2].y - amt
            else
                WE.pos[1].y = WE.pos[1].y - amt
            end
        elseif WE.direction == "north" then
            if WE.pos[1].z > WE.pos[2].z then
                WE.pos[2].z = WE.pos[2].z - amt
            else
                WE.pos[1].z = WE.pos[1].z - amt
            end
        elseif WE.direction == "south" then
            if WE.pos[1].z > WE.pos[2].z then
                WE.pos[1].z = WE.pos[1].z + amt
            else
                WE.pos[2].z = WE.pos[2].z + amt
            end
        else
            WE.sendChat "Invalid direction."
            return
        end
        if WE.makeSelection[WE.selection.type] then
            WE.makeSelection[WE.selection.type]()
        else
            WE.sendChat(("Selection mode %s not implemented correctly!"):format(WE.selection.type))
            return
        end
        WE.sendChat("Region expanded " .. tonumber(amt) .. " block" .. ((tonumber(amt) > 1 and "s") or "") .. " " .. WE.direction .. "." .. " (" .. #WE.selection .. ")")
    end
end

function cuboid.contract() --http://wiki.sk89q.com/wiki/WorldEdit/Selection#Contracting_the_selection
    local args2, beforeComma, afterComma, amt
    local direction = direction or WE.getDirection(true):lower()
    if not WE.isDirection(direction) then return end
    for i = 1, #WE.normalArgs do
        local currentArg = WE.normalArgs[i]
        if WE.isDirection(currentArg) then
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
            WE.sendChat(("\"%s\" and \"%s\" are not numbers!"):format(tostring(args2[1] or nil), tostring(args2[2] or nil)))
            return
        elseif not tonumber(args2[1]) then
            WE.sendChat(("\"%s\" is not a number!"):format(tostring(args2[1])))
            return
        elseif not tonumber(args2[2]) then
            WE.sendChat(("\"%s\" is not a number!"):format(tostring(args2[2])))
            return
        end
    end
    if beforeComma and afterComma then
        if WE.direction == "west" then
            if WE.pos[1].x >= WE.pos[2].x then
                WE.pos[1].x = WE.pos[1].x - beforeComma
                WE.pos[2].x = WE.pos[2].x + afterComma
            else
                WE.pos[1].x = WE.pos[1].x + afterComma
                WE.pos[2].x = WE.pos[2].x - beforeComma
            end
        elseif WE.direction == "east" then
            if WE.pos[1].x >= WE.pos[2].x then
                WE.pos[1].x = WE.pos[1].x + afterComma
                WE.pos[2].x = WE.pos[2].x - beforeComma
            else
                WE.pos[1].x = WE.pos[1].x - beforeComma
                WE.pos[2].x = WE.pos[2].x + afterComma
            end
        elseif WE.direction == "north" then
            if WE.pos[1].z >= WE.pos[2].z then
                WE.pos[1].z = WE.pos[1].z - afterComma
                WE.pos[2].z = WE.pos[2].z + beforeComma
            else
                WE.pos[1].z = WE.pos[1].z + beforeComma
                WE.pos[2].z = WE.pos[2].z - afterComma
            end
        elseif WE.direction == "south" then
            if WE.pos[1].z >= WE.pos[2].z then
                WE.pos[1].z = WE.pos[1].z - beforeComma
                WE.pos[2].z = WE.pos[2].z + afterComma
            else
                WE.pos[1].z = WE.pos[1].z + afterComma
                WE.pos[2].z = WE.pos[2].z - beforeComma
            end
        elseif WE.direction == "up" then
            if WE.pos[1].y >= WE.pos[2].y then
                WE.pos[1].y = math.max(0, math.min(WE.pos[1].y - beforeComma, 256))
                WE.pos[2].y = math.max(0, math.min(WE.pos[2].y + afterComma, 256))
            else
                WE.pos[1].y = math.max(0, math.min(WE.pos[1].y + afterComma, 256))
                WE.pos[2].y = math.max(0, math.min(WE.pos[2].y - beforeComma, 256))
            end
        elseif WE.pos[1].y >= WE.pos[2].y then
            WE.pos[1].y = math.max(0, math.min(WE.pos[1].y - afterComma, 256))
            WE.pos[2].y = math.max(0, math.min(WE.pos[2].y + beforeComma, 256))
        else
            WE.pos[1].y = math.max(0, math.min(WE.pos[1].y + beforeComma, 256))
            WE.pos[2].y = math.max(0, math.min(WE.pos[2].y - afterComma, 256))
        end
        if WE.makeSelection[WE.selection.type] then
            WE.makeSelection[WE.selection.type]()
        else
            WE.sendChat(("Selection mode %s not implemented correctly!"):format(WE.selection.type))
            return
        end
        WE.sendChat("Region contracted " .. beforeComma .. " block" .. ((tonumber(beforeComma) > 1 and "s") or "") .. " " .. WE.direction .. " and " .. afterComma .. " block" .. ((tonumber(afterComma) > 1 and "s") or "") .. " " .. WE.oppositeDirection(WE.direction) .. ".")
    else
        if not tonumber(command) then
            WE.sendChat(("\"%s\" is not a number!"):format(amt))
            return
        else
            amt = tonumber(amt)
        end
        if WE.direction == "west" then
            if WE.pos[1].x > WE.pos[2].x then
                WE.pos[1].x = WE.pos[1].x - amt
            else
                WE.pos[2].x = WE.pos[2].x - amt
            end
        elseif WE.direction == "east" then
            if WE.pos[1].x > WE.pos[2].x then
                WE.pos[2].x = WE.pos[2].x + amt
            else
                WE.pos[1].x = WE.pos[1].x + amt
            end
        elseif WE.direction == "north" then
            if WE.pos[1].z > WE.pos[2].z then
                WE.pos[2].z = WE.pos[2].z + amt
            else
                WE.pos[1].z = WE.pos[1].z + amt
            end
        elseif WE.direction == "south" then
            if WE.pos[1].z > WE.pos[2].z then
                WE.pos[1].z = WE.pos[1].z - amt
            else
                WE.pos[2].z = WE.pos[2].z - amt
            end
        elseif WE.direction == "up" then
            if WE.pos[1].y > WE.pos[2].y then
                WE.pos[1].y = math.max(0, math.min(WE.pos[1].y - amt, 256))
            else
                WE.pos[2].y = math.max(0, math.min(WE.pos[2].y - amt, 256))
            end
        elseif WE.direction == "down" then
            if WE.pos[1].y > WE.pos[2].y then
                WE.pos[2].y = math.max(0, math.min(WE.pos[2].y + amt, 256))
            else
                WE.pos[1].y = math.max(0, math.min(WE.pos[1].y + amt, 256))
            end
        else
            WE.sendChat "Incorrect direction."
            return
        end
        if WE.makeSelection[WE.selection.type] then
            WE.makeSelection[WE.selection.type]()
        else
            WE.sendChat(("Selection mode %s not implemented correctly!"):format(WE.selection.type))
            return
        end
        WE.sendChat("Region contracted " .. amt .. " block" .. ((amt > 1 and "s") or "") .. " " .. WE.direction .. "." .. " (" .. #WE.selection .. ")")
    end
end

function cuboid.inset() --http://wiki.sk89q.com/wiki/WorldEdit/Selection#Contracting_2_axes_simultaneously_.28inset.29
    local amt = WE.normalArgs[1]
    if tonumber(amt) then
        amt = tonumber(amt)
        if WE.pos[1].x > WE.pos[2].x then
            WE.pos[1].x = WE.pos[1].x - amt
            WE.pos[2].x = WE.pos[2].x + amt
        else
            WE.pos[1].x = WE.pos[1].x + amt
            WE.pos[2].x = WE.pos[2].x - amt
        end
        if WE.pos[1].z > WE.pos[2].z then
            WE.pos[1].z = WE.pos[1].z - amt
            WE.pos[2].z = WE.pos[2].z + amt
        else
            WE.pos[1].z = WE.pos[1].z + amt
            WE.pos[2].z = WE.pos[2].z - amt
        end
        if WE.pos[1].y > WE.pos[2].y then
            WE.pos[1].y = WE.pos[1].y - amt
            WE.pos[2].y = WE.pos[2].y + amt
        else
            WE.pos[1].y = WE.pos[1].y + amt
            WE.pos[2].y = WE.pos[2].y - amt
        end
    else
        WE.sendChat("\"" .. amt .. "\" is not a number!")
        return
    end
    if WE.makeSelection[WE.selection.type] then
        WE.makeSelection[WE.selection.type]()
    else
        WE.sendChat(("Selection mode %s not implemented correctly!"):format(WE.selection.type))
        return
    end
    WE.sendChat("Selection inset " .. amt .. " block" .. ((tonumber(amt) > 1 and "s") or "") .. ".")
end

function cuboid.outset() --http://wiki.sk89q.com/wiki/WorldEdit/Selection#Contracting_2_axes_simultaneously_.28inset.29
    local amt = WE.normalArgs[1]
    if tonumber(amt) then
        amt = tonumber(amt)
        if WE.pos[1].x > WE.pos[2].x then
            WE.pos[1].x = WE.pos[1].x + amt
            WE.pos[2].x = WE.pos[2].x - amt
        else
            WE.pos[1].x = WE.pos[1].x - amt
            WE.pos[2].x = WE.pos[2].x + amt
        end
        if WE.pos[1].z > WE.pos[2].z then
            WE.pos[1].z = WE.pos[1].z + amt
            WE.pos[2].z = WE.pos[2].z - amt
        else
            WE.pos[1].z = WE.pos[1].z - amt
            WE.pos[2].z = WE.pos[2].z + amt
        end
        if WE.pos[1].y > WE.pos[2].y then
            WE.pos[1].y = math.max(0, math.min(WE.pos[1].y + amt, 256))
            WE.pos[2].y = math.max(0, math.min(WE.pos[2].y - amt, 256))
        else
            WE.pos[1].y = math.max(0, math.min(WE.pos[1].y - amt, 256))
            WE.pos[2].y = math.max(0, math.min(WE.pos[2].y + amt, 256))
        end
    end
    if WE.makeSelection[WE.selection.type] then
        WE.makeSelection[WE.selection.type]()
    else
        WE.sendChat(("Selection mode %s not implemented correctly!"):format(WE.selection.type))
        return
    end
    WE.sendChat("Selection outset " .. amt .. " block" .. ((tonumber(amt) > 1 and "s") or "") .. ".")
end

function WE.makeSelection.cuboid()
    --- Makes a cuboid selection given two points are selected.
    WE.selection = { pos1 = WE.pos[1], pos2 = WE.pos[2], type = "cuboid" }
    for x = math.min(WE.pos[1].x, WE.pos[2].x), math.max(WE.pos[1].x, WE.pos[2].x) do
        for y = math.min(WE.pos[1].y, WE.pos[2].y), math.max(WE.pos[1].y, WE.pos[2].y) do
            for z = math.min(WE.pos[1].z, WE.pos[2].z), math.max(WE.pos[1].z, WE.pos[2].z) do
                WE.selection[#WE.selection + 1] = { x = x, y = y, z = z }
            end
        end
    end
    WE.writeSelection()
    return WE.selection
end

WE.registerCommand("inset", cuboid.inset, WE.hasSelection, WE.missingPos)
WE.registerCommand("outset", cuboid.outset, WE.hasSelection, WE.missingPos)

return cuboid
