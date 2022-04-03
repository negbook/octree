# Octree
Octree utilities for FiveM

## Installation
Set it as a dependency in you fxmanifest.lua
```
client_script '@octree/octree.lua'
```

## Usage
```
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
    center = mapCenter,
    game_center = mapCenter + vector3(0.0,0.0,-mapMaxZ),
    size = vector3(mapMaxX - mapMinX, mapMaxY - mapMinY, mapMaxZ - mapMinZ)
}, 1)

for i=1,1000 do 
    local x = GetRandomFloatInRange(-1.0, 1.0)
    local y = GetRandomFloatInRange(-1.0, 1.0)
    local z = GetRandomFloatInRange(-1.0, 1.0)
    print(x,y,z)
    tree:insert_point(pos+vector3(x,y,z))
end


print(tree)


tree:insert_point(pos+vector3(1.0,1.0,30.0))
print("point by point",#tree:query_points_by_point(pos+vector3(1.0,1.0,30.0),0.0))

print("point by circle",#tree:query_points_by_point(vector3(1.0,1.0,30.0),100000))

print("point by rectangle",#tree:query_points_by_box({
    center = vector3(222.0,4000.0,30.0),
    size = vector3(40000.0,40000.0,40000.0)
}))



tree:Debug()
```
