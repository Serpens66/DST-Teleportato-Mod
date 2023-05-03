-- save the skin of items
-- when spawning an item you either need a userid from an active player that owns that skin, or you need a valid skin_id which is only valid for this world.
-- wenn loading items there is no creator known, so a valid skin id is needed. But after worldloading there are no valid skin_id because they are only created on spawning the item first the item.
-- and for obvious reason we dont have access to a list of valid skin_ids to save and load them, otherwise we could cheat all skins.
-- so the only possible way is to remember the creator of every single items and on spawning those items, we have to spawn them with the creators userid.
-- therefore we will hack into the OnBuld, to save the creator, and then hack into the games save and load stuff for entities SpawnSaveRecord and GetSaveRecord.
-- only overwrite as less as possible and only if there is a skin


local _G = GLOBAL
AddPrefabPostInitAny(function(inst)
    if inst~=nil and inst.prefab~=nil and _G.IsRecipeValid(inst.prefab) and not inst:HasTag("player") then
        if _G.PREFAB_SKINS[inst.prefab]~=nil then -- if skins for this thing exist, we change the onbuild and onsave to save the creator of it
            local _OnBuilt = inst.OnBuilt
            local function OnBuilt(inst,creator,...)
                if inst.skinname~=nil and creator and creator.userid then -- only if it was build with a skin, save the creator
                    inst:Setthecreatorbuilder(creator.userid) -- save it within entityscript, so it can be saved/loaded there and used within their functions
                end
                if _OnBuilt~=nil then
                    _OnBuilt(inst,creator,...) -- call the previous
                end
                
            end
            inst.OnBuilt = OnBuilt
        end
    end
end)

-- if the devs are changing SpawnSaveRecord, we have to adjust it accoridingly (mainfunctions.lua). they are mostly a copy, except for the thecreatorbuilder part

local _SpawnSaveRecord = _G.SpawnSaveRecord
_G.SpawnSaveRecord = function(saved, newents,...)
    if saved.thecreatorbuilder==nil or saved.skinname==nil then -- only overwrite this function, if a creator and skinname was saved for this
        return _SpawnSaveRecord(saved,newents,...)
    else
        -- print(string.format("~~~~~~~~~~~~~~~~~~~~~SpawnSaveRecord [%s, %s, %s]", tostring(saved.id), tostring(saved.prefab), tostring(saved.data)))
        local inst = _G.SpawnPrefab(saved.prefab, saved.skinname, saved.skin_id, saved.thecreatorbuilder or nil) -- also provide the creator, so we get our skin
        if inst then
            if saved.alt_skin_ids then
                inst.alt_skin_ids = saved.alt_skin_ids
            end
            if saved.thecreatorbuilder then
                inst.thecreatorbuilder = saved.thecreatorbuilder
            end
            inst.Transform:SetPosition(saved.x or 0, saved.y or 0, saved.z or 0)
            if not inst.entity:IsValid() then
                --print(string.format("SpawnSaveRecord [%s, %s] FAILED - entity invalid", tostring(saved.id), saved.prefab))
                return nil
            end
            if newents then
                --this is kind of weird, but we can't use non-saved ids because they might collide
                if saved.id  then
                    newents[saved.id] = {entity=inst, data=saved.data} 
                else
                    newents[inst] = {entity=inst, data=saved.data} 
                end

            end
            -- Attach scenario. This is a special component that's added based on save data, not prefab setup.
            if saved.scenario or (saved.data and saved.data.scenariorunner) then
                if inst.components.scenariorunner == nil then
                    inst:AddComponent("scenariorunner")
                end
                if saved.scenario then
                    inst.components.scenariorunner:SetScript(saved.scenario)
                end
            end
            inst:SetPersistData(saved.data, newents)
        else
            print(string.format("SpawnSaveRecord [%s, %s] FAILED", tostring(saved.id), saved.prefab))
        end
        return inst
    end
end
AddGlobalClassPostConstruct("entityscript", "EntityScript", function(self) 
    local _GetSaveRecord = self.GetSaveRecord
    local function GetSaveRecord(self,...)
        if self.thecreatorbuilder==nil or self.skinname==nil then
            return _GetSaveRecord(self,...)
        else
            local record, references = _GetSaveRecord(self,...) -- I think no need here to copy paste the code
            if self.thecreatorbuilder then
                record.thecreatorbuilder = self.thecreatorbuilder
            end
            return record, references
        end
    end
    self.GetSaveRecord = GetSaveRecord
    
    local function Setthecreatorbuilder(self,thecreatorbuilder)
        print("Setthecreatorbuilder "..tostring(self).." "..tostring(thecreatorbuilder))
        self.thecreatorbuilder = thecreatorbuilder
    end
    self.Setthecreatorbuilder = Setthecreatorbuilder
end)