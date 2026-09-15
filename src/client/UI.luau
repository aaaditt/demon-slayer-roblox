local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Content=require(ReplicatedStorage:WaitForChild("Shared").Content)
local UI={}
UI.__index=UI
local palette={bg=Color3.fromRGB(14,19,31),panel=Color3.fromRGB(23,29,44),card=Color3.fromRGB(32,39,55),text=Color3.fromRGB(243,235,219),muted=Color3.fromRGB(158,171,189),gold=Color3.fromRGB(229,184,112),line=Color3.fromRGB(64,69,84),teal=Color3.fromRGB(103,201,185)}

local function make(class,parent,props)
    local item=Instance.new(class)
    for k,v in pairs(props or {}) do item[k]=v end
    item.Parent=parent
    return item
end
local function corner(item,radius) make("UICorner",item,{CornerRadius=UDim.new(0,radius or 8)}) end
local function stroke(item,color) make("UIStroke",item,{Color=color or palette.line,Thickness=1,Transparency=0.2}) end
local function label(parent,text,size,position,textSize,color)
    return make("TextLabel",parent,{Text=text,Size=size,Position=position or UDim2.new(),BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=textSize or 14,TextColor3=color or palette.text,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextWrapped=true})
end
local function button(parent,text,size,position,callback,accent)
    local item=make("TextButton",parent,{Text=text,Size=size,Position=position or UDim2.new(),BackgroundColor3=accent and palette.gold or palette.card,BorderSizePixel=0,AutoButtonColor=true,Font=Enum.Font.GothamMedium,TextSize=13,TextColor3=accent and palette.bg or palette.text,TextWrapped=true})
    corner(item,7)
    item.Activated:Connect(callback)
    return item
end
local function scroll(parent,size,position)
    local item=make("ScrollingFrame",parent,{Size=size,Position=position,BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=palette.gold,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y})
    make("UIListLayout",item,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
    make("UIPadding",item,{PaddingRight=UDim.new(0,6),PaddingBottom=UDim.new(0,12)})
    return item
end
local function clear(frame)
    for _,child in ipairs(frame:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end
    end
end

function UI.new(send,effects)
    local self=setmetatable({send=send,effects=effects,tab="Journey",selected="tanjiro",equipSlot=1,filter="",category="All",state=nil,toastToken=0},UI)
    local gui=make("ScreenGui",Players.LocalPlayer:WaitForChild("PlayerGui"),{Name="WisteriaUI",ResetOnSpawn=false,IgnoreGuiInset=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
    self.gui=gui
    self.top=make("Frame",gui,{Size=UDim2.new(1,-28,0,58),Position=UDim2.fromOffset(14,10),BackgroundColor3=palette.bg,BackgroundTransparency=0.12,BorderSizePixel=0});corner(self.top)
    label(self.top,"WISTERIA  /  CHRONICLES",UDim2.new(0.55,-10,0,22),UDim2.fromOffset(16,7),15,palette.gold)
    self.location=label(self.top,"Connecting to the courtyard…",UDim2.new(0.68,-20,0,19),UDim2.fromOffset(16,30),12,palette.muted)
    self.menuButton=button(self.top,"MENU  [M]",UDim2.new(0.2,0,0,34),UDim2.new(0.79,0,0,12),function() self:toggle() end)
    self.status=make("Frame",gui,{Size=UDim2.new(0.32,40,0,83),Position=UDim2.new(0,14,1,-185),BackgroundColor3=palette.bg,BackgroundTransparency=0.12,BorderSizePixel=0});corner(self.status)
    self.name=label(self.status,"Tanjiro Kamado",UDim2.new(1,-20,0,22),UDim2.fromOffset(10,6),14)
    local hpbg=make("Frame",self.status,{Size=UDim2.new(1,-20,0,8),Position=UDim2.fromOffset(10,34),BackgroundColor3=palette.card,BorderSizePixel=0});corner(hpbg,4)
    self.hp=make("Frame",hpbg,{Size=UDim2.fromScale(1,1),BackgroundColor3=palette.teal,BorderSizePixel=0});corner(self.hp,4)
    local enbg=make("Frame",self.status,{Size=UDim2.new(1,-20,0,5),Position=UDim2.fromOffset(10,49),BackgroundColor3=palette.card,BorderSizePixel=0});corner(enbg,3)
    self.energy=make("Frame",enbg,{Size=UDim2.fromScale(1,1),BackgroundColor3=palette.gold,BorderSizePixel=0});corner(self.energy,3)
    self.stats=label(self.status,"160 HP  /  100 ENERGY",UDim2.new(1,-20,0,18),UDim2.fromOffset(10,60),11,palette.muted)
    self.skillbar=make("Frame",gui,{Size=UDim2.new(0.68,0,0,74),Position=UDim2.new(0.5,0,1,-89),AnchorPoint=Vector2.new(0.5,0),BackgroundTransparency=1})
    self.skillButtons={}
    for i=1,4 do
        local b=button(self.skillbar,tostring(i),UDim2.new(0.25,-5,1,0),UDim2.new((i-1)*0.25,2,0,0),function() if self.onSkill then self.onSkill(i) end end)
        b.TextSize=12;stroke(b)
        self.skillButtons[i]=b
    end
    self.hint=label(gui,"LMB attack   •   1–4 techniques   •   F guard/parry   •   Q dodge",UDim2.new(0.9,0,0,22),UDim2.new(0.05,0,1,-25),11,palette.muted)
    self.hint.TextXAlignment=Enum.TextXAlignment.Center
    self.toastFrame=make("Frame",gui,{Size=UDim2.new(0.72,0,0,60),Position=UDim2.new(0.5,0,0,80),AnchorPoint=Vector2.new(0.5,0),BackgroundColor3=palette.bg,BackgroundTransparency=0.04,BorderSizePixel=0,Visible=false,ZIndex=20});corner(self.toastFrame);stroke(self.toastFrame,palette.gold)
    self.toastLabel=label(self.toastFrame,"",UDim2.new(1,-28,1,-12),UDim2.fromOffset(14,6),15);self.toastLabel.ZIndex=21;self.toastLabel.TextXAlignment=Enum.TextXAlignment.Center

    self.shade=make("Frame",gui,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(),BackgroundTransparency=0.38,BorderSizePixel=0,Visible=true,ZIndex=5})
    self.panel=make("Frame",self.shade,{Size=UDim2.fromScale(0.94,0.83),Position=UDim2.fromScale(0.5,0.52),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=palette.bg,BorderSizePixel=0,ZIndex=6});corner(self.panel,12);stroke(self.panel)
    make("UISizeConstraint",self.panel,{MaxSize=Vector2.new(1120,730)})
    self.heading=label(self.panel,"YOUR NEXT CHAPTER",UDim2.new(0.8,-24,0,31),UDim2.fromOffset(20,12),18,palette.gold)
    button(self.panel,"×",UDim2.fromOffset(36,34),UDim2.new(1,-50,0,12),function() self:toggle(false) end)
    local nav=make("Frame",self.panel,{Size=UDim2.new(1,-32,0,36),Position=UDim2.fromOffset(16,53),BackgroundTransparency=1})
    for i,tab in ipairs({"Journey","Characters","Techniques","Codex","Settings"}) do
        button(nav,tab,UDim2.new(0.2,-4,1,0),UDim2.new((i-1)*0.2,2,0,0),function() self.tab=tab;self:render() end)
    end
    self.body=make("Frame",self.panel,{Size=UDim2.new(1,-32,1,-111),Position=UDim2.fromOffset(16,101),BackgroundTransparency=1})
    self:render()
    RunService.RenderStepped:Connect(function()
        if not self.state then return end
        local now=workspace:GetServerTimeNow()
        for i,b in ipairs(self.skillButtons) do
            local id=self.state.loadout[i]
            local move=Content.moves[id]
            if move then
                local remaining=math.max(0,(self.state.cooldowns[id] or 0)-now)
                b.Text=tostring(i).."   "..(remaining>0 and string.format("%.1fs",remaining) or tostring(move.cost).." EN").."\n"..move.name
                b.BackgroundColor3=remaining>0 and palette.bg or palette.card
                b.TextColor3=remaining>0 and palette.muted or palette.text
            end
        end
    end)
    return self
end

function UI:toggle(value)
    if value==nil then value=not self.shade.Visible end
    self.shade.Visible=value
    if value then self:render() end
    if self.onMenu then self.onMenu(value) end
end

function UI:toast(text)
    self.toastToken+=1
    local token=self.toastToken
    self.toastLabel.Text=text;self.toastFrame.Visible=true
    task.delay(3.5,function() if self.toastToken==token then self.toastFrame.Visible=false end end)
end

function UI:update(state)
    if state.kind=="toast" then self:toast(state.text);return end
    local changed=not self.state or self.state.selected~=state.selected or self.state.chapter~=state.chapter or self.state.mode~=state.mode or table.concat(self.state.loadout,"|")~=table.concat(state.loadout,"|")
    self.state=state
    self.name.Text=Content.characters[state.selected].name
    self.hp.Size=UDim2.fromScale(math.clamp(state.hp/state.maxHp,0,1),1)
    self.energy.Size=UDim2.fromScale(math.clamp(state.energy/state.maxEnergy,0,1),1)
    self.stats.Text=string.format("%d HP  /  %d ENERGY",math.ceil(state.hp),math.floor(state.energy))
    self.location.Text=state.mode.."  ·  "..state.rank.."  ·  "..state.xp.." XP"
    if state.mission then
        self.location.Text=Content.chapters[state.mission.index].name.."  ·  Encounter "..state.mission.wave.."/"..state.mission.total
    elseif state.mode=="Arena" then
        local seconds=math.max(0,math.ceil(state.round.ends-state.time))
        self.location.Text=state.round.active and ("ARENA  ·  "..seconds.."s  ·  "..(#state.round.leaderboard>0 and state.round.leaderboard[1].name.." "..state.round.leaderboard[1].score or "")) or "ARENA  ·  Waiting for two players"
    end
    if changed and self.shade.Visible then self:render() end
end

function UI:renderJourney()
    local s=self.state
    local list=scroll(self.body,UDim2.fromScale(1,1),UDim2.new())
    local hero=make("Frame",list,{Size=UDim2.new(1,-2,0,158),BackgroundColor3=palette.panel,BorderSizePixel=0,LayoutOrder=0});corner(hero);stroke(hero,palette.gold)
    local chapter=Content.chapters[math.min(s and s.chapter or 1,#Content.chapters)]
    label(hero,"A LONG NIGHT. A NEW PATH.",UDim2.new(1,-28,0,22),UDim2.fromOffset(14,10),12,palette.gold)
    label(hero,chapter.name,UDim2.new(1,-28,0,32),UDim2.fromOffset(14,35),24)
    label(hero,chapter.objective,UDim2.new(1,-28,0,38),UDim2.fromOffset(14,69),13,palette.muted)
    button(hero,"PLAY STORY",UDim2.new(0.45,-16,0,33),UDim2.fromOffset(14,116),function() self.send("Story",chapter.index);self:toggle(false) end,true)
    button(hero,s and s.mode~="Hub" and "RETURN TO HUB" or "JOIN PVP",UDim2.new(0.55,-24,0,33),UDim2.new(0.45,10,0,116),function() self.send(s and s.mode~="Hub" and "Hub" or "Arena");self:toggle(false) end)
    for _,c in ipairs(Content.chapters) do
        local unlocked=not s and c.index==1 or s and c.index<=s.chapter
        local card=make("Frame",list,{Size=UDim2.new(1,-2,0,74),BackgroundColor3=palette.card,BorderSizePixel=0,LayoutOrder=c.index});corner(card)
        label(card,string.format("%02d",c.index),UDim2.fromOffset(30,50),UDim2.fromOffset(12,10),20,unlocked and palette.gold or palette.muted)
        label(card,c.name,UDim2.new(0.72,-60,0,29),UDim2.fromOffset(50,8),15,unlocked and palette.text or palette.muted)
        label(card,Content.locations[c.location].name..(c.spoiler and "  ·  LATER STORY" or ""),UDim2.new(0.75,-60,0,30),UDim2.fromOffset(50,36),11,palette.muted)
        local b=button(card,unlocked and "PLAY" or "LOCKED",UDim2.new(0.23,0,0,34),UDim2.new(0.76,-6,0,20),function()
            if unlocked then self.send("Story",c.index);self:toggle(false) else self:toast("Complete the previous chapter first.") end
        end)
        b.TextSize=11
    end
end

function UI:renderCharacters()
    local search=make("TextBox",self.body,{Size=UDim2.new(1,0,0,36),PlaceholderText="Search character or style…",Text=self.filter,ClearTextOnFocus=false,BackgroundColor3=palette.card,BorderSizePixel=0,TextColor3=palette.text,PlaceholderColor3=palette.muted,Font=Enum.Font.Gotham,TextSize=14});corner(search)
    local list=scroll(self.body,UDim2.new(0.43,-6,1,-48),UDim2.fromOffset(0,48))
    local detail=scroll(self.body,UDim2.new(0.57,-6,1,-48),UDim2.new(0.43,6,0,48))
    local function showDetails(id)
        self.selected=id;clear(detail)
        local c=Content.characters[id]
        local accent=Color3.fromRGB(table.unpack(c.color))
        local banner=make("Frame",detail,{Size=UDim2.new(1,-2,0,148),BackgroundColor3=palette.panel,BorderSizePixel=0});corner(banner);stroke(banner,accent)
        label(banner,c.name,UDim2.new(1,-24,0,62),UDim2.fromOffset(12,7),22,accent)
        label(banner,c.title.."\n"..#c.moves.." techniques",UDim2.new(1,-24,0,37),UDim2.fromOffset(12,67),13,palette.muted)
        button(banner,self.state and self.state.selected==id and "SELECTED" or "SELECT CHARACTER",UDim2.new(1,-24,0,32),UDim2.fromOffset(12,108),function()
            if self.state and self.state.mode~="Hub" then self:toast("Return to the courtyard to change character.");return end
            self.send("Select",id)
        end,true)
        local note=label(detail,c.note,UDim2.new(1,-4,0,75),nil,12,palette.muted)
        note.LayoutOrder=1
        for i,mid in ipairs(c.moves) do
            local m=Content.moves[mid]
            local row=make("Frame",detail,{Size=UDim2.new(1,-2,0,60),BackgroundColor3=palette.card,BorderSizePixel=0,LayoutOrder=i+1});corner(row)
            label(row,m.name,UDim2.new(1,-20,0,34),UDim2.fromOffset(10,3),13)
            label(row,m.pattern.."  ·  "..m.cost.." energy"..(m.spoiler and "  ·  later story" or ""),UDim2.new(1,-20,0,20),UDim2.fromOffset(10,36),10,palette.muted)
        end
    end
    local function populate()
        clear(list)
        local query=string.lower(search.Text)
        local roster={}
        for _,c in pairs(Content.characters) do if c.playable then table.insert(roster,c) end end
        table.sort(roster,function(a,b) return a.group==b.group and a.name<b.name or a.group<b.group end)
        for i,c in ipairs(roster) do
            if query=="" or string.find(string.lower(c.name.." "..c.title),query,1,true) then
                local b=button(list,c.name.."\n"..c.title,UDim2.new(1,-2,0,62),nil,function() showDetails(c.id) end)
                b.LayoutOrder=i;b.TextSize=12
                if self.state and c.id==self.state.selected then stroke(b,palette.gold) end
            end
        end
    end
    search:GetPropertyChangedSignal("Text"):Connect(function() self.filter=search.Text;populate() end)
    populate();showDetails(self.selected)
end

function UI:renderTechniques()
    local selected=self.state and self.state.selected or "tanjiro"
    local c=Content.characters[selected]
    local list=scroll(self.body,UDim2.fromScale(1,1),UDim2.new())
    local slots=make("Frame",list,{Size=UDim2.new(1,0,0,72),BackgroundTransparency=1,LayoutOrder=0})
    for i=1,4 do
        local id=self.state and self.state.loadout[i] or c.loadout[i]
        local b=button(slots,tostring(i).."  "..Content.moves[id].name,UDim2.new(0.25,-5,1,0),UDim2.new((i-1)*0.25,0,0,0),function() self.equipSlot=i;self:render() end,self.equipSlot==i)
        b.TextSize=12
    end
    local help=label(list,"Select a slot above, then equip a technique below. Duplicate moves swap slots. Loadouts can be changed in the courtyard.",UDim2.new(1,-8,0,46),nil,12,palette.muted);help.LayoutOrder=1
    for i,id in ipairs(c.moves) do
        local m=Content.moves[id]
        local card=make("Frame",list,{Size=UDim2.new(1,-2,0,87),BackgroundColor3=palette.card,BorderSizePixel=0,LayoutOrder=i+1});corner(card)
        label(card,m.name,UDim2.new(0.76,-18,0,38),UDim2.fromOffset(12,5),15)
        label(card,m.damage.." damage  /  "..m.cost.." energy  /  "..m.cooldown.."s\n"..m.canon..(m.spoiler and " · later story" or "").." · "..m.status,UDim2.new(0.76,-18,0,38),UDim2.fromOffset(12,44),11,palette.muted)
        button(card,"EQUIP "..self.equipSlot,UDim2.new(0.23,-8,0,36),UDim2.new(0.77,0,0,24),function()
            if self.state and self.state.mode~="Hub" then self:toast("Return to the courtyard to edit your loadout.");return end
            self.send("Equip",{slot=self.equipSlot,move=id})
        end,true)
    end
end

function UI:renderCodex()
    local list=scroll(self.body,UDim2.fromScale(1,1),UDim2.new())
    local text="THE CORPS ARCHIVE\n\n44 selectable characters · 210 techniques · 22 chapters\n\nCombat\nWatch the red outline before an enemy's attack. Dodge out of the marked area or face the attack and guard. Raise guard just before impact to parry. Your energy recovers while you are free to act.\n\nCampaign\nComplete chapters to unlock the next encounter and earn rank. Every playable character is available from the start. Campaign XP does not increase PvP damage or health.\n\nArena\nTwo players begin a three-minute round. Reach five eliminations, or finish with the highest score. A tied score draws. Leave through Journey after five seconds out of combat.\n\nThe archive labels later-story material. Original and descriptive ability names distinguish adaptations from named canon techniques. Lower Moons whose arts were never revealed use original demon fundamentals.\n\nWORLD ATLAS\n"
    local locations={}
    for _,l in pairs(Content.locations) do table.insert(locations,l) end
    table.sort(locations,function(a,b)return a.name<b.name end)
    for _,l in ipairs(locations) do text..="\n"..l.name.."\n"..l.description.."\n" end
    text..="\nUNREVEALED FORMS\n"
    for _,note in ipairs(Content.unknowns) do text..="\n• "..note.."\n" end
    local t=label(list,text,UDim2.new(1,-12,0,0),nil,14,palette.muted)
    t.AutomaticSize=Enum.AutomaticSize.Y;t.TextYAlignment=Enum.TextYAlignment.Top
end

function UI:renderSettings()
    local list=scroll(self.body,UDim2.fromScale(1,1),UDim2.new())
    button(list,self.effects.reduced and "REDUCED EFFECTS: ON" or "REDUCED EFFECTS: OFF",UDim2.new(1,-4,0,48),nil,function() self.effects.reduced=not self.effects.reduced;self:render() end)
    local save=self.state and self.state.saveStatus or "Connecting…"
    local t=label(list,"CONTROLS\n\nKeyboard: WASD move · Space jump\nMouse 1 attack · 1–4 techniques\nF hold guard · Q dodge · M menu\n\nController: right trigger attack\nX / Y / B / left bumper: techniques\nLeft trigger guard · right bumper dodge\nD-pad up: menu\n\nTouch: tap technique cards; use Attack, Guard and Dodge buttons. The default Roblox thumbstick and jump button control movement.\n\nPROGRESSION\n\n"..save.."\n\nRank and character mastery track campaign progress. PvP uses equal health and energy.\n\nUse the Roblox reset option to respawn if stuck.",UDim2.new(1,-12,0,0),nil,14,palette.muted)
    t.AutomaticSize=Enum.AutomaticSize.Y;t.TextYAlignment=Enum.TextYAlignment.Top;t.LayoutOrder=2
end

function UI:render()
    clear(self.body)
    self.heading.Text=string.upper(self.tab).."  /  WISTERIA CHRONICLES"
    if self.tab=="Journey" then self:renderJourney()
    elseif self.tab=="Characters" then self:renderCharacters()
    elseif self.tab=="Techniques" then self:renderTechniques()
    elseif self.tab=="Codex" then self:renderCodex()
    else self:renderSettings() end
end

return UI
