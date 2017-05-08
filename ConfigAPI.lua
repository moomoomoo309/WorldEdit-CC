--Settings File API used to parse and interpret and save settings files. 
--Created by bwhodle, edited by moomoomoo3O9
--Forum post: http://www.computercraft.info/forums2/index.php?/topic/14311-preferences-settings-configuration-store-them-all-settings-file-api/

--DEPRECATED.
local function trimComments(line)
    local commentstart = #line
    for i = 1, #line do
        if line:byte(i) == (";"):byte() then
            commentstart = i - 1
            break
        end
    end
    return line:sub(0, commentstart)
end

local function split(line)
    local equalssign
    for i = 1, #line do
        if line:byte(i) == ("="):byte() or line:byte(i) == (":"):byte() then
            equalssign = i - 1
        end
    end
    if equalssign == nil then
        return nil, nil
    end
    return line:sub(1, equalssign), line:sub(equalssign + 2)
end

function Trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function RemoveQuotes(s)
    if s:byte(1) == ("\""):byte() and s:byte(#s) == ("\""):byte() then
        return s:sub(2, -2)
    end
    return s
end

local config = {}


function config.addSection(name)
    config.content = config.content or {}
    config.content[name] = {}
end

function config.addComment(key, value)
    config.comment[1][key] = value
end

function config.addSectionedComment(section, key, value)
    config.comment = config.comment or {}
    config.comment[section] = config.comment[section] or {}
    config.comment[section][key] = value
end

function config.getValue(key)
    return config.content[1][key]
end

function config.getSectionedValue(section, key)
    config.content = config.content or {}
    config.content[section] = config.content[section] or {}
    return config.content[section][key]
end

function config.hasSection(section)
    return config.content[section] ~= nil
end

function config.hasSectionedValue(section, key)
    return config.getSectionedValue(section, key) ~= nil
end

function config.setValue(key, value)
    config.content = config.content or {}
    config.content[1] = config.content[1] or {}
    config.content[1][key] = value
end

function config.setSectionedValue(section, key, value)
    config.content = config.content or {}
    config.content[section] = config.content[section] or {}
    config.content[section][key] = value
end

function config.save(path)
    local file = fs.open(path, "w")
    local d = config.content[1]
    if d ~= nil then
        for k, v in pairs(d) do
            if config.comment[1][k] then
                file.writeLine("; " .. config.comment[1][k])
            end
            local x = v
            if v:byte(1) == (" "):byte() or v:byte(#v) == (" "):byte() then
                x = "\"" .. v .. "\""
            end
            file.writeLine(k .. "=" .. x)
        end
    end
    for k, v in pairs(config.content) do
        if k ~= 1 then
            file.writeLine("")
            file.writeLine("[" .. k .. "]")
            for j, l in pairs(v) do
                l = tostring(l)
                if config.comment and config.comment[k] and config.comment[k][j] then
                    file.writeLine("; " .. config.comment[k][j])
                end
                local x = l
                if l:byte(1) == (" "):byte() or l:byte(#l) == (" "):byte() then
                    x = "\"" .. l .. "\""
                end
                file.writeLine(j .. "=" .. x)
            end
        end
    end
    file.close()
    return config
end

function openConfigFile(path)
    config = config or {}
    local currentsection = {}
    local currentsectionname
    if not fs.exists(path) then
        local touch = fs.open(path, "w")
        touch.close() --Make sure the file is created
        touch = nil
    end
    local file = fs.open(path, "r")
    local lines = true
    config.content = {}
    while lines do
        local currentline = file.readLine()
        if currentline == nil then
            lines = false
            break
        end
        currentline = trimComments(currentline)
        if Trim(currentline) ~= "" then
            if currentline:byte(1) == ("["):byte() then
                if currentsectionname ~= nil then
                    config.content[currentsectionname] = currentsection
                    currentsection = {}
                elseif currentsectionname == nil then
                    config.content[1] = currentsection
                    currentsection = {}
                end
                currentsectionname = currentline:sub(2, -2)
            else
                local key, value = split(currentline)
                if Trim(key) ~= nil and Trim(value) ~= nil then
                    local x = Trim(value)
                    if tonumber(x) then
                        x = tonumber(x)
                    else
                        x = RemoveQuotes(x)
                    end
                    if x ~= nil and tostring(Trim(key)) ~= nil then
                        currentsection[Trim(key)] = x
                    end
                end
            end
        end
    end
    if currentsectionname ~= nil then
        config.content[currentsectionname] = currentsection
        currentsection = {}
    elseif currentsectionname == nil then
        config.content[1] = currentsection
        currentsection = {}
    end
    return config
end