--WE_Ellipse
Selection = Selection or {} --Only create globals in the outermost scope.
pos = pos or {}

function makeEllipseSelection()
    if not pos or not pos[1] or not pos[2] then
        sendChat "Select something first!"
        return
    end
    local dx = pos[2].x - pos[1].x --Delta X from corner to center, or radius X.
    local dy = pos[2].y - pos[1].y --Delta Y from corner to center, or radius Y.
    local dz = pos[2].z - pos[1].z --Delta Z from corner to center, or radius Z.
    local centerPoint = pos[1]
    centerPoint.x, centerPoint.y, centerPoint.z = math.floor(centerPoint.x, centerPoint.y, centerPoint.z)
    centerPoint.x, centerPoint.y, centerPoint.z = centerPoint.x + .5, centerPoint.y + .5, centerPoint.z + .5
    local cornerPoint = pos[2]
    cornerPoint.x, cornerPoint.y, cornerPoint.z = math.floor(cornerPoint.x, cornerPoint.y, cornerPoint.z)
    cornerPoint.x, cornerPoint.y, cornerPoint.z = cornerPoint.x + .5, cornerPoint.y + .5, cornerPoint.z + .5
    local corner1 = cornerPoint
    local corner2 = { x = corner1.x - 2 * dx, y = corner1.y - 2 * dy, z = corner1.z - 2 * dz }
    Selection = { pos1 = corner1, pos2 = corner2, center = centerPoint, corner = cornerPoint, type = "ellipse" }
    for x = math.min(corner1.x, corner2.x), math.max(corner1.x, corner2.x) do
        for y = math.min(corner1.y, corner2.y), math.max(corner1.y, corner2.y) do
            for z = math.min(corner1.z, corner2.z), math.max(corner1.z, corner2.z) do
                if (x + .5 - centerPoint.x) ^ 2 / dx ^ 2 + (y + .5 - centerPoint.y) ^ 2 / dy ^ 2 + (z + .5 - centerPoint.z) ^ 2 / dz ^ 2 <= 1 then
                    table.insert(Selection, { x = x, y = y, z = z })
                end
            end
        end
    end
    writeSelection(Selection)
    return Selection
end

ellipse = {} --Needs to exist to detect if WE_Ellipse was loaded correctly.

function ellipse.expand()
    local direction
    local amt
    if not isDirection(direction) then return end
    for i = 1, #normalArgs do
        local currentArg = normalArgs[i]
        if isDirection(currentArg) then
            direction = currentArg
        elseif tonumber(currentArg) then
            amt = tonumber(currentArg)
        end
    end
    direction = (not isDirection(direction) or direction == "self" or direction == "me") and getDirection(true):lower() or direction
    resetPos()
    pos[1], pos[2] = Selection.center, Selection.corner
    if Direction == "west" or Direction == "east" then
        pos[2].x = pos[2].x + (pos[1].x > pos[2].x and -amt or amt)
    elseif Direction == "north" or direction == "south" then
        pos[2].z = pos[2].z + (pos[1].z > pos[2].z and -amt or amt)
    elseif Direction == "up" or direction == "down" then
        pos[2].y = math.max(0, math.min(pos[2].y + (pos[1].y > pos[2].y and -amt or amt), 256))
    else
        sendChat "Incorrect direction."
        return
    end
    makeEllipseSelection()
end

function ellipse.contract()
    local direction
    local amt
    if not isDirection(direction) then return end
    for i = 1, #normalArgs do
        local currentArg = normalArgs[i]
        if isDirection(currentArg) then
            direction = currentArg
        elseif tonumber(currentArg) then
            amt = tonumber(currentArg)
        end
    end
    direction = (not isDirection(direction) or direction == "self" or direction == "me") and getDirection(true):lower() or direction
    resetPos()
    pos[1], pos[2] = Selection.center, Selection.corner
    if Direction == "west" or Direction == "east" then
        pos[2].x = pos[2].x + (pos[1].x > pos[2].x and amt or -amt)
    elseif Direction == "up" or direction == "down" then
        pos[2].y = math.max(0, math.min(pos[2].y + (pos[1].y > pos[2].y and amt or -amt), 256))
    elseif Direction == "north" or direction == "south" then
        pos[2].z = pos[2].z + (pos[1].z > pos[2].z and amt or -amt)
    else
        sendChat "Incorrect direction."
        return
    end
    makeEllipseSelection()
end

function ellipse.inset()
    local amt
    if not isDirection(direction) then return end
    for i = 1, #normalArgs do
        local currentArg = normalArgs[i]
        if tonumber(currentArg) then
            amt = tonumber(currentArg)
            break
        end
    end
    pos[2].x = pos[2].x + (pos[1].x > pos[2].x and -amt or amt)
    pos[2].y = math.max(pos[2].y + (pos[1].y > pos[2].y and -amt or amt), 256)
    pos[2].z = pos[2].z + (pos[1].z > pos[2].z and -amt or amt)
    makeEllipseSelection()
end

function ellipse.outset()
    local amt
    if not isDirection(direction) then return end
    for i = 1, #normalArgs do
        local currentArg = normalArgs[i]
        if tonumber(currentArg) then
            amt = tonumber(currentArg)
            break
        end
    end
    pos[2].x = pos[2].x + (pos[1].x > pos[2].x and amt or -amt)
    pos[2].y = math.min(pos[2].y + (pos[1].y > pos[2].y and amt or -amt), 256)
    pos[2].z = pos[2].z + (pos[1].z > pos[2].z and amt or -amt)
    makeEllipseSelection()
end
