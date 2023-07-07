--WE_Ellipse
WE.selection = WE.selection or {} --Only create globals in the outermost scope.
WE.pos = WE.pos or {}

function WE.makeSelection.ellipse()
    if not WE.pos or not WE.pos[1] or not WE.pos[2] then
        WE.sendChat "Select something first!"
        return
    end
    local dx = WE.pos[2].x - WE.pos[1].x --Delta X from corner to center, or radius X.
    local dy = WE.pos[2].y - WE.pos[1].y --Delta Y from corner to center, or radius Y.
    local dz = WE.pos[2].z - WE.pos[1].z --Delta Z from corner to center, or radius Z.
    local centerPoint = WE.pos[1]
    centerPoint.x, centerPoint.y, centerPoint.z = math.floor(centerPoint.x, centerPoint.y, centerPoint.z)
    centerPoint.x, centerPoint.y, centerPoint.z = centerPoint.x + .5, centerPoint.y + .5, centerPoint.z + .5
    local cornerPoint = WE.pos[2]
    cornerPoint.x, cornerPoint.y, cornerPoint.z = math.floor(cornerPoint.x, cornerPoint.y, cornerPoint.z)
    cornerPoint.x, cornerPoint.y, cornerPoint.z = cornerPoint.x + .5, cornerPoint.y + .5, cornerPoint.z + .5
    local corner1 = cornerPoint
    local corner2 = { x = corner1.x - 2 * dx, y = corner1.y - 2 * dy, z = corner1.z - 2 * dz }
    WE.selection = { pos1 = corner1, pos2 = corner2, center = centerPoint, corner = cornerPoint, type = "ellipse" }
    for x = math.min(corner1.x, corner2.x), math.max(corner1.x, corner2.x) do
        for y = math.min(corner1.y, corner2.y), math.max(corner1.y, corner2.y) do
            for z = math.min(corner1.z, corner2.z), math.max(corner1.z, corner2.z) do
                if (x + .5 - centerPoint.x) ^ 2 / dx ^ 2 + (y + .5 - centerPoint.y) ^ 2 / dy ^ 2 + (z + .5 - centerPoint.z) ^ 2 / dz ^ 2 <= 1 then
                    table.insert(WE.selection, { x = x, y = y, z = z })
                end
            end
        end
    end
    WE.writeSelection(WE.selection)
    return WE.selection
end

local ellipse = { name = "ellipse" } --Needs to exist to detect if WE_Ellipse was loaded correctly.

function ellipse.expand()
    local direction
    local amt
    if not WE.isDirection(direction) then
        return
    end
    for i = 1, #WE.normalArgs do
        local currentArg = WE.normalArgs[i]
        if WE.isDirection(currentArg) then
            direction = currentArg
        elseif tonumber(currentArg) then
            amt = tonumber(currentArg)
        end
    end
    direction = (not WE.isDirection(direction) or direction == "self" or direction == "me") and WE.getDirection(true):lower() or direction
    resetPos()
    WE.pos[1], WE.pos[2] = WE.selection.center, WE.selection.corner
    if WE.direction == "west" or WE.direction == "east" then
        WE.pos[2].x = WE.pos[2].x + (WE.pos[1].x > WE.pos[2].x and -amt or amt)
    elseif WE.direction == "north" or direction == "south" then
        WE.pos[2].z = WE.pos[2].z + (WE.pos[1].z > WE.pos[2].z and -amt or amt)
    elseif WE.direction == "up" or direction == "down" then
        WE.pos[2].y = math.max(0, math.min(WE.pos[2].y + (WE.pos[1].y > WE.pos[2].y and -amt or amt), 256))
    else
        WE.sendChat "Incorrect direction."
        return
    end
    if WE.makeSelection[WE.selection.type] then
        WE.makeSelection[WE.selection.type]()
    else
        WE.sendChat(("Selection mode %s not implemented correctly!"):format(WE.selection.type))
    end
end

function ellipse.contract()
    local direction
    local amt
    if not WE.isDirection(direction) then
        return
    end
    for i = 1, #WE.normalArgs do
        local currentArg = WE.normalArgs[i]
        if WE.isDirection(currentArg) then
            direction = currentArg
        elseif tonumber(currentArg) then
            amt = tonumber(currentArg)
        end
    end
    direction = (not WE.isDirection(direction) or direction == "self" or direction == "me") and WE.getDirection(true):lower() or direction
    resetPos()
    WE.pos[1], WE.pos[2] = WE.selection.center, WE.selection.corner
    if WE.direction == "west" or WE.direction == "east" then
        WE.pos[2].x = WE.pos[2].x + (WE.pos[1].x > WE.pos[2].x and amt or -amt)
    elseif WE.direction == "up" or direction == "down" then
        WE.pos[2].y = math.max(0, math.min(WE.pos[2].y + (WE.pos[1].y > WE.pos[2].y and amt or -amt), 256))
    elseif WE.direction == "north" or direction == "south" then
        WE.pos[2].z = WE.pos[2].z + (WE.pos[1].z > WE.pos[2].z and amt or -amt)
    else
        WE.sendChat "Incorrect direction."
        return
    end
    if WE.makeSelection[WE.selection.type] then
        WE.makeSelection[WE.selection.type]()
    else
        WE.sendChat(("Selection mode %s not implemented correctly!"):format(WE.selection.type))
    end
end

function ellipse.inset()
    local amt
    if not WE.isDirection(direction) then
        return
    end
    for i = 1, #WE.normalArgs do
        local currentArg = WE.normalArgs[i]
        if tonumber(currentArg) then
            amt = tonumber(currentArg)
            break
        end
    end
    WE.pos[2].x = WE.pos[2].x + (WE.pos[1].x > WE.pos[2].x and -amt or amt)
    WE.pos[2].y = math.max(WE.pos[2].y + (WE.pos[1].y > WE.pos[2].y and -amt or amt), 256)
    WE.pos[2].z = WE.pos[2].z + (WE.pos[1].z > WE.pos[2].z and -amt or amt)
    if WE.makeSelection[WE.selection.type] then
        WE.makeSelection[WE.selection.type]()
    else
        WE.sendChat(("Selection mode %s not implemented correctly!"):format(WE.selection.type))
    end
end

function ellipse.outset()
    local amt
    if not WE.isDirection(direction) then
        return
    end
    for i = 1, #WE.normalArgs do
        local currentArg = WE.normalArgs[i]
        if tonumber(currentArg) then
            amt = tonumber(currentArg)
            break
        end
    end
    WE.pos[2].x = WE.pos[2].x + (WE.pos[1].x > WE.pos[2].x and amt or -amt)
    WE.pos[2].y = math.min(WE.pos[2].y + (WE.pos[1].y > WE.pos[2].y and amt or -amt), 256)
    WE.pos[2].z = WE.pos[2].z + (WE.pos[1].z > WE.pos[2].z and amt or -amt)
    if WE.makeSelection[WE.selection.type] then
        WE.makeSelection[WE.selection.type]()
    else
        WE.sendChat(("Selection mode %s not implemented correctly!"):format(WE.selection.type))
    end
end

return ellipse
