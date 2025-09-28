

---------------------------
-- ## Add more options to existing game settings. 
-- this is an example to add 3 and 5 days to all season lengths. Requires upvaluehacker (google for it if you dont have it)
local UpvalueHacker = GLOBAL.require("upvaluehacker")
local customize = GLOBAL.require("map/customize")
local WSO = require("worldsettings_overrides")
local RefreshWorldTabs = UpvalueHacker.GetUpvalue(customize.RemoveCustomizeGroup, "RefreshWorldTabs")
local customize_descriptions = UpvalueHacker.GetUpvalue(customize.GetDescription, "descriptions")

local new_seasonlengths = {{ text = "3 days", data = "3__daysseason", pos=1 },{ text = "5 days", data = "5__daysseason", pos=2 }}
for _,length in ipairs(new_seasonlengths) do
    table.insert(customize_descriptions.season_length_descriptions,length.pos,length)
end
UpvalueHacker.SetUpvalue(customize.GetDescription, customize_descriptions, "descriptions")
RefreshWorldTabs() -- refresh to display new settings

local seasons = {"autumn","summer","spring","winter"}
for i,season in ipairs(seasons) do
    local old_fn = WSO.Post[season]
    WSO.Post[season] = function(difficulty,...)
        if string.find(difficulty,"__") then
            local diff_split = difficulty:split("__") -- this way we get the desired length number from aboves data string
            GLOBAL.TheWorld:PushEvent("ms_setseasonlength", {season = season, length = diff_split[1]})
        elseif old_fn~=nil then
            return old_fn(difficulty,...)
        end
    end
end

local _G = GLOBAL
local Wset = _G.LEVELCATEGORY.SETTINGS -- just shortnaming
local Wgen = _G.LEVELCATEGORY.WORLDGEN

---------------------------


if GLOBAL.rawget(GLOBAL, "TheFrontEnd") and GLOBAL.rawget(GLOBAL, "IsInFrontEnd") and GLOBAL.IsInFrontEnd() then return end -- only load to generate the world
-- if not (GLOBAL.rawget(GLOBAL, "IsInFrontEnd") and GLOBAL.IsInFrontEnd()==false) then return end -- only WSO Änderung wird übernommen..
-- if not (GLOBAL.rawget(GLOBAL, "TheFrontEnd")==nil and GLOBAL.rawget(GLOBAL, "IsInFrontEnd")==nil) then return end -- only AddLevelPreInitAny wird ausgeführt..
-- Important PROBLEM
-- modworldgenmain runs 3 times:
--   one time in the modsettings screen when IsInFrontEnd is true (only stuff that changes settings selection should be done there)
--   one time while IsInFrontEnd is false -> only worldsetting stuff is done, like overwriting the WSO
--   one time while GLOBAL.rawget(GLOBAL, "IsInFrontEnd") is nil -> I guess this is for worldgeneration, at least AddLevelPreInitAny is called.
-- and the problem is that all calls don't have a connection. Variables defined in one are not useable in the other. 
-- in modmain, ONLY the stuff that was defined in the WSO call (IsFrontEnd false) is usable eg. TELEPORTATOMOD variables!
----
-- dedicated servers have a leveldataoverride.lua .. maybe we can also use that one? No time for testing...
-- ##########################


local helpers = _G.require("tele_helpers") 
-- Adventure stuff
-- print("HIER modworldgenmain tele "..tostring(_G.TUNING.TELEPORTATOMOD))

-- ideas for more worlds mods:
-- a world basically the same like default forest, but with more islands.
-- combine mods like multi_worlds?

local function IsModLoaded(modname) -- there is no TheNet on world generation, so we use this to find out about gem api
    return GLOBAL.KnownModIndex:IsModEnabled(modname) or GLOBAL.KnownModIndex:IsModForceEnabled(modname)
end
local GEMAPIActive = IsModLoaded("workshop-1378549454")



if not _G.TUNING.TELEPORTATOMOD then
    _G.TUNING.TELEPORTATOMOD = {}
end
if not _G.TUNING.TELEPORTATOMOD.WORLDS then
    _G.TUNING.TELEPORTATOMOD.WORLDS = {} -- other mods should fill this prior. if something is in it, that world will be loaded instead
end
local WORLDS = _G.TUNING.TELEPORTATOMOD.WORLDS


local setting_do_variate_world = GetModConfigData("variateworld")
local setting_do_variate_event_chance = GetModConfigData("variate_specialevent")
local setting_variate_suck = GetModConfigData("variate_suck")
local setting_variate_islands = GetModConfigData("variate_islands")
local island_size_setting = GetModConfigData("island_size_setting")
---------------------------------


if _G.next(WORLDS) then
    -- print("HIER modworldgenmain tele MIT WORLDS")
    -- stuff from DarkXero to make adventure progress:
    local io = _G.io
    local json = _G.json
    -- local tmp_filepath = MODROOT.."adventure" -- not allowed anymore to create files there
    local tmp_filepath = "unsafedata/adventure_mod_serp.txt"

    _G.MakeTemporalAdventureFile = function(json_string)
        local advfile = io.open(tmp_filepath, "w")

        if advfile then
            advfile:write(json_string)
            advfile:close()
        end
    end

    _G.CleanTemporalAdventureFile = function()
        _G.MakeTemporalAdventureFile("")
    end

    _G.GetTemporalAdventureContent = function()
        local advfile = io.open(tmp_filepath, "r")

        if advfile == nil then
            print(modname..": no adventure override found...")
            return nil
        end

        local adventure_stuff = nil

        local advstr = advfile:read("*all")

        if advstr ~= "" then
            adventure_stuff = json.decode(advstr)
        end

        advfile:close()

        return adventure_stuff
    end
    
    -- Explanation of the WORLD table:
    -- name -> shown in title
    -- taskdatafunctions -> this function is called in AddTaskSetPreInitAny in modwordgenmain of the base mod to set the tasksetdata of the world, so your mod is loaded.
    -- location -> forest or cave
    -- positions -> only 5 maps per game are chosen. maps chosen randomly or disallow certain positions. eg. {2,3} your world may only load at second or third world. {1,2,3,4,5} your world may load regardless on which position.
    -- defaultpositions -> in case positions was set up poorly and not enough worlds are choosable to fill all chapters. Put here a table with 1 number, so display the order of worlds you put them
    -- sample: table.insert(_G.TUNING.TELEPORTATOMOD.WORLDS, {name="Two Worlds", taskdatafunctions = {forest=AdventureTwoWorlds, cave=AlwaysTinyCave}, defaultpositions={4,5}, positions=GetModConfigData("twoworlds")})
    -- more detailed sample see adventure mod from me.
    
    
    -- the following is a bit complicated code to randomly choose the level for every chapter, based on the position settings of every world.
    _G.TUNING.TELEPORTATOMOD.POSITIONS = {{},{},{},{},{},{},{}}
    for i,W in ipairs(WORLDS) do
        if W.positions~=nil and type(W.positions)=="string" then  -- is nil if there was an error loading the adventure mod
            W.positions = string.split(W.positions, ",") --W.positions:_G.split(",") -- in modconfig tables as setting are not allowed, so we used strings and have to convert them here
            for _,pos in ipairs(W.positions) do
                table.insert(_G.TUNING.TELEPORTATOMOD.POSITIONS[_G.tonumber(pos)], i)
            end
        else
            print("Teleportato ERROR: W.positions is nil? "..tostring(W.positions))
            for k,v in pairs(W) do
                print(k)
                print(v)
            end
        end
    end
    _G.TUNING.TELEPORTATOMOD.DEFAULTPOSITIONS = {{},{},{},{},{},{},{}} -- just in case user set too less worlds, then use the defaultpositions too fill
    for i,W in ipairs(WORLDS) do
        for _,pos in ipairs(W.defaultpositions) do
            table.insert(_G.TUNING.TELEPORTATOMOD.DEFAULTPOSITIONS[pos], i)
        end
    end  
    
    local positions = _G.deepcopy(_G.TUNING.TELEPORTATOMOD.POSITIONS)
    local defaultpositions = _G.deepcopy(_G.TUNING.TELEPORTATOMOD.DEFAULTPOSITIONS)
    -- important: all _GEN values are only valid after the first generation of the world! when loading an existing world, they are worng and one should use component saves instead (in modmain)
    if _G.TUNING.TELEPORTATOMOD.LEVEL_GEN==nil then -- in case another mod set it to some value to test a map, dont ooverwerite it
        _G.TUNING.TELEPORTATOMOD.CHAPTER_GEN = 1 -- _GEN is only usable if the world was just generated. In other cases use the saved chapter/level stored in adv_startstuff, done in modmain
        local adventure_stuff = _G.GetTemporalAdventureContent() -- eg. {"current_level":3,"level_list":[3,4,5,1,6,7]}
        if adventure_stuff then -- is only true, if we just adventure_jumped 
            _G.TUNING.TELEPORTATOMOD.LEVEL_GEN = adventure_stuff.level_list[adventure_stuff.current_level] or adventure_stuff.level_list[1]
            _G.TUNING.TELEPORTATOMOD.CHAPTER_GEN = adventure_stuff.current_level or 1
            print("Adventure: adventurestuff loaded successfully")
        else -- if the game was started first time and we are in sandbox world chapter 1
            local level_list = {}
            local usedefault = false
            for i=1,7 do
                level_list[i] = helpers.MyPickSome(1,positions[i])[1]
                if level_list[i]==nil then
                    usedefault = true
                    print("AdventureMod: WARNING: Not enough worlds are active, therefore modsettings are ignored and default settings used")
                    break
                end
                for k,v in pairs(positions) do
                    table.removearrayvalue(v, level_list[i]) -- remove the chosen level from the other positionpossibilites
                end
            end
            if usedefault==true then -- make it again, but with default values this time
                level_list = {}
                for i=1,7 do
                    level_list[i] = helpers.MyPickSome(1,defaultpositions[i])[1]
                    if level_list[i]==nil then
                        usedefault = "alsofailed"
                        print("AdventureMod: WARNING: also default positions failed")
                        break
                    end
                    for k,v in pairs(defaultpositions) do
                        table.removearrayvalue(v, level_list[i]) -- remove the chosen level from the other positionpossibilites
                    end
                end
            end
            if usedefault=="alsofailed" then
                level_list = {}
                if _G.TUNING.TELEPORTATOMOD.LEVEL_LIST_FALLBACK ~=nil then
                    for chapter,name in pairs(_G.TUNING.TELEPORTATOMOD.LEVEL_LIST_FALLBACK) do 
                        for level,world in pairs(WORLDS) do
                            if world.name == name then
                                level_list[chapter] = level
                            end
                        end
                    end
                else
                    print("AdventureMod: ERROR: modsetting worlds and also default worlds are not enough to cover every chapter! No LEVEL_LIST_FALLBACK defined! Make game crash now"..makecrash)
                end
            end
            
            _G.TUNING.TELEPORTATOMOD.LEVEL_LIST_GEN = level_list
            _G.TUNING.TELEPORTATOMOD.LEVEL_GEN = level_list[_G.TUNING.TELEPORTATOMOD.CHAPTER_GEN] -- the level for first chapter
        end
    end
    if _G.TUNING.TELEPORTATOMOD.CHAPTER_GEN==nil then -- in case the other modder did not set chapter
        _G.TUNING.TELEPORTATOMOD.CHAPTER_GEN = 1
    end
    print("Level gen1 is "..tostring(_G.TUNING.TELEPORTATOMOD.LEVEL_GEN).." Chapter is "..tostring(_G.TUNING.TELEPORTATOMOD.CHAPTER_GEN))
    
end


--------------------------
-------------------------------

-- Note after QoL update in 2021:
-- We still can change anything that really affects the worldgeneration within AddLevelPreInitAny.
-- But we can no longer change things that can be altered after worldgeneration, which is defined in Pre/Post within worldsettings_overrides.lua
-- the following "hack" (WSO = require("worldsettings_overrides")...), mostly written by penguin0616, tries to set the values for them when first generating the world. (and players will be able to change them in worldsettings, if they dont like it)
-- (we spend over 50 hours for this and just because Klei changed how worldsettings work and did not add a proper way for mods to change values -.-, previously the data was accessable via AddLevelPreInitAny, now the first defintion of the savadata is outside of accessable lua)

local OPTIONS = {}
OPTIONS["forest"] = customize.GetOptions("forest",true) -- read all the possible worldgeneration and worldsettings from customize.lua . TheNet and The Shard is not always awailable when we call this, so is_master_world can only be determined by forest/cave string...
OPTIONS["cave"] = customize.GetOptions("cave",false)

local function get_tele_tasksetdata_overrides(tasksetdata) -- need to put it all in this functoin, instead of AddLevelPreInitAny, because it is impossible to get the tasksetdata I set in AddLevelPreInitAny here to put it into Pre/Post
    if setting_do_variate_world then
        
        if tasksetdata.overrides==nil then
            tasksetdata.overrides = {}
        end
        
        local var_t = {} -- variation_table
        var_t["manuell"] = {} -- explicit manuel assignment (instead of automatical which is done for animals, monsters and ressources)
        local sucking_settings = {"disease_delay","wildfires","petrification","frograin","deerclops","antliontribute"} -- only variated if setting_variate_suck is true
        local random_result = nil
        local variation_string = nil
        
        if tasksetdata.location == "forest" then -- forest/master is controlling the event
            if setting_do_variate_event_chance > 0 and _G.GetRandomMinMax(0,100)<=setting_do_variate_event_chance then -- setting_do_variate_event_chance% chance
                local special_events = _G.shallowcopy(_G.SPECIAL_EVENTS)
                table.removearrayvalue(special_events, _G.SPECIAL_EVENTS.NONE) -- now they only contain special events
                local event = _G.GetRandomItem(special_events) -- choose a random one without weight
                var_t["manuell"][event] = "enabled" 
            end
        end
        
        if setting_do_variate_world~="justislands" then
            
            local shouldnt_be_never = {}
            shouldnt_be_never.forest = {"grass","sapling","reeds","trees","flint","rock_ice","berrybush","moon_rock","ocean_bullkelp","palmconetree",
                "birds","beefalo","bees","spiders"} -- without these stuff we would go gameover too fast, so do not allow "never" (but we can increase respawn/regrow time to still have it harder)
            shouldnt_be_never.cave = {"flower_cave"} -- for caves.. most can be never because we have it -not never- in forest already, so it is no gameover if it does not exist in caves

            
            var_t[tostring(Wset).."_"..tostring("giants")] = {default=100}
            var_t[tostring(Wset).."_"..tostring("monsters")] = {default=100}
            var_t[tostring(Wset).."_"..tostring("monsters_shouldnt_be_never")] = {default=100} -- used for stuff mentioned in shouldnt_be_never list
            var_t[tostring(Wset).."_"..tostring("animals")] = {default=100}
            var_t[tostring(Wset).."_"..tostring("animals_shouldnt_be_never")] = {default=100}
            var_t[tostring(Wset).."_"..tostring("resources")] = {default=100}  -- regrowth means respawn of destroyed plants (eg burnt) up to the starting amount or so.
            var_t[tostring(Wset).."_"..tostring("resources_shouldnt_be_never")] = {default=100}
            var_t[tostring(Wset).."_"..tostring("portal_resources")] = {default=100}
            -- Wset misc, survivors and global do have too different stuff, we will define them one by one later
            var_t[tostring(Wgen).."_"..tostring("monsters")] = {default=100}
            var_t[tostring(Wgen).."_"..tostring("monsters_shouldnt_be_never")] = {default=100}
            var_t[tostring(Wgen).."_"..tostring("animals")] = {default=100}
            var_t[tostring(Wgen).."_"..tostring("animals_shouldnt_be_never")] = {default=100}
            var_t[tostring(Wgen).."_"..tostring("resources")] = {default=100}
            var_t[tostring(Wgen).."_"..tostring("resources_shouldnt_be_never")] = {default=100}
            -- Wgen misc and global do have too different stuff, we will define them one by one later
            
            local plants_animals_Wgen = {default=100} -- will be used for animals and resources Wgen -> number of prefabs at game start
            local plants_animals_shouldnt_be_never_Wgen = {default=100}
            local plants_animals_Wset = {default=100} -- will be used for animals and resources Wset -> mostly respawn time and  -- regrowth means respawn of destroyed plants (eg burnt) up to the starting amount or so.
            local plants_animals_shouldnt_be_never_Wset = {default=100}
            
            local stuff = {default=100}
            local ocean_stuff = {ocean_default=100} -- currently only seastacks and waterplants, see customize.lua ocean_worldgen_frequency_descriptions. the naming is different with ocean_ prefix
            
            local more_world_settings_mod_mults = {["MODMULTS_1"]=100}

            if setting_do_variate_world==true then -- mixed

                var_t[tostring(Wset).."_"..tostring("giants")] = {never=5,rare=20,default=50,often=20,always=5}
                var_t[tostring(Wset).."_"..tostring("monsters")] = {never=5,rare=25,default=40,often=25,always=5}
                var_t[tostring(Wgen).."_"..tostring("monsters")] = {never=5,rare=10,uncommon=20,default=28,often=20,mostly=10,always=5,insane=2}
                var_t[tostring(Wset).."_"..tostring("resources")] = {never=5,veryslow=10,slow=25,default=35,fast=20,veryfast=5}
                plants_animals_Wgen = {never=5,rare=10,uncommon=20,default=28,often=20,mostly=10,always=5,insane=2} -- will be used for animals and resources Wgen
                plants_animals_Wset = {never=5,rare=25,default=40,often=25,always=5} -- will be used for animals and resources Wset
                stuff = {never=0,rare=20,default=50,often=25,always=5}
                ocean_stuff = {ocean_never=0,ocean_rare=5,ocean_uncommon=20,ocean_default=40,ocean_often=20,ocean_mostly=10,ocean_always=5,ocean_insane=0}
                
                -- no need to differentiate between location forest or caves, unless we want different chances (then add a if/elseif condition)
                var_t["manuell"].touchstone = {never=5,rare=10,uncommon=15,default=20,often=20,mostly=15,always=10,insane=5}
                var_t["manuell"].chess = {never=0,rare=0,uncommon=0,default=73,often=12,mostly=8,always=5,insane=2} -- default or below does nothing. above default it will place small groups of clockworks aroudn the world with a chance in every biome

                var_t["manuell"].autumn = {noseason=2,veryshortseason=10,shortseason=25,default=38,longseason=25,verylongseason=10}
                var_t["manuell"].winter = {noseason=2,veryshortseason=10,shortseason=25,default=38,longseason=25,verylongseason=10}
                var_t["manuell"].spring = {noseason=2,veryshortseason=10,shortseason=25,default=38,longseason=25,verylongseason=10}
                var_t["manuell"].summer = {noseason=2,veryshortseason=10,shortseason=25,default=38,longseason=25,verylongseason=10}
                
                var_t["manuell"].season_start = {summer=10,spring=20,default=45,winter=25} -- default is autumn
                var_t["manuell"].day = {default=25,longday=15,longdusk=15,longnight=15,noday=5,nodusk=5,nonight=5,onlyday=5,onlydusk=5,onlynight=5}
                var_t["manuell"].roads = {never=30,default=70}
                var_t["manuell"].lightning = {never=5,rare=25,default=45,often=25,always=0} -- never allow always, because this is just impossible...
                
                 -- some stuff that may suck, wont be changed if in sucking_settings and setting_variate_suck is false:
                var_t["manuell"].disease_delay = {none=5,random=20,short=5,default=60,long=10} -- nothing has the component diseaseable anymore, so does nothing
                var_t["manuell"].wildfires = stuff
                var_t["manuell"].petrification = {none=5,few=20,default=50,many=20,max=5}
                var_t["manuell"].frograin = stuff
                
                -- support for my more worldsettings mod with mults (we could do this with variable code (eg treat mult as chance), but it would be too random I think)
                more_world_settings_mod_mults = {["MODMULTS_0.1"]=5, ["MODMULTS_0.3"]=10, ["MODMULTS_0.5"]=10, ["MODMULTS_0.7"]=10, ["MODMULTS_1"]=15, ["MODMULTS_1.25"]=15, ["MODMULTS_1.5"]=13, ["MODMULTS_2"]=5, ["MODMULTS_2.5"]=5, ["MODMULTS_3"]=5, ["MODMULTS_5"]=5, ["MODMULTS_10"]=2 }

            elseif setting_do_variate_world=="easy" then
                var_t[tostring(Wset).."_"..tostring("giants")] = {never=20,rare=60,default=20,often=0,always=0}
                var_t[tostring(Wset).."_"..tostring("monsters")] = {never=0,rare=10,default=80,often=10,always=0}
                var_t[tostring(Wgen).."_"..tostring("monsters")] = {never=0,rare=5,uncommon=30,default=60,often=5,mostly=0,always=0,insane=0}
                var_t[tostring(Wset).."_"..tostring("resources")] = {never=0,veryslow=0,slow=5,default=60,fast=20,veryfast=15}
                plants_animals_Wgen = {never=0,rare=0,uncommon=10,default=43,often=30,mostly=10,always=5,insane=2} -- will be used for animals and resources Wgen
                plants_animals_Wset = {never=0,rare=5,default=50,often=35,always=10} -- will be used for animals and resources Wset
                
                stuff = {never=0,rare=5,default=90,often=5,always=0}
                ocean_stuff = {ocean_never=5,ocean_rare=10,ocean_uncommon=30,ocean_default=55,ocean_often=0,ocean_mostly=0,ocean_always=0,ocean_insane=0}
                
                var_t["manuell"].touchstone = {never=0,rare=0,uncommon=0,default=0,often=10,mostly=10,always=10,insane=70}
                var_t["manuell"].chess = {never=0,rare=0,uncommon=0,default=100,often=0,mostly=0,always=0,insane=0} -- default or below does nothing. above default it will place small groups of clockworks aroudn the world with a chance in every biome

                var_t["manuell"].autumn = {noseason=0,veryshortseason=0,shortseason=25,default=40,longseason=30,verylongseason=15}
                var_t["manuell"].winter = {noseason=5,veryshortseason=20,shortseason=25,default=40,longseason=10,verylongseason=0}
                var_t["manuell"].spring = {noseason=5,veryshortseason=20,shortseason=25,default=40,longseason=10,verylongseason=0}
                var_t["manuell"].summer = {noseason=5,veryshortseason=20,shortseason=25,default=40,longseason=10,verylongseason=0}
                
                var_t["manuell"].season_start = {summer=0,spring=0,default=100,winter=0} -- default is autumn
                var_t["manuell"].day = {default=85,longday=5,longdusk=5,longnight=5,noday=0,nodusk=0,nonight=0,onlyday=0,onlydusk=0,onlynight=0}
                var_t["manuell"].lightning = {never=0,rare=30,default=70,often=0,always=0} -- never allow always, because this is just impossible...


                 -- some stuff that may suck, wont be changed if in sucking_settings and setting_variate_suck is false:
                var_t["manuell"].disease_delay = {none=50,random=5,short=0,default=25,long=20} -- nothing has the component diseaseable anymore, so does nothing
                var_t["manuell"].wildfires = {never=50,rare=30,default=20,often=0,always=0}
                var_t["manuell"].petrification = {none=15,few=35,default=50,many=0,max=0}
                var_t["manuell"].frograin = {never=50,rare=30,default=20,often=0,always=0}

                -- support for my more worldsettings mod with mults (we could do this with variable code (eg treat mult as chance), but it would be too random I think)
                more_world_settings_mod_mults = {["MODMULTS_0.1"]=10, ["MODMULTS_0.3"]=10, ["MODMULTS_0.5"]=20, ["MODMULTS_0.7"]=30, ["MODMULTS_1"]=30, ["MODMULTS_1.25"]=0, ["MODMULTS_1.5"]=0, ["MODMULTS_2"]=0, ["MODMULTS_2.5"]=0, ["MODMULTS_3"]=0, ["MODMULTS_5"]=0, ["MODMULTS_10"]=0 }

            elseif setting_do_variate_world=="medium" then
                var_t[tostring(Wset).."_"..tostring("giants")] = {never=5,rare=20,default=65,often=10,always=0}
                var_t[tostring(Wset).."_"..tostring("monsters")] = {never=0,rare=20,default=60,often=20,always=0}
                var_t[tostring(Wgen).."_"..tostring("monsters")] = {never=0,rare=5,uncommon=20,default=50,often=20,mostly=5,always=0,insane=0}
                var_t[tostring(Wset).."_"..tostring("resources")] = {never=0,veryslow=0,slow=15,default=70,fast=15,veryfast=0}
                plants_animals_Wgen = {never=2,rare=5,uncommon=15,default=51,often=15,mostly=5,always=5,insane=2} -- will be used for animals and resources Wgen
                plants_animals_Wset = {never=2,rare=20,default=53,often=20,always=5} -- will be used for animals and resources Wset
                
                stuff = {never=0,rare=20,default=65,often=15,always=0}
                ocean_stuff = {ocean_never=0,ocean_rare=5,ocean_uncommon=15,ocean_default=55,ocean_often=20,ocean_mostly=5,ocean_always=0,ocean_insane=0}
                
                var_t["manuell"].touchstone = {never=0,rare=5,uncommon=10,default=65,often=10,mostly=5,always=3,insane=2}
                var_t["manuell"].chess = {never=0,rare=0,uncommon=0,default=95,often=5,mostly=0,always=0,insane=0} -- default or below does nothing. above default it will place small groups of clockworks aroudn the world with a chance in every biome

                var_t["manuell"].autumn = {noseason=2,veryshortseason=10,shortseason=20,default=53,longseason=20,verylongseason=5}
                var_t["manuell"].winter = {noseason=2,veryshortseason=10,shortseason=20,default=53,longseason=20,verylongseason=5}
                var_t["manuell"].spring = {noseason=2,veryshortseason=10,shortseason=20,default=53,longseason=20,verylongseason=5}
                var_t["manuell"].summer = {noseason=2,veryshortseason=10,shortseason=20,default=53,longseason=20,verylongseason=5}
                
                var_t["manuell"].season_start = {summer=2,spring=15,default=80,winter=3} -- default is autumn
                var_t["manuell"].day = {default=55,longday=15,longdusk=15,longnight=15,noday=0,nodusk=0,nonight=0,onlyday=0,onlydusk=0,onlynight=0}
                var_t["manuell"].lightning = {never=0,rare=0,default=100,often=0,always=0} -- never allow always, because this is just impossible...

                
                 -- some stuff that may suck, wont be changed if in sucking_settings and setting_variate_suck is false:
                var_t["manuell"].disease_delay = {none=5,random=5,short=5,default=55,long=30} -- nothing has the component diseaseable anymore, so does nothing
                var_t["manuell"].wildfires = {never=5,rare=20,default=72,often=3,always=0}
                var_t["manuell"].petrification = {none=5,few=20,default=50,many=20,max=5}
                var_t["manuell"].frograin = {never=5,rare=25,default=60,often=10,always=0}
                
                -- support for my more worldsettings mod with mults (we could do this with variable code (eg treat mult as chance), but it would be too random I think)
                more_world_settings_mod_mults = {["MODMULTS_0.1"]=5, ["MODMULTS_0.3"]=5, ["MODMULTS_0.5"]=5, ["MODMULTS_0.7"]=20, ["MODMULTS_1"]=30, ["MODMULTS_1.25"]=20, ["MODMULTS_1.5"]=5, ["MODMULTS_2"]=5, ["MODMULTS_2.5"]=5, ["MODMULTS_3"]=0, ["MODMULTS_5"]=0, ["MODMULTS_10"]=0 }

            elseif setting_do_variate_world=="hard" then
                var_t[tostring(Wset).."_"..tostring("giants")] = {never=0,rare=5,default=65,often=25,always=5}
                var_t[tostring(Wset).."_"..tostring("monsters")] = {never=5,rare=25,default=40,often=25,always=5}
                var_t[tostring(Wgen).."_"..tostring("monsters")] = {never=3,rare=10,uncommon=20,default=30,often=20,mostly=10,always=5,insane=2}
                var_t[tostring(Wset).."_"..tostring("resources")] = {never=2,veryslow=20,slow=35,default=40,fast=3,veryfast=0}
                plants_animals_Wgen = {never=2,rare=20,uncommon=25,default=30,often=20,mostly=3,always=0,insane=0} -- will be used for animals and resources Wgen
                plants_animals_Wset = {never=5,rare=45,default=40,often=10,always=0} -- will be used for animals and resources Wset
                
                stuff = {never=0,rare=15,default=50,often=30,always=5}
                ocean_stuff = {ocean_never=0,ocean_rare=0,ocean_uncommon=0,ocean_default=45,ocean_often=40,ocean_mostly=10,ocean_always=5,ocean_insane=0}
                
                var_t["manuell"].touchstone = {never=5,rare=15,uncommon=30,default=50,often=0,mostly=0,always=0,insane=0}
                var_t["manuell"].chess = {never=0,rare=0,uncommon=0,default=80,often=15,mostly=5,always=0,insane=0} -- default or below does nothing. above default it will place small groups of clockworks aroudn the world with a chance in every biome

                var_t["manuell"].autumn = {noseason=5,veryshortseason=60,shortseason=25,default=10,longseason=0,verylongseason=0}
                var_t["manuell"].winter = {noseason=5,veryshortseason=10,shortseason=10,default=20,longseason=20,verylongseason=35}
                var_t["manuell"].spring = {noseason=5,veryshortseason=20,shortseason=20,default=20,longseason=10,verylongseason=25}
                var_t["manuell"].summer = {noseason=5,veryshortseason=10,shortseason=10,default=20,longseason=20,verylongseason=35}
                
                var_t["manuell"].season_start = {summer=25,spring=25,default=25,winter=25} -- default is autumn
                var_t["manuell"].day = {default=31,longday=15,longdusk=15,longnight=15,noday=5,nodusk=5,nonight=5,onlyday=3,onlydusk=3,onlynight=3}
                var_t["manuell"].lightning = {never=0,rare=0,default=80,often=20,always=0} -- never allow always, because this is just impossible...

                 -- some stuff that may suck, wont be changed if in sucking_settings and setting_variate_suck is false:
                var_t["manuell"].disease_delay = {none=0,random=20,short=25,default=45,long=10}  -- nothing has the component diseaseable anymore, so does nothing
                var_t["manuell"].wildfires = {never=0,rare=10,default=60,often=25,always=5}
                var_t["manuell"].petrification = {none=5,few=10,default=50,many=30,max=5}
                var_t["manuell"].frograin = {never=0,rare=5,default=75,often=15,always=5}
                
                -- support for my more worldsettings mod with mults (we could do this with variable code (eg treat mult as chance), but it would be too random I think)
                more_world_settings_mod_mults = {["MODMULTS_0.1"]=2, ["MODMULTS_0.3"]=3, ["MODMULTS_0.5"]=4, ["MODMULTS_0.7"]=5, ["MODMULTS_1"]=31, ["MODMULTS_1.25"]=15, ["MODMULTS_1.5"]=10, ["MODMULTS_2"]=10, ["MODMULTS_2.5"]=10, ["MODMULTS_3"]=8, ["MODMULTS_5"]=2, ["MODMULTS_10"]=0 }

            elseif setting_do_variate_world=="very hard" then
                var_t[tostring(Wset).."_"..tostring("giants")] = {never=0,rare=0,default=50,often=30,always=20}
                var_t[tostring(Wset).."_"..tostring("monsters")] = {never=20,rare=20,default=20,often=20,always=20}
                var_t[tostring(Wgen).."_"..tostring("monsters")] = {never=5,rare=15,uncommon=20,default=15,often=20,mostly=10,always=10,insane=5}
                var_t[tostring(Wset).."_"..tostring("resources")] = {never=15,veryslow=35,slow=40,default=10,fast=0,veryfast=0}
                plants_animals_Wgen = {never=5,rare=25,uncommon=50,default=20,often=0,mostly=0,always=0,insane=0} -- will be used for animals and resources Wgen
                plants_animals_Wset = {never=10,rare=70,default=20,often=0,always=0} -- will be used for animals and resources Wset
                
                stuff = {never=0,rare=10,default=45,often=30,always=15}
                ocean_stuff = {ocean_never=0,ocean_rare=0,ocean_uncommon=0,ocean_default=40,ocean_often=35,ocean_mostly=15,ocean_always=5,ocean_insane=5}
                
                var_t["manuell"].touchstone = {never=20,rare=40,uncommon=30,default=10,often=0,mostly=0,always=0,insane=0}
                var_t["manuell"].chess = {never=0,rare=0,uncommon=0,default=50,often=35,mostly=10,always=3,insane=2} -- default or below does nothing. above default it will place small groups of clockworks aroudn the world with a chance in every biome

                var_t["manuell"].autumn = {noseason=20,veryshortseason=70,shortseason=10,default=0,longseason=0,verylongseason=0}
                var_t["manuell"].winter = {noseason=5,veryshortseason=10,shortseason=10,default=20,longseason=20,verylongseason=35}
                var_t["manuell"].spring = {noseason=5,veryshortseason=20,shortseason=20,default=20,longseason=10,verylongseason=25}
                var_t["manuell"].summer = {noseason=5,veryshortseason=10,shortseason=10,default=20,longseason=20,verylongseason=35}
               
                var_t["manuell"].season_start = {summer=40,spring=27,default=5,winter=28} -- default is autumn
                var_t["manuell"].day = {default=10,longday=15,longdusk=15,longnight=20,noday=10,nodusk=10,nonight=5,onlyday=5,onlydusk=5,onlynight=5}
                var_t["manuell"].roads = "never"
                var_t["manuell"].lightning = {never=0,rare=0,default=60,often=40,always=0} -- never allow always, because this is just impossible...
                
                 -- some stuff that may suck, wont be changed if in sucking_settings and setting_variate_suck is false:
                var_t["manuell"].disease_delay = {none=0,random=20,short=60,default=10,long=0}  -- nothing has the component diseaseable anymore, so does nothing
                var_t["manuell"].wildfires = {never=0,rare=0,default=40,often=35,always=25}
                var_t["manuell"].petrification = {none=0,few=5,default=40,many=35,max=20}
                var_t["manuell"].frograin = {never=0,rare=0,default=50,often=35,always=15}
                
                -- support for my more worldsettings mod with mults (we could do this with variable code (eg treat mult as chance), but it would be too random I think)
                more_world_settings_mod_mults = {["MODMULTS_0.1"]=1, ["MODMULTS_0.3"]=2, ["MODMULTS_0.5"]=3, ["MODMULTS_0.7"]=4, ["MODMULTS_1"]=10, ["MODMULTS_1.25"]=10, ["MODMULTS_1.5"]=10, ["MODMULTS_2"]=20, ["MODMULTS_2.5"]=20, ["MODMULTS_3"]=12, ["MODMULTS_5"]=5, ["MODMULTS_10"]=3 }

                
            end
            
            -- set the "shouldnt_be_never" chances by simply moving the "never" value to "rare"
            plants_animals_shouldnt_be_never_Wgen = _G.deepcopy(plants_animals_Wgen) -- basically the same, but we will move the stuff from "never" to "rare"
            plants_animals_shouldnt_be_never_Wgen.rare = plants_animals_shouldnt_be_never_Wgen.rare + plants_animals_shouldnt_be_never_Wgen.never
            plants_animals_shouldnt_be_never_Wgen.never = 0
            plants_animals_shouldnt_be_never_Wset = _G.deepcopy(plants_animals_Wset) -- basically the same, but we will move the stuff from "never" to "rare"
            plants_animals_shouldnt_be_never_Wset.rare = plants_animals_shouldnt_be_never_Wset.rare + plants_animals_shouldnt_be_never_Wset.never
            plants_animals_shouldnt_be_never_Wset.never = 0
            var_t[tostring(Wgen).."_"..tostring("monsters_shouldnt_be_never")] = _G.deepcopy(var_t[tostring(Wgen).."_"..tostring("monsters")]) -- basically the same, but we will move the stuff from "never" to "rare"
            var_t[tostring(Wgen).."_"..tostring("monsters_shouldnt_be_never")].rare = var_t[tostring(Wgen).."_"..tostring("monsters_shouldnt_be_never")].rare + var_t[tostring(Wgen).."_"..tostring("monsters_shouldnt_be_never")].never
            var_t[tostring(Wgen).."_"..tostring("monsters_shouldnt_be_never")].never = 0
            var_t[tostring(Wset).."_"..tostring("monsters_shouldnt_be_never")] = _G.deepcopy(var_t[tostring(Wset).."_"..tostring("monsters")]) -- basically the same, but we will move the stuff from "never" to "rare"
            var_t[tostring(Wset).."_"..tostring("monsters_shouldnt_be_never")].rare = var_t[tostring(Wset).."_"..tostring("monsters_shouldnt_be_never")].rare + var_t[tostring(Wset).."_"..tostring("monsters_shouldnt_be_never")].never
            var_t[tostring(Wset).."_"..tostring("monsters_shouldnt_be_never")].never = 0
            var_t[tostring(Wset).."_"..tostring("resources_shouldnt_be_never")] = _G.deepcopy(var_t[tostring(Wset).."_"..tostring("resources")]) -- basically the same, but we will move the stuff from "never" to "rare"
            var_t[tostring(Wset).."_"..tostring("resources_shouldnt_be_never")].veryslow = var_t[tostring(Wset).."_"..tostring("resources_shouldnt_be_never")].veryslow + var_t[tostring(Wset).."_"..tostring("resources_shouldnt_be_never")].never
            var_t[tostring(Wset).."_"..tostring("resources_shouldnt_be_never")].never = 0
            
            var_t[tostring(Wset).."_"..tostring("animals")] = plants_animals_Wset
            var_t[tostring(Wset).."_"..tostring("animals_shouldnt_be_never")] = plants_animals_shouldnt_be_never_Wset
            var_t[tostring(Wset).."_"..tostring("portal_resources")] = plants_animals_Wset
            var_t[tostring(Wgen).."_"..tostring("animals")] = plants_animals_Wgen
            var_t[tostring(Wgen).."_"..tostring("animals_shouldnt_be_never")] = plants_animals_shouldnt_be_never_Wgen
            var_t[tostring(Wgen).."_"..tostring("resources")] = plants_animals_Wgen
            var_t[tostring(Wgen).."_"..tostring("resources_shouldnt_be_never")] = plants_animals_shouldnt_be_never_Wgen
            

            -- some exceptions where we want to treat some options differently although they are in the same category and group_name
            -- eg because we did not mention the group_name in var_t because they are too different from each other
            -- or because the "desc" (so the choices) are different although they are in same group
            --   found no better way for different "desc" than this and ValidateOption
        
           -- no need to differentiate between location forest or caves, unless we want different chances (then add a if/elseif condition)
        -- ######## WorldGen ########
        -- # monsters
            var_t["manuell"].ocean_waterplant = ocean_stuff
            -- var_t["manuell"].chess = {never=0,rare=0,uncommon=0,default=100,often=0,mostly=0,always=0,insane=0} -- default or below does nothing. above default it will place small groups of clockworks aroudn the world with a chance in every biome
        -- # animals
        -- # resources
            var_t["manuell"].ocean_seastack = ocean_stuff
        -- # misc
            -- task_set
            -- start_location
            var_t["manuell"].world_size = _G.IsPS4() and {medium=50,default=50} or {small=30,medium=30,default=30,huge=10} -- PS4 has no small and huge?
            var_t["manuell"].branching = {never=20,least=20,default=35,most=20}
            var_t["manuell"].loop = {never=30,default=40,always=30}
            -- roads
            -- touchstone
            var_t["manuell"].boons = {never=5,rare=10,uncommon=15,default=20,often=20,mostly=15,always=10,insane=5} -- failed survivors
            var_t["manuell"].cavelight = var_t[tostring(Wset).."_"..tostring("resources")]
            var_t["manuell"].prefabswaps_start = {classic=10,default=50,["highly random"]=40}
            -- moon_fissure -- i dont care...
            -- terrariumchest
        -- # global
            -- var_t["manuell"].season_start = season_start_choices
        
        -- ######## WorldSettings ########
        -- # giants
            var_t["manuell"].liefs = stuff
            var_t["manuell"].deciduousmonster = stuff
        -- # monsters
            var_t["manuell"].mutated_hounds = false -- dont change it so it will use the users setting
            var_t["manuell"].penguins_moon = false -- dont change it so it will use the users setting
            var_t["manuell"].spider_warriors = false -- dont change it so it will use the users setting
        -- # animals
        -- # resources
        -- # portal_resources
        -- # misc
            -- lightning
            -- frograin
            -- wildfires
            -- petrification
            var_t["manuell"].meteorshowers = stuff
            var_t["manuell"].hunt = plants_animals_Wset
            var_t["manuell"].alternatehunt = stuff
            var_t["manuell"].hounds = stuff -- hound attacks
            var_t["manuell"].winterhounds = false -- can only be never or default, do not change it, so it is the setting from the user
            var_t["manuell"].summerhounds = false -- hound attacks, do not change it, so it is the setting from the user
            var_t["manuell"].weather = stuff -- rain
            var_t["manuell"].earthquakes = stuff
            var_t["manuell"].wormattacks = stuff
            -- atriumgate -- verylsow,slow,default,fast,veryfast -- ATRIUM_GATE_COOLDOWN, can stay on user setting
            -- disease_delay -- nothing has the component diseaseable anymore, so does nothing
        -- # survivors
            -- extrastartingitems
            -- seasonalstartingitems
            -- spawnprotection
            -- dropeverythingondespawn
            var_t["manuell"].shadowcreatures = stuff
            -- var_t["manuell"].shadowcreatures = "often" -- testing
            var_t["manuell"].brightmarecreatures = stuff
        -- # events
            -- crow_carnival
            -- hallowed_nights
            -- winters_feast
            -- year_of_the_gobbler
            -- year_of_the_varg
            -- year_of_the_pig
            -- year_of_the_carrat
            -- year_of_the_beefalo
            -- year_of_the_catcoon
        -- # global
            -- specialevent (done above)
            -- autumn
            -- winter
            -- spring
            -- summer
            -- day
            var_t["manuell"].beefaloheat = stuff
            var_t["manuell"].krampus = stuff


            
            -- add support for my More Worldsettings mod
            local weight = nil -- my mod adds multipliers from *0.01 to *10 (and never), try to weight them properly depending on difficulty chosen...
            local mult = nil
            local category = nil
            for _,item in ipairs(OPTIONS[tasksetdata.location]) do 
                if item~=nil then
                    if string.match(item.group,"MODMULT") and item.options~=nil and type(item.options)=="table" then -- MODMULT all More Settings options that add multipliers to different things and have the same structure
                        category = customize.GetCategoryForOption(item.name)
                        
                        var_t[tostring(category).."_"..tostring(item.group)] = more_world_settings_mod_mults
                        
                        -- the following code is hard to control for different difficulty settings, so it is not used anymore
                        --[[
                        var_t[tostring(category).."_"..tostring(item.group)] = {} -- MODMULT all More Settings options that add multipliers to different things and have the same structure
                        for _,desc in ipairs(item.options) do
                            if desc~=nil and desc.data~=nil then
                                mult = _G.tonumber(string.split(desc.data,"_")[2]) -- eg. desc.data == "MODMULTS_0.8"
                                if mult>1 then -- higher growtime
                                    weight = mult^-1 -- to make *0.2 as common as *5
                                    if setting_do_variate_world=="very hard" then
                                        weight = weight*20 -- make higher growtimes x times more likely than the other options
                                        if mult==1000 then -- never growing
                                            weight = weight*20 -- increase the otherwise minimal chance of "never"
                                        end
                                    elseif setting_do_variate_world=="hard" then
                                        weight = weight*10 -- make higher growtimes x times more likely than the other options
                                    elseif setting_do_variate_world=="easy" then
                                        weight = weight/2 -- make higher growtimes x times less likely than the other options
                                    elseif setting_do_variate_world==true then -- mixed
                                        weight = weight*8 -- make higher growtimes x times more likely than the other options
                                        if mult==1000 then -- never growing
                                            weight = weight*5 -- increase the otherwise minimal change of "never"
                                        end
                                    end
                                elseif mult<1 then -- less growtime
                                    weight = mult
                                    if setting_do_variate_world=="easy" then
                                        weight = weight*3 -- make lower growtimes x times more likely than the other options
                                    elseif setting_do_variate_world==true then -- mixed
                                        weight = weight*4 -- make lower growtimes x times more likely than the other options
                                    end
                                elseif mult==1 then -- default growtime
                                    weight = mult*2 -- default is always more likely
                                    if setting_do_variate_world=="easy" then
                                        weight = weight*2 -- make default growtimes x times more likely than the other options
                                    elseif setting_do_variate_world=="medium" then
                                        weight = weight*2 -- make default growtimes x times more likely than the other options
                                    end
                                end
                                weight = 100 * weight -- not necessary to multiply with 100, but also does not hurt (weighted_random_choice should be able to deal with floats)
                                var_t[tostring(category).."_"..tostring(item.group)][desc.data] = weight -- add a chance for this option
                            end
                        end
                        ]]--
                    end
                end
            end
            
            -- automatically apply our var_t to the tasksetdata.overrides
            -- also automatically makes sure only overrides are added to the correct world (because OPTIONS only contains the correct world ones and we do also ValidateOption)
            local category = nil
            for _,item in ipairs(OPTIONS[tasksetdata.location]) do
                if item~=nil and item.name~=nil then -- item.name is sth like "spiders" or "spiders_setting"
                    
                    if var_t["manuell"][item.name]~=nil then -- manual exception
                        if setting_variate_suck or not table.contains(sucking_settings,item.name) then
                            if var_t["manuell"][item.name]~=false then -- I set it manual false to not change this value
                                if type(var_t["manuell"][item.name])=="table" then
                                    random_result = _G.weighted_random_choice(var_t["manuell"][item.name])
                                else
                                    random_result = var_t["manuell"][item.name]
                                end
                                if customize.ValidateOption(item.name,random_result,tasksetdata.location) then -- make sure it is a valid option
                                    tasksetdata.overrides[item.name] = random_result
                                else
                                    print("TELEMOD: not valid option: "..tostring(item.name)..": "..tostring(random_result).." in "..tostring(tasksetdata.location))
                                end
                            end
                        end
                    else
                        category = customize.GetCategoryForOption(item.name)
                        if table.contains(shouldnt_be_never[tasksetdata.location],item.name) then
                            variation_string = tostring(category).."_"..tostring(item.group).."_shouldnt_be_never"
                        else
                            variation_string = tostring(category).."_"..tostring(item.group) -- group_name == giants or animals and so on -- category == _G.LEVELCATEGORY.WORLDGEN or _G.LEVELCATEGORY.SETTINGS
                        end
                        if var_t[variation_string]~=nil then
                            if setting_variate_suck or not table.contains(sucking_settings,item.name) then
                                if type(var_t[variation_string])=="table" then
                                    random_result = _G.weighted_random_choice(var_t[variation_string])
                                else
                                    random_result = var_t[variation_string]
                                end
                                if customize.ValidateOption(item.name,random_result,tasksetdata.location) then -- make sure it is a valid option
                                    tasksetdata.overrides[item.name] = random_result
                                else -- some exceptions are handled below
                                    print("TELEMOD: not valid option: "..tostring(item.name)..": "..tostring(random_result).." in "..tostring(tasksetdata.location))
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return tasksetdata
end


local WSO = require("worldsettings_overrides")
local savedata = nil
local new_game = true
local function GetSaveData()
    if new_game then
        if savedata then
            return savedata
        end
        local i = 1
        local stack_i = 3 -- we increment this in case another mod is overwriting a function, to make sure getlocal still works.
        while true do
            if stack_i>20 then --give up
                print("TELEMOD: failed to find -savedata- to apply modded worldsettings.. will be unchanged now")
                return nil
            end
            local name, value = GLOBAL.debug.getlocal(stack_i, i) -- Level 1 is where we are now, Level 2 is our Pre function calling this, level 3 is gamelogic.lua:362 or gamelogic.lua:367 depending on the savedata.
            if name then
                if name == "savedata" then
                    if value.meta.SERP_MOD_HAS_OVERRIDEN then -- only do it once per world
                        new_game = false -- do not try it again, it is no new game, so no need to find savedata again.
                        return nil
                    end
                    savedata = value
                    savedata.meta.SERP_MOD_HAS_OVERRIDEN = true
                    return savedata
                end
                i = i+1
            else
                stack_i = stack_i+1
                i = 1
            end
        end
    end
end



-- use those dummies, so we do not need to rewrite the adventure mod code.
-- tasksetdata_cache will include all the tasksetdata stuff, but only the one for worldsettings is used! (because it can not be accessed in AddLevelPreInitAny, at least not the very same object) 
-- in AddLevelPreInitAny we have to call functions (eg get_tele_tasksetdata_overrides) again and then use the worldgeneration stuff from it (settings dont have an effect there)
if (setting_do_variate_world and setting_do_variate_world~="justislands") or _G.next(WORLDS) then
    local tasksetdata_dummy_forest = {location="forest",overrides={}} 
    local tasksetdata_dummy_cave = {location="cave",overrides={}}
    local tasksetdata_cache = {}
    tasksetdata_cache["forest"] = tasksetdata_dummy_forest -- EVLT wäre es besser doch keinen cache zu machen, damit get_tele_tasksetdata_overrides usw zu einem zeitpunkt aufgerufen wird, zu dem zb bekannt ist ob es ein mastershard ist oder nicht usw.
    tasksetdata_cache["cave"] = tasksetdata_dummy_cave

    if _G.next(WORLDS) then
        tasksetdata_cache["forest"] = WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL_GEN].taskdatafunctions~=nil and WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL_GEN].taskdatafunctions["forest"] and WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL_GEN].taskdatafunctions["forest"](tasksetdata_dummy_forest) or tasksetdata_dummy_forest
        tasksetdata_cache["cave"] = WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL_GEN].taskdatafunctions~=nil and WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL_GEN].taskdatafunctions["cave"] and WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL_GEN].taskdatafunctions["cave"](tasksetdata_dummy_cave) or tasksetdata_dummy_cave
    else
        tasksetdata_cache["forest"] = get_tele_tasksetdata_overrides(tasksetdata_dummy_forest)
        tasksetdata_cache["cave"] = get_tele_tasksetdata_overrides(tasksetdata_dummy_cave)
    end
    
    local category = nil
    if (GLOBAL.rawget(GLOBAL, "IsInFrontEnd") and GLOBAL.IsInFrontEnd()==false) and GLOBAL.rawget(GLOBAL, "TheNet") and GLOBAL.TheNet:GetIsServer() then -- run only while WSO settings are applied
        local dump_settings = {}
        for world,settings in pairs(tasksetdata_cache) do
            dump_settings[world] = {}
            for name,setting in pairs(settings.overrides) do
                category = customize.GetCategoryForOption(name)
                if category==Wset then -- if it is a worldsetting (not a generation) ( in WSO is not a valid condition for a worldsetting, use category instead)
                    dump_settings[world][name] = setting
                end
            end
        end
        if _G.next(dump_settings) then
            print("Variate World Teleportato mod: these are the changed worldsettings (only world of this logfile is correct!):")
            _G.dumptable(dump_settings)
        end
    end

    if (GLOBAL.rawget(GLOBAL, "IsInFrontEnd") and GLOBAL.IsInFrontEnd()==false) and GLOBAL.rawget(GLOBAL, "TheNet") and GLOBAL.TheNet:GetIsServer() then -- run only while WSO settings are applied
        -- When caves is enabled worldsettingspicker (customize.lua Levels) is showing wrong values (with the IsInFrontEnd condition always  "default")
        -- for whatever reason the "world settings picker" mod is displaying the results from another modworldgenmain run (when cave is enabled), while TheWorld.topology.overrides shows the results from this run (so only world settings picker is wrong)
        -- it is because customize.lua is using Levels.GetDataForLocation which most likely means that 1) the run in which AddLevelPreInitAny runs the savedata is saved in levels.
        -- but that levels run is NOT used ingame, it is another run of modworldgenmain. Therefore we have 2 different overrides, one in levels (nowhere used except in customize.lua) and the one in theworld.topology which is used ingame
        for i,PrePost in ipairs({"Pre","Post"}) do
            for name, fn in pairs(WSO[PrePost]) do
                local old_fn = WSO[PrePost][name]
                WSO[PrePost][name] = function(difficulty,...)
                    if new_game then -- only when it is a new game, so users can change it if they dont like it
                        if not savedata then 
                            GetSaveData() -- this will for sure get savedata
                        end
                        if savedata then
                            if tasksetdata_cache[savedata.map.prefab].overrides~=nil and tasksetdata_cache[savedata.map.prefab].overrides[name]~=nil then
                                savedata.map.topology.overrides[name] = tasksetdata_cache[savedata.map.prefab].overrides[name] -- save the setting so we can see it in menu and it wont revert to default on the next start of the world
                                difficulty = tasksetdata_cache[savedata.map.prefab].overrides[name]
                            end
                            
                            if name=="pigs_setting" and tasksetdata_cache[savedata.map.prefab].overrides~=nil then -- hacky way to save all of our worldsettings to savedata, even those that are not within WSO. we check for "pigs_setting" because we want to execute it only once and for forest and caves
                                for loopname,setting in pairs(tasksetdata_cache[savedata.map.prefab].overrides) do -- save all worldsettings (not all have WSO functions, eg events)
                                    category = customize.GetCategoryForOption(loopname)
                                    if category==Wset then
                                        savedata.map.topology.overrides[loopname] = setting
                                    end
                                end
                            end
                            
                        end
                    end
                    if old_fn then
                        return old_fn(difficulty,...)
                    end
                end
            end
        end
    end
end


-------------------------------
-------------------------------





-- teleportato stuff

_G.TUNING.TELEPORTATOMOD.set_behaviour = _G.TUNING.TELEPORTATOMOD.set_behaviour~=nil and _G.TUNING.TELEPORTATOMOD.set_behaviour or GetModConfigData("set_behaviour")

local require = _G.require
local PLACE_MASK = _G.PLACE_MASK
local LAYOUT_POSITION = _G.LAYOUT_POSITION

local LLayouts = require("map/layouts").Layouts
LLayouts["TeleportatoRingLayoutSanityRocks"] = require("map/layouts/TeleportatoRingLayoutSanityRocks")

if _G.TUNING.TELEPORTATOMOD.teleportato_layouts==nil then
    _G.TUNING.TELEPORTATOMOD.teleportato_layouts = {}
end

if _G.TUNING.TELEPORTATOMOD.teleportato_layouts["forest"]==nil then -- may also be changed by another mod
    if GetModConfigData("DSlike") then
        _G.TUNING.TELEPORTATOMOD.teleportato_layouts["forest"] = {
            teleportato_box="TeleportatoBoxLayout",
            teleportato_ring="TeleportatoRingLayout",
            teleportato_potato="TeleportatoPotatoLayout",
            teleportato_crank="TeleportatoCrankLayout",
            teleportato_base="TeleportatoBaseLayout",
        }
    else
        _G.TUNING.TELEPORTATOMOD.teleportato_layouts["forest"] = {
            teleportato_box="TeleportatoBoxLayout",
            teleportato_ring="TeleportatoRingLayoutSanityRocks",
            teleportato_potato="TeleportatoPotatoLayout",
            teleportato_crank="TeleportatoCrankLayout",
            teleportato_base="TeleportatoBaseLayout",
        }
    end
end

if _G.TUNING.TELEPORTATOMOD.teleportato_layouts["cave"]==nil then -- may also be changed by another mod
    if GetModConfigData("DSlike") then
        _G.TUNING.TELEPORTATOMOD.teleportato_layouts["cave"] = { -- without base ! base is only in forest (mastershard)
            teleportato_box="TeleportatoBoxLayout",
            teleportato_ring="TeleportatoRingLayout",
            teleportato_potato="TeleportatoPotatoLayout",
            teleportato_crank="TeleportatoCrankLayout",
        }
    else
        _G.TUNING.TELEPORTATOMOD.teleportato_layouts["cave"] = {
            teleportato_box="TeleportatoBoxLayout",
            teleportato_ring="TeleportatoRingLayoutSanityRocks",
            teleportato_potato="TeleportatoPotatoLayout",
            teleportato_crank="TeleportatoCrankLayout",
        }
    end
end


local function Add_IIBE_Mask(layout,fill_mask)
    layout.start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN -- make the layouts from teleportato to ignore impassable
    layout.layout_position = LAYOUT_POSITION.CENTER
    
    if fill_mask then
        layout.fill_mask = fill_mask
    elseif _G.TUNING.TELEPORTATOMOD.set_behaviour==0 or _G.TUNING.TELEPORTATOMOD.set_behaviour==3 then
        layout.fill_mask = PLACE_MASK.NORMAL
    elseif _G.TUNING.TELEPORTATOMOD.set_behaviour==1 or _G.TUNING.TELEPORTATOMOD.set_behaviour==4 then
        layout.fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN
    elseif _G.TUNING.TELEPORTATOMOD.set_behaviour==2 or _G.TUNING.TELEPORTATOMOD.set_behaviour==5 then
        layout.fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED -- also ignore other setpieces
    end
end
AddLevelPreInitAny(function(level)
    for worldprefab,layouts in pairs(_G.TUNING.TELEPORTATOMOD.teleportato_layouts) do
        for i, v in pairs(layouts) do
            Add_IIBE_Mask(LLayouts[v])
        end
    end
end)


----------


local tasksfile = require("map/tasks")
local allTasks = tasksfile.GetAllTaskNames() -- get all loaded tasks. Is only used if spawntelemoonisland setting is true, cause this will circumvent the "level_set_piece_blocker"
table.removearrayvalue(allTasks, "Make a pick") -- "Make a pick" is very near the starting location, in forest, so do not use it to place a teleportato part

if setting_variate_islands~=false then
    AddRoom("LittleBitRockyTelemod", {
        colour={r=.55,g=.75,b=.75,a=.50},
        value = WORLD_TILES.DIRT,
        tags = {"ExitPiece"},
        contents =  {
                        distributepercent = .15,
                        distributeprefabs=
                        {
                            rock1 = 0.7,
                            rock2 = 1, -- more gold
                            rock_ice = 0.3,
                            spiderden = 0.2, -- few spiders
                        },
                    }
        })
    AddTask("Little Bit Of Stone Telemod", {
		locks={_G.LOCKS.TIER1},
		keys_given={_G.KEYS.ROCKS, _G.KEYS.GOLD,_G.KEYS.TIER2}, -- we need to set keys here, otherwise storygen might crash
		room_choices={
			["LittleBitRockyTelemod"] = 1,
		}, 
		room_bg=WORLD_TILES.ROCKY,
		background_room="BGRocky",
		colour={r=1,g=1,b=0,a=1}
	})
end

local function Add_optionaltasks_to_tasks(tasksetdata)
    -- a function that chooses optionaltasks based on the code from Level:ChooseTasks() in map/level.lua
    -- and puts them into "tasks". This is needed because of this bug that will never be fixed: https://forums.kleientertainment.com/klei-bug-tracker/dont-starve-together/addtaskpreinit-does-not-affect-optionaltasks-intended-r25702/
    -- so we are able to know within AddLevelPreInitAny which tasks will be generated and which not
    if tasksetdata.numoptionaltasks and tasksetdata.numoptionaltasks > 0 and tasksetdata.optionaltasks then
		_G.shuffleArray(tasksetdata.optionaltasks) -- serp: removed "local shuffletasknames = ", because it is not used anyways
		local numtoadd = tasksetdata.numoptionaltasks
		local i = 1
		while numtoadd > 0 and i <= #tasksetdata.optionaltasks do
			if type(tasksetdata.optionaltasks[i]) == "table" then
				_G.shuffleArray(tasksetdata.optionaltasks[i]) -- added by serp
                for i,taskname in ipairs(tasksetdata.optionaltasks[i]) do
					-- tasksetdata:EnqueueATask(tasklist, taskname) -- removed by serp
                    table.insert(tasksetdata.tasks,taskname) -- added by serp
					numtoadd = numtoadd - 1
				end
			else
				-- tasksetdata:EnqueueATask(tasklist, tasksetdata.optionaltasks[i]) -- removed by serp
                table.insert(tasksetdata.tasks,tasksetdata.optionaltasks[i]) -- added by serp
				numtoadd = numtoadd - 1
			end
			i = i + 1
		end
	end
    tasksetdata.numoptionaltasks = 0 -- set it zero afterwards, so the game does not add them again
end





-- removing the monkeyqueen und monkeyisland helps alot for island generation (guess because games generation code is bad for monkeyisland), but we dont want to play without it
AddRoomPreInit("OceanRough",function(roomdata)
    if setting_do_variate_world and not _G.next(WORLDS) and (setting_variate_islands=="many" or setting_variate_islands=="all") then
        -- table.removearrayvalue(roomdata.required_prefabs,"monkeyqueen")
        roomdata.contents.countstaticlayouts["MonkeyIsland"] = nil
        -- try add a smaller one, guess it helps a bit, but not always. better than nothing
        roomdata.contents.countstaticlayouts["monkeyisland_retrofitsmall_0"..tostring(math.random(1,2))] = 1 -- monkeyisland_retrofitsmall_02
    end
end)

-- here we can only change the worldgeneration stuff, not the worldsettings. settings are changed in aboves code WSO
-- my functions taskdatafunction and get_tele_tasksetdata_overrides do add both to tasksetdata and do not differentiate between settings or generation.
-- but in AddLevelPreInitAny only generation has an effect and in the WSO code only settings have an effect.
-- unfortunately we can not combine these to parts so that only one get_tele_tasksetdata_overrides-call is necessary, but it is not really mandatory
AddLevelPreInitAny(function(tasksetdata) -- (is not called twice. only when generation failed and it retries)
    -- print("HIER called AddLevelPreInitAny ")
    local _overrides = nil
    if GEMAPIActive then -- to prevent gem api to revert our changes in rare cases
        _overrides = GLOBAL.shallowcopy(tasksetdata.overrides)
    end
    
    
    if _G.next(WORLDS) then -- if another mod wants to load his worlds. sandboxpreconfigured should be checked within taskdatafunction
        tasksetdata = WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL_GEN].taskdatafunctions~=nil and WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL_GEN].taskdatafunctions[tasksetdata.location] and WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL_GEN].taskdatafunctions[tasksetdata.location](tasksetdata) or tasksetdata
    end

    if setting_do_variate_world and not _G.next(WORLDS) then -- if activated and no other mod wants to generate his world
        
        tasksetdata = get_tele_tasksetdata_overrides(tasksetdata)        
        
        if tasksetdata.location == "forest" then
            -- most already done in get_tele_tasksetdata_overrides
            if setting_variate_islands~=false then
                
                -- not sure if this helps to prevent placement issues (and therefore endless generation because of missing required_prefabs, but I think it also does not hurt)
                -- the games placement of the terrarium and MonkeyIsland set_pieces is terrible bad, which shows very badly when we make islands
                Add_IIBE_Mask(LLayouts["Terrarium_Forest_Spiders"],PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED)
                Add_IIBE_Mask(LLayouts["Terrarium_Forest_Pigs"],PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED)
                Add_IIBE_Mask(LLayouts["Terrarium_Forest_Fire"],PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED)
                Add_IIBE_Mask(LLayouts["MonkeyIsland"],PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED)
                LLayouts["MonkeyIsland"].min_dist_from_land = 0
                if tasksetdata.required_prefabs == nil then
                    tasksetdata.required_prefabs = {}
                end
                table.removearrayvalue(tasksetdata.required_prefabs,"terrariumchest") -- we will spawn it instead in modmain, the setpiece is troublesome to place with islands and causes endless generation of map otherwise..

                
                
                -- ## important line:
                Add_optionaltasks_to_tasks(tasksetdata) -- trigger the selection of optionaltasks now, so we know the final tasks here (see https://forums.kleientertainment.com/klei-bug-tracker/dont-starve-together/addtaskpreinit-does-not-affect-optionaltasks-intended-r25702/)
                -- ##
                local numberofislands = 0
                local tasknamelist = {} -- dont add islands (not_mainland) that are generated from the game
                for i,name in ipairs(tasksetdata.tasks) do
                    task = tasksfile.GetTaskByName(name)
                    if task~=nil and not table.contains(task.room_tags,"not_mainland") then
                        table.insert(tasknamelist,name)
                    end
                end
                local totaltasks = #tasknamelist -- dont count islands (not_mainland) that are generated from the game
                if setting_variate_islands=="random" then
                    numberofislands = math.random(0,totaltasks)
                elseif setting_variate_islands=="few" then
                    numberofislands = math.random(math.ceil(totaltasks*0.1),math.ceil(totaltasks*0.3))
                elseif setting_variate_islands=="medium" then
                    numberofislands = math.random(math.ceil(totaltasks*0.3),math.ceil(totaltasks*0.55))
                elseif setting_variate_islands=="many" then
                    numberofislands = math.random(math.ceil(totaltasks*0.5),math.ceil(totaltasks*0.8))
                elseif setting_variate_islands=="all" then
                    numberofislands = totaltasks 
                end
                                
                local island_task_ratio = totaltasks / numberofislands -- calculate this before we add "Little Bit Of Stone Telemod", because we count this and "Make a pick" as 1
                table.insert(tasksetdata.tasks,"Little Bit Of Stone Telemod") -- add this as mandatory task that is connected to the mainland, to make sure players have rocks/gold there.
                table.insert(tasknamelist,"Little Bit Of Stone Telemod")
                _G.shuffleArray(tasksetdata.tasks)
                _G.shuffleArray(tasknamelist)
                local task = nil
                
                if numberofislands>0 then
                    
                    if island_size_setting=="mainbig_othersmall" then
                        for i,name in ipairs(tasknamelist) do
                            if numberofislands>0 then
                                task = tasksfile.GetTaskByName(name)
                                if task~=nil then --and not table.contains(task.room_tags,"not_mainland") then
                                    if name~="Make a pick" and name~="Little Bit Of Stone Telemod" then -- the mainland needs at least 2 tasks, otherwise storgen will crash
                                        task.region_id = "teleportato_island_"..tostring(i)
                                        task.room_tags = _G.ArrayUnion(task.room_tags,{"not_mainland"})
                                        numberofislands = numberofislands - 1
                                    end                      
                                end
                            end
                        end
                    elseif island_size_setting=="mainsmall_othersamesize" then
                        for _,name in ipairs({"Make a pick","Little Bit Of Stone Telemod"}) do -- these are mandatory mainland tasks
                            task = tasksfile.GetTaskByName(name)
                            if task~=nil then
                                task.region_id = "mainland"
                            end
                            table.removearrayvalue(tasknamelist,name)
                        end
                        island_task_ratio = #tasknamelist / numberofislands -- new calculation without mainland
                        local region_numbers = {}
                        for i,name in ipairs(tasknamelist) do
                            table.insert(region_numbers,math.ceil(i/island_task_ratio))
                        end
                        local taskname = nil
                        for _,region_number in ipairs(region_numbers) do
                            if _G.next(tasknamelist)~=nil then
                                taskname = _G.PickSome(1,tasknamelist)[1]
                                if taskname~=nil then
                                    task = tasksfile.GetTaskByName(taskname)
                                    if task~=nil then
                                        task.region_id = "teleportato_island_"..tostring(region_number)  
                                        task.room_tags = _G.ArrayUnion(task.room_tags,{"not_mainland"})
                                    end
                                end
                            end
                        end
                    elseif island_size_setting=="allsamesize" then -- approximately same size, not exactly, but we try to add the same number of tasks to every island
                        -- can result in all islands 3 tasks and 1 island 1 task (the alternative would be make one island 4 tasks)
                        -- all in all the code is not perfect, but good enough I think
                        local region_numbers = {}
                        for i,name in ipairs(tasknamelist) do
                            table.insert(region_numbers,math.ceil(i/island_task_ratio))
                        end
                        for _,name in ipairs({"Make a pick","Little Bit Of Stone Telemod"}) do -- these are mandatory mainland tasks
                            task = tasksfile.GetTaskByName(name)
                            if task~=nil then
                                task.region_id = "mainland"
                            end
                            table.removearrayvalue(tasknamelist,name)
                            table.removearrayvalue(region_numbers,1) -- remove an "1" as region_number if there is one left
                        end
                        local taskname = nil
                        for _,region_number in ipairs(region_numbers) do
                            if _G.next(tasknamelist)~=nil then
                                taskname = _G.PickSome(1,tasknamelist)[1]
                                if taskname~=nil then
                                    task = tasksfile.GetTaskByName(taskname)
                                    if task~=nil then
                                        if region_number~=1 then -- 1 will be mainland
                                            task.region_id = "teleportato_island_"..tostring(region_number)  
                                            task.room_tags = _G.ArrayUnion(task.room_tags,{"not_mainland"})
                                        else
                                            task.region_id = "mainland" -- 1 will be added to mainland
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                end
            end

            
        -- elseif tasksetdata.location == "cave" then -- season and day settings will always be identical to forest, so no effect by changing them here
            --most already done in get_tele_tasksetdata_overrides
            
        end
    end

    if tasksetdata.add_teleportato or (not _G.next(WORLDS) and string.match(GetModConfigData("spawnteleworld"),tasksetdata.location)) then
        if not (tasksetdata.ordered_story_setpieces~=nil and _G.next(tasksetdata.ordered_story_setpieces)) then -- only add teleportato layouts, if other mod did not define ordered_story_setpieces, which should ONLY be used for the original DS worlds!
            if not tasksetdata.set_pieces then -- ordered_story_setpieces is deprecated and not working for caves and also placing mask has no good effect on it
                tasksetdata.set_pieces = {}
            end
            if tasksetdata.required_prefabs == nil then
                tasksetdata.required_prefabs = {}
            end
            if not tasksetdata.required_setpieces then
                tasksetdata.required_setpieces = {}
            end
            if _G.TUNING.TELEPORTATOMOD.teleportato_layouts[tasksetdata.location]~=nil then
                for prefab,layout in pairs(_G.TUNING.TELEPORTATOMOD.teleportato_layouts[tasksetdata.location]) do
                    if GetModConfigData("spawntelemoonisland") then
                        if tasksetdata.set_pieces[layout]==nil then -- adding them here, may also add them to a task with level_set_piece_blocker
                            tasksetdata.set_pieces[layout] = { count = 1, tasks=allTasks} -- tasks in this list that do not exist in the world, are automatically removed from choices 
                        end
                    else
                        table.insert(tasksetdata.required_setpieces, layout) -- will spawn them in a random task, except those with "level_set_piece_blocker"
                    end
                    if _G.TUNING.TELEPORTATOMOD.set_behaviour==4 or _G.TUNING.TELEPORTATOMOD.set_behaviour==5  then
                        if not table.contains(tasksetdata.required_prefabs, prefab) then
                            table.insert(tasksetdata.required_prefabs, prefab)
                        end
                    end
                end
            end
        end

    elseif tasksetdata.location=="forest" then -- a base always at forest (mastershard), if teleporato should be added to any world ... I don't know a way to check if current wolrd is mastershard (so to be independend of the forest name)... TheShard and TheWorld do not exist yet.
        local weiter = false
        if not _G.next(WORLDS) then -- a base always at forest, if teleporato should be added to any world
            weiter = true
        elseif WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL_GEN].taskdatafunctions~=nil then
            for worldprefab,func in pairs(WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL_GEN].taskdatafunctions) do
                if worldprefab~=tasksetdata.location then-- we are currently in mastershard and now find out if any world that is not mastershard, added the tele parts
                    if func({}).add_teleportato then
                        weiter = true
                    end
                end
            end
        end    
        if weiter then
            -- print("WERT still spawn base...")
            if not tasksetdata.set_pieces then
                tasksetdata.set_pieces = {}
            end
            if tasksetdata.set_pieces["TeleportatoBaseLayout"]==nil and tasksetdata.set_pieces["TeleportatoBaseAdventureLayout"]==nil then
                tasksetdata.set_pieces["TeleportatoBaseLayout"] = { count = 1, tasks=allTasks} -- tasks in this list that do not exist in the world, are automatically removed from choices 
            end
            if _G.TUNING.TELEPORTATOMOD.set_behaviour==4 or _G.TUNING.TELEPORTATOMOD.set_behaviour==5  then
                if tasksetdata.required_prefabs == nil then
                    tasksetdata.required_prefabs = {}
                end
                table.insert(tasksetdata.required_prefabs, "teleportato_base")
            end
        end
    end
    
    local category = nil
    local dump_gen_settings = _G.deepcopy(tasksetdata)
    if tasksetdata.overrides~=nil then
        for name,setting in pairs(tasksetdata.overrides) do
            category = customize.GetCategoryForOption(name)
            if category==Wset then -- if it is a worldsetting (not a generation) ( in WSO is not a valid condition for a worldsetting, use category instead)
                dump_gen_settings.overrides[name] = nil -- remove entries that are worldsettings (and thus not applied here)
            end
        end
    end
    if _G.next(dump_gen_settings) then
        print("Variate World Teleportato mod: this is the "..tostring(tasksetdata.location).." worldgeneration:")
        _G.dumptable(dump_gen_settings)
    end


    if GEMAPIActive and _overrides~=nil then -- to prevent gem api to revert our changes in rare cases
        local overrides_to_block = {}
        for k, v in pairs(tasksetdata.overrides) do
            --original blockoverrides updateanyways are 3 things that could be in this table that aren't actually overrides.
            if k ~= "original" and k ~= "blockoverrides" and k ~= "updateanyways" and _overrides[k] ~= v then
                table.insert(overrides_to_block, k)
            end
        end
    	GLOBAL.gemrun("overridesblocker", tasksetdata.overrides, modname, overrides_to_block)
    end
end)



-- [02:22:48]: MaxPuzzle1	
-- [02:22:48]: MaxPuzzle2	
-- [02:22:48]: MaxPuzzle3	
-- [02:22:48]: MaxHome	
-- [02:22:48]: IslandHop_Start	
-- [02:22:48]: IslandHop_Hounds	
-- [02:22:48]: IslandHop_Forest	
-- [02:22:48]: IslandHop_Savanna	
-- [02:22:48]: IslandHop_Rocky	
-- [02:22:48]: IslandHop_Merm	
-- [02:22:48]: Resource-rich Tier2	
-- [02:22:48]: Resource-Rich	
-- [02:22:48]: Wasps and Frogs and bugs	
-- [02:22:48]: Frogs and bugs	
-- [02:22:48]: Hounded Magic meadow	
-- [02:22:48]: Magic meadow	
-- [02:22:48]: Waspy The hunters	
-- [02:22:48]: The hunters	
-- [02:22:48]: Guarded Walrus Desolate	
-- [02:22:48]: Walrus Desolate	
-- [02:22:48]: Insanity-Blocked Necronomicon	
-- [02:22:48]: Necronomicon	
-- [02:22:48]: Easy Blocked Dig that rock	
-- [02:22:48]: Dig that rock	
-- [02:22:48]: Tentacle-Blocked The Deep Forest	
-- [02:22:48]: The Deep Forest	
-- [02:22:48]: Mole Colony Deciduous	
-- [02:22:48]: Mole Colony Rocks	
-- [02:22:48]: Trapped Befriend the pigs	
-- [02:22:48]: Befriend the pigs	
-- [02:22:48]: Pigs in the city	
-- [02:22:48]: The Pigs are back in town	
-- [02:22:48]: Guarded King and Spiders	
-- [02:22:48]: Guarded Speak to the king	
-- [02:22:48]: King and Spiders	
-- [02:22:48]: Speak to the king	
-- [02:22:48]: Speak to the king classic	
-- [02:22:48]: Hounded Greater Plains	
-- [02:22:48]: Greater Plains	
-- [02:22:48]: Sanity-Blocked Great Plains	
-- [02:22:48]: Great Plains	
-- [02:22:48]: Rock-Blocked HoundFields	
-- [02:22:48]: HoundFields	
-- [02:22:48]: Merms ahoy	
-- [02:22:48]: Sane-Blocked Swamp	
-- [02:22:48]: Guarded Squeltch	
-- [02:22:48]: Squeltch	
-- [02:22:48]: Swamp start	
-- [02:22:48]: Tentacle-Blocked Spider Swamp	
-- [02:22:48]: Lots-o-Spiders	
-- [02:22:48]: Lots-o-Tentacles	
-- [02:22:48]: Lots-o-Tallbirds	
-- [02:22:48]: Lots-o-Chessmonsters	
-- [02:22:48]: Spider swamp	
-- [02:22:48]: Sanity-Blocked Spider Queendom	
-- [02:22:48]: Spider Queendom	
-- [02:22:48]: Guarded For a nice walk	
-- [02:22:48]: For a nice walk	
-- [02:22:48]: Mine Forest	
-- [02:22:48]: Battlefield	
-- [02:22:48]: Guarded Forest hunters	
-- [02:22:48]: Trapped Forest hunters	
-- [02:22:48]: Forest hunters	
-- [02:22:48]: Walled Kill the spiders	
-- [02:22:48]: Kill the spiders	
-- [02:22:48]: Waspy Beeeees!	
-- [02:22:48]: Beeeees!	
-- [02:22:48]: Killer bees!	
-- [02:22:48]: Pretty Rocks Burnt	
-- [02:22:48]: Make a Beehat	
-- [02:22:48]: The charcoal forest	
-- [02:22:48]: Land of Plenty	
-- [02:22:48]: The other side	
-- [02:22:48]: Chessworld	
-- [02:22:48]: MooseBreedingTask	
-- [02:22:48]: MoonIsland_IslandShards	
-- [02:22:48]: MoonIsland_Beach	
-- [02:22:48]: MoonIsland_Forest	
-- [02:22:48]: MoonIsland_Mine	
-- [02:22:48]: MoonIsland_Baths	
-- [02:22:48]: CavesTEST	
-- [02:22:48]: MudWorld	
-- [02:22:48]: MudCave	
-- [02:22:48]: MudLights	
-- [02:22:48]: MudPit	
-- [02:22:48]: ToadStoolTask1	
-- [02:22:48]: ToadStoolTask2	
-- [02:22:48]: ToadStoolTask3	
-- [02:22:48]: BigBatCave	
-- [02:22:48]: RockyLand	
-- [02:22:48]: RedForest	
-- [02:22:48]: GreenForest	
-- [02:22:48]: BlueForest	
-- [02:22:48]: SpillagmiteCaverns	
-- [02:22:48]: SwampySinkhole	
-- [02:22:48]: CaveSwamp	
-- [02:22:48]: UndergroundForest	
-- [02:22:48]: PleasantSinkhole	
-- [02:22:48]: SoggySinkhole	
-- [02:22:48]: FungalNoiseForest	
-- [02:22:48]: FungalNoiseMeadow	
-- [02:22:48]: BatCloister	
-- [02:22:48]: RabbitTown	
-- [02:22:48]: RabbitCity	
-- [02:22:48]: SpiderLand	
-- [02:22:48]: RabbitSpiderWar	
-- [02:22:48]: CaveExitTask1	
-- [02:22:48]: CaveExitTask2	
-- [02:22:48]: CaveExitTask3	
-- [02:22:48]: CaveExitTask4	
-- [02:22:48]: CaveExitTask5	
-- [02:22:48]: CaveExitTask6	
-- [02:22:48]: CaveExitTask7	
-- [02:22:48]: CaveExitTask8	
-- [02:22:48]: CaveExitTask9	
-- [02:22:48]: CaveExitTask10	
-- [02:22:48]: LichenLand	
-- [02:22:48]: CaveJungle	
-- [02:22:48]: Residential	
-- [02:22:48]: MilitaryPits	
-- [02:22:48]: Military	
-- [02:22:48]: Sacred	
-- [02:22:48]: TheLabyrinth	
-- [02:22:48]: SacredAltar	
-- [02:22:48]: MoreAltars	
-- [02:22:48]: SacredDanger	
-- [02:22:48]: MuddySacred	
-- [02:22:48]: Residential2	
-- [02:22:48]: Residential3	
-- [02:22:48]: AtriumMaze	
-- [02:22:48]: Badlands	
-- [02:22:48]: Oasis	
-- [02:22:48]: Lightning Bluff	
-- [02:22:48]: LavaArenaTask	
-- [02:22:48]: Quagmire_KitchenTask	
-- [02:22:48]: TEST_TASK	
-- [02:22:48]: TEST_TASK1	
-- [02:22:48]: TEST_EMPTY
