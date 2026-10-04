-- Original compact city and hidden-house layouts; not a reconstruction of canonical geography.
local AsakusaWorld={}
function AsakusaWorld.build(parent,center,story)
    local clinic=story.map=="clinic"
    local folder=Instance.new("Model");folder.Name=clinic and "HiddenClinic" or "AsakusaStreets";folder.Parent=parent
    local wood=Color3.fromRGB(88,65,52);local roof=Color3.fromRGB(48,56,65)
    local function part(name,size,pos,color,material)
        local p=Instance.new("Part");p.Name=name;p.Size=size;p.Position=center+pos;p.Anchored=true;p.CanTouch=false
        p.Color=color;p.Material=material or Enum.Material.WoodPlanks
        p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=folder;return p
    end
    part("Ground",Vector3.new(320,4,320),Vector3.new(0,-2,0),clinic and Color3.fromRGB(106,127,98) or Color3.fromRGB(103,105,112),Enum.Material.Ground)
    for _,s in ipairs({-1,1}) do
        part("Boundary",Vector3.new(2,70,322),Vector3.new(s*161,32,0),roof).Transparency=1
        part("Boundary",Vector3.new(322,70,2),Vector3.new(0,32,s*161),roof).Transparency=1
    end
    local paths={}
    local function path(a,b,width)
        table.insert(paths,{a,b})
        local p=part("Walkway",Vector3.new(width or 14,0.12,(b-a).Magnitude),(a+b)/2,Color3.fromRGB(153,143,126),Enum.Material.Slate)
        p.CFrame=CFrame.lookAt(center+(a+b)/2,center+b)
    end
    local function sign(name,text,pos,size)
        local p=part(name,size or Vector3.new(15,3,0.2),pos,Color3.fromRGB(50,46,43))
        local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Front;gui.Parent=p
        local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
        label.Text=text;label.TextScaled=true;label.Font=Enum.Font.GothamMedium;label.TextColor3=Color3.fromRGB(255,225,173);label.Parent=gui
    end
    if clinic then
        path(Vector3.new(0,0.12,135),Vector3.new(0,0.12,-60),18)
        local house=Instance.new("Model");house.Name="TamayoHouse";house.Parent=folder
        local function piece(name,size,pos,color)
            local p=part(name,size,pos,color);p.Parent=house;return p
        end
        piece("Floor",Vector3.new(72,0.3,48),Vector3.new(0,0.15,-72),wood)
        piece("BackWall",Vector3.new(72,12,1),Vector3.new(0,6,-96),wood)
        for _,s in ipairs({-1,1}) do
            piece("SideWall",Vector3.new(1,12,48),Vector3.new(s*36,6,-72),wood)
            piece("FrontWall",Vector3.new(27,12,1),Vector3.new(s*22.5,6,-48),Color3.fromRGB(189,180,157))
            piece("GardenWall",Vector3.new(2,7,155),Vector3.new(s*94,3.5,-24),wood)
            for _,z in ipairs({40,-8,-114}) do
                part("GardenTree",Vector3.new(2,11,2),Vector3.new(s*62,5.5,z),wood)
                part("Canopy",Vector3.new(16,9,16),Vector3.new(s*62,14,z),Color3.fromRGB(75,115,91),Enum.Material.Grass)
            end
        end
        piece("DoorLintel",Vector3.new(18,3,1),Vector3.new(0,10.5,-48),wood)
        piece("Roof",Vector3.new(78,1.5,54),Vector3.new(0,12.4,-72),roof)
        for _,x in ipairs({-23,23}) do
            piece("PatientMat",Vector3.new(8,0.25,14),Vector3.new(x,0.5,-72),Color3.fromRGB(214,211,182))
        end
        piece("MedicineTable",Vector3.new(10,2.5,3),Vector3.new(0,1.5,-89),wood)
        for i=-3,3 do piece("MedicineBottle",Vector3.new(0.7,1.2,0.7),Vector3.new(i*1.1,3.3,-89),Color3.fromRGB(112,160,144)) end
        sign("ClinicSign","A place to heal",Vector3.new(0,8,-47.4))
    else
        path(Vector3.new(0,0.12,145),Vector3.new(0,0.12,-138),34)
        path(Vector3.new(0,0.12,75),Vector3.new(-27,0.12,75),12)
        path(Vector3.new(0,0.12,-40),Vector3.new(-87,0.12,-40),16)
        path(Vector3.new(-87,0.12,-40),Vector3.new(-87,0.12,-102),16)
        for _,x in ipairs({-58,58}) do
            for _,z in ipairs({102,30,-80}) do
                local facade=part("ShopBuilding",Vector3.new(42,25,42),Vector3.new(x,12.5,z),Color3.fromRGB(161,143,123))
                part("ShopRoof",Vector3.new(46,2,46),Vector3.new(x,26,z),roof)
                for _,dx in ipairs({-11,0,11}) do
                    local window=part("LitWindow",Vector3.new(7,6,0.2),Vector3.new(x+dx,16,z+21.1),Color3.fromRGB(255,210,137),Enum.Material.Neon)
                    window.CanCollide=false
                end
                sign("ShopSign",z==102 and "ASAKUSA" or z==30 and "TEA HOUSE" or "EVENING MARKET",facade.Position-center+Vector3.new(0,-6,21.2))
            end
        end
        part("NoodleCounter",Vector3.new(9,3,3),Vector3.new(-26,1.5,86),wood)
        part("NoodleAwning",Vector3.new(14,0.5,10),Vector3.new(-26,9,86),Color3.fromRGB(164,66,55))
        for _,x in ipairs({-32,-20}) do part("StallPost",Vector3.new(0.4,9,0.4),Vector3.new(x,4.5,89),wood) end
        sign("StallSign","NOODLES",Vector3.new(-26,7.5,91.1),Vector3.new(11,2,0.2))
        for i=0,2 do part("Bowl",Vector3.new(1,0.4,1),Vector3.new(-28+i*2,3.2,86),Color3.fromRGB(223,222,205),Enum.Material.SmoothPlastic) end
        for _,z in ipairs({123,67,0,-53,-124}) do
            for _,x in ipairs({-23,23}) do
                part("StreetLightPost",Vector3.new(0.5,11,0.5),Vector3.new(x,5.5,z),roof,Enum.Material.Metal)
                local lamp=part("ElectricLamp",Vector3.new(1.5,1.8,1.5),Vector3.new(x,11,z),Color3.fromRGB(255,222,160),Enum.Material.Neon)
                local light=Instance.new("PointLight");light.Color=lamp.Color;light.Range=30;light.Brightness=1;light.Parent=lamp
            end
        end
    end
    local anchors={}
    for id,coords in pairs(story.targets) do
        local p=part("Objective_"..id,Vector3.one,Vector3.new(table.unpack(coords)),wood)
        p.Transparency=1;p.CanCollide=false;p.CanQuery=false;anchors[id]=p
    end
    return {folder=folder,center=center,size=320,spawn=center+Vector3.new(0,3,135),bossSpawn=center+Vector3.new(0,3,-8),anchors=anchors,paths=paths}
end
return AsakusaWorld
