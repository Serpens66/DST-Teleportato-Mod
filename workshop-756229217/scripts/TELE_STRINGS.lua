
local STRINGS = GLOBAL.STRINGS

-- allwos the admin to type into the say-console "/worldjump" to start poll to generate new world
STRINGS.UI.BUILTINCOMMANDS.WORLDJUMP = {
	PRETTYNAME = "World Jump",
	DESC = "Activate the potato!",
	VOTETITLEFMT = "Should we activate the potato?",
	VOTENAMEFMT = "vote to activate the potato",
	VOTEPASSEDFMT = "Potato activating in 10 seconds...",
}


if STRINGS.TELEPORTATOMOD==nil then
    STRINGS.TELEPORTATOMOD = {}
end

STRINGS.TELEPORTATOMOD.WORLD_JUMP = "Worldjump!"
STRINGS.TELEPORTATOMOD.WORLD_JUMP_ABORT = "Worldjump aborted, cause world is not mastersim/mastershard!"
STRINGS.TELEPORTATOMOD.WORLD_JUMP_ABORT_NOT_ENOUGH_PLAYERS =
    "Worldjump aborted, cause not enough players are near teleportato.\nMore than half needed %u/%u"
STRINGS.TELEPORTATOMOD.WORLD_JUMP_TIPS = "Leave teleportato area, if you dont want a new world within 15 seconds!"
STRINGS.TELEPORTATOMOD.WORLD_JUMP_TICK_5S = "5 seconds left!"
STRINGS.TELEPORTATOMOD.WORLD_JUMP_TICK_4S = "4 seconds left!"
STRINGS.TELEPORTATOMOD.WORLD_JUMP_TICK_3S = "3 seconds left!"
STRINGS.TELEPORTATOMOD.WORLD_JUMP_TICK_2S = "2 seconds left!"
STRINGS.TELEPORTATOMOD.WORLD_JUMP_TICK_1S = "1 seconds left!"
STRINGS.TELEPORTATOMOD.TELE_PICKUP = " picked up the "

STRINGS.TELEPORTATOMOD.TELE_COMPLETED_HEARTHAT = "Teleportato Completed! Did you hear that?!"
STRINGS.TELEPORTATOMOD.TELE_COMPLETED = "Teleportato Completed!"
STRINGS.TELEPORTATOMOD.TELE_MORE_THAN = "More than %u players must be near teleportato!\nCounted only: %u"
STRINGS.TELEPORTATOMOD.TELE_LESS_THAN = "At least %u players must be near teleportato!\nCounted only: %u"

STRINGS.TELEPORTATOMOD.TELE_DISABLED =
    "Worldjump disabled.\nBut Admin/Host can still type the commands in console or set TUNING.TELEPORTATOMOD.TELENEWWORLD to true!"

STRINGS.TELEPORTATOMOD.PLAYERS_TOO_FAR_AWAY = "Somebody is too far away..."
STRINGS.TELEPORTATOMOD.MAXWELL_DOOR_ENTER = "HA-HA-HA!"
STRINGS.TELEPORTATOMOD.PLAYER_REJECT_ENTER = "Maybe next time..."
STRINGS.TELEPORTATOMOD.DIALOG_ADV_TITLE = "Doorway to Adventure!"
STRINGS.TELEPORTATOMOD.DIALOG_ADV_BODYTEXT =
    "You are about to embark on a long, arduous expedition to locate something familiar. You will need to survive five randomly chosen worlds, each presenting you with a unique challenge. You won't come back to this world."
STRINGS.TELEPORTATOMOD.DIALOG_ADV_GO = "Go"
STRINGS.TELEPORTATOMOD.DIALOG_ADV_STAY = "Stay"

STRINGS.TELEPORTATOMOD.TITLE_PROLOGUE = "Prologue"
