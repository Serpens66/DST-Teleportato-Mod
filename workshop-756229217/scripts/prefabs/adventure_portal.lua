local BigPopupDialogScreen = require "screens/bigpopupdialog"

local assets = {
	Asset("ANIM", "anim/portal_adventure.zip"),
	Asset("MINIMAP_IMAGE", "portal"),
}

local function GetVerb()
    return STRINGS.ACTIONS.ACTIVATE.GENERIC
end

local function JumpToAdventure(world, carrystuff)
    TheWorld.components.adventurejump:DoJump(carrystuff, carrystuff, carrystuff) -- without transfering stuff
end

local function OnStartAdventure(inst, carrystuff)
    local player = inst.adventureSerpleader:value()
    local userid = player and player.userid
    if userid and userid == inst.valid_adventureSerpleader_id then
        -- if TheNet:GetPlayerCount() ~= #AllPlayers then
        -- inst.components.talker:Say("Hey! Where are the others?")
        -- else
        local everybody_nearby = true
        local dist_sq = 30 * 30
        for k, v in pairs(AllPlayers) do
            if not v:IsNear(inst, 10) then
                inst.components.talker:Say(STRINGS.TELEPORTATOMOD.PLAYERS_TOO_FAR_AWAY)
                everybody_nearby = false
                break
            end
        end
        if everybody_nearby then
            inst.components.talker:Say(STRINGS.TELEPORTATOMOD.MAXWELL_DOOR_ENTER)
            inst.SoundEmitter:KillSound("talk")
            inst.SoundEmitter:PlaySound("dontstarve/common/teleportato/teleportato_maxwelllaugh", "teleportato_laugh")
            for k, v in pairs(AllPlayers) do
                if v.components.health and not v.components.health:IsDead() then
                    v.sg:GoToState("teleportato_teleport")
                end
            end
            TheWorld:DoTaskInTime(5, JumpToAdventure, carrystuff)
        else
            player.components.health:SetInvincible(false) -- remove invincible 
        end
        -- end
        inst.components.activatable.inactive = true
    end
end

local function OnRejectAdventure(inst)
    local player = inst.adventureSerpleader:value()
    player.components.health:SetInvincible(false) -- remove invincible 
    local userid = player and player.userid
    if userid and userid == inst.valid_adventureSerpleader_id then
        inst.components.talker:Say(STRINGS.TELEPORTATOMOD.PLAYER_REJECT_ENTER)
        inst.components.activatable.inactive = true
    end
end

local function OnActivate(inst, doer)
    inst.valid_adventureSerpleader_id = doer.userid
    inst.adventureSerpleader:set_local(doer)
    inst.adventureSerpleader:set(doer)
    doer.components.health:SetInvincible(true) -- make invincible 
end

local function StartRagtime(inst)
    if inst.ragtime_playing == nil then
        inst.ragtime_playing = true
        inst.SoundEmitter:PlaySound("dontstarve/common/teleportato/ragtime", "ragtime")
    else
        inst.SoundEmitter:SetVolume("ragtime", 1)
    end
end

local function OnNearPlayer(inst, player)
    inst.AnimState:PushAnimation("activate", false)
    inst.AnimState:PushAnimation("idle_loop_on", true)
    inst.SoundEmitter:PlaySound("dontstarve/common/maxwellportal_activate")
    inst.SoundEmitter:PlaySound("dontstarve/common/maxwellportal_idle", "idle")

    inst:DoTaskInTime(1, StartRagtime)
end

local function ShutUpRagtime(inst)
    inst.SoundEmitter:SetVolume("ragtime", 0)
end

local function OnFarAllPlayers(inst)
    inst.AnimState:PushAnimation("deactivate", false)
    inst.AnimState:PushAnimation("idle_off", true)
    inst.SoundEmitter:KillSound("idle")
    inst.SoundEmitter:PlaySound("dontstarve/common/maxwellportal_shutdown")

    inst:DoTaskInTime(1, ShutUpRagtime)
end

local function OnAdventureLeaderDirty(inst)
    local player = inst.adventureSerpleader:value()
    if player == ThePlayer then
        local function start_adventure()
            TheFrontEnd:PopScreen()
            local rpc = GetModRPC("adventureSerp", "confirm")
            SendModRPCToServer(rpc, inst, true)
        end

        local function reject_adventure()
            TheFrontEnd:PopScreen()
            local rpc = GetModRPC("adventureSerp", "confirm")
            SendModRPCToServer(rpc, inst, false)
        end

        local yes_box = {
            text = STRINGS.TELEPORTATOMOD.DIALOG_ADV_GO,
            cb = start_adventure
        }
        local no_box = {
            text = STRINGS.TELEPORTATOMOD.DIALOG_ADV_STAY,
            cb = reject_adventure
        }

        local bpds = BigPopupDialogScreen(STRINGS.TELEPORTATOMOD.DIALOG_ADV_TITLE, STRINGS.TELEPORTATOMOD.DIALOG_ADV_BODYTEXT, {yes_box, no_box})
        bpds.title:SetPosition(0, 85, 0)
        bpds.text:SetPosition(0, -15, 0)

        TheFrontEnd:PushScreen(bpds)
    end
end

local function RegisterNetListeners(inst)
    inst:ListenForEvent("adventureSerpleaderdirty", OnAdventureLeaderDirty)
end

local function OnTalk(inst, script)
    inst.SoundEmitter:PlaySound("dontstarve/characters/maxwell/talk_LP", "talk")
end

local function KillTalkSound(inst)
    inst.SoundEmitter:KillSound("talk")
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.MiniMapEntity:SetIcon("portal.png")

    inst.AnimState:SetBank("portal_adventure")
    inst.AnimState:SetBuild("portal_adventure")
    inst.AnimState:PlayAnimation("idle_off", true)

    inst.GetActivateVerb = GetVerb

    inst.adventureSerpleader = net_entity(inst.GUID, "adventureSerp.leader", "adventureSerpleaderdirty")

    inst:DoTaskInTime(0, RegisterNetListeners)

    inst:AddComponent("talker")
    inst.components.talker.fontsize = 35
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.offset = Vector3(0, -1050, 0)

    inst:AddTag("adventure_portal")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.talker.ontalk = OnTalk
    inst:ListenForEvent("donetalking", KillTalkSound)

    inst:AddComponent("inspectable")
    inst.components.inspectable:RecordViews()

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(4, 5)
    inst.components.playerprox:SetOnPlayerNear(OnNearPlayer)
    inst.components.playerprox:SetOnPlayerFar(OnFarAllPlayers)

    inst:AddComponent("activatable")
    inst.components.activatable.OnActivate = OnActivate
    inst.components.activatable.inactive = true
    inst.components.activatable.quickaction = true

    inst.StartAdventure = OnStartAdventure
    inst.RejectAdventure = OnRejectAdventure

    return inst
end

return Prefab("adventure_portal", fn, assets)