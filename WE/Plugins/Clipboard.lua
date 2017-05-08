local function nbtToTable(typ, val)
    --Converts Immibis's NBT to a table
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

local function tableToNbt(typ, tag, tbl)
    --Converts table to Immibis's NBT
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

local function readTileNBT(te)
    --Reads a tile entity using the adventure map interface.
    te.readNBT()
    return nbtToTable("compound", te.getNBT())
end

local function writeTileNBT(te, nbt)
    --Writes the NBT of a block using the adventure map interface.
    te.readNBT()
    tableToNbt("compound", te.getNBT(), nbt)
    te.writeNBT()
end


--And here begins my code!

local function loadClipboard()
    --Loads the clipboard from file, if it exists, for persistence
    if fs.exists(WE.ConfigFolder .. WE.ClipboardPath) then
        if fs.isDir(WE.ConfigFolder .. WE.ClipboardPath) then
            WE.sendChat(("Could not load Clipboard, %s is a directory."):format(WE.ConfigFolder .. WE.ClipboardPath))
            return
        end
        local f = fs.open(WE.ConfigFolder .. WE.ClipboardPath, "r")
        WE.Clipboard = textutils.unserialize(f.readAll())
        f.close()
        return WE.Clipboard
    end
end

local function updateClipboard()
    --Writes the clipboard to file, for persistence
    local f = fs.open(tostring(WE.ConfigFolder .. WE.ClipboardPath), "w")
    local str = (WE.plugins.serpent and WE.plugins.serpent.block or textutils.serialize)(WE.Clipboard, { sortkeys = false, comment = false })
    coroutine.yield()
    WE.sendChat "Table serialization complete! Writing to a file..."
    f.write(str)
    WE.sendChat "Written!"
    f.close()
end

local clipboard = { name = "Clipboard" } --Holds the functions, clipboard.copy, clipboard.paste, etc.
WE.Clipboard = WE.Clipboard or loadClipboard() or {} --The clipboard which holds the blocks
WE.Clipboard[1] = WE.Clipboard[1] or {}
local directions = { "down", "up", "north", "south", "east", "west", "self", "me" }

--Deep Copy does NBT at 1 block/tick.
function clipboard.deepCopy(NoOutput, beingReused)
    --http://wiki.sk89q.com/wiki/WorldEdit/Clipboard#Copying_and_cutting
    local function getBlockIDAndMeta(x, y, z)
        local info = commands.getBlockInfo(x, y, z)
        return info.name, info.metadata
    end

    local iteration = 0
    WE.Clipboard = {}
    if not NoOutput then
        WE.sendChat "Copying..."
    end
    if not beingReused then
        WE.px, WE.py, WE.pz = math.floor(WE.getPlayerPos(username)) --GeneralAPI overwrites math.floor() to accept unlimited args.
    end
    WE.Clipboard.ox = WE.px --Original coords of the player at the time of the copying
    WE.Clipboard.oy = WE.py
    WE.Clipboard.oz = WE.pz
    if #WE.Selection > 0 then
        for i = 1, #WE.Selection do
            --Go through all of the blocks in the selection...
            if not WE.Clipboard[i] then
                WE.Clipboard[i] = {}
            end
            WE.Clipboard[i].x = WE.Selection[i].x --Integers play much nicer.
            WE.Clipboard[i].y = WE.Selection[i].y
            WE.Clipboard[i].z = WE.Selection[i].z
            WE.Clipboard[i].ID, WE.Clipboard[i].Meta = getBlockIDAndMeta(WE.Clipboard[i].x, WE.Clipboard[i].y, WE.Clipboard[i].z)
            if w and w.getTileEntity(WE.Clipboard[i].x, WE.Clipboard[i].y, WE.Clipboard[i].z) then
                --Store NBT with the adventure map interface
                WE.Clipboard[i].NBT = readTileNBT(w.getTileEntity(WE.Clipboard[i].x, WE.Clipboard[i].y, WE.Clipboard[i].z))
                WE.Clipboard.format = "immibis"
            elseif WE.isCommandComputer then
                --Store NBT with a command computer
                iteration = iteration + 1
                local blockData = { commands.blockdata(WE.Selection[i].x, WE.Selection[i].y, WE.Selection[i].z, {}) }
                if blockData[2][1] ~= "The target block is not a data holder block" then
                    local data = blockData[2][1]
                    local findX, findZ = data:find("x:", nil, true), data:find("z:", nil, true)
                    WE.Clipboard[i].NBT = data:sub(data:find("{", 2, true), findX - 1) .. data:sub(data:find(",", findZ, true) + 1) --Removes the coordinates from the NBT
                    WE.Clipboard.format = "command"
                end
                if iteration == 1 or iteration % 20 == 0 then
                    WE.sendChat(("%d%% (%d/%d) Complete..."):format(i / #WE.Selection * 100, i, #WE.Selection))
                end
            end
        end
    end
    if not NoOutput then
        WE.sendChat "Area copied."
    end
    updateClipboard() --Write the clipboard to a file
end

--Copy does not to NBT, but at about 4096 blocks/tick.
function clipboard.copy(noOutput, beingReused)
    --http://wiki.sk89q.com/wiki/WorldEdit/Clipboard#Copying_and_cutting
    WE.Clipboard = {}
    if not noOutput then
        WE.sendChat "Copying..."
    end
    if not beingReused then
        WE.px, WE.py, WE.pz = math.floor(WE.getPlayerPos(username)) --GeneralAPI overwrites math.floor() to accept unlimited args.
    end
    WE.Clipboard.ox = WE.px --Original coords of the player at the time of the copying
    WE.Clipboard.oy = WE.py
    WE.Clipboard.oz = WE.pz
    if #WE.Selection > 0 then
        local blocksTbl = WE.selectLargeArea(WE.Selection.pos1.x, WE.Selection.pos1.y, WE.Selection.pos1.z, WE.Selection.pos2.x, WE.Selection.pos2.y, WE.Selection.pos2.z, nil, #WE.Selection >= 16384)
        for i = 1, #WE.Selection do
            --Go through all of the blocks in the selection...
            WE.Clipboard[i] = WE.Clipboard[i] or {}
            WE.Clipboard[i].x = WE.Selection[i].x
            WE.Clipboard[i].y = WE.Selection[i].y
            WE.Clipboard[i].z = WE.Selection[i].z
            local blockInfo = blocksTbl[WE.Clipboard[i].x][WE.Clipboard[i].y][WE.Clipboard[i].z]
            WE.Clipboard[i].ID, WE.Clipboard[i].Meta = blockInfo.name, blockInfo.metadata
        end
    end
    if not noOutput then
        WE.sendChat "Writing clipboard to a file..."
    end
    updateClipboard() --Write the clipboard to a file
    if not noOutput then
        WE.sendChat "Area copied."
    end
end

--http://wiki.sk89q.com/wiki/WorldEdit/Clipboard#Pasting
function clipboard.paste(beingReused)
    --Pastes the current clipboard
    local iterations = 0
    local flags = { none = 0, a = 1, ao = 2, both = 3 } --a means without pasting air blocks, ao means At Origin, at the origin of the paste (Where it was copied from).
    local args = flags.none
    if not beingReused then
        WE.px, WE.py, WE.pz = WE.getPlayerPos()
        if #WE.normalArgs > 2 then
            WE.sendChat "Syntax: paste [-a] [-ao]"
            return false
        end
        if WE.shortSwitches.a then
            args = (args == flags.ao or args == flags.both) and flags.both or flags.a
        end
        if WE.shortSwitches.ao then
            args = (args == flags.a or args == flags.both) and flags.both or flags.ao
        end
    else
        args = flags.none
    end
    if WE.Clipboard and #WE.Clipboard > 0 and WE.Clipboard[1].x then
        if not beingReused then
            WE.sendChat "Pasting..."
        end
        local function rotateCoords(px, x, py, y, pz, z)
            local originalX, originalY, originalZ = x, y, z
            local axes = { x = { 1, 3 }, y = { 1, 2 }, z = { 2, 3 } } --X rotation is XZ axis, Y rotation is XY axis, Z rotation is YZ axis.
            local axisMap = { "x", "y", "z" }
            WE.Clipboard.rotationX, WE.Clipboard.rotationY, WE.Clipboard.rotationZ = WE.Clipboard.rotationX or 0, WE.Clipboard.rotationY or 0, WE.Clipboard.rotationZ or 0
            local deltas = { x, y, z }
            for key, rotation in pairs { WE.Clipboard.rotationX, WE.Clipboard.rotationY, WE.Clipboard.rotationZ } do
                local rotation = rotation % 360 or 0
                if rotation ~= 0 then
                    local axis = axisMap[key]
                    rotation = rotation < 0 and 360 + rotation or rotation
                    if rotation == 270 then
                        --Swap, negative on the second
                        deltas[axes[axis][1]], deltas[axes[axis][2]] = deltas[axes[axis][2]], -deltas[axes[axis][1]]
                    elseif rotation == 180 then
                        --Negative on the first
                        deltas[axes[axis][1]], deltas[axes[axis][2]] = -deltas[axes[axis][1]], -deltas[axes[axis][2]]
                    elseif rotation == 90 then
                        --Swap, negative on the first
                        deltas[axes[axis][1]], deltas[axes[axis][2]] = -deltas[axes[axis][2]], deltas[axes[axis][1]]
                    end
                end
            end
            return WE.px + deltas[1], WE.py + deltas[2], WE.pz + deltas[3]
        end

        local blockChanged = true
        for i = 1, #WE.Clipboard do
            local currentX, currentY, currentZ
            if args == flags.none then
                currentX, currentY, currentZ = rotateCoords(WE.px, WE.Clipboard[i].x - WE.Clipboard.ox, WE.py, WE.Clipboard[i].y - WE.Clipboard.oy, WE.pz, WE.Clipboard[i].z - WE.Clipboard.oz) --Coords relative to the player
                if not WE.isCommandComputer then
                    blockChanged = WE.blockHasChanged(currentX, currentY, currentZ, WE.Clipboard[i].ID, WE.Clipboard[i].Meta)
                    WE.setBlock(currentX, currentY, currentZ, WE.Clipboard[i].ID, WE.Clipboard[i].Meta)
                else
                    WE.setBlock(currentX, currentY, currentZ, WE.Clipboard[i].ID, WE.Clipboard[i].Meta, WE.Clipboard[i].NBT)
                end
                iterations = iterations + ((blockChanged and 1) or 0)
            elseif args == flags.a then
                if WE.Clipboard[i].ID ~= 0 and WE.Clipboard[i].ID ~= "minecraft:air" then
                    --If the block in the clipboard isn't air...
                    currentX, currentY, currentZ = rotateCoords(WE.px, WE.Clipboard[i].x - WE.Clipboard.ox, WE.py, WE.Clipboard[i].y - WE.Clipboard.oy, WE.pz, WE.Clipboard[i].z - WE.Clipboard.oz) --Coords relative to the player
                    if not WE.isCommandComputer then
                        blockChanged = WE.blockHasChanged(currentX, currentY, currentZ, WE.Clipboard[i].ID, WE.Clipboard[i].Meta)
                        WE.setBlock(currentX, currentY, currentZ, WE.Clipboard[i].ID, WE.Clipboard[i].Meta)
                    else
                        WE.setBlock(currentX, currentY, currentZ, WE.Clipboard[i].ID, WE.Clipboard[i].Meta, WE.Clipboard[i].NBT)
                    end
                    iterations = iterations + ((blockChanged and 1) or 0)
                end
            elseif args == flags.ao then
                currentX, currentY, currentZ = rotateCoords(WE.Clipboard.ox, (WE.Clipboard[i].x - WE.Clipboard.ox), WE.Clipboard.oy, (WE.Clipboard[i].y - WE.Clipboard.oy), WE.Clipboard.oz, (WE.Clipboard[i].z - WE.Clipboard.oz)) --Original coords from the clipboard
                if not WE.isCommandComputer then
                    blockChanged = WE.blockHasChanged(currentX, currentY, currentZ, WE.Clipboard[i].ID, WE.Clipboard[i].Meta)
                    WE.setBlock(currentX, currentY, currentZ, WE.Clipboard[i].ID, WE.Clipboard[i].Meta)
                else
                    WE.setBlock(currentX, currentY, currentZ, WE.Clipboard[i].ID, WE.Clipboard[i].Meta, WE.Clipboard[i].NBT)
                end
                iterations = iterations + ((blockChanged and 1) or 0)
            elseif args == flags.both then
                if WE.Clipboard[i].ID ~= 0 and WE.Clipboard[i].ID ~= "minecraft:air" then
                    --If the block in the clipboard isn't air...
                    currentX, currentY, currentZ = rotateCoords(WE.Clipboard.ox, (WE.Clipboard[i].x - WE.Clipboard.ox), WE.Clipboard.oy, (WE.Clipboard[i].y - WE.Clipboard.oy), WE.Clipboard.oz, (WE.Clipboard[i].z - WE.Clipboard.oz)) --Original coords from the clipboard
                    if not WE.isCommandComputer then
                        blockChanged = WE.blockHasChanged(currentX, currentY, currentZ, WE.Clipboard[i].ID, WE.Clipboard[i].Meta)
                        WE.setBlock(currentX, currentY, currentZ, WE.Clipboard[i].ID, WE.Clipboard[i].Meta)
                    else
                        WE.setBlock(currentX, currentY, currentZ, WE.Clipboard[i].ID, WE.Clipboard[i].Meta, WE.Clipboard[i].NBT)
                    end
                    iterations = iterations + ((blockChanged and 1) or 0)
                end
            end
            if useNBT and WE.Clipboard[i].NBT and WE.Clipboard.format == "immibis" then
                --If the block in the clipboard has NBT data and is using the adventure map interface
                for k, v in pairs(WE.Clipboard[i]) do
                    if k == "NBT" then
                        v.value.x.value, v.value.y.value, v.value.z.value = math.floor(currentX, currentY, currentZ) --Change the coords in the NBT data to the new coordinates
                    end
                end
                writeTileNBT(w.getTileEntity(currentX, currentY, currentZ), WE.Clipboard[i].NBT) --Write the NBT to the block it's supposed to be on with the adventure map interface.
            end
        end
    else
        WE.sendChat "Copy something first!"
    end
    if not beingReused then
        WE.sendChat(("%d blocks changed."):format(hasChatbox and #WE.Clipboard or iterations))
    end
end

function clipboard.cut(noOutput, deep)
    --http://wiki.sk89q.com/wiki/WorldEdit/Clipboard#Copying_and_cutting
    noOutput = noOutput or forceSilent
    print(noOutput)
    clipboard[deep and "deepcopy" or "copy"](noOutput) --Reusing functions makes this much easier. Set it so it won't say "Area Copied", but will say everything else.
    WE.runCommands("set air", true)
    if not noOutput then
        WE.sendChat "Area Cut."
    end
end

function clipboard.move()
    --http://wiki.sk89q.com/wiki/WorldEdit/Region_operations#Moving
    local moveSelection, moveDistance
    for i = 1, #WE.shortSwitches do
        if WE.shortSwitches[i] == "s" then
            moveSelection = true
            break
        end
    end
    WE.px, WE.py, WE.pz = WE.getPlayerPos(username)
    for i = 1, #WE.normalArgs do
        for i2 = 1, #directions do
            if WE.normalArgs[i] == directions[i2] then
                WE.Direction = directions[i2]
                break
            end
        end
    end
    local moveDistance = tonumber(WE.normalArgs[1])
    local fillBlock = WE.normalArgs[3]
    if not WE.Direction or WE.Direction == "" or WE.Direction == "self" or WE.Direction == "me" then
        WE.Direction = WE.getDirection(true)
        if not WE.Direction then
            WE.sendChat "No direction!"
            return
        end
    end
    if not moveDistance then
        WE.sendChat "Specify an amount to move!"
        return
    elseif moveDistance == 0 then
        if not forceSilent then
            WE.sendChat "Selection moved."
        end
        return
    end
    local tmpClipboard = {}
    if WE.Direction then
        if not WE.px or not WE.py or not WE.pz then
            WE.px, WE.py, WE.pz = WE.getPlayerPos()
        end
        local tx, ty, tz = WE.px, WE.py, WE.pz --Temporary storage for the player location
        tmpClipboard = tablex.copy(WE.Clipboard)
        clipboard.cut(true) --Run it in silent mode.
        if WE.Direction == "east" then
            WE.px = WE.px + moveDistance
        elseif WE.Direction == "west" then
            WE.px = WE.px - moveDistance
        elseif WE.Direction == "north" then
            WE.pz = WE.pz - moveDistance
        elseif WE.Direction == "south" then
            WE.pz = WE.pz + moveDistance
        elseif WE.Direction == "up" then
            WE.py = WE.py + moveDistance
        elseif WE.Direction == "down" then
            WE.py = WE.py - moveDistance
        else
            error(("I screwed up the direction function. Tell me how you made this bug happen on the forum thread! (Direction=%s)"):format(tostring(WE.Direction)))
        end
    end
    clipboard.paste(true)
    WE.Clipboard = tmpClipboard
    tmpClipboard = nil
    WE.px, WE.py, WE.pz = tx, ty, tz
    if moveSelection then
        --Do a little cheatiness to make sel.shift think the player ran shift.
        WE.runCommands(("shift %d %s"):format(moveDistance, WE.Direction), true)
    end

    if fillBlock then
        local oldMessage, oldForceSilent = OriginalMessage, forceSilent
        WE.runCommands("set " .. fillBlock, true)
    end
    WE.sendChat "Selection moved."
end

local function selectionLength(axis)
    --Used in stack to get the length of the selection on tdeephe given axis.
    local maxCoord = WE.Selection[1][axis]
    local minCoord = WE.Selection[1][axis]
    for i = 1, #WE.Selection do
        if WE.Selection[i][axis] > maxCoord then
            maxCoord = WE.Selection[i][axis]
        elseif WE.Selection[i][axis] < minCoord then
            minCoord = WE.Selection[i][axis]
        end
    end
    return maxCoord - minCoord + 1, minCoord, maxCoord --Length, min, max
end

function clipboard.rotate()
    --Sets the rotation flag on the current clipboard to the specified amount on the given axis (or X by default)
    local rotate = function()
        local rotation, axis = tonumber(WE.normalArgs[1]), (WE.normalArgs[2] or "x")
        local clipboardKey = { x = "rotationX", y = "rotationY", z = "rotationZ" }
        if not clipboardKey[axis] then
            error(("\"%s\" is not a valid axis!"):format(tostring(axis)))
        elseif not rotation then
            error(("\"%s\" is not a valid number!"):format(tostring(rotation)))
        end
        WE.Clipboard[clipboardKey[axis]] = ((WE.Clipboard[clipboardKey[axis]] or 0) + rotation) % 360
        return rotation, axis
    end
    local success, errMessageOrArg2, arg3 = pcall(rotate) --Catch the errors and send them out as chat if they occur.
    if success then
        --In this case, arg2.
        WE.sendChat(("Clipboard rotated %d degrees on the %s axis. (%d,%d,%d)"):format(errMessageOrArg2, arg3, WE.Clipboard.rotationX or 0, WE.Clipboard.rotationY or 0, WE.Clipboard.rotationZ or 0))
        updateClipboard()
    else
        WE.sendChat(errMessageOrArg2) --In this case, errMessage.
    end
end

function clipboard.stack()
    --http://wiki.sk89q.com/wiki/WorldEdit/Region_operations#Stacking
    local tmpClipboard = {}
    tmpClipboard = tablex.copy(WE.Clipboard)
    WE.px, WE.py, WE.pz = WE.getPlayerPos(username)
    local stackAmt = 0
    for i = 1, #directions do
        for i2 = 1, #WE.normalArgs do
            if directions[i] == WE.normalArgs[i2] then
                WE.Direction = directions[i]
                break
            elseif tonumber(WE.normalArgs[i2]) ~= nil then
                stackAmt = tonumber(WE.normalArgs[i2])
            end
        end
    end
    if not WE.Direction or WE.Direction == "" or WE.Direction == "self" or WE.Direction == "me" then
        WE.Direction = WE.getDirection(true)
        if not WE.Direction then
            return
        end
    end
    if WE.Direction then
        local tx, ty, tz = WE.px, WE.py, WE.pz --temporary storage for the player location
        clipboard.copy(true)
        WE.Clipboard.ox, WE.Clipboard.oy, WE.Clipboard.oz = tx, ty, tz
        --The equation gets the size of the selection in that dimension then moves the area operated upon accordingly
        --(since it uses the player's position, that is edited, but the original is restored after the command finishes)
        local directionToAxis = { east = "x", west = "x", up = "y", down = "y", north = "z", south = "z" }
        local selectionLen = selectionLength(directionToAxis[WE.Direction])
        for i = 1, tonumber(stackAmt) do
            if WE.Direction == "east" then
                WE.px = WE.px + selectionLen
            elseif WE.Direction == "west" then
                WE.px = WE.px - selectionLen
            elseif WE.Direction == "up" then
                WE.py = WE.py + selectionLen
            elseif WE.Direction == "down" then
                WE.py = WE.py - selectionLen
            elseif WE.Direction == "south" then
                WE.pz = WE.pz + selectionLen
            elseif WE.Direction == "north" then
                WE.pz = WE.pz - selectionLen
            else
                WE.sendChat(tostring(WE.Direction))
                WE.sendChat "I screwed up the direction function. Tell me how you made this bug happen on the forum thread!"
            end
            clipboard.paste(true)
        end
    end
    WE.Clipboard = tmpClipboard
    tmpClipboard = nil
    WE.Direction = nil
    WE.px, WE.py, WE.pz = tx, ty, tz
    WE.sendChat "Selection stacked."
end

function clipboard.save()
    --Save the current clipboard to a file
    local fileName = WE.normalArgs[1]:gsub(" ", "_")
    local allowOverwriting = WE.shortSwitches.o
    if WE.Clipboard and #WE.Clipboard > 0 then
        local filePath = WE.ConfigFolder .. "Schematics/" .. fileName
        if not fs.exists(filePath) or allowOverwriting then
            local f = fs.open(filePath, "w")
            f.write(textutils.serialize(WE.Clipboard))
            f.close()
        else
            WE.sendChat "That name is already used. Run with the -o flag to allow overwriting."
            return false
        end
    else
        WE.sendChat "You need to have something in your clipboard first!"
        return false
    end
    WE.sendChat "Build Saved."
    return true
end

function clipboard.load()
    --Load the specified clipboard from file, if it exists.
    local dir = WE.normalArgs[1] and WE.normalArgs[1]:gsub(" ", "_") or nil
    dir = (dir == nil or dir == "") and WE.ConfigFolder .. "Clipboard" or WE.ConfigFolder .. "Schematics/" .. dir
    if fs.exists(dir) then
        local f = fs.open(dir, "r")
        WE.Clipboard = textutils.unserialize(f.readAll())
        f.close()
        WE.sendChat "Clipboard loaded."
    else
        WE.sendChat "That clipboard does not exist!"
    end
end

function clipboard.list()
    --List all of the files in the schematics directory.
    local folderPath = WE.ConfigFolder .. "Schematics/"
    local files = fs.list(folderPath)
    if #files > 0 then
        WE.sendChat(("The files in %s are:"):format(folderPath))
        for _, file in ipairs(files) do
            WE.sendChat(("%s    %d bytes"):format(file, fs.getSize(folderPath .. file))) --I'd use \t, but MC chat can't render it properly.
        end
    else
        WE.sendChat(("%s is empty!"):format(folderPath))
    end
end

WE.registerCommand("copy", clipboard.copy, WE.hasSelection, missingPos, "Copies the blocks in the selection into the clipboard. (about 4096 Blocks/tick)", "copy (Takes no arguments)")
WE.registerCommand("deepcopy", clipboard.deepCopy, WE.hasSelection, missingPos, "Copies the blocks in the selection, including NBT data, into the clipboard. Should not be used with large selections. (1 Block/tick)", "depcopy (Takes no arguments)")
WE.registerCommand("paste", clipboard.paste, WE.hasNBTSupport, "Puts the current clipboard in the world. -a does not paste air blocks, -ao pastes it at the origin of the clipboard.", "paste [-a] [-ao]")
WE.registerCommand("move", clipboard.move, WE.hasNBTSupportAndSel, missingPos, "Moves the blocks in the selection in the given direction, or in the direction the player is looking if not specified.", "move (amount) [direction] [-s] (Direction defaults to \"self\")")
WE.registerCommand("cut", clipboard.cut, WE.hasNBTSupportAndSel, missingPos, "Copies all blocks in the selection into the clipboard, then sets them to air. (about 4096 Blocks/tick)", "cut (Takes no arguments)")
WE.registerCommand("deepcut", function()
    clipboard.cut(false, true)
end, WE.hasNBTSupportAndSel, missingPos, "Copies all blocks in the selection with their NBT data into the clipboard, then sets them to air. Should not be used with large selections. (1 Block/tick)", "deepcut (Takes no arguments)")
WE.registerCommand("stack", clipboard.stack, WE.hasNBTSupportAndSel, missingPos, "Repeats the blocks in the selection.", "stack (amount) [direction] (Direction defaults to \"self\")")
WE.registerCommand("save", clipboard.save, WE.hasNBTSupport, "Saves a clipboard to a file.", "save (name)")
WE.registerCommand("rotate", clipboard.rotate, function()
    return type(WE.Clipboard) == "table" and #WE.Clipboard > 0
end, function()
    WE.sendChat "You need a clipboard to rotate!"
end, "Rotates all of the blocks in the clipboard on the given axis/axes an increment of 90 degrees.", "rotate (degrees) (axis)")
WE.registerCommand("load", clipboard.load, WE.hasNBTSupport, nil, "Loads a saved clipboard.", "load (name)")
WE.registerCommand({ "list", "ls" }, clipboard.list, true, nilz, "Lists all of the saved schematics in the schematic directory.", "list (Takes no arguments)")

return clipboard