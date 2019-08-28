
local function GiveStuff(inst,fn,self,name,...)-- to run a function only once per inst
    -- print("HIER startstuff comp, GiveStuff, for "..tostring(self.inst).." "..tostring(name).." : "..tostring(self.done[name]))
    if self.done[name]~=true or (inst.adv_startstuffdone~=nil and inst.adv_startstuffdone[name]~=true) then -- put the done thing here, cause without the DoTask dealy (can also be 0), this might be called before OnLoad
        self.done[name] = true -- should be before the function is run, to make it possible to set done to false in this function
        -- if inst.adv_startstuffdone==nil then
            -- inst.adv_startstuffdone = {}
        -- end
        -- inst.adv_startstuffdone[name] = true -- this will be saved also for clients within modmain
        if fn~=nil then
            fn(inst,...)
        end
    end
end

local StartStuff = Class(function(self, inst)
	self.inst = inst
	self.done = {} -- self.done["thisthat"] == false/true
    -- print("component startstuff for "..tostring(self.inst).." created")
end)

function StartStuff:DoStartStuffIn(x,fn,name,...) -- use this eg within AddPrefabPostInit if you want to run the code AFTER the components were acutally loaded (OnLoad)
    self.inst:DoTaskInTime(x, GiveStuff, fn, self,name,...)
end

function StartStuff:DoStartStuffNow(fn,name,...) -- dont use this before the game already started, otherwise our OnLoad was not loaded yet. use DoStartStuffIn instead
    GiveStuff(self.inst, fn, self,name,...)
end

function StartStuff:OnSave()
	return { done = self.done , partpositions=self.partpositions,adv_level=self.adv_level,adv_chapter=self.adv_chapter}
end

function StartStuff:OnLoad(data)
	print("StartStuff:OnLoad "..tostring(self.inst))
    self.done = data and data.done or {}
    self.partpositions = data and data.partpositions or {} -- this will only be used for the world
    self.adv_level = data and data.adv_level or nil -- this will only be used for the world
    self.adv_chapter = data and data.adv_chapter or nil -- this will only be used for the world
    if self.inst~=nil and self.inst.mynetvarAdvStartStuffDone~=nil then
        for k,v in pairs(self.done) do
            print("StartStuff:OnLoad send to client "..tostring(k))
            self.inst.mynetvarAdvStartStuffDone:set(k) -- make also clients know this
        end
    end
end


return StartStuff
