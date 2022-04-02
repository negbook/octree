local setmetatable = setmetatable
local DrawLine = DrawLine
local GetEntityCoords = GetEntityCoords
local Wait = Wait
local CreateThread = CreateThread
local table = table
local ipairs = ipairs
local math = math
local GetPlayerPed = GetPlayerPed
local GetEntityCoords = GetEntityCoords
local vector3 = vector3
local vector2 = vector2
OcTree = {}
local Contains = {
    pointtopoint = function(pointA,pointB,radius)
        local radius = radius or 0
        return #(pointA - pointB) <= radius
    end,
    pointtobox = function(pointA,box,radius)
        local radius = radius or 0
        --return pointA.x >= box.center.x - box.size.x/2 - radius and pointA.x <= box.center.x + box.size.x/2 + radius and pointA.y >= box.center.y - box.size.y/2 - radius and pointA.y <= box.center.y + box.size.y/2 + radius and pointA.z >= box.center.z - box.size.z/2 - radius and pointA.z <= box.center.z + box.size.z/2 + radius
        local pointAx = pointA.x
        local pointAy = pointA.y
        local pointAz = pointA.z
        local boxCenterx = box.center.x
        local boxCentery = box.center.y
        local boxCenterz = box.center.z
        local boxSizeX = box.size.x
        local boxSizeY = box.size.y
        local boxSizeZ = box.size.z

        return pointAx >= boxCenterx - boxSizeX/2 - radius and pointAx <= boxCenterx + boxSizeX/2 + radius and pointAy >= boxCentery - boxSizeY/2 - radius and pointAy <= boxCentery + boxSizeY/2 + radius and pointAz >= boxCenterz - boxSizeZ/2 - radius and pointAz <= boxCenterz + boxSizeZ/2 + radius
    end,
    boxtobox = function(boxA,boxB,radius)
        local radius = radius or 0
        --return boxA.center.x - boxA.size.x/2 - radius <=  boxB.center.x + boxB.size.x/2 + radius and boxA.center.y - boxA.size.y/2 - radius <=  boxB.center.y + boxB.size.y/2 + radius and boxA.center.z - boxA.size.z/2 - radius <=  boxB.center.z + boxB.size.z/2 + radius
        local boxACenterx = boxA.center.x
        local boxACentery = boxA.center.y
        local boxACenterz = boxA.center.z
        local boxASizeX = boxA.size.x
        local boxASizeY = boxA.size.y
        local boxASizeZ = boxA.size.z

        local boxBCenterx = boxB.center.x
        local boxBCentery = boxB.center.y
        local boxBCenterz = boxB.center.z
        local boxBSizeX = boxB.size.x
        local boxBSizeY = boxB.size.y
        local boxBSizeZ = boxB.size.z

        return boxACenterx - boxASizeX/2 - radius <=  boxBCenterx + boxBSizeX/2 + radius and boxACentery - boxASizeY/2 - radius <=  boxBCentery + boxBSizeY/2 + radius and boxACenterz - boxASizeZ/2 - radius <=  boxBCenterz + boxBSizeZ/2 + radius
    end,
}

function OcTree.new(boundary, capacity)
    local boundary_bottom_center = boundary.game_center
    local boundary_top_center = boundary.game_center + vector3(0.0,0.0,boundary.size.z)
    local boundary_center = boundary.center or (boundary_bottom_center + boundary_top_center) * 0.5
    local boundary_width = boundary.size.x
    local boundary_length = boundary.size.y
    local boundary_hight = boundary.size.z
    local o = {
        center     = boundary_center,
        game_center = boundary_bottom_center,-- we use gamecenter on init and checks
        size = boundary.size,
        capacity = capacity or 4,
        points = {},
        objects = {},
        isdivided = false,
        isinquery = false,
    }
    setmetatable(o.objects,{__tostring = function(t) 
        local r = ""
        for i,v in pairs(t) do 
            r = r .. i.."("..#v..")" .. " "
        end 
        return r
    end})
    return setmetatable(
    o, {
        __index = OcTree,
        __tostring = function(self)
            return "QuadTree: center: "..self.center.x.." "..self.center.y..
            " width: "..self.size.x.." height: "..self.size.y..
            " capacity: "..self.capacity.." points: "..#self.points..
              " isdivided: "..tostring(self.isdivided).."\nobjects: "..tostring(self.objects)
            
        end
    })
end

--similar to quadtree.lua
function OcTree:inner_subdivide()
    local parentcenter = self.center
    local parentwidth = self.size.x
    local parentlength = self.size.y
    local parenthight = self.size.z
    local childwidth = parentwidth / 2
    local childlength = parentlength / 2
    local childhight = parenthight / 2
    local toleftX = parentcenter.x - childwidth/2
    local toupY = parentcenter.y - childlength/2
    local tofloorZ = parentcenter.z - childhight/2
    
    local torightX = parentcenter.x + childwidth/2
    local todownY = parentcenter.y + childlength/2
    local toroofZ = parentcenter.z + childhight/2

    local childlefttopcenter_topbox = vector3(parentcenter.x - childwidth/2 , parentcenter.y + childlength/2, parentcenter.z + childhight/2)
    local childrighttopcenter_topbox = vector3(parentcenter.x + childwidth/2 , parentcenter.y + childlength/2, parentcenter.z + childhight/2)
    local childleftbottomcenter_topbox = vector3(parentcenter.x - childwidth/2 , parentcenter.y - childlength/2, parentcenter.z + childhight/2)
    local childrightbottomcenter_topbox = vector3(parentcenter.x + childwidth/2 , parentcenter.y - childlength/2, parentcenter.z + childhight/2)

    local childlefttopcenter_bottombox = vector3(parentcenter.x - childwidth/2 , parentcenter.y + childlength/2, parentcenter.z - childhight/2)
    local childrighttopcenter_bottombox = vector3(parentcenter.x + childwidth/2 , parentcenter.y + childlength/2, parentcenter.z - childhight/2)
    local childleftbottomcenter_bottombox = vector3(parentcenter.x - childwidth/2 , parentcenter.y - childlength/2, parentcenter.z - childhight/2)
    local childrightbottomcenter_bottombox = vector3(parentcenter.x + childwidth/2 , parentcenter.y - childlength/2, parentcenter.z - childhight/2)

    local childsize = vector3(childwidth,childlength,childhight)
    --create new quadtrees in 8 box regions
    self.topbox_lefttop = OcTree.new(
        {
            center = childlefttopcenter_topbox,
            game_center = childlefttopcenter_topbox - vector3(0.0,0.0,childhight),
            size = childsize
        },
        self.capacity
    )
    self.topbox_righttop = OcTree.new(
        {
            center = childrighttopcenter_topbox,
            game_center = childrighttopcenter_topbox - vector3(0.0,0.0,childhight),
            size = childsize
        },
        self.capacity
    )
    self.topbox_leftbottom = OcTree.new(
        {
            center = childleftbottomcenter_topbox,
            game_center = childleftbottomcenter_topbox - vector3(0.0,0.0,childhight),
            size = childsize
        },
        self.capacity
    )
    self.topbox_rightbottom = OcTree.new(
        {
            center = childrightbottomcenter_topbox,
            game_center = childrightbottomcenter_topbox - vector3(0.0,0.0,childhight),
            size = childsize
        },
        self.capacity
    )
    self.bottombox_lefttop = OcTree.new(
        {
            center = childlefttopcenter_bottombox,
            game_center = childlefttopcenter_bottombox - vector3(0.0,0.0,childhight),
            size = childsize
        },
        self.capacity
    )
    self.bottombox_righttop = OcTree.new(
        {
            center = childrighttopcenter_bottombox,
            game_center = childrighttopcenter_bottombox - vector3(0.0,0.0,childhight),
            size = childsize
        },
        self.capacity
    )
    self.bottombox_leftbottom = OcTree.new(
        {
            center = childleftbottomcenter_bottombox,
            game_center = childleftbottomcenter_bottombox - vector3(0.0,0.0,childhight),
            size = childsize
        },
        self.capacity
    )
    self.bottombox_rightbottom = OcTree.new(
        {
            center = childrightbottomcenter_bottombox,
            game_center = childrightbottomcenter_bottombox - vector3(0.0,0.0,childhight),
            size = childsize
        },
        self.capacity
    )
    
    
    self.isdivided = true
end

function OcTree:inner_intersects(box)
    local box_center = box.center
    local box_width = box.size.x
    local box_length = box.size.y
    local box_hight = box.size.z
    local center = self.center
    local width = self.size.x
    local length = self.size.y
    local hight = self.size.z
    --[[
    return (box_center.x + box_width/2 > center.x - width/2 and
            box_center.x - box_width/2 < center.x + width/2 and
            box_center.y + box_length/2 > center.y - length/2 and
            box_center.y - box_length/2 < center.y + length/2 and
            box_center.z + box_hight/2 > center.z - hight/2 and
            box_center.z - box_hight/2 < center.z + hight/2)
    --]]
    local boxcenterx = box_center.x
    local boxcenterz = box_center.z
    local boxcentery = box_center.y
    local boxhalfwidth = box_width/2
    local boxhalflength = box_length/2
    local boxhalfhight = box_hight/2
    local selfcenterx = center.x
    local selfcenterz = center.z
    local selfcentery = center.y
    local selfhalfwidth = width/2
    local selfhalflength = length/2
    local selfhalfhight = hight/2

    return (boxcenterx + boxhalfwidth > selfcenterx - selfhalfwidth and
            boxcenterx - boxhalfwidth < selfcenterx + selfhalfwidth and
            boxcenterz + boxhalflength > selfcenterz - selfhalflength and
            boxcenterz - boxhalflength < selfcenterz + selfhalflength and
            boxcentery + boxhalfhight > selfcentery - selfhalfhight and
            boxcentery - boxhalfhight < selfcentery + selfhalfhight)
end

function OcTree:inner_point_contains (point, radius)
    local radius = radius or 0.0
    --[[
    return point.x >= self.center.x - self.size.x/2 - radius and point.x <= self.center.x + self.size.x/2 + radius and
           point.y >= self.center.y - self.size.y/2 - radius and point.y <= self.center.y + self.size.y/2 + radius and
           point.z >= self.center.z - self.size.z/2 - radius and point.z <= self.center.z + self.size.z/2 + radius
    --]]
    local pointx = point.x
    local pointz = point.z
    local pointy = point.y
    local selfcenterx = self.center.x
    local selfcenterz = self.center.z
    local selfcentery = self.center.y
    local selfhalfwidth_withradius = self.size.x/2 + radius
    local selfhalflength_withradius = self.size.y/2 + radius
    local selfhalfhight_withradius = self.size.z/2 + radius

    return (pointx >= selfcenterx - selfhalfwidth_withradius and pointx <= selfcenterx + selfhalfwidth_withradius and
            pointz >= selfcenterz - selfhalflength_withradius and pointz <= selfcenterz + selfhalflength_withradius and
            pointy >= selfcentery - selfhalfhight_withradius and pointy <= selfcentery + selfhalfhight_withradius)

end

function OcTree:insert_point(point)
    if not self:inner_point_contains(point) then
        return false
    end
    if #self.points < self.capacity then
        table.insert(self.points, point)
        return true
    else 
        if not self.isdivided then
            self:inner_subdivide()
        end
        if self.topbox_lefttop:insert_point(point) then
            return true 
        end
        if self.topbox_righttop:insert_point(point) then
            return true 
        end
        if self.topbox_leftbottom:insert_point(point) then
            return true 
        end
        if self.topbox_rightbottom:insert_point(point) then
            return true 
        end
        if self.bottombox_lefttop:insert_point(point) then
            return true 
        end
        if self.bottombox_righttop:insert_point(point) then
            return true 
        end
        if self.bottombox_leftbottom:insert_point(point) then
            return true 
        end
        if self.bottombox_rightbottom:insert_point(point) then
            return true 
        end
        return false
    end
end

function OcTree:query_points_by_box(box, found)
    found = found or {}
    if not self:inner_intersects(box) then
        return found
    end
    for _, point in ipairs(self.points) do
        if Contains.pointtobox(point, box) then
            table.insert(found, point)
        end
    end
    if self.isdivided then
        self.topbox_lefttop:query_points_by_box(box, found)
        self.topbox_righttop:query_points_by_box(box, found)
        self.topbox_leftbottom:query_points_by_box(box, found)
        self.topbox_rightbottom:query_points_by_box(box, found)
        self.bottombox_lefttop:query_points_by_box(box, found)
        self.bottombox_righttop:query_points_by_box(box, found)
        self.bottombox_leftbottom:query_points_by_box(box, found)
        self.bottombox_rightbottom:query_points_by_box(box, found)
    end
    return found
end

function OcTree:query_points_by_point(point, radius, found)
    found = found or {}
    if not self:inner_point_contains(point, radius) then
        return found
    end
    for _, point_ in ipairs(self.points) do
        if Contains.pointtopoint(point_, point, radius) then
            table.insert(found, point_)
        end
    end
    if self.isdivided then
        self.topbox_lefttop:query_points_by_point(point, radius, found)
        self.topbox_righttop:query_points_by_point(point, radius, found)
        self.topbox_leftbottom:query_points_by_point(point, radius, found)
        self.topbox_rightbottom:query_points_by_point(point, radius, found)
        self.bottombox_lefttop:query_points_by_point(point, radius, found)
        self.bottombox_righttop:query_points_by_point(point, radius, found)
        self.bottombox_leftbottom:query_points_by_point(point, radius, found)
        self.bottombox_rightbottom:query_points_by_point(point, radius, found)
    end
    return found
end

function OcTree:inner_object_contains(object)
    local center = object.center 
    local size = object.size
    --[[
    return center.x - size.x/2 >= self.center.x - self.size.x/2 and center.x + size.x/2 <= self.center.x + self.size.x/2 and
           center.y - size.y/2 >= self.center.y - self.size.y/2 and center.y + size.y/2 <= self.center.y + self.size.y/2 and
           center.z - size.z/2 >= self.center.z - self.size.z/2 and center.z + size.z/2 <= self.center.z + self.size.z/2
    --]]
    local selfcenterx = self.center.x
    local selfcenterz = self.center.z
    local selfcentery = self.center.y
    local selfhalfwidth = self.size.x/2
    local selfhalflength = self.size.y/2
    local selfhalfhight = self.size.z/2
    local objectcenterx = center.x
    local objectcenterz = center.z
    local objectcentery = center.y
    local objecthalfwidth = size.x/2
    local objecthalflength = size.y/2
    local objecthalfhight = size.z/2

    return (objectcenterx - objecthalfwidth >= selfcenterx - selfhalfwidth and objectcenterx + objecthalfwidth <= selfcenterx + selfhalfwidth and
            objectcenterz - objecthalflength >= selfcenterz - selfhalflength and objectcenterz + objecthalflength <= selfcenterz + selfhalflength and
            objectcentery - objecthalfhight >= selfcentery - selfhalfhight and objectcentery + objecthalfhight <= selfcentery + selfhalfhight)

end


function OcTree:insert_object(catagary_name,object)
    if not self:inner_object_contains(object) then
        return false
    end
    if not self.objects[catagary_name] then
        self.objects[catagary_name] = {}
    end
    if #self.objects[catagary_name] < self.capacity then
        table.insert(self.objects[catagary_name], object)
        return true
    else 
        if not self.isdivided then
            self:inner_subdivide()
        end
        if self.topbox_lefttop:insert_object(catagary_name,object) then
            return true 
        end
        if self.topbox_righttop:insert_object(catagary_name,object) then
            return true 
        end
        if self.topbox_leftbottom:insert_object(catagary_name,object) then
            return true 
        end
        if self.topbox_rightbottom:insert_object(catagary_name,object) then
            return true 
        end
        if self.bottombox_lefttop:insert_object(catagary_name,object) then
            return true 
        end
        if self.bottombox_righttop:insert_object(catagary_name,object) then
            return true 
        end
        if self.bottombox_leftbottom:insert_object(catagary_name,object) then
            return true 
        end
        if self.bottombox_rightbottom:insert_object(catagary_name,object) then
            return true 
        end
        return false
    end
end

function OcTree:query_objects_by_box(catagary_name, box, found)
    found = found or {}
    if not self:inner_intersects(box) then
        return found
    end
    if self.objects[catagary_name] then 
        for _, object in ipairs(self.objects[catagary_name]) do
            if Contains.boxtobox(object, box) then
                table.insert(found, object)
            end
        end
    else 
        return found
    end 
    if self.isdivided then
        self.topbox_lefttop:query_objects_by_box(catagary_name, box, found)
        self.topbox_righttop:query_objects_by_box(catagary_name, box, found)
        self.topbox_leftbottom:query_objects_by_box(catagary_name, box, found)
        self.topbox_rightbottom:query_objects_by_box(catagary_name, box, found)
        self.bottombox_lefttop:query_objects_by_box(catagary_name, box, found)
        self.bottombox_righttop:query_objects_by_box(catagary_name, box, found)
        self.bottombox_leftbottom:query_objects_by_box(catagary_name, box, found)
        self.bottombox_rightbottom:query_objects_by_box(catagary_name, box, found)
    end
    return found
end

function OcTree:query_objects_by_point(catagary_name, point, radius, found)
    found = found or {}
    if not self:inner_point_contains(point, radius) then
        return found
    end
    if self.objects[catagary_name] then 
        for _, object in ipairs(self.objects[catagary_name]) do
            if Contains.pointtobox(point, object, radius) then
                table.insert(found, object)
            end
        end
    else 
        return found
    
    end 
    if self.isdivided then
        self.topbox_lefttop:query_objects_by_point(catagary_name, point, radius, found)
        self.topbox_righttop:query_objects_by_point(catagary_name, point, radius, found)
        self.topbox_leftbottom:query_objects_by_point(catagary_name, point, radius, found)
        self.topbox_rightbottom:query_objects_by_point(catagary_name, point, radius, found)
        self.bottombox_lefttop:query_objects_by_point(catagary_name, point, radius, found)
        self.bottombox_righttop:query_objects_by_point(catagary_name, point, radius, found)
        self.bottombox_leftbottom:query_objects_by_point(catagary_name, point, radius, found)
        self.bottombox_rightbottom:query_objects_by_point(catagary_name, point, radius, found)
    end
    return found
end



    

local DrawPixel = function(pos,pixelscale,r,g,b,a)
    local pixelscale  = pixelscale or 0.01
    local r,g,b,a = r or 255,g or 255,b or 255,a or 255
    DrawLine(pos.x-pixelscale,pos.y-pixelscale,pos.z-pixelscale,pos.x+pixelscale,pos.y-pixelscale,pos.z-pixelscale,r,g,b,a)
    DrawLine(pos.x+pixelscale,pos.y-pixelscale,pos.z-pixelscale,pos.x+pixelscale,pos.y+pixelscale,pos.z-pixelscale,r,g,b,a)   
    DrawLine(pos.x+pixelscale,pos.y+pixelscale,pos.z-pixelscale,pos.x-pixelscale,pos.y+pixelscale,pos.z-pixelscale,r,g,b,a)
    DrawLine(pos.x-pixelscale,pos.y+pixelscale,pos.z-pixelscale,pos.x-pixelscale,pos.y-pixelscale,pos.z-pixelscale,r,g,b,a)
    
    DrawLine(pos.x-pixelscale,pos.y-pixelscale,pos.z+pixelscale,pos.x+pixelscale,pos.y-pixelscale,pos.z+pixelscale,r,g,b,a)
    DrawLine(pos.x+pixelscale,pos.y-pixelscale,pos.z+pixelscale,pos.x+pixelscale,pos.y+pixelscale,pos.z+pixelscale,r,g,b,a)
    DrawLine(pos.x+pixelscale,pos.y+pixelscale,pos.z+pixelscale,pos.x-pixelscale,pos.y+pixelscale,pos.z+pixelscale,r,g,b,a)
    DrawLine(pos.x-pixelscale,pos.y+pixelscale,pos.z+pixelscale,pos.x-pixelscale,pos.y-pixelscale,pos.z+pixelscale,r,g,b,a)

    DrawLine(pos.x-pixelscale,pos.y-pixelscale,pos.z-pixelscale,pos.x-pixelscale,pos.y-pixelscale,pos.z+pixelscale,r,g,b,a)
    DrawLine(pos.x+pixelscale,pos.y-pixelscale,pos.z-pixelscale,pos.x+pixelscale,pos.y-pixelscale,pos.z+pixelscale,r,g,b,a)
    DrawLine(pos.x+pixelscale,pos.y+pixelscale,pos.z-pixelscale,pos.x+pixelscale,pos.y+pixelscale,pos.z+pixelscale,r,g,b,a)
    DrawLine(pos.x-pixelscale,pos.y+pixelscale,pos.z-pixelscale,pos.x-pixelscale,pos.y+pixelscale,pos.z+pixelscale,r,g,b,a)
end 
function OcTree:DrawGrids()
    local r,g,b,a = 255,255,255,255
    if self.isinquery then
        r,g,b,a = 0,255,0,255
    end
    DrawLine(self.center.x-self.size.x/2,self.center.y-self.size.y/2,self.center.z-self.size.z/2,self.center.x+self.size.x/2,self.center.y-self.size.y/2,self.center.z-self.size.z/2,r,g,b,a)
    DrawLine(self.center.x+self.size.x/2,self.center.y-self.size.y/2,self.center.z-self.size.z/2,self.center.x+self.size.x/2,self.center.y+self.size.y/2,self.center.z-self.size.z/2,r,g,b,a)
    DrawLine(self.center.x+self.size.x/2,self.center.y+self.size.y/2,self.center.z-self.size.z/2,self.center.x-self.size.x/2,self.center.y+self.size.y/2,self.center.z-self.size.z/2,r,g,b,a)
    DrawLine(self.center.x-self.size.x/2,self.center.y+self.size.y/2,self.center.z-self.size.z/2,self.center.x-self.size.x/2,self.center.y-self.size.y/2,self.center.z-self.size.z/2,r,g,b,a)

    DrawLine(self.center.x-self.size.x/2,self.center.y-self.size.y/2,self.center.z+self.size.z/2,self.center.x+self.size.x/2,self.center.y-self.size.y/2,self.center.z+self.size.z/2,r,g,b,a)
    DrawLine(self.center.x+self.size.x/2,self.center.y-self.size.y/2,self.center.z+self.size.z/2,self.center.x+self.size.x/2,self.center.y+self.size.y/2,self.center.z+self.size.z/2,r,g,b,a)
    DrawLine(self.center.x+self.size.x/2,self.center.y+self.size.y/2,self.center.z+self.size.z/2,self.center.x-self.size.x/2,self.center.y+self.size.y/2,self.center.z+self.size.z/2,r,g,b,a)
    DrawLine(self.center.x-self.size.x/2,self.center.y+self.size.y/2,self.center.z+self.size.z/2,self.center.x-self.size.x/2,self.center.y-self.size.y/2,self.center.z+self.size.z/2,r,g,b,a)

    DrawLine(self.center.x-self.size.x/2,self.center.y-self.size.y/2,self.center.z-self.size.z/2,self.center.x-self.size.x/2,self.center.y-self.size.y/2,self.center.z+self.size.z/2,r,g,b,a)
    DrawLine(self.center.x+self.size.x/2,self.center.y-self.size.y/2,self.center.z-self.size.z/2,self.center.x+self.size.x/2,self.center.y-self.size.y/2,self.center.z+self.size.z/2,r,g,b,a)
    DrawLine(self.center.x+self.size.x/2,self.center.y+self.size.y/2,self.center.z-self.size.z/2,self.center.x+self.size.x/2,self.center.y+self.size.y/2,self.center.z+self.size.z/2,r,g,b,a)
    DrawLine(self.center.x-self.size.x/2,self.center.y+self.size.y/2,self.center.z-self.size.z/2,self.center.x-self.size.x/2,self.center.y+self.size.y/2,self.center.z+self.size.z/2,r,g,b,a)

    for i,v in pairs(self.points) do 
        DrawPixel(v,0.01,math.random(0,255),math.random(0,255),math.random(0,255),255)
    end
    
    if self.isdivided then
        self.topbox_lefttop:DrawGrids()
        self.topbox_righttop:DrawGrids()
        self.topbox_leftbottom:DrawGrids()
        self.topbox_rightbottom:DrawGrids()
        self.bottombox_lefttop:DrawGrids()
        self.bottombox_righttop:DrawGrids()
        self.bottombox_leftbottom:DrawGrids()
        self.bottombox_rightbottom:DrawGrids()
    end

end 

function OcTree:Debug(freezeZ)
    CreateThread(function()
        while true do
            self:DrawGrids(freezeZ)
            Wait(0)
        end
    end)
end

