

 
local function DelayedSaveAndClean() -- save stuff in components, to prevent datalost after worldgenereation if game crashes. Should only be needed directly after world generation
    TheWorld:PushEvent("ms_save") -- save with the save animation. this is to make sure adventure stuff is not lost when the game crashes between generation and first day.
    print("clean adventure file")
    CleanTemporalAdventureFile() -- Clean temporal file so other servers don't load adventure levels by mistake
end

local function FixLevelList(inst,self) -- for updating old versions of the mod. can be removed after some months, when all users should already use the version 1.144 or higher
    if self.adventure_info.level_list~=nil and GetTableSize(self.adventure_info.level_list)==6 then -- update old version, now it is 7 to also include the sandbox
        local new_level_list = {}
        new_level_list[1] = TUNING.TELEPORTATOMOD.POSITIONS[1][1] -- get the first entry, so the sandbox level
        for k,v in pairs(self.adventure_info.level_list) do -- now enter the old values, so the total size will be 7 now
            new_level_list[k+1] = v
        end
        self.adventure_info.level_list = new_level_list
        self.adventure_info.current_level = self.adventure_info.current_level + 1
        print("Teleportato Adventure: Fixed level_list by adding sandbox chapter")
    end
end
 
local function OnInit(inst, self)
    
    inst:DoTaskInTime(2, FixLevelList, self)
    
    if not self.adventure_info.initialized then
        print("adventurejump oninit")
        
        if not next(TUNING.TELEPORTATOMOD.WORLDS) then
            return
        end
        
        local adventure_stuff = GetTemporalAdventureContent()
        if adventure_stuff then -- if we recently made an adventure jump
            self.adventure_info = adventure_stuff
            inst:DoTaskInTime(1, DelayedSaveAndClean)
        else -- if the world was generated without an adventurejump
            if self.adventure_info.current_level == nil then
                self.adventure_info.current_level = 1 -- start with chapter 1 the sandbox. all other values of current_level are simply saved/loaded, either with component or within the adventure file
            end
            if self.adventure_info.level_list == nil then
                self.adventure_info.level_list = TUNING.TELEPORTATOMOD.LEVEL_LIST_GEN or {} -- simply to save the first generated list
            end
        end
     
        local s = ""
        for _,worldnumber in pairs(self.adventure_info.level_list) do
            s = s .. tostring(TUNING.TELEPORTATOMOD.WORLDS[tonumber(worldnumber)].name) .. " ,"
        end
        print("Adventure Mod: The Following worlds will load: "..s)
        self.adventure_info.initialized = true -- only do this once per world
    end
end


local AdventureJump = Class(function(self, inst)
	self.inst = inst
	self.adventure_info = {}
    -- OnInit(inst,self)
    inst:DoTaskInTime(0, OnInit, self) -- use DoTaskInTime to do it after OnLoad was executed
end)

function AdventureJump:OnSave()
	-- print("adventurejump save currentlevel "..tostring(self.adventure_info.current_level))
    return { code = json.encode(self.adventure_info) }
end

function AdventureJump:OnLoad(data)
	self.adventure_info = data and json.decode(data.code) or {}
    print("adventurejump load currentlevel "..tostring(self.adventure_info.current_level))
end

function AdventureJump:DoJump(keepage,keepinventory,keeprecipes)
	-- Up the level
	local current_level = self.adventure_info.current_level + 1
	self.adventure_info.current_level = current_level

	-- 1 is sandbox key
	-- 2-7 are adventure keys
	-- 8 means we completed the level list, it's over
	if current_level < 8 then
		MakeTemporalAdventureFile(json.encode(self.adventure_info))
	end

    if TheWorld.components.worldjump then
        TheWorld.components.worldjump:DoJump(keepage,keepinventory,keeprecipes)
    else
        TheNet:SendWorldResetRequestToServer()
    end
end

return AdventureJump
