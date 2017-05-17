function argError(...)
    --- Returns error text if any of the arguments are nil. Pass it your command's arguments.
    for k, v in pairs({ ... }) do
        if v == nil then
            return "Argument " .. k .. " is nil."
        end
    end
end

function all(...)
    --- Returns if all of the given values are truthy.
    return select("#", ...) == 1 and ((...) and true or false) or ((...) and all(select(2, ...)))
end

function any(...)
    --- Returns if any of the given values are truthy.
    return ((...) and true or false) or any(select(2, ...))
end

function mapIterative(fct, numArgs, ...)
    --- Allows functions to take unlimited arguments.
    assert(type(fct) == "function" and type(numArgs) == "number")
    if numArgs == 0 then
        fct()
        return
    end
    local args, returns = { ... }, {}
    for i = 1, #args, numArgs do
        local localArgs, len = {}, localArgs and #localArgs or 0 --Cut down on length lookups
        for i2 = 1, numArgs do
            localArgs[len + 1] = args[i + i2 - 1]
            len = len + 1
        end
        local len = #returns --Cut down on length lookups more
        local fctResults = { fct(unpack(localArgs)) }
        for i = 1, #fctResults do
            returns[len + 1] = fctResults[i]
            len = len + 1
        end
    end
    return unpack(returns)
end

function mapRecursive(fct, numArgs, ...)
    --- Allows functions to take unlimited arguments.
    assert(type(fct) == "function" and type(numArgs) == "number")
    local results = {}
    local function innerWrap(fct, numArgs, results, args)
        local tbl, argsLen, tblLen = {}, #args, 0 --Do only one length lookup per table
        for i = argsLen, argsLen - numArgs + 1, -1 do
            tblLen = tblLen + 1
            tbl[tblLen] = args[i]
            args[argsLen] = nil --Remove the last argument, so to avoid a table.remove() call (which is O(n-i), where this is O(1))
            argsLen = argsLen - 1
        end
        for i = 1, tblLen / 2 do
            tbl[i], tbl[tblLen - i + 1] = tbl[tblLen - i + 1], tbl[i]
        end
        if argsLen < 0 and tblLen < numArgs then
            return results
        end
        results[#results + 1] = fct(unpack(tbl))
        return #args >= numArgs and innerWrap(fct, numArgs, results, args) or results
    end

    local tbl = innerWrap(fct, numArgs, results, { ... })
    local tblLen = #tbl
    for i = 1, tblLen / 2 do
        --Reverse the table, since inserting it backwards is n(n-i) iterations, but reversing it is n/2.
        tbl[i], tbl[tblLen - i + 1] = tbl[tblLen - i + 1], tbl[i] --Swap the first half of the elements with the last half
    end
    return unpack(tbl)
end
map = mapRecursive --mapRecursive is faster, unsurprisingly, as a good recursion implementation often is.

local oldmath = {}
oldmath.floor = math.floor
function math.floor(...)
    --- Same as default in Lua, but it takes as many values as it needs.
    return map(oldmath.floor, 1, ...)
end

oldmath.ceil = math.ceil
function math.ceil(...)
    --- Same as default in Lua, but it takes as many values as it needs.
    return map(oldmath.ceil, 1, ...)
end

function oldmath.round(num)
    local lowNum = oldmath.floor(tonumber(num))
    return lowNum + (num - lowNum < .5 and 0 or 1)
end

function math.round(...)
    --- I have no idea why this isn't in Lua. Also takes as many values as it needs.
    return map(oldmath.round, 1, ...)
end

function math.frandom(low, high)
    --- Works like math.random(low,high), but returns a float instead of an int.
    if high then
        return math.random((low or 1) - (high and 0 or 1), high - 1) + math.random()
    else
        return (low and low > 1 and math.random(low - 1) or low) + math.random()
    end
end

stringx = stringx or {}
function stringx.indexOf(str, char, index)
    --- Works like String.indexOf() in Java without pattern recognition.
    return str:find(char, index, true)
end

function stringx.lastIndexOf(str, char, index)
    --- Works like String.lastIndexOf() in Java without pattern recognition.
    index = index or 1
    local charLen = #char
    for i = #str - charLen + index, 1, -1 do
        if str:sub(i, i + charLen - 1) == char then
            return i, i + charLen
        end
    end
end

function stringx.findLast(str, char, index, plain)
    --- Works like string.find, but from the back to the front. If you're using a lua pattern, make the lua pattern work for the reversed string.
    local lastIndex, lastIndexEnd = str:reverse():find((plain and char:reverse() or char), index, plain)
    return lastIndex and #str - lastIndexEnd + 1, #str - lastIndex + 1
end

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

function stringx.psplit(str, char)
    --- Converts str into a table given char as a delimiter. Works like String.split() in Java with pattern recognition.
    local tbl = {}
    local findChar, findCharEnd = str:find(char, nil, true)
    if findChar then
        tbl[#tbl + 1] = str:sub(1, findChar - 1)
        repeat
            local findChar2, findChar2End = str:find(char, findCharEnd + 1)
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

function stringx.splitFirst(str, char)
    --- Returns the characters before and after the first instance of char in str without pattern recognition.
    local index, indexEnd = stringx.indexOf(str, char)
    return str:sub(1, index), str:sub(indexEnd + 1)
end

function stringx.splitLast(str, char)
    --- Returns the characters before and after the last instance of char in str without pattern recognition.
    local index, indexEnd = stringx.lastIndexOf(str, char)
    return str:sub(1, index), str:sub(indexEnd + 1)
end

function stringx.psplitFirst(str, char)
    --- Returns the characters before and after the first instance of char in str with pattern recognition.
    local index, indexEnd = str:find(char)
    return str:sub(1, index), str:sub(indexEnd + 1)
end

function stringx.psplitLast(str, char)
    --- Returns the characters before and after the last instance of char in str with pattern recognition.
    local index, indexEnd = stringx.findLast(str, char)
    return str:sub(1, index), str:sub(indexEnd + 1)
end

tablex = {}
--- Returns the index of element in tbl, or nil if no such index exists.
--- Returns the indices as a table as {ind1,ind2,...,indN} for tbl[ind1][ind2]...[indN].
function tablex.indexOf(tbl, element)
    local indices, indicesLen = {}, 1
    local function searchTbl(tbl, element)
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                local index = searchTbl(v, element) --Recursive search
                if index ~= nil then
                    --Can't do "if not index", because false is allowed.
                    --Inserting it at index 1 is O(n), this is O(1). That results in O(n) total,
                    --rather than O(n^2) to insert it O(n) each time.
                    indices[indicesLen] = k
                    indicesLen = indicesLen + 1
                    return indices
                else
                    return nil
                end
            elseif v == element then
                indices[indicesLen] = k
                indicesLen = indicesLen + 1
                return indices
            end
        end
        return nil
    end

    for k, v in pairs(tbl) do
        if type(v) == "table" then
            local indices = { k }
            local results = searchTbl(v, element)
            for i = #results, 1, -1 do
                --searchTbl returns the indices in reverse, so if you insert them backwards, it's correct.
                indices[#indices + 1] = results[i]
            end
            return indices
        elseif v == element then
            return k
        end
    end
end

tablex.find = tablex.indexOf --Alias

--There isn't a tablex.lastIndexOf or a tablex.findLast because not all tables necessarily have an order of traversal
--until they have been traversed through, and therefore cannot be traversed in reverse.
--It could be done by traversing it once, keeping track of the keys, and traversing it in the reverse key order,
--But that's pretty inefficient, and shouldn't be needed.

local function doNothing()
end

function tablex.walk(tbl)
    ---"Walks" through a table, I.E. Iterates through an N-deep table as if it were a flat table. Returns key(s) and value.
    ---Use it like pairs() or ipairs() in a for loop. The key(s) will always be in a table.
    local indices = {}
    local indicesLen = 1
    local function appendKey(indices, indicesLen, key)
        --Always return copies of the table, since it will be modified within the coroutine.
        local newIndices = {}
        for i = 1, indicesLen-1 do
            newIndices[i] = indices[i]
        end
        --Append key, but since no more values will be appended to this copy, indicesLen does not need to be incremented.
        newIndices[indicesLen] = key
        return newIndices
    end
    local searchTblWrapper

    local function searchTbl(tbl, indices, indicesLen)
        --Make a copy of indices, so each reference frame of this function has its own copy of indices.
        local indicesCopy = {}
        for i = 1, indicesLen-1 do
            indicesCopy[i] = indices[i]
        end
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                indicesCopy[indicesLen] = k --Add the current key into the indices.
                for _ in searchTblWrapper(v, indicesCopy, indicesLen+1), v, nil do
                    doNothing() --IntelliJ doesn't like empty for loops, even though it makes shorter code in this case.
                end
            else
                coroutine.yield(appendKey(indicesCopy, indicesLen, k), v)
            end
        end
    end

    searchTblWrapper = function(tbl, indices, indicesLen)
        return function()
            searchTbl(tbl, indices, indicesLen)
        end
    end

    return coroutine.wrap(searchTblWrapper(tbl, indices, indicesLen)), tbl, nil
end

function tablex.merge(t1, t2)
    --- Merges tables, without any advanced functionality, like metatable merging.
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k]) == "table" then
            tablex.merge(t1[k], t2[k])
        else
            t1[k] = v
        end
    end
    return t1
end

--- This is what you would give the results from table.indexOf() to.
--- The first argument should be the table being accessed, the following arguments should be the indices in order.
--- Example use: To access tbl.bacon[a][5].c, use "tablex.get(tbl,unpack{"bacon",a,5,"c"})" or "tablex.get(tbl,"bacon",a,5,"c")"
function tablex.get(...)
    return select("#", ...) >= 3 and tablex.get((...)[select(2, ...)], select(3, ...)) or (...)[select(2, ...)]
end

--Modified from penlight. https://github.com/stevedonovan/Penlight/blob/master/lua/pl/tablex.lua
function tablex.equals(tbl1, tbl2, ignoreMetatable, threshold)
    --- Returns if two tables are the same, including sub-tables.
    local type1 = type(tbl1)
    if type1 ~= type(tbl2) then
        return false
    end
    --Non-table types can be directly compared
    if type1 ~= "table" then
        if type1 == "number" and threshold then
            return math.abs(tbl1 - tbl2) < threshold
        end
        return tbl1 == tbl2
    end
    --As well as tables which have the metamethod __eq
    local metatable = getmetatable(tbl1)
    if not ignoreMetatable and metatable and metatable.__eq then
        return tbl1 == tbl2
    end
    for k1 in pairs(tbl1) do
        if tbl2[k1] == nil then
            return false
        end
    end
    for k2 in pairs(tbl2) do
        if tbl1[k2] == nil then
            return false
        end
    end
    for k1, v1 in pairs(tbl1) do
        local v2 = tbl2[k1]
        if not tablex.equals(v1, v2, ignoreMetatable, threshold) then
            return false
        end
    end
    return true
end

--- Copies the value of tbl1 to tbl2 instead of making a pointer.
--- Modified from penlight. https://github.com/stevedonovan/Penlight/blob/master/lua/pl/tablex.lua
function tablex.copy(tbl, errorIfNotTable)
    if type(tbl) ~= "table" then
        if errorIfNotTable then
            --Silently returns the passed value by default.
            error(("Expected table, got %s"):format(type(tbl)))
        end
        return tbl
    end
    local copiedTbl = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            v = tablex.copy(v)
        end
        copiedTbl[k] = v
    end
    setmetatable(copiedTbl, getmetatable(tbl))
    return copiedTbl
end

function tablex.reverse(tbl, copy)
    ---Reverses a table. If copy is false, reverse in-place, otherwise make a new table.
    local tblLen = #tbl
    if not copy then
        for i = 1, tblLen / 2 do
            --Reverse the table, since inserting it backwards is n(n-i) iterations, but reversing it is n/2.
            tbl[i], tbl[tblLen - i + 1] = tbl[tblLen - i + 1], tbl[i] --Swap the first half of the elements with the last half
        end
        return tbl
    else
        local newTbl = {}
        for i = 1, tblLen do
            newTbl[i] = tbl[tblLen-i+1]
        end
        return newTbl
    end
end

---Like next(), but returns the elements in random order.
---useIPairs makes it like ipairs(),
---tblMutable allows it to work on mutable tables.
local function randNext(tbl, useIPairs, tblMutable)
    local tbl = tbl
    if tblMutable then
        -- If the table is mutable, copy it to avoid modification.
        tbl = tablex.copy(tbl)
    end
    return coroutine.wrap(function()
        local key, value
        local keys = {}
        local keysLen = 0
        for k in (useIPairs and ipairs or pairs)(tbl) do
            --Make a table of all of the keys in the table.
            keysLen = keysLen + 1
            keys[keysLen] = k
        end
        for i = 1, keysLen do
            local randIndex = math.random(1, keysLen) --Grab a random key from the remaining keys.
            keys[randIndex], keys[keysLen] = keys[keysLen], keys[randIndex] --Swap the random and last element
            key = keys[keysLen] --Grab the element before it's removed
            keys[keysLen] = nil --Remove the last element, which is O(1), where table.remove() is O(n)
            keysLen = keysLen - 1 --Update the length, because decrementing is cheaper than table length lookup.
            coroutine.yield(key, tbl[key]) --Yield the key and value.
        end
    end)
end

local function randPairs(tbl, i, tblMutable)
    return randNext(tbl, i, tblMutable), tbl, 1
end

---Like pairs(), but returns the elements in random order.
function randomPairs(tbl, tblMutable)
    return randPairs(tbl, false, tblMutable)
end

---Like ipairs(), but returns the elements in random order.
function randomIPairs(tbl, tblMutable)
    return randPairs(tbl, true, tblMutable)
end

---Like next(), but returns the elements in random order.
function randomNext(tbl, tblMutable)
    return randNext(tbl, false, tblMutable)
end

---Like the next() equivalent for ipairs(), but returns the elements in random order.
function randomINext(tbl, tblMutable)
    return randNext(tbl, true, tblMutable)
end

return true