-- Original explorable temple/forest/training set. No downloaded models or textures.
local SagiriWorld={}
local wood=Color3.fromRGB(82,61,47)
local stone=Color3.fromRGB(83,99,99)
local dark=Color3.fromRGB(37,48,54)
local paper=Color3.fromRGB(221,207,172)
function SagiriWorld.build(parent,center,story)
    local folder=Instance.new("Model");folder.Name="MountSagiri";folder.Parent=parent
    local function part(name,size,pos,color,material,rotation)
        local p=Instance.new("Part");p.Name=name;p.Size=size;p.Anchored=true
        p.CFrame=CFrame.new(center+pos)*(rotation or CFrame.identity);p.Color=color
        p.Material=material or Enum.Material.WoodPlanks;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
        p.CanTouch=false;p.Parent=folder;return p
    end
    part("Ground",Vector3.new(380,4,380),Vector3.new(0,-2,0),Color3.fromRGB(65,85,73),Enum.Material.Grass)
    for _,side in ipairs({-1,1}) do
        local x=part("Boundary",Vector3.new(2,80,380),Vector3.new(side*191,35,0),dark);x.Transparency=1
        local z=part("Boundary",Vector3.new(380,80,2),Vector3.new(0,35,side*191),dark);z.Transparency=1
    end
    local function path(a,b,width)
        local p=part("ForestPath",Vector3.new(width or 12,0.12,(b-a).Magnitude+3),(a+b)/2+Vector3.new(0,0.1,0),Color3.fromRGB(131,125,105),Enum.Material.Ground)
        p.CFrame=CFrame.lookAt(center+(a+b)/2+Vector3.new(0,0.1,0),center+b);return p
    end
    local function lantern(pos)
        part("StoneLantern",Vector3.new(1.6,4,1.6),pos+Vector3.new(0,2,0),stone,Enum.Material.Slate)
        local glow=part("Lantern",Vector3.new(1.7,1.4,1.7),pos+Vector3.new(0,4.5,0),Color3.fromRGB(247,189,112),Enum.Material.Neon)
        local light=Instance.new("PointLight");light.Range=22;light.Brightness=1;light.Color=glow.Color;light.Parent=glow
        part("LanternCap",Vector3.new(2.4,0.5,2.4),pos+Vector3.new(0,5.5,0),stone,Enum.Material.Slate)
    end
    local function building(name,pos,width,depth,temple)
        part(name,Vector3.new(width,0.6,depth),pos+Vector3.new(0,0.3,0),wood)
        part("BackWall",Vector3.new(width,11,0.6),pos+Vector3.new(0,5.5,-depth/2),wood)
        for _,side in ipairs({-1,1}) do
            part("SideWall",Vector3.new(0.6,11,depth),pos+Vector3.new(side*width/2,5.5,0),wood)
            part("FrontWall",Vector3.new(width/2-5,11,0.6),pos+Vector3.new(side*(width/4+2.5),5.5,depth/2),wood)
            part("PaperScreen",Vector3.new(5,5,0.15),pos+Vector3.new(side*(width/4+2.5),6,depth/2+0.35),paper)
            for i=-2,2 do part("ScreenLattice",Vector3.new(0.12,5,0.2),pos+Vector3.new(side*(width/4+2.5)+i,6,depth/2+0.46),wood) end
            part("GabledRoof",Vector3.new(width/2+4,1,depth+7),pos+Vector3.new(side*width/4,13,0),dark,Enum.Material.Slate,CFrame.Angles(0,0,-side*0.27))
            part("PorchPillar",Vector3.new(0.8,11,0.8),pos+Vector3.new(side*(width/2-2),5.5,depth/2+2),wood)
        end
        part("Lintel",Vector3.new(11,2,1),pos+Vector3.new(0,10,depth/2),wood)
        part("Veranda",Vector3.new(width+2,0.5,5),pos+Vector3.new(0,0.25,depth/2+2),wood)
        part("Tatami",Vector3.new(width-3,0.1,depth-4),pos+Vector3.new(0,0.67,0),Color3.fromRGB(158,152,116),Enum.Material.Fabric)
        if temple then
            part("Altar",Vector3.new(8,2,3),pos+Vector3.new(0,1.7,-depth/2+4),dark)
            part("OfferingBowl",Vector3.new(1.5,0.6,1.5),pos+Vector3.new(0,3,-depth/2+4),Color3.fromRGB(176,150,101),Enum.Material.Metal)
            local scroll=part("HangingScroll",Vector3.new(5,6,0.15),pos+Vector3.new(0,7,-depth/2+0.4),paper,Enum.Material.Fabric)
            scroll.CanCollide=false
        else
            part("NezukoFuton",Vector3.new(5,0.3,7),pos+Vector3.new(-3,0.9,-3),Color3.fromRGB(156,139,159),Enum.Material.Fabric)
            part("Hearth",Vector3.new(4,0.2,4),pos+Vector3.new(6,0.8,2),dark,Enum.Material.Slate)
            part("TeaTable",Vector3.new(5,1,3),pos+Vector3.new(5,1.2,-5),wood)
        end
    end
    building("MountainTemple",Vector3.new(-112,0,40),34,28,true)
    building("UrokodakiHouse",Vector3.new(-48,0,88),30,26,false)
    path(Vector3.new(-140,0,130),Vector3.new(-112,0,63))
    path(Vector3.new(-112,0,63),Vector3.new(-48,0,107))
    path(Vector3.new(-48,0,107),Vector3.new(-15,0,70))
    path(Vector3.new(-15,0,70),Vector3.new(50,0,91))
    path(Vector3.new(50,0,91),Vector3.new(96,0,25))
    path(Vector3.new(96,0,25),Vector3.new(62,0,-36))
    path(Vector3.new(62,0,-36),Vector3.new(112,0,-43))
    for _,pos in ipairs({Vector3.new(-129,0,106),Vector3.new(-126,0,62),Vector3.new(-66,0,109),Vector3.new(34,0,93),Vector3.new(111,0,35),Vector3.new(75,0,-34)}) do lantern(pos) end
    local low,high=Vector3.new(-15,0,70),Vector3.new(-15,34,-110)
    local ramp=part("MountainCourse",Vector3.new(18,2,(high-low).Magnitude),(low+high)/2-Vector3.yAxis,stone,Enum.Material.Slate)
    ramp.CFrame=CFrame.lookAt(center+(low+high)/2-Vector3.yAxis,center+high-Vector3.yAxis)
    for z=-105,50,25 do
        local height=(70-z)*34/180-1.5
        part("RidgeRock",Vector3.new(34,height,22),Vector3.new(-15,height/2,z),stone,Enum.Material.Rock)
        for _,side in ipairs({-1,1}) do part("TrailPost",Vector3.new(0.5,2,0.5),Vector3.new(-15+side*8,height+2,z),wood) end
    end
    part("Summit",Vector3.new(29,3,25),Vector3.new(-15,32.5,-113),stone,Enum.Material.Slate)
    part("PracticeCourt",Vector3.new(32,0.15,32),Vector3.new(50,0.08,83),Color3.fromRGB(125,117,94),Enum.Material.Ground)
    part("SwordRack",Vector3.new(8,1,2),Vector3.new(40,2,87),wood)
    for i=1,4 do part("WoodenSword",Vector3.new(0.2,4,0.35),Vector3.new(36+i*1.5,3,87),Color3.fromRGB(179,144,97)) end
    for _,side in ipairs({-1,1}) do
        part("WaterfallCliff",Vector3.new(14,31,13),Vector3.new(96+side*17,15.5,12),stone,Enum.Material.Rock)
    end
    part("WaterfallCrest",Vector3.new(40,5,10),Vector3.new(96,29,11),stone,Enum.Material.Rock)
    local water=part("Waterfall",Vector3.new(21,27,1.1),Vector3.new(96,14,17),Color3.fromRGB(166,210,214),Enum.Material.Glass)
    water.Transparency=0.28;water.CanCollide=false
    local pool=part("ShallowPool",Vector3.new(27,0.2,24),Vector3.new(96,0.2,29),Color3.fromRGB(112,173,178),Enum.Material.Glass)
    pool.Transparency=0.3;pool.CanCollide=false
    for x=-8,8,4 do
        local ribbon=part("FallingWater",Vector3.new(0.8,26,0.2),Vector3.new(96+x,14,17.7),Color3.fromRGB(220,238,235),Enum.Material.Neon)
        ribbon.Transparency=0.65;ribbon.CanCollide=false
    end
    local boulder={}
    for _,side in ipairs({-1,1}) do
        local rock=part("BoulderHalf",Vector3.new(7,11,11),Vector3.new(112+side*3.5,5.5,-59),Color3.fromRGB(119,132,135),Enum.Material.Rock,CFrame.Angles(0,0,side*0.05))
        table.insert(boulder,{part=rock,closed=rock.CFrame,open=rock.CFrame*CFrame.new(side*4,0,0)*CFrame.Angles(0,side*0.12,0)})
    end
    local rope=part("BoulderRope",Vector3.new(15,0.35,11.5),Vector3.new(112,7,-59),Color3.fromRGB(169,149,102))
    rope.CanCollide=false
    local rng=Random.new(90318)
    for i=1,95 do
        local x,z=rng:NextNumber(-181,181),rng:NextNumber(-181,181)
        if math.abs(x+15)<30 or x< -70 and z>10 or x>20 and z> -85 and z<125 or x> -75 and x< -20 and z>60 then continue end
        local h=rng:NextNumber(18,31)
        part("Cedar",Vector3.new(1.6,h,1.6),Vector3.new(x,h/2,z),wood,Enum.Material.Wood)
        for j=1,3 do
            local canopy=part("CedarCrown",Vector3.new(13-j*2,8,13-j*2),Vector3.new(x,h-7+j*3,z),Color3.fromRGB(47,78,70),Enum.Material.Grass)
            canopy.Shape=Enum.PartType.Ball;canopy.CanCollide=false
        end
    end
    local anchors={}
    for name,coords in pairs(story.targets) do
        local p=part("Objective_"..name,Vector3.one,Vector3.new(table.unpack(coords)),paper)
        p.Transparency=1;p.CanCollide=false;p.CanQuery=false;anchors[name]=p
    end
    local hazards={}
    for _,definition in ipairs(story.hazards) do
        local pos=Vector3.new(table.unpack(definition.position))
        local surface=Vector3.new(pos.X,(70-pos.Z)*34/180+0.12,pos.Z)
        local warning=part("TrapWarning",Vector3.new(18,0.12,6),surface,Color3.fromRGB(202,167,89),Enum.Material.Neon,CFrame.Angles(math.atan(34/180),0,0))
        warning.CanCollide=false;warning.Transparency=0.85
        local log=part("SpringLog",Vector3.new(18,1,1),pos,wood,Enum.Material.Wood)
        log.CanCollide=false;log.Transparency=0.8
        table.insert(hazards,{definition=definition,warning=warning,log=log,origin=log.CFrame})
    end
    return {folder=folder,center=center,size=380,spawn=center+Vector3.new(-140,3,130),bossSpawn=center+Vector3.new(-112,3,49),anchors=anchors,hazards=hazards,boulder=boulder,boulderRope=rope}
end
return SagiriWorld
