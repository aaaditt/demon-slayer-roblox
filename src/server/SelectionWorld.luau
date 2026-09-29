-- Original compact Fujikasane geography; no external assets.
local SelectionWorld={}
function SelectionWorld.build(parent,center,story)
    local folder=Instance.new("Model");folder.Name="Fujikasane";folder.Parent=parent
    local wood=Color3.fromRGB(76,62,61)
    local function part(name,size,pos,color,material,cf)
        local p=Instance.new("Part");p.Name=name;p.Size=size;p.Anchored=true
        p.CFrame=CFrame.new(center+pos)*(cf or CFrame.identity);p.Color=color;p.Material=material or Enum.Material.Wood
        p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.CanTouch=false;p.Parent=folder;return p
    end
    part("Ground",Vector3.new(380,4,380),Vector3.new(0,-2,0),Color3.fromRGB(52,69,66),Enum.Material.Grass)
    for _,side in ipairs({-1,1}) do
        local a=part("Boundary",Vector3.new(2,80,380),Vector3.new(side*191,35,0),wood);a.Transparency=1
        local b=part("Boundary",Vector3.new(380,80,2),Vector3.new(0,35,side*191),wood);b.Transparency=1
    end
    local function path(a,b,width)
        local p=part("MountainPath",Vector3.new(width or 13,0.15,(b-a).Magnitude+2),(a+b)/2+Vector3.yAxis*0.1,Color3.fromRGB(119,118,106),Enum.Material.Ground)
        p.CFrame=CFrame.lookAt(center+(a+b)/2+Vector3.yAxis*0.1,center+b+Vector3.yAxis*0.1)
    end
    local paths={
        {Vector3.new(0,0,170),Vector3.new(0,0,115)},
        {Vector3.new(0,0,115),Vector3.new(-42,0,58)},
        {Vector3.new(-42,0,58),Vector3.new(43,0,-10)},
        {Vector3.new(43,0,-10),Vector3.new(65,0,-52)},
        {Vector3.new(65,0,-52),Vector3.new(-54,0,-40)},
        {Vector3.new(-54,0,-40),Vector3.new(-89,0,-62)},
        {Vector3.new(-89,0,-62),Vector3.new(-65,0,-112)},
        {Vector3.new(-65,0,-112),Vector3.new(-4,0,-104)},
        {Vector3.new(-4,0,-104),Vector3.new(8,0,99)},
    }
    for _,pair in ipairs(paths) do path(pair[1],pair[2]) end
    part("GatheringCourt",Vector3.new(88,0.2,52),Vector3.new(0,0.1,139),Color3.fromRGB(148,135,160),Enum.Material.Slate)
    part("BossClearing",Vector3.new(72,0.15,76),Vector3.new(65,0.09,-63),Color3.fromRGB(100,109,100),Enum.Material.Ground)
    for _,side in ipairs({-1,1}) do
        part("GatePost",Vector3.new(2,16,2),Vector3.new(side*15,8,111),wood)
        part("StoneLantern",Vector3.new(2,4,2),Vector3.new(side*23,2,112),Color3.fromRGB(108,112,125),Enum.Material.Slate)
        local glow=part("LanternLight",Vector3.new(2.1,1.6,2.1),Vector3.new(side*23,4.8,112),Color3.fromRGB(226,191,245),Enum.Material.Neon)
        local light=Instance.new("PointLight");light.Color=glow.Color;light.Brightness=1.1;light.Range=23;light.Parent=glow
    end
    part("GateLintel",Vector3.new(38,2,3),Vector3.new(0,16,111),wood)
    local rng=Random.new(91926)
    local function tree(x,z,wisteria)
        local height=wisteria and 16 or rng:NextNumber(19,30)
        part("TreeTrunk",Vector3.new(1.8,height,1.8),Vector3.new(x,height/2,z),wood)
        local crown=part(wisteria and "WisteriaCrown" or "CedarCrown",Vector3.new(13,8,13),Vector3.new(x,height,z),wisteria and Color3.fromRGB(142,108,186) or Color3.fromRGB(43,67,67),Enum.Material.Grass)
        crown.Shape=Enum.PartType.Ball;crown.CanCollide=false
        if wisteria then
            for i=1,6 do
                local angle=i*math.pi/3
                local blossom=part("HangingBlossoms",Vector3.new(1.6,6,1.6),Vector3.new(x+math.cos(angle)*4,height-5,z+math.sin(angle)*4),Color3.fromRGB(188,147+i*3,219),Enum.Material.SmoothPlastic)
                blossom.Shape=Enum.PartType.Ball;blossom.CanCollide=false
            end
        end
    end
    for _,x in ipairs({-60,-42,42,60}) do for _,z in ipairs({106,132,162}) do tree(x,z,true) end end
    local function distanceToPath(point,a,b)
        local delta=b-a
        local t=math.clamp((point-a):Dot(delta)/delta:Dot(delta),0,1)
        return (point-(a+delta*t)).Magnitude
    end
    for _=1,95 do
        local x,z=rng:NextNumber(-180,180),rng:NextNumber(-178,94)
        local point=Vector3.new(x,0,z)
        local blocked=(point-Vector3.new(65,0,-63)).Magnitude<48 or (point-Vector3.new(-42,0,58)).Magnitude<34
        for _,pair in ipairs(paths) do if distanceToPath(point,pair[1],pair[2])<16 then blocked=true end end
        for _,id in ipairs({"camp","watch_one","watch_two","watch_three"}) do
            local coords=story.targets[id]
            if (point-Vector3.new(coords[1],0,coords[3])).Magnitude<22 then blocked=true end
        end
        if blocked then continue end
        tree(x,z,false)
    end
    for _,pos in ipairs({Vector3.new(-70,0,24),Vector3.new(30,0,40),Vector3.new(-119,0,-29),Vector3.new(125,0,-96)}) do
        local rock=part("ForestRock",Vector3.new(13,9,11),pos+Vector3.yAxis*3,Color3.fromRGB(91,103,108),Enum.Material.Rock)
        rock.Shape=Enum.PartType.Ball
    end
    part("FallenCedar",Vector3.new(20,3,3),Vector3.new(-67,1.5,-28),wood)
    part("OreTable",Vector3.new(12,2,5),Vector3.new(22,1,105),wood)
    for i=-1,1 do
        local ore=part(i==0 and "ChosenOre" or "NichirinOre",Vector3.new(2.4,1.6,2),Vector3.new(22+i*3.3,2.8,105),Color3.fromRGB(91+i*13,96,111-i*9),Enum.Material.Slate)
        ore.Shape=Enum.PartType.Ball
    end
    part("CrowPerch",Vector3.new(0.5,6,0.5),Vector3.new(38,3,118),wood)
    local bird=part("KasugaiCrow",Vector3.new(1,0.8,1.8),Vector3.new(38,6.6,118),Color3.fromRGB(27,29,38));bird.Shape=Enum.PartType.Ball;bird.CanCollide=false
    part("CrowHead",Vector3.new(0.7,0.7,0.7),Vector3.new(38,7,117.2),bird.Color).CanCollide=false
    part("CrowBeak",Vector3.new(0.3,0.2,0.6),Vector3.new(38,6.9,116.7),Color3.fromRGB(93,88,68)).CanCollide=false
    local anchors={}
    for id,coords in pairs(story.targets) do
        local anchor=part("Objective_"..id,Vector3.one,Vector3.new(table.unpack(coords)),wood)
        anchor.Transparency=1;anchor.CanCollide=false;anchor.CanQuery=false;anchors[id]=anchor
    end
    return {folder=folder,center=center,size=380,spawn=center+Vector3.new(0,3,156),anchors=anchors,paths=paths,bossSpawn=center+Vector3.new(65,4.5,-68)}
end
return SelectionWorld
