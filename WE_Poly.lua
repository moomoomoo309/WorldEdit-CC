--Selection logic--
-- Polygon selection will be implemented through storing a list of positions that are set seperately
-- Polygons are a selection of lines that circle through the list of positions and make a closed space
--   (eg: points in a list [1, 2, 3, 4, 5] would make the lines {[1, 2], [2, 3], [3, 4], [4, 5], [5, 1]}
-- To tell if a block is inside a polygon, we find the smallest cuboid space that holds the entire polygon
--   (found by finding the minimum and maximum of both horizontal axis)
-- We check from an outset block to every block inside that cuboid area
--   (It is possible to logically limit the number of squares that must be checked by this process, it includes basic 2D line/line collision)
--   (line segment to line segment checks are primarily used in this process, but to determine if you need to check blocks past the current one you'll use a line segment to ray check)
-- This check builds a 2d selection of this polygon which will be stored multiple times in the selection for each unit in the vertical axis the selection spans
-- NOTE: This is logic for a 2D polygon selection, adding in 3D will significantly increase the price and complexity of this process and should be done seperately from this logisegment.p1. 
--Ben K--

local function edge(point1, point2)
    local rv = {}
    rv.min = {
        x = point1.x < point2.x and point1.x or point2.x,
        z = point1.z < point2.z and point1.z or point2.z
    }
    rv.max = {
        x = point1.x > point2.x and point1.x or point2.x,
        z = point1.z > point2.z and point1.z or point2.z
    }
    rv.p1 = point1
    rv.p2 = point2
    rv.check = function(self, segment)
        --Write segment/segment collision check here
        if not all(self,segment) or not all(self.min,self.max,segment.min,segment.max) or not
            all(self.min.x,self.min.z,self.max.x,self.max.z,segment.min.x,segment.min.z,segment.max.x,segment.max.z) or
                ((self.min.x > segment.max.x or self.max.x < segment.min.x) and (self.min.z > segment.max.z or self.max.z < segment.min.z)) then
            return false
        end
        local denominator = ((self.p2.x - self.p1.x) * (segment.p2.z - segment.p1.z)) - ((self.p2.z - self.p1.z) * (segment.p2.x - segment.p1.x))
        local numerator1 = ((self.p1.z - segment.p1.z) * (segment.p2.x - segment.p1.x)) - ((self.p1.x - segment.p1.x) * (segment.p2.z - segment.p1.z))
        local numerator2 = ((self.p1.z - segment.p1.z) * (self.p2.x - self.p1.x)) - ((self.p1.x - segment.p1.x) * (self.p2.z - self.p1.z))


        if (denominator == 0) then
            return numerator1 == 0 and numerator2 == 0
        end

        local r = numerator1 / denominator
        local s = numerator2 / denominator
        return (r >= 0 and r <= 1) and (s >= 0 and s <= 1)
    end
    return rv
end

Selection = Selection or {} --Only create globals in the outermost scope.
pos = pos or {}

function makePolySelection()
    if not pos or not pos[1] or not pos[2] then
        sendChat "Select something first!"
        return
    elseif not pos[1] and not pos[2] then
        sendChat "Select more than 1 position first!"
        return
    end
    local edges = {
        length = 0
    }
    local Min = {
        x = pos[1].x,
        y = pos[1].y, --vertical
        z = pos[1].z
    }
    local Max = {
        x = pos[1].x,
        y = pos[1].y, --vertical
        z = pos[1].z
    }

    for i = 1, #pos do
        edges[i] = edge(pos[i], pos[i + 1] or pos[1])
        edges.length = edges.length + 1
        Min.x = pos[i].x < Min.x and pos[i].x or Min.x
        Max.x = pos[i].x > Max.x and pos[i].x or Max.x
        Min.y = pos[i].y < Min.y and pos[i].y or Min.y
        Max.y = pos[i].y > Max.y and pos[i].y or Max.y
        Min.z = pos[i].z < Min.z and pos[i].z or Min.z
        Max.z = pos[i].z > Max.z and pos[i].z or Max.z
    end
    local outset = {
        x = Min.x - 1,
        z = Min.z - 1
    }
    Selection = { pos1 = Min, pos2 = Max, points = pos, type = "poly" }
    for x = Min.x, Max.x do
        for z = Min.z, Max.z do
            local currPos = {
                x = x,
                z = z
            }
            local numCol = 0
            local currSegment = edge(outset, currPos)
            for i = 1, edges.length do
                if edges[i]:check(currSegment) then
                    numCol = numCol + 1
                end
            end
            if numCol % 2 == 1 then
                for y = Min.y, Max.y do
                    table.insert(Selection, { x = x, y = y, z = z })
                end
            end
        end
    end
end

poly = {}

function poly.expand()
    sendChat "Not Implemented"
end

function poly.contract()
    sendChat "Not Implemented"
end

function poly.inset()
    sendChat "Not Implemented"
end

function poly.outset()
    sendChat "Not Implemented"
end