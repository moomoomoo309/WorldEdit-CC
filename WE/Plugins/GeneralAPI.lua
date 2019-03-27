--- Returns error text if any of the arguments are nil. Pass it your command's arguments.
function argError(...)
    for k, v in pairs({ ... }) do
        if v == nil then
            return "Argument " .. k .. " is nil."
        end
    end
end

--- Returns if all of the given values are truthy.
function all(...)
    return select("#", ...) == 1 and ((...) and true or false) or ((...) and all(select(2, ...)))
end

--- Returns if any of the given values are truthy.
function any(...)
    return ((...) and true or false) or any(select(2, ...))
end

local function mapIterative(fct, numArgs, ...)
    assert(type(fct) == "function" and type(numArgs) == "number")
    if numArgs == 0 then
        fct()
        return
    end
    local args, returns = { ... }, {}
    for i = 1, #args, numArgs do
        local localArgs, len = {}, 0 --Cut down on length lookups
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

local function mapRecursive(fct, numArgs, ...)
    assert(type(fct) == "function" and type(numArgs) == "number")
    if numArgs == 0 then
        fct()
        return
    end
    local results = {}
    local function innerWrap(fct, numArgs, results, args)
        local tbl, argsLen, tblLen = {}, #args, 0 --Do only one length lookup per table
        --You could insert the elements at their final index and not reverse the argument table, but doing that
        --means there's no guarantee the table will be represented as an array internally.
        --Starting with an empty table and appending to the end repeatedly does assure this.
        for i = argsLen, argsLen - numArgs + 1, -1 do
            tblLen = tblLen + 1
            tbl[tblLen] = args[i]
            args[argsLen] = nil --Remove the last argument, so to avoid a table.remove() call (which is O(n-i), where this is O(1))
            argsLen = argsLen - 1
        end
        --Reversing the table does not change the array representation of the table because it's only using swaps.
        for i = 1, tblLen / 2 do
            tbl[i], tbl[tblLen - i + 1] = tbl[tblLen - i + 1], tbl[i]
        end
        if argsLen < 0 and tblLen < numArgs then
            return results
        end
        results[#results + 1] = { fct(unpack(tbl)) }
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
--- Same as default in Lua, but it takes as many values as it needs.
function math.floor(...)
    return map(oldmath.floor, 1, ...)
end

oldmath.ceil = math.ceil
--- Same as default in Lua, but it takes as many values as it needs.
function math.ceil(...)
    return map(oldmath.ceil, 1, ...)
end

function oldmath.round(num)
    local lowNum = oldmath.floor(tonumber(num))
    return lowNum + (num - lowNum < .5 and 0 or 1)
end

--- I have no idea why this isn't in Lua. Also takes as many values as it needs.
function math.round(...)
    return map(oldmath.round, 1, ...)
end

--- Works like math.random(low,high), but returns a float instead of an int.
function math.frandom(low, high)
    if low then
        if high then
            return low + math.random() * (high - low)
        else
            return math.random() * low
        end
    else
        return math.random()
    end
end

stringx = stringx or {}
--- Works like String.indexOf() in Java without pattern recognition.
function stringx.indexOf(str, char, index)
    return str:find(char, index, true)
end

--- Works like String.lastIndexOf() in Java without pattern recognition.
function stringx.lastIndexOf(str, char, index)
    index = index or 1
    local charLen = #char
    for i = #str - charLen + index, 1, -1 do
        if str:sub(i, i + charLen - 1) == char then
            return i, i + charLen
        end
    end
end

--- Works like string.find, but from the back to the front. If you're using a lua pattern, make the lua pattern work for the reversed string.
function stringx.findLast(str, char, index, plain)
    local lastIndex, lastIndexEnd = str:reverse():find((plain and char:reverse() or char), index, plain)
    return lastIndex and #str - lastIndexEnd + 1, #str - lastIndex + 1
end

--- Converts str into a table given char as a delimiter. Works like String.split() in Java without pattern recognition.
function stringx.split(str, char)
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

--- Converts str into a table given char as a delimiter. Works like String.split() in Java with pattern recognition.
function stringx.psplit(str, char)
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

--- Returns the characters before and after the first instance of char in str without pattern recognition.
function stringx.splitFirst(str, char)
    local index, indexEnd = stringx.indexOf(str, char)
    return str:sub(1, index), str:sub(indexEnd + 1)
end

--- Returns the characters before and after the last instance of char in str without pattern recognition.
function stringx.splitLast(str, char)
    local index, indexEnd = stringx.lastIndexOf(str, char)
    return str:sub(1, index), str:sub(indexEnd + 1)
end

--- Returns the characters before and after the first instance of char in str with pattern recognition.
function stringx.psplitFirst(str, char)
    local index, indexEnd = str:find(char)
    return str:sub(1, index), str:sub(indexEnd + 1)
end

--- Returns the characters before and after the last instance of char in str with pattern recognition.
function stringx.psplitLast(str, char)
    local index, indexEnd = stringx.findLast(str, char)
    return str:sub(1, index), str:sub(indexEnd + 1)
end

tablex = {}
--- Returns the index of element in tbl, or nil if no such index exists.
--- @return the indices as a table as {ind1,ind2,...,indN} for tbl[ind1][ind2]...[indN].
function tablex.indexOf(tbl, element)
    local indices, indicesLen = {}, 1
    local function searchTbl(tbl, element)
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                local index = searchTbl(v, element) --Recursive search
                if index ~= nil then
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
            --Reverse the table, for the savings you get on insertion.
            for i = #results, 1, -1 do
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

--- "Walks" through a table, I.E. Iterates through an N-deep table as if it were a flat table. Returns key(s) and value.
--- Use it like pairs() or ipairs() in a for loop. The key(s) will always be in a table.
function tablex.walk(tbl)
    local indices = {}
    local indicesLen = 1
    local function appendKey(indices, indicesLen, key)
        --Always return copies of the table, since it will be modified within the coroutine.
        local newIndices = {}
        for i = 1, indicesLen - 1 do
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
        for i = 1, indicesLen - 1 do
            indicesCopy[i] = indices[i]
        end
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                indicesCopy[indicesLen] = k --Add the current key into the indices.
                for _ in searchTblWrapper(v, indicesCopy, indicesLen + 1), v, nil do
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

--- Makes a flat copy of the given table. Order is based on pairs(), and is therefore arbitrary.
function tablex.flatten(tbl)
    local newTbl = {}
    local len = 0
    for _, v in tablex.walk(tbl) do
        len = len + 1
        newTbl[len] = v
    end
    return newTbl
end

--- Flattens a table in-place.
--- @param topTbl The table to flatten. It will be modified.
--- @return The original table, modified to have its contents flattened.
function tablex.flattenInPlace(topTbl)
    local originalLen = #topTbl
    local flatLength = 0

    local function recurse(tbl, oldK, oldTbl, topLevel)
        oldTbl[oldK] = nil -- Release the parent table's reference to this one, so once you're done, it's GC'd.
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                recurse(v, k, tbl, false)
            else
                flatLength = flatLength + 1
                topTbl[flatLength] = v
            end
        end
    end

    for k, v in pairs(topTbl) do
        if k == originalLen + 1 then -- No need to iterate over the stuff you already appended.
            break
        end
        if type(v) == "table" then
            recurse(v, k, topTbl, true)
        else
            flatLength = flatLength + 1
            if k ~= flatLength then
                topTbl[k], topTbl[flatLength] = topTbl[flatLength], topTbl[k]
            end
        end
    end
    return topTbl
end


--- Merges tables, without any advanced functionality, like metatable merging.
function tablex.merge(t1, t2)
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

--- Returns if two tables are the same, including sub-tables.
function tablex.equals(tbl1, tbl2, ignoreMetatable, threshold)
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

--- Reverses a table. If copy is false, reverse in-place, otherwise make a new table.
function tablex.reverse(tbl, copy)
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
            newTbl[i] = tbl[tblLen - i + 1]
        end
        return newTbl
    end
end

--- Like next(), but returns the elements in random order.
--- useIPairs makes it like ipairs(),
--- tblMutable allows it to work on mutable tables.
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

local function randPairs(tbl, useIPairs, tblMutable)
    return randNext(tbl, useIPairs, tblMutable), tbl, 1
end

--- Like pairs(), but returns the elements in random order.
function randomPairs(tbl, tblMutable)
    return randPairs(tbl, false, tblMutable)
end

--- Like ipairs(), but returns the elements in random order.
function randomIPairs(tbl, tblMutable)
    return randPairs(tbl, true, tblMutable)
end

--- Like next(), but returns the elements in random order.
function randomNext(tbl, tblMutable)
    return randNext(tbl, false, tblMutable)
end

--- Like the next() equivalent for ipairs(), but returns the elements in random order.
function randomINext(tbl, tblMutable)
    return randNext(tbl, true, tblMutable)
end

return true
