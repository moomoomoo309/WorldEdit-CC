--WorldEdit by moomoomoo309 and exlted. http://www.computercraft.info/forums2/index.php?/topic/16846-worldedit-now-works-with-command-computers/
--For the WorldEdit equivalent of each function, the link is right before the function itself.

--Common variable name syntax:
--pos[1].x, pos[1].y, pos[1].z, and pos[2].x, pos[2].y, and pos[2].z are the coordinates of cuboid selections.
--WE.px, WE.py, and WE.pz are the player's coordinates.

--To add a new command, simply add a call to registerCommand(name/names,condition/conditionFunction,ifFunction,elseFunction) in registerCommands,
--And add the help entry in helpText and commandSyntax.

--If you want to use this program in an OS or somehow bootstrap it to another program, instructions are on the bottom of this file.


--Local vars, so as to not fill the global namespace
WE = {}
WE.Selection = {}
WE.pos = nil
WE.isCommandComputer = nil
local taskAmt
WE.px, WE.py, WE.pz = nil, nil, nil
WE.command, WE.normalArgs, WE.namedArgs, WE.shortSwitches, WE.longSwitches = nil, nil, nil, nil, nil
local firstHpos
local endProgram
local username, message, OriginalMessage
local debug
local ConfigPath
WE.ConfigFolder = nil
WE.ClipboardPath = "Clipboard"
WE.RandomSetOrder = nil
local ConfigAPIPath = "NewConfigAPI.lua"
local SelectionPath = "Selection"
local IDPath = "trustedIDs"
local PluginPath
local p, w, pl, ent
local BlockNames, MCNames, IDs
WE.pipeBlocks = nil
local trustedIDs, currentCmds
WE.blockBlacklist = {}
WE.cfg = nil
WE.makeSelection = {}
WE.plugins = {}
WE.maxSel = { cuboid = 2, ellipse = 2, poly = 9001 } --The maximum number of positions allowed for selection types.

local function getCommand()
    local username, message
    while true do
        local args = { os.pullEvent() } --Get "chat" messages. All chat boxes seem to pass events that start with chat.
        if args[1]:sub(1, 4) == "chat" then
            --Rednet and console input pass events starting with chat, and so, run through this function.
            if not WE.isCommandComputer then
                --The adventure map interface uses a different number of arguments.
                username = args[2]
                message = args[3]
                break
            end
            username = args[#args - 1]
            message = args[#args]
            break
        end
    end
    return username, message
end

--Converts a block ID to minecraft's unlocalized name. removeMinecraft will remove the "minecraft:" at the beginning.
function WE.idToMCName(id, removeMinecraft)
    if tonumber(id) and tonumber(id) <= 175 then
        id = tonumber(id)
        return (removeMinecraft and MCNames[id]:sub(1, 11) == "minecraft:" and MCNames[id]:sub(11)) or MCNames[id] or id
    end
end

--Converts a block's name to its block ID (vanilla blocks only!)
function WE.MCNameToID(name, addMinecraft)
    if type(name) == "string" then
        return tonumber(IDs[((addMinecraft and name:sub(1, 11) ~= "minecraft:" and "minecraft:" .. name) or name)])
    end
end

--Sends chat using either the adventure map interface or a command computer, depending on which is available.
function WE.sendChat(...)
    local msg = ""
    local padding = "    "
    for i = 1, select("#", ...) do
        local v = (select(i, ...))
        msg = msg .. padding .. (v == nil and "nil" or type(v) == "table" and (serpent and serpent.block(v) or textutils.serialize(v)) or tostring(v))
    end
    msg = msg:sub(#padding + 1)
    if msg == "" then
        return
    end
    if WE.isCommandComputer then
        commands.async.say(msg)
    else
        for _, v in pairs(p.getPlayerUsernames()) do
            --Send chat to all players
            p.getPlayerByName(v).WE.sendChat(msg)
        end
    end
end

function WE.getBlockID(x, y, z)
    --- Gets the block ID or the name of the block at the given coordinates.
    return (not WE.isCommandComputer and w.WE.getBlockID(x, y, z)) or WE.MCNameToID(commands.getBlockInfo(x, y, z).name) or commands.getBlockInfo(x, y, z).name
end

function WE.getMetadata(x, y, z)
    --- Gets the meta of the block at the given coordinates
    return ((not WE.isCommandComputer and w.WE.getMetadata(x, y, z)) or commands.getBlockInfo(x, y, z).metadata)
end

local function setBlockWithoutNBT(x, y, z, id, meta)
    --- Sets the block at the given coords to the given ID and metadata using either the adventure map interface or a command computer.
    meta = tonumber(meta)
    if not WE.isCommandComputer then
        return w.setBlockWithoutNotify(x, y, z, tonumber(id) or WE.MCNameToID(id), meta) --Set the block to the appropriate block type.
    else
        coroutine.yield() --Slows down the block setting tremendously, but prevents "too long without yielding" errors.
        taskAmt = taskAmt and taskAmt + 1 or 1
        if taskAmt == 4095 then
            os.pullEvent "taskCount"
        end
        commands.async.setblock(x, y, z, (tonumber(id) and WE.idToMCName(tonumber(id), false) or id), meta and meta > 0 and meta or 0)
    end
end

function WE.setBlock(x, y, z, id, meta, NBT)
    --- Sets a block with/without NBT using a command computer
    NBT = NBT or ""
    if (type(NBT) == "string" and #NBT > 0) or (type(NBT) == "table" and select(2, next(NBT)) ~= nil) then
        taskAmt = taskAmt and taskAmt + 1 or 1
        meta = tonumber(meta)
        commands.async.setblock(x, y, z, ((tonumber(id) and (WE.idToMCName(tonumber(id), false))) or id), meta and meta > 0 and meta or 0, "replace", NBT)
    else
        setBlockWithoutNBT(x, y, z, id, meta)
    end
end

function WE.blockHasChanged(x, y, z, id, meta, blocksTbl, slow)
    --- Returns if the given block differs in block ID or metadata to the one provided.
    local blockData
    if WE.isCommandComputer then
        x, y, z = math.floor(x, y, z)
        blockData = blocksTbl and blocksTbl[x] and blocksTbl[x][y] and blocksTbl[x][y][z]
        if not blockData then
            if not slow then
                return "?" --Still truthy, but can be checked for. Block change unknown, so true is assumed.
            else
                blockData = commands.getBlockInfo(x, y, z)
            end
        end
        return tostring(blockData.name) ~= tostring(WE.idToMCName(id) or id) or (meta ~= "-1" and tostring(blockData.metadata) ~= tostring(meta))
    end
    coroutine.yield()
    return tostring(WE.getBlockID(x, y, z)) ~= tostring(id) or (meta ~= -1 and tostring(WE.getMetadata(x, y, z)) ~= tostring(meta))
end

function WE.blockEquals(x, y, z, id, meta, blocksTbl)
    --- Returns if the given block's ID and metadata equal the block's at the given coords
    return not WE.blockHasChanged(x, y, z, id, meta, blocksTbl)
end

local taskAmt = 0
local function taskCounter()
    --- Makes sure when setting blocks that the task limit is not exceeded.
    while true do
        os.pullEvent "task_complete"
        taskAmt = taskAmt and taskAmt - 1 or 0
        os.queueEvent "taskCount"
    end
end

local function serpentProgress()
    while true do
        local _, progress = os.pullEvent "SerpentProgress"
        progress = tostring(progress)
        WE.sendChat(("Table serialization %s%% complete."):format(progress:sub(1, progress:find(".", nil, true) + 2)))
    end
end

local function numToOrdinalForm(num)
    --- Converts a number into ordinal form (1 to 1st, 2 to 2nd, etc.)
    local num2 = math.floor(num)
    return num2 .. ((num2 < 11 or num2 > 13) and (num2 % 10 > 0 and num2 % 10 <= 3 and select(num2 % 10, "st", "nd", "rd")) or "th")
end

function WE.getPlayerPos()
    --- Gets the position of the player. Runs fewer commands than getPlayerPositionAndLooking.
    if WE.isCommandComputer then
        local state, result = commands.tp(username, "~", "~", "~")
        if state then
            local returnVal = stringx.split(result[1]:sub(16 + #username), ",")
            for i = 1, #returnVal do
                returnVal[i] = math.floor(tonumber(returnVal[i]:sub(1, math.min(#returnVal[i]))))
            end
            return unpack(returnVal)
        end
    end
    return ent.getPosition()
end

function WE.makeSelection.cuboid()
    --- Makes a cuboid selection given two points are selected.
    WE.Selection = { pos1 = WE.pos[1], pos2 = WE.pos[2], type = "cuboid" }
    for x = math.min(WE.pos[1].x, WE.pos[2].x), math.max(WE.pos[1].x, WE.pos[2].x) do
        for y = math.min(WE.pos[1].y, WE.pos[2].y), math.max(WE.pos[1].y, WE.pos[2].y) do
            for z = math.min(WE.pos[1].z, WE.pos[2].z), math.max(WE.pos[1].z, WE.pos[2].z) do
                WE.Selection[#WE.Selection + 1] = { x = x, y = y, z = z }
            end
        end
    end
    WE.writeSelection()
    return WE.Selection
end

--- pos is the table which holds the positions which bound the selection, and is also a function which sets a position to the player's feet.
-- Using metatables, it can do both!
local function resetPos(tbl)
    --- Resets pos to the given value, resetting its metatable and setting its values to what's provided (or an empty table)
    WE.pos = setmetatable(tbl or { firstPos = false, type = WE.Selection.type or "cuboid" }, {
        __call = function(_, numPosition)
            numPosition = numPosition or (WE.Selection.type == "cuboid" or (WE.Selection and WE.Selection.type == "cuboid")) and ((function()
                WE.pos.firstPos = not WE.pos.firstPos return WE.pos.firstPos
            end)() and 1 or 2) or #WE.pos + 1
            WE.pos[numPosition] = WE.pos[numPosition] or {}
            WE.pos[numPosition].x, WE.pos[numPosition].y, WE.pos[numPosition].z = WE.getPlayerPos(username)
            WE.pos[numPosition].y = WE.pos[numPosition].y - 1 --Select the block UNDERNEATH them, not the block they're in.
            WE.pos[numPosition].x, WE.pos[numPosition].y, WE.pos[numPosition].z = math.floor(WE.pos[numPosition].x, WE.pos[numPosition].y, WE.pos[numPosition].z)
            if WE.pos[1] and WE.pos[2] and WE.pos[1].x and WE.pos[2].x and WE.pos[1].y and WE.pos[2].y and WE.pos[1].z and WE.pos[2].z then
                if WE.makeSelection[WE.Selection.type] then
                    WE.makeSelection[WE.Selection.type]()
                else
                    WE.sendChat(("Selection mode %s not implemented correctly!"):format(WE.Selection.type))
                    return
                end
            end
            WE.sendChat(("%s position set to (%d, %d, %d)%s"):format(numToOrdinalForm(numPosition), WE.pos[numPosition].x, WE.pos[numPosition].y, WE.pos[numPosition].z, ((#WE.Selection > 0 and (" (" .. #WE.Selection .. ")")) or "")))
            WE.pos.type = WE.Selection.type
            WE.writeSelection()
        end
    })
end

function WE.writeSelection(Selection)
    --- Saves the current positions to a file.
    if SelectionPath and SelectionPath ~= "" then
        --Load the last selection from file, if it exists.
        local f = fs.open(WE.ConfigFolder .. SelectionPath, "w")
        f.write(textutils.serialize(WE.pos))
        f.close()
    end
end

local function readSelection()
    --- Load the last selection from file, if it exists.
    if SelectionPath and SelectionPath ~= "" and fs.exists(WE.ConfigFolder .. SelectionPath) then
        local f = fs.open(WE.ConfigFolder .. SelectionPath, "r")
        resetPos(textutils.unserialize(f.readAll()))
        f.close()
        if all(WE.pos[1], WE.pos[2]) and all(WE.pos[1].x, WE.pos[1].y, WE.pos[1].z, WE.pos[2].x, WE.pos[2].y, WE.pos[2].z) then
            if WE.makeSelection[WE.Selection.type] then
                WE.makeSelection[WE.Selection.type]()
            else
                WE.sendChat(("Selection mode %s not implemented correctly!"):format(WE.Selection.type))
                return
            end
        end
    end
    WE.Selection = WE.Selection or {}
end

local function writeIDs()
    --- Writes the list of trusted rednet IDs to a file.
    if IDPath and IDPath ~= "" then
        --Load the IDs from file, if they exist.
        local f = fs.open(WE.ConfigFolder .. IDPath, "w")
        f.write(textutils.serialize(trustedIDs))
        f.close()
    end
end

local function readIDs()
    --- Reads the list of trusted rednet IDs from a file.
    if SelectionPath and IDPath ~= "" and fs.exists(WE.ConfigFolder .. IDPath) then
        --Load the IDs from file, if they exist.
        local f = fs.open(WE.ConfigFolder .. IDPath, "r")
        local file = textutils.unserialize(f.readAll())
        f.close()
        return file
    end
    return {}
end

--Beginning of Wergat's code (with minor modifications by me)
local function convertNBTtoTable(startString)
    --- Converts NBT strings to Lua tables
    local function getCharAtPos(str, pos)
        return str:sub(pos, pos)
    end

    local warn = function(str)
        local f = fs.open("error", "w")
        f.write(str)
        f.close()
    end
    local str = startString
    local t = {}
    local err = false
    if getCharAtPos(str, 1) ~= "{" and getCharAtPos(str, 1) ~= "[" then
        err = true
        warn(("[NBTtoTable] Wrong start of NBT! \"%s\" (%s)"):format(getCharAtPos(str, 1), startString))
    end
    local isBlocky = getCharAtPos(str, 1) == "["
    str = str:sub(2, -1)
    local keyCount = 0
    while #str > 0 and not err and str ~= "}" and str ~= "]" do
        local key = ""
        local value = ""

        -- Find key (or value if it is a list)
        local i = 1
        while getCharAtPos(str, i):match "%w" and i < #str do
            key = key .. (getCharAtPos(str, i))
            i = i + 1
        end
        if not (getCharAtPos(str, i) == ":" or (getCharAtPos(str, i) == "," and isBlocky)) then
            warn(("[NBTtoTable] End of key error \"%s\" (key=%s) (%s)) %s"):format(getCharAtPos(str, i), key, startString, tostring(isBlocky)))
            err = true
        end
        if getCharAtPos(str, i) == "," and isBlocky then
            value = key
            key = keyCount
            keyCount = keyCount + 1
        else
            str = str:sub(i + 1, -1)
            local function doString()
                local j = 2
                while (not (getCharAtPos(str, j) == "\"" and getCharAtPos(str, j - 1) ~= "\\")) and (j) < #str do
                    value = value .. getCharAtPos(str, j)
                    j = j + 1
                end
                t[key] = (value)
                str = str:sub(j + 1, -1)
            end

            local function doNumber()
                local j = 1
                -- string.match(getCharAtPos(str,j),"%w") or getCharAtPos(str,j)=="." or (getCharAtPos(str,j)=="-" and j==1)
                while getCharAtPos(str, j) ~= "," and (j) < #str do
                    value = value .. (getCharAtPos(str, j))
                    j = j + 1
                end
                local typeIdentifier = value:sub(-1, -1)
                -- Remove type identifier
                str = str:sub(j, -1)
                local v = value:sub(1, -2)
                if tonumber(v) or #v == 0 then
                    -- Boolean
                    if typeIdentifier == "b" then
                        t[key] = "1" == v
                    else -- Number of some kind
                        if tonumber(typeIdentifier) then
                            t[key] = tonumber(v .. typeIdentifier)
                        else
                            t[key] = tonumber(v)
                        end
                    end
                else
                    t[key] = value
                end
            end

            local function doTable()
                local j = 2
                local openSwrily = getCharAtPos(str, 1) == "{" and 1 or 0
                local openBlocky = getCharAtPos(str, 1) == "[" and 1 or 0
                local isString = false
                local bracketString = getCharAtPos(str, 1)
                while ((openSwrily >= 1 or openBlocky >= 1) and (j) < #str) do
                    bracketString = bracketString .. (getCharAtPos(str, j))
                    if getCharAtPos(str, j) == "{" and not isString then
                        openSwrily = openSwrily + 1
                    end
                    if getCharAtPos(str, j) == "[" and not isString then
                        openBlocky = openBlocky + 1
                    end
                    if getCharAtPos(str, j) == "]" and not isString then
                        openBlocky = openBlocky - 1
                    end
                    if getCharAtPos(str, j) == "}" and not isString then
                        openSwrily = openSwrily - 1
                    end
                    if getCharAtPos(str, j) == "\"" and getCharAtPos(str, j - 1) ~= "\\" then
                        isString = not isString
                    end
                    j = j + 1
                end
                t[key] = convertNBTtoTable(bracketString)
                str = str:sub(bracketString:len() + 1, -1)
            end

            -- Find Value
            -- Is number
            if getCharAtPos(str, 1):match "%w" or getCharAtPos(str, 1) == "-" then
                doNumber()
                -- Is string
            elseif getCharAtPos(str, 1) == '"' then
                doString()
            elseif getCharAtPos(str, 1) == '{' or getCharAtPos(str, 1) == '[' then
                doTable()
            else
                warn(("[NBTtoTable] Invalid stuff type >%s<"):format(getCharAtPos(str, 1)))
                err = true
            end
        end
        -- Remove something?
        str = str:sub(2, -1)
    end
    return t
end

local isArmorStandCreated = {}
local function getPlayerPositionAndLooking(playerName)
    --- Returns the position, pitch, and yaw of the player with the given name.
    local pos = {}
    local entitySelector = ("@e[name=%s,type=ArmorStand]"):format(playerName)
    if not isArmorStandCreated[playerName] then
        isArmorStandCreated[playerName] = commands.testfor(entitySelector)
        if not isArmorStandCreated[playerName] then
            commands.summon("ArmorStand", "~", "~1", "~", { CustomName = playerName, ShowArms = 1, Invisible = 1, NoGravity = 1, DisabledSlots = 1973790 })
        end
    end
    commands.tp(entitySelector, playerName)
    local _, e = commands.entitydata(entitySelector, {})
    local data = convertNBTtoTable(e[1]:sub(30, -1))
    pos.position = { x = tonumber(data.Pos["0"]) or 0, y = tonumber(data.Pos["1"]) or 0, z = tonumber(data.Pos["2"]) or 0 }
    pos.rotation = { rX = tonumber(data.Rotation["0"]) or 0, ["rY"] = tonumber(data.Rotation["1"]) or 0 }
    commands.tp(entitySelector, 0, 10, 0)
    return pos
end

--End of Wergat's code

local function hpos(numPosition)
    --- Selects the block the player is looking at.
    if not tonumber(numPosition) then
        WE.sendChat "Specify a position!"
        return
    elseif tonumber(numPosition) > WE.maxSel[WE.Selection.type] then
        WE.sendChat(("Try and pick a position that'll be used. (1-%d)"):format(WE.maxSel[WE.Selection.type]))
        return
    end
    local playerInfo = getPlayerPositionAndLooking(username)
    local pitch, yaw = playerInfo.rotation.rX, playerInfo.rotation.rY
    --The player's eyes are 1.62 blocks from the ground
    WE.px, WE.py, WE.pz = playerInfo.position.x, playerInfo.position.y + 1.62, playerInfo.position.z
    WE.blockBlacklist = WE.blockBlacklist or { 0, "minecraft:air" }
    --Convert pitch/yaw into Vec3 from http://stackoverflow.com/questions/10569659/camera-pitch-yaw-to-direction-vector
    local xzLen = -math.cos(math.rad(yaw))
    local x, y, z = xzLen * math.sin(-math.rad(pitch + 180)), math.sin(math.rad(-yaw)), xzLen * math.cos(math.rad(pitch + 180))
    local lastX, lastY, lastZ = math.huge, math.huge, math.huge
    local mult = 0
    local skip
    local currX, currY, currZ
    while true do
        --Extend the normalized vector out linearly
        currX, currY, currZ = x * mult + WE.px, y * mult + WE.py, z * mult + WE.pz
        --Never check the same block twice.
        skip = math.floor(currX) == math.floor(lastX) and math.floor(currY) == math.floor(lastY) and math.floor(currZ) == math.floor(lastZ)
        if not skip then
            local ID = WE.getBlockID(math.floor(currX, currY, currZ))
            if not tablex.indexOf(WE.blockBlacklist, ID) then
                --Check if it hit a block
                break
            end
        end
        mult = mult + 0.05 --Otherwise check another point along the line.
        if mult >= 100 then
            WE.sendChat "No block found."
            return
        end
        lastX, lastY, lastZ = currX, currY, currZ
    end
    currX, currY, currZ = math.floor(currX, currY, currZ)
    WE.pos[numPosition] = { x = currX, y = currY, z = currZ }
    if all(WE.pos[1], WE.pos[2]) and all(WE.pos[1].x, WE.pos[1].y, WE.pos[1].z, WE.pos[2].x, WE.pos[2].y, WE.pos[2].z) then
        if WE.makeSelection[WE.Selection.type] then
            WE.makeSelection[WE.Selection.type]()
        else
            WE.sendChat(("Selection mode %s not implemented correctly!"):format(WE.Selection.type))
            return
        end
    end
    WE.writeSelection(WE.Selection)
    WE.sendChat(("%s position set to (%d, %d, %d).%s"):format(numToOrdinalForm(numPosition), currX, currY, currZ, (#WE.Selection > 0 and (" (%d)"):format(#WE.Selection or ""))))
end

function WE.getFormattedBlockInfos(x, y, z, x2, y2, z2)
    --find the minimum and maximum verticies
    local minX, minY, minZ = math.floor(math.min(x, x2), math.min(y, y2), math.min(z, z2))
    local maxX, maxY, maxZ = math.floor(math.max(x, x2), math.max(y, y2), math.max(z, z2))
    local tBlockInfos = commands.getBlockInfos(minX, minY, minZ, maxX, maxY, maxZ)
    local tFormattedBlockInfos = {}
    local iTablePosition = 1
    for iy = minY, maxY do
        for iz = minZ, maxZ do
            for ix = minX, maxX do
                tFormattedBlockInfos[ix] = tFormattedBlockInfos[ix] or {}
                tFormattedBlockInfos[ix][iy] = tFormattedBlockInfos[ix][iy] or {}
                tFormattedBlockInfos[ix][iy][iz] = tBlockInfos[iTablePosition]
                iTablePosition = iTablePosition + 1
            end
        end
    end
    return tFormattedBlockInfos
end

--Select large area
function WE.makeCuboidsOfVolume(xLen, yLen, zLen, volume)
    local minLen = math.round(volume ^ .33) - 1
    local min = math.floor(xLen / minLen) * math.floor(yLen / minLen) * math.floor(zLen / minLen)
    local solution = { x = minLen, y = minLen, z = minLen, vol = volume, num = min }
    for x = 1, math.min(xLen, volume) do
        for y = 1, math.min(yLen, volume / x) do
            local z = math.floor(volume / x / y)
            local num = math.ceil(xLen / x) * math.ceil(yLen / y) * math.ceil(zLen / z)
            if num < min then
                min = num
                solution = { x = x, y = y, z = z, vol = (x + 1) * (y + 1) * (z + 1), num = min }
            end
        end
    end
    return solution
end

function WE.selectLargeArea(x1, y1, z1, x2, y2, z2, volume, printProgress)
    volume = type(volume) == number and math.max(volume, 1) or 4096
    x1, y1, z1, x2, y2, z2 = map(tonumber, 1, x1, y1, z1, x2, y2, z2)
    if x1 > x2 then
        x1, x2 = x2, x1
    end
    if y1 > y2 then
        y1, y2 = y2, y1
    end
    if z1 > z2 then
        z1, z2 = z2, z1
    end
    local blockInfo = {}
    local cuboids
    if (x2 - x1 + 1) * (y2 - y1 + 1) * (z2 - z1 + 1) > volume then
        cuboids = WE.makeCuboidsOfVolume(x2 - x1, y2 - y1, z2 - z1, volume)
    else --If it's less than 4096 blocks, you can just select them all at once.
        return WE.getFormattedBlockInfos(x1, y1, z1, x2, y2, z2)
    end
    cuboids = cuboids or { x = x2 - x1, y = y2 - y1, z = z2 - z1 }
    local function getNumIterations(start, stop, step)
        return math.floor((stop - start) / step) + 1
    end

    local function getVol(x1, y1, z1, x2, y2, z2)
        return (math.abs(x2 - x1) + 1) * (math.abs(y2 - y1) + 1) * (math.abs(z2 - z1) + 1)
    end

    local i, totalVol, newVol = 0, 0, 0
    local tbl
    local stepX, stepY, stepZ = map(math.min, 2, cuboids.x, x2 - x1 + 1, cuboids.y, y2 - y1 + 1, cuboids.z, z2 - z1 + 1)
    local totalCuboidsX, totalCuboidsY, totalCuboidsZ = map(getNumIterations, 3, x1, x2, stepX, y1, y2, stepY, z1, z2, stepZ)
    for x = x1, x2, stepX do
        for y = y1, y2, stepY do
            for z = z1, z2, stepZ do
                newVol = getVol(x, y, z, map(math.min, 2, x2, x + stepX - 1, y2, y + stepY - 1, z2, z + stepZ - 1))
                tbl = WE.getFormattedBlockInfos(x, y, z, map(math.min, 2, x2, x + stepX - 1, y2, y + stepY - 1, z2, z + stepZ - 1))
                totalVol = totalVol + newVol
                i = i + 1
                if printProgress then
                    local formattedPercent = tostring(100 * i / (totalCuboidsX * totalCuboidsY * totalCuboidsZ)) --So, let's do some string formatting manually.
                    formattedPercent = formattedPercent:sub(1, (formattedPercent:find(".", nil, true) or #formattedPercent - 1) + 1)
                    local formattedBlocksPercent = tostring(100 * totalVol / ((x2 - x1 + 1) * (y2 - y1 + 1) * (z2 - z1 + 1)))
                    formattedBlocksPercent = formattedBlocksPercent:sub(1, (formattedBlocksPercent:find(".", nil, true) or -2) + 1)
                    WE.sendChat(("Scanning... %s%% (%d/%db, +%d, %d/%dcb (%s%%))"):format(formattedBlocksPercent, totalVol, (x2 - x1 + 1) * (y2 - y1 + 1) * (z2 - z1 + 1), newVol, i, totalCuboidsX * totalCuboidsY * totalCuboidsZ, formattedPercent))
                end
                blockInfo = tablex.merge(blockInfo, tbl)
            end
        end
    end
    return blockInfo
end

local function getFlatSelection(Selection)
    --- Iterates through a selection and converts it to 2D (adds the X,Z if they don't already exist)
    local sel = { pos1 = selection.pos1, pos2 = selection.pos2, type = "flat" }
    sel[1] = selection[1]
    for i = 1, #WE.Selection do
        for j = 1, #sel do
            if selection[i].x == sel[j].x and selection[i].z == sel[j].z then
                break
            elseif j == #sel then
                sel[#sel + 1] = { x = selection[i].x, z = selection[i].z }
            end
        end
    end
    return sel
end

function WE.convertName(tbl, tbl2)
    --- Change block names into block IDs. May convert to minecraft names later.
    if tbl and tbl2 then
        for i = 1, #tbl do
            if tonumber(tbl[i]) == nil then
                for k, v in pairs(BlockNames) do
                    if tablex.find(v, tostring(tbl[i])) then
                        if k == 17 then
                            if tbl[i] == "pine" then
                                tbl2[i] = 1
                            elseif tbl[i] == "birch" then
                                tbl2[i] = 2
                            elseif tbl[i] == "jungle" then
                                tbl2[i] = 3
                            end
                            tbl[i] = k
                            break
                        elseif k == 162 then
                            if tbl[i] == "darkoak" then
                                tbl2[i] = 1
                            end
                            tbl[i] = k
                            break
                        elseif k == 12 then
                            if tbl[i] == "redsand" or tbl[i] == "red_sand" then
                                tbl2[i] = 1
                            end
                            tbl[i] = k
                            break
                        else
                            tbl[i] = k
                            break
                        end
                    elseif next(BlockNames, k) == nil then
                        --The block is not in BlockNames
                        WE.sendChat(("Invalid block: \"%s\", was it a typo?"):format(tbl[i]))
                        return false
                    end
                end
            end
        end
    end
    return true
end

function WE.getDirection(shouldReturn)
    ---Gets the direction the player is currently looking in.
    local playerInfo = getPlayerPositionAndLooking(username)
    local pitch, yaw = playerInfo.rotation.rX, playerInfo.rotation.rY
    --Convert pitch/yaw into Vec3 from http://stackoverflow.com/questions/10569659/camera-pitch-yaw-to-direction-vector
    local xzLen = -math.cos(math.rad(yaw))
    local xDir, yDir, zDir = xzLen * math.sin(-math.rad(pitch + 180)), math.sin(math.rad(-yaw)), xzLen * math.cos(math.rad(pitch + 180))

    local function between(num, limit1, limit2)
        return num >= math.min(limit1, limit2) and num <= math.max(limit1, limit2)
    end

    if between(xDir, .5, 1) then
        WE.Direction = "east"
    elseif between(xDir, -.5, -1) then
        WE.Direction = "west"
    elseif between(xDir, -.5, .5) and between(zDir, .5, 1) then
        WE.Direction = "south"
    elseif between(xDir, -.5, .5) and between(zDir, -1, -.5) then
        WE.Direction = "north"
    elseif yDir > 0.85 then
        WE.Direction = "up"
    elseif yDir < -0.15 then
        WE.Direction = "down"
    else
        WE.sendChat "I believe you are looking inside out."
        return false
    end
    WE.Direction = WE.Direction:lower()
    --If shouldReturn is false, it's just modifying the Direction in the global table.
    if shouldReturn then
        return WE.Direction
    end
end

function WE.oppositeDirection(dir)
    --- Returns the direction opposite of the one provided (up returns down, east returns west, etc.)
    return ({ north = "south", south = "north", east = "west", west = "east", up = "down", down = "up" })[dir:lower()] or false
end

function WE.isDirection(dir)
    --- Returns if the given string is a direction
    return tablex.indexOf({ "up", "down", "north", "south", "east", "west", "self", "me" }, dir) ~= nil
end

function WE.hasDirection(str)
    --- Returns whether the given string contains a direction in it
    for _, dir in pairs { "up", "down", "north", "south", "east", "west", "self", "me" } do
        if str:find(" " .. dir) then
            return true
        end
    end
    return false
end


local sel = function(numPos)
    --- Clears the selection at the given position, or altogether.
    numPos = tonumber(numPos) or tonumber(WE.normalArgs[1])
    WE.Selection = {}
    if #WE.normalArgs == 0 then
        resetPos()
        WE.sendChat "Selection cleared."
    elseif numPos then
        WE.pos[numPos] = nil
    elseif WE.makeSelection[WE.normalArgs[1]] then
        WE.Selection.type = WE.normalArgs[1]
        WE.sendChat(("Selection type set to \"%s\""):format(WE.normalArgs[1]))
        resetPos()
    end
    fs.delete(WE.ConfigFolder .. SelectionPath)
end

local helpText = {
    --Contains all of the help text for each command.
    blockpatterns = 'A number of commands which take a "block" parameter really take a pattern. Rather than set one single block (by name or ID), a pattern allows you to set more complex patterns. For example, you can set a pattern where each block has a 10% chance of being brick and a 90% chance of being smooth stone.\nBlock probability pattern is specified with a list of block types (supports block:meta) with their respective probability.\nExample: Setting all blocks to a random pattern using a list with percentages (Which do not need to add to 100%):\n"set 15%planks:3,95%3"\nFor a truly random pattern, no probability percentage is needed.\nExample: Setting all blocks to a random pattern using a list without percentages\n"set obsidian,stone"',
}

local commandSyntax = {--Contains the syntax for each command.
}

local sortedHelpKeys = {} --These are used to traverse the table in order. It contains the keys alphabetically.
table.sort(sortedHelpKeys) --Sort the keys alphabetically

local function titleCase(str)
    return str:sub(1, 1):upper() .. str:sub(2)
end

local function help()
    --- Prints out help on the given page or for the given command.
    local command = WE.normalArgs[1] and WE.normalArgs[1]:lower() or 1
    sortedHelpKeys = {}
    for k, _ in pairs(helpText) do
        table.insert(sortedHelpKeys, k)
    end
    table.sort(sortedHelpKeys)
    local commandsPerPage = 8
    local numPages = math.ceil(#sortedHelpKeys / commandsPerPage)
    if tonumber(command) then
        local pageNum = math.min(command, numPages)
        WE.sendChat "Run \"help (commandname)\" for a description of the command and its syntax."
        for i = 1, commandsPerPage do
            local index = i + (pageNum - 1) * commandsPerPage
            if index > #sortedHelpKeys then
                break
            end
            if sortedHelpKeys[index] ~= "blockpatterns" then
                WE.sendChat(("%s - %s"):format(titleCase(sortedHelpKeys[index]), helpText[sortedHelpKeys[index]]))
            else
                WE.sendChat("BlockPatterns - See help BlockPatterns for more information.")
            end
        end
        WE.sendChat(("Page %d/%d"):format((pageNum < numPages and pageNum or numPages), numPages))
    elseif helpText[command] then
        WE.sendChat(("%s - %s"):format(command, helpText[command]))
        if commandSyntax[command] then
            WE.sendChat(("Syntax: %s"):format(commandSyntax[command]))
        end
    else
        WE.sendChat(("Command \"%s\" not found."):format(command))
    end
end

local cmds = {} --Holds each command.
function WE.registerCommand(nameTbl, fct, condition, elseFct, helptext, syntax)
    --- Adds a command to the list.
    cmds[#cmds + 1] = { names = nameTbl, fct = fct, condition = condition, elseFct = elseFct }
    if type(nameTbl) == "string" then
        if not helpText[nameTbl] and not helpText then
            WE.sendChat(("Missing syntax for command %s."):format(type(nameTbl) == "string" and nameTbl or table.concat(nameTbl, " and ")))
        end
        helpText[nameTbl] = helptext
        commandSyntax[nameTbl] = syntax
    elseif type(nameTbl) == "table" then
        for k, v in pairs(nameTbl) do
            if not helpText[nameTbl] and not helpText then
                WE.sendChat(("Missing help text for command %s."):format(type(nameTbl) == "string" and nameTbl or table.concat(nameTbl, " and ")))
            end
            helpText[v] = helptext
            commandSyntax[v] = syntax
        end
    end
end

stringx = stringx or {} --parseCommandArgs needs it, so it needed to be in here.
function stringx.split(str, char)
    --- Converts str into a table given char as a delimiter. Works like String.split() in Java without pattern recognition.
    local tbl = {}
    local findChar, findCharEnd = str:find(char, nil, true)
    if findChar then
        tbl[#tbl + 1] = str:sub(1, findChar - 1)
        repeat
            local findChar2, findChar2End = str:find(char, findCharEnd + 1, true)
            if findChar2 then
                tbl[#tbl + 1] = str:sub(findCharEnd + 1, findChar2 - 1)
                findChar, findCharEnd = findChar2, findChar2End
            end
        until findChar2 == nil
        tbl[#tbl + 1] = str:sub(findCharEnd + 1)
    else
        return { str }
    end
    return tbl
end

local function parseCommandArgs(message, argAfterShortSwitches, argAfterLongSwitches)
    --- Returns the command and its arguments separated as tables.
    local normalArgs, namedArgs, shortSwitches, longSwitches = {}, {}, {}, {}
    local splitMsg = stringx.split(message, " ")
    local currentCommand = splitMsg[1]:lower()
    --Used to grab the next element if needed.
    local currTbl
    local currElement

    for i = 2, #splitMsg do
        local currentArg = splitMsg[i] --Prevent repeated table lookups, 'cause lua doesn't do switch
        if currElement and currTbl then
            --Use currentArg as the value for currTbl.
            currTbl[currElement] = currentArg
            currElement, currTbl = nil, nil
            --If this wasn't lua, I'd have put a continue here, but this is, so it's an if-else.
        else
            if currentArg:sub(1, 2) == "--" then
                local equalsIndex = currentArg:find("=", nil, true) --Don't use Lua patterns.
                if equalsIndex then
                    namedArgs[currentArg:sub(1, equalsIndex - 1)] = currentArg:sub(equalsIndex + 1) --"command blah=this"
                else
                    if argAfterLongSwitches then
                        --Use the switch as the key, and the next element as the value.
                        currElement = currentArg:sub(3) --"command --blah"
                        currTbl = longSwitches
                    else
                        longSwitches[currentArg:sub(3)] = true
                    end
                end
            elseif currentArg:sub(1, 1) == "-" then
                if argAfterShortSwitches then
                    --Use the switch as the key, and the next element as the value.
                    currElement = currentArg:sub(2) --"command -blah"
                    currTbl = shortSwitches
                else
                    shortSwitches[currentArg:sub(2)] = true
                end
            else
                normalArgs[#normalArgs + 1] = currentArg --"command blah"
            end
        end
    end
    return currentCommand, normalArgs, namedArgs, shortSwitches, longSwitches
end

function WE.runCommands(msgOverride, forceSilentOverride)
    --- Runs the command corresponding to the current message.
    WE.command, WE.normalArgs, WE.namedArgs, WE.shortSwitches, WE.longSwitches = parseCommandArgs(msgOverride or OriginalMessage) --Get args from command
    local oldForceSilent
    if forceSilentOverride ~= nil then
        oldForceSilent = forceSilent
        _G.forceSilent = forceSilentOverride
    end
    for i = 1, #cmds do
        local names = ((type(cmds[i].names) == "table" and cmds[i].names) or { cmds[i].names })
        for i2 = 1, #names do
            --It'll put the name into a table if it isn't already.
            if WE.command == names[i2]:lower() then
                if type(cmds[i].fct) == "function" and (cmds[i].condition == nil or type(cmds[i].condition) == "function" and cmds[i].condition() or (cmds[i].condition) ~= "function" and cmds[i].condition) then
                    cmds[i].fct()
                    return
                elseif type(cmds[i].elseFct) == "function" then
                    cmds[i].elseFct()
                    return
                end
                WE.sendChat(("No function(s) defined for command \"%s\"."):format(WE.command))
                return
            elseif i == #cmds and i2 == #names then
                WE.sendChat(("No command \"%s\" found."):format(tostring(WE.command)))
            end
        end
    end
    if forceSilentOverride ~= nil then
        _G.forceSilent = oldForceSilent
    end
end

local function exportVar(varName, filePath, silent, printFct, shouldPrint)
    --- Prints out the value of a global variable, and writes it to a file.
    varName = tostring(varName)
    printFct = type(printFct) == "function" and printFct or print
    local shortVarName = varName:sub(1, (varName:find("%.", nil, true) or (#varName + 1)) - 1)
    local var = rawget(_G, shortVarName) or rawget(_ENV, shortVarName) --Check locals and globals
    if var ~= nil then
        --It's allowed to be false, so an explicit nil check is needed.
        local outString = ""
        if type(var) == "table" and varName:find(".", nil, true) then
            local fields = stringx.split(varName, ".")
            for i = 2, #fields do
                var = var[tonumber(fields[i]) or fields[i]]
            end
        end
        outString = (type(var) == "table" and ((serpent and serpent.block(var, { numformat = "%d" }))) or textutils.serialize(var)) or (type(var) == "function" and string.dump(var)) or tostring(var)
        if filePath then
            local success, errMessage = pcall(--Try to write it to a file, and catch and rethrow any errors if necessary.
            function()
                if type(filePath) == "string" and #filePath > 0 then
                    local f = fs.open(filePath, "w")
                    f.write(outString)
                    f.close()
                else
                    error(("File path \"%s\" not a valid path!"):format(tostring(filePath)))
                end
            end)
            if not silent then
                if not success then
                    printFct(("Error writing to file! Error message: \"%s\"."):format(errMessage))
                else
                    printFct(("Variable \"%s\" written to file at %s."):format(varName, filePath))
                end
            end
        end
        if shouldPrint then
            printFct(outString)
        end
        return outString
    elseif not silent then
        printFct(("The variable \"%s\" doesn't exist or is nil."):format(tostring(varName)))
    end
end

local function loadPlugin(filePath)
    --- Load a plugin. This function expects to be run in protected mode. (pcall)
    if not fs.exists(filePath) or fs.isDir(filePath) then
        error(("Tried to access file at %s, but no file existed."):format(filePath))
    end
    local file = loadfile(filePath)
    setfenv(file, getfenv())
    local success, val = pcall(file)
    if not success then
        error(val) --The error will propogate to loadPlugins, which will handle it.
    end
    return val
end

local function loadPlugins()
    --- Load all of the plugins in the plugin folder.
    for k, v in pairs(fs.list(WE.ConfigFolder .. PluginPath)) do
        local success, pluginVal = pcall(loadPlugin, WE.ConfigFolder .. PluginPath .. "/" .. v)
        if not success then
            WE.sendChat(("Error loading %s! Plugin errored in initialization!\nError Message: %s"):format(v, tostring(pluginVal)))
        else
            if pluginVal == true then
                WE.plugins[v] = pluginVal
            else
                if type(pluginVal) ~= "table" or not pluginVal.name then
                    WE.sendChat(("Warning! Plugin at %s did not specify a name! Using its filename instead..."):format(v))
                else
                    WE.plugins[pluginVal.name] = pluginVal
                end
            end
        end
    end
end

function missingPos()
    --- What to do if position(s) are missing. Used in registering commands a ton.
    WE.sendChat "Set a position first!"
end

function WE.hasSelection()
    --- The most common condition for a command to fail. Used in registering commands a ton.
    return WE.Selection and #WE.Selection > 0
end

function WE.hasNBTSupport()
    --- Check if command computers exist or the adventure map interface works in this version.
    return (fs.open("/rom/help/changelog", "r").readAll():find("1.7", nil, true)) ~= nil or p
end

function WE.hasNBTSupportAndSel()
    return WE.hasSelection() and WE.hasNBTSupport()
end

local function registerCommands()
    WE.registerCommand("sel", function()
        sel(#WE.normalArgs > 0 and WE.normalArgs[1] or nil)
    end, nil, nil, "Clears the selection, with an argument specifying which position to clear, or \"vert\", to expand the selection to Y 0-256 or changes the selection type.", "sel [1/2/vert/poly/cuboid/ellipse]")
    WE.registerCommand("pos", function()
        WE.pos(tonumber(#WE.normalArgs == 1 and #WE.normalArgs[1] > 0 and WE.normalArgs[1] or message:sub(4)))
    end, nil, nil, "Selects the position specified using the block the player is standing on.", "pos (position number)")
    WE.registerCommand("pos1", function()
        WE.pos(1)
    end, nil, nil, "Selects the first position using the block the player is standing on.", "pos1 (Takes no arguments)")
    WE.registerCommand("pos2", function()
        WE.pos(2)
    end, nil, nil, "Selects the second position using the block the player is standing on.", "pos2 (Takes no arguments)")
    WE.registerCommand("hpos", function()
        firstHpos = firstHpos == nil and false or firstHpos
        if #WE.normalArgs == 1 then
            hpos(tonumber(WE.normalArgs[1]))
        elseif WE.Selection.type == "cuboid" or WE.Selection.type == "ellipse" then
            firstHpos = not firstHpos
            hpos(tonumber(firstHpos and 1 or 2))
        else
            hpos(#WE.pos + 1)
        end
    end, nil, nil, "Selects the position specified using the block the player is looking at.", "hpos (position number)")
    WE.registerCommand("hpos1", function()
        hpos(1)
    end, nil, nil, "Selects the first position using the block the player is looking at.", "hpos1 (Takes no arguments)")
    WE.registerCommand("hpos2", function()
        hpos(2)
    end, nil, nil, "Selects the second position using the block the player is looking at.", "hpos2 (Takes no arguments)")
    WE.registerCommand("expand", function()
        if Plugins[WE.Selection.type] then
            Plugins[WE.Selection.type].expand()
        else
            WE.sendChat(("Expand not implemented for selection mode %s. This is a bug."):format(WE.Selection.type))
        end
    end, WE.hasSelection, missingPos, "Expands the selection in the given direction, or in the direction the player is looking if not specified.", "expand (amount) [direction] (Direction defaults to \"self\")")
    WE.registerCommand("contract", function()
        if Plugins[WE.Selection.type] then
            Plugins[WE.Selection.type].contract()
        else
            WE.sendChat(("Contract not implemented for selection mode %s. This is a bug."):format(WE.Selection.type))
        end
    end, WE.hasSelection, missingPos, "Contracts the selection in the given direction, or in the direction the player is looking if not specified.", "contract (amount) [direction] (Direction defaults to \"self\")")
    WE.registerCommand("inset", function()
        if Plugins[WE.Selection.type] then
            Plugins[WE.Selection.type].inset()
        else
            WE.sendChat(("Inset not implemented for selection mode %s."):format(WE.Selection.type))
        end
    end, nil, nil, "Shrinks the selection by one block in all directions.", "inset (amount)")
    WE.registerCommand("outset", function()
        if Plugins[WE.Selection.type] then
            Plugins[WE.Selection.type].outset()
        else
            WE.sendChat(("Outset not implemented for selection mode %s."):format(WE.Selection.type))
        end
    end, nil, nil, "Expand the selection by one block in all directions.", "outset (amount)")
    WE.registerCommand({ "terminate", "exit" }, function()
        WE.sendChat "Goodbye!"
        print "Goodbye!"
        endProgram = true
    end, "Ends the program.", "exit (Takes no arguments)")
    WE.registerCommand({ "reboot", "restart" }, os.reboot, nil, nil, "Reboots the computer.", "Reboot (Takes no arguments)")
    WE.registerCommand({ "help", "?" }, help, nil, nil, "Lists commands or gives information and syntax about specific commands.", "help [page/command name]")
    WE.registerCommand("endchatspam", function()
        WE.sendChat "Spam ended."
        commands.gamerule("commandBlockOutput", false)
    end, WE.isCommandComputer, function()
        WE.sendChat "There is no chat spam, silly!"
    end, "Turns off commandBlockOutput. Only works with command computers.", "endchatspam (Takes no arguments)")
    WE.registerCommand("refresh", loadPlugins, nil, nil, "Re-runs all the files, allowing all changes to take effect.", "refresh (Takes no arguments)")
    WE.registerCommand("clear", function()
        term.clear()
        term.setCursorPos(1, 1)
        io.write "Type your command:\n> "
    end, nil, nil, "Clears the screen.", "clear (Takes no arguments)")
    WE.registerCommand("exportvar", function()
        exportVar(WE.normalArgs[1], WE.ConfigFolder .. "vars/" .. WE.normalArgs[1], WE.longSwitches.silent, WE.sendChat, true)
    end, "A debug command which exports the given variable to a file. table indices (string only) may be separated by dots.", "exportVar (variable name/tablename.index1.index2...)")
end

local function getPlayerName()
    --- Returns the name of the closest player.
    if WE.isCommandComputer then
        local state, result = commands.xp(0, "@p") --The result will be "gave 0 experience to playername"
        if state then
            return result[1]:sub((stringx.findLast(result[1], " ", nil, true)) + 1)
        end
    end
end

--- lsh, created by Lyqyd, with only a few tweaks by me
-- (mostly bugfixes to get it working without the entirety of the file, and changing the history path)
-- Used for the console input (and on the rednet companion as well)
local runHistory = {}
if fs.exists ".history" then
    local histFile = io.open(".history", "r")
    if histFile then
        for line in histFile:lines() do
            table.insert(runHistory, line)
        end
        histFile:close()
    end
end
local sizeOfHistory = #runHistory

local function saveHistory()
    if #runHistory > sizeOfHistory then
        local histFile = io.open(".history", "a")
        if histFile then
            for i = sizeOfHistory + 1, #runHistory do
                histFile:write(runHistory[i] .. "\n")
            end
            histFile:close()
        end
    end
end

local function customRead(history)
    term.setCursorBlink(true)

    local line = ""
    local nHistoryPos
    local nPos = 0

    local w, h = term.getSize()
    local sx, sy = term.getCursorPos()

    local function redraw()
        local nScroll = 0
        if sx + nPos >= w then
            nScroll = (sx + nPos) - w
        end

        term.setCursorPos(sx, sy)
        term.write(line:sub(nScroll + 1))
        term.write((" "):rep(math.max(0, w - (#line - nScroll) - sx)))
        term.setCursorPos(sx + nPos - nScroll, sy)
    end

    while true do
        local sEvent, param = os.pullEvent()
        if sEvent == "char" then
            line = line:sub(1, nPos) .. param .. line:sub(nPos + 1)
            nPos = nPos + 1
            redraw()

        elseif sEvent == "key" then
            if param == keys.enter then
                table.insert(runHistory, line)
                saveHistory()
                -- Enter
                break

            elseif param == keys.left then
                -- Left
                if nPos > 0 then
                    nPos = nPos - 1
                    redraw()
                end

            elseif param == keys.right then
                -- Right
                if nPos < #line then
                    nPos = nPos + 1
                    redraw()
                end

            elseif param == keys.up or param == keys.down then
                -- Up or down
                if history then
                    if param == keys.up then
                        -- Up
                        if nHistoryPos == nil then
                            if #history > 0 then
                                nHistoryPos = #history
                            end
                        elseif nHistoryPos > 1 then
                            nHistoryPos = nHistoryPos - 1
                        end
                    else
                        -- Down
                        if nHistoryPos == #history then
                            nHistoryPos = nil
                        elseif nHistoryPos ~= nil then
                            nHistoryPos = nHistoryPos + 1
                        end
                    end

                    if nHistoryPos then
                        line = history[nHistoryPos]
                        nPos = #line
                    else
                        line = ""
                        nPos = 0
                    end
                    redraw()
                end
            elseif param == keys.backspace then
                -- Backspace
                if nPos > 0 then
                    line = line:sub(1, nPos - 1) .. line:sub(nPos + 1)
                    nPos = nPos - 1
                    redraw()
                end
            elseif param == keys.home then
                -- Home
                nPos = 0
                redraw()
            elseif param == keys.delete then
                if nPos < #line then
                    line = line:sub(1, nPos) .. line:sub(nPos + 2)
                    redraw()
                end
            elseif param == keys["end"] then
                -- End
                nPos = #line
                redraw()
            elseif param == keys.tab then
                --tab autocomplete.
                if #line > 0 then
                    local startsWithCurrentInput, results = false, {}
                    for _, v in pairs(sortedHelpKeys) do
                        if v ~= "blockpatterns" then
                            local lineLen = #line
                            if lineLen < #v and not line:find(" ", nil, true) and line == v:sub(1, #line) then
                                startsWithCurrentInput = true
                                results[#results + 1] = v
                            elseif v > line then
                                break
                            end
                        end
                    end
                    if #results == 1 then
                        line = results[1]
                        nPos = #line
                        redraw()
                    elseif #results > 1 then
                        print ""
                        print(unpack(results))
                        io.write "> "
                        line = ""
                        nPos = 0
                        sy = sy + 2
                    end
                end
            end
        end
    end

    term.setCursorBlink(false)
    term.setCursorPos(w + 1, sy)
    io.write "\n> "
    return line
end

--End of lsh


local function getConsoleInput()
    --- Gets commands from typing on the computer itself.
    while true do
        local str = customRead(runHistory)
        local username = getPlayerName()
        os.queueEvent("chatFromConsole", username, str) --As long as the event starts with "chat", it works!
    end
end

local function getRednetInput()
    --- Gets commands from rednet messages sent by trusted IDs.
    peripheral.find("modem", rednet.open) --Open all rednet modems
    local event = { os.pullEvent "rednet_message" } --Listen for the initial message
    while true do
        if event[4]:sub(1, 8) == "WE_Input" then
            --Listen for the protocol
            if tablex.find(trustedIDs, event[2]) == nil then
                --If the ID is not trusted
                WE.sendChat(("Computer with ID %s is trying to connect for remote input. Allow? (Y/N)"):format(event[2])) --Prompt the user to trust it
                username, message = getCommand() --Get the user's response
                if message:lower() == "t" or message:lower() == "true" or message:lower() == "y" or message:lower() == "yes" then
                    table.insert(trustedIDs, event[2]) --Trust the IDs
                    writeIDs() --Update the IDs file
                    WE.sendChat(("Allowing pocket computer with ID %s to control this computer remotely."):format(event[2]))
                else
                    WE.sendChat(("Not allowing computer with ID %s."):format(event[2]))
                end
            end
        end
        if tablex.find(trustedIDs, event[2]) ~= nil then
            --If it's already trusted, run the command.
            os.queueEvent("chatFromRednet", event[4]:sub(9), event[3])
        end
        event = { os.pullEvent "rednet_message" } --Listen for the next message.
    end
end

local args = { ... }

local function parseCmdArgs()
    --- Parse any arguments passed through the command line
    if #args == 0 then
        return
    end
    local cmd = "_ " --We only have access to the stuff after the command, so "_" is put in as a dummy command.
    for i = 1, #args do
        cmd = cmd .. args[i] .. " " --Generate the original command from the command line arguments
    end
    cmd = cmd:sub(1, -1)
    local cmdArgs = { parseCommandArgs(cmd, true, false) } --Parse the args like a normal command
    WE.normalArgs, WE.namedArgs, WE.shortSwitches, WE.longSwitches = cmdArgs[2], cmdArgs[3], cmdArgs[4], cmdArgs[5]
    debug = WE.shortSwitches.d or WE.shortSwitches.debug
    for k, v in pairs(WE.namedArgs) do
        if k == "cf" or k == "cfgfolder" then
            --Change the folder in which the config is stored.
            if #v > 0 then
                WE.ConfigFolder = v
            else
                WE.sendChat(("Commandline argument: \"%s\" has no value."):format(k))
            end
        elseif k == "cap" or k == "cfgapipath" then
            --Change the path to ConfigAPI
            if #v > 0 then
                ConfigAPIPath = v
            else
                WE.sendChat(("Commandline argument: \"%s\" has no value."):format(k))
            end
        end
    end
    for k, v in pairs(WE.shortSwitches) do
        if k == "cp" or k == "cfgpath" then
            --Change the name of the config
            if #v > 0 then
                ConfigPath = v
            else
                WE.sendChat(("Commandline argument: \"%s\" has no value."):format(k))
            end
        end
    end
    return WE.normalArgs, WE.namedArgs, WE.shortSwitches, WE.longSwitches
end

local function parseConfig()
    WE.ConfigFolder = type(WE.ConfigFolder) == "string" and WE.ConfigFolder or "WE/"
    ConfigPath = ConfigPath or WE.ConfigFolder .. "Config"
    ConfigAPIPath = ConfigAPIPath or "NewConfigAPI"
    fs.makeDir(WE.ConfigFolder)
    WE.cfg = loadPlugin(WE.ConfigFolder .. ConfigAPIPath)
    WE.cfg.read(ConfigPath, [[
[FileLocations]
; Where in the WorldEdit folder the plugins are located.
PluginPath=Plugins
; Where in the WorldEdit folder the Clipboard will be stored.
ClipboardPath=Clipboard
; Where in the WorldEdit folder the previous selection will be stored.
SelectionPath=Selection
; Where in the WorldEdit folder the trusted rednet IDs will be stored.
IDPath=trustedIDs
[SillyOptions]
; Whether the blocks should be set in order, or randomly.
RandomSetOrder=false
    ]])
    if not WE.cfg.hasValue("FileLocations", "PluginPath") then
        WE.sendChat "PluginPath does not exist! Generating config option..."
        WE.cfg.add("FileLocations", "PluginPath", "Plugins")
        WE.cfg.addComment("FileLocations", "PluginPath", "Where in the WorldEdit folder the plugins are located.")
    end
    if not WE.cfg.hasValue("FileLocations", "ClipboardPath") then
        WE.sendChat "ClipboardPath does not exist! Generating config option..."
        WE.cfg.add("FileLocations", "ClipboardPath", "Clipboard")
        WE.cfg.addComment("FileLocations", "ClipboardPath", "Where in the WorldEdit folder the Clipboard will be stored.")
    end
    if not WE.cfg.hasValue("FileLocations", "SelectionPath") then
        WE.sendChat "SelectionPath does not exist! Generating config option..."
        WE.cfg.add("FileLocations", "SelectionPath", "Selection")
        WE.cfg.addComment("FileLocations", "SelectionPath", "Where in the WorldEdit folder the previous selection will be stored.")
    end
    if not WE.cfg.hasValue("FileLocations", "IDPath") then
        WE.sendChat "IDPath does not exist! Generating config option..."
        WE.cfg.add("FileLocations", "IDPath", "trustedIDs")
        WE.cfg.addComment("FileLocations", "IDPath", "Where in the WorldEdit folder the trusted rednet IDs will be stored.")
    end
    if not WE.cfg.hasValue("SillyOptions", "RandomSetOrder") then
        WE.sendChat "RandomSetOrder does not exist! Generating config option..."
        WE.cfg.add("SillyOptions", "RandomSetOrder", false)
        WE.cfg.addComment("SillyOptions", "RandomSetOrder", "Whether the blocks should be set in order, or randomly.")
    end
    WE.cfg.write(ConfigPath)
    --Set the paths based on the config
    WE.ClipboardPath = WE.cfg.get("FileLocations", "ClipboardPath")
    PluginPath = WE.cfg.get("FileLocations", "PluginPath")
    SelectionPath = WE.cfg.get("FileLocations", "SelectionPath")
    IDPath = WE.cfg.get("FileLocations", "IDPath")
    WE.RandomSetOrder = WE.cfg.get("SillyOptions", "RandomSetOrder")
    fs.makeDir(WE.ConfigFolder .. PluginPath)
end

local function init()
    WE.isCommandComputer = type(commands) == "table"
    endProgram = false
    p = peripheral.find "adventure map interface" --Wrap the adventure map interface if it exists.
    w = p and p.getWorld(p.getPeripheralWorldID()) --Set up the adventure map interface
    --Names of the blocks, and conversion to and from ID and MC name
    BlockNames = {
        { "stone", "rock" }, { "grass" }, { "dirt" }, { "cobblestone", "cobble" }, { "wood", "woodplank", "plank", "woodplanks", "planks" }, { "sapling", "seedling" }, { "adminium", "bedrock" }, { "water_(stationary)", "water", "waterstationary", "stationarywater", "stillwater" }, { "watermoving", "movingwater", "flowingwater", "waterflowing" }, { "lavamoving", "movinglava", "flowinglava", "lavaflowing" }, { "lava_(stationary)", "lava", "lavastationary", "stationarylava", "stilllava" }, { "sand", "redsand", "red_sand" }, { "gravel" }, { "gold_ore", "goldore" }, { "iron_ore", "ironore" }, { "coal_ore", "coalore" }, { "log", "tree", "pine", "oak", "birch", "jungle" }, { "leaves", "leaf" }, { "sponge" }, { "glass" }, { "lapis_lazuli_ore", "lapislazuliore", "blueore", "lapisore" }, { "lapis_lazuli", "lapislazuli", "lapislazuliblock", "bluerock", "lapisblock" }, { "dispenser" }, { "sandstone" }, { "note_block", "musicblock", "noteblock", "note", "music", "instrument" }, { "bed" }, { "poweredrail", "boosterrail", "poweredtrack", "boostertrack", "booster" }, { "detector_rail", "detectorrail", "detector" }, { "sticky_piston", "stickypiston" }, { "web", "spiderweb" }, { "tall_grass", "long_grass", "longgrass", "tallgrass" }, { "deadbush", "shrub", "deadshrub", "tumbleweed" }, { "piston" }, { "piston_extension", "pistonextendsion", "pistonhead" }, { "cloth", "wool" }, { "piston_moving_piece", "movingpiston" }, { "yellow_flower", "yellowflower", "flower" }, { "red_rose", "redflower", "redrose", "rose" }, { "brown_mushroom", "brownmushroom", "mushroom" }, { "red_mushroom", "redmushroom" }, { "gold_block", "gold", "goldblock" }, { "iron_block", "iron", "ironblock" }, { "double_step", "doubleslab", "doublestoneslab", "doublestep" }, { "slab", "stoneslab", "step", "halfstep" }, { "brick", "brickblock" }, { "tnt", "c4", "explosive" }, { "bookshelf", "bookshelves", "bookcase", "bookcases" }, { "cobblestone_(mossy)", "mossycobblestone", "mossstone" }, { "obsidian" }, { "torch", "light", "candle" }, { "fire", "flame", "flames" }, { "mob_spawner", "mobspawner", "spawner" }, { "wooden_stairs", "woodstair", "woodstairs", "woodenstair", "woodenstairs" }, { "chest", "storage", "storagechest" }, { "redstone_wire", "redstone", "redstoneblock" }, { "diamond_ore", "diamondore" }, { "diamond_block", "diamond", "diamondblock" }, { "workbench", "table", "craftingtable", "crafting" }, { "crops", "crop", "plant", "plants" }, { "soil", "farmland" }, { "furnace" }, { "furnace_(burning)", "burningfurnace", "litfurnace" }, { "sign_post", "sign", "signpost" }, { "wooden_door", "wooddoor", "woodendoor", "door" }, { "ladder" }, { "minecart_tracks", "track", "tracks", "minecrattrack", "minecarttracks", "rails", "rail" }, { "cobblestone_stairs", "cobblestonestair", "cobblestonestairs", "cobblestair", "cobblestairs" },
        { "wall_sign", "wallsign" }, { "lever", "switch", "stonelever", "stoneswitch" }, { "stone_pressure_plate", "stonepressureplate", "stoneplate" }, { "iron_door", "irondoor" }, { "wooden_pressure_plate", "woodpressureplate", "woodplate", "woodenpressureplate", "woodenplate", "plate", "pressureplate" }, { "redstone_ore", "redstoneore" }, { "glowing_redstone_ore", "glowingredstoneore" }, { "redstone_torch_(off)", "redstonetorchoff", "rstorchoff" }, { "redstone_torch_(on)", "redstonetorch", "redstonetorchon", "rstorchon", "redtorch" }, { "stone_button", "stonebutton", "button" }, { "snow", "snow_layer" }, { "ice" }, { "snow_block", "snowblock" }, { "cactus", "cacti" }, { "clay" }, { "reed", "cane", "sugarcane", "sugarcanes" }, { "jukebox", "stereo", "recordplayer" }, { "fence", "fence" }, { "pumpkin" }, { "redmossycobblestone", "redcobblestone", "redmosstone", "redcobble", "netherstone", "netherrack", "nether", "hellstone" }, { "soul_sand", "slowmud", "mud", "soulsand", "hellmud" }, { "glowstone", "brittlegold", "lightstone", "brimstone", "australium" }, { "portal", "portal" }, { "pumpkin_(on)", "pumpkinlighted", "pumpkinon", "litpumpkin", "jackolantern" }, { "cake", "cakeblock" }, { "redstone_repeater_(off)", "diodeoff", "redstonerepeater", "repeateroff", "delayeroff" }, { "redstone_repeater_(on)", "diodeon", "redstonerepeateron", "repeateron", "delayeron" }, { "stained_glass", "stainedglass" }, { "trap_door", "trapdoor", "hatch", "floordoor" }, { "silverfish_block", "silverfish", "silver" }, { "stone_brick", "stonebrick", "sbrick", "smoothstonebrick" }, { "red_mushroom_cap", "giantmushroomred", "redgiantmushroom", "redmushroomcap" }, { "brown_mushroom_cap", "giantmushroombrown", "browngiantmushoom", "brownmushroomcap" }, { "iron_bars", "ironbars", "ironfence" }, { "glass_pane", "window", "glasspane", "glasswindow" }, { "melon_(block)", "melonblock" }, { "pumpkin_stem", "pumpkinstem" }, { "melon_stem", "melonstem" }, { "vine", "vines", "creepers" }, { "fence_gate", "fencegate", "gate" }, { "brick_stairs", "brickstairs", "bricksteps" }, { "stone_brick_stairs", "stonebrickstairs", "smoothstonebrickstairs" }, { "mycelium", "fungus", "mycel" }, { "lily_pad", "lilypad", "waterlily" }, { "nether_brick", "netherbrick" }, { "nether_brick_fence", "netherbrickfence", "netherfence" }, { "nether_brick_stairs", "netherbrickstairs", "netherbricksteps", "netherstairs", "nethersteps" }, { "nether_wart", "netherwart", "netherstalk" }, { "enchantment_table", "enchantmenttable", "enchanttable" }, { "brewing_stand", "brewingstand" }, { "cauldron" }, { "end_portal", "endportal", "blackstuff", "airportal", "weirdblackstuff" }, { "end_portal_frame", "endportalframe", "airportalframe", "crystalblock" }, { "end_stone", "endstone", "enderstone", "endersand" }, { "dragon_egg", "dragonegg", "dragons" },
        { "redstone_lamp_(off)", "redstonelamp", "redstonelampoff", "rslamp", "rslampoff", "rsglow", "rsglowoff" }, { "redstone_lamp_(on)", "redstonelampon", "rslampon", "rsglowon" }, { "double_wood_step", "doublewoodslab", "doublewoodstep" }, { "wood_step", "woodenslab", "woodslab", "woodstep", "woodhalfstep" }, { "cocoa_plant", "cocoplant", "cocoaplant" }, { "sandstone_stairs", "sandstairs", "sandstonestairs" }, { "emerald_ore", "emeraldore" }, { "ender_chest", "enderchest" }, { "tripwire_hook", "tripwirehook" }, { "tripwire", "string" }, { "emerald_block", "emeraldblock", "emerald" }, { "spruce_wood_stairs", "sprucestairs", "sprucewoodstairs" }, { "birch_wood_stairs", "birchstairs", "birchwoodstairs" }, { "jungle_wood_stairs", "junglestairs", "junglewoodstairs" }, { "command_block", "commandblock", "cmdblock", "command", "cmd" }, { "beacon", "beaconblock" }, { "cobblestone_wall", "cobblestonewall", "cobblewall" }, { "flower_pot", "flowerpot", "plantpot", "pot" }, { "carrots", "carrotsplant", "carrotsblock" }, { "potatoes", "potatoesblock" }, { "wooden_button", "woodbutton", "woodenbutton" }, { "head", "skull" }, { "anvil", "blacksmith" }, { "trapped_chest", "trappedchest", "redstonechest" }, { "weighted_pressure_plate_(light)", "lightpressureplate" }, { "weighted_pressure_plate_(heavy)", "heavypressureplate" }, { "redstone_comparator_(inactive)", "redstonecomparator", "comparator" }, { "redstone_comparator_(active)", "redstonecomparatoron", "comparatoron" }, { "daylight_sensor", "daylightsensor", "lightsensor", "daylightdetector" }, { "block_of_redstone", "redstoneblock", "blockofredstone" }, { "nether_quartz_ore", "quartzore", "netherquartzore" }, { "hopper" }, { "block_of_quartz", "quartzblock", "quartz" }, { "quartz_stairs", "quartzstairs" }, { "activator_rail", "activatorrail", "tntrail", "activatortrack" }, { "dropper" }, { "stained_clay", "stainedclay", "stainedhardenedclay" }, { "stained_glass_pane", "stainedglasspane" }, { "leaves2", "acacialeaves", "darkoakleaves" }, { "log2", "acacia", "darkoak" }, { "acacia_wood_stairs", "acaciawoodstairs", "acaciastairs" }, { "dark_oak_wood_stairs", "darkoakwoodstairs", "darkoakstairs" },
        [165] = { "slimeblock", "slime_block" },
        [170] = { "hay_block", "hayblock", "haybale", "wheatbale" },
        [171] = { "carpet", "carpet" },
        [172] = { "hardened_clay", "hardenedclay", "hardclay" },
        [173] = { "block_of_coal", "coalblock", "blockofcoal" },
        [174] = { "packed_ice", "packedice", "hardice" },
        [175] = { "large_flowers", "largeflowers", "doubleflowers" },
        [176] = { "large_flowers", "largeflowers", "doubleflowers" },
        [0] = { "air" }
    }
    MCNames = {
        [0] = "minecraft:air", "minecraft:stone", "minecraft:grass", "minecraft:dirt", "minecraft:cobblestone", "minecraft:planks", "minecraft:sapling", "minecraft:bedrock", "minecraft:flowing_water", "minecraft:water", "minecraft:flowing_lava", "minecraft:lava", "minecraft:sand", "minecraft:gravel", "minecraft:gold_ore", "minecraft:iron_ore", "minecraft:coal_ore", "minecraft:log", "minecraft:leaves", "minecraft:sponge", "minecraft:glass", "minecraft:lapis_ore", "minecraft:lapis_block", "minecraft:dispenser", "minecraft:sandstone", "minecraft:noteblock", "minecraft:bed", "minecraft:golden_rail", "minecraft:detector_rail", "minecraft:sticky_piston", "minecraft:web", "minecraft:tallgrass", "minecraft:deadbush", "minecraft:piston", "minecraft:piston_head", "minecraft:wool",
        [37] = "minecraft:yellow_flower",
        [38] = "minecraft:red_flower",
        [39] = "minecraft:brown_mushroom",
        [40] = "minecraft:red_mushroom",
        [41] = "minecraft:gold_block",
        [42] = "minecraft:iron_block",
        [43] = "minecraft:double_stone_slab",
        [44] = "minecraft:stone_slab",
        [45] = "minecraft:brick_block",
        [46] = "minecraft:tnt",
        [47] = "minecraft:bookshelf",
        [48] = "minecraft:mossy_cobblestone",
        [49] = "minecraft:obsidian",
        [50] = "minecraft:torch",
        [51] = "minecraft:fire",
        [52] = "minecraft:mob_spawner",
        [53] = "minecraft:oak_stairs",
        [54] = "minecraft:chest",
        [55] = "minecraft:redstone_wire",
        [56] = "minecraft:diamond_ore",
        [57] = "minecraft:diamond_block",
        [58] = "minecraft:crafting_table",
        [59] = "minecraft:wheat",
        [60] = "minecraft:farmland",
        [61] = "minecraft:furnace",
        [62] = "minecraft:lit_furnace",
        [63] = "minecraft:standing_sign",
        [64] = "minecraft:wooden_door",
        [65] = "minecraft:ladder",
        [66] = "minecraft:rail",
        [67] = "minecraft:stone_stairs",
        [68] = "minecraft:wall_sign",
        [69] = "minecraft:lever",
        [70] = "minecraft:stone_pressure_plate",
        [71] = "minecraft:iron_door",
        [72] = "minecraft:wooden_pressure_plate",
        [73] = "minecraft:redstone_ore",
        [74] = "minecraft:lit_redstone_ore",
        [75] = "minecraft:unlit_redstone_torch",
        [76] = "minecraft:redstone_torch",
        [77] = "minecraft:stone_button",
        [78] = "minecraft:snow_layer",
        [79] = "minecraft:ice",
        [80] = "minecraft:snow",
        [81] = "minecraft:cactus",
        [82] = "minecraft:clay",
        [83] = "minecraft:reeds",
        [84] = "minecraft:jukebox",
        [85] = "minecraft:fence",
        [86] = "minecraft:pumpkin",
        [87] = "minecraft:netherrack",
        [88] = "minecraft:soul_sand",
        [89] = "minecraft:glowstone",
        [90] = "minecraft:portal",
        [91] = "minecraft:lit_pumpkin",
        [92] = "minecraft:cake",
        [93] = "minecraft:unpowered_repeater",
        [94] = "minecraft:powered_repeater",
        [95] = "minecraft:stained_glass",
        [96] = "minecraft:trapdoor",
        [97] = "minecraft:monster_egg",
        [98] = "minecraft:stonebrick",
        [99] = "minecraft:stonebrick",
        [100] = "minecraft:stonebrick",
        [101] = "minecraft:iron_bars",
        [102] = "minecraft:glass_pane",
        [103] = "minecraft:melon_block",
        [104] = "minecraft:pumpkin_stem",
        [105] = "minecraft:melon_stem",
        [106] = "minecraft:vine",
        [107] = "minecraft:fence_gate",
        [108] = "minecraft:brick_stairs",
        [109] = "minecraft:stone_brick_stairs",
        [110] = "minecraft:mycelium",
        [111] = "minecraft:waterlily",
        [112] = "minecraft:nether_brick",
        [113] = "minecraft:nether_brick_fence",
        [114] = "minecraft:nether_brick_stairs",
        [115] = "minecraft:nether_wart",
        [116] = "minecraft:enchanting_table",
        [117] = "minecraft:brewing_stand",
        [118] = "minecraft:cauldron",
        [119] = "minecraft:end_portal",
        [120] = "minecraft:end_portal_frame",
        [121] = "minecraft:end_stone",
        [122] = "minecraft:dragon_egg",
        [123] = "minecraft:redstone_lamp",
        [124] = "minecraft:lit_redstone_lamp",
        [125] = "minecraft:double_wooden_slab",
        [126] = "minecraft:wooden_slab",
        [127] = "minecraft:cocoa",
        [128] = "minecraft:sandstone_stairs",
        [129] = "minecraft:emerald_ore",
        [130] = "minecraft:ender_chest",
        [131] = "minecraft:tripwire_hook",
        [132] = "minecraft:tripwire_hook",
        [133] = "minecraft:emerald_block",
        [134] = "minecraft:spruce_stairs",
        [135] = "minecraft:birch_stairs",
        [136] = "minecraft:jungle_stairs",
        [137] = "minecraft:command_block",
        [138] = "minecraft:beacon",
        [139] = "minecraft:cobblestone_wall",
        [140] = "minecraft:flower_pot",
        [141] = "minecraft:carrots",
        [142] = "minecraft:potatoes",
        [143] = "minecraft:wooden_button",
        [144] = "minecraft:skull",
        [145] = "minecraft:anvil",
        [146] = "minecraft:trapped_chest",
        [147] = "minecraft:light_weighted_pressure_plate",
        [148] = "minecraft:heavy_weighted_pressure_plate",
        [149] = "minecraft:unpowered_comparator",
        [150] = "minecraft:powered_comparator",
        [151] = "minecraft:daylight_detector",
        [152] = "minecraft:redstone_block",
        [153] = "minecraft:quartz_ore",
        [154] = "minecraft:hopper",
        [155] = "minecraft:quartz_block",
        [156] = "minecraft:quartz_stairs",
        [157] = "minecraft:activator_rail",
        [158] = "minecraft:dropper",
        [159] = "minecraft:stained_hardened_clay",
        [160] = "minecraft:stained_glass_pane",
        [161] = "minecraft:leaves2",
        [162] = "minecraft:logs2",
        [163] = "minecraft:acacia_stairs",
        [164] = "minecraft:dark_oak_stairs",
        [170] = "minecraft:hay_block",
        [171] = "minecraft:carpet",
        [172] = "minecraft:hardened_clay",
        [173] = "minecraft:coal_block",
        [174] = "minecraft:packed_ice",
        [175] = "minecraft:double_plant"
    }
    IDs = {
        ["minecraft:bed"] = 26,
        ["minecraft:unlit_redstone_torch"] = 75,
        ["minecraft:mob_spawner"] = 52,
        ["minecraft:stone_brick_stairs"] = 109,
        ["minecraft:end_portal"] = 119,
        ["minecraft:web"] = 30,
        ["minecraft:oak_stairs"] = 53,
        ["minecraft:nether_brick"] = 112,
        ["minecraft:noteblock"] = 25,
        ["minecraft:dropper"] = 158,
        ["minecraft:ladder"] = 65,
        ["minecraft:detector_rail"] = 28,
        ["minecraft:lapis_block"] = 22,
        ["minecraft:emerald_ore"] = 129,
        ["minecraft:water"] = 9,
        ["minecraft:stained_hardened_clay"] = 159,
        ["minecraft:beacon"] = 138,
        ["minecraft:soul_sand"] = 88,
        ["minecraft:wooden_door"] = 64,
        ["minecraft:pumpkin"] = 86,
        ["minecraft:wheat"] = 59,
        ["minecraft:iron_bars"] = 101,
        ["minecraft:redstone_ore"] = 73,
        ["minecraft:jukebox"] = 84,
        ["minecraft:dragon_egg"] = 122,
        ["minecraft:spruce_stairs"] = 134,
        ["minecraft:hopper"] = 154,
        ["minecraft:stone_slab"] = 44,
        ["minecraft:skull"] = 144,
        ["minecraft:carpet"] = 171,
        ["minecraft:mycelium"] = 110,
        ["minecraft:sand"] = 12,
        ["minecraft:coal_ore"] = 16,
        ["minecraft:stained_glass"] = 95,
        ["minecraft:snow"] = 80,
        ["minecraft:fire"] = 51,
        ["minecraft:enchanting_table"] = 116,
        ["minecraft:lava"] = 11,
        ["minecraft:potatoes"] = 142,
        ["minecraft:unpowered_repeater"] = 93,
        ["minecraft:stone_stairs"] = 67,
        ["minecraft:cauldron"] = 118,
        ["minecraft:stone_pressure_plate"] = 70,
        ["minecraft:deadbush"] = 32,
        ["minecraft:torch"] = 50,
        ["minecraft:hay_block"] = 170,
        ["minecraft:sandstone_stairs"] = 128,
        ["minecraft:netherrack"] = 87,
        ["minecraft:sandstone"] = 24,
        ["minecraft:gold_ore"] = 14,
        ["minecraft:bookshelf"] = 47,
        ["minecraft:cake"] = 92,
        ["minecraft:logs2"] = 162,
        ["minecraft:melon_stem"] = 105,
        ["minecraft:piston_head"] = 34,
        ["minecraft:brick_block"] = 45,
        ["minecraft:acacia_stairs"] = 163,
        ["minecraft:brown_mushroom"] = 39,
        ["minecraft:lit_furnace"] = 62,
        ["minecraft:glass"] = 20,
        ["minecraft:stone_button"] = 77,
        ["minecraft:air"] = 0,
        ["minecraft:packed_ice"] = 174,
        ["minecraft:sapling"] = 6,
        ["minecraft:pumpkin_stem"] = 104,
        ["minecraft:leaves"] = 18,
        ["minecraft:fence"] = 85,
        ["minecraft:obsidian"] = 49,
        ["minecraft:snow_layer"] = 78,
        ["minecraft:wool"] = 35,
        ["minecraft:powered_comparator"] = 150,
        ["minecraft:jungle_stairs"] = 136,
        ["minecraft:iron_block"] = 42,
        ["minecraft:chest"] = 54,
        ["minecraft:diamond_ore"] = 56,
        ["minecraft:glowstone"] = 89,
        ["minecraft:dispenser"] = 23,
        ["minecraft:nether_brick_fence"] = 113,
        ["minecraft:sticky_piston"] = 29,
        ["minecraft:end_portal_frame"] = 120,
        ["minecraft:nether_brick_stairs"] = 114,
        ["minecraft:tnt"] = 46,
        ["minecraft:redstone_wire"] = 55,
        ["minecraft:command_block"] = 137,
        ["minecraft:golden_rail"] = 27,
        ["minecraft:flowing_water"] = 8,
        ["minecraft:coal_block"] = 173,
        ["minecraft:double_wooden_slab"] = 125,
        ["minecraft:dark_oak_stairs"] = 164,
        ["minecraft:double_plant"] = 175,
        ["minecraft:mossy_cobblestone"] = 48,
        ["minecraft:gravel"] = 13,
        ["minecraft:reeds"] = 83,
        ["minecraft:trapdoor"] = 96,
        ["minecraft:planks"] = 5,
        ["minecraft:stained_glass_pane"] = 160,
        ["minecraft:activator_rail"] = 157,
        ["minecraft:quartz_stairs"] = 156,
        ["minecraft:nether_wart"] = 115,
        ["minecraft:flowing_lava"] = 10,
        ["minecraft:waterlily"] = 111,
        ["minecraft:quartz_block"] = 155,
        ["minecraft:light_weighted_pressure_plate"] = 147,
        ["minecraft:brick_stairs"] = 108,
        ["minecraft:wooden_button"] = 143,
        ["minecraft:quartz_ore"] = 153,
        ["minecraft:standing_sign"] = 63,
        ["minecraft:unpowered_comparator"] = 149,
        ["minecraft:daylight_detector"] = 151,
        ["minecraft:redstone_block"] = 152,
        ["minecraft:heavy_weighted_pressure_plate"] = 148,
        ["minecraft:vine"] = 106,
        ["minecraft:lit_redstone_lamp"] = 124,
        ["minecraft:anvil"] = 145,
        ["minecraft:carrots"] = 141,
        ["minecraft:flower_pot"] = 140,
        ["minecraft:cobblestone_wall"] = 139,
        ["minecraft:birch_stairs"] = 135,
        ["minecraft:emerald_block"] = 133,
        ["minecraft:tripwire_hook"] = 132,
        ["minecraft:farmland"] = 60,
        ["minecraft:furnace"] = 61,
        ["minecraft:cocoa"] = 127,
        ["minecraft:stone"] = 1,
        ["minecraft:wooden_slab"] = 126,
        ["minecraft:trapped_chest"] = 146,
        ["minecraft:redstone_lamp"] = 123,
        ["minecraft:double_stone_slab"] = 43,
        ["minecraft:tallgrass"] = 31,
        ["minecraft:monster_egg"] = 97,
        ["minecraft:sponge"] = 19,
        ["minecraft:end_stone"] = 121,
        ["minecraft:iron_ore"] = 15,
        ["minecraft:gold_block"] = 41,
        ["minecraft:red_flower"] = 38,
        ["minecraft:piston"] = 33,
        ["minecraft:powered_repeater"] = 94,
        ["minecraft:brewing_stand"] = 117,
        ["minecraft:wall_sign"] = 68,
        ["minecraft:clay"] = 82,
        ["minecraft:wooden_pressure_plate"] = 72,
        ["minecraft:lapis_ore"] = 21,
        ["minecraft:ender_chest"] = 130,
        ["minecraft:crafting_table"] = 58,
        ["minecraft:lever"] = 69,
        ["minecraft:grass"] = 2,
        ["minecraft:cactus"] = 81,
        ["minecraft:dirt"] = 3,
        ["minecraft:ice"] = 79,
        ["minecraft:bedrock"] = 7,
        ["minecraft:hardened_clay"] = 172,
        ["minecraft:stonebrick"] = 100,
        ["minecraft:yellow_flower"] = 37,
        ["minecraft:fence_gate"] = 107,
        ["minecraft:melon_block"] = 103,
        ["minecraft:red_mushroom"] = 40,
        ["minecraft:lit_redstone_ore"] = 74,
        ["minecraft:redstone_torch"] = 76,
        ["minecraft:iron_door"] = 71,
        ["minecraft:leaves2"] = 161,
        ["minecraft:diamond_block"] = 57,
        ["minecraft:lit_pumpkin"] = 91,
        ["minecraft:cobblestone"] = 4,
        ["minecraft:portal"] = 90,
        ["minecraft:rail"] = 66,
        ["minecraft:glass_pane"] = 102,
        ["minecraft:log"] = 17
    }
    WE.pipeBlocks = {
        ["minecraft:standing_sign"] = function(pipeTbl)
            return { Text1 = pipeTbl[1], Text2 = pipeTbl[2], Text3 = pipeTbl[3], Text4 = pipeTbl[4] }
        end,
        ["minecraft:wall_sign"] = function(pipeTbl)
            return WE.pipeBlocks["minecraft:standing_sign"](pipeTbl)
        end,
        ["minecraft:mob_spawner"] = function(pipeTbl)
            return {
                EntityId = pipeTbl[1],
                MaxNearbyEntities = 6,
                RequiredPlayerRange = 16,
                SpawnCount = 4,
                id = "MobSpawner",
                MaxSpawnDelay = 800,
                SpawnRange = 4,
                Delay = 0,
                MinSpawnDelay = 200
            }
        end
    }
    parseCmdArgs() --Check any arguments passed through the command line
    parseConfig() --Read the config file and get the values from it
    WE.blockBlacklist = { 0, "minecraft:air" } --Blocks that should be ignored in hpos.
    WE.Direction = "" --The direction the player is looking in.
    WE.Selection = { type = "cuboid" } --Default selection type
    WE.pos = {}
    loadPlugins()
    resetPos() --Set up the pos table (using a metatable so it can store the positions and be called as a function!)
    readSelection() --Read the previous selection from file, if it doesn't exist.
    trustedIDs = readIDs() --Check which IDs are trusted for rednet input from file
    registerCommands() --Register all of the commands that are allowed to run.
    WE.sendChat "WorldEdit started."
    print "WorldEdit started."
    WE.sendChat "Just say your command (if you have a chat box), or type your desired command at the computer, or send it over rednet.\nRun help if you want a list of commands or information about a specific command."
    io.write "> "
    currentCmds = {}
end

--Main program loop
local function main()
    if endProgram then
        return
    end
    while true do
        WE.isCommandComputer = type(commands) == "table"
        if endProgram then
            --Only used in exit/terminate.
            term.clear()
            term.setCursorPos(1, 1)
            return
        end
        username, message = getCommand() --Get the command from "chat"
        username = username or getPlayerName() --If the username is nil, get the closest player
        pl = p and p.getPlayerByName(username) --Get the player object if using the Adventure Map Interface
        ent = pl and pl.asEntity() --Get the player object as an entity if using the Adventure Map Interface
        OriginalMessage = message
        message = message:lower() --Make it case-insensitive, but keep the original just in case it's needed.
        parallel.waitForAny(main, WE.runCommands) --Run main again, so that commands can be entered while it waits for the current one to finish.
    end
end

init() --Initialize the program, setting up a few globals, reading files and configs, etc.
parallel.waitForAny(main, getConsoleInput, getRednetInput, taskCounter, serpentProgress)

--- To bootstrap other programs to WE:
--- -Remove getConsoleInput and getRednetInput from the parallel.waitForAny() call above. This will make WE not get console or rednet input.
--- -To make a command run as if it was entered into the console, queue an event starting with "chat" as such:
--- "os.queueEvent("chatFromSomeOtherProgram",username,message)"
--- -Note: If username is nil, WE will automatically get the name of the nearest player.

---Program(s) made by moomoomoo3O9 and exlted, with contributions from Wergat and Lyqyd--
