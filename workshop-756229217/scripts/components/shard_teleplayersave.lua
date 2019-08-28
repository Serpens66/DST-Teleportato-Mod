------------------------------------------------------------------------
--[[ shard_teleplayersave ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

    assert(TheWorld.ismastersim, "shard_teleplayersave should not exist on client")

    --------------------------------------------------------------------------
    --[[ Constants ]]
    --------------------------------------------------------------------------

    local MAX_TARGETS = 10

    --------------------------------------------------------------------------
    --[[ Member variables ]]
    --------------------------------------------------------------------------

    --Public
    self.inst = inst

    --Private
    local _world = TheWorld
    local _ismastershard = _world.ismastershard
    local _requestdata = net_bool(inst.GUID, "shard_teleplayersave._requestdata", "shard_teleplayersave._requestdatadirty") -- value does not matter, everytime it is changed the slave sends data to master
    -- local _requestdata = net_event(inst.GUID, "shard_teleplayersave._requestdata")
    
    --------------------------------------------------------------------------
    --[[ Private member functions ]]
    --------------------------------------------------------------------------
    
    local function SaveAndSendDataToMaster()
        print("SaveAndSendDataToMaster")
        if not _ismastershard then
            print("SaveAndSendDataToMaster slave")
            _world.components.worldjump:SavePlayerData() -- will save playerdata within worldjump.player_data_save
            local player_data_save = _world.components.worldjump.player_data_save
            SendShardRPCToServer(SHARD_RPC.TeleSerp.PlayerSave, player_data_save) -- send it to master (currently only identified by forest Tag...)
        end
    end
    

    
    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------

    
    -- inst:ListenForEvent("shard_teleplayersave._requestdatadirty", function(inst) -- if the master sends a request via netvar to the slaves, save our data and send them via rpc
    inst:ListenForEvent("shard_teleplayersave._requestdata", function(inst) -- if the master sends a request via netvar to the slaves, save our data and send them via rpc   
        print("_requestdatadirty")
        if not _ismastershard then -- only do it when you are not master
            if _requestdata:value()==true then
                print("_requestdatadirty slave and set true")
                SaveAndSendDataToMaster()
            end
        end
    end)
    _requestdata:set(false)
    
    --------------------------------------------------------------------------
    --[[ Public member functions ]]
    --------------------------------------------------------------------------
    
    function self:RequestPlayerData()
        print("RequestPlayerData")
        _requestdata:set(true) -- simply change the value, the value itself does not matter,we only want to trigger the dirty functions
        -- _requestdata:push()
    end
    
    
    --------------------------------------------------------------------------
    --[[ End ]]
    --------------------------------------------------------------------------
    
end)