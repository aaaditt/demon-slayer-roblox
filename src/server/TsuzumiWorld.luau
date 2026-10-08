-- Compact original mansion route. Horizontal quarter-turns are a gameplay adaptation.
local TsuzumiWorld={}
function TsuzumiWorld.build(parent,center,story)
    local folder=Instance.new("Model");folder.Name="TsuzumiMansion";folder.Parent=parent
    local wood=Color3.fromRGB(86,57,45);local plaster=Color3.fromRGB(188,171,136)
    local function part(name,size,pos,color,owner)
        local p=Instance.new("Part");p.Name=name;p.Size=size;p.Position=center+pos;p.Anchored=true;p.CanTouch=false
        p.Color=color or wood;p.Material=Enum.Material.WoodPlanks;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
        p.Parent=owner or folder;return p
    end
    part("Ground",Vector3.new(320,4,320),Vector3.new(0,-2,0),Color3.fromRGB(69,84,59)).Material=Enum.Material.Grass
    for _,side in ipairs({-1,1}) do
        part("Boundary",Vector3.new(2,70,322),Vector3.new(side*161,32,0)).Transparency=1
        part("Boundary",Vector3.new(322,70,2),Vector3.new(0,32,side*161)).Transparency=1
        for _,z in ipairs({-125,24,102}) do
            part("CedarTrunk",Vector3.new(3,22,3),Vector3.new(side*116,11,z))
            part("CedarCrown",Vector3.new(21,24,21),Vector3.new(side*116,27,z),Color3.fromRGB(41,67,54)).Material=Enum.Material.Grass
        end
    end
    local paths={}
    local function path(a,b)
        table.insert(paths,{a,b})
        local p=part("Path",Vector3.new(12,0.12,(b-a).Magnitude),(a+b)/2,Color3.fromRGB(139,123,100))
        p.CFrame=CFrame.lookAt(center+(a+b)/2,center+b)
    end
    path(Vector3.new(0,0.1,145),Vector3.new(0,0.1,-2))
    path(Vector3.new(0,0.1,45),Vector3.new(-22,0.1,45))
    path(Vector3.new(0,0.1,85),Vector3.new(85,0.1,85))
    path(Vector3.new(85,0.1,85),Vector3.new(85,0.1,76))
    table.insert(paths,{Vector3.new(0,0,2),Vector3.new(0,0,-48)})
    table.insert(paths,{Vector3.new(0,0,-48),Vector3.new(-63,0,-48)})
    table.insert(paths,{Vector3.new(85,0,90),Vector3.new(85,0,64)})
    local arena=Instance.new("Model");arena.Name="TurningRoom";arena.Parent=folder
    local pivot=center+Vector3.new(0,0,-48)
    part("TatamiFloor",Vector3.new(84,0.4,84),Vector3.new(0,0.2,-48),Color3.fromRGB(174,161,110),arena)
    for _,side in ipairs({-1,1}) do
        for _,offset in ipairs({-25,25}) do
            part("ShojiWall",Vector3.new(34,12,1),Vector3.new(offset,6,-48+side*42),plaster,arena)
            part("ShojiWall",Vector3.new(1,12,34),Vector3.new(side*42,6,-48+offset),plaster,arena)
        end
        part("DoorLintel",Vector3.new(16,3,1),Vector3.new(0,10.5,-48+side*42),wood,arena)
        part("DoorLintel",Vector3.new(1,3,16),Vector3.new(side*42,10.5,-48),wood,arena)
    end
    -- Distinct wall/floor patterns make the turn readable without obstructing the combat floor.
    for i=1,4 do
        local banner=part("DrumBanner_"..i,Vector3.new(7,6,0.2),Vector3.new(-30+(i-1)*20,7,-89.4),Color3.fromRGB(132+i*17,75+i*9,57),arena)
        banner.CanCollide=false
        local stripe=part("TatamiStripe",Vector3.new(1,0.04,64),Vector3.new(-30+(i-1)*20,0.43,-48),wood,arena);stripe.CanCollide=false
    end
    arena.WorldPivot=CFrame.new(pivot)
    -- The annex shelters the children and hosts the parallel-fight cutaways.
    part("AnnexFloor",Vector3.new(42,0.3,32),Vector3.new(-63,0.15,-48),plaster)
    part("AnnexBack",Vector3.new(42,12,1),Vector3.new(-63,6,-64),wood)
    part("AnnexSide",Vector3.new(1,12,32),Vector3.new(-84,6,-48),wood)
    part("AnnexFront",Vector3.new(42,12,1),Vector3.new(-63,6,-32),wood)
    local box=part("NezukoTravelBox",Vector3.new(2.7,3.6,2),Vector3.new(-22,1.8,45),Color3.fromRGB(111,77,51))
    box.Transparency=1;box.CanCollide=false
    part("ShadeTrunk",Vector3.new(3,18,3),Vector3.new(-31,9,45))
    part("ShadeCanopy",Vector3.new(25,12,25),Vector3.new(-31,21,45),Color3.fromRGB(61,92,64))
    -- Enterable original wisteria rest house, separate from the combat chamber.
    part("RestFloor",Vector3.new(40,0.3,30),Vector3.new(85,0.15,60),plaster)
    part("RestBack",Vector3.new(40,10,1),Vector3.new(85,5,45))
    for _,side in ipairs({-1,1}) do
        part("RestSide",Vector3.new(1,10,30),Vector3.new(85+side*20,5,60))
        part("RestFront",Vector3.new(13,10,1),Vector3.new(85+side*13.5,5,75),plaster)
        part("WisteriaCrown",Vector3.new(12,7,12),Vector3.new(85+side*26,12,70),Color3.fromRGB(169,131,207)).CanCollide=false
    end
    part("RestRoof",Vector3.new(44,1,34),Vector3.new(85,11,60),Color3.fromRGB(47,45,59))
    local anchors={}
    for id,coords in pairs(story.targets) do
        local p=part("Objective_"..id,Vector3.one,Vector3.new(table.unpack(coords)))
        p.Transparency=1;p.CanCollide=false;p.CanQuery=false;anchors[id]=p
    end
    return {folder=folder,center=center,size=320,spawn=center+Vector3.new(0,3,135),bossSpawn=pivot+Vector3.yAxis*3,
        anchors=anchors,paths=paths,arena=arena,arenaBase=CFrame.new(pivot)}
end
return TsuzumiWorld
