local mapMinX, mapMinY, mapMaxX, mapMaxY = -3700, -4400, 4500, 8000
local mapMinZ, mapMaxZ = -8000, 8000

local mapCenter = vector3(mapMinX + (mapMaxX - mapMinX) / 2, mapMinY + (mapMaxY - mapMinY) / 2, mapMinZ + (mapMaxZ - mapMinZ) / 2)

--[[
local tree =  OcTree.new({
    center = mapCenter,
    game_center = vector3(mapMinX + (mapMaxX - mapMinX) / 2, mapMinY + (mapMaxY - mapMinY) / 2, mapMinZ),
    size = vector3(mapMaxX - mapMinX, mapMaxY - mapMinY, mapMaxZ - mapMinZ)
}, 4)
--]]

local pos = GetEntityCoords(PlayerPedId())
local tree =  OcTree.new({
    center = pos,
    game_center = pos,
    size = vector3(5.0,5.0,5.0)
}, 1)

for i=1,100 do 
    local x = GetRandomFloatInRange(-1.0, 1.0)
    local y = GetRandomFloatInRange(-1.0, 1.0)
    local z = GetRandomFloatInRange(-1.0, 1.0)
    print(x,y,z)
    tree:insert_point(pos+vector3(x,y,z))
end
--[[
for i=1,10000 do 
    local x = GetRandomFloatInRange(0, 10)
    local y = GetRandomFloatInRange(0, 10)
    local z = GetRandomFloatInRange(0, 10)
    tree:insert_object("circle?",{
        center = pos+vector3(x,y,z),
        size = vector3(1.0,1.0,1.0),
        whatisthat = "circle"..(i)
    })
end
--]]
print(tree)


tree:insert_point(pos+vector3(1.0,1.0,30.0))
print("point by point",#tree:query_points_by_point(pos+vector3(1.0,1.0,30.0),0.0))

print("point by circle",#tree:query_points_by_point(vector3(1.0,1.0,30.0),100000))

print("point by rectangle",#tree:query_points_by_box({
    center = vector3(222.0,4000.0,30.0),
    size = vector3(40000.0,40000.0,40000.0)
}))


print("object by point",#tree:query_objects_by_point("circle?",vector3(1.0,1.0,30.0),100000))

print("object by rectangle",#tree:query_objects_by_box("circle?",{
    center = vector3(222.0,1.0,30.0),
    size = vector3(40000.0,40000.0,40000.0)
}))


--tree:Debug()