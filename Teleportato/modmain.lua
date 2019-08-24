-- to test mod you can use c_gonext("prefab") to teleport to the parts. The prefabs are:
-- teleportato_base
-- teleportato_box
-- teleportato_crank
-- teleportato_potato
-- teleportato_ring



print("HIER ist modmain")

local _G = GLOBAL
local helpers = _G.require("tele_helpers") 
if not _G.TUNING.TELEPORTATOMOD then
    _G.TUNING.TELEPORTATOMOD = {}
end
if not _G.TUNING.TELEPORTATOMOD.WORLDS then
    _G.TUNING.TELEPORTATOMOD.WORLDS = {}
end
local WORLDS = _G.TUNING.TELEPORTATOMOD.WORLDS -- testen ob ich auch hier erst definiren muss, obwohl bereits in modworldgenmain gemacht..

-- print("WORLDS tele modmain:")
-- print(_G.next(WORLDS))

_G.TUNING.TELEPORTATOMOD.LEVEL = nil -- is set in momdain to _GEN after world generation, or else is extracted from adv_startstuff component
_G.TUNING.TELEPORTATOMOD.CHAPTER = nil

if _G.next(WORLDS) then
    _G.TUNING.TELEPORTATOMOD.WorldWithTeleportato = nil
else
    _G.TUNING.TELEPORTATOMOD.WorldWithTeleportato = GetModConfigData("spawnteleworld")
end

-- your mod can overwrite the teleportato modsettings:
_G.TUNING.TELEPORTATOMOD.ITEMNUMBERTRANS = _G.TUNING.TELEPORTATOMOD.ITEMNUMBERTRANS~=nil and _G.TUNING.TELEPORTATOMOD.ITEMNUMBERTRANS or GetModConfigData("inventorysavenumber") -- number of transferred items
_G.TUNING.TELEPORTATOMOD.TELENEWWORLD = _G.TUNING.TELEPORTATOMOD.TELENEWWORLD~=nil and _G.TUNING.TELEPORTATOMOD.TELENEWWORLD or GetModConfigData("newworld")
_G.TUNING.TELEPORTATOMOD.RegenerateHealth = _G.TUNING.TELEPORTATOMOD.RegenerateHealth~=nil and _G.TUNING.TELEPORTATOMOD.RegenerateHealth or GetModConfigData("RegeneratePlayerHealth")
_G.TUNING.TELEPORTATOMOD.RegenerateSanity = _G.TUNING.TELEPORTATOMOD.RegenerateSanity~=nil and _G.TUNING.TELEPORTATOMOD.RegenerateSanity or GetModConfigData("RegeneratePlayerSanity")
_G.TUNING.TELEPORTATOMOD.RegenerateHunger = _G.TUNING.TELEPORTATOMOD.RegenerateHunger~=nil and _G.TUNING.TELEPORTATOMOD.RegenerateHunger or GetModConfigData("RegeneratePlayerHunger")
_G.TUNING.TELEPORTATOMOD.Enemies = _G.TUNING.TELEPORTATOMOD.Enemies~=nil and _G.TUNING.TELEPORTATOMOD.Enemies or GetModConfigData("Enemies")
_G.TUNING.TELEPORTATOMOD.Thulecite = _G.TUNING.TELEPORTATOMOD.Thulecite~=nil and _G.TUNING.TELEPORTATOMOD.Thulecite or GetModConfigData("Thulecite")
_G.TUNING.TELEPORTATOMOD.Ancient = _G.TUNING.TELEPORTATOMOD.Ancient~=nil and _G.TUNING.TELEPORTATOMOD.Ancient or GetModConfigData("Ancient")
_G.TUNING.TELEPORTATOMOD.Chests = _G.TUNING.TELEPORTATOMOD.Chests~=nil and _G.TUNING.TELEPORTATOMOD.Chests or GetModConfigData("Chests")
_G.TUNING.TELEPORTATOMOD.min_players = _G.TUNING.TELEPORTATOMOD.min_players~=nil and _G.TUNING.TELEPORTATOMOD.min_players or GetModConfigData("min_players")
_G.TUNING.TELEPORTATOMOD.agesave = _G.TUNING.TELEPORTATOMOD.agesave~=nil and _G.TUNING.TELEPORTATOMOD.agesave or GetModConfigData("agesave")
_G.TUNING.TELEPORTATOMOD.inventorysave = _G.TUNING.TELEPORTATOMOD.inventorysave~=nil and _G.TUNING.TELEPORTATOMOD.inventorysave or GetModConfigData("inventorysave")
_G.TUNING.TELEPORTATOMOD.recipesave = _G.TUNING.TELEPORTATOMOD.recipesave~=nil and _G.TUNING.TELEPORTATOMOD.recipesave or GetModConfigData("recipesave")
_G.TUNING.TELEPORTATOMOD.DSlike = _G.TUNING.TELEPORTATOMOD.DSlike~=nil and _G.TUNING.TELEPORTATOMOD.DSlike or GetModConfigData("DSlike")




local SanityAuraList = {-_G.TUNING.SANITYAURA_SMALL,-_G.TUNING.SANITYAURA_SMALL_TINY,-_G.TUNING.SANITYAURA_TINY,_G.TUNING.SANITYAURA_TINY, _G.TUNING.SANITYAURA_SMALL_TINY, _G.TUNING.SANITYAURA_SMALL ,_G.TUNING.SANITYAURA_MED ,_G.TUNING.SANITYAURA_LARGE,_G.TUNING.SANITYAURA_HUGE}

local function DoRegeneratePlayers(inst)
    if inst.completed and (_G.TUNING.TELEPORTATOMOD.RegenerateHealth~=0 or _G.TUNING.TELEPORTATOMOD.RegenerateHunger~=0 or _G.TUNING.TELEPORTATOMOD.RegenerateSanity~=0) then
        if inst.components.sanityaura==nil and _G.TUNING.TELEPORTATOMOD.RegenerateSanity>0 then
            inst:AddComponent("sanityaura")
            inst.components.sanityaura.aura = SanityAuraList[_G.TUNING.TELEPORTATOMOD.RegenerateSanity]
        end
        if _G.TUNING.TELEPORTATOMOD.RegenerateHealth~=0 or _G.TUNING.TELEPORTATOMOD.RegenerateHunger~=0 then
            local x, y, z = inst.Transform:GetWorldPosition() 
            local players = _G.TheSim:FindEntities(x, y, z, 10, nil, nil, {"player"}) --(x, y, z, radius, musttags, canttags, mustoneoftags)
            for _,player in pairs(players) do
                if player and player.components then
                    if _G.TUNING.TELEPORTATOMOD.RegenerateHealth~=0 and player.components.health then
                        player.components.health:DoDelta(_G.TUNING.TELEPORTATOMOD.RegenerateHealth)
                    end
                    if _G.TUNING.TELEPORTATOMOD.RegenerateHunger~=0 and player.components.hunger then
                        player.components.hunger:DoDelta(_G.TUNING.TELEPORTATOMOD.RegenerateHunger)
                    end
                end
            end
        end
    end
    inst:DoTaskInTime(5, DoRegeneratePlayers)
end




-- divining Rod recipe
local Recipe = _G.Recipe
local diviningrod = AddRecipe("diviningrod", {Ingredient("twigs", 1), Ingredient("nightmarefuel", 4), Ingredient("gears", 1)}, _G.RECIPETABS.SCIENCE, _G.TECH.SCIENCE_TWO)




------ ####################
-- ## adventrure stuff
------ ####################




if not helpers.exists_in_table("functionatplayerfirstspawn",_G.TUNING.TELEPORTATOMOD) then
    _G.TUNING.TELEPORTATOMOD.functionatplayerfirstspawn = nil
end
if not helpers.exists_in_table("functionatfirstplayerfirstspawn",_G.TUNING.TELEPORTATOMOD) then
    _G.TUNING.TELEPORTATOMOD.functionatfirstplayerfirstspawn = nil
end
if not helpers.exists_in_table("functionpostinitworldONCE",_G.TUNING.TELEPORTATOMOD) then
    _G.TUNING.TELEPORTATOMOD.functionpostinitworldONCE = nil
end

local function TitleStufff(inst) -- inst is player
    if _G.TheWorld:HasTag("forest") then -- we have to use this TAg check instead of ismastershard, because otherwise it will return false for clients
        _G.TUNING.TELEPORTATOMOD.CHAPTER = _G.TUNING.TELEPORTATOMOD.CHAPTER or inst.mynetvarAdvChapter:value()
        _G.TUNING.TELEPORTATOMOD.LEVEL = _G.TUNING.TELEPORTATOMOD.LEVEL or inst.mynetvarAdvLevel:value()
        local chapter = _G.TUNING.TELEPORTATOMOD.CHAPTER
        local level = _G.TUNING.TELEPORTATOMOD.LEVEL
        
        local title = "test"
        local subtitle = "test"
        if chapter and chapter > 0 then -- show title and chapter
            -- TheNet:Announce("Congratulation! You won the adventure!")
            title = WORLDS[level].name
            subtitle = _G.STRINGS.UI.SANDBOXMENU.CHAPTERS[chapter]
        elseif chapter and chapter == 0 then
            title = WORLDS[level].name
            subtitle = "Prologue"
            -- _G.TheCamera:SetDistance(12)
            if _G.TheWorld.ismastersim then
                inst:SetCameraDistance(12)
            end
        end
        -- print("HIER TITLESTUFF funktion chapter: "..tostring(chapter).."title: "..tostring(title).." subtitle: "..tostring(subtitle))
        if not _G.TheWorld.ismastersim then -- only at client
            _G.TheFrontEnd:ShowTitle(title,subtitle)
            _G.TheFrontEnd:Fade(true, 1, function()
                _G.SetPause(false)

                _G.TheFrontEnd:HideTitle()
            end, 3 ,function() _G.SetPause(false) end)
        end
        inst:DoTaskInTime(4,function(inst)
             if chapter and chapter==0 then
                -- _G.TheCamera:SetDefault()
                if _G.TheWorld.ismastersim then
                    inst:SetCameraDistance()
                end
            end
        end)
    end
end


local function StartItems(inst)
    print("HIER startitems LEVEL: "..tostring(_G.TUNING.TELEPORTATOMOD.LEVEL))
    if _G.TheWorld.ismastersim and _G.TheWorld.ismastershard then
        inst.mynetvarTitleStufff:set(1) -- send info to clients, to show the game title at game start
    end
    if _G.TheWorld.ismastersim then
        inst:SetCameraDistance(12)
        inst:DoTaskInTime(4,function() inst:SetCameraDistance() end) -- move camera back to default after title screen
    end
    if _G.TUNING.TELEPORTATOMOD.functionatplayerfirstspawn~=nil then -- eg spawn some stuff for plaers joining the first time
        _G.TUNING.TELEPORTATOMOD.functionatplayerfirstspawn(inst)
    end
end

local function DoStartStuff(world) -- könnte man evtl mit prefabpostinit world und POPULATING machen, damts nur einmal beim erstellen der welt gemacht wird?
    -- correct the globals if the world just generated
    print("DoStartStuff")
    _G.TUNING.TELEPORTATOMOD.LEVEL = _G.TUNING.TELEPORTATOMOD.LEVEL_GEN -- GEN is only correct just after the world generation using adventurejump. On every game load, it is wrong, that's why we set this once per world
    world.components.adv_startstuff.adv_level = _G.TUNING.TELEPORTATOMOD.LEVEL -- save it in world component so it is also correct after loading the game
    print("Adventure: LEVEL defined to _GEN "..tostring(_G.TUNING.TELEPORTATOMOD.LEVEL_GEN))
    
    _G.TUNING.TELEPORTATOMOD.CHAPTER = _G.TUNING.TELEPORTATOMOD.CHAPTER_GEN
    world.components.adv_startstuff.adv_chapter = _G.TUNING.TELEPORTATOMOD.CHAPTER
    print("Adventure: CHAPTER defined to GEN "..tostring(_G.TUNING.TELEPORTATOMOD.CHAPTER_GEN))
    
    if world.ismastersim and world.ismastershard then
        world:DoTaskInTime(1,function(world) world.components.adventurejump:MakeSave() end)
    end    
        
    if _G.TUNING.TELEPORTATOMOD.functionpostinitworldONCE~=nil then -- eg to spawn some grass/rocks or so at the starting postion
        _G.TUNING.TELEPORTATOMOD.functionpostinitworldONCE(world)
    end

    if _G.TUNING.TELEPORTATOMOD.functionatfirstplayerfirstspawn~=nil then -- executed only for the first spawn of first player -- eg to spawn maxwell
        world:ListenForEvent("ms_playerspawn", function(world,inst) world.components.adv_startstuff:GiveStartStuffIn(0.01,_G.TUNING.TELEPORTATOMOD.functionatfirstplayerfirstspawn,"functionatfirstplayerfirstspawn",inst) end)
    end
end

local function OnDirtyEventTitleStufff(inst) -- this is called on client, if the server does inst.mynetvarTitleStufff:set(...)
    local val = inst.mynetvarTitleStufff:value()
    if val==1 then
        inst:DoTaskInTime(0.01,TitleStufff)
    -- elseif val==2 then -- braucht man nicht, da camera vom server gesteuert wird
        -- inst:SetCameraDistance(12)
    -- elseif val==3 then
        -- inst:SetCameraDistance()
    end
    -- Use val and do client related stuff
end
local function RegisterListenersTitleStufff(inst)
    -- check that the entity is the playing player
    if inst.HUD ~= nil then
        inst:ListenForEvent("DirtyEventTitleStufff", OnDirtyEventTitleStufff)
    end
end
local function SetChapterStuff(inst)
    print("SetChapterStuff")
    inst.mynetvarAdvChapter:set(_G.TUNING.TELEPORTATOMOD.CHAPTER)
    inst.mynetvarAdvLevel:set(_G.TUNING.TELEPORTATOMOD.LEVEL)
end
local function OnPlayerSpawn(inst)
    print("onplayerspawn")
    if _G.TheWorld:HasTag("forest") then--_G.TheWorld.ismastershard then
        
         -- only for showing the correct title at clients screen
        inst.mynetvarAdvChapter = _G.net_tinybyte(inst.GUID, "AdvChapterNetStuff", "DirtyEventAdvChapter") -- value from 0 to 7
        inst.mynetvarAdvChapter:set(0) -- set a default value
        inst.mynetvarAdvLevel = _G.net_tinybyte(inst.GUID, "AdvLevelNetStuff", "DirtyEventAdvLevel") -- value from 0 to 7
        inst.mynetvarAdvLevel:set(1) -- set a default value
        if inst.ismastersim then
            inst:DoTaskInTime(0.2,SetChapterStuff)
        end
        
        -- defined in netvars.lua
        -- GUID of entity, unique name identifier (among entity netvars), dirty event name
        inst.mynetvarTitleStufff = _G.net_tinybyte(inst.GUID, "TitleStufffNetStuff", "DirtyEventTitleStufff") 
        -- set a default value
        inst.mynetvarTitleStufff:set(0)
        inst:DoTaskInTime(0, RegisterListenersTitleStufff)
        
        
        
        
    end
    -- if _G.TheWorld.ismastersim then
    inst:AddComponent("adv_startstuff") -- also add this to client, otherwise we can not call StartItems also for clients... make sure to not mix this =/
    -- end
    inst.components.adv_startstuff:GiveStartStuffIn(0.3,StartItems,"StartItems") -- should be done after the world did his adv_startstuff and maxwellspawn-- dealy of 0.3 is needed, cause otherwise the client netvar stuff does not work everytime...
end
if _G.next(WORLDS) then -- if another mod wants us to load a specific world
    print("WORLDS tele modmain MIT WORLDS")
    AddPlayerPostInit(OnPlayerSpawn)
    -- now when doing server stuff, use
    -- inst.mynetvarTitleStufff:set(num), with inst being a player and num a number between 0 and 7
    -- changes will propagate to clients
    local function ConfirmAdventure(player, portal, answer)
        if type(portal) == "table" then
            if answer then
                if portal.StartAdventure then
                    portal:StartAdventure()
                end
            else
                if portal.RejectAdventure then
                    portal:RejectAdventure()
                end
            end
        end
    end
    AddModRPCHandler("adventure", "confirm", ConfirmAdventure)
else
    print("WORLDS tele modmain KEINE WORLDS")
end



--#############################################################






if not (_G.TheNet:GetIsServer() or _G.TheNet:IsDedicated())then 
    return
end


local function DoTheWorldJump(inst,doer) -- inst has to be the teleportato_base
    local counter = helpers.CheckHowManyPlayers(inst)
    NeededPlayers = _G.TUNING.TELEPORTATOMOD.min_players=="half" and _G.TheNet:GetPlayerCount()/2 or _G.TUNING.TELEPORTATOMOD.min_players=="all" and _G.TheNet:GetPlayerCount() or _G.TUNING.TELEPORTATOMOD.min_players
    if (_G.TUNING.TELEPORTATOMOD.min_players=="half" and counter > NeededPlayers) or counter >= NeededPlayers then
        _G.TheNet:Announce("Worldjump!")
        inst:DoTaskInTime(4, function() inst.AnimState:PlayAnimation("laugh", false) ; inst.AnimState:PushAnimation("active_idle", true) ; inst.SoundEmitter:PlaySound("dontstarve/common/teleportato/teleportato_maxwelllaugh", "teleportato_laugh") end)
        _G.TheWorld:DoTaskInTime(6.46, function(world) _G.TheFrontEnd:Fade(false,1) end)
        _G.TheWorld:DoTaskInTime(2.11, function(world) for k,v in pairs(_G.AllPlayers) do v.sg:GoToState("teleportato_teleport") end end)
        _G.TheWorld:DoTaskInTime(8, function(world)
            if world.ismastersim and world.ismastershard then
                if _G.next(WORLDS) then -- if another mod wants us to load a specific world
                    world.components.adventurejump:DoJump(_G.TUNING.TELEPORTATOMOD.agesave,_G.TUNING.TELEPORTATOMOD.inventorysave,_G.TUNING.TELEPORTATOMOD.recipesave) -- transfer days, recipes and inventory
                else
                    world.components.worldjump:DoJump(_G.TUNING.TELEPORTATOMOD.agesave,_G.TUNING.TELEPORTATOMOD.inventorysave,_G.TUNING.TELEPORTATOMOD.recipesave)
                end
            else
                _G.TheNet:Announce("Worldjump aborted, cause world is not mastersim/mastershard!")
            end
        end)
    else
        if _G.TUNING.TELEPORTATOMOD.min_players=="half" then
            _G.TheNet:Announce("Worldjump aborted, cause not enough players are near teleportato.\nMore than half needed"..tostring(counter).."/"..tostring(NeededPlayers))
        else
            _G.TheNet:Announce("Worldjump aborted, cause not enough players are near teleportato.\n"..tostring(counter).."/"..tostring(NeededPlayers))
        end
        inst:DoTaskInTime(7, helpers.DeactivateTeleportato)
    end
end


local function RecognizeTelePart(world,inst) -- call this only once for every part after world is generated! if more than one of each part exist, we do not remove them, only one will be saved
    -- print("RecognizeTelePart "..tostring(world).." "..tostring(inst))
    if inst~=nil then
        if _G.TheWorld.components.adv_startstuff.partpositions==nil then
            _G.TheWorld.components.adv_startstuff.partpositions = {}
        end
        if _G.TheWorld.components.adv_startstuff.partpositions[inst.prefab]==nil then
            _G.TheWorld.components.adv_startstuff.partpositions[inst.prefab] = inst:GetPosition() -- is saved and loaded within this components
            -- print("RecognizeTelePart set position for "..tostring(inst.prefab).." to "..tostring(_G.TheWorld.components.adv_startstuff.partpositions[inst.prefab]))
        end
    end
end


local function TeleportatoPostInit(inst)
    print("TeleportatoPostInit")
    inst:DoTaskInTime(1,function(inst)
        if TUNING.TELEPORTATOMOD.IsWorldWithTeleportato()==true then  -- this is defined 0.2 seconds after world start!
            _G.TheWorld:DoTaskInTime(0,function(world,inst) world.components.adv_startstuff:GiveStartStuffIn(0,RecognizeTelePart,"RecognizeTelePart"..inst.prefab,inst) end, inst)
            if not _G.TUNING.TELEPORTATOMOD.DSlike then
                inst:DoTaskInTime(5, DoRegeneratePlayers)
            end
        end
    end   ) 
    
    local _OnSave = inst.OnSave
    local function OnSave(inst,data)
        _OnSave(inst,data) -- call the previous
        data.activatedonce = inst.activatedonce
        data.completed = inst.completed
    end
    inst.OnSave = OnSave
    
    local _OnLoad = inst.OnLoad
    local function OnLoad(inst,data)
        _OnLoad(inst,data) -- call the previous
        if data then
            if data.activatedonce then
                inst.activatedonce = data.activatedonce
            end
            if data.completed then
                inst.completed = data.completed
            end
        end
    end
    inst.OnLoad = OnLoad
    
    local _OnActivate = inst.components.activatable.OnActivate
    local function OnActivate(inst,doer,donothing) -- doer can be nil

        _OnActivate(inst,doer) -- call the previous OnAcvtivate to make animations and set the activatedonce to true
        
        if _G.TUNING.TELEPORTATOMOD.TELENEWWORLD then -- following code taken from the TeleportatoFix Mod by Cliff http://steamcommunity.com/sharedfiles/filedetails/?id=728755481
            local counter = helpers.CheckHowManyPlayers(inst)
            NeededPlayers = _G.TUNING.TELEPORTATOMOD.min_players=="half" and _G.TheNet:GetPlayerCount()/2 or _G.TUNING.TELEPORTATOMOD.min_players=="all" and _G.TheNet:GetPlayerCount() or _G.TUNING.TELEPORTATOMOD.min_players
            if (_G.TUNING.TELEPORTATOMOD.min_players=="half" and counter > NeededPlayers) or counter >= NeededPlayers then
                _G.TheNet:Announce("Leave teleportato area, if you dont want a new world within 15 seconds!\nStuff from players in cave will be last known overworld stuff")
                inst:DoTaskInTime(15,DoTheWorldJump,doer)
                inst:DoTaskInTime(10,function() _G.TheNet:Announce("5 seconds left!") end)
                inst:DoTaskInTime(11,function() _G.TheNet:Announce("4 seconds left!") end)
                inst:DoTaskInTime(12,function() _G.TheNet:Announce("3 seconds left!") end)
                inst:DoTaskInTime(13,function() _G.TheNet:Announce("2 seconds left!") end)
                inst:DoTaskInTime(14,function() _G.TheNet:Announce("1 seconds left!") end)
            else
                inst:DoTaskInTime(2, function() inst.AnimState:PlayAnimation("laugh", false) ; inst.AnimState:PushAnimation("active_idle", true) ; inst.SoundEmitter:PlaySound("dontstarve/common/teleportato/teleportato_maxwelllaugh", "teleportato_laugh") end)
                if _G.TUNING.TELEPORTATOMOD.min_players=="half" then
                    _G.TheNet:Announce("More than "..tostring(NeededPlayers).." players must be near teleportato!\nCounted only: "..tostring(counter))
                else
                    _G.TheNet:Announce("At least "..tostring(NeededPlayers).." players must be near teleportato!\nCounted only: "..tostring(counter))
                end
                inst:DoTaskInTime(7, helpers.DeactivateTeleportato)
            end
            return
        else
            inst:DoTaskInTime(2, function() inst.AnimState:PlayAnimation("laugh", false) ; inst.AnimState:PushAnimation("active_idle", true) ;  inst.SoundEmitter:PlaySound("dontstarve/common/teleportato/teleportato_maxwelllaugh", "teleportato_laugh") end)
            _G.TheNet:Announce("Worldjump disabled.\nBut Admin/Host can still type the commands in console or set TUNING.TELEPORTATOMOD.TELENEWWORLD to true!")
            inst:DoTaskInTime(7, helpers.DeactivateTeleportato)
        end

    end
    inst.components.activatable.OnActivate = OnActivate
    
    local _ItemGet = inst.components.trader.onaccept
    local function ItemGet(inst, giver, item) 
        _ItemGet(inst, giver, item)
        if inst.collectedParts.teleportato_ring and inst.collectedParts.teleportato_crank and inst.collectedParts.teleportato_box and inst.collectedParts.teleportato_potato then
            if not inst.completed and not inst.activatedonce then -- if it was completed the first time... and a check if it was already activated to don't break savegames were it is already active
                if giver and giver.components and giver.components.talker then
                    giver.components.talker:ShutUp()
                    giver.components.talker:Say(_G.GetString(doer, "ANNOUNCE_TRAP_WENT_OFF"))
                end
                if _G.TUNING.TELEPORTATOMOD.Enemies > 0 and not _G.TUNING.TELEPORTATOMOD.DSlike then
                    _G.TheNet:Announce("Teleportato Completed! Did you hear that?!")
                else
                    _G.TheNet:Announce("Teleportato Completed!")
                end
                if not _G.TUNING.TELEPORTATOMOD.DSlike then
                    inst:DoTaskInTime(1+2, helpers.SpawnThuleciteStatue)
                    inst:DoTaskInTime(3+2, helpers.SpawnAncientStation) -- 
                    inst:DoTaskInTime(4+2, helpers.SpawnOrnateChest) -- 
                    inst:DoTaskInTime(5+2, helpers.SpawnEnemies) -- some new enemies at parts positions
                end
            end
            inst.completed = true
        end
    end
    inst.components.trader.onaccept = ItemGet
end
AddPrefabPostInit("teleportato_base", TeleportatoPostInit) 

_G.TUNING.TELEPORTATOMOD.IsWorldWithTeleportato = function()   -- this is defined 0.2 seconds after world start!
    if _G.TUNING.TELEPORTATOMOD.WorldWithTeleportato==nil then
        return nil
    elseif string.match(_G.TUNING.TELEPORTATOMOD.WorldWithTeleportato,_G.TheWorld.worldprefab) or (_G.TUNING.TELEPORTATOMOD.WorldWithTeleportato~="" and _G.TheWorld.ismastershard) then -- the mastershard has always the base (except no world at all has any tele)
        return true
    end
    return false
end



AddPrefabPostInit("world", function(world)
    
    print("worldpostinit")
    if world.ismastersim and world.ismastershard then -- telebase and these componets only to the mastershard. teleparts can be transferred between worlds.
        world:AddComponent("worldjump") -- but all worlds get thee jump component
        if _G.next(WORLDS) then
            world:AddComponent("adventurejump") -- better add this after worldjump, cause the jump itself uses worldjump
        end
    end
    
    world:AddComponent("adv_startstuff") -- also add it for client
    if _G.next(WORLDS) then
        _G.TUNING.TELEPORTATOMOD.LEVEL = world.components.adv_startstuff.adv_level or 1 -- if world was just created, this will be overwritten from DoStartStuff
        print("Adventure: LEVEL defined to "..tostring(_G.TUNING.TELEPORTATOMOD.LEVEL))
        _G.TUNING.TELEPORTATOMOD.CHAPTER = world.components.adv_startstuff.adv_chapter or 0
        print("Adventure: CHAPTER defined to "..tostring(_G.TUNING.TELEPORTATOMOD.CHAPTER))
        world:DoTaskInTime(0,function(world) world.components.adv_startstuff:GiveStartStuffIn(0.01,DoStartStuff,"DoStartStuff") end)
    end
    if world.ismastersim then
        world:DoTaskInTime(0.2,function(world) -- do it after DoStartStuff
            if _G.next(WORLDS) then
                local stri = ""
                if WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL].taskdatafunctions~=nil then -- if index nil error arrives, it may be because LEVEL in DoStartStuff was not defined yet...
                    for worldprefab,func in pairs(WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL].taskdatafunctions) do
                        stri = stri..(func({}).add_teleportato and worldprefab or "")
                    end
                end
                _G.TUNING.TELEPORTATOMOD.WorldWithTeleportato = stri -- "", "forest", "cave" or "forestcave"
                -- we could also save/load this within the world.... 
            end
        end)
        
        world:ListenForEvent("ms_playerdespawnandmigrate", function(world,data)
            -- data = { player = doer, portalid = self.id, worldid = self.linkedWorld }
            if data~=nil and data.player~=nil and data.player.components and data.player.components.inventory then -- a player switching worlds
                local inst = data.player
                for i = 1, inst.components.inventory:GetNumSlots() do
                    item = inst.components.inventory:GetItemInSlot(i)
                    if item~=nil and item:IsValid() and table.contains({"teleportato_potato","teleportato_box","teleportato_ring","teleportato_crank"},item.prefab) and item:HasTag("irreplaceable") then
                        item:RemoveTag("irreplaceable") -- remove this tag for now, so parts can be transferred between worlds. is automatically added on spwning again
                    end
                end
            end
        end)
    
        world:DoTaskInTime(1, function(world)
            if _G.TUNING.TELEPORTATOMOD.IsWorldWithTeleportato()==true then -- this is defined 0.2 seconds after world start!
                world.components.adv_startstuff:GiveStartStuffIn(5,function(world) -- do this only once per game (so its not done for other bases if there are any)
                    if not _G.TUNING.TELEPORTATOMOD.DSlike then
                        helpers.SpawnEnemies(world) -- some enemies at start of the game at the part positions
                    end
                end,"InitTeleBase")
            end
        end)
    
        world:DoTaskInTime(3,function(world) -- check if we have all parts
            if _G.TheWorld.components.adv_startstuff.partpositions==nil then
                _G.TheWorld.components.adv_startstuff.partpositions = {}
            end
            if _G.TUNING.TELEPORTATOMOD.IsWorldWithTeleportato()==true then -- this is defined 0.2 seconds after world start!
                local missingparts = {}
                local searchparts = {"teleportato_potato","teleportato_box","teleportato_ring","teleportato_crank"}
                if _G.TUNING.TELEPORTATOMOD.WorldWithTeleportato~="" and not string.match(_G.TUNING.TELEPORTATOMOD.WorldWithTeleportato,"forest") and world.ismastershard then
                    searchparts = {} -- if we want the parts only be there at cave
                end
                if world.ismastershard then -- the base should only be there at mastershard (forest)
                    table.insert(searchparts,"teleportato_base")
                end
                for _,partprefab in ipairs(searchparts) do
                    if world.components.adv_startstuff.partpositions[partprefab]==nil then
                        table.insert(missingparts,partprefab)
                    end
                end
                if _G.next(missingparts) then
                    local portal = nil
                    for k,v in pairs(_G.Ents) do
                        if (v.prefab == "spawnpoint_master") then
                            portal = v
                            break
                        end
                    end
                    if portal~=nil then
                        local spawn = nil
                        -- print("teleportato parts are missing, spawning them near a spawnpoint_master...")
                        for _,partprefab in ipairs(missingparts) do
                            spawn = helpers.SpawnPrefabAtLandPlotNearInst(partprefab,portal,450,0,450,nil,50,50)
                            if partprefab=="teleportato_base" and spawn~=nil then -- then we need more enemies here
                                world.telebasewasspawnedbymod = true -- so it knows, it has to spawn some more enemies around the base
                            end
                        end
                    else
                        print("teleportato parts are missing, but there is no portal to spawn them near to...")
                    end
                end
            end
        end)
    end
end)

for _, prefab in ipairs({"teleportato_potato","teleportato_box","teleportato_ring","teleportato_crank"}) do
    AddPrefabPostInit(prefab, function(inst)
        helpers.MakeSlowPick(inst)
        _G.TheWorld:DoTaskInTime(0,function(world,inst) world.components.adv_startstuff:GiveStartStuffIn(0.01,RecognizeTelePart,"RecognizeTelePart"..inst.prefab,inst) end, inst)
    end)
end





--- ############# Worldjump code by DarkXero! :)
-- allwos the admin to type into the say-console "/worldjump" to generate new world

_G.STRINGS.UI.BUILTINCOMMANDS.WORLDJUMP = {
	PRETTYNAME = "World Jump",
	DESC = "Activate the potato!",
	VOTETITLEFMT = "Should we activate the potato?",
	VOTENAMEFMT = "vote to activate the potato",
	VOTEPASSEDFMT = "Potato activating in 10 seconds...",
}

local VoteUtil = _G.require("voteutil")
local UserCommands = _G.require("usercommands")

_G.AddModUserCommand("worldjumpmod", "worldjump", {
	prettyname = nil, -- defaults to STRINGS.UI.BUILTINCOMMANDS.WORLDJUMP.PRETTYNAME
	desc = nil, -- defaults to STRINGS.UI.BUILTINCOMMANDS.WORLDJUMP.DESC
	permission = _G.COMMAND_PERMISSION.ADMIN,
	confirm = true,
	slash = true,
	usermenu = false,
	servermenu = true,
	params = {},
	vote = true, -- so people can vote
	votetimeout = 30,
	voteminpasscount = 3,
	votecountvisible = true,
	voteallownotvoted = true,
	voteoptions = nil, -- defaults to { "Yes", "No" }
	votetitlefmt = nil, -- defaults to STRINGS.UI.BUILTINCOMMANDS.WORLDJUMP.VOTETITLEFMT
	votenamefmt = nil, -- defaults to STRINGS.UI.BUILTINCOMMANDS.WORLDJUMP.VOTENAMEFMT
	votepassedfmt = nil, -- defaults to STRINGS.UI.BUILTINCOMMANDS.WORLDJUMP.VOTEPASSEDFMT
	votecanstartfn = VoteUtil.DefaultCanStartVote, -- there's only one of these it seems
	voteresultfn = VoteUtil.YesNoMajorityVote, -- check voteutil.lua for the other three
	serverfn = function(params, caller)
		-- NOTE: must support nil caller for voting
		if caller ~= nil then
			-- Wasn't a vote so we should send out an announcement manually
			-- NOTE: the vote regenerate announcement is customized and still
			--       makes sense even when it wasn't a vote, (run by admin)
			local command = UserCommands.GetCommandFromName("worldjump")
			_G.TheNet:AnnounceVoteResult(command.hash, nil, true)
		end
        _G.TheWorld:DoTaskInTime(13.46, function(world) if world.ismastersim and world.ismastershard then _G.TheFrontEnd:Fade(false,1) end end)
        _G.TheWorld:DoTaskInTime(8.11, function(world) if world.ismastersim and world.ismastershard then for k,v in pairs(_G.AllPlayers) do v.sg:GoToState("teleportato_teleport") end end end)
		_G.TheWorld:DoTaskInTime(15, function(world)
			if world.ismastersim and world.ismastershard then
				if _G.next(WORLDS) then -- if another mod wants us to load a specific world
                    world.components.adventurejump:DoJump(_G.TUNING.TELEPORTATOMOD.agesave,_G.TUNING.TELEPORTATOMOD.inventorysave,_G.TUNING.TELEPORTATOMOD.recipesave) -- transfer days, recipes and inventory
                else
                    world.components.worldjump:DoJump(_G.TUNING.TELEPORTATOMOD.agesave,_G.TUNING.TELEPORTATOMOD.inventorysave,_G.TUNING.TELEPORTATOMOD.recipesave)
                end
			end
		end)
	end,
})
