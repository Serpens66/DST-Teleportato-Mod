local _G = GLOBAL
local helpers = _G.require("tele_helpers") 
-- Adventure stuff
print("HIER modworldgenmain tele "..tostring(_G.TUNING.TELEPORTATOMOD))

-- ideas for more worlds mods:
-- a world basically the same like default forest, but with more islands.
-- combine mods like multi_worlds?


if not _G.TUNING.TELEPORTATOMOD then
    _G.TUNING.TELEPORTATOMOD = {}
end
if not _G.TUNING.TELEPORTATOMOD.WORLDS then
    _G.TUNING.TELEPORTATOMOD.WORLDS = {} -- other mods should fill this prior. if something is in it, that world will be loaded instead
end
local WORLDS = _G.TUNING.TELEPORTATOMOD.WORLDS


AddGlobalClassPostConstruct("map/storygen", "Story",  function(self) -- bugfix of gamecode, the original function returns nil if the task is no valid starttask (it returns _G.GetRandomItem(task_nodes).task instead of _G.GetRandomItem(task_nodes) )
    local function FindStartingTask(self,task_nodes)
        local startTasks = {}
        for task_id, nodes in pairs(task_nodes) do
            if #self.tasks[task_id].locks == 0 or self.tasks[task_id].locks[1] == LOCKS.NONE then
                table.insert(startTasks, nodes)
            end
        end
        return #startTasks > 0 and startTasks[math.random(#startTasks)] or _G.GetRandomItem(task_nodes)
    end
    self._FindStartingTask = FindStartingTask
end)

if _G.next(WORLDS) then
    print("HIER modworldgenmain tele MIT WORLDS")
    -- stuff from DarkXero to make adventure progress:
    local io = _G.io
    local json = _G.json
    local modfoldername = "workshop-756229217" -- adjust this to the workshop folder name after uploading!
    local tmp_filepath = "../mods/"..modfoldername.."/adventure"

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
            print(modfoldername..": no adventure override found...")
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


    -- if not helpers.exists_in_table("LEVEL_GEN",_G) then -- in case another mod set it to some value to test a map
    if _G.TUNING.TELEPORTATOMOD.LEVEL_GEN==nil then -- in case another mod set it to some value to test a map, dont ooverwerite it
        _G.TUNING.TELEPORTATOMOD.LEVEL_GEN = 1
        _G.TUNING.TELEPORTATOMOD.CHAPTER_GEN = 0
        _G.ADVENTURE_STUFF = nil
        local adventure_stuff = _G.GetTemporalAdventureContent() -- eg. {"current_level":3,"level_list":[3,4,5,1,6,7]}
        if adventure_stuff then -- is only true, if we just adventure_jumped 
            _G.ADVENTURE_STUFF = adventure_stuff
            _G.TUNING.TELEPORTATOMOD.LEVEL_GEN = adventure_stuff.level_list[adventure_stuff.current_level] or 1
            _G.TUNING.TELEPORTATOMOD.CHAPTER_GEN = adventure_stuff.current_level or 0
            print("Adventure: adventurestuff loaded successfully")
        end
    end
    if _G.TUNING.TELEPORTATOMOD.CHAPTER_GEN==nil then -- in case the other modder did not set chapter
        _G.TUNING.TELEPORTATOMOD.CHAPTER_GEN = 0
    end
    print("Level gen1 is "..tostring(_G.TUNING.TELEPORTATOMOD.LEVEL_GEN).." Chapter is "..tostring(_G.TUNING.TELEPORTATOMOD.CHAPTER_GEN))
    
    -- Explanation of the WORLD table:
    -- name -> shown in title
    -- taskdatafunctions -> this function is called in AddTaskSetPreInitAny in modwordgenmain of the base mod to set the taskdata of the world, so your mod is loaded.
    -- location -> forest or cave
    -- positions -> only 5 maps per game are chosen. maps chosen randomly or disallow certain positions. eg. {2,3} your world may only load at second or third world. {1,2,3,4,5} your world may load regardless on which position.
    -- defaultpositions -> in case positions was set up poorly and not enough worlds are choosable to fill all chapters. Put here a table with 1 number, so display the order of worlds you put them
    -- sample: table.insert(_G.TUNING.TELEPORTATOMOD.WORLDS, {name="Two Worlds", taskdatafunctions = {forest=AdventureTwoWorlds, cave=AlwaysTinyCave}, defaultpositions={4,5}, positions=GetModConfigData("twoworlds")})
    -- more detailed sample see adventure mod from me.
    
    _G.TUNING.TELEPORTATOMOD.POSITIONS = {{},{},{},{},{},{},{}}
    for i,W in ipairs(WORLDS) do
        W.positions = string.split(W.positions, ",") --W.positions:_G.split(",") -- in modconfig tables as setting are not allowed, so we used strings and have to convert them here
        for _,pos in ipairs(W.positions) do
            table.insert(_G.TUNING.TELEPORTATOMOD.POSITIONS[_G.tonumber(pos)], i)
        end
    end
    _G.TUNING.TELEPORTATOMOD.DEFAULTPOSITIONS = {{},{},{},{},{},{},{}} -- just in case user set too less worlds, then use the defaultpositions too fill
    for i,W in ipairs(WORLDS) do
        for _,pos in ipairs(W.defaultpositions) do
            table.insert(_G.TUNING.TELEPORTATOMOD.DEFAULTPOSITIONS[pos], i)
        end
    end    
else
    print("HIER modworldgenmain tele KEIN WORLDS")
end


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


AddLevelPreInitAny(function(level)
    local function Add_IIBE_Mask(layout)
        layout.start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN -- make the layouts from teleportato to ignore impassable
        layout.layout_position = LAYOUT_POSITION.CENTER
        
        if _G.TUNING.TELEPORTATOMOD.set_behaviour==0 or _G.TUNING.TELEPORTATOMOD.set_behaviour==3 then
            layout.fill_mask = PLACE_MASK.NORMAL
        elseif _G.TUNING.TELEPORTATOMOD.set_behaviour==1 or _G.TUNING.TELEPORTATOMOD.set_behaviour==4 then
            layout.fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN
        elseif _G.TUNING.TELEPORTATOMOD.set_behaviour==2 or _G.TUNING.TELEPORTATOMOD.set_behaviour==5 then
            layout.fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED -- also ignore other setpieces
        end
    end

    for worldprefab,layouts in pairs(_G.TUNING.TELEPORTATOMOD.teleportato_layouts) do
        for i, v in pairs(layouts) do
            Add_IIBE_Mask(LLayouts[v])
        end
    end
end)


----------


local tasksfile = require("map/tasks")
local allTasks = tasksfile.GetAllTaskNames() -- get all loaded tasks. Is only used if spawntelemoonisland setting is true, cause this will circumvent the "level_set_piece_blocker"
table.removearrayvalue(allTasks, "Make a pick") -- "Make a pick" is very near the starting location, in forest, so do not use it

AddTaskSetPreInitAny(function(tasksetdata)
    
    if _G.next(WORLDS) then -- if another mod wants to load his worlds
        -- print("TTTTX")
        tasksetdata = WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL_GEN].taskdatafunctions~=nil and WORLDS[_G.TUNING.TELEPORTATOMOD.LEVEL_GEN].taskdatafunctions[tasksetdata.location](tasksetdata)
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
            print("WERT still spawn base...")
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
    

    if GetModConfigData("variateworld") and not _G.next(WORLDS) then -- if activated and no other mod wants to generate his world
        if tasksetdata.location == "forest" then -- world variation only for forest currently
            tasksetdata.substitutes = {["spiderden"] = {perstory=1, pertask=1, weight=1}} -- make all spiderdens a random size
            
            tasksetdata.overrides={ -- seems we have to replace the original , cause overrides is nil currently ... and everything not mentioned within here, will be set to default even, if the game location has other values defined...
                start_location = "default",
                task_set = "default",
                layout_mode = "LinkNodesByKeys", -- default for forest
                wormhole_prefab = "wormhole",
                roads = "default",
                world_size  =  _G.PLATFORM == "PS4" and _G.GetRandomItem({"default","default","medium","large"}) or _G.GetRandomItem({"small","default","default","medium","huge"}),
                deerclops  =  _G.GetRandomItem({"rare","default","default","often"}),
                dragonfly  =  _G.GetRandomItem({"rare","default","default","often"}),
                bearger  =  _G.GetRandomItem({"rare","default","default","often"}),
                goosemoose  =  _G.GetRandomItem({"rare","default","default","often"}),
                antliontribute  =  _G.GetRandomItem({"rare","default","default","often"}),
                season_start  =  _G.GetRandomItem({"autumn","autumn","autumn","autumn","autumn","winter","winter","spring","summer"}),
                autumn = _G.GetRandomItem({"veryshortseason","shortseason","shortseason","default","default","default","default","longseason","longseason","verylongseason"}),
                winter = _G.GetRandomItem({"veryshortseason","shortseason","shortseason","default","default","default","default","longseason","longseason","verylongseason"}),
                spring = _G.GetRandomItem({"veryshortseason","shortseason","shortseason","default","default","default","default","longseason","longseason","verylongseason"}),
                summer = _G.GetRandomItem({"veryshortseason","shortseason","shortseason","default","default","default","default","longseason","longseason","verylongseason"}),
                
                branching = _G.GetRandomItem({"default","default","never","least","most"}),
                loop = _G.GetRandomItem({"default","default","never","always"}),

                day = _G.GetRandomItem({"default","default","default","longday","longdusk","longnight"}),
                weather = _G.GetRandomItem({"rare","default","default","default","often"}),
                lightning = _G.GetRandomItem({"rare","default","default","default","often"}),
                frograin = _G.GetRandomItem({"rare","default","default","default","often"}),
                wildfires = _G.GetRandomItem({"rare","default","default","default","often"}),
                boons = _G.GetRandomItem({"rare","default","default","default","often"}),
                
                krampus = _G.GetRandomItem({"rare","default","default","default","default","often","often","always"}),
                alternatehunt = _G.GetRandomItem({"rare","default","default","default","default","often","often","always"}),
                beefaloheat = _G.GetRandomItem({"rare","default","default","default","often"}),
                perd = _G.GetRandomItem({"rare","default","default","default","default","often","often","always"}),
                hounds = _G.GetRandomItem({"rare","default","default","default","often"}),
                liefs = _G.GetRandomItem({"rare","default","default","default","default","often","often","always"}),
                deciduousmonster = _G.GetRandomItem({"rare","default","default","default","default","often","often","always"}),
                
                flowers = _G.GetRandomItem({"rare","default","default","default"}), -- more/always is rubbish, since then they will spawn everywhere...
                grass = _G.GetRandomItem({"rare","default","default","default"}),
                sapling = _G.GetRandomItem({"rare","default","default","default"}),
                tumbleweed = _G.GetRandomItem({"rare","default","default","default"}),
                trees = _G.GetRandomItem({"rare","default","default","default"}),
                flint = _G.GetRandomItem({"rare","default","default","default"}),
                rock = _G.GetRandomItem({"rare","default","default","default"}),
                meteorspawner = _G.GetRandomItem({"rare","default","default","default"}),
                meteorshowers = _G.GetRandomItem({"rare","default","default","default"}),
                berrybush = _G.GetRandomItem({"rare","default","default","default"}),
                carrot = _G.GetRandomItem({"rare","default","default","default"}),
                mushroom = _G.GetRandomItem({"rare","default","default","default"}),
                cactus = _G.GetRandomItem({"rare","default","default","default"}),
                
                keep_disconnected_tiles = true,
                no_wormholes_to_disconnected_tiles = true,
                no_joining_islands = true,
                has_ocean = true,
            }
            _G.dumptable(tasksetdata)
        elseif tasksetdata.location == "cave" then -- season and day settings will always be identical to forest, so no effect by changing them here
            tasksetdata.overrides={ -- seems we have to replace the original , cause overrides is nil currently ... and everything not mentioned within here, will be set to default even, if the game location has other values defined...
                task_set = "cave_default",
                start_location = "caves",
                layout_mode = "RestrictNodesByKey", -- default for cave
                wormhole_prefab = "tentacle_pillar",
                roads = "never",
                world_size  =  _G.PLATFORM == "PS4" and _G.GetRandomItem({"default","default","medium","large"}) or _G.GetRandomItem({"small","default","default","medium","huge"}),

                branching = _G.GetRandomItem({"default","default","never","least","most"}),
                loop = _G.GetRandomItem({"default","default","never","always"}),

                weather = _G.GetRandomItem({"rare","default","default","default","often"}),
                boons = _G.GetRandomItem({"rare","default","default","default","often"}),
                cavelight = _G.GetRandomItem({"rare","default","default","default","often"}),
                
                wormattacks = _G.GetRandomItem({"rare","default","default","default","often"}),
                liefs = _G.GetRandomItem({"rare","default","default","default","default","often","often","always"}),
                
                grass = _G.GetRandomItem({"rare","default","default","default"}),-- more/always is rubbish, since then they will spawn everywhere...
                sapling = _G.GetRandomItem({"rare","default","default","default"}),
                trees = _G.GetRandomItem({"rare","default","default","default"}),
                flint = _G.GetRandomItem({"rare","default","default","default"}),
                rock = _G.GetRandomItem({"rare","default","default","default"}),
                berrybush = _G.GetRandomItem({"rare","default","default","default"}),
                banana = _G.GetRandomItem({"rare","default","default","default"}),
                mushroom = _G.GetRandomItem({"rare","default","default","default"}),
                lichen = _G.GetRandomItem({"rare","default","default","default"}),
                mushtree = _G.GetRandomItem({"rare","default","default","default"}),
                flower_cave = _G.GetRandomItem({"rare","default","default","default"}),
                wormlights = _G.GetRandomItem({"rare","default","default","default"}),
                
                keep_disconnected_tiles = true,
                no_wormholes_to_disconnected_tiles = true,
                no_joining_islands = true,
                has_ocean = true,
            }
        end
    end
end)
