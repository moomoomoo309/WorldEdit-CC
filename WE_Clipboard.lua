local function nbtToTable(typ, val) --Converts Immibis's NBT to a table
    if typ == "compound" then
        local rv = {}
        for _, key in ipairs(val.getKeys()) do
            local typ2, val2 = val.getValue(key)
            rv[key] = nbtToTable(typ2, val2)
        end
        return { type = "compound", value = rv }
    elseif typ == "list" then
        local n = val.getSize()
        local rv = {}
        for k = 0, n - 1 do
            local typ2, val2 = val.get(k)
            rv[k + 1] = nbtToTable(typ2, val2)
        end
        return { type = "list", value = rv }
    elseif typ == "string" or typ == "double" or typ == "float" or typ == "byte" or typ == "short" or typ == "int" or typ == "long" then
        return { type = typ, value = val }
    elseif typ == "intArray" or typ == "byteArray" then
        local rv = {}
        for k = 0, val.getLength() - 1 do
            rv[k + 1] = val.get(k)
        end
        return { type = typ, value = rv }
    else
        error("unimplemented tag type: " .. typ)
    end
end

local function tableToNbt(typ, tag, tbl) --Converts table to Immibis's NBT
    assert(type(tag) == "table" and tbl.type == typ and tag.getType() == typ)
    if typ == "compound" then
        for _, key in ipairs(tag.getKeys()) do
            if not tbl.value[key] then
                tag.remove(key)
            end
        end
        for key, value in pairs(tbl.value) do
            if value.type == "compound" or value.type == "list" then
                tag.setValue(key, value.type)
                tableToNbt(value.type, select(2, tag.getValue(key)), value)
            elseif value.type == "intArray" or value.type == "byteArray" then
                tag.setValue(key, value.type, #value.value)
                tableToNbt(value.type, select(2, tag.getValue(key)), value)
            elseif value.type == "string" or value.type == "double" or value.type == "float" or value.type == "byte" or value.type == "short" or value.type == "int" then
                tag.setValue(key, value.type, value.value)
            elseif value.type == "long" then
                tag.setValue(key, value.type, value.value[1], value.value[2])
            else
                error("unimplemented tag type: " .. value.type)
            end
        end
    elseif typ == "list" then
        while tag.getSize() > 0 do
            tag.remove(0)
        end
        for _, value in ipairs(tbl.value) do
            if value.type == "compound" or value.type == "list" then
                tag.add(tag.getSize(), value.type)
                tableToNbt(value.type, select(2, tag.get(tag.getSize() - 1)), value)
            elseif value.type == "intArray" or value.type == "byteArray" then
                tag.add(tag.getSize(), value.type, #value.value)
                tableToNbt(value.type, select(2, tag.get(tag.getSize() - 1)), value)
            elseif value.type == "string" or value.type == "double" or value.type == "float" or value.type == "byte" or value.type == "short" or value.type == "int" then
                tag.add(tag.getSize(), value.type, value.value)
            elseif value.type == "long" then
                tag.add(tag.getSize(), value.type, value.value[1], value.value[2])
            else
                error("unimplemented tag type: " .. value.type)
            end
        end
    elseif typ == "intArray" or typ == "byteArray" then
        for k = 0, tag.getLength() - 1 do
            tag.set(k, tbl.value[k + 1])
        end
    else
        error("unimplemented tag type: " .. typ)
    end
end

local function readTileNBT(te) --Reads a tile entity using the adventure map interface.
    te.readNBT()
    local nbtData = nbtToTable("compound", te.getNBT())
    return nbtDate
end

local function writeTileNBT(te, nbt) --Writes the NBT of a block using the adventure map interface.
    te.readNBT()
    tableToNbt("compound", te.getNBT(), nbt)
    te.writeNBT()
end


--And here begins my code!

local function setBlockWithNBT(x, y, z, id, meta, NBT) --Sets a block with/without NBT using a command computer
    NBT = NBT or ""
    if type(NBT) == "string" and #NBT > 0 then
        taskAmt = taskAmt and taskAmt + 1 or 1
        commands.async.setblock(x, y, z, ((tonumber(id) and (idToMCName(tonumber(id), false))) or id), meta > 0 and meta or 0, "replace", NBT)
    else
        setBlock(x, y, z, ((tonumber(id) and (idToMCName(tonumber(id), false))) or id), meta > 0 and meta or 0)
    end
end

local function loadClipboard() --Loads the clipboard from file, if it exists, for persistence
    if fs.exists(ConfigFolder .. ClipboardStorage) then
        local f = fs.open(ConfigFolder .. ClipboardStorage, "r")
        Clipboard = textutils.unserialize(f.readAll())
        f.close()
        return Clipboard
    end
end

local function updateClipboard() --Writes the clipboard to file, for persistence
    local f = fs.open(tostring(ConfigFolder .. ClipboardStorage), "w")
    serpent = serpent or dofile(SerpentPath)
    local str = (serpent.block or textutils.serialize)(Clipboard, { sortkeys = false, comment = false })
    coroutine.yield()
    sendChat "Table serialization complete! Writing to a file..."
    f.write(str)
    sendChat "Written!"
    f.close()
end

clipboard = {} --Holds the functions, clipboard.copy, clipboard.paste, etc.
Clipboard = Clipboard or loadClipboard() or {} --The clipboard which holds the blocks
Clipboard[1] = Clipboard[1] or {}
local directions = { "down", "up", "north", "south", "east", "west", "self", "me" }

--Deep Copy does NBT at 1 block/tick.
function clipboard.deepCopy(NoOutput, beingReused) --http://wiki.sk89q.com/wiki/WorldEdit/Clipboard#Copying_and_cutting
    local function getBlockIDAndMeta(x, y, z)
        local info = commands.getBlockInfo(x, y, z)
        return info.name, info.metadata
    end

    local iteration = 0
    Clipboard = {}
    if not NoOutput then
        sendChat "Copying..."
    end
    if not beingReused then
        px, py, pz = math.floor(getPlayerPos(username)) --GeneralAPI overwrites math.floor() to accept unlimited args.
    end
    Clipboard.ox = px --Original coords of the player at the time of the copying
    Clipboard.oy = py
    Clipboard.oz = pz
    if #Selection > 0 then
        for i = 1, #Selection do --Go through all of the blocks in the selection...
            if not Clipboard[i] then
                Clipboard[i] = {}
            end
            Clipboard[i].x = Selection[i].x --Integers play much nicer.
            Clipboard[i].y = Selection[i].y
            Clipboard[i].z = Selection[i].z
            Clipboard[i].ID, Clipboard[i].Meta = getBlockIDAndMeta(Clipboard[i].x, Clipboard[i].y, Clipboard[i].z)
            if w and w.getTileEntity(Clipboard[i].x, Clipboard[i].y, Clipboard[i].z) then --Store NBT with the adventure map interface
                Clipboard[i].NBT = readTileNBT(w.getTileEntity(Clipboard[i].x, Clipboard[i].y, Clipboard[i].z))
                Clipboard.format = "immibis"
            elseif isCommandComputer then --Store NBT with a command computer
                iteration = iteration + 1
                local blockData = { commands.blockdata(Selection[i].x, Selection[i].y, Selection[i].z, {}) }
                if blockData[2][1] ~= "The target block is not a data holder block" then
                    Clipboard[i].NBT = "{" .. blockData[2][1]:sub(blockData[2][1]:find(",", blockData[2][1]:find "z:") + 1) --Removes the coordinates from the NBT
                    Clipboard.format = "command"
                end
                if iteration == 1 or iteration % 20 == 0 then
                    sendChat(("%d%% (%d/%d) Complete..."):format(i / #Selection * 100, i, #Selection))
                end
            end
        end
    end
    if not NoOutput then
        sendChat "Area copied."
    end
    updateClipboard() --Write the clipboard to a file
end

--Copy does not to NBT, but at about 4096 blocks/tick.
function clipboard.copy(noOutput, beingReused) --http://wiki.sk89q.com/wiki/WorldEdit/Clipboard#Copying_and_cutting
    local iteration = 0
    Clipboard = {}
    if not noOutput then
        sendChat "Copying..."
    end
    if not beingReused then
        px, py, pz = math.floor(getPlayerPos(username)) --GeneralAPI overwrites math.floor() to accept unlimited args.
    end
    Clipboard.ox = px --Original coords of the player at the time of the copying
    Clipboard.oy = py
    Clipboard.oz = pz
    if #Selection > 0 then
        local blocksTbl = selectLargeArea(Selection.pos1.x, Selection.pos1.y, Selection.pos1.z, Selection.pos2.x, Selection.pos2.y, Selection.pos2.z, nil, #Selection >= 16384)
        for i = 1, #Selection do --Go through all of the blocks in the selection...
            if not Clipboard[i] then
                Clipboard[i] = {}
            end
            Clipboard[i].x = Selection[i].x --Integers play much nicer.
            Clipboard[i].y = Selection[i].y
            Clipboard[i].z = Selection[i].z
            local blockInfo = blocksTbl[Clipboard[i].x][Clipboard[i].y][Clipboard[i].z]
            Clipboard[i].ID, Clipboard[i].Meta = blockInfo.name, blockInfo.metadata
        end
    end
    if not noOutput then
        sendChat "Writing clipboard to a file..."
    end
    updateClipboard() --Write the clipboard to a file
    if not noOutput then
        sendChat "Area copied."
    end
end

--http://wiki.sk89q.com/wiki/WorldEdit/Clipboard#Pasting
function clipboard.paste(beingReused) --Pastes the current clipboard
    local iterations = 0
    local flags = { none = 0, a = 1, ao = 2, both = 3 } --a means without pasting air blocks, ao means At Origin, at the origin of the paste (Where it was copied from).
    local args = flags.none
    if not beingReused then
        if #normalArgs > 2 then
            sendChat "Syntax: paste [-a] [-ao]"
            return false
        end
        for i = 1, #shortSwitches do
            local currentSwitch = shortSwitches[i]
            if currentSwitch == "a" then
                args = (args == flags.ao or args == flags.both) and flags.both or flags.a
            elseif currentSwitch == "ao" then
                args = (args == flags.a or args == flags.both) and flags.both or flags.ao
            end
        end
    else
        args = flags.none
    end
    if Clipboard and #Clipboard > 0 and Clipboard[1].x then
        if not beingReused then
            sendChat "Pasting..."
        end
        local function rotateCoords(px, x, py, y, pz, z)
            local originalX, originalY, originalZ = x, y, z
            local axes = { x = { 1, 3 }, y = { 1, 2 }, z = { 2, 3 } } --X rotation is XZ axis, Y rotation is XY axis, Z rotation is YZ axis.
            local axisMap = { "x", "y", "z" }
            Clipboard.rotationX, Clipboard.rotationY, Clipboard.rotationZ = Clipboard.rotationX or 0, Clipboard.rotationY or 0, Clipboard.rotationZ or 0
            local deltas = { x, y, z }
            for key, rotation in pairs { Clipboard.rotationX, Clipboard.rotationY, Clipboard.rotationZ } do
                local rotation = rotation or 0
                if rotation ~= 0 then
                    local axis = axisMap[key]
                    rotation = rotation < 0 and 360 + rotation or rotation
                    if rotation == 270 then
                        deltas[axes[axis][1]], deltas[axes[axis][2]] = deltas[axes[axis][2]], -deltas[axes[axis][1]]
                    elseif rotation == 180 then
                        deltas[axes[axis][1]], deltas[axes[axis][2]] = -deltas[axes[axis][1]], -deltas[axes[axis][2]]
                    elseif rotation == 90 then
                        deltas[axes[axis][1]], deltas[axes[axis][2]] = -deltas[axes[axis][2]], deltas[axes[axis][1]]
                    end
                end
            end
            return px + deltas[1], py + deltas[2], pz + deltas[3]
        end

        local blockChanged = true
        for i = 1, #Clipboard do
            local currentX, currentY, currentZ
            if args == flags.none then
                currentX, currentY, currentZ = rotateCoords(px, Clipboard[i].x - Clipboard.ox, py, Clipboard[i].y - Clipboard.oy, pz, Clipboard[i].z - Clipboard.oz) --Coords relative to the player
                if not isCommandComputer then
                    blockChanged = blockHasChanged(currentX, currentY, currentZ, Clipboard[i].ID, Clipboard[i].Meta)
                    setBlock(currentX, currentY, currentZ, Clipboard[i].ID, Clipboard[i].Meta)
                elseif isCommandComputer then
                    setBlockWithNBT(currentX, currentY, currentZ, Clipboard[i].ID, Clipboard[i].Meta, Clipboard[i].NBT)
                end
                iterations = iterations + ((blockChanged and 1) or 0)
            elseif args == flags.a then
                if Clipboard[i].ID ~= 0 and Clipboard[i].ID ~= "minecraft:air" then --If the block in the clipboard isn't air...
                    currentX, currentY, currentZ = rotateCoords(px, Clipboard[i].x - Clipboard.ox, py, Clipboard[i].y - Clipboard.oy, pz, Clipboard[i].z - Clipboard.oz) --Coords relative to the player
                    if not isCommandComputer then
                        blockChanged = blockHasChanged(currentX, currentY, currentZ, Clipboard[i].ID, Clipboard[i].Meta)
                        setBlock(currentX, currentY, currentZ, Clipboard[i].ID, Clipboard[i].Meta)
                    elseif isCommandComputer then
                        setBlockWithNBT(currentX, currentY, currentZ, Clipboard[i].ID, Clipboard[i].Meta, Clipboard[i].NBT)
                    end
                    iterations = iterations + ((blockChanged and 1) or 0)
                end
            elseif args == flags.ao then
                currentX, currentY, currentZ = rotateCoords(Clipboard.ox, (Clipboard[i].x - Clipboard.ox), Clipboard.oy, (Clipboard[i].y - Clipboard.oy), Clipboard.oz, (Clipboard[i].z - Clipboard.oz)) --Original coords from the clipboard
                if not isCommandComputer then
                    blockChanged = blockHasChanged(currentX, currentY, currentZ, Clipboard[i].ID, Clipboard[i].Meta)
                    setBlock(currentX, currentY, currentZ, Clipboard[i].ID, Clipboard[i].Meta)
                elseif isCommandComputer then
                    setBlockWithNBT(currentX, currentY, currentZ, Clipboard[i].ID, Clipboard[i].Meta, Clipboard[i].NBT)
                end
                iterations = iterations + ((blockChanged and 1) or 0)
            elseif args == flags.both then
                if Clipboard[i].ID ~= 0 and Clipboard[i].ID ~= "minecraft:air" then --If the block in the clipboard isn't air...
                    currentX, currentY, currentZ = rotateCoords(Clipboard.ox, (Clipboard[i].x - Clipboard.ox), Clipboard.oy, (Clipboard[i].y - Clipboard.oy), Clipboard.oz, (Clipboard[i].z - Clipboard.oz)) --Original coords from the clipboard
                    if not isCommandComputer then
                        blockChanged = blockHasChanged(currentX, currentY, currentZ, Clipboard[i].ID, Clipboard[i].Meta)
                        setBlock(currentX, currentY, currentZ, Clipboard[i].ID, Clipboard[i].Meta)
                    elseif isCommandComputer then
                        setBlockWithNBT(currentX, currentY, currentZ, Clipboard[i].ID, Clipboard[i].Meta, Clipboard[i].NBT)
                    end
                    iterations = iterations + ((blockChanged and 1) or 0)
                end
            end
            if useNBT and Clipboard[i].NBT and Clipboard.format == "immibis" then --If the block in the clipboard has NBT data and is using the adventure map interface
                for k, v in pairs(Clipboard[i]) do
                    if k == "NBT" then
                        v.value.x.value, v.value.y.value, v.value.z.value = math.floor(currentX, currentY, currentZ) --Change the coords in the NBT data to the new coordinates
                    end
                end
                writeTileNBT(w.getTileEntity(currentX, currentY, currentZ), Clipboard[i].NBT) --Write the NBT to the block it's supposed to be on with the adventure map interface.
            end
        end
    else
        sendChat "Copy something first!"
    end
    if not beingReused then
        sendChat(("%d blocks changed."):format(hasChatbox and #Clipboard or iterations))
    end
end

function clipboard.cut(noOutput, deep) --http://wiki.sk89q.com/wiki/WorldEdit/Clipboard#Copying_and_cutting
    noOutput = noOutput or forceSilent
    print(noOutput)
    clipboard[deep and "deepcopy" or "copy"](noOutput) --Reusing functions makes this much easier. Set it so it won't say "Area Copied", but will say everything else.
    runCommands("set air", true)
    if not noOutput then
        sendChat "Area Cut."
    end
end

function clipboard.move() --http://wiki.sk89q.com/wiki/WorldEdit/Region_operations#Moving
    local moveSelection, moveDistance
    for i = 1, #shortSwitches do
        if shortSwitches[i] == "s" then
            moveSelection = true
            break
        end
    end
    px, py, pz = getPlayerPos(username)
    for i = 1, #normalArgs do
        for i2 = 1, #directions do
            if normalArgs[i] == directions[i2] then
                Direction = directions[i2]
                break
            end
        end
    end
    local moveDistance = tonumber(normalArgs[1])
    local fillBlock = normalArgs[3]
    if not Direction or Direction == "" or Direction == "self" or Direction == "me" then
        Direction = getDirection(true)
        if not Direction then
            sendChat "No direction!"
            return
        end
    end
    if not moveDistance then
        sendChat "Specify an amount to move!"
        return
    elseif moveDistance == 0 then
        if not forceSilent then
            sendChat "Selection moved."
        end
        return
    end
    local tmpClipboard = {}
    if Direction then
        if not px or not py or not pz then
            px, py, pz = getPlayerPos()
        end
        local tx, ty, tz = px, py, pz --Temporary storage for the player location
        tmpClipboard = tablex.copy(Clipboard)
        clipboard.cut(true) --Run it in silent mode.
        if Direction == "east" then
            px = px + moveDistance
        elseif Direction == "west" then
            px = px - moveDistance
        elseif Direction == "north" then
            pz = pz - moveDistance
        elseif Direction == "south" then
            pz = pz + moveDistance
        elseif Direction == "up" then
            py = py + moveDistance
        elseif Direction == "down" then
            py = py - moveDistance
        else
            error(("I screwed up the direction function. Tell me how you made this bug happen on the forum thread! (Direction=%s)"):format(tostring(Direction)))
        end
    end
    clipboard.paste(true)
    Clipboard = tmpClipboard
    tmpClipboard = nil
    px, py, pz = tx, ty, tz
    if moveSelection then --Do a little cheatiness to make sel.shift think the player ran shift.
        runCommands(("shift %d %s"):format(moveDistance, Direction), true)
    end

    if fillBlock then
        local oldMessage, oldForceSilent = OriginalMessage, forceSilent
        runCommands("set " .. fillBlock, true)
    end
    sendChat "Selection moved."
end

local function selectionLength(axis) --Used in stack to get the length of the selection on tdeephe given axis.
    local maxCoord = Selection[1][axis]
    local minCoord = Selection[1][axis]
    for i = 1, #Selection do
        if Selection[i][axis] > maxCoord then
            maxCoord = Selection[i][axis]
        elseif Selection[i][axis] < minCoord then
            minCoord = Selection[i][axis]
        end
    end
    return maxCoord - minCoord + 1, minCoord, maxCoord --Length, min, max
end

function clipboard.rotate() --Sets the rotation flag on the current clipboard to the specified amount on the given axis (or X by default)
    local rotate = function()
        local rotation, axis = tonumber(normalArgs[1]), (normalArgs[2] or "x")
        local clipboardKey = { x = "rotationX", y = "rotationY", z = "rotationZ" }
        if not clipboardKey[axis] then
            error(("\"%s\" is not a valid axis!"):format(tostring(axis)))
        elseif not rotation then
            error(("\"%s\" is not a valid number!"):format(tostring(rotation)))
        end
        Clipboard[clipboardKey[axis]] = ((Clipboard[clipboardKey[axis]] or 0) + rotation) % 360
        return rotation, axis
    end
    local success, errMessageOrArg2, arg3 = pcall(rotate) --Catch the errors and send them out as chat if they occur.
    if success then --In this case, arg2.
        sendChat(("Clipboard rotated %d degrees on the %s axis. (%d,%d,%d)"):format(errMessageOrArg2, arg3, Clipboard.rotationX or 0, Clipboard.rotationY or 0, Clipboard.rotationZ or 0))
        updateClipboard()
    else
        sendChat(errMessageOrArg2) --In this case, errMessage.
    end
end

function clipboard.stack() --http://wiki.sk89q.com/wiki/WorldEdit/Region_operations#Stacking
    local tmpClipboard = {}
    tmpClipboard = tablex.copy(Clipboard)
    px, py, pz = getPlayerPos(username)
    local stackAmt = 0
    for i = 1, #directions do
        for i2 = 1, #normalArgs do
            if directions[i] == normalArgs[i2] then
                Direction = directions[i]
                break
            elseif tonumber(normalArgs[i2]) ~= nil then
                stackAmt = tonumber(normalArgs[i2])
            end
        end
    end
    if not Direction or Direction == "" or Direction == "self" or Direction == "me" then
        Direction = getDirection(true)
        if not Direction then return end
    end
    if Direction then
        local tx, ty, tz = px, py, pz --temporary storage for the player location
        clipboard.copy(true)
        Clipboard.ox, Clipboard.oy, Clipboard.oz = tx, ty, tz
        --The equation gets the size of the selection in that dimension then moves the area operated upon accordingly
        --(since it uses the player's position, that is edited, but the original is restored after the command finishes)
        local directionToAxis = { east = "x", west = "x", up = "y", down = "y", north = "z", south = "z" }
        local selectionLen = selectionLength(directionToAxis[Direction])
        for i = 1, tonumber(stackAmt) do
            if Direction == "east" then
                px = px + selectionLen
            elseif Direction == "west" then
                px = px - selectionLen
            elseif Direction == "up" then
                py = py + selectionLen
            elseif Direction == "down" then
                py = py - selectionLen
            elseif Direction == "south" then
                pz = pz + selectionLen
            elseif Direction == "north" then
                pz = pz - selectionLen
            else
                sendChat(tostring(Direction))
                sendChat "I screwed up the direction function. Tell me how you made this bug happen on the forum thread!"
            end
            clipboard.paste(true)
        end
    end
    Clipboard = tmpClipboard
    tmpClipboard = nil
    Direction = nil
    px, py, pz = tx, ty, tz
    sendChat "Selection stacked."
end

function clipboard.save() --Save the current clipboard to a file
    local fileName = normalArgs[1]:gsub(" ", "_")
    local allowOverwriting = false
    for i = 1, #shortSwitches do
        if shortSwitches[i] == "o" then
            allowOverwriting = true
            break
        end
    end
    if Clipboard and #Clipboard > 0 then
        local filePath = ConfigFolder .. "Schematics/" .. fileName
        if not fs.exists(filePath) or allowOverwriting then
            local f = fs.open(filePath, "w")
            f.write(textutils.serialize(Clipboard))
            f.close()
        else
            sendChat "That name is already used. Run with the -o flag to allow overwriting."
            return false
        end
    else
        sendChat "You need to have something in your clipboard first!"
        return false
    end
    sendChat "Build Saved."
    return true
end

function clipboard.load() --Load the specified clipboard from file, if it exists.
    local dir = normalArgs[1] and normalArgs[1]:gsub(" ", "_") or nil
    dir = (dir == nil or dir == "") and ConfigFolder .. "Clipboard" or ConfigFolder .. "Schematics/" .. dir
    if fs.exists(dir) then
        local f = fs.open(dir, "r")
        Clipboard = textutils.unserialize(f.readAll())
        f.close()
        sendChat "Clipboard loaded."
    else
        sendChat "That clipboard does not exist!"
    end
end

function clipboard.list() --List all of the files in the schematics directory.
    local folderPath = ConfigFolder .. "Schematics/"
    local files = fs.list(folderPath)
    if #files > 0 then
        sendChat(("The files in %s are:"):format(folderPath))
        for _, file in ipairs(files) do
            sendChat(("%s    %d bytes"):format(file, fs.getSize(folderPath .. file))) --I'd use \t, but MC chat can't render it properly.
        end
    else
        sendChat(("%s is empty!"):format(folderPath))
    end
end

registerCommand("copy", clipboard.copy, hasSelection, missingPos)
registerCommand("deepcopy", clipboard.deepCopy, hasSelection, missingPos)
registerCommand("paste", clipboard.paste, hasNBTSupport)
registerCommand("move", clipboard.move, hasNBTSupportAndSel, missingPos)
registerCommand("cut", clipboard.cut, hasNBTSupportAndSel, missingPos)
registerCommand("deepcut", function() clipboard.cut(false, true) end, hasNBTSupportAndSel, missingPos)
registerCommand("stack", clipboard.stack, hasNBTSupportAndSel, missingPos)

