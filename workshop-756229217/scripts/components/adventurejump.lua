-- Maxwells Door = 1
-- A Cold Reception = 2
-- King of Winter = 3
-- The Game is Afoot = 4
-- Archipelago = 5
-- Two Worlds = 6
-- Darkness = 7
-- MaxwellHome = 8
 
local function DelayedSaveAndClean()
    -- With this, stuff will be safe in the component
    -- SaveGame(false)
    TheWorld:PushEvent("ms_save") -- save with the save animation. this is to make sure adventure stuff is not lost when the game crashes between generation and first day.
    print("clean adventure file")
    -- Clean temporal file so other servers don't load adventure levels by mistake
    CleanTemporalAdventureFile()
end
 
 -- Made to work with (And return) array-style tables
-- This function does not preserve the original table
local function MyPickSome(num, choices) -- better function than in util.lua
	local l_choices = choices
	local ret = {}
	if l_choices then -- nil check
        for i=1,num do
            if #l_choices > 0 then -- bigger 0 check
                local choice = math.random(#l_choices)
                table.insert(ret, l_choices[choice])
                table.remove(l_choices, choice)
            end
        end
    end
	return ret
end
 
local function OnInit(inst, self)
    -- If we bring stuff from modworldgenmain, attach it
    -- Else, make it yourself (what happens for the sandbox worlds)
    
    if not next(TUNING.TELEPORTATOMOD.WORLDS) then
        return
    end
    
    local adventure_stuff = GetTemporalAdventureContent()
    if adventure_stuff then
        self.adventure_info = adventure_stuff
        -- print("adventure_info")
        -- print(self.adventure_info)
        inst:DoTaskInTime(0, self.MakeSave, self) -- at first start of the world after generation. otherwise adventure_stuff will be "" 
    else
        local adventure_info = self.adventure_info
 
        if adventure_info.current_level == nil then
            -- 0 is the starting sandbox world
            adventure_info.current_level = 0
        end
        
        if adventure_info.level_list == nil then -- at adventure start, create the worlds order
            local level_list = {}
            local usedefault = false 
            for i=1,6 do -- there is no need to save chapter 0 here. and if we would, list[0] is not good, since they are transformed in strings list["0"]
                level_list[i] = MyPickSome(1,TUNING.TELEPORTATOMOD.POSITIONS[i+1])[1]
                for _,entry in pairs(level_list) do
                    while _~=i and level_list[i] == entry do
                        level_list[i] = MyPickSome(1,TUNING.TELEPORTATOMOD.POSITIONS[i+1])[1] -- make sure the same world is not used more than once
                        if not level_list[i] then -- if there are too few worlds to only use each world once
                            print("AdventureMod: WARNING: Not enough worlds are active, therefore modsettings are ignored and default settings used")
                            usedefault = true
                            break
                        end
                    end
                    if usedefault then
                        break
                    end
                end
                if usedefault then
                    break
                end
            end
            if usedefault then -- make it again, but with default values this time
                level_list = {}
                for i=1,6 do
                    level_list[i] = MyPickSome(1,TUNING.TELEPORTATOMOD.DEFAULTPOSITIONS[i+1])[1]
                    for _,entry in pairs(level_list) do
                        while _~=i and level_list[i] == entry do -- should not be a problem, except defaultpositions are wrong
                            level_list[i] = MyPickSome(1,TUNING.TELEPORTATOMOD.DEFAULTPOSITIONS[i+1])[1] -- make sure the same world is not used more than once
                            if not level_list[i] then -- should not happen if mod is build correct
                                print("AdventureMod: ERROR: modsetting worlds and also default worlds are not enough to cover every chapter! Make game crash now"..makecrash)
                            end
                        end
                    end
                end
            end
            adventure_info.level_list = level_list
        end

    end
    
    
    -- level und chapter are instead now saved within adv_startstuff component, so we can also give it to caves without allowing it to worldjump
    -- TELEPORTATOMOD.LEVEL /Chapter will now always be defined within modmain
    
    -- if self.adventure_info.level_list then 
        -- TUNING.TELEPORTATOMOD.LEVEL = self.adventure_info.level_list[self.adventure_info.current_level] or 1 -- this is to now the level when loading a world
        -- print("Adventure1: LEVEL  "..tostring(self.adventure_info.level_list[self.adventure_info.current_level])) -- is nil when world just generated, then we will set it to _GEN in StartStuff fn
        -- TUNING.TELEPORTATOMOD.CHAPTER = self.adventure_info.current_level or 0 -- the load from the component, if world is 0, it will be nil most likely
        -- print("Adventure1: CHAPTER "..tostring(self.adventure_info.current_level))
    -- else
        -- TUNING.TELEPORTATOMOD.LEVEL = 1 -- this is to now the level when loading a world
        -- print("Adventure: (level_list nil) LEVEL "..tostring(1)) -- is nil when world just generated, then we will set it to _GEN in StartStuff fn
        -- TUNING.TELEPORTATOMOD.CHAPTER = 0 -- the load from the component, if world is 0, it will be nil most likely
        -- print("Adventure: (level_list nil) CHAPTER "..tostring(0))
    -- end 
 
    local s = ""
    for _,worldnumber in pairs(self.adventure_info.level_list) do
        s = s .. tostring(TUNING.TELEPORTATOMOD.WORLDS[tonumber(worldnumber)].name) .. " ,"
    end
    print("Adventure Mod: The Following worlds will load: "..s)

    -- inst:DoTaskInTime(1, DelayedSaveAndClean) -- call it instead only after worldgeneration in modmain
    
end


local AdventureJump = Class(function(self, inst)
	self.inst = inst
	self.adventure_info = {}
    OnInit(inst,self)
    -- inst:DoTaskInTime(0, OnInit, self)
end)

function AdventureJump:OnSave()
	-- print("hier adventurejump save currentlevel "..tostring(self.adventure_info.current_level))
    return { code = json.encode(self.adventure_info) }
end

function AdventureJump:OnLoad(data)
	self.adventure_info = data and json.decode(data.code) or {}
    -- print("hier adventurejump load currentlevel "..tostring(self.adventure_info.current_level))
end

function AdventureJump:DoJump(keepage,keepinventory,keeprecipes)
	-- Up the level
	local current_level = self.adventure_info.current_level + 1
	self.adventure_info.current_level = current_level

	-- 0 is sandbox key
	-- 1, 2, 3, 4, 5, 6 are adventure keys
	-- 7 means we completed the level list, it's over
	if current_level < 7 then
		MakeTemporalAdventureFile(json.encode(self.adventure_info))
	end

    if TheWorld.components.worldjump then
        TheWorld.components.worldjump:DoJump(keepage,keepinventory,keeprecipes)
    else
        TheNet:SendWorldResetRequestToServer()
    end
end

function AdventureJump:MakeSave(self) -- save stuff in components, to prevent datalost after worldgenereation if game crashes. Should only be needed directly after world generation
	print("MakeSave")
    self.inst:DoTaskInTime(1, DelayedSaveAndClean)
end

return AdventureJump