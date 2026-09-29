-- Original street/house layout and a separate, walkable interpretation of the swamp.
local TownWorld={}
function TownWorld.build(parent,center,story)
    local depths=story.map=="swamp"
    local folder=Instance.new("Model");folder.Name=depths and "SwampDepths" or "NorthwestTown";folder.Parent=parent
    local wood=Color3.fromRGB(97,70,57);local dark=Color3.fromRGB(46,54,64)
    local function part(name,size,pos,color,material)
        local p=Instance.new("Part");p.Name=name;p.Size=size;p.Position=center+pos;p.Anchored=true
        p.Color=color;p.Material=material or Enum.Material.WoodPlanks;p.CanTouch=false
        p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=folder;return p
    end
    part("Ground",Vector3.new(320,4,320),Vector3.new(0,-2,0),depths and Color3.fromRGB(31,52,54) or Color3.fromRGB(115,111,101),Enum.Material.Slate)
    for _,sign in ipairs({-1,1}) do
        local a=part("Boundary",Vector3.new(2,80,322),Vector3.new(sign*161,36,0),dark);a.Transparency=1
        local b=part("Boundary",Vector3.new(322,80,2),Vector3.new(0,36,sign*161),dark);b.Transparency=1
    end
    local paths={}
    local function path(a,b)
        table.insert(paths,{a,b})
        local p=part("Lane",Vector3.new(16,0.1,(b-a).Magnitude), (a+b)/2,Color3.fromRGB(147,137,121),Enum.Material.Ground)
        p.CFrame=CFrame.lookAt(center+(a+b)/2,center+b)
    end
    if depths then
        local water=part("SwampSurface",Vector3.new(310,0.08,310),Vector3.new(0,0.04,0),Color3.fromRGB(39,86,84),Enum.Material.Glass)
        water.Transparency=0.4;water.CanCollide=false;water.CanQuery=false
        for i=1,16 do
            local angle=i*math.pi/8
            part("SubmergedPillar",Vector3.new(5,21,5),Vector3.new(math.cos(angle)*85,10,math.sin(angle)*85),dark,Enum.Material.Rock)
        end
        path(Vector3.new(0,0.12,35),Vector3.new(0,0.12,-30))
    else
        path(Vector3.new(0,0.1,145),Vector3.new(0,0.1,-104))
        path(Vector3.new(0,0.1,30),Vector3.new(-12,0.1,30))
        path(Vector3.new(0,0.1,-36),Vector3.new(42,0.1,-36))
        path(Vector3.new(42,0.1,-36),Vector3.new(42,0.1,-68))
        local function house(name,x,z)
            local house=Instance.new("Model");house.Name=name;house.Parent=folder
            local function piece(n,size,offset,color)
                local p=part(n,size,Vector3.new(x,0,z)+offset,color);p.Parent=house;return p
            end
            piece("Floor",Vector3.new(32,0.25,28),Vector3.new(0,0.12,0),wood)
            piece("BackWall",Vector3.new(32,12,1),Vector3.new(0,6,-14),wood)
            for _,s in ipairs({-1,1}) do
                piece("SideWall",Vector3.new(1,12,28),Vector3.new(s*16,6,0),wood)
                piece("FrontWall",Vector3.new(11,12,1),Vector3.new(s*10.5,6,14),Color3.fromRGB(170,152,124))
            end
            piece("DoorLintel",Vector3.new(10,3,1),Vector3.new(0,10.5,14),wood)
            piece("Roof",Vector3.new(37,1.3,33),Vector3.new(0,12.4,0),dark)
            piece("SleepingMat",Vector3.new(5,0.12,7),Vector3.new(4,0.3,-3),Color3.fromRGB(189,176,132))
            piece("LowTable",Vector3.new(5,1.7,3),Vector3.new(-8,0.85,-6),wood)
        end
        for _,x in ipairs({-48,48}) do for _,z in ipairs({95,44}) do house("TownHouse",x,z) end end
        house("RescueHouse",42,-68);house("Storehouse",-55,-67)
        for _,z in ipairs({120,66,8,-34,-96}) do
            for _,x in ipairs({-21,21}) do
                part("LanternPost",Vector3.new(0.6,7,0.6),Vector3.new(x,3.5,z),wood)
                local p=part("PaperLantern",Vector3.new(1.8,2,1.8),Vector3.new(x,7,z),Color3.fromRGB(255,203,127),Enum.Material.Neon)
                local light=Instance.new("PointLight");light.Color=p.Color;light.Range=26;light.Brightness=1.2;light.Parent=p
            end
        end
        for i=1,4 do
            local p=part("ScentTrace",Vector3.new(0.7,0.08,1.5),Vector3.new(-12+i*3,0.13,30-i*12),Color3.fromRGB(124,188,179),Enum.Material.Neon)
            p.CanCollide=false;p.CanQuery=false
        end
        local pool=part("SwampEntrance",Vector3.new(11,0.14,11),Vector3.new(0,0.15,-80),Color3.fromRGB(22,49,50),Enum.Material.Glass)
        pool.CanCollide=false;pool.CanQuery=false
        local keepsake=part("LostKeepsake",Vector3.new(1.1,0.2,0.45),Vector3.new(12,0.3,-93),Color3.fromRGB(203,138,156))
        keepsake.CanCollide=false;keepsake.CanQuery=false
    end
    local anchors={}
    for id,coords in pairs(story.targets) do
        local p=part("Objective_"..id,Vector3.one,Vector3.new(table.unpack(coords)),wood)
        p.Transparency=1;p.CanCollide=false;p.CanQuery=false;anchors[id]=p
    end
    return {folder=folder,center=center,size=320,spawn=center+Vector3.new(0,3,135),bossSpawn=center+Vector3.new(0,3,-68),anchors=anchors,paths=paths}
end
return TownWorld
