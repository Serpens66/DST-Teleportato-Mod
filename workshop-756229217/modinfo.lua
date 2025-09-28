-- This information tells other players more about the mod
name = "Teleportato"
description = "Adds the teleportato parts to the World generation and makes the Divining Rod craftable. In the settings of mod, you can choose what should happen, when teleportato is complete and if a new world should be generated if activated. Better don't add this mod to already generated world and don't deactivate it if you had it active at world generation! Admin can use say-command /worldjump to generate new world. Stuff from players at cave wont be saved (unless you have GEMAPI active)!\nOther mods can add adventure like worlds!"
author = "Serpens66"
version = "1.283"

-- This is the URL name of the mod's thread on the forum; the part after the index.php? and before the first & in the URL
-- Example:
-- http://forums.kleientertainment.com/index.php?/files/file/202-sample-mods/
-- becomes
-- /files/file/202-sample-mods/
forumthread = ""

--Adds a priority to the mod. Loads it before or after other mods. This can help to fix various incompatibilities between other mods.
priority = 8888

-- This lets other players know if your mod is out of date, update it to match the current version in the game
api_version = 10

--This lets the clients know that they need to download the mod before they can join a server that is using it.
all_clients_require_mod = true

--This let's the game know that this mod doesn't need to be listed in the server's mod listing
client_only_mod = false

--Let the mod system know that this mod is functional with Don't Starve Together
dst_compatible = true

--These tags allow the server running this mod to be found with filters from the server listing screen
server_filter_tags = {"teleportato","worldgen","ancientstation","worldjump","worldhopping"}

--Adds an icon to the mod
icon_atlas = "modicon.xml"
icon = "modicon.tex"

configuration_options =
{
    {
		name = "variateworld",
		label = "Variate World?",
		hover = "Worldsettings are randomly chosen at worldgeneration, your worldsettings will have no effect! Use my mod -Increase Animals- for more variation.",
		options =	{
						{description = "No", data = false, hover = "Always the same worldsettings you chose."},
                        {description = "Just islands", data = "justislands", hover = "Nothing is variated, but the -Variate Islands / Variate Event- option below works."},
                        {description = "Yes, mixed Worlds", data = true, hover = "Medium, but small chance for easy/hard aspects"},
                        {description = "Yes, easy Worlds", data = "easy", hover = " "},
                        {description = "Yes, medium Worlds", data = "medium", hover = " "},
                        {description = "Yes, hard Worlds", data = "hard", hover = " "},
                        {description = "Yes, very hard Worlds", data = "very hard", hover = " "},
					},
		default = false,
	},
    {
		name = "variate_islands",
		label = "Number of Islands?",
		hover = "If -Variate World- is enabled, how many islands should be generated on average (the more the smaller they get)",
		options =	{
						{description = "Default", data = false, hover = "Vanilla islands"},
                        {description = "Random", data = "random", hover = "Random amount of islands"},
                        {description = "Few", data = "few", hover = "10-30% of the task-count"},
                        {description = "Medium", data = "medium", hover = "30-55% of the task-count"},
                        {description = "Many", data = "many", hover = "50-80% of the task-count"},
                        {description = "All", data = "all", hover = "Tries to put every task into an island (many small islands)"},
					},
		default = false,
	},
    {
		name = "island_size_setting",
		label = "Size of Islands?",
		hover = "If -Variate World- is enabled, what size should the islands have? (affects number of tasks per island. does not change vanilla islands)",
		options =	{
						{description = "MainSmall Same", data = "mainsmall_othersamesize", hover = "Mainland small (2 tasks) and rest is divided between rest of islands."},
                        {description = "All Same Size", data = "allsamesize", hover = "All islands will be roughly the same size. (default)"},
                        {description = "MainBig Small", data = "mainbig_othersmall", hover = "Islands will be a single task and rest tasks are added to mainland."},
					},
		default = "allsamesize",
	},
    {
		name = "variate_suck",
		label = "Variate annoying?",
        hover = "If -Variate World- is enabled, also randomly set: wildfire, disease, frograin, deerclops, antlion and petrification.",
		options =	{
						{description = "No", data = false, hover = "Will use your set worldsetting instead."},
                        {description = "Yes", data = true, hover = " "},
					},
		default = true,
	},
    {
		name = "variate_specialevent",
		label = "Variate Event?",
		hover = "If -Variate World- is enabled, set here the chance that the next world will have one random special event",
		options =	{
						{description = "Disabled", data = 0, hover = "Will use your set worldsetting instead."},
                        {description = "5%", data = 5, hover = " "},
                        {description = "10%", data = 10, hover = " "},
                        {description = "15%", data = 15, hover = " "},
                        {description = "20%", data = 20, hover = " "},
                        {description = "25%", data = 25, hover = " "},
                        {description = "30%", data = 30, hover = " "},
                        {description = "35%", data = 35, hover = " "},
                        {description = "40%", data = 40, hover = " "},
                        {description = "45%", data = 45, hover = " "},
                        {description = "50%", data = 50, hover = " "},
                        {description = "55%", data = 55, hover = " "},
                        {description = "60%", data = 60, hover = " "},
                        {description = "65%", data = 65, hover = " "},
                        {description = "70%", data = 70, hover = " "},
                        {description = "75%", data = 75, hover = " "},
                        {description = "80%", data = 80, hover = " "},
                        {description = "85%", data = 85, hover = " "},
                        {description = "90%", data = 90, hover = " "},
                        {description = "95%", data = 95, hover = " "},
                        {description = "100%", data = 100, hover = " "},
					},
		default = 0,
	},
    {
		name = "DSlike",
		label = "DS like",
			hover = "If enabled,you turn all my changes like more enemies,thulecite statues and obelisks around the ring, off. None of the following options will do something.",
		options =	{
						{description = "Disabled", data = false, hover = " "},
                        {description = "Enabled", data = true, hover = " "},
					},
		default = false,
	},
    {
		name = "null_option",
		label = "When activate",
		hover = "Stuff from players at cave wont be saved!",
		options =	{
						{description = " ", data = 0, hover = " "},
					},
		default = 0,
	},
    {
		name = "newworld",
		label = "Generate New World",
			hover = "Generate a new world, old will be destroyed. You may choose another character. Set below which things should be transferred. Admin can also change this during game with changing TUNING.TELEPORTATOMOD.TELENEWWORLD true/false",
		options =	{
						{description = "Disabled", data = false, hover = " "},
                        {description = "Enabled", data = true, hover = " "},
					},
		default = true,
	},
    {
		name = "min_players",
		label = "Min Players",
		hover = "Min amount of players that have to be near teleportato to activate the worldjump.",
		options =	{
						{description = "More Half", data = "half", hover = "Default. More than half of all currently active players."},
                        {description = "All", data = "all", hover = "All currently active players."},
                        {description = "1", data = 1, hover = " "},
                        {description = "2", data = 2, hover = " "},
                        {description = "3", data = 3, hover = " "},
                        {description = "4", data = 4, hover = " "},
                        {description = "5", data = 5, hover = " "},
                        {description = "6", data = 6, hover = " "},
                        {description = "7", data = 7, hover = " "},
                        {description = "8", data = 8, hover = " "},
                        {description = "9", data = 9, hover = " "},
                        {description = "10", data = 10, hover = " "},
                        {description = "11", data = 11, hover = " "},
                        {description = "12", data = 12, hover = " "},
                        {description = "13", data = 13, hover = " "},
                        {description = "14", data = 14, hover = " "},
                        {description = "15", data = 15, hover = " "},
                        {description = "16", data = 16, hover = " "},
					},
		default = "half",
	},
    {
		name = "agesave",
		label = "Save Days?",
			hover = "Transfer -days survived-? If enabled it makes the next world harder, because eg hound-waves check for this number.",
		options =	{
						{description = "No", data = false, hover = " "},
                        {description = "Yes", data = true, hover = " "},
					},
		default = true,
	},
    {
		name = "inventorysave",
		label = "Save Inventory?",
			hover = "Transfer the stuff in inventory?",
		options =	{
						{description = "No", data = false, hover = " "},
                        {description = "Yes", data = true, hover = " "},
					},
		default = true,
	},
    {
		name = "inventorysavenumber",
		label = "Number of items?",
			hover = "How much of your inventory should be transferred",
		options =	{
						{description = "Everything", data = "all", hover = "All items and also everything equipped."},
                        {description = "1", data = 1, hover = "Only the first x items, no equipped stuff"},
                        {description = "2", data = 2, hover = "Only the first x items, no equipped stuff"},
                        {description = "3", data = 3, hover = "Only the first x items, no equipped stuff"},
                        {description = "4", data = 4, hover = "Only the first x items, no equipped stuff"},
                        {description = "5", data = 5, hover = "Only the first x items, no equipped stuff"},
                        {description = "6", data = 6, hover = "Only the first x items, no equipped stuff"},
                        {description = "7", data = 7, hover = "Only the first x items, no equipped stuff"},
                        {description = "8", data = 8, hover = "Only the first x items, no equipped stuff"},
					},
		default = "all",
	},
    {
		name = "recipesave",
		label = "Save Prototypes?",
			hover = "Transfer prototypes and unlocked recipes?",
		options =	{
						{description = "No", data = false, hover = " "},
                        {description = "Yes", data = true, hover = " "},
					},
		default = true,
	},
    {
		name = "statssave",
		label = "Save Stats?",
			hover = "Transfer current health/sanity/hunger values? (but minpercent 0.2, 0.3 and 0.4). So eg. never less than 20% health.",
		options =	{
						{description = "No", data = false, hover = " "},
                        {description = "Yes", data = true, hover = " "},
					},
		default = false,
	},
    {
		name = "ALLsave",
		label = "Save Everything else?",
			hover = "Transfer all other data found on your character that was not mentioned yet. If this causes problems or crash, disable this setting.",
		options =	{
						{description = "No", data = false, hover = "Only data mentioned in earlier modsettings might be transfered."},
                        {description = "Yes", data = true, hover = "Only works if you choose the same char in next world."},
					},
		default = true,
	},
    {
		name = "adv_itemcarrysandbox",
		label = "Adventure Stuff",
		hover = "Only if adventure mod is enabled. Able to carry over your stuff from -Maxwells Door- to adventure?",
		options = 
		{
            {description = "no,nothing", data = false, hover="Nothing you got within -Maxwells Door- will carry over to adventure"},
            {description = "yes, everything", data = true, hover="Everything you got within -Maxwells Door- will carry over to adventure"},
        },                   
		default = false,
    },
    {
		name = "announcepickparts",
		label = "Announce Pick?",
			hover = "Do a global announcment when someone picked a teleportato part?",
		options =	{
						{description = "No", data = false, hover = " "},
                        {description = "Yes", data = true, hover = " "},
					},
		default = false,
	},
    {
		name = "null_option",
		label = "",
		hover = "",
		options =	{
						{description = " ", data = 0, hover = " "},
					},
		default = 0,
	},
    {
		name = "Enemies",
		label = "Guards",
			hover = "How much enemies should guard the teleportato positions? They will spawn at beginning of world and again after activating the teleportato.",
		options =	{
						{description = "Disabled", data = 0, hover = " "},
                        {description = "Few", data = 0.5, hover = " "},
                        {description = "Medium", data = 1, hover = "Default"},
                        {description = "Many", data = 2, hover = " "},
					},
		default = 1,
	},
    {
		name = "null_option",
		label = "When completed",
		hover = "Please set, what should happen when you completed (not activated) teleportato",
		options =	{
						{description = " ", data = 0, hover = " "},
					},
		default = 0,
	},
    {
		name = "RegeneratePlayerHealth",
		label = "Player Health Regeneration",
			hover = "All players near the Teleportato will regenerate Health slowly.",
		options =	{
						{description = "Disabled", data = 0, hover = " "},
                        {description = "-1", data = -1, hover = "per 5 seconds"},
                        {description = "-0.5", data = -0.5, hover = "per 5 seconds"},
                        {description = "-0.25", data = -0.25, hover = "per 5 seconds"},
                        {description = "0.25", data = 0.25, hover = "per 5 seconds"},
                        {description = "0.5", data = 0.5, hover = "per 5 seconds"},
                        {description = "1", data = 1, hover = "per 5 seconds"},
                        {description = "2", data = 2, hover = "per 5 seconds (Default)"},
                        {description = "3", data = 3, hover = "per 5 seconds"},
                        {description = "4", data = 4, hover = "per 5 seconds"},
                        {description = "5", data = 5, hover = "per 5 seconds"},
					},
		default = 2,
	},
    {
		name = "RegeneratePlayerHunger",
		label = "Player Hunger Regeneration",
			hover = "All players near the Teleportato will regenerate Hunger slowly.",
		options =	{
						{description = "Disabled", data = 0, hover = " "},
                        {description = "-1", data = -1, hover = "per 5 seconds"},
                        {description = "-0.5", data = -0.5, hover = "per 5 seconds"},
                        {description = "-0.25", data = -0.25, hover = "per 5 seconds"},
                        {description = "0.25", data = 0.25, hover = "per 5 seconds (Default)"},
                        {description = "0.5", data = 0.5, hover = "per 5 seconds"},
                        {description = "1", data = 1, hover = "per 5 seconds"},
                        {description = "2", data = 2, hover = "per 5 seconds"},
                        {description = "3", data = 3, hover = "per 5 seconds"},
                        {description = "4", data = 4, hover = "per 5 seconds"},
                        {description = "5", data = 5, hover = "per 5 seconds"},
					},
		default = 0.25,
	},
    {
		name = "RegeneratePlayerSanity",
		label = "Player Sanity Regeneration",
			hover = "All players near the Teleportato will regenerate Sanity slowly.",
		options =	{
						{description = "Disabled", data = 0, hover = " "},
                        {description = "-Small", data = 1, hover = " "},
                        {description = "-SmallTiny", data = 2, hover = " "},
                        {description = "-Tiny", data = 3, hover = " "},
                        {description = "Tiny", data = 4, hover = " "},
                        {description = "SmallTiny", data = 5, hover = " "},
                        {description = "Small", data = 6, hover = "Default"},
                        {description = "Medium", data = 7, hover = " "},
                        {description = "Large", data = 8, hover = " "},
                        {description = "Huge", data = 9, hover = " "},
					},
		default = 6,
	},
    {
		name = "Ancient",
		label = "Ancient Station",
			hover = "Spawns an Ancient Pseudoscience Station. And an enemy.",
		options =	{
						{description = "Disabled", data = 0, hover = " "},
						{description = "Broken", data = 1, hover = "Thulecite will spawn at the places where you found the teleportato parts! But also some enemies. (Default)"}, -- "thulecite_pieces" "thulecite" "pandoraschest"
                        {description = "Complete", data = 2, hover = " "}, -- "ruins_statue_mage" "ruins_statue_mage_nogem"
					},
		default = 1,
	},
    {
		name = "Thulecite",
		label = "Thulecite",
			hover = "Spawns Thulecite at the previous locations from teleportato parts.",
		options =	{
						{description = "Disabled", data = 0, hover = " "},
                        {description = "Few", data = 1, hover = " "},
                        {description = "Medium", data = 2, hover = "Default"},
                        {description = "Many", data = 3, hover = " "},
					},
		default = 2,
	},
    {
		name = "Chests",
		label = "Treasure Chests",
		hover = "Spawns Treasure Chests at the previous locations from teleportato parts. But also some enemies.",
		options =	{
						{description = "Disabled", data = 0, hover = " "},
                        {description = "Few", data = 1, hover = " "},
                        {description = "Medium", data = 2, hover = "Default"},
                        {description = "Many", data = 3, hover = " "},
					},
		default = 2,
	},
    {
		name = "null_option",
		label = "",
		hover = "",
		options =	{
						{description = " ", data = 0, hover = " "},
					},
		default = 0,
	},
    {
        name = "set_behaviour",
        label = "Placing Style",
        hover = "Parts are normally only placed, if nothing else is blocking the position. Therefore it can happen, that one of it won't exist.",
        options =   {
                        {description = "IgnoreBarren", data = 1, hover = "Ignore Impassable and Barren, when placing."},
                        {description = "IgnoreAll", data = 2, hover = "Ignores also other setpieces, but it could be at the same location like other things."},
                        {description = "IgBar+Req", data = 4, hover = "Same as IgnoreBarren, but world will generate again until all parts are placed."},
                        {description = "IgAll+Req", data = 5, hover = "Same as IgBar+Req but with IgnoreAll"}, -- usually IgnoreAll will be 100% gurantee, but not if modworldgenmain spawns them as story setpieces, which is only true for adventure mode
                    },
        default = 4,
    },
    {
        name = "spawnteleworld",
        label = "Which world",
        hover = "Should the parts spawn in forest or in cave or both? The base will always be in forest. Parts can be transferred between worlds.",
        options =   {
                        {description = "Forest", data = "forest", hover = ""},
                        {description = "Cave", data = "cave", hover = "Only the parts. Base is always at forest."},
                        {description = "Both", data = "forestcave", hover = "A full set of parts is spawned in both worlds, while base is only in forest"},
                    },
        default = "forest",
    },
    {
        name = "spawntelemoonisland",
        label = "Moon Island?",
        hover = "Should base/parts also spawn at moon island?",
        options =   {
                        {description = "No", data = false, hover = ""},
                        {description = "Yes", data = true, hover = "Also works for other -level_set_piece_blockers-! (currently only moonislands)"},
                    },
        default = true,
    },
}

