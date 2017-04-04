sel = sel or {}

function oppositeDirection(dir) --Returns the direction opposite of the one provided (up returns down, east returns west, etc.)
    return ({ north = "south", south = "north", east = "west", west = "east", up = "down", down = "up" })[dir:lower()] or false
end

function isDirection(dir) --Returns if the given string is a direction
    return tablex.indexOf({ "up", "down", "north", "south", "east", "west", "self", "me" }, dir) ~= nil
end

function hasDirection(str) --Returns whether the given string contains a direction in it
    for _, dir in pairs { "up", "down", "north", "south", "east", "west", "self", "me" } do
        if str:find(" " .. dir) then
            return true
        end
    end
    return false
end

--Returns a heightmap for the selected area.
function heightmap()
    local map = {}
    local cnt = 1
    local blocksChecked = 0
    local timeDelay = 2.5 --Seconds before it prints out a percentage
    local x, z
    local yMin, yMax = Selection[1].y, Selection[1].y
    for i = 2, #Selection do
        yMin = math.min(yMin, Selection[i].y)
        yMax = math.max(yMax, Selection[i].y)
    end
    local Selection = getFlatSelection(Selection)
    local tbl
    if isCommandComputer then
        tbl = selectLargeArea(Selection.pos1.x, Selection.pos1.y, Selection.pos1.z, Selection.pos2.x, Selection.pos2.y, Selection.pos2.z, 4096, true)
        timeDelay = tbl.size
    end
    if #Selection > 0 then
        for i = 1, #Selection do
            if not map[cnt] then
                map[cnt] = {} --Make sure there is a subtable in there
            end
            map[cnt].x = Selection[i].x --Store X coordinate
            map[cnt].z = Selection[i].z --Store Z coordinate
            x, z = Selection[i].x, Selection[i].z
            for yVal = yMax, yMin, -1 do
                if (tbl and tbl[x][yVal][z].name ~= "minecraft:air") or (not tbl and getBlockID(x, yVal, z) ~= 0) then
                    map[cnt].y = yVal --Store Y coordinate
                    break
                end
                blocksChecked = blocksChecked + 1
                if blocksChecked % (timeDelay * 20) == 1 and isCommandComputer then
                    if blocksChecked == 1 then
                        sendChat "Generating heightmap..."
                    end
                    sendChat(("%.1f%% Complete."):format(i / #Selection * 100))
                end
            end --Note, it WILL return nil if there isn't a highest block.
            cnt = cnt + 1
        end
    else
        sendChat "Make a selection first!"
        return false
    end
    return map
end

--This will count all the blocks in the selection, specifying the distribution of blocks.
function sel.distr() --http://wiki.sk89q.com/wiki/WorldEdit/Selection#Finding_the_block_distribution
    local blockCount = {}
    local TotalCount = 0
    local useClipboard, air, useData, useAir
    for i = 1, #shortSwitches do
        local currentSwitch = shortSwitches[i]
        if currentSwitch == "-c" then
            useClipboard = true
        elseif currentSwitch == "-d" then
            useData = true
        elseif currentSwitch == "-a" then
            useAir = true
        end
    end
    local tbl = (useClipboard and #Clipboard > 0) and Clipboard or Selection
    local blocksTbl
    if isCommandComputer then
        blocksTbl = selectLargeArea(Selection.pos1.x, Selection.pos1.y, Selection.pos1.z, Selection.pos2.x, Selection.pos2.y, Selection.pos2.z, 4096, true)
    end
    if not useData then --Check for -d flag
        for i = 1, #Selection do
            local x = Selection[i].x
            local y = Selection[i].y
            local z = Selection[i].z
            local blockID = blocksTbl and MCNameToID(blocksTbl[x][y][z].name) or getBlockID(x, y, z)
            if not air or (air and blockID ~= 0) then
                blockCount[blockID] = blockCount[blockID] and (blockCount[blockID] + 1) or 1 --Count blocks
            end
        end
    else
        for i = 1, #Selection do
            local x = Selection[i].x
            local y = Selection[i].y
            local z = Selection[i].z
            local blockID = tonumber(blocksTbl and MCNameToID(blocksTbl[x][y][z].name) or getBlockID(x, y, z))
            local meta = blocksTbl and blocksTbl[x][y][z].metadata or getMetadata(x, y, z)
            if blockCount[blockID] and blockCount[blockID][meta] and not air or (air and blockID ~= 0) then
                blockCount[blockID] = blockCount[blockID] or {}
                blockCount[blockID][meta] = (blockCount[blockID][meta] or 0) + 1 --Store the amount of blocks for the given Block ID with the given meta
            elseif not air or (air and blockID ~= 0) then
                blockCount[blockID] = {} --Make sure there is a subtable in there.
                blockCount[blockID][meta] = 1 --Make sure the entry exists first or it will throw an error!
            end
        end
    end
    for k, v in pairs(blockCount) do --Count total number of blocks
        if useData then
            for k2, v2 in pairs(v) do
                TotalCount = TotalCount + v2
            end
        else
            TotalCount = TotalCount + v
        end
    end
    for k, v in pairs(blockCount) do
        if not message:find "-d" then
            sendChat(v .. ("  (%.2f%%) "):format(v / TotalCount * 100) .. (BlockNames[k] and (BlockNames[k][1]:sub(1, 1):upper() .. BlockNames[k][1]:sub(2):gsub("_", " ")) or k) .. " #" .. k) --This takes the first entry in the BlockNames table and force capitalizes the first letter.
        else
            for k2, v2 in pairs(i) do --Go through all meta values
                sendChat(v2 .. ("  (%.2f%%) "):format(v2 / TotalCount * 100) .. (BlockNames[k] and (BlockNames[k][1]:sub(1, 1):upper() .. BlockNames[k][1]:sub(2):gsub("_", " ")) or k) .. " #" .. k .. ":" .. k2) --Check the comment before last! This one just has a ":[Metadata]" at the end!
            end
        end
    end
end

function sel.count() --http://wiki.sk89q.com/wiki/WorldEdit/Selection#Calculating_a_block.27s_frequency
    if #normalArgs == 0 then
        sendChat "Specify the block you want to count!"
        return
    end
    local checkMeta = false
    for i = 1, #shortSwitches do
        if shortSwitches[i] == "-d" then
            checkMeta = true
        end
    end
    local findColon, findColonEnd = message:find ":" --Find the colon for the meta
    local findSpace, findSpaceEnd = message:find " " --Find the space to get the argument
    if findColon and not CheckMeta then
        sendChat "Use the -d flag for data values!"
        return false
    end --Why yes, this IS the ConvertName() function repurposed!
    local ID, Meta
    if CheckMeta and findColon then
        ID = message:sub(findSpace + 1, findColon - 1)
        Meta = message:sub(findColon + 1)
    elseif findSpace then
        ID = message:sub(findSpace + 1)
        Meta = nil --No meta means no meta!
    end
    if not tonumber(ID) then
        for k, v in pairs(BlockNames) do
            if tablex.indexOf(v, ID) then
                if k == 17 then
                    if ID == "pine" then
                        Meta = 1
                    elseif ID == "birch" then
                        Meta = 2
                    elseif ID == "jungle" then
                        Meta = 3
                    end
                    ID = k
                    break
                elseif k == 162 then
                    if ID == "darkoak" then
                        Meta = 1
                    end
                    ID = k
                    break
                elseif k == 12 then
                    if ID == "redsand" or ID == "red_sand" then
                        Meta = 1
                    end
                    ID = k
                    break
                else
                    ID = k
                    break
                end
            elseif next(BlockNames, k) == nil then
                sendChat(("Invalid Block: \"%s\". Was it a typo?"):format(ID))
                return false
            end
        end
    end
    local Num = 0
    local tbl
    if isCommandComputer then
        tbl = selectLargeArea(Selection.pos1.x, Selection.pos1.y, Selection.pos1.z, Selection.pos2.x, Selection.pos2.y, Selection.pos2.z, 4096, true)
    end
    for i = 1, #Selection do --The for loops like this just mean "Go through all of the coordinates in a rectangular area."
        local x = Selection[i].x
        local y = Selection[i].y
        local z = Selection[i].z
        if Meta then --If there's meta, check for it
            if (tbl and MCNameToID(tbl[x][y][z].name) == ID and (Meta < 0 or tbl[x][y][z].metadata == Meta)) or (getBlockID(x, y, z) == ID and getMetadata(x, y, z) == Meta) then
                Num = Num + 1
            end
        else
            if getBlockID(x, y, z) == ID or MCNameToID(tbl[x][y][z].name) == ID then --If there isn't, don't.
                Num = Num + 1
            end
        end
    end
    if not Meta then
        sendChat(("Counted: %d %s%s"):format(Num, message:sub(findSpace + 1, findSpace + 1):upper(), message:sub(findSpace + 2))) --Tell how many counted and it spits back out what block the player said it was. No need to reference BlockNames!
    else
        sendChat(("Counted: %d %s%s"):format(Num, message:sub(findSpace + 1, findSpace + 1):upper(), message:sub(findSpace + 2, findColon - 1)))
    end
end

function sel.size() --http://wiki.sk89q.com/wiki/WorldEdit/Selection#Getting_selection_size
    if message:find "-c" then
        sendChat(("There are %d blocks in the clipboard."):format(#Clipboard)) --Fortunately, it does store air blocks as well.
    else
        sendChat(("There are %d blocks in the selection."):format(#Selection))
    end
end

function sel.set(silent) --http://wiki.sk89q.com/wiki/WorldEdit/Region_operations#Setting_blocks
    local count = 0
    local iterations = 0
    silent = silent or forceSilent
    if #Selection > 0 then
        if not silent then
            sendChat "Scanning..."
        end
        local blocksTbl = selectLargeArea(Selection.pos1.x, Selection.pos1.y, Selection.pos1.z, Selection.pos2.x, Selection.pos2.y, Selection.pos2.z, 4096, true)
        if not silent then
            sendChat "Scanning complete!"
        end
        for i = 1, #Selection do --Go through all of the blocks in the selection...
            local x = Selection[i].x
            local y = Selection[i].y
            local z = Selection[i].z
            local blockChanged, BlockType, RandomRoll
            if #Blocks2 > 0 then
                if TotalPercent ~= 0 then
                    repeat
                        BlockType = math.random(1, #Blocks2)
                        RandomRoll = math.frandom(0, TotalPercent)
                    until RandomRoll <= tonumber(Percentages[BlockType]) --Pick weighted random numbers, so that it picks a block randomly using the probabilities given by the user.
                else
                    BlockType = 1 --If there's only one block, use it!
                end
                blockChanged = blockHasChanged(x, y, z, Blocks2[BlockType], Meta2[BlockType], blocksTbl, true)
                if blockChanged then
                    setBlock(x, y, z, Blocks2[BlockType], Meta2[BlockType])
                    iterations = iterations + 1 --Count how many blocks actually changed.
                end
                if i == 1 and not silent then
                    sendChat "Setting blocks..."
                end
            end
        end
    end
    if not silent then
        sendChat(("%s blocks changed."):format(iterations == 0 and "No" or iterations))
    end
end

function sel.replace(silent) --http://wiki.sk89q.com/wiki/WorldEdit/Region_operations#Replacing_blocks
    local iterations = 0
    local sleepInterval = sleepInterval or 25000
    local sleepInterval2 = sleepInterval or 6
    silent = silent or forceSilent
    local tbl
    if #Selection > 0 then
        for i = 1, #Selection do --Go through all of the blocks in the selection...
            local x = Selection[i].x
            local y = Selection[i].y
            local z = Selection[i].z
            local BlockType, RandomRoll
            if TotalPercent ~= 0 then
                repeat
                    BlockType = math.random(1, #Blocks2)
                    RandomRoll = math.frandom(0, TotalPercent)
                until RandomRoll <= tonumber(Percentages[BlockType])
            else
                BlockType = 1
            end
            if not isCommandComputer then
                for i = 1, #Blocks do
                    if blockEquals(x, y, z, Blocks[i], Meta[i]) then --If they match any of them...
                        setBlock(x, y, z, Blocks2[BlockType], Meta2[BlockType])
                        iterations = iterations + 1 --Count how many blocks were changed.
                        break
                    end
                end
            else
                if tbl == nil then
                    if not silent then
                        sendChat "Scanning..."
                    end
                    tbl = selectLargeArea(Selection.pos1.x, Selection.pos1.y, Selection.pos1.z, Selection.pos2.x, Selection.pos2.y, Selection.pos2.z, 4096, true)
                    if not silent then
                        sendChat "Scanning complete!"
                    end
                end
                for i = 1, #Blocks do
                    if tbl[x][y][z].name == (idToMCName(Blocks[i]) or Blocks[i]) and (tbl[x][y][z].metadata == Meta[i] or Meta[1] < 0) then
                        setBlock(x, y, z, Blocks2[BlockType], Meta2[BlockType])
                        iterations = iterations + 1 --Count how many blocks were changed.
                        break
                    end
                end
            end
            if i == 1 and not silent then
                sendChat "Replacing blocks..."
            end
        end
    end
    if not silent then
        sendChat(("%s blocks changed."):format(iterations == 0 and "No" or iterations))
    end
end

function sel.naturalize(silent) --Makes the given area look more natural.
    local iterations = 0
    local Map = heightmap()
    silent = silent or forceSilent
    local BlocksTbl
    if isCommandComputer then
        BlocksTbl = selectLargeArea(Selection.pos1.x, Selection.pos1.y, Selection.pos1.z, Selection.pos2.x, Selection.pos2.y, Selection.pos2.z, 4096, true)
    end
    for i = 1, #Map do
        local x, y, z = Map[i].x, Map[i].y, Map[i].z
        if y then
            for j = 0, Map[i].y - math.min(Selection.pos1.y, Selection.pos2.y) do
                local ID = BlocksTbl and MCNameToID(BlocksTbl[x][y - j][z].name) or tonumber(getBlockID(x, y - j, z))
                if ID == 1 or ID == 2 or ID == 3 then
                    local naturalBlockID = j > 3 and 1 or (j == 0 and 2) or 3
                    if blockHasChanged(x, y - j, z, naturalBlockID, 0) then
                        iterations = iterations + 1
                        setBlock(x, y - j, z, naturalBlockID, 0)
                    end
                    if i == 1 and not silent then
                        sendChat "Naturalizing..."
                    end
                end
            end
        end
    end
    if not silent then
        sendChat(("%s blocks changed."):format(iterations == 0 and "No" or iterations))
    end
end

function sel.overlay(silent) --Overlays the selection with the given block
    local count = 0
    local count2 = 0
    local iterations = 0
    local Map = heightmap()
    local BlockType
    silent = silent or forceSilent
    for i = 1, #Map do
        if tonumber(Map[i].y) and (SelectionType == "cuboid" and tonumber(Map[i].y) <= math.max(Selection.pos1.y, Selection.pos2.y) or SelectionType ~= "cuboid") then
            local x, y, z = Map[i].x, Map[i].y + 1, Map[i].z
            count = count + 1
            if TotalPercent ~= 0 then
                repeat
                    BlockType = math.random(1, #Blocks2)
                    local RandomRoll = math.frandom(0, TotalPercent)
                until RandomRoll <= tonumber(Percentages[BlockType])
            else
                local BlockType = 1
            end
            local blockChanged = blockHasChanged(x, y, z, Blocks2[BlockType], Meta2[BlockType])
            if blockChanged then
                setBlock(x, y, z, Blocks2[BlockType], Meta2[BlockType])
            end
            if blockChanged then --If the block is actually CHANGED.
                iterations = iterations + 1 --Count how many blocks actually changed.
            end
            if i == 1 and not silent then
                sendChat "Overlaying blocks..."
            end
        end
    end
    if not silent then
        sendChat(("%s blocks changed."):format(iterations == 0 and "No" or iterations))
    end
end

function sel.shift(silent) --http://wiki.sk89q.com/wiki/WorldEdit/Selection#Shifting_your_selection
    local dir = false
    silent = silent or forceSilent
    local shiftAmt, direction
    for i = 1, #normalArgs do
        if tonumber(normalArgs[i]) then
            dir = true
            shiftAmt = tonumber(normalArgs[i])
        elseif isDirection(normalArgs[i]) then
            direction = normalArgs[i]
        end
    end
    if tonumber(command) and not dir then
        direction = getDirection(true):lower()
        if not direction then return end
        dir = true
    end
    if not isDirection(direction) then
        sendChat(("Invalid direction: %s"):format(direction))
        return
    end
    if not shiftAmt then
        sendChat "No amount found!"
        return
    end
    local field = { east = "x", west = "x", north = "z", south = "z", up = "y", down = "y" }
    local mult = { east = 1, west = -1, north = -1, south = 1, up = 1, down = -1 }
    for i = 1, #Selection do
        Selection[i][field[direction]] = Selection[i][field[direction]] + shiftAmt * mult[direction] --Shift each block in the selection over in the correct direction.
    end
    for i = 1, #pos do
        pos[i][field[direction]] = pos[i][field[direction]] + shiftAmt * mult[direction] --Shift each position over as well
    end
    if SelectionType == "cuboid" and cuboid then
        makeCuboidSelection()
    elseif SelectionType == "poly" and poly then
        makePolySelection()
    elseif SelectionType == "ellipse" and ellipse then --Might as well put it here for later.
        makeEllipseSelection()
    end
    if not silent then
        sendChat(("Region shifted %d block%s %s. (%d)"):format(shiftAmt, shiftAmt ~= 1 and "s" or "", direction, #Selection))
    end
end

registerCommand("set", function() parseBlockPatterns() if convertName(Blocks, Meta) and convertName(Blocks2, Meta2) then sel.set() end end, hasSelection, missingPos)
registerCommand("replace", function() parseBlockPatterns() if convertName(Blocks, Meta) and convertName(Blocks2, Meta2) then sel.replace() end end, hasSelection, missingPos)
registerCommand("naturalize", sel.naturalize, hasSelection, missingPos)
registerCommand("overlay", function() parseBlockPatterns() convertName() sel.overlay() end, hasSelection, missingPos)

