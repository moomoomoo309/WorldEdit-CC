local sel = { name = "sel" }

--Returns a heightmap for the selected area.
function heightmap()
    local map = {}
    local cnt = 1
    local blocksChecked = 0
    local timeDelay = 2.5 --Seconds before it prints out a percentage
    local x, z
    local yMin, yMax = WE.Selection[1].y, WE.Selection[1].y
    for i = 2, #WE.Selection do
        yMin = math.min(yMin, WE.Selection[i].y)
        yMax = math.max(yMax, WE.Selection[i].y)
    end
    local Selection = getFlatSelection(WE.Selection)
    local tbl
    if WE.isCommandComputer then
        tbl = WE.selectLargeArea(WE.Selection.pos1.x, WE.Selection.pos1.y, WE.Selection.pos1.z, WE.Selection.pos2.x, WE.Selection.pos2.y, WE.Selection.pos2.z, 4096, true)
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
                if (tbl and not tablex.find(WE.blockBlacklist, tbl[x][yVal][z].name)) or (not tbl and WE.getBlockID(x, yVal, z) ~= 0) then
                    map[cnt].y = yVal --Store Y coordinate
                    break
                end
                blocksChecked = blocksChecked + 1
                if blocksChecked % (timeDelay * 20) == 1 and WE.isCommandComputer then
                    if blocksChecked == 1 then
                        WE.sendChat "Generating heightmap..."
                    end
                    WE.sendChat(("%.1f%% Complete."):format(i / #WE.Selection * 100))
                end
            end --Note, it WILL return nil if there isn't a highest block.
            cnt = cnt + 1
        end
    else
        WE.sendChat "Make a selection first!"
        return false
    end
    return map
end

--Parses the message for set and replace
local function parseBlockPatterns()
    local function splitTbls(text, needsPercent)
        local BlocksTbl = {}
        local MetaTbl = {}
        local PercentagesTbl = {}
        local PipeTbl = {}
        local tmpBlocks = stringx.split(text, ",") --Split each block type
        for i = 1, #tmpBlocks do
            local findColon = tmpBlocks[i]:find(":", nil, true) --Check if the meta was specified
            local findPipe = tmpBlocks[i]:find("|", nil, true) --Check if NBT was specified
            if findColon then
                --If it was, put the ID and meta in, otherwise, put the ID in and -1 for the meta.
                table.insert(BlocksTbl, tonumber(tmpBlocks[i]:sub(1, findColon - 1)) or tmpBlocks[i]:sub(1, findColon - 1))
                if findPipe then
                    table.insert(MetaTbl, tmpBlocks[i]:sub(findColon + 1, findPipe - 1))
                    table.insert(PipeTbl, tmpBlocks[i]:sub(findPipe + 1))
                else
                    table.insert(MetaTbl, tmpBlocks[i]:sub(findColon + 1))
                    table.insert(PipeTbl, false)
                end
            else
                if findPipe then
                    table.insert(BlocksTbl, tonumber(tmpBlocks[i]:sub(1, findPipe - 1)) or tmpBlocks[i]:sub(1, findPipe - 1))
                    table.insert(PipeTbl, tmpBlocks[i]:sub(findPipe + 1))
                else
                    table.insert(BlocksTbl, tonumber(tmpBlocks[i]) or tmpBlocks[i])
                    table.insert(PipeTbl, false)
                end
                table.insert(MetaTbl, -1)
            end
        end
        if needsPercent then
            for i = 1, #BlocksTbl do
                local tmpBlocks2 = stringx.split(tostring(BlocksTbl[i]), "%")
                if #tmpBlocks2 == 2 then
                    BlocksTbl[i] = tonumber(tmpBlocks2[2]) or tmpBlocks2[2]
                    PercentagesTbl[i] = tmpBlocks2[1]
                else
                    BlocksTbl[i] = tonumber(tmpBlocks2[1]) or tmpBlocks2[1]
                    PercentagesTbl[i] = PercentagesTbl[i] or false --This could be any non-number.
                end
            end
        end
        if needsPercent then
            return BlocksTbl, MetaTbl, PercentagesTbl, PipeTbl
        else
            return BlocksTbl, MetaTbl
        end
    end

    local Blocks, Meta, Blocks2, Meta2, Percentages, Pipes
    if #WE.normalArgs == 2 then
        --If two types of blocks were specified
        Blocks, Meta = splitTbls(WE.normalArgs[1], false)
        Blocks2, Meta2, Percentages, Pipes = splitTbls(WE.normalArgs[2], true)
    else
        Blocks2, Meta2, Percentages, Pipes = splitTbls(WE.normalArgs[1], true)
    end

    local TotalPercent = 0 --Convert ones without percentages to ones WITH percentages!
    local Spaces = 0
    for i = 1, #Percentages do
        if not tonumber(Percentages[i]) then
            Spaces = Spaces + 1
        end
    end
    if Spaces == #Percentages then
        for i = 1, #Percentages do
            Percentages[i] = 1
        end
    end
    for i = 1, #Percentages do
        if tonumber(Percentages[i]) then
            TotalPercent = TotalPercent + Percentages[i]
        end
    end
    for i = 1, #Percentages do
        if not tonumber(Percentages[i]) then
            Percentages[i] = TotalPercent / (#Percentages - Spaces)
        end
    end
    if #WE.normalArgs == 2 then
        return Blocks, Meta, Blocks2, Meta2, Percentages, Pipes
    else
        return Blocks2, Meta2, Percentages, Pipes
    end
end

--This will count all the blocks in the selection, specifying the distribution of blocks.
function sel.distr()
    --http://wiki.sk89q.com/wiki/WorldEdit/Selection#Finding_the_block_distribution
    local blockCount = {}
    local TotalCount = 0
    local useClipboard, useData, useAir
    for i = 1, #WE.shortSwitches do
        local currentSwitch = WE.shortSwitches[i]
        if currentSwitch == "-c" then
            useClipboard = true
        elseif currentSwitch == "-d" then
            useData = true
        elseif currentSwitch == "-a" then
            useAir = true
        end
    end
    local tbl = (useClipboard and #WE.Clipboard > 0) and WE.Clipboard or WE.Selection
    local blocksTbl
    if not useClipboard and WE.isCommandComputer then
        blocksTbl = WE.selectLargeArea(WE.Selection.pos1.x, WE.Selection.pos1.y, WE.Selection.pos1.z, WE.Selection.pos2.x, WE.Selection.pos2.y, WE.Selection.pos2.z, 4096, true)
    end
    if not useData then
        for i = 1, #tbl do
            local x = tbl[i].x
            local y = tbl[i].y
            local z = tbl[i].z
            local blockID
            if useClipboard then
                blockID = WE.MCNameToID(tbl[i].ID)
            else
                blockID = blocksTbl and WE.MCNameToID(blocksTbl[x][y][z].name) or WE.getBlockID(x, y, z)
            end
            if blockID ~= 0 then
                blockCount[blockID] = blockCount[blockID] and (blockCount[blockID] + 1) or 1 --Count blocks
            end
        end
    else
        for i = 1, #tbl do
            local x = tbl[i].x
            local y = tbl[i].y
            local z = tbl[i].z
            local blockID, meta
            if useClipboard then
                blockID = WE.MCNameToID(tbl[i].ID)
                meta = tonumber(tbl[i].meta)
            else
                blockID = tonumber(blocksTbl and WE.MCNameToID(blocksTbl[x][y][z].name) or WE.getBlockID(x, y, z))
                meta = blocksTbl and blocksTbl[x][y][z].metadata or WE.getMetadata(x, y, z)
            end
            if blockCount[blockID] and blockCount[blockID][meta] and blockID ~= 0 then
                blockCount[blockID] = blockCount[blockID] or {}
                blockCount[blockID][meta] = (blockCount[blockID][meta] or 0) + 1 --Store the amount of blocks for the given Block ID with the given meta
            elseif blockID ~= 0 then
                blockCount[blockID] = {} --Make sure there is a subtable in there.
                blockCount[blockID][meta] = 1 --Make sure the entry exists first or it will throw an error!
            end
        end
    end
    for _, v in pairs(blockCount) do
        --Count total number of blocks
        if useData then
            for _, v2 in pairs(v) do
                TotalCount = TotalCount + v2
            end
        else
            TotalCount = TotalCount + v
        end
    end
    for k, v in pairs(blockCount) do
        if not message:find "-d" then
            WE.sendChat(v .. ("  (%.2f%%) "):format(v / TotalCount * 100) .. (BlockNames[k] and (BlockNames[k][1]:sub(1, 1):upper() .. BlockNames[k][1]:sub(2):gsub("_", " ")) or k) .. " #" .. k) --This takes the first entry in the BlockNames table and force capitalizes the first letter.
        else
            for k2, v2 in pairs(i) do
                --Go through all meta values
                WE.sendChat(v2 .. ("  (%.2f%%) "):format(v2 / TotalCount * 100) .. (BlockNames[k] and (BlockNames[k][1]:sub(1, 1):upper() .. BlockNames[k][1]:sub(2):gsub("_", " ")) or k) .. " #" .. k .. ":" .. k2) --Check the comment before last! This one just has a ":[Metadata]" at the end!
            end
        end
    end
end

function sel.count()
    --http://wiki.sk89q.com/wiki/WorldEdit/Selection#Calculating_a_block.27s_frequency
    if #WE.normalArgs == 0 then
        WE.sendChat "Specify the block you want to count!"
        return
    end
    local checkMeta = WE.shortSwitches.d
    local findColon, findColonEnd = message:find(":", nil, true) --Find the colon for the meta
    local findSpace, findSpaceEnd = message:find(" ", nil, true) --Find the space to get the argument
    if findColon and not checkMeta then
        WE.sendChat "Use the -d flag for data values!"
        return false
    end --Why yes, this IS the ConvertName() function repurposed!
    local ID, Meta
    if checkMeta and findColon then
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
                WE.sendChat(("Invalid Block: \"%s\". Was it a typo?"):format(ID))
                return false
            end
        end
    end
    local Num = 0
    local tbl
    if WE.isCommandComputer then
        tbl = WE.selectLargeArea(WE.Selection.pos1.x, WE.Selection.pos1.y, WE.Selection.pos1.z, WE.Selection.pos2.x, WE.Selection.pos2.y, WE.Selection.pos2.z, 4096, true)
    end
    for i = 1, #WE.Selection do
        --The for loops like this just mean "Go through all of the coordinates in a rectangular area."
        local x = WE.Selection[i].x
        local y = WE.Selection[i].y
        local z = WE.Selection[i].z
        if Meta then
            --If there's meta, check for it
            if (tbl and WE.MCNameToID(tbl[x][y][z].name) == ID and (Meta < 0 or tbl[x][y][z].metadata == Meta)) or (WE.getBlockID(x, y, z) == ID and WE.getMetadata(x, y, z) == Meta) then
                Num = Num + 1
            end
        else
            if WE.getBlockID(x, y, z) == ID or WE.MCNameToID(tbl[x][y][z].name) == ID then
                --If there isn't, don't.
                Num = Num + 1
            end
        end
    end
    if not Meta then
        WE.sendChat(("Counted: %d %s%s"):format(Num, message:sub(findSpace + 1, findSpace + 1):upper(), message:sub(findSpace + 2))) --Tell how many counted and it spits back out what block the player said it was. No need to reference BlockNames!
    else
        WE.sendChat(("Counted: %d %s%s"):format(Num, message:sub(findSpace + 1, findSpace + 1):upper(), message:sub(findSpace + 2, findColon - 1)))
    end
end

function sel.size()
    --http://wiki.sk89q.com/wiki/WorldEdit/Selection#Getting_selection_size
    if WE.shortSwitches.c then
        WE.sendChat(("There are %d blocks in the clipboard."):format(#WE.Clipboard)) --Fortunately, it does store air blocks as well.
    else
        WE.sendChat(("There are %d blocks in the selection."):format(#WE.Selection))
    end
end

function sel.set(silent)
    --http://wiki.sk89q.com/wiki/WorldEdit/Region_operations#Setting_blocks
    local Blocks2, Meta2, Percentages, Pipes = parseBlockPatterns()
    if not WE.convertName(Blocks2, Meta2) then
        WE.sendChat "Could not convert names. Was there a typo?"
        return
    end

    local iterations = 0
    silent = silent or forceSilent

    if #WE.Selection > 0 then
        if not silent then
            WE.sendChat "Scanning..."
        end
        local blocksTbl = WE.selectLargeArea(WE.Selection.pos1.x, WE.Selection.pos1.y, WE.Selection.pos1.z, WE.Selection.pos2.x, WE.Selection.pos2.y, WE.Selection.pos2.z, 4096, true)
        if not silent then
            WE.sendChat "Scanning complete!"
        end
        local set = false
        for i in (WE.RandomSetOrder and randomIPairs or ipairs)(WE.Selection) do
            --Go through all of the blocks in the selection...
            local x = WE.Selection[i].x
            local y = WE.Selection[i].y
            local z = WE.Selection[i].z
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
                local NBT = Pipes[BlockType] and WE.pipeBlocks[WE.idToMCName(Blocks2[BlockType])](stringx.split(Pipes[BlockType], "|"))
                blockChanged = NBT or WE.blockHasChanged(x, y, z, Blocks2[BlockType], Meta2[BlockType], blocksTbl, true)
                if blockChanged then
                    WE.setBlock(x, y, z, Blocks2[BlockType], Meta2[BlockType], NBT)
                    iterations = iterations + 1 --Count how many blocks actually changed.
                end
                if not set and not silent then
                    WE.sendChat "Setting blocks..."
                end
            end
            set = true
        end
    end
    if not silent then
        WE.sendChat(("%s blocks changed."):format(iterations == 0 and "No" or iterations))
    end
end

function sel.replace(silent)
    --http://wiki.sk89q.com/wiki/WorldEdit/Region_operations#Replacing_blocks
    local Blocks, Meta, Blocks2, Meta2, Percentages, Pipes = parseBlockPatterns(WE.normalArgs)
    if not all(WE.convertName(Blocks, Meta), WE.convertName(Blocks2, Meta2)) then
        WE.sendChat "Could not convert names. Was there a typo?"
        return
    end

    local iterations = 0
    silent = silent or forceSilent
    local tbl
    if #WE.Selection > 0 then
        for i in (WE.RandomSetOrder and randomIPairs or ipairs)(WE.Selection) do
            --Go through all of the blocks in the selection...
            local x = WE.Selection[i].x
            local y = WE.Selection[i].y
            local z = WE.Selection[i].z
            local BlockType, RandomRoll
            if TotalPercent ~= 0 then
                repeat
                    BlockType = math.random(1, #Blocks2)
                    RandomRoll = math.frandom(0, TotalPercent)
                until RandomRoll <= tonumber(Percentages[BlockType])
            else
                BlockType = 1
            end
            if not WE.isCommandComputer then
                for i = 1, #Blocks do
                    if WE.blockEquals(x, y, z, Blocks[i], Meta[i]) then
                        --If they match any of them...
                        WE.setBlock(x, y, z, Blocks2[BlockType], Meta2[BlockType])
                        iterations = iterations + 1 --Count how many blocks were changed.
                        break
                    end
                end
            else
                if tbl == nil then
                    if not silent then
                        WE.sendChat "Scanning..."
                    end
                    tbl = WE.selectLargeArea(WE.Selection.pos1.x, WE.Selection.pos1.y, WE.Selection.pos1.z, WE.Selection.pos2.x, WE.Selection.pos2.y, WE.Selection.pos2.z, 4096, true)
                    if not silent then
                        WE.sendChat "Scanning complete!"
                    end
                end
                for i = 1, #Blocks do
                    if tbl[x][y][z].name == (WE.idToMCName(Blocks[i]) or Blocks[i]) and (tbl[x][y][z].metadata == Meta[i] or Meta[i] < 0) then
                        WE.setBlock(x, y, z, Blocks2[BlockType], Meta2[BlockType])
                        iterations = iterations + 1 --Count how many blocks were changed.
                        break
                    end
                end
            end
            if i == 1 and not silent then
                WE.sendChat "Replacing blocks..."
            end
        end
    end
    if not silent then
        WE.sendChat(("%s blocks changed."):format(iterations == 0 and "No" or iterations))
    end
end

function sel.naturalize(silent)
    --Makes the given area look more natural.
    local iterations = 0
    local Map = heightmap()
    silent = silent or forceSilent
    local BlocksTbl
    if WE.isCommandComputer then
        BlocksTbl = WE.selectLargeArea(WE.Selection.pos1.x, WE.Selection.pos1.y, WE.Selection.pos1.z, WE.Selection.pos2.x, WE.Selection.pos2.y, WE.Selection.pos2.z, 4096, true)
    end
    local hasSet = false
    for i in (WE.RandomSetOrder and randomIPairs or ipairs)(Map) do
        local x, y, z = Map[i].x, Map[i].y, Map[i].z
        if y then
            for j = 0, Map[i].y - math.min(WE.Selection.pos1.y, WE.Selection.pos2.y) do
                local ID = BlocksTbl and WE.MCNameToID(BlocksTbl[x][y - j][z].name) or tonumber(WE.getBlockID(x, y - j, z))
                if ID == 1 or ID == 2 or ID == 3 then
                    local naturalBlockID = j > 3 and 1 or (j == 0 and 2) or 3
                    if WE.blockHasChanged(x, y - j, z, naturalBlockID, 0) then
                        iterations = iterations + 1
                        WE.setBlock(x, y - j, z, naturalBlockID, 0)
                    end
                    if not hasSet and not silent then
                        WE.sendChat "Naturalizing..."
                        hasSet = true
                    end
                end
            end
        end
    end
    if not silent then
        WE.sendChat(("%s blocks changed."):format(iterations == 0 and "No" or iterations))
    end
end

function sel.overlay(silent)
    --Overlays the selection with the given block
    local count = 0
    local iterations = 0
    local Map = heightmap()
    local BlockType
    local hasSet = false
    silent = silent or forceSilent
    for i in (WE.RandomSetOrder and randomIPairs or ipairs)(Map) do
        if tonumber(Map[i].y) and (SelectionType == "cuboid" and tonumber(Map[i].y) <= math.max(WE.Selection.pos1.y, WE.Selection.pos2.y) or SelectionType ~= "cuboid") then
            local x, y, z = Map[i].x, Map[i].y + 1, Map[i].z
            count = count + 1
            if TotalPercent ~= 0 then
                local RandomRoll
                repeat
                    BlockType = math.random(1, #Blocks2)
                    RandomRoll = math.frandom(0, TotalPercent)
                until RandomRoll <= tonumber(Percentages[BlockType])
            else
                BlockType = 1
            end
            local blockChanged = WE.blockHasChanged(x, y, z, Blocks2[BlockType], Meta2[BlockType])
            if blockChanged then
                WE.setBlock(x, y, z, Blocks2[BlockType], Meta2[BlockType])
            end
            if blockChanged then
                --If the block is actually CHANGED.
                iterations = iterations + 1 --Count how many blocks actually changed.
            end
            if not hasSet and not silent then
                WE.sendChat "Overlaying blocks..."
                hasSet = true
            end
        end
    end
    if not silent then
        WE.sendChat(("%s blocks changed."):format(iterations == 0 and "No" or iterations))
    end
end

function sel.shift(silent)
    --http://wiki.sk89q.com/wiki/WorldEdit/Selection#Shifting_your_selection
    local dir = false
    silent = silent or forceSilent
    local shiftAmt, direction
    for i = 1, #WE.normalArgs do
        if tonumber(WE.normalArgs[i]) then
            dir = true
            shiftAmt = tonumber(WE.normalArgs[i])
        elseif WE.isDirection(WE.normalArgs[i]) then
            direction = WE.normalArgs[i]
        end
    end
    if tonumber(WE.command) and not dir then
        direction = WE.getDirection(true):lower()
        if not direction then
            return
        end
        dir = true
    end
    if not WE.isDirection(direction) then
        WE.sendChat(("Invalid direction: %s"):format(direction))
        return
    end
    if not shiftAmt then
        WE.sendChat "No amount found!"
        return
    end
    local fields = { east = "x", west = "x", north = "z", south = "z", up = "y", down = "y" }
    local mult = { east = 1, west = -1, north = -1, south = 1, up = 1, down = -1 }
    local field = fields[direction]
    for i = 1, #WE.Selection do
        WE.Selection[i][field] = WE.Selection[i][field] + shiftAmt * mult[direction] --Shift each block in the selection over in the correct direction.
    end
    for i = 1, #WE.pos do
        WE.pos[i][field] = WE.pos[i][field] + shiftAmt * mult[direction] --Shift each position over as well
    end
    if WE.makeSelection[WE.Selection.type] then
        WE.makeSelection[WE.Selection.type]()
    else
        WE.sendChat(("Selection mode %s not implemented correctly!"):format(WE.Selection.type))
        return
    end
    if not silent then
        WE.sendChat(("Region shifted %d block%s %s. (%d)"):format(shiftAmt, shiftAmt ~= 1 and "s" or "", direction, #WE.Selection))
    end
end

function sel.chunk()
    --- Sets the selection to the chunk the player is in.
    WE.Selection = {}
    WE.px, WE.py, WE.pz = math.floor(WE.getPlayerPos(username))
    WE.pos = setmetatable({ pos1 = { x = WE.px - WE.px % 16, y = 0, z = WE.pz - WE.pz % 16 }, pos2 = { x = WE.px - WE.px % 16 + 16, y = 256, z = WE.pz - WE.pz % 16 + 16 } }, getmetatable(WE.pos))
    WE.makeSelection.cuboid()
    WE.Selection.type = "cuboid"
    WE.sendChat "Selection set to the chunk the player is in."
end

WE.registerCommand("set", function()
    parseBlockPatterns()
    sel.set()
end, WE.hasSelection, missingPos, "Sets all blocks in the selection to the given block(s) with the given proportion(s).", "set [probability]block[:meta][,...] (See \"help BlockPatterns\" for more information)")
WE.registerCommand("replace", function()
    parseBlockPatterns()
    sel.replace()
end, WE.hasSelection, missingPos, "Replaces all block(s) in the first argument with the block(s) in the second with their given proportion(s).", "replace [probability]block1[:meta1][,...] block2[:meta2][,...] (See \"help BlockPatterns\" for more information)")
WE.registerCommand("naturalize", sel.naturalize, WE.hasSelection, missingPos, "Makes the terrain look more natural.", "naturalize (Takes no arguments)")
WE.registerCommand("overlay", function()
    parseBlockPatterns()
    WE.convertName()
    sel.overlay()
end, WE.hasSelection, missingPos, "Overlays the selected terrain with the provided block(s).", "overlay [probability]block[:meta][,...] (See \"help BlockPatterns\" for more information)")
WE.registerCommand("distr", sel.distr, WE.hasSelection, missingPos, "Prints out the distribution of blocks in the selection. -d splits on meta, -c operates on the clipboard instead of the selection, -a ignores air blocks.", "distr [-d] [-c] [-a]")
WE.registerCommand("count", sel.count, WE.hasSelection, missingPos, "Counts the number of blocks in the selection. -d flag lets you specify meta in block:meta form.", "count [-d] block[:meta]")
WE.registerCommand("size", sel.size, WE.hasSelection, missingPos, "Prints the size of the selection, or the clipboard if the -c flag is provided.", "size [-c]")
WE.registerCommand("shift", sel.shift, WE.hasSelection, missingPos, "Moves the selection by one block in all directions.", "shift (amount) [direction] (Direction defaults to \"self\")")
WE.registerCommand("chunk", sel.chunk, WE.hasSelection, missingPos, "Changes the selection to the chunk the player is in.", "chunk (Takes no arguments)")

return sel
