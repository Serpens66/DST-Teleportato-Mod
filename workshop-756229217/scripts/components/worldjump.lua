--- ############# Worldjump code by DarkXero! 

local function PlayerExitWorld(player)
    if TheWorld.components.worldjump then
        TheWorld.components.worldjump:OnPlayerExitWorld(player)
    end
end

-- Load the decoded data from the persistent string on new spawn
local function OnPlayerSpawn(world, player)
    player:ListenForEvent("onremove", PlayerExitWorld) -- add listener to notice overwolrd leaving (entering cave)
    if world.ismastershard then  -- after a worldjump we always spawn in forest, so only spawn stuff there.
        world:DoTaskInTime(0, function(world)
            local worldjump = world.components.worldjump
            local userid = player.userid
            local t = worldjump.player_ids
            local found = false
            found = table.contains(t,userid)
            if not found then
                local jumpdata = worldjump.player_data[userid]
                -- print("WERT playerspawned")
                if jumpdata then
                    -- print("WERT playerspawned jumpdata")
                    if jumpdata.chardata~=nil then
                        jumpdata.chardata.is_ghost = false -- no ghosts, revieve everyone
                    end
                    if TUNING.TELEPORTATOMOD.ALLsave and player.prefab==jumpdata.prefab and jumpdata.chardata~=nil then -- load character prefab specific stuff if it is the same character (because otherwise it might crash because of bad game code in some OnLoad)
                        -- ALLsave stands for "load everything character related that is not otherwise mentioned in settings"
                        -- most of the time this should be fine, but there may be mechanics that do not work as intended if everything is loaded in another world, so we added an extra modsetting ALLsave for it
                        
                        for pl_prefab,dataname in pairs(TUNING.TELEPORTATOMOD.DoNotLoadPlayerData) do
                            if player.prefab == pl_prefab and jumpdata.chardata[dataname]~=nil then
                                jumpdata.chardata[dataname] = nil -- set it to nil before we call OnPreLoad and OnLoad because stuff into this table should not be loaded, eg. because it causes bugs
                            end
                        end
                        
                        if player.OnPreLoad~=nil then
                            player:OnPreLoad(jumpdata.chardata) -- for whatever reason although the function requires "inst,data", inst is automatcally transfered, so we only need to pass data
                        end
                        if player.OnLoad~=nil then
                            player:OnLoad(jumpdata.chardata) -- for whatever reason although the function requires "inst,data", inst is automatcally transfered, so we only need to pass data
                        end
                        for dataname,data in pairs(jumpdata.chardata) do -- load all components data automatically
                            if data~=nil and player.components[dataname]~=nil and player.components[dataname].OnLoad~=nil then
                                if (dataname~="age" or worldjump.saveage) and
                                    (dataname~="skinner" or TUNING.TELEPORTATOMOD.repickcharacter==false) and
                                    ((dataname~="builder" and dataname~="knownfoods") or worldjump.savebuilder) and
                                    ((dataname~="health" and dataname~="sanity" and dataname~="hunger") or TUNING.TELEPORTATOMOD.statssave) and
                                    (dataname~="inventory" or worldjump.saveinventory) and
                                    not table.contains(TUNING.TELEPORTATOMOD.DoNotLoadComponentData,dataname) then -- eg. adv_startstuff: teleportato mod includes things that should be executed once per world, so we dont want to load this
                                    -- will also load stuff like beard, upgrademoduleowner and other char related stuff, but only if it is the same prefab like before
                                    if dataname=="inventory" then
                                        if TUNING.TELEPORTATOMOD.ITEMNUMBERTRANS~="all" then -- defined in modmain, only transfer a number of items
                                            local transitems = {}
                                            for i=1,TUNING.TELEPORTATOMOD.ITEMNUMBERTRANS do
                                                table.insert(transitems,data.items[i])
                                            end
                                            data.items = transitems
                                            data.equip = {} -- delete quipped items
                                        end
                                    end
                                    player.components[dataname]:OnLoad(data)
                                end
                            end
                        end
                        player.components.health:ForceUpdateHUD(true) -- update HUD after all those changes
                    else -- load the components manually, because we dont want to transfer everything to the new character
                        if jumpdata.chardata~=nil then
                            if worldjump.saveage then
                                player.components.age:OnLoad(jumpdata.chardata.age)
                            end
                            if worldjump.savebuilder then
                                player.components.builder:OnLoad(jumpdata.chardata.builder)
                            end
                            
                            if worldjump.saveinventory then -- inventory extra code, to only transfer a set amount of stuff
                                if TUNING.TELEPORTATOMOD.ITEMNUMBERTRANS~="all" then -- defined in modmain, only transfer a number of items
                                    local transitems = {}
                                    for i=1,TUNING.TELEPORTATOMOD.ITEMNUMBERTRANS do
                                        table.insert(transitems,jumpdata.chardata.inventory.items[i])
                                    end
                                    jumpdata.chardata.inventory.items = transitems
                                    jumpdata.chardata.inventory.equip = {} -- delete quipped items
                                end
                                player.components.inventory.ignoresound = true -- no sound when giving them to player
                                player.components.inventory:OnLoad(jumpdata.chardata.inventory)
                                player.components.inventory.ignoresound = false
                            end
                            
                        else -- compatibilty code for older savegames we did not save chardata yet...
                            if worldjump.saveage then
                                player.components.age:OnLoad(jumpdata.age_data)
                            end
                            if worldjump.savebuilder then
                                player.components.builder:OnLoad(jumpdata.builder_data)
                            end
                            
                            if TUNING.TELEPORTATOMOD.repickcharacter==false and jumpdata.prefab == player.prefab and jumpdata.skin_data then -- load skin, if forceload char and we have the same character selected again
                                player.components.skinner:OnLoad(jumpdata.skin_data)
                            end
                            
                            if worldjump.saveinventory then -- inventory extra code, to only transfer a set amount of stuff
                                if TUNING.TELEPORTATOMOD.ITEMNUMBERTRANS~="all" then -- defined in modmain, only transfer a number of items
                                    local transitems = {}
                                    for i=1,TUNING.TELEPORTATOMOD.ITEMNUMBERTRANS do
                                        table.insert(transitems,jumpdata.inventory_data.items[i])
                                    end
                                    jumpdata.inventory_data.items = transitems
                                    jumpdata.inventory_data.equip = {} -- delete quipped items
                                end
                                player.components.inventory.ignoresound = true -- no sound when giving them to player
                                player.components.inventory:OnLoad(jumpdata.inventory_data, jumpdata.inventory_references)
                                player.components.inventory.ignoresound = false
                            end
                        end
                        
                        if TUNING.TELEPORTATOMOD.statssave and jumpdata.stats_data~=nil then
                            if jumpdata.stats_data["health"]~=nil and player.components.health then
                                player.components.health:SetPercent(jumpdata.stats_data["health"])
                            end
                            if jumpdata.stats_data["sanity"]~=nil and player.components.sanity then
                                player.components.sanity:SetPercent(jumpdata.stats_data["sanity"])
                            end
                            if jumpdata.stats_data["hunger"]~=nil and player.components.hunger then
                                player.components.hunger:SetPercent(jumpdata.stats_data["hunger"])
                            end                        
                        end
                        
                    end
                    table.insert(t, userid)
                    player:PushEvent("teleportatojumpLoadData",jumpdata.mods_data) -- push an event, so eg other mods can use this data too
                end
            end
        end)
    end
end

local function OnPlayerDespawn(world, player)
    if world.components.worldjump then
        world.components.worldjump:SavePlayerData(player) -- save player data when leaving overworld (leaving game or entering caves)
    end
end

local WorldJump = Class(function(self, inst)
	self.inst = inst
	-- I don't know the previous session, it is deleted
	-- I don't know the new session identifier that the regenerated world will have
	-- The save slot is a constant, I guess
	local saveslot = SaveGameIndex:GetCurrentSaveSlot() or 0
	self.info_dir = "mod_config_data/mod_worldjump_data_"..tostring(saveslot)

	-- jumping data
	-- saves before jumping, loads when the world loads
	self.player_data = {}
    self:LoadPlayerData() -- loads everytime the fiel, so this infor is not saved within this component -> only the stuff from previous world is accessable, cause with the next jump this file is overwritten
    -- print("playerdata loaded")
	-- player ids get saved so game can determine if guy is a new spawn or not
	-- if he is, then he gets looked up on the jumping data saved
	self.player_ids = {}
    
    self.player_data_save = {} -- is the playerdata that is saved during game wehn player leaves game. is not used when player spawns and is saved in persistent string when worldjump is done
	self.inst:ListenForEvent("ms_playerspawn", OnPlayerSpawn)
    self.inst:ListenForEvent("ms_playerdespawn", OnPlayerDespawn) -- leaving game.. 
    self.saveinventory = self.player_data.saveinventory
    self.savebuilder = self.player_data.savebuilder
    self.saveage = self.player_data.saveage
end)

function WorldJump:OnPlayerExitWorld(player) 
    if TheWorld.components.worldjump and player and player.migration then
        TheWorld.components.worldjump:SavePlayerData(player) -- save player data when leaving overworld (leaving game or entering caves)
    end
end

-- Load the persistent string
-- To prevent resetted worlds or new worlds on the same slot from loading this, we are saving the persistent string again
-- But this time we bind a session to the persistent string, if the string did not have a session stored on it
function WorldJump:LoadPlayerData()
	local callback = function(success, encoded_data)
		if success then
			local decoded_data = json.decode(encoded_data)
			local decoded_session = decoded_data.session_id
			local session_id = TheNet:GetSessionIdentifier()
			if decoded_session == nil then
				decoded_data.session_id = session_id
				local re_encoded_data = json.encode(decoded_data)
				TheSim:SetPersistentString(self.info_dir, re_encoded_data, true)
				self.player_data = decoded_data
			elseif decoded_session == session_id then
				self.player_data = decoded_data
			end
		end
	end
	TheSim:GetPersistentString(self.info_dir, callback)
    -- print("HIER LoadPlayerData "..tostring(self.player_data and next(self.player_data) and self.player_data.inventory_data and self.player_data.inventory_data.items and self.player_data.inventory_data.items[0] or "kein Item"))
end

-- Save a persistent string with all the relevant player info
function WorldJump:SavePlayerData(pl)	
    -- print("SavePlayerData")
    local stuff = {}
    local inventory_data, inventory_references = nil,nil
    local skin_data = nil
    local stats_data = {}
    local mods_data = {}
    local healthpercent = nil
    local sanitypercent = nil
    local hungerpercent = nil
    if pl and pl:HasTag("player") then -- only save for one specific player, eg when he leaves
        pl.components.inventory:DropEverythingWithTag("irreplaceable")
        -- inventory_data, inventory_references = pl.components.inventory:OnSave()
        -- stuff.inventory_data = inventory_data
        -- stuff.inventory_references = inventory_references
        if pl.OnSave~=nil then
            local record = pl:GetSaveRecord() -- refs are empty anyway (at least for wx78, refs from components are not saved, but also not needed?)
            if record then
                stuff.chardata = record.data
            end
        end
        if pl.components.upgrademoduleowner then
            stuff.upgrademoduleowner_data,stuff.upgrademoduleowner_refs = pl.components.upgrademoduleowner:OnSave()
        end
        -- print("HIER inventory_data and reference: "..tostring(inventory_data).." , "..tostring(inventory_references).." from "..tostring(pl))
        -- for k,v in pairs(inventory_data.items) do
            -- print(tostring(k).." , "..tostring(v))
        -- end
        stuff.timefromsave = GetTime()
        stuff.prefab = pl.prefab -- save also the prefab, so we can force load the same character after worldjump (within modmain)
        self.player_data_save[pl.userid] = stuff -- save or overload the stuff of this player
        healthpercent = pl.components.health and pl.components.health:GetPercent() or 1
        sanitypercent = pl.components.sanity and pl.components.sanity:GetPercent() or 1
        hungerpercent = pl.components.hunger and pl.components.hunger:GetPercent() or 1
        stats_data["health"] = healthpercent>0.2 and healthpercent or 0.2
        stats_data["sanity"] = sanitypercent>0.3 and sanitypercent or 0.3
        stats_data["hunger"] = hungerpercent>0.4 and hungerpercent or 0.4
        stuff.stats_data = stats_data
        if TUNING.TELEPORTATOMOD.functionsavewithteleportato~=nil then
            mods_data = TUNING.TELEPORTATOMOD.functionsavewithteleportato(pl)
        end -- otherwise empty list
        stuff.mods_data = mods_data
    else -- in case of worldjump
        -- print("SavePlayerData worldjump")
        for k, v in pairs(AllPlayers) do -- all players that are online and in overworld
            print("SavePlayerData save data for "..tostring(v))
            stuff = {}
            local record = v:GetSaveRecord() -- refs are empty anyway (at least for wx78, refs from components are not saved, but also not needed?)
            if record then
                stuff.chardata = record.data
            end
            
            if v.components.upgrademoduleowner then
                stuff.upgrademoduleowner_data,stuff.upgrademoduleowner_refs = v.components.upgrademoduleowner:OnSave()
            end
            v.components.inventory:DropEverythingWithTag("irreplaceable")
            -- inventory_data, inventory_references = v.components.inventory:OnSave()
            -- stuff.inventory_data = inventory_data
            -- stuff.inventory_references = inventory_references
            -- print("HIER worldjump inventory_data and reference: "..tostring(inventory_data).." , "..tostring(inventory_references).." from "..tostring(v))
            stuff.timefromsave = GetTime()
            stuff.prefab = v.prefab -- save also the prefab, so we can force load the same character after worldjump (within modmain)
            self.player_data_save[v.userid] = stuff
            healthpercent = v.components.health and v.components.health:GetPercent() or 1
            sanitypercent = v.components.sanity and v.components.sanity:GetPercent() or 1
            hungerpercent = v.components.hunger and v.components.hunger:GetPercent() or 1
            stats_data["health"] = healthpercent>0.2 and healthpercent or 0.2
            stats_data["sanity"] = sanitypercent>0.3 and sanitypercent or 0.3
            stats_data["hunger"] = hungerpercent>0.4 and hungerpercent or 0.4
            stuff.stats_data = stats_data
            if TUNING.TELEPORTATOMOD.functionsavewithteleportato~=nil then
                mods_data = TUNING.TELEPORTATOMOD.functionsavewithteleportato(v)
            end -- otherwise empty list
            stuff.mods_data = mods_data
        end
        self.player_data_save.saveinventory = self.saveinventory
        self.player_data_save.savebuilder = self.savebuilder
        self.player_data_save.saveage = self.saveage
        if self.inst.ismastershard then -- only for master shard
            local encoded_data = json.encode(self.player_data_save)
            TheSim:SetPersistentString(self.info_dir, encoded_data, true) -- only save it in string when the worldjump is done.
        end
    end
    -- print("hier should be saved now ,"..tostring(pl))
	
end

-- Load the saved player ids
function WorldJump:OnLoad(data)
	if data then
		local t = self.player_ids
		for i, v in ipairs(data) do
            table.insert(t, v)
		end
        self.player_data_save = data.player_data_save or {}
	end
end

-- Save player ids to help on player spawns
function WorldJump:OnSave()
	local data = {}
	local t = self.player_ids
	for i, v in ipairs(t) do
		table.insert(data, v)
	end
    data.player_data_save = self.player_data_save
	return data
end

-- Run this method and let the magic do the rest
-- Since we parse AllPlayers, all the players have to be on the jumping master shard
-- A dedicated server won't count itself for the player count
function WorldJump:DoJump(keepage,keepinventory,keeprecipes)
	if self.inst.ismastershard then
        if keepage==nil or keepage then -- by default, everything is true
            self.saveage = true
        else -- if false
            self.saveage = false
        end
        if keepinventory==nil or keepinventory then    
            self.saveinventory = true
        else
            self.saveinventory = false
        end
        if keeprecipes==nil or keeprecipes then
            self.savebuilder = true
        else
            self.savebuilder = false
        end

        if _G.TUNING.TELEPORTATOMOD.GEMAPIActive and #SHARD_LIST>0 then 
            print("DoShardWorldJumpifmastershard")
            _G.TheWorld.shard.components.shard_teleplayersave:RequestPlayerData()  -- notify cave that he should send us his data... within the function that is called by cave within forest, receive and save the cavedata within the forest data and call DoJumpFinalWithCave
            return
        else
            print("worldjump ohne shards")
            self:SavePlayerData()
            TheNet:SendWorldResetRequestToServer()
        end
    end
end

function WorldJump:DoJumpFinalWithCave() -- only used with GEM API and it contains also cave informtaion
    -- wir können jetzt auch zählen, wieviele im cave sind... dh evtl können wir noch hier abbrechen, wenns zu wenige spieler sind (und auch hier ein announce dafür machen)
    print("DoJumpFinalWithCave")
    self:SavePlayerData()
    TheNet:SendWorldResetRequestToServer()
end    

return WorldJump
