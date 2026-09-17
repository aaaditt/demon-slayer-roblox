-- Original explorable mountain set; geometry is built locally, without asset IDs.
local StoryWorld = {}
local snow=Color3.fromRGB(221,231,237)
local wood=Color3.fromRGB(90,64,51)
local dark=Color3.fromRGB(47,52,62)
local warm=Color3.fromRGB(255,201,119)

function StoryWorld.build(parent,center,story)
    local folder=Instance.new("Model");folder.Name="KamadoMountain";folder.Parent=parent
    local function part(name,size,pos,color,material,rotation)
        local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.Size=size
        p.CFrame=CFrame.new(center+pos)*(rotation or CFrame.identity)
        p.Color=color;p.Material=material or Enum.Material.WoodPlanks
        p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.CanTouch=false;p.Parent=folder
        return p
    end
    part("Ground",Vector3.new(340,4,340),Vector3.new(0,-2,0),snow,Enum.Material.Snow)
    for _,x in ipairs({-171,171}) do
        local wall=part("Boundary",Vector3.new(2,80,342),Vector3.new(x,36,0),snow);wall.Transparency=1
        local back=part("Boundary",Vector3.new(342,80,2),Vector3.new(0,36,x),snow);back.Transparency=1
    end
    local function lamp(pos)
        part("LanternPost",Vector3.new(0.5,6,0.5),pos+Vector3.new(0,3,0),wood)
        local glow=part("PaperLantern",Vector3.new(1.6,1.6,1.6),pos+Vector3.new(0,6,0),warm,Enum.Material.Neon)
        local light=Instance.new("PointLight");light.Color=warm;light.Range=24;light.Brightness=1.1;light.Parent=glow
        part("LanternRoof",Vector3.new(2.3,0.5,2.3),pos+Vector3.new(0,7,0),dark)
    end
    local function house(name,pos,w,d)
        local h=10
        local floor=part(name,Vector3.new(w,0.6,d),pos+Vector3.new(0,0.3,0),wood)
        part("BackWall",Vector3.new(w,h,0.7),pos+Vector3.new(0,h/2,-d/2),wood)
        for _,side in ipairs({-1,1}) do
            part("SideWall",Vector3.new(0.7,h,d),pos+Vector3.new(side*w/2,h/2,0),wood)
            part("FrontWall",Vector3.new(w/2-4,h,0.7),pos+Vector3.new(side*(w/4+2),h/2,d/2),wood)
            part("PaperWindow",Vector3.new(6,4,0.2),pos+Vector3.new(side*(w/4+2),5.5,d/2+0.45),Color3.fromRGB(218,193,149))
            for bar=-2,2 do part("WindowLattice",Vector3.new(0.12,4,0.3),pos+Vector3.new(side*(w/4+2)+bar,5.5,d/2+0.6),dark) end
            part("SnowRoof",Vector3.new(w/2+3,1.1,d+5),pos+Vector3.new(side*w/4,h+2,0),snow,Enum.Material.Snow,CFrame.Angles(0,0,side*-0.28))
            part("VerandaPost",Vector3.new(0.6,h,0.6),pos+Vector3.new(side*(w/2-1),h/2,d/2+3),wood)
        end
        part("DoorLintel",Vector3.new(9,2,0.8),pos+Vector3.new(0,9,d/2),wood)
        part("Porch",Vector3.new(w+2,0.45,5),pos+Vector3.new(0,0.225,d/2+2),wood)
        part("Tatami",Vector3.new(w-4,0.15,d-5),pos+Vector3.new(0,0.7,-1),Color3.fromRGB(177,165,120),Enum.Material.Fabric)
        part("Hearth",Vector3.new(4,0.3,4),pos+Vector3.new(-w/4,0.9,0),dark,Enum.Material.Slate)
        local coals=part("Embers",Vector3.new(2,0.2,2),pos+Vector3.new(-w/4,1.1,0),Color3.fromRGB(225,99,44),Enum.Material.Neon)
        local light=Instance.new("PointLight");light.Color=warm;light.Brightness=1;light.Range=18;light.Parent=coals
        part("LowTable",Vector3.new(6,1.1,3),pos+Vector3.new(w/4,1.3,-3),wood)
        for i=1,3 do part("SleepingMat",Vector3.new(3,0.2,5),pos+Vector3.new(-w/2+5+i*4,0.9,-d/2+4),Color3.fromRGB(144,130,122),Enum.Material.Fabric) end
        return floor
    end
    house("KamadoHouse",Vector3.new(0,0,-123),32,27)
    house("SaburoShelter",Vector3.new(103,0,73),24,22)
    house("TownHouse",Vector3.new(-99,0,115),27,23)
    part("MarketCounter",Vector3.new(12,2.7,4),Vector3.new(-86,1.35,108),wood)
    for i=1,4 do part("CharcoalSack",Vector3.new(1.5,1.8,1.5),Vector3.new(-91+i*2,3.5,108),dark,Enum.Material.Fabric) end
    part("CharcoalBasket",Vector3.new(3,3,2.4),Vector3.new(10,1.7,-105),Color3.fromRGB(138,104,64))
    for i=1,6 do part("Charcoal",Vector3.new(0.6,1,0.7),Vector3.new(9+(i%3)*0.7,3.4,-105+math.floor(i/3)*0.6),dark,Enum.Material.Slate) end
    local route={Vector3.new(0,0,-99),Vector3.new(-28,0,-64),Vector3.new(12,0,17),Vector3.new(-40,0,64),Vector3.new(-84,0,103)}
    local function path(a,b)
        local delta=b-a
        local p=part("SnowTrail",Vector3.new(13,0.08,delta.Magnitude+4),(a+b)/2+Vector3.new(0,0.06,0),Color3.fromRGB(174,193,202),Enum.Material.Snow)
        p.CFrame=CFrame.lookAt(center+(a+b)/2+Vector3.new(0,0.06,0),center+b)
    end
    for i=1,#route-1 do path(route[i],route[i+1]);lamp(i==1 and Vector3.new(-18,0,-94) or route[i]+Vector3.new(9,0,0)) end
    path(route[4],Vector3.new(98,0,85));path(Vector3.new(98,0,85),Vector3.new(134,0,130))
    lamp(Vector3.new(89,0,88));lamp(Vector3.new(126,0,123));lamp(Vector3.new(-76,0,97))
    local rng=Random.new(932)
    for i=1,64 do
        local x,z=rng:NextNumber(-162,162),rng:NextNumber(-162,162)
        -- Preserve the central route and all building approaches.
        if math.abs(x)<43 or (z>55 and z<140) or z< -92 and math.abs(x)<28 then continue end
        local h=rng:NextNumber(15,25)
        part("CedarTrunk",Vector3.new(1.7,h,1.7),Vector3.new(x,h/2,z),wood,Enum.Material.Wood)
        for j=1,3 do
            local crown=part("SnowCedar",Vector3.new(12-j*2,7,12-j*2),Vector3.new(x,h-7+j*3,z),j==3 and snow or Color3.fromRGB(91,120,123),Enum.Material.Snow)
            crown.Shape=Enum.PartType.Ball;crown.CanCollide=false
        end
    end
    for i=1,18 do
        local angle=i*math.pi*2/18
        local mountain=part("MountainRidge",Vector3.new(75,80+(i%4)*16,65),Vector3.new(math.cos(angle)*220,22,math.sin(angle)*220),Color3.fromRGB(144,168,182),Enum.Material.Slate,CFrame.Angles(0,angle,0.25))
        mountain.CanCollide=false
    end
    local anchors={}
    for name,coords in pairs(story.targets) do
        local marker=part("Objective_"..name,Vector3.one,Vector3.new(table.unpack(coords)),warm)
        marker.Transparency=1;marker.CanCollide=false;marker.CanQuery=false
        anchors[name]=marker
    end
    return {folder=folder,center=center,size=340,spawn=center+Vector3.new(0,3,-93),bossSpawn=center+Vector3.new(12,3,17),anchors=anchors}
end
return StoryWorld
