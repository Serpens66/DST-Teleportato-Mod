-- to test mod you can use c_gonext("prefab") to teleport to the parts. The prefabs are:
-- teleportato_base
-- teleportato_box
-- teleportato_crank
-- teleportato_potato
-- teleportato_ring


-- print("HIER ist modmain")

local _G = GLOBAL
local helpers = _G.require("tele_helpers") 
if not _G.TUNING.TELEPORTATOMOD then
    _G.TUNING.TELEPORTATOMOD = {}
end
if not _G.TUNING.TELEPORTATOMOD.WORLDS then
    _G.TUNING.TELEPORTATOMOD.WORLDS = {}
end
local WORLDS = _G.TUNING.TELEPORTATOMOD.WORLDS -- testen ob ich auch hier erst definiren muss, obwohl bereits in modworldgenmain gemacht..
_G.TUNING.TELEPORTATOMOD.LEVELINFOLOADED = false -- if you can use TUNING.TELEPORTATOMOD.LEVEL and so on already. will be set true as soon as the world finished loading

local function IsLEVELINFOLOADED()
    return _G.TUNING.TELEPORTATOMOD.LEVELINFOLOADED
end

modimport("scripts/tele_itemskinsave") -- save the skins for items for worldjump

_G.TUNING.TELEPORTATOMOD.IsWorldWithTeleportato = function() -- as soon LEVELINFOLOADED is true, you can use this
    if _G.TUNING.TELEPORTATOMOD.WorldWithTeleportato==nil then
        return nil
    elseif string.match(_G.TUNING.TELEPORTATOMOD.WorldWithTeleportato,_G.TheWorld.worldprefab) or (_G.TUNING.TELEPORTATOMOD.WorldWithTeleportato~="" and _G.TheWorld.ismastershard) then -- the mastershard has always the base (except no world at all has any tele)
        return true
    end
    return false
end

local TheNet = GLOBAL.TheNet
local SERVER_SIDE, DEDICATED_SIDE, CLIENT_SIDE, ONLY_CLIENT_SIDE
if TheNet:GetIsServer() then
	SERVER_SIDE = true
	if TheNet:IsDedicated() then
		DEDICATED_SIDE = true -- ==ONLY_SERVER_SIDE
	else
		CLIENT_SIDE = true
	end
elseif TheNet:GetIsClient() then
	SERVER_SIDE = false
	CLIENT_SIDE = true
	ONLY_CLIENT_SIDE = true
end


local enabledmods = {}
for _,modname in pairs(_G.TheNet:GetIsServer() and _G.ModManager:GetEnabledServerModNames() or _G.TheNet:GetServerModNames()) do
    enabledmods[_G.KnownModIndex:GetModFancyName(modname)] = true
    -- print("found enabled mod "..modname.." == "..tostring(_G.KnownModIndex:GetModFancyName(modname)))
end
-- print(enabledmods["[API] Gem Core"])
_G.TUNING.TELEPORTATOMOD.GEMAPIActive = enabledmods["[API] Gem Core"]
if _G.TUNING.TELEPORTATOMOD.GEMAPIActive then
    _G.SetupGemCoreEnv()
    AddShardComponent("shard_teleplayersave")
    -- print("called AddComponent within modmain")
    local shardReceivedList = {}
    local function SavePlayerDatainMaster(shard_id,player_data_save,test)
        if _G.TheWorld.ismastershard then
            -- print("SavePlayerDatainMaster on master")
            -- print(shard_id)
            -- print(player_data_save)
            table.insert(shardReceivedList,shard_id)
            local player_data_save_MASTER = _G.TheWorld.components.worldjump.player_data_save -- this is old data from players left the master. new data from all players currently active at master will be added at last
            
            print("player_data_save_slave:")
            for userid, data in pairs(player_data_save) do
                print(tostring(userid).." :: "..tostring(data))
                if data~=nil and type(data)=="table" then
                    for k,v in pairs(data) do
                        print(tostring(k).." == "..tostring(v))
                    end
                end
            end
            print("player_data_save_slave done")
            print("player_data_save_MASTER:")
            for userid, data in pairs(player_data_save_MASTER) do
                print(tostring(userid).." :: "..tostring(data))
                if data~=nil and type(data)=="table" then
                    for k,v in pairs(data) do
                        print(tostring(k).." == "..tostring(v))
                    end
                end
            end
            print("player_data_save_MASTER done")
            
            for userid, data in pairs(player_data_save) do
                if userid~="saveinventory" and userid~="savebuilder" and userid~="saveage" then
                    if player_data_save_MASTER[userid]==nil then -- new info? add it
                        player_data_save_MASTER[userid] = data
                    else -- we already have stuff from that player? check which is newer
                        if data.timefromsave > player_data_save_MASTER[userid].timefromsave then -- if slave data is newer (higher time value), replace our master data
                            player_data_save_MASTER[userid] = data
                        end
                    end
                end
            end
            -- print(#shardReceivedList)
            -- print(#_G.SHARD_LIST)
            if #shardReceivedList==#_G.SHARD_LIST then -- sobald shardReceivedList dieselben id enthält wie shardSendList, kann worldjump gemacht werden
                shardReceivedList = {}
                _G.TheWorld.components.worldjump:DoJumpFinalWithCave() -- this will also save for all current players on master
            end
        end
    end
    _G.AddShardRPCHandler("TeleSerp", "PlayerSave", SavePlayerDatainMaster)
end


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



local function DoStartStuff(world) -- könnte man evtl mit prefabpostinit world und POPULATING machen, damts nur einmal beim erstellen der welt gemacht wird?
    -- correct the globals if the world just generated
    print("DoStartStuff")
    _G.TUNING.TELEPORTATOMOD.LEVEL = _G.TUNING.TELEPORTATOMOD.LEVEL_GEN -- GEN is only correct just after the world generation using adventurejump. On every game load, it is wrong, that's why we set this once per world
    world.components.adv_startstuff.adv_level = _G.TUNING.TELEPORTATOMOD.LEVEL -- save it in world component so it is also correct after loading the game
    print("Adventure: LEVEL defined to _GEN "..tostring(_G.TUNING.TELEPORTATOMOD.LEVEL_GEN))
    
    _G.TUNING.TELEPORTATOMOD.CHAPTER = _G.TUNING.TELEPORTATOMOD.CHAPTER_GEN
    world.components.adv_startstuff.adv_chapter = _G.TUNING.TELEPORTATOMOD.CHAPTER
    print("Adventure: CHAPTER defined to GEN "..tostring(_G.TUNING.TELEPORTATOMOD.CHAPTER_GEN))
    
    if _G.TUNING.TELEPORTATOMOD.functionpostloadworldONCE~=nil then -- eg to spawn some grass/rocks or so at the starting postion
        _G.TUNING.TELEPORTATOMOD.functionpostloadworldONCE(world)
    end
    
end

local function LoadLevelAndDoStuff(world)
    if _G.next(WORLDS) then
        _G.TUNING.TELEPORTATOMOD.LEVEL = world.components.adv_startstuff.adv_level or 1 -- if world was just created, this will be overwritten from DoStartStuff
        print("Adventure: LEVEL defined to "..tostring(_G.TUNING.TELEPORTATOMOD.LEVEL))
        _G.TUNING.TELEPORTATOMOD.CHAPTER = world.components.adv_startstuff.adv_chapter or 1
        print("Adventure: CHAPTER defined to "..tostring(_G.TUNING.TELEPORTATOMOD.CHAPTER))
        world.components.adv_startstuff:DoStartStuffNow(DoStartStuff,"DoStartStuff")
        
        if world.ismastershard and world.components.adventurejump.adventure_info.level_list~=nil and _G.GetTableSize(world.components.adventurejump.adventure_info.level_list)==6 then
            _G.TUNING.TELEPORTATOMOD.CHAPTER = _G.TUNING.TELEPORTATOMOD.CHAPTER + 1 -- wont be executed for caves, but currently it is not a big problem
            print("Teleportato Adventure: Fixed Chapter by adding +1") -- for updating old versions of the mod. can be removed after some months, when all users should already use the version 1.144 or higher
        end
        
        local stri = ""
        if WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL].taskdatafunctions~=nil then -- if index nil error arrives, it may be because LEVEL in DoStartStuff was not defined yet...
            for worldprefab,func in pairs(WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL].taskdatafunctions) do
                stri = stri..(func({}).add_teleportato and worldprefab or "")
            end
        end
        _G.TUNING.TELEPORTATOMOD.WorldWithTeleportato = stri -- "", "forest", "cave" or "forestcave"
        -- we could also save/load this within the world.... 
    end
    
    world:DoTaskInTime(3,function(world) -- check if we have all parts
        if world.components.adv_startstuff.partpositions==nil then
            world.components.adv_startstuff.partpositions = {}
        end
        local portal = nil
        if _G.TUNING.TELEPORTATOMOD.IsWorldWithTeleportato()==true then 
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
                portal = nil
                for k,v in pairs(_G.Ents) do
                    if (v.prefab == "spawnpoint_master") then
                        portal = v
                        break
                    end
                end
                if portal~=nil then
                    local spawn = nil
                    print("teleportato parts are missing, spawning them near a spawnpoint_master...")
                    for _,partprefab in ipairs(missingparts) do
                        spawn = helpers.SpawnPrefabAtLandPlotNearInst(partprefab,portal,1000,0,1000,nil,150,150)
                        if spawn==nil then
                            print("Teleportato: ERROR failed to spawn missing "..tostring(partprefab))
                        end
                        if partprefab=="teleportato_base" and spawn~=nil then -- then we need more enemies here
                            world.telebasewasspawnedbymod = true -- so it knows, it has to spawn some more enemies around the base
                        end
                    end
                else
                    print("teleportato parts are missing, but there is no portal to spawn them near to...")
                end
            end
        end
        if _G.next(WORLDS) and world.ismastershard and _G.TUNING.TELEPORTATOMOD.WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL].name=="Maxwells Door" then -- check if adventure portal was placed
            local advportal = _G.TheSim:FindFirstEntityWithTag("adventure_portal")
            if advportal==nil then
                portal = nil
                for k,v in pairs(_G.Ents) do
                    if (v.prefab == "spawnpoint_master") then
                        portal = v
                        break
                    end
                end
                if portal~=nil then
                    print("adventure_portal is missing, spawning them near a spawnpoint_master...")
                    spawn = helpers.SpawnPrefabAtLandPlotNearInst("adventure_portal",portal,1000,0,1000,nil,150,150)
                    if spawn~=nil then
                        helpers.SpawnPrefabAtLandPlotNearInst("knight",spawn,10,0,10,2,3,3)
                        helpers.SpawnPrefabAtLandPlotNearInst("bishop",spawn,10,0,10,2,3,3)
                    else
                        print("Teleportato: ERROR failed to spawn missing adventure_portal")
                    end
                end
            end
        end
    end)
 
    _G.TUNING.TELEPORTATOMOD.LEVELINFOLOADED = true
end

-- print("WORLDS tele modmain:")
-- print(_G.next(WORLDS))





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
if not helpers.exists_in_table("functionpostloadworldONCE",_G.TUNING.TELEPORTATOMOD) then
    _G.TUNING.TELEPORTATOMOD.functionpostloadworldONCE = nil
end

local function TitleStufff(inst) -- inst is player
    -- print("TitleStufff")
    if _G.ThePlayer==inst and inst.HUD and _G.TheWorld:HasTag("forest") then -- we have to use this TAg check instead of ismastershard, because otherwise it will return false for clients
        -- print("TitleStufff1")
        _G.TUNING.TELEPORTATOMOD.CHAPTER = _G.TUNING.TELEPORTATOMOD.CHAPTER or inst.mynetvarAdvChapter:value()
        _G.TUNING.TELEPORTATOMOD.LEVEL = _G.TUNING.TELEPORTATOMOD.LEVEL or inst.mynetvarAdvLevel:value()
        local chapter = _G.TUNING.TELEPORTATOMOD.CHAPTER
        local level = _G.TUNING.TELEPORTATOMOD.LEVEL
        
        local title = "test"
        local subtitle = "test"
        if chapter and chapter > 1 then -- show title and chapter
            title = WORLDS[level].name
            subtitle = _G.STRINGS.UI.SANDBOXMENU.CHAPTERS[chapter-1] -- our chapter goes from 1 to 7 (including prologue and epilogue), while DS chapter goes from 1 to 5/6
        elseif chapter and chapter == 1 then
            title = WORLDS[level].name
            subtitle = "Prologue"
        end
        print("HIER TITLESTUFF funktion chapter: "..tostring(chapter).."title: "..tostring(title).." subtitle: "..tostring(subtitle))
        _G.TheFrontEnd:ShowTitle(title,subtitle)
        
        -- following does not work so well, sometimes works, sometimes not, so we simply remove it
        -- GLOBAL.TheFrontEnd:Fade(true, 1, function() -- makes screen unclickable afterwards. first number is the time the fading out takes (then first function is called). second number is the time to screen will stay (then second function is called). the second funtion is called before the first
            -- GLOBAL.SetPause(false) -- SetPause(false) fixes it 
            -- GLOBAL.TheFrontEnd:HideTitle()
        -- end, 4 ,function() GLOBAL.SetPause(false) end, "white")        
    end
end


local function StartItems(inst)
    print("HIER startitems LEVEL: "..tostring(_G.TUNING.TELEPORTATOMOD.LEVEL).." CHAPTER: "..tostring(_G.TUNING.TELEPORTATOMOD.CHAPTER))
    if SERVER_SIDE and _G.TheWorld.ismastershard then
        -- print("mynetvarTitleStufff:set")
        inst.mynetvarTitleStufff:set(1) -- send info to clients, to show the game title at game start
    end
    if _G.TUNING.TELEPORTATOMOD.functionatplayerfirstspawn~=nil then -- eg spawn some stuff for plaers joining the first time
        _G.TUNING.TELEPORTATOMOD.functionatplayerfirstspawn(inst)
    end
end



local function OnDirtyEventTitleStufff(inst) -- this is called on client, if the server does inst.mynetvarTitleStufff:set(...)
    -- print("OnDirtyEventTitleStufff")
    if CLIENT_SIDE then -- only on client .. 
        local val = inst.mynetvarTitleStufff:value()
        -- print("OnDirtyEventTitleStufff2 "..tostring(val))
        if val==1 then
            inst:DoTaskInTime(0.01,TitleStufff)
        end
    end
end

local function DoPlayerStuffAfterLevelLoaded(inst)
    print("DoPlayerStuffAfterLevelLoaded")
    if SERVER_SIDE and inst.mynetvarLEVELINFOLOADED:value()==false then
        inst.mynetvarLEVELINFOLOADED:set(_G.TUNING.TELEPORTATOMOD.LEVELINFOLOADED) -- now it is 100% true
    end
    if _G.next(WORLDS) then
        if SERVER_SIDE and inst.mynetvarAdvLevel:value()==0 then -- if it was not already set prevously (eg if player and world loading are at the same time)
            -- print("SetChapterStuff")
            inst.mynetvarAdvChapter:set(_G.TUNING.TELEPORTATOMOD.CHAPTER)
            inst.mynetvarAdvLevel:set(_G.TUNING.TELEPORTATOMOD.LEVEL)
        end
        -- StartItems(inst)
        inst.components.adv_startstuff:DoStartStuffNow(StartItems,"StartItems")
    end
end


local function OnPlayerPostInit(inst) -- called for server and client
    print("OnPlayerPostInit")
    
    inst.mynetvarLEVELINFOLOADED = _G.net_bool(inst.GUID, "LEVELINFOLOADEDNetStuff", "DirtyEventLEVELINFOLOADED") -- true or false
    inst.mynetvarLEVELINFOLOADED:set(false) -- set a default value
    if CLIENT_SIDE then
        inst:ListenForEvent("DirtyEventLEVELINFOLOADED", function(inst) _G.TUNING.TELEPORTATOMOD.LEVELINFOLOADED = inst.mynetvarLEVELINFOLOADED:value() end) -- also set up for client
    end
    if _G.next(WORLDS) then
        if _G.TUNING.TELEPORTATOMOD.CHAPTER==nil then -- at client it is nil
            _G.TUNING.TELEPORTATOMOD.CHAPTER = 1
        end
        if _G.TUNING.TELEPORTATOMOD.LEVEL==nil then
            _G.TUNING.TELEPORTATOMOD.LEVEL = 1
        end
        if _G.TheWorld:HasTag("forest") then--_G.TheWorld.ismastershard then
            inst.mynetvarTitleStufff = _G.net_tinybyte(inst.GUID, "TitleStufffNetStuff", "DirtyEventTitleStufff") 
            if CLIENT_SIDE then
                inst:ListenForEvent("DirtyEventTitleStufff", OnDirtyEventTitleStufff)
            end
            inst.mynetvarTitleStufff:set(0)
        end
        inst:AddComponent("adv_startstuff")
        inst.mynetvarAdvChapter = _G.net_tinybyte(inst.GUID, "AdvChapterNetStuff", "DirtyEventAdvChapter") -- value from 0 to 7
        inst.mynetvarAdvChapter:set(0) -- set a default value
        inst.mynetvarAdvLevel = _G.net_smallbyte(inst.GUID, "AdvLevelNetStuff", "DirtyEventAdvLevel") -- value from 0 to 63
        inst.mynetvarAdvLevel:set(0) -- set a default value
        inst.mynetvarAdvStartStuffDone = _G.net_string(inst.GUID, "StartStuffDoneNetStuff", "DirtyEventStartStuffDone") -- 
        inst.mynetvarAdvStartStuffDone:set("") -- set a default value
        if CLIENT_SIDE then
            inst:ListenForEvent("DirtyEventAdvChapter", function(inst) print("set chapter for client"); _G.TUNING.TELEPORTATOMOD.CHAPTER = inst.mynetvarAdvChapter:value() end) -- also set up the LEVEL/CHAPTER for client
            inst:ListenForEvent("DirtyEventAdvLevel", function(inst) print("set level for client"); _G.TUNING.TELEPORTATOMOD.LEVEL = inst.mynetvarAdvLevel:value() end) -- also set up the LEVEL/CHAPTER for client
            inst:ListenForEvent("DirtyEventStartStuffDone", function(inst) if inst.components.adv_startstuff.done==nil then inst.components.adv_startstuff.done={} end; local val=inst.mynetvarAdvStartStuffDone:value(); print("set adv_startstuffdone for client "..tostring(val)); if val~=nil then inst.components.adv_startstuff.done[val]=true end; end) -- also set up for client
        end
        -- inst.adv_startstuffdone = {} -- we also save it directly in inst, cause components will not load for clients
        -- inst.OnLoad = function(inst,data)
            -- print("load adv_startstuffdone")
            -- inst.adv_startstuffdone = data~=nil and data.adv_startstuffdone or {}
        -- end
        -- inst.OnSave = function(inst,data)
            -- print("save adv_startstuffdone")
            -- data.adv_startstuffdone = inst.adv_startstuffdone or nil
        -- end
    end
    if SERVER_SIDE then
        inst.mynetvarLEVELINFOLOADED:set(_G.TUNING.TELEPORTATOMOD.LEVELINFOLOADED) -- may be true already
        if _G.TUNING.TELEPORTATOMOD.LEVELINFOLOADED==true and _G.next(WORLDS) then -- then already set it up here to save time
            -- print("SetChapterStuff")
            inst.mynetvarAdvChapter:set(_G.TUNING.TELEPORTATOMOD.CHAPTER)
            inst.mynetvarAdvLevel:set(_G.TUNING.TELEPORTATOMOD.LEVEL)
        end
    end
    inst:DoTaskInTime(0,helpers.CallthisfnIfthatfnIsTrue,DoPlayerStuffAfterLevelLoaded,IsLEVELINFOLOADED,100,inst)
end
AddPlayerPostInit(OnPlayerPostInit)
if _G.next(WORLDS) then -- if another mod wants us to load a specific world
    -- print("WORLDS tele modmain MIT WORLDS")
    local function ConfirmAdventure(player, portal, answer)
        if type(portal) == "table" then
            if answer then
                if portal.StartAdventure then
                    portal:StartAdventure(GetModConfigData("adv_itemcarrysandbox"))
                end
            else
                if portal.RejectAdventure then
                    portal:RejectAdventure()
                end
            end
        end
    end
    AddModRPCHandler("adventureSerp", "confirm", ConfirmAdventure)
-- else
    -- print("WORLDS tele modmain KEINE WORLDS")
end



--#############################################################






if not (_G.TheNet:GetIsServer() or _G.TheNet:IsDedicated())then 
    return
end


local function DoTheWorldJump(inst,doer) -- inst has to be the teleportato_base
    local counter = helpers.CheckHowManyPlayers(inst)
    local totalnumberofplayers = _G.TheWorld.shard.components.shard_players:GetNumPlayers()
    local thenetnumberofplayers = _G.TheNet:GetPlayerCount()
    if totalnumberofplayers~=thenetnumberofplayers then
        print("Teleportato: TheNet playercount: "..tostring(thenetnumberofplayers).." vs the globalplayerscount: "..tostring(totalnumberofplayers))
    end
    local NeededPlayers = _G.TUNING.TELEPORTATOMOD.min_players=="half" and totalnumberofplayers/2 or _G.TUNING.TELEPORTATOMOD.min_players=="all" and totalnumberofplayers or _G.TUNING.TELEPORTATOMOD.min_players
    if (_G.TUNING.TELEPORTATOMOD.min_players=="half" and counter > NeededPlayers) or counter >= NeededPlayers then
        _G.TheNet:Announce("Worldjump!")
        inst:DoTaskInTime(4, function() inst.AnimState:PlayAnimation("laugh", false) ; inst.AnimState:PushAnimation("active_idle", true) ; inst.SoundEmitter:PlaySound("dontstarve/common/teleportato/teleportato_maxwelllaugh", "teleportato_laugh") end)
        _G.TheWorld:DoTaskInTime(6.46, function(world) _G.TheFrontEnd:Fade(false,1) end)
        _G.TheWorld:DoTaskInTime(2.11, function(world) for k,v in pairs(_G.AllPlayers) do v.sg:GoToState("teleportato_teleport") end end)
        _G.TheWorld:DoTaskInTime(8, function(world)
            if SERVER_SIDE and world.ismastershard then
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



local function RecognizeTelePart(world,inst) -- call this only once for every part after world is generated and loaded! if more than one of each part exist, we do not remove them, only one will be saved
    -- print("RecognizeTelePart0 "..tostring(world).." "..tostring(inst))
    if TUNING.TELEPORTATOMOD.IsWorldWithTeleportato()==true then
        -- print("RecognizeTelePart "..tostring(world).." "..tostring(inst))
        if inst~=nil then
            if world.components.adv_startstuff.partpositions==nil then
                world.components.adv_startstuff.partpositions = {}
            end
            if world.components.adv_startstuff.partpositions[inst.prefab]==nil then
                world.components.adv_startstuff.partpositions[inst.prefab] = inst:GetPosition() -- is saved and loaded within this components
                -- print("RecognizeTelePart set position for "..tostring(inst.prefab).." to "..tostring(world.components.adv_startstuff.partpositions[inst.prefab]))
            end
            -- print(_G.GetTableSize(world.components.adv_startstuff.partpositions))
            if _G.GetTableSize(world.components.adv_startstuff.partpositions)==5 and not _G.TUNING.TELEPORTATOMOD.DSlike then -- if the last part was added, spawn the eneimies around them
                -- print("call SpawnEnemies")
                helpers.SpawnEnemies(inst,world) -- some enemies at start of the game at the part positions
            end
        end
    end
end


        -- _G.TheWorld.components.adv_startstuff:DoStartStuffIn(0,RecognizeTelePart,"RecognizeTelePart"..inst.prefab,inst)

local function TeleportatoPostInit(inst)
    -- print("TeleportatoPostInit")
    
    inst:DoTaskInTime(0,helpers.CallthisfnIfthatfnIsTrue,_G.TheWorld.components.adv_startstuff.DoStartStuffNow,IsLEVELINFOLOADED,100,_G.TheWorld.components.adv_startstuff,RecognizeTelePart,"RecognizeTelePart"..inst.prefab,inst)
    
    if not _G.TUNING.TELEPORTATOMOD.DSlike then
        inst:DoTaskInTime(5, DoRegeneratePlayers)
    end
    
    local _OnSave = inst.OnSave
    local function OnSave(inst,data)
        if _OnSave~=nil then
            _OnSave(inst,data) -- call the previous
        end
        data.activatedonce = inst.activatedonce
        data.completed = inst.completed
    end
    inst.OnSave = OnSave
    
    local _OnLoad = inst.OnLoad
    local function OnLoad(inst,data)
        if _OnLoad~=nil then
            _OnLoad(inst,data) -- call the previous
        end
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
            local totalnumberofplayers = _G.TheWorld.shard.components.shard_players:GetNumPlayers()
            local thenetnumberofplayers = _G.TheNet:GetPlayerCount()
            if totalnumberofplayers~=thenetnumberofplayers then
                print("Teleportato: TheNet playercount: "..tostring(thenetnumberofplayers).." vs the globalplayerscount: "..tostring(totalnumberofplayers))
            end
            local NeededPlayers = _G.TUNING.TELEPORTATOMOD.min_players=="half" and totalnumberofplayers/2 or _G.TUNING.TELEPORTATOMOD.min_players=="all" and totalnumberofplayers or _G.TUNING.TELEPORTATOMOD.min_players
            if (_G.TUNING.TELEPORTATOMOD.min_players=="half" and counter > NeededPlayers) or counter >= NeededPlayers then
                _G.TheNet:Announce("Leave teleportato area, if you dont want a new world within 15 seconds!")
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
                    inst:DoTaskInTime(5+2, helpers.SpawnEnemies,_G.TheWorld) -- some new enemies at parts positions
                end
            end
            inst.completed = true
        end
    end
    inst.components.trader.onaccept = ItemGet
end
AddPrefabPostInit("teleportato_base", TeleportatoPostInit) 



AddPrefabPostInit("world", function(world) -- prefabpostinits are never called for clients
    
    if SERVER_SIDE then -- just to make it more clear that everything is server
        -- print("worldpostinit")
        world:DoTaskInTime(0,function() LoadLevelAndDoStuff(world) end)
        
        if world.ismastershard or _G.TUNING.TELEPORTATOMOD.GEMAPIActive then -- with APIGem we also add worldjump to cave with limited functionality to get info about players in caves
            world:AddComponent("worldjump")
        end
        if world.ismastershard and _G.next(WORLDS) then  -- telebase and these componets only to the mastershard. teleparts can be transferred between worlds.
            world:AddComponent("adventurejump") -- better add this after worldjump, cause the jump itself uses worldjump
        end
        world:AddComponent("adv_startstuff") -- aldo add this to client

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
        
    end
end)

for _, prefab in ipairs({"teleportato_potato","teleportato_box","teleportato_ring","teleportato_crank"}) do
    AddPrefabPostInit(prefab, function(inst)
        helpers.MakeSlowPick(inst)
        inst:DoTaskInTime(0,helpers.CallthisfnIfthatfnIsTrue,_G.TheWorld.components.adv_startstuff.DoStartStuffNow,IsLEVELINFOLOADED,100,_G.TheWorld.components.adv_startstuff,RecognizeTelePart,"RecognizeTelePart"..inst.prefab,inst)
        -- _G.TheWorld.components.adv_startstuff:DoStartStuffIn(0,RecognizeTelePart,"RecognizeTelePart"..inst.prefab,inst)
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
        _G.TheWorld:DoTaskInTime(13.46, function(world) if SERVER_SIDE and world.ismastershard then _G.TheFrontEnd:Fade(false,1) end end)
        _G.TheWorld:DoTaskInTime(8.11, function(world) if SERVER_SIDE and world.ismastershard then for k,v in pairs(_G.AllPlayers) do v.sg:GoToState("teleportato_teleport") end end end)
		_G.TheWorld:DoTaskInTime(15, function(world)
			if SERVER_SIDE and world.ismastershard then
				if _G.next(WORLDS) then -- if another mod wants us to load a specific world
                    world.components.adventurejump:DoJump(_G.TUNING.TELEPORTATOMOD.agesave,_G.TUNING.TELEPORTATOMOD.inventorysave,_G.TUNING.TELEPORTATOMOD.recipesave) -- transfer days, recipes and inventory
                else
                    world.components.worldjump:DoJump(_G.TUNING.TELEPORTATOMOD.agesave,_G.TUNING.TELEPORTATOMOD.inventorysave,_G.TUNING.TELEPORTATOMOD.recipesave)
                end
			end
		end)
	end,
})
