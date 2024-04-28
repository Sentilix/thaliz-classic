--[[
Author:			Mimma @ <EU-Pyrewood Village>
Create Date:	2015-05-10 17:50:57

The latest version of Thaliz can always be found at:
(tbd)

The source code can be found at Github:
https://github.com/Sentilix/thaliz-classic

Please see the ReadMe.txt for addon details.
]]


local addonMetadata = {
	["ADDONNAME"]		= "Thaliz",
	["SHORTNAME"]		= "THALIZ",
	["PREFIX"]			= "Thalizv1",
	["NORMALCHATCOLOR"]	= "40A0F8",
	["HOTCHATCOLOR"]	= "00F0F0",
};
local A = DigamAddonLib:new(addonMetadata);


local PARTY_CHANNEL							= "PARTY"
local RAID_CHANNEL							= "RAID"
local YELL_CHANNEL							= "YELL"
local SAY_CHANNEL							= "SAY"
local WARN_CHANNEL							= "RAID_WARNING"
local GUILD_CHANNEL							= "GUILD"
local THALIZ_MAX_MESSAGES					= 200
local THALIZ_MAX_VISIBLE_MESSAGES			= 20
local THALIZ_EMPTY_MESSAGE					= "(Empty)"

local THALIZ_CURRENT_VERSION				= 0
local THALIZ_UPDATE_MESSAGE_SHOWN			= false
local THALIZ_REZBUTTON_SIZE					= 32;

local EMOTE_GROUP_DEFAULT					= "Default";
local EMOTE_GROUP_GUILD						= "Guild";
local EMOTE_GROUP_CHARACTER					= "Name";
local EMOTE_GROUP_CLASS						= "Class";
local EMOTE_GROUP_RACE						= "Race";

--	List of valid class names with priority and resurrection spell name (if any)
--	classname, priority, spellname (translated runtime), spellID

local Thaliz_ClassMatrix = {
	["DEATHKNIGHT"] = {
		["class"] = "Death Knight",
		["priority"] = 20,
		["spellid"] = nil,
		["color"] = { 196, 30, 58 },
	},
	["DEMON HUNTER"] = {
		["class"] = "Demon Hunter",
		["priority"] = 30,
		["spellid"] = nil,
		["color"] = { 163, 48, 201 },
	},
	["DRUID"] = {
		["class"] = "Druid",
		["priority"] = 40,
		["spellid"] = 20747,		--50769,
		["color"] = { 255, 125, 10 },
	},
	["HUNTER"] = {
		["class"] = "Hunter",
		["priority"] = 30,
		["spellid"] = nil,
		["color"] = { 171, 212, 115 },
	},
	["MAGE"] = {
		["class"] = "Mage",
		["priority"] = 40,
		["spellid"] = nil,
		["color"] = { 105, 204, 240 },
	},
	["MONK"] = {
		["class"] = "Monk",
		["priority"] = 50,
		["spellid"] = 115178,
		["color"] = { 0, 255, 150 },
	},
	["PALADIN"] = {
		["class"] = "Paladin",
		["priority"] = 50,
		["spellid"] = 7328,
		["color"] = { 245, 140, 186 },
	},
	["PRIEST"] = {
		["class"] = "Priest",
		["priority"] = 50,
		["spellid"] = 2006,
		["color"] = { 255, 255, 255 },
	},
	["ROGUE"] = {
		["class"] = "Rogue",
		["priority"] = 10,
		["spellid"] = nil,
		["color"] = { 255, 245, 105 },
	},
	["SHAMAN"] = {
		["class"] = "Shaman",
		["priority"] = 50,
		["spellid"] = 2008,
		["color"] = { 0, 112, 221 },
	},
	["WARLOCK"] = {
		["class"] = "Warlock",
		["priority"] = 30,
		["spellid"] = nil,
		["color"] = { 148, 130, 201 },
	},
	["WARRIOR"] = {
		["class"] = "Warrior",
		["priority"] = 20,
		["spellid"] = nil,
		["color"] = { 199, 156, 110 },
	},
}


local Thaliz_classInfo = { }


--	Table: { Name, Sample, Pattern }
--	At runtime Sample ("%") is replaced with UnitName('Player').
--	Pattern is used when the macros are shown.
local THALIZ_NAME_ENCLOSURES = {
	{ "NONE",		"%s",		"%s"		},
	{ "BRACKET",	"[%s]",		"[%s]"		},
	{ "CURLY",		"{%s}",		"{%s}"		},
	{ "XMLTAG",		"<%s>",		"<%s>"		},
	{ "CENTER1",	">%s<",		">%s<"		},
	{ "CENTER2",	">>%s<<",	">>%s<<"	},
	{ "ARROW",		"-->%s",	"-->%s"		},
	{ "ATTENTION",	"!!%s!!",	"!!%s!!"	},
	{ "SINGLEQ",	"'%s'",		"'%s'"		},
	{ "DOUBLEQ",	'"%s"',		'"%s"'		}
}

local IsPaladin = false;
local IsPriest = false;
local IsShaman = false;
local IsDruid = false;
local IsMonk = false;
local IsResser = false;

local THALIZ_RezBtn_Passive			= "";
local THALIZ_RezBtn_Active			= "";
local THALIZ_RezBtn_Combat			= "Interface\\Icons\\Ability_dualwield";
local THALIZ_RezBtn_Dead			= "Interface\\Icons\\Ability_rogue_feigndeath";

local THALIZ_ICON_OTHER_PASSIVE		= "Interface\\Icons\\INV_Misc_Gear_01";
local THALIZ_ICON_DRUID_PASSIVE		= "Interface\\Icons\\INV_Misc_Monsterclaw_04";
local THALIZ_ICON_DRUID_ACTIVE		= "Interface\\Icons\\spell_holy_resurrection";
local THALIZ_ICON_MONK_PASSIVE		= "Interface\\Icons\\classicon_monk";
local THALIZ_ICON_MONK_ACTIVE		= "Interface\\Icons\\ability_druid_lunarguidance";
local THALIZ_ICON_PALADIN_PASSIVE	= "Interface\\Icons\\INV_Hammer_01";
local THALIZ_ICON_PALADIN_ACTIVE	= "Interface\\Icons\\spell_holy_resurrection";
local THALIZ_ICON_PRIEST_PASSIVE	= "Interface\\Icons\\INV_Staff_30";
local THALIZ_ICON_PRIEST_ACTIVE		= "Interface\\Icons\\spell_holy_resurrection";
local THALIZ_ICON_SHAMAN_PASSIVE	= "Interface\\Icons\\INV_Jewelry_Talisman_04";
local THALIZ_ICON_SHAMAN_ACTIVE		= "Interface\\Icons\\spell_holy_resurrection";


local PriorityToFirstWarlock  = 45;     -- Prio below ressers if no warlocks are alive
local PriorityToMasterLooter  = 60;     -- Prio above ressers if master looter
local PriorityToCurrentTarget = 100;	-- Prio over all if target i selected

-- List of blacklisted (already ressed) people
-- Table { PlayerName-RealmName, TimerTick }
local blacklistedTable = {}
-- Corpses are blacklisted for 40 seconds (10 seconds cast time + 30 seconds waiting) as default
local Thaliz_Blacklist_Spellcast = 10;
local Thaliz_Blacklist_Resurrect = 30;
local Thaliz_Blacklist_Timeout = Thaliz_Blacklist_Spellcast + Thaliz_Blacklist_Resurrect;

local Thaliz_LastRandomMessageIndex = -1;
local Thaliz_Enabled = true;
local ThalizConfigDialogOpen = false;
local ThalizDoScanRaid = true;
local ThalizScanFrequency = 0.2;		-- Scan 5 times per second
local Thaliz_ProfileTable = { };
local Thaliz_SelectedProfile = nil;

-- Configuration constants:
local Thaliz_Configuration_Default_Level				= "Character";	-- Can be "Character" or "Realm"
local Thaliz_Target_Channel_Default						= "RAID";
local Thaliz_Target_Whisper_Default						= "0";
local Thaliz_Resurrection_Whisper_Message_Default		= "Resurrection incoming in 10 seconds!";
local Thaliz_Include_Default_Group_Default				= "1";
local Thaliz_OPTION_RezButtonVisible_Default			= "1";

local Thaliz_ConfigurationLevel							= Thaliz_Configuration_Default_Level;

local Thaliz_ROOT_OPTION_CharacterBasedSettings			= "CharacterBasedSettings";
local Thaliz_OPTION_ResurrectionMessageTargetChannel	= "ResurrectionMessageTargetChannel";
local Thaliz_OPTION_ResurrectionMessageTargetWhisper	= "ResurrectionMessageTargetWhisper";
local Thaliz_OPTION_ResurrectionNameEnclosure			= "ResurrectionNameEnclosure";
local Thaliz_OPTION_AlwaysIncludeDefaultGroup			= "AlwaysIncludeDefaultGroup";
local Thaliz_OPTION_ResurrectionWhisperMessage			= "ResurrectionWhisperMessage";
local Thaliz_OPTION_ResurrectionMessages				= "ResurrectionMessages";
local Thaliz_OPTION_RezButtonPosX						= "RezButtonPosX";
local Thaliz_OPTION_RezButtonPosY						= "RezButtonPosY";
local Thaliz_OPTION_RezButtonVisible					= "ResurrectionButtonVisible";

local Thaliz_DebugFunction = nil;

-- Persisted information:
--	{realmname}{playername}{parameter}
Thaliz_Options = { }

-- First-time messages: use the DAD JOKES, beware! :-D
local Thaliz_DefaultPresetGroup							= 5;		


--[[
	Echo in raid chat (if in raid) or party chat (if not)
]]
local function partyEcho(msg)
	if IsInRaid() then
		SendChatMessage(msg, RAID_CHANNEL)
	elseif A:isInParty() then
		SendChatMessage(msg, PARTY_CHANNEL)
	end
end




--  *******************************************************
--
--	Slash commands
--
--  *******************************************************

--[[
	Main entry for Thaliz.
	This will send the request to one of the sub slash commands.
	Syntax: /thaliz [option, defaulting to "cfg"]
	Added in: 0.0.1
]]
SLASH_THALIZ_THALIZ1 = "/thaliz"
SlashCmdList["THALIZ_THALIZ"] = function(msg)
	local _, _, option = string.find(msg, "(%S*)")

	if not option or option == "" then
		option = "CFG"
	end
	option = string.upper(option);
		
	if (option == "CFG" or option == "CONFIG") then
		SlashCmdList["THALIZ_CONFIG"]();
	elseif option == "DISABLE" then
		SlashCmdList["THALIZ_DISABLE"]();
	elseif option == "ENABLE" then
		SlashCmdList["THALIZ_ENABLE"]();
	elseif option == "RESETBUTTON" then
		SlashCmdList["THALIZ_RESETBUTTON"]();
	elseif option == "HELP" then
		SlashCmdList["THALIZ_HELP"]();
	elseif option == "SHOW" then
		SlashCmdList["THALIZ_SHOW"]();
	elseif option == "HIDE" then
		SlashCmdList["THALIZ_HIDE"]();
	elseif option == "VERSION" then
		SlashCmdList["THALIZ_VERSION"]();
	else
		A:echo(string.format("Unknown command: %s", option));
	end
end

--[[
	Show the resurrection button
	Syntax: /thalizshow
	Alternative: /thaliz show
	Added in: 1.1.1
]]
SLASH_THALIZ_SHOW1 = "/thalizshow"	
SlashCmdList["THALIZ_SHOW"] = function(msg)
	RezButton:Show();
	Thaliz_SetOption(Thaliz_OPTION_RezButtonVisible, "1");
end


--[[
	Hide the resurrection button
	Syntax: /thalizhide
	Alternative: /thaliz hide
	Added in: 1.1.1
]]
SLASH_THALIZ_HIDE1 = "/thalizhide"	
SlashCmdList["THALIZ_HIDE"] = function(msg)
	RezButton:Hide();
	Thaliz_SetOption(Thaliz_OPTION_RezButtonVisible, "0");
end

--[[
	Request client version information
	Syntax: /thalizversion
	Alternative: /thaliz version
	Added in: 0.2.1
]]
SLASH_THALIZ_VERSION1 = "/thalizversion"
SlashCmdList["THALIZ_VERSION"] = function(msg)
	if IsInRaid() or A:isInParty() then
		A:sendAddonMessage("TX_VERSION##");
	else
		A:echo(string.format("%s is using Thaliz version %s", A.localPlayerName, A.addonVersion));
	end
end

--[[
	Show configuration options
	Syntax: /thalizconfig
	Alternative: /thaliz config
	Added in: 0.3.0
]]
SLASH_THALIZ_CONFIG1 = "/thalizconfig"
SLASH_THALIZ_CONFIG2 = "/thalizcfg"
SlashCmdList["THALIZ_CONFIG"] = function(msg)
	Thaliz_OpenConfigurationDialogue();
end

--[[
	Disable Thaliz' messages
	Syntax: /thaliz disable
	Added in: 0.3.2
]]
SLASH_THALIZ_DISABLE1 = "/thalizdisable"
SlashCmdList["THALIZ_DISABLE"] = function(msg)
	Thaliz_Enabled = false;
	A:echo("Resurrection announcements has been disabled.");
end

--[[
	Enable Thaliz' messages
	Syntax: /thaliz enable
	Added in: 0.3.2
]]
SLASH_THALIZ_ENABLE1 = "/thalizenable"
SlashCmdList["THALIZ_ENABLE"] = function(msg)
	Thaliz_Enabled = true;
	A:echo("Resurrection announcements has been enabled.");
end

--[[
	Enable Thaliz' messages
	Syntax: /thaliz resetbutton
	Added in: 3.1.3
]]
SLASH_THALIZ_RESETBUTTON1 = "/thalizresetbutton"
SlashCmdList["THALIZ_RESETBUTTON"] = function(msg)

	RezButton:ClearAllPoints();
	RezButton:SetPoint("CENTER", "UIParent", "CENTER", 0, 0);
	RezButton:SetSize(THALIZ_REZBUTTON_SIZE, THALIZ_REZBUTTON_SIZE);

	if Thaliz_OPTION_RezButtonVisible_Default == "1" then
		RezButton:Show();
	end;

	Thaliz_SetOption(Thaliz_OPTION_RezButtonPosX, 0);
	Thaliz_SetOption(Thaliz_OPTION_RezButtonPosY, 0);

	A:echo("The Resurrection button has been reset.");
end





--[[
	Set DEBUG level for Thaliz.
	Syntax: /thaliz debug <method>
	Added in: classic-0.2.1
]]
SLASH_THALIZ_DEBUG1 = "/thalizdebug"
SlashCmdList["THALIZ_DEBUG"] = function(msg)
	local _, _, dbgfunc = string.find(msg, "(%S*)");

	if dbgfunc and dbgfunc ~= '' then
		A:echo(string.format("Enabling debug for %s", dbgfunc));
		ThalizScanFrequency = 1.0;
		Thaliz_DebugFunction = dbgfunc;
	else
		A:echo("Disabling debug");
		ThalizScanFrequency = 0.2;
		Thaliz_DebugFunction = nil;
	end;
end



--[[
	Show HELP options
	Syntax: /thalizhelp
	Alternative: /thaliz help
	Added in: 0.2.0
]]
SLASH_THALIZ_HELP1 = "/thalizhelp"
SlashCmdList["THALIZ_HELP"] = function(msg)
	A:echo(string.format("Thaliz version %s options:", A.addonVersion));
	A:echo("Syntax:");
	A:echo("    /thaliz [option]");
	A:echo("Where options can be:");
	A:echo("    Config       (default) Open the configuration dialogue,");
	A:echo("    Disable      Disable Thaliz resurrection messages.");
	A:echo("    Enable       Enable Thaliz resurrection messages again.");
	A:echo("    ResetButton  Resets the position of the Rez Button.");
	A:echo("    Help         This help.");
	A:echo("    Show         Shows the resurrection button.");
	A:echo("    Hide         Hides the resurrection button.");
	A:echo("    Version      Request version info from all clients.");
end



--  *******************************************************
--
--	Configuration functions
--
--  *******************************************************

function Thaliz_ToggleConfigurationDialogue()
	if ThalizConfigDialogOpen then
		Thaliz_CloseButton_OnClick();
	else
		Thaliz_OpenConfigurationDialogue();
	end;
end

function Thaliz_OpenConfigurationDialogue()
	local whisperMsg = Thaliz_GetOption(Thaliz_OPTION_ResurrectionWhisperMessage);

	if not whisperMsg then whisperMsg = ""; end;

	ThalizFrameWhisper:SetText(whisperMsg);
	ThalizFrameWhisper:SetAutoFocus(false);
	ThalizConfigDialogOpen = true;
	ThalizFrame:Show();
end

function Thaliz_CloseConfigurationDialogue()
	Thaliz_CloseMsgEditorButton_OnClick();
	Thaliz_CloseProfileButton_OnClick();
	Thaliz_ClosePresetButton_OnClick();

	ThalizConfigDialogOpen = false;
	ThalizFrame:Hide();
end


function Thaliz_RefreshVisibleMessageList(offset)
--	echo(string.format("Thaliz_RefreshVisibleMessageList: Offset=%d", offset));
	local macros = Thaliz_GetResurrectionMessages();
	
	-- Set a priority on each spell, and then sort them accordingly:
	local macro, msg, grp, prm, prio
	for n=1, table.getn(macros), 1 do
		msg = macros[n][1];
		grp = macros[n][2];
		prm = macros[n][3];

		if msg == THALIZ_EMPTY_MESSAGE or msg == "" then
			prio = -1
		elseif grp == EMOTE_GROUP_GUILD then
			prio = 20
		elseif grp == EMOTE_GROUP_CHARACTER then
			prio = 30
		elseif grp == EMOTE_GROUP_RACE then
			prio = 100
			-- Racess are listed by race name:
			if prm == "Blood Elf" then
				prio = 101
			elseif prm == "Dark Iron Dwarf" then
				prio = 102
			elseif prm == "Draenei" then
				prio = 103
			elseif prm == "Dwarf" then
				prio = 104
			elseif prm == "Gnome" then
				prio = 105
			elseif prm == "Goblin" then
				prio = 106
			elseif prm == "Highmountain Tauren" then
				prio = 107
			elseif prm == "Human" then
				prio = 108
			elseif prm == "Kul Tiran" then
				prio = 109
			elseif prm == "Lightforged Draenei" then
				prio = 110
			elseif prm == "Mag'har Orc" then
				prio = 111
			elseif prm == "Mechagnome" then
				prio = 112
			elseif prm == "Nightborne" then
				prio = 113
			elseif prm == "Night Elf" then
				prio = 114
			elseif prm == "Orc" then
				prio = 115
			elseif prm == "Pandaren" then
				prio = 116
			elseif prm == "Tauren" then
				prio = 117
			elseif prm == "Troll" then
				prio = 118
			elseif prm == "Undead" then
				prio = 119
			elseif prm == "Void Elf" then
				prio = 120
			elseif prm == "Vulpera" then
				prio = 121
			elseif prm == "Worgen" then
				prio = 122
			elseif prm == "Zandalari Troll" then
				prio = 123
			end;			
		elseif grp == EMOTE_GROUP_CLASS then
			-- Class names are listed alphabetically:
			prio = 200
			if prm == "Death Knight" then
				prio = 212
			elseif prm == "Demon Hunter" then
				prio = 211
			elseif prm == "Druid" then
				prio = 210
			elseif prm == "Hunter" then
				prio = 209
			elseif prm == "Mage" then
				prio = 208
			elseif prm == "Monk" then
				prio = 207
			elseif prm == "Paladin" then
				prio = 206
			elseif prm == "Priest" then
				prio = 205
			elseif prm == "Rogue" then
				prio = 204
			elseif prm == "Shaman" then
				prio = 203
			elseif prm == "Warlock" then
				prio = 202
			elseif prm == "Warrior" then
				prio = 201
			end;			
		elseif grp == EMOTE_GROUP_DEFAULT then
			prio = 0
		end

		macros[n][4] = prio;		
	end
	
	Thaliz_SortTableDescending(macros, 4);
	
	for n=1, THALIZ_MAX_VISIBLE_MESSAGES, 1 do
		macro = macros[n + offset]
		if not macro then
			macro = { "", EMOTE_GROUP_DEFAULT, "" }
		end
		
		local msg = Thaliz_CheckMessage(macro[1]);
		local grp = Thaliz_CheckGroup(macro[2]);
		local prm = Thaliz_CheckGroupValue(macro[3]);
		
		--echo(string.format("-> Msg=%s, Grp=%s, Value=%s", msg, grp, prm));
		
		local frame = _G["ThalizFrameTableListEntry"..n];
		if(not frame) then
			echo("*** Oops, frame is nil");
			return;
		end;

		_G[frame:GetName().."Message"]:SetText(msg);
		_G[frame:GetName().."Group"]:SetText(grp);
		_G[frame:GetName().."Param"]:SetText(prm);
		
		local grpColor = { 0.5, 0.5, 0.5 }
		local prmColor = { 0.5, 0.5, 0.5 }
		
		prm = string.upper(prm);
		
		if grp == EMOTE_GROUP_GUILD then
			grpColor = { 0.0, 1.0, 0.0 }
			prmColor = { 0.8, 0.8, 0.0 }
		elseif grp == EMOTE_GROUP_CHARACTER then
			grpColor = { 0.8, 0.8, 0.8 }
			prmColor = { 0.8, 0.8, 0.0 }
		elseif grp == EMOTE_GROUP_CLASS then
			grpColor = { 0.8, 0.0, 1.0 }

			local classinfo = Thaliz_ClassMatrix[prm];
			if classinfo then
				prmColor = { classinfo["color"][1] / 255, classinfo["color"][2] / 255, classinfo["color"][3] / 255 };
			end;
		elseif grp == EMOTE_GROUP_RACE then
			grpColor = { 0.80, 0.80, 0.00 }			
			if prm == "DWARF" or prm == "GNOME" or prm == "HUMAN" or prm == "NIGHT ELF" or prm == "DRAENAI" then
				grpColor = { 0.00, 0.50, 1.00 }
			elseif prm == "ORC" or prm == "TAUREN" or prm == "TROLL" or prm == "UNDEAD" or prm == "BLOOD ELF" then
				grpColor = { 1.00, 0.00, 0.00 }
			end
			prmColor = grpColor;
		end;
		
		_G[frame:GetName().."Group"]:SetTextColor(grpColor[1], grpColor[2], grpColor[3]);
		_G[frame:GetName().."Param"]:SetTextColor(prmColor[1], prmColor[2], prmColor[3]);
		
		frame:Show();
	end
end

function Thaliz_UpdateMessageList()
	FauxScrollFrame_Update(ThalizFrameTableList, THALIZ_MAX_MESSAGES, 10, 20);
	local offset = FauxScrollFrame_GetOffset(ThalizFrameTableList);
	
	Thaliz_RefreshVisibleMessageList(offset);
end

function Thaliz_InitializeListElements()
	local entry = CreateFrame("Button", "$parentEntry1", ThalizFrameTableList, "Thaliz_CellTemplate");
	entry:SetID(1);
	entry:SetPoint("TOPLEFT", 4, -4);
	for n=2, THALIZ_MAX_MESSAGES, 1 do
		local entry = CreateFrame("Button", "$parentEntry"..n, ThalizFrameTableList, "Thaliz_CellTemplate");
		entry:SetID(n);
		entry:SetPoint("TOP", "$parentEntry"..(n-1), "BOTTOM");
	end
end

local currentObjectId;	-- A small hack: the object ID is lost when using own frame
local msgEditorIsOpen;
local profileFrameIsOpen;
local presetFrameIsOpen;
function Thaliz_OnMessageClick(object)
	Thaliz_CloseMsgEditorButton_OnClick();

	currentObjectId = object:GetID();
	local offset = FauxScrollFrame_GetOffset(ThalizFrameTableList);
		
	local msg = _G[object:GetName().."Message"]:GetText();
	local grp = _G[object:GetName().."Group"]:GetText();
	local prm = _G[object:GetName().."Param"]:GetText();
	if not msg or msg == THALIZ_EMPTY_MESSAGE then
		msg = "";
	end
	
	grp = Thaliz_CheckGroup(grp);
	prm = Thaliz_CheckGroupValue(prm);

	local frame = _G["ThalizMsgEditorFrame"];
	_G[frame:GetName().."Message"]:SetText(msg);
	_G[frame:GetName().."GroupValue"]:SetText(prm);

	_G[frame:GetName().."CheckbuttonAlways"]:SetChecked();		
	_G[frame:GetName().."CheckbuttonGuild"]:SetChecked();		
	_G[frame:GetName().."CheckbuttonCharacter"]:SetChecked();		
	_G[frame:GetName().."CheckbuttonClass"]:SetChecked();		
	_G[frame:GetName().."CheckbuttonRace"]:SetChecked();		

	if grp == EMOTE_GROUP_GUILD then
		_G[frame:GetName().."CheckbuttonGuild"]:SetChecked(1);		
	elseif grp == EMOTE_GROUP_CHARACTER then
		_G[frame:GetName().."CheckbuttonCharacter"]:SetChecked(1);		
	elseif grp == EMOTE_GROUP_CLASS then
		_G[frame:GetName().."CheckbuttonClass"]:SetChecked(1);		
	elseif grp == EMOTE_GROUP_RACE then
		_G[frame:GetName().."CheckbuttonRace"]:SetChecked(1);		
	else
		_G[frame:GetName().."CheckbuttonAlways"]:SetChecked(1);
	end
	
	msgEditorIsOpen = true;
	ThalizMsgEditorFrame:Show();
	ThalizMsgEditorFrameMessage:SetFocus();
end


function Thaliz_SaveMessageButton_OnClick()
	local msg = ThalizMsgEditorFrameMessage:GetText();
	local prm = ThalizMsgEditorFrameGroupValue:GetText();
	local grp;
	local offset = FauxScrollFrame_GetOffset(ThalizFrameTableList);

	if ThalizMsgEditorFrameCheckbuttonGuild:GetChecked() then
		grp = EMOTE_GROUP_GUILD;
	elseif ThalizMsgEditorFrameCheckbuttonCharacter:GetChecked() then
		grp = EMOTE_GROUP_CHARACTER;
	elseif ThalizMsgEditorFrameCheckbuttonClass:GetChecked() then
		grp = EMOTE_GROUP_CLASS;
	elseif ThalizMsgEditorFrameCheckbuttonRace:GetChecked() then
		grp = EMOTE_GROUP_RACE;
	else
		grp = EMOTE_GROUP_DEFAULT;
	end;

	if	grp == EMOTE_GROUP_CHARACTER or 
		grp == EMOTE_GROUP_CLASS then
		prm = Thaliz_UCFirst(prm)
	elseif grp == EMOTE_GROUP_RACE then
		-- Allow both "nightelf" and "night elf".
		-- This weird construction ensures all are shown with capital first letter.
		if string.upper(prm) == "NIGHTELF" or string.upper(prm) == "NIGHT ELF" then
			prm = "Night Elf"
		elseif string.upper(prm) == "BLOODELF" or string.upper(prm) == "BLOOD ELF" then
			prm = "Blood Elf"
		else
			prm = Thaliz_UCFirst(prm)
		end;
	end

	Thaliz_CloseMsgEditorButton_OnClick();	
	Thaliz_UpdateResurrectionMessage(currentObjectId, offset, msg, grp, prm);
	Thaliz_UpdateMessageList();
end


function Thaliz_HandleCheckbox(checkbox)
	local checkboxname = checkbox:GetName();

	--	If checked, then we need to uncheck others in same group:
	if checkboxname == "ThalizFrameCheckbuttonRaid" or checkboxname == "ThalizFrameCheckbuttonYell" or checkboxname == "ThalizFrameCheckbuttonSay" then	
		if checkbox:GetChecked() then
			if checkboxname == "ThalizFrameCheckbuttonRaid" then
				Thaliz_SetOption(Thaliz_OPTION_ResurrectionMessageTargetChannel, "RAID");
				ThalizFrameCheckbuttonSay:SetChecked();
				ThalizFrameCheckbuttonYell:SetChecked();
			elseif checkboxname == "ThalizFrameCheckbuttonYell" then
				Thaliz_SetOption(Thaliz_OPTION_ResurrectionMessageTargetChannel, "YELL");
				ThalizFrameCheckbuttonSay:SetChecked();
				ThalizFrameCheckbuttonRaid:SetChecked();
			elseif checkboxname == "ThalizFrameCheckbuttonSay" then
				Thaliz_SetOption(Thaliz_OPTION_ResurrectionMessageTargetChannel, "SAY");
				ThalizFrameCheckbuttonRaid:SetChecked();
				ThalizFrameCheckbuttonYell:SetChecked();
			end
		else
			Thaliz_SetOption(Thaliz_OPTION_ResurrectionMessageTargetChannel, "NONE");
			ThalizFrameCheckbuttonRaid:SetChecked();
			ThalizFrameCheckbuttonSay:SetChecked();
			ThalizFrameCheckbuttonYell:SetChecked();
		end
	end

	-- "single" checkboxes (checkboxes with no impact on other checkboxes):
	if ThalizFrameCheckbuttonWhisper:GetChecked() then
		Thaliz_SetOption(Thaliz_OPTION_ResurrectionMessageTargetWhisper, 1);
	else
		Thaliz_SetOption(Thaliz_OPTION_ResurrectionMessageTargetWhisper, 0);
	end	
	
	if ThalizFrameCheckbuttonIncludeDefault:GetChecked() then
		Thaliz_SetOption(Thaliz_OPTION_AlwaysIncludeDefaultGroup, 1);
	else
		Thaliz_SetOption(Thaliz_OPTION_AlwaysIncludeDefaultGroup, 0);
	end	
		
	if ThalizFrameCheckbuttonPerCharacter:GetChecked() then
		Thaliz_SetRootOption(Thaliz_ROOT_OPTION_CharacterBasedSettings, "Character");
	else
		Thaliz_SetRootOption(Thaliz_ROOT_OPTION_CharacterBasedSettings, "Realm");
	end	
	
	-- Emote Groups: Only one can be active:
	if checkboxname == "ThalizMsgEditorFrameCheckbuttonAlways" then	
		if checkbox:GetChecked() then
			ThalizMsgEditorFrameCheckbuttonGuild:SetChecked();
			ThalizMsgEditorFrameCheckbuttonCharacter:SetChecked();
			ThalizMsgEditorFrameCheckbuttonClass:SetChecked();
			ThalizMsgEditorFrameCheckbuttonRace:SetChecked();
		end;
	elseif checkboxname == "ThalizMsgEditorFrameCheckbuttonGuild" then	
		if checkbox:GetChecked() then
			ThalizMsgEditorFrameCheckbuttonAlways:SetChecked();
			ThalizMsgEditorFrameCheckbuttonCharacter:SetChecked();
			ThalizMsgEditorFrameCheckbuttonClass:SetChecked();
			ThalizMsgEditorFrameCheckbuttonRace:SetChecked();
		end;
	elseif checkboxname == "ThalizMsgEditorFrameCheckbuttonCharacter" then	
		if checkbox:GetChecked() then
			ThalizMsgEditorFrameCheckbuttonAlways:SetChecked();
			ThalizMsgEditorFrameCheckbuttonGuild:SetChecked();
			ThalizMsgEditorFrameCheckbuttonClass:SetChecked();
			ThalizMsgEditorFrameCheckbuttonRace:SetChecked();
		end;
	elseif checkboxname == "ThalizMsgEditorFrameCheckbuttonClass" then	
		if checkbox:GetChecked() then
			ThalizMsgEditorFrameCheckbuttonAlways:SetChecked();
			ThalizMsgEditorFrameCheckbuttonGuild:SetChecked();
			ThalizMsgEditorFrameCheckbuttonCharacter:SetChecked();
			ThalizMsgEditorFrameCheckbuttonRace:SetChecked();
		end;
	elseif checkboxname == "ThalizMsgEditorFrameCheckbuttonRace" then	
		if checkbox:GetChecked() then
			ThalizMsgEditorFrameCheckbuttonAlways:SetChecked();
			ThalizMsgEditorFrameCheckbuttonGuild:SetChecked();
			ThalizMsgEditorFrameCheckbuttonCharacter:SetChecked();
			ThalizMsgEditorFrameCheckbuttonClass:SetChecked();
		end;
	end;
end

function Thaliz_GetRootOption(parameter, defaultValue)
	if Thaliz_Options then
		if Thaliz_Options[parameter] then
			local value = Thaliz_Options[parameter];
			if (type(value) == "table") or not(value == "") then
				return value;
			end
		end		
	end
	
	return defaultValue;
end

function Thaliz_SetRootOption(parameter, value)
	if not Thaliz_Options then
		Thaliz_Options = {};
	end
	
	Thaliz_Options[parameter] = value;
end

function Thaliz_GetOption(parameter, defaultValue)
	local realmname = GetRealmName();
	local playername = UnitName("player");

	if Thaliz_ConfigurationLevel == "Character" then
		-- Character level
		if Thaliz_Options[realmname] then
			if Thaliz_Options[realmname][playername] then
				if Thaliz_Options[realmname][playername][parameter] then
					local value = Thaliz_Options[realmname][playername][parameter];
					if (type(value) == "table") or not(value == "") then
						return value;
					end
				end		
			end
		end
	else
		-- Realm level:
		if Thaliz_Options[realmname] then
			if Thaliz_Options[realmname][parameter] then
				local value = Thaliz_Options[realmname][parameter];
				if (type(value) == "table") or not(value == "") then
					return value;
				end
			end		
		end
	end
	
	return defaultValue;
end

function Thaliz_SetOption(parameter, value)
	local realmname = GetRealmName();
	local playername = UnitName("player");

	if Thaliz_ConfigurationLevel == "Character" then
		-- Character level:
		if not Thaliz_Options[realmname] then
			Thaliz_Options[realmname] = {};
		end
		
		if not Thaliz_Options[realmname][playername] then
			Thaliz_Options[realmname][playername] = {};
		end
		
		Thaliz_Options[realmname][playername][parameter] = value;		
	else
		-- Realm level:
		if not Thaliz_Options[realmname] then
			Thaliz_Options[realmname] = {};
		end	
		
		Thaliz_Options[realmname][parameter] = value;
	end
end

function Thaliz_InitializeConfigSettings()
	if not Thaliz_Options then
		Thaliz_Options = { };
	end

	Thaliz_SetRootOption(Thaliz_ROOT_OPTION_CharacterBasedSettings, Thaliz_GetRootOption(Thaliz_ROOT_OPTION_CharacterBasedSettings, Thaliz_Configuration_Default_Level))
	Thaliz_ConfigurationLevel = Thaliz_GetRootOption(Thaliz_ROOT_OPTION_CharacterBasedSettings, Thaliz_Configuration_Default_Level);
	
	Thaliz_SetOption(Thaliz_OPTION_ResurrectionMessageTargetChannel, Thaliz_GetOption(Thaliz_OPTION_ResurrectionMessageTargetChannel, Thaliz_Target_Channel_Default))
	Thaliz_SetOption(Thaliz_OPTION_ResurrectionMessageTargetWhisper, Thaliz_GetOption(Thaliz_OPTION_ResurrectionMessageTargetWhisper, Thaliz_Target_Whisper_Default))
	Thaliz_SetOption(Thaliz_OPTION_ResurrectionWhisperMessage, Thaliz_GetOption(Thaliz_OPTION_ResurrectionWhisperMessage, Thaliz_Resurrection_Whisper_Message_Default))
	Thaliz_SetOption(Thaliz_OPTION_AlwaysIncludeDefaultGroup, Thaliz_GetOption(Thaliz_OPTION_AlwaysIncludeDefaultGroup, Thaliz_Include_Default_Group_Default))

	Thaliz_SetOption(Thaliz_OPTION_RezButtonVisible, Thaliz_GetOption(Thaliz_OPTION_RezButtonVisible, Thaliz_OPTION_RezButtonVisible_Default))

	Thaliz_SetOption(Thaliz_OPTION_ResurrectionNameEnclosure, Thaliz_GetOption(Thaliz_OPTION_ResurrectionNameEnclosure, "NONE"));
	Thaliz_InitializeNameEnclosures();


	local x,y = RezButton:GetPoint();
	Thaliz_SetOption(Thaliz_OPTION_RezButtonPosX, Thaliz_GetOption(Thaliz_OPTION_RezButtonPosX, x))
	Thaliz_SetOption(Thaliz_OPTION_RezButtonPosY, Thaliz_GetOption(Thaliz_OPTION_RezButtonPosY, y))

	if Thaliz_GetOption(Thaliz_OPTION_ResurrectionMessageTargetChannel) == "RAID" then
		ThalizFrameCheckbuttonRaid:SetChecked(1)
	end
	if Thaliz_GetOption(Thaliz_OPTION_ResurrectionMessageTargetChannel) == "SAY" then
		ThalizFrameCheckbuttonSay:SetChecked(1)
	end
	if Thaliz_GetOption(Thaliz_OPTION_ResurrectionMessageTargetChannel) == "YELL" then
		ThalizFrameCheckbuttonYell:SetChecked(1)
	end
	if Thaliz_GetOption(Thaliz_OPTION_ResurrectionMessageTargetWhisper) == 1 then
		ThalizFrameCheckbuttonWhisper:SetChecked(1)
	end
	if Thaliz_GetOption(Thaliz_OPTION_AlwaysIncludeDefaultGroup) == 1 then
		ThalizFrameCheckbuttonIncludeDefault:SetChecked(1)
	end
	if Thaliz_GetRootOption(Thaliz_ROOT_OPTION_CharacterBasedSettings) == "Character" then
		ThalizFrameCheckbuttonPerCharacter:SetChecked(1)
	end    
	if Thaliz_GetOption(Thaliz_OPTION_RezButtonVisible) == "1" then
		RezButton:Show();
	else
		RezButton:Hide()
	end
	
	Thaliz_ParseProfileNames();

	Thaliz_ValidateResurrectionMessages();
end

function Thaliz_ValidateResurrectionMessages()
	local macros = Thaliz_GetResurrectionMessages();
	local changed = False;
	
	for n=1, table.getn( macros ), 1 do
		local macro = macros[n];
		
		if type(macro) == "table" then
			-- Macro is fine; do nothing
		else
			-- Macro is ... hmmm beyond repair?; reset it:
			macros[n] = { "", EMOTE_GROUP_DEFAULT, "" }
			changed = True;
		end
	end;

	if changed then	
		Thaliz_SetResurrectionMessages(macros);	
	end;
end;

function Thaliz_ParseProfileNames()
	Thaliz_ProfileTable = { };

	for realmName, realmInfo in next, Thaliz_Options do
		if type(realmInfo) == "table" then
			for playerName, playerInfo in next, realmInfo do
				if type(playerInfo) == "table" then
					local messages = playerInfo["ResurrectionMessages"];
					if messages and type(messages) == "table" and table.getn(messages) > 0 then	
						local playerRealm = playerName .."-".. string.gsub(realmName, " ", "");

						tinsert(Thaliz_ProfileTable, { ["realm"] = realmName, ["name"] = playerName, ["count"] = table.getn(messages), ["fullname"] = playerRealm });
					end;
				end
			end;
		end;
	end;
end;



--[[
	Convert a msg so first letter is uppercase, and rest as lower case.
]]
function Thaliz_UCFirst(playername)
	if not playername then
		return ""
	end	

	-- Handles utf8 characters in beginning.. Ugly, but works:
	local offset = 2;
	local firstletter = string.sub(playername, 1, 1);
	if(not string.find(firstletter, '[a-zA-Z]')) then
		firstletter = string.sub(playername, 1, 2);
		offset = 3;
	end;

	return string.upper(firstletter) .. string.lower(string.sub(playername, offset));
end


--  *******************************************************
--
--	Resurrect message functions
--
--  *******************************************************
function Thaliz_AnnounceResurrection(playername, unitid)

	if not Thaliz_Enabled then
		return;
	end

	playername = A:getFullPlayerName(playername);

	if not unitid then
		unitid = A:getUnitidFromName(playername);
		if not unitid then
			return;
		end
	end

	local playershortname = Thaliz_StripRealmName(playername);
	local guildname = GetGuildInfo(unitid);
	local race = string.upper(UnitRace(unitid));
	local class = A:unitClass(unitid);
	local charname = string.upper(playershortname);

	if guildname then
		UCGuildname = string.upper(guildname);
	else
		-- Note: guildname is unfortunately not detected for released corpses.
		guildname = "(No Guild)";
		UCGuildname = "";
	end;	

	-- This is a list of ALL messages.
	-- Now identify the macros suitable for this player only:
	local dmacro = { }		-- Default macros
	local gmacro = { }		-- Guild macros
	local nmacro = { }		-- character Name macros
	local cmacro = { }		-- Class macros
	local rmacro = { }		-- Race macros
	
	local didx = 0;
	local gidx = 0;
	local nidx = 0;
	local cidx = 0;
	local ridx = 0;
	
	local macros = Thaliz_GetResurrectionMessages();
	for n=1, table.getn( macros ), 1 do
		local macro = macros[n];
		local param = "";
		if macro[3] then
			param = string.upper(macro[3]);
		end
		
		if macro[2] == EMOTE_GROUP_DEFAULT then
			didx = didx + 1;
			dmacro[ didx ] = macro;
		elseif macro[2] == EMOTE_GROUP_GUILD then
			if param == UCGuildname then
				gidx = gidx + 1;
				gmacro[ gidx ] = macro;
			end
		elseif macro[2] == EMOTE_GROUP_CHARACTER then
			if param == charname then
				nidx = nidx + 1;
				nmacro[ nidx ] = macro;
			end
		elseif macro[2] == EMOTE_GROUP_CLASS then
			if param == class then
				cidx = cidx + 1;
				cmacro[ cidx ] = macro;
			end
		elseif macro[2] == EMOTE_GROUP_RACE then
			if param == race then
				ridx = ridx + 1;
				rmacro[ ridx ] = macro;
			end
		end;		
	end
	
	-- Now generate list, using the found criterias above:
	local macros = { }
	local index = 0;
	for n=1, table.getn( gmacro ), 1 do
		index = index + 1;
		macros[index] = gmacro[n];
	end
	for n=1, table.getn( nmacro ), 1 do
		index = index + 1;
		macros[index] = nmacro[n];
	end
	for n=1, table.getn( cmacro ), 1 do
		index = index + 1;
		macros[index] = cmacro[n];
	end
	for n=1, table.getn( rmacro ), 1 do
		index = index + 1;
		macros[index] = rmacro[n];
	end;
	

	-- Include the default macro list if
	-- * No macros matching group rules, or
	-- * The "Include Default" option is selected.
	if table.getn(macros) == 0 or 
		Thaliz_GetOption(Thaliz_OPTION_AlwaysIncludeDefaultGroup) == 1 then
		for n=1, table.getn( dmacro ), 1 do
			index = index + 1;
			macros[index] = dmacro[n];
		end;
	end;

	
	local validMessages = {}
	local validCount = 0;
	for n=1, table.getn( macros ), 1 do
		local msg = macros[n][1];
		if msg and not (msg == "") then
			validCount = validCount + 1;
			validMessages[ validCount ] = msg;
		end
	end
	
	-- Fallback message if none are configured
	if validCount == 0 then
		validMessages[1] = "Resurrecting %s";
		validCount = 1;
	end

	-- Check player name enclosure:
	local enclosure = Thaliz_GetNameEnclosure(Thaliz_GetOption(Thaliz_OPTION_ResurrectionNameEnclosure, "NONE"));
	if enclosure then
		playershortname = string.format(enclosure[3], playershortname);
	end;


	--	This prevents the same message being shown twice:
	local randomMsgIndex = random(validCount);
	if randomMsgIndex == Thaliz_LastRandomMessageIndex then
		randomMsgIndex = randomMsgIndex + 1;
		if randomMsgIndex > validCount then
			randomMsgIndex = 1;
		end;
	end;
	Thaliz_LastRandomMessageIndex = randomMsgIndex;

	local message = validMessages[ randomMsgIndex ];

	--	%m (male/female specific message):
	--	Syntax: "%m{male text:female text}"
	if UnitSex(unitid) == 2 then
		--	(male) Use first string
		message = string.gsub(message, "%%m\{([^:^}]*):?([^}]*)\}", "%1");
	else
		--	(female) Use second string
		message = string.gsub(message, "%%m\{([^:^}]*):?([^}]*)\}", "%2");
	end;

	message = string.gsub(message, "%%c", Thaliz_UCFirst(class));
	message = string.gsub(message, "%%r", Thaliz_UCFirst(race));
	message = string.gsub(message, "%%g", guildname);
	message = string.gsub(message, "%%s", playershortname);

	local targetChannel = Thaliz_GetOption(Thaliz_OPTION_ResurrectionMessageTargetChannel);

	if not IsInInstance() then
		if targetChannel == "SAY" or targetChannel == "YELL" then
			targetChannel = "RAID";
		end;
	end;
	
	if targetChannel == "RAID" then
		partyEcho(message);
	elseif targetChannel == "SAY" then
		SendChatMessage(message, SAY_CHANNEL)
	elseif targetChannel == "YELL" then
		SendChatMessage(message, YELL_CHANNEL)
	else
		echo(message);
	end
	

	if Thaliz_GetOption(Thaliz_OPTION_ResurrectionMessageTargetWhisper) == 1 then
		local whisperMsg = Thaliz_GetOption(Thaliz_OPTION_ResurrectionWhisperMessage);
		if whisperMsg and not(whisperMsg == "") then
			SendChatMessage(whisperMsg, "WHISPER", nil, playername);
		end;
	end
end

function Thaliz_GetResurrectionMessages()
	local messages = Thaliz_GetOption(Thaliz_OPTION_ResurrectionMessages, nil);

	if (not messages) or not(type(messages) == "table") or (table.getn(messages) == 0) then
		messages = Thaliz_ResetResurrectionMessages(); 
	end
	
	return messages;
end

function Thaliz_RenumberTable(sourcetable)
	local index = 1;
	local temptable = { };
	
	for key, value in next, sourcetable do
		temptable[index] = value;
		index = index + 1
	end
	return temptable;
end

function Thaliz_SetResurrectionMessages(resurrectionMessages)
	Thaliz_SetOption(Thaliz_OPTION_ResurrectionMessages, Thaliz_RenumberTable(resurrectionMessages));
end

function Thaliz_ResetResurrectionMessages()
	local preset = Thaliz_PresetMessages[Thaliz_DefaultPresetGroup];

	local presetMessages = preset["messages"];
	if not presetMessages or type(presetMessages) ~= "table" then return; end;

	local resurrectionMessages = { };
	for _, message in next, presetMessages do
		tinsert(resurrectionMessages, { message, EMOTE_GROUP_DEFAULT, "" });
	end;

	Thaliz_SetResurrectionMessages(resurrectionMessages);
	Thaliz_UpdateMessageList();
	
	return resurrectionMessages;
end

function Thaliz_AddResurrectionMessage(message, group, param)
	if message and not (message == "") then
		group = Thaliz_CheckGroup(group);
		param = Thaliz_CheckGroupValue(param);

		local resMsgs = Thaliz_GetResurrectionMessages();		
		resMsgs[ table.getn(resMsgs) + 1] = { message, group, param }
		
		Thaliz_SetResurrectionMessages(resMsgs);
	end
end

function Thaliz_CheckMessage(msg)
	if not msg or msg == "" then
		msg = THALIZ_EMPTY_MESSAGE;
	end
	return msg;
end

function Thaliz_CheckGroup(group)
	if not group or group == "" then
		group = EMOTE_GROUP_DEFAULT;
	end
	return group;
end

function Thaliz_CheckGroupValue(param)
	if not param then
		param = "";
	end
	return param;
end

function Thaliz_UpdateResurrectionMessage(index, offset, message, group, param)
	group = Thaliz_CheckGroup(group);
	param = Thaliz_CheckGroupValue(param);

	local messages = Thaliz_GetResurrectionMessages();
	messages[index + offset] = { message, group, param }
	
	Thaliz_SetResurrectionMessages( messages );

	--	Update the frame UI:
	local frame = _G["ThalizFrameTableListEntry"..index];
	if not message or message == "" then
		message = THALIZ_EMPTY_MESSAGE;
	end
	_G[frame:GetName().."Message"]:SetText(message);
	_G[frame:GetName().."Param"]:SetText(param);
end



--  *******************************************************
--
--	Ressing functions
--
--  *******************************************************

--[[
Scan the entire raid / group for corpses, and activate
ress button if anyone found.
--]]
function Thaliz_ScanRaid()
	local debug = (Thaliz_DebugFunction and Thaliz_DebugFunction == "Thaliz_ScanRaid");

	if not ThalizDoScanRaid then 
		Thaliz_SetRezTargetText();
		if(debug) then 
			echo("**DEBUG**: ThalizDoScanRaid=false");
		end;
		return;
	end;

	--	Jesus, this class can't even ress!! Disable event
	if not IsResser then
		ThalizDoScanRaid = false;
		Thaliz_HideResurrectionButton();

		if(debug) then 
			echo("**DEBUG**: IsResser=false");
		end;
		return;
	end

	-- Doh, 1! Can't ress while dead!
	if UnitIsDeadOrGhost("player") then
		Thaliz_SetRezTargetText();
		Thaliz_SetButtonTexture(THALIZ_RezBtn_Dead);

		if(debug) then 
			echo("**DEBUG**: UnitIsDeadOrGhost=true");
		end;
		return;
	end;

	-- Doh, 2! Can't ress while in combat. Sorry druids, you get a LUA error if you try :-(
	if UnitAffectingCombat("player") then
		Thaliz_SetRezTargetText();
		Thaliz_SetButtonTexture(THALIZ_RezBtn_Combat);

		if(debug) then 
			echo("**DEBUG**: UnitAffectingCombat=true");
		end;
		return;
	end;

	local groupsize = GetNumGroupMembers();
	if groupsize == 0 then
		Thaliz_HideResurrectionButton();

		if(debug) then 
			echo("**DEBUG**: GetNumGroupMembers=0");
		end;
		return;
	end

	local grouptype = "party";
	if IsInRaid() then
		grouptype = "raid";
	end;

	local unitid;
	local warlocksAlive = false;
	for n=1, groupsize, 1 do
		unitid = grouptype..n
		if not UnitIsDead(unitid) and UnitIsConnected(unitid) and UnitIsVisible(unitid) and A:unitClass(unitid) == "WARLOCK" then
			warlocksAlive = true;
			break;
		end
	end

	Thaliz_CleanupBlacklistedPlayers();

	local classinfo = Thaliz_GetClassinfo(A.localPlayerClass);

	local spellnameStr = GetSpellInfo(classinfo["spellid"]);

	--Fetch current assigned target (if any):
	local currentPrio = 0;
	local highestPrio = 0;
	local currentIsValid = false;
	local currentTarget = "";
	unitid = RezButton:GetAttribute("unit");
	if unitid then
		currentTarget = A:getPlayerAndRealm(unitid);
	end;

	local masterLooter = nil;
	if IsInRaid() then
		local lootMethod, _, raidIndex = GetLootMethod();
		if lootMethod == "master" then
			masterLooter = A:getPlayerAndRealm("raid"..raidIndex);
		end;
	end;

	local targetprio;
	local corpseTable = { };
	local playername, classinfo, targetname, isBlacklisted;
	for n=1, groupsize, 1 do
		unitid = grouptype..n
		playername = A:getPlayerAndRealm(unitid);
		isBlacklisted = false;

		for b=1, table.getn(blacklistedTable), 1 do
			blacklistInfo = blacklistedTable[b];
			blacklistTick = blacklistInfo[2];
			
			if blacklistInfo[1] == playername then
				isBlacklisted = true;
				if(debug) then 
					echo(string.format("**DEBUG**: Player %s is blacklisted ...", playername));
				end;
				break;
			end
		end
		
		targetname = A:getPlayerAndRealm("playertarget");

		if (isBlacklisted == false) and 
			UnitIsDead(unitid) and 
			(UnitHasIncomingResurrection(unitid) == false) and 
			UnitIsConnected(unitid) and 
			UnitIsVisible(unitid) and 
			(IsSpellInRange(spellnameStr, unitid) == 1) 
		then
			classinfo = Thaliz_GetClassinfo(A:unitClass(unitid));
			targetprio = classinfo["priority"];
			if targetname and targetname == playername then
				targetprio = PriorityToCurrentTarget;
			end

			--	If masterlooter is ON then give prio to the master looter:
			if (playername == masterLooter) and (PriorityToMasterLooter > targetprio) then
				targetprio = PriorityToMasterLooter;
			end;

			if not warlocksAlive and classinfo["class"] == "Warlock" and PriorityToFirstWarlock > targetprio then
				targetprio = PriorityToFirstWarlock;				
			end

			
			-- Check if the current target is still eligible for ress:
			if playername == currentTarget then
				currentPrio = targetprio;
				currentIsValid = true;
			end;

			if targetprio > highestPrio then
				highestPrio = targetprio;
			end;

			-- Add a random decimal factor to priority to spread ressings out.
			-- Random is a float between 0 and 1:
			targetprio = targetprio + random();	

			--echo(string.format("%s added, unitid=%s, priority=%f", playername, unitid, targetprio));			
			corpseTable[ table.getn(corpseTable) + 1 ] = { unitid, targetprio } ;
		end
	end	

	if (table.getn(corpseTable) == 0) then
		Thaliz_HideResurrectionButton();

		if(debug) then 
			echo("**DEBUG**: corpseTable=(empty)");
		end;
		return;
	end

	if highestPrio > currentPrio then
		currentIsValid = false;
	end;


	if not currentIsValid then
		-- We found someone (or a new person) to ress.
		-- Sort the corpses with highest priority in top:
		Thaliz_SortTableDescending(corpseTable, 2);

		unitid = corpseTable[1][1];

		if(debug) then 
			if not spellnameStr then spellnameStr = "nil"; end;
			echo(string.format("**DEBUG**: corpse=%s, unitid=%s, spell=%s", UnitName(unitid), unitid, spellnameStr));
		end;

		RezButton:SetAttribute("type", "spell");
		RezButton:SetAttribute("spell", spellnameStr);
		RezButton:SetAttribute("unit", unitid);
	end;

	Thaliz_SetRezTargetText(A:getPlayerAndRealm(unitid));
	Thaliz_SetButtonTexture(THALIZ_RezBtn_Active, true);
end;


function Thaliz_OnRezClick(self)
	local buttonName = GetMouseButtonClicked();
	if buttonName == "RightButton" then
		Thaliz_OpenConfigurationDialogue();
	else
		Thaliz_BroadcastResurrection(self);
	end;
end;


function Thaliz_BroadcastResurrection(self)
	local unitid = self:GetAttribute("unit");
	if not unitid then 
		return; 
	end;

	A:sendAddonMessage(string.format("TX_RESBEGIN#%s#", A:getPlayerAndRealm(unitid)));
end;


function Thaliz_SetRezTargetText(playername)
	if not playername then
		playername = "";
	end;

	RezButton.title:SetText(playername);
end;


function Thaliz_HideResurrectionButton()
	Thaliz_SetButtonTexture(THALIZ_RezBtn_Passive);
	RezButton:SetAttribute("type", nil);
	RezButton:SetAttribute("unit", nil);
	Thaliz_SetRezTargetText();
end;


function Thaliz_InitClassSpecificStuff()
	local classname = A.localPlayerClass;

	THALIZ_RezBtn_Passive = THALIZ_ICON_OTHER_PASSIVE;
	THALIZ_RezBtn_Active = THALIZ_ICON_OTHER_PASSIVE;
	if classname == "DRUID" then
		IsDruid = true;
		IsResser = true;
		THALIZ_RezBtn_Passive = THALIZ_ICON_DRUID_PASSIVE;
		THALIZ_RezBtn_Active = THALIZ_ICON_DRUID_ACTIVE;
	elseif classname == "MONK" then
		IsMonk = true;
		IsResser = true;
		THALIZ_RezBtn_Passive = THALIZ_ICON_MONK_PASSIVE;
		THALIZ_RezBtn_Active = THALIZ_ICON_MONK_ACTIVE;
	elseif classname == "PALADIN" then
		IsPaladin = true;
		IsResser = true;
		THALIZ_RezBtn_Passive = THALIZ_ICON_PALADIN_PASSIVE;
		THALIZ_RezBtn_Active = THALIZ_ICON_PALADIN_ACTIVE;
	elseif classname == "PRIEST" then
		IsPriest = true;
		IsResser = true;
		THALIZ_RezBtn_Passive = THALIZ_ICON_PRIEST_PASSIVE;
		THALIZ_RezBtn_Active = THALIZ_ICON_PRIEST_ACTIVE;
	elseif classname == "SHAMAN" then
		IsShaman = true;
		IsResser = true;
		THALIZ_RezBtn_Passive = THALIZ_ICON_SHAMAN_PASSIVE;
		THALIZ_RezBtn_Active = THALIZ_ICON_SHAMAN_ACTIVE;
	end;

	if not IsResser then
		Thaliz_OPTION_RezButtonVisible_Default = "0";
	end;
end;

local RezButtonLastTexture = "";
function Thaliz_SetButtonTexture(textureName, isEnabled)
	local alphaValue = 0.5;
	if isEnabled then
		alphaValue = 1.0;
	end;

	if RezButtonLastTexture ~= textureName then	
		RezButtonLastTexture = textureName;
		RezButton:SetAlpha(alphaValue);
		RezButton:SetNormalTexture(textureName);		
	end;
end;


function Thaliz_GetClassinfo(classname)
	return Thaliz_ClassMatrix[string.upper(classname)];
end



--  *******************************************************
--
--	Blacklisting functions
--
--  *******************************************************

--[[
	Blacklist specific player.
]]
function Thaliz_BlacklistPlayer(playername, blacklistTime)
	if not blacklistTime then
		blacklistTime = Thaliz_Blacklist_Timeout;
	end;

	local timerTick = Thaliz_GetTimerTick();

	if Thaliz_IsPlayerBlacklisted(playername) then
		-- Player is already blacklisted; if the current blacklist time is higher than 
		-- the remaining blacklist value, we need to replace the current time with the
		-- requested time.
		for b=1, table.getn(blacklistedTable), 1 do
			local blacklistInfo = blacklistedTable[b];
			if blacklistInfo[1] == playername then
				local remainingTime = blacklistInfo[2] - timerTick;
				if remainingTime < blacklistTime then
					blacklistedTable[b][2] = timerTick + blacklistTime;
				end;
				break;
			end
		end
	else
		blacklistedTable[ table.getn(blacklistedTable) + 1 ] = { playername, timerTick + blacklistTime };
	end
end

--[[
	Remove player from Blacklist (if any)
]]
function Thaliz_WhitelistPlayer(playername)
	local WhitelistTable = { }

	for n=1, table.getn(blacklistedTable), 1 do
		blacklistInfo = blacklistedTable[n];
		if not (playername == blacklistInfo[1]) then
			WhitelistTable[ table.getn(WhitelistTable) + 1 ] = blacklistInfo;
		end
	end
	blacklistedTable = WhitelistTable;
end


function Thaliz_IsPlayerBlacklisted(playername)
	Thaliz_CleanupBlacklistedPlayers();

	for n=1, table.getn(blacklistedTable), 1 do		 
		if blacklistedTable[n][1] == playername then
			return true;
		end
	end
	return false;
end


function Thaliz_CleanupBlacklistedPlayers()
	local BlacklistedTableNew = {}
	local blacklistInfo;	
	local timerTick = Thaliz_GetTimerTick();
	
	for n=1, table.getn(blacklistedTable), 1 do
		blacklistInfo = blacklistedTable[n];
		if timerTick < blacklistInfo[2] then
			BlacklistedTableNew[ table.getn(BlacklistedTableNew) + 1 ] = blacklistInfo;
		end
	end
	blacklistedTable = BlacklistedTableNew;
end



--  *******************************************************
--
--	Helper functions
--
--  *******************************************************
function Thaliz_StripRealmName(playername)
	return string.gsub(playername, "(.*)-.*", "%1");
end;

function Thaliz_SortTableDescending(sourcetable, index)
	local doSort = true
	while doSort do
		doSort = false
		for n=1,table.getn(sourcetable) - 1,1 do
			local a = sourcetable[n]
			local b = sourcetable[n + 1]
			if tonumber(a[index]) and tonumber(b[index]) and tonumber(a[index]) < tonumber(b[index]) then
				sourcetable[n] = b
				sourcetable[n + 1] = a
				doSort = true
			end
		end
	end
end



--  *******************************************************
--
--	Version functions
--
--  *******************************************************

--[[
	Broadcast my version if this is not a beta (CurrentVersion > 0) and
	my version has not been identified as being too low (MessageShown = false)
]]
function Thaliz_OnGroupRosterUpdate(event, ...)
	if THALIZ_CURRENT_VERSION > 0 and not THALIZ_UPDATE_MESSAGE_SHOWN then
		if IsInRaid() or A:isInParty() then
			A:sendAddonMessage(string.format("TX_VERCHECK#%s#", A.addonVersion));
		end
	end
end

function Thalix_CheckIsNewVersion(versionstring)
	local incomingVersion = A:calculateVersion( versionstring );

	if (THALIZ_CURRENT_VERSION > 0 and incomingVersion > 0) then
		if incomingVersion > THALIZ_CURRENT_VERSION then
			if not THALIZ_UPDATE_MESSAGE_SHOWN then
				THALIZ_UPDATE_MESSAGE_SHOWN = true;
				A:echo(string.format("NOTE: A newer version of ".. A.chatColorHot .."THALIZ".. A.chatColorNormal .."! is available (version %s)!", versionstring));
				A:echo("You can download latest version from https://www.curseforge.com/ or https://github.com/Sentilix/thaliz-classic.");
			end
		end	
	end
end


--  *******************************************************
--
--	Timer functions
--
--  *******************************************************
local Timers = {}
local TimerTick = 0
local NextScanTime = 0;

function Thaliz_OnTimer(elapsed)
	TimerTick = TimerTick + elapsed

	if TimerTick > (NextScanTime + ThalizScanFrequency) then
		Thaliz_ScanRaid();
		NextScanTime = TimerTick;
	end;
end

function Thaliz_GetTimerTick()
	return TimerTick;
end





--  *******************************************************
--
--	Internal Communication Functions
--
--  *******************************************************

--[[
	Respond to a TX_VERSION command.
	Input:
		msg is the raw message
		sender is the name of the message sender.
	We should whisper this guy back with our current version number.
	We therefore generate a response back (RX) in raid with the syntax:
	Thaliz:<sender (which is actually the receiver!)>:<version number>
]]
function Thaliz_HandleTXVersion(message, sender)
	A:sendAddonMessage("RX_VERSION#".. A.addonVersion .."#"..sender)
end

function Thaliz_HandleTXResBegin(message, sender)
	-- Blacklist target unless ress was initated by me
	if not (sender == UnitName("player")) then
		--echo(string.format("*** Remote blacklisting %s (%s is ressing)", message, sender));
		Thaliz_BlacklistPlayer(message);
	end
end

--[[
	A version response (RX) was received. The version information is displayed locally.
]]
function Thaliz_HandleRXVersion(message, sender)
	A:echo(string.format("[%s] is using Thaliz version %s", sender, message))
end

function Thaliz_HandleTXVerCheck(message, sender)
	Thalix_CheckIsNewVersion(message);
end

function Thaliz_OnChatMsgAddon(event, ...)
	local prefix, msg, channel, sender = ...;

	if prefix == A.addonPrefix then
		Thaliz_HandleThalizMessage(msg, sender);
	end
end

function Thaliz_GetMyRealm()
	local realmname = GetRealmName();
	
	if string.find(realmname, " ") then
		local _, _, name1, name2 = string.find(realmname, "([a-zA-Z]*) ([a-zA-Z]*)");
		realmname = name1 .. name2; 
	end;

	return realmname;
end;

function Thaliz_HandleThalizMessage(msg, sender)
	local _, _, cmd, message, recipient = string.find(msg, "([^#]*)#([^#]*)#([^#]*)");	

	--	Ignore message if it is not for me. 
	--	Receipient can be blank, which means it is for everyone.
	if recipient ~= "" then
		-- Note: recipient comes with realmname. We need to compare
		-- with realmname too, even GetUnitName() does not return one:
		recipient = A:getFullPlayerName(recipient);

		if recipient ~= A.localPlayerName then
			return
		end
	end


	if cmd == "TX_VERSION" then
		Thaliz_HandleTXVersion(message, sender)
	elseif cmd == "RX_VERSION" then
		Thaliz_HandleRXVersion(message, sender)
	elseif cmd == "TX_RESBEGIN" then
		Thaliz_HandleTXResBegin(message, sender)
	elseif cmd == "TX_VERCHECK" then
		Thaliz_HandleTXVerCheck(message, sender)
	end
end

function Thaliz_BeginsWith(String, Start)
   return string.sub(String, 1, string.len(Start)) == Start;
end


function Thaliz_SpellIsResurrect(spellId)
	local resSpell = false;

	if spellId then
		local incRessName = GetSpellInfo(spellId);

		local classinfo = Thaliz_ClassMatrix[A.localPlayerClass];

		local classRessName = "";
		if classinfo["spellid"] then
			classRessName = GetSpellInfo(classinfo["spellid"]);
		end;

		resSpell = (incRessName == classRessName);
	end;

	return resSpell;
end;


--[[
	Return # of seconds left of blacklist timer, nil if not blacklisted
--]]
function Thaliz_IsPlayerBlacklisted(playername)

	for b=1, table.getn(blacklistedTable), 1 do
		local blacklistInfo = blacklistedTable[b];
		if blacklistInfo[1] == playername then
			return (blacklistInfo[2] - TimerTick);
		end
	end
	return nil;
end;


local Thaliz_CurrentRessedTarget = nil;
function Thaliz_ClearCurrentResurrectedTarget()
	Thaliz_SetCurrentResurrectedTarget(nil);
end;

function Thaliz_GetCurrentResurrectedTarget()
	return Thaliz_CurrentRessedTarget;
end;

function Thaliz_SetCurrentResurrectedTarget(target)
	Thaliz_CurrentRessedTarget = target;
end;


--[[
	UI events
--]]

function Thaliz_OKButton_OnClick()
	Thaliz_CloseConfigurationDialogue();
	
	local whisperMsg = _G["ThalizFrameWhisper"]:GetText(whisperMsg);
	Thaliz_SetOption(Thaliz_OPTION_ResurrectionWhisperMessage, whisperMsg);
	
	Thaliz_ConfigurationLevel = Thaliz_GetRootOption(Thaliz_ROOT_OPTION_CharacterBasedSettings, Thaliz_Configuration_Default_Level);
end

function Thaliz_ProfileButton_OnClick()
	if msgEditorIsOpen then
		Thaliz_CloseMsgEditorButton_OnClick();
	end;

	ThalizProfileFrame:Show();
end;

function Thaliz_PresetButton_OnClick()
	if msgEditorIsOpen then
		Thaliz_CloseMsgEditorButton_OnClick();
	end;

	ThalizPresetFrame:Show();
end;

function Thaliz_CloseButton_OnClick()
	if msgEditorIsOpen then
		Thaliz_CloseMsgEditorButton_OnClick();
	elseif profileFrameIsOpen then
		Thaliz_CloseProfileButton_OnClick();
	elseif presetFrameIsOpen then
		Thaliz_ClosePresetButton_OnClick();
	else
		Thaliz_CloseConfigurationDialogue();
	end;
end

function Thaliz_CloseProfileButton_OnClick()
	ThalizProfileFrame:Hide();
	profileFrameIsOpen = false;
end;

function Thaliz_ClosePresetButton_OnClick()
	ThalizPresetFrame:Hide();
	presetFrameIsOpen = false;
end;

function Thaliz_CloseMsgEditorButton_OnClick()
	ThalizMsgEditorFrame:Hide();
	msgEditorIsOpen = false;
end

function Thaliz_DropDownNameEnclosureButton_OnClick(self, arg1, arg2, checked)
	if arg1 then
		Thaliz_SetOption(Thaliz_OPTION_ResurrectionNameEnclosure, arg1);
	end;

	Thaliz_UpdateNameEnclosureText();
end;

function Thaliz_UpdateNameEnclosureText()
	local enclosure = Thaliz_GetNameEnclosure(Thaliz_GetOption(Thaliz_OPTION_ResurrectionNameEnclosure, "NONE"));
	if enclosure then
		UIDropDownMenu_SetText(DropDownNameEnclosureButton, enclosure[2]);
	end;
end;

function Thaliz_GetNameEnclosure(optionname)
	local enclosure = nil;

	for n=1, table.getn(THALIZ_NAME_ENCLOSURES), 1 do
		if THALIZ_NAME_ENCLOSURES[n][1] == optionname then
			enclosure = THALIZ_NAME_ENCLOSURES[n];
			break;
		end;
	end;	
	
	return enclosure;
end;

function Thaliz_RepositionateButton(self)
	local x, y = self:GetLeft(), self:GetTop() - UIParent:GetHeight();

	Thaliz_SetOption(Thaliz_OPTION_RezButtonPosX, x);
	Thaliz_SetOption(Thaliz_OPTION_RezButtonPosY, y);

	RezButton:SetSize(THALIZ_REZBUTTON_SIZE, THALIZ_REZBUTTON_SIZE);

	local classinfo = Thaliz_GetClassinfo(A.localPlayerClass);

	local spellId = classinfo["spellid"];
	if spellId then
		RezButton:Show();
	else
		RezButton:Hide();
	end;
end

local SkipTaintCheck = true;
function Thaliz_DropDownNameEnclosure_Initialize(frame, level, menuList)
	_delayed_owner = this;
	Thaliz_DelayInitialization = true;
	Thaliz_DelayedDropDownNameEnclosure_Initialize();
end;

function Thaliz_DropDownProfiles_Initialize(frame, level, menuList)
	UIDropDownMenu_SetWidth(DropDownProfileButton, 300);

	for index=1, table.getn(Thaliz_ProfileTable), 1 do
		local profile = Thaliz_ProfileTable[index];

		local info = UIDropDownMenu_CreateInfo();
		info.text			= string.format("%s - %s (%d)", profile["realm"], profile["name"], profile["count"]);
		info.notCheckable	= true;
		info.func			= function() Thaliz_DropDownProfiles_OnClick(this, profile) end;
		UIDropDownMenu_AddButton(info);
	end
end;

function Thaliz_DropDownPresets_Initialize(frame, level, menuList)
	UIDropDownMenu_SetWidth(DropDownPresetButton, 300);

	for index=1, table.getn(Thaliz_PresetMessages) do
		local preset = Thaliz_PresetMessages[index];

		local info = UIDropDownMenu_CreateInfo();
		info.text			= string.format("%s - %s", preset["name"], preset["description"]);
		info.notCheckable	= true;
		info.func			= function() Thaliz_DropDownPreset_OnClick(this, preset) end;
		UIDropDownMenu_AddButton(info);
	end;
end;

function Thaliz_DropDownProfiles_OnClick(sender, profile)
	Thaliz_SelectedProfile = profile;
	UIDropDownMenu_SetText(DropDownProfileButton, string.format("%s - %s (%d)", profile["realm"], profile["name"], profile["count"]));
	Thaliz_RefreshProfileButtons();
end;

function Thaliz_DropDownPreset_OnClick(sender, preset)
	Thaliz_SelectedPreset = preset;
	UIDropDownMenu_SetText(DropDownPresetButton, string.format("%s - %s", preset["name"], preset["description"]));
	Thaliz_RefreshPresetButtons();
end;

function Thaliz_InitializeNameEnclosures()
	local playername = UnitName('Player');
	for n=1, table.getn(THALIZ_NAME_ENCLOSURES), 1 do
		THALIZ_NAME_ENCLOSURES[n][2] = string.format(THALIZ_NAME_ENCLOSURES[n][2], playername);
	end;

	Thaliz_UpdateNameEnclosureText();
end;

function Thaliz_DelayedDropDownNameEnclosure_Initialize()
	if not CompactRaidFrame1  then
		if not SkipTaintCheck then
			return;
		end;
	end;

	Thaliz_DelayInitialization = false;

	local CurOption = Thaliz_GetOption(Thaliz_OPTION_ResurrectionNameEnclosure, "NONE");


	for n=1, table.getn(THALIZ_NAME_ENCLOSURES), 1 do
		local checked = false;
		if CurOption == THALIZ_NAME_ENCLOSURES[n][1] then 
			checked = true;
		end;

		local info = UIDropDownMenu_CreateInfo();
		info.text       = THALIZ_NAME_ENCLOSURES[n][2];
		info.checked	= checked;
		info.func       = function() Thaliz_DropDownNameEnclosureButton_OnClick(_delayed_owner, THALIZ_NAME_ENCLOSURES[n][1]) end;
		UIDropDownMenu_AddButton(info);
	end
end



--[[
	Profile functions
--]]

function Thaliz_RefreshProfileButtons()
	local profileText = UIDropDownMenu_GetText(DropDownProfileButton) or "";

	if profileText == "" then
		ReplaceWithProfileButton:Disable();
		MergeWithProfileButton:Disable();
	else
		ReplaceWithProfileButton:Enable();
		MergeWithProfileButton:Enable();
	end;
end;

function Thaliz_RefreshPresetButtons()
	local presetText = UIDropDownMenu_GetText(DropDownPresetButton) or "";

	if presetText == "" then
		ReplaceWithPresetButton:Disable();
		MergeWithPresetButton:Disable();
	else
		ReplaceWithPresetButton:Enable();
		MergeWithPresetButton:Enable();
	end;
end;

function Thaliz_ReplaceWithProfile_OnClick()
	Thaliz_ImportProfile();
end;

function Thaliz_ReplaceWithPreset_OnClick()
	Thaliz_ImportPreset();
end;

function Thaliz_MergeWithProfile_OnClick()
	Thaliz_ImportProfile(true);
end;

function Thaliz_MergeWithPreset_OnClick()
	Thaliz_ImportPreset(true);
end;

function Thaliz_ImportProfile(keepExistingMessages)
	if not Thaliz_SelectedProfile then return; end;
	local profile = Thaliz_SelectedProfile;

	if not Thaliz_Options[profile["realm"]] then return; end;
	if not Thaliz_Options[profile["realm"]][profile["name"]] then return; end;
	local importedMessages = Thaliz_Options[profile["realm"]][profile["name"]]["ResurrectionMessages"];
	if not importedMessages or type(importedMessages) ~= "table" then return; end;

	local resurrectionMessages = { };
	if keepExistingMessages then
		resurrectionMessages = Thaliz_GetResurrectionMessages();
	end;

	--	Check if we already have this macro in our list:
	local messageAddedCounter = 0;
	for _, importMessage in next, importedMessages do

		--	Sanity check: in case original table is borken:
		if	type(importMessage) == "table" and 
			table.getn(importMessage) >= 3 and 
			table.getn(importMessage) <= 4 and 
			type(importMessage[1]) == "string" and
			type(importMessage[2]) == "string" and
			type(importMessage[3]) == "string" then

			local alreadyExists = false;
			for _, myMessage in next, resurrectionMessages do
				if myMessage[1] == importMessage[1] then
					alreadyExists = true;
					break;
				end;
			end;

			if not alreadyExists then
				messageAddedCounter = messageAddedCounter + 1;
				tinsert(resurrectionMessages, { importMessage[1], importMessage[2], importMessage[3] });
			end;
		end;
	end;

	if messageAddedCounter > 0 then
		Thaliz_SetResurrectionMessages(resurrectionMessages);
		if keepExistingMessages then
			A:echo(string.format("%d message(s) was merged from %s's profile.", messageAddedCounter, profile["fullname"]));
		else
			A:echo(string.format("%d message(s) was imported from %s's profile.", messageAddedCounter, profile["fullname"]));
		end;

		Thaliz_UpdateMessageList();
	else
		A:echo(string.format("No messages was imported from %s's profile.", profile["fullname"]));
	end;
end;

function Thaliz_ImportPreset(keepExistingMessages)
	if not Thaliz_SelectedPreset then return; end;
	local preset = Thaliz_SelectedPreset;

	local presetMessages = preset["messages"];
	if not presetMessages or type(presetMessages) ~= "table" then return; end;

	local resurrectionMessages = { };
	if keepExistingMessages then
		resurrectionMessages = Thaliz_GetResurrectionMessages();
	end;

	--	Check if we already have this macro in our list:
	local messageAddedCounter = 0;
	for _, importMessage in next, presetMessages do
		local alreadyExists = false;
		for _, myMessage in next, resurrectionMessages do
			if myMessage[1] == importMessage then
				alreadyExists = true;
				break;
			end;
		end;

		if not alreadyExists then
			messageAddedCounter = messageAddedCounter + 1;
			tinsert(resurrectionMessages, { importMessage, EMOTE_GROUP_DEFAULT, "" });
		end;
	end;

	if messageAddedCounter > 0 then
		Thaliz_SetResurrectionMessages(resurrectionMessages);
		if keepExistingMessages then
			A:echo(string.format("%d message(s) was merged from presets.", messageAddedCounter));
		else
			A:echo(string.format("%d message(s) was imported from presets.", messageAddedCounter));
		end;

		Thaliz_UpdateMessageList();
	else
		A:echo("No messages was imported from preset.");
	end;
end;



--  *******************************************************
--
--	Event handlers
--
--  *******************************************************

local SpellcastIsStarted = 0;
function Thaliz_OnEvent(self, event, ...)
	local debug = (Thaliz_DebugFunction and Thaliz_DebugFunction == "Thaliz_OnEvent");
	local timerTick = Thaliz_GetTimerTick();

	if (event == "ADDON_LOADED") then
		local addonname = ...;
		if addonname == A.addonName then
		    Thaliz_InitializeConfigSettings();
		end

	elseif (event == "UNIT_SPELLCAST_SENT") then
		local resser, target, _, spellId = ...;
		if(resser == "player") then
			if (target ~= "Unknown") then
				if(debug) then 
					print(string.format("**DEBUG**: UNIT_SPELLCAST_SENT, SpellId=%s", spellId));
				end;
				if not Thaliz_IsPlayerBlacklisted(target) then
					if Thaliz_SpellIsResurrect(spellId) then
						Thaliz_SetCurrentResurrectedTarget(target);
						Thaliz_BlacklistPlayer(target, Thaliz_Blacklist_Resurrect);
						Thaliz_AnnounceResurrection(target);
					end;
				end;
			end;
		end;
		
	elseif(event == "UNIT_SPELLCAST_START") then
		local resser, _, _, _ = ...;
		if(resser == "player") then
			SpellcastIsStarted = timerTick;
		end;

	elseif(event == "UNIT_SPELLCAST_SUCCEEDED") then
		local resser, _, _, _ = ...;
		if(resser == "player") then
			Thaliz_ClearCurrentResurrectedTarget();
		end;

	elseif(event == "UNIT_SPELLCAST_STOP") then
		local resser, _, _, _ = ...;
		if(resser ~= "player") then
			if(debug) then 
				echo(string.format("**DEBUG**: UNIT_SPELLCAST_STOP, by other resser=%s", resser));
			end;
			return;
		end;

		local target = Thaliz_GetCurrentResurrectedTarget();
		if target then
			if(debug) then 
				echo(string.format("**DEBUG**: UNIT_SPELLCAST_STOP, whitelisting player=%s", target));
			end;
			Thaliz_WhitelistPlayer(target);
			Thaliz_ClearCurrentResurrectedTarget();
		end;

	elseif(event == "UNIT_SPELLCAST_FAILED") then
		Thaliz_ClearCurrentResurrectedTarget();

	elseif (event == "INCOMING_RESURRECT_CHANGED") then
		local arg1 = ...;

		local timeDiff = timerTick - SpellcastIsStarted;
		if(debug) then 
			echo(string.format("**DEBUG**: INCOMING_RESURRECT_CHANGED, cast=%f, diff=%f", SpellcastIsStarted, timeDiff));
		end;

		if (timeDiff < 0.001) and UnitIsGhost(arg1) then
			if(debug) then 
				echo("**DEBUG**: INCOMING_RESURRECT_CHANGED, starting");
			end;

			SpellcastIsStarted = timerTick;
			if IsInRaid() then
				if Thaliz_BeginsWith(arg1, 'raid') then
					Thaliz_SetCurrentResurrectedTarget(A:getPlayerAndRealm(arg1));
				end;
			else
				if Thaliz_BeginsWith(arg1, 'party') then
					Thaliz_SetCurrentResurrectedTarget(A:getPlayerAndRealm(arg1));
				end;
			end;

			local target = Thaliz_GetCurrentResurrectedTarget();
			if target then
				if(debug) then 
					echo(string.format("**DEBUG**: INCOMING_RESURRECT_CHANGED, target=%s", target));
				end;

				if Thaliz_IsPlayerBlacklisted(target) then
					A:echo(string.format("Note: [%s] is already being resurrected.", target));
				else
					Thaliz_BlacklistPlayer(target, Thaliz_Blacklist_Spellcast);
					Thaliz_AnnounceResurrection(target, arg1);
				end;
			end;
		end;

	elseif (event == "CHAT_MSG_ADDON") then
		Thaliz_OnChatMsgAddon(event, ...)

	elseif (event == "GROUP_ROSTER_UPDATE") then
		Thaliz_OnGroupRosterUpdate(event, ...)

	elseif (event == "COMBAT_LOG_EVENT_UNFILTERED") then
		local _, subevent, _, _, sourceName, _, _, _, destName, _, _, spellId = CombatLogGetCurrentEventInfo();

		if (subevent == "SPELL_CAST_START") then
			if(debug) then 
				echo(string.format("**DEBUG**: COMBAT_LOG_EVENT_UNFILTERED, subevent=%s, sourceName=%s, spellId=%s", subevent, sourceName, spellId));
			end;

			if (sourceName == A.localPlayerName) then
				if Thaliz_SpellIsResurrect(spellId) then
					SpellcastIsStarted = timerTick;
				end;
			end

		elseif subevent == "SPELL_RESURRECT" then
			if sourceName ~= A.localPlayerName then
				Thaliz_BlacklistPlayer(destName, Thaliz_Blacklist_Resurrect);
			end;
		end

	else
		if(debug) then 
			echo("**DEBUG**: Other event: "..event);

			local arg1, arg2, arg3, arg4 = ...;
			if arg1 then
				echo(string.format("**DEBUG**: arg1=%s", arg1));
			end;
			if arg2 then				
				echo(string.format("**DEBUG**: arg2=%s", arg2));
			end;
			if arg3 then				
				echo(string.format("**DEBUG**: arg3=%s", arg3));
			end;
			if arg4 then				
				echo(string.format("**DEBUG**: arg4=%s", arg4));
			end;
		end;
	end
end

function Thaliz_OnLoad()
	msgEditorIsOpen = false;

	THALIZ_CURRENT_VERSION = A:calculateVersion(A.addonVersion);

	_G["ThalizVersionString"]:SetText(string.format("Thaliz version %s by %s", A.addonVersion, A.addonAuthor));

	A:echo(string.format("Type %s/thaliz%s to configure the addon, or right-click the Thaliz button.", A.chatColorHot, A.chatColorNormal));

    ThalizEventFrame:RegisterEvent("ADDON_LOADED");
    ThalizEventFrame:RegisterEvent("CHAT_MSG_ADDON");
    ThalizEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
    ThalizEventFrame:RegisterEvent("UNIT_SPELLCAST_SENT");
	ThalizEventFrame:RegisterEvent("INCOMING_RESURRECT_CHANGED");
	ThalizEventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
    ThalizEventFrame:RegisterEvent("UNIT_SPELLCAST_START");
    ThalizEventFrame:RegisterEvent("UNIT_SPELLCAST_STOP");
    ThalizEventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED");
    ThalizEventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");

	C_ChatInfo.RegisterAddonMessagePrefix(A.addonPrefix);

	Thaliz_InitClassSpecificStuff();
    Thaliz_InitializeListElements();
	Thaliz_RefreshProfileButtons();

	Thaliz_RepositionateButton(RezButton);
end
