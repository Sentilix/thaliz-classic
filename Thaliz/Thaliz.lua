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

Thaliz = select(2, ...)
Thaliz.lib = DigamAddonLib:new(addonMetadata);
Thaliz.API = Thaliz.lib.API;


local PARTY_CHANNEL							= "PARTY"
local RAID_CHANNEL							= "RAID"
local YELL_CHANNEL							= "YELL"
local SAY_CHANNEL							= "SAY"
local WARN_CHANNEL							= "RAID_WARNING"
local GUILD_CHANNEL							= "GUILD"
local THALIZ_MAX_MESSAGES					= 400
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

Thaliz.ClassMatrix = {
	["DRUID"] = {
		["class"] = "Druid",
		["priority"] = 40,
		["spellid"] = 20747,
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
	--	Non-playable classes:
	["TARGET"] = {
		["class"] = "Current Target",
		["priority"] = 100,
		["spellid"] = nil,
		["color"] = { 0, 0, 0 },
	},
	["MASTER"] = {
		["class"] = "Master Looter",
		["priority"] = 60,
		["spellid"] = nil,
		["color"] = { 0, 0, 0 },
	},
	["FIRSTLOCK"] = {
		["class"] = "First Warlock",
		["priority"] = 45,
		["spellid"] = nil,
		["color"] = { 0, 0, 0 },
	},

}


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

local THALIZ_MESSAGE_ORDERS = {
	{ "RANDOM",		"Random"		},
	{ "SEQUENTIAL",	"Sequential"	},
}

local IsPaladin = false;
local IsPriest = false;
local IsShaman = false;
local IsDruid = false;
local IsMonk = false;
local IsResser = false;

Thaliz.Icon_RezBtn_Passive			= "";
Thaliz.Icon_RezBtn_Active			= "";
Thaliz.Icon_RezBtn_Combat			= "Interface\\Icons\\Ability_dualwield";
Thaliz.Icon_RezBtn_Dead				= "Interface\\Icons\\Ability_rogue_feigndeath";

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


-- List of blacklisted (already ressed) people
-- Table { PlayerName-RealmName, TimerTick }
local blacklistedTable = {}
-- Corpses are blacklisted for 40 seconds (10 seconds cast time + 30 seconds waiting) as default
Thaliz.BlacklistSpellcastTime = 10;
Thaliz.BlacklistResurrectionTimeout = 30;
Thaliz.BlacklistTimeout = Thaliz.BlacklistSpellcastTime + Thaliz.BlacklistResurrectionTimeout;

Thaliz.LastRandomMessageIndex = -1;
Thaliz.Enabled = true;
Thaliz.ScanFrequency = 0.2;		-- Scan 5 times per second
Thaliz.ProfileTable = { };
Thaliz.SelectedImportProfile = nil;
Thaliz.ResurrectionNextMessage = 1;

local ThalizConfigDialogOpen = false;
local ThalizDoScanRaid = true;

-- Configuration values:
Thaliz.Configuration_Default_Level				= "Character";	-- Can be "Character" or "Realm"
Thaliz.Target_Channel_Default					= "RAID";
Thaliz.Target_Whisper_Default					= "0";
Thaliz.Resurrection_Whisper_Message_Default		= "Resurrection incoming in 10 seconds!";
Thaliz.Include_Default_Group_Default			= "1";
Thaliz.OPTION_RezButtonVisible_Default			= "1";

Thaliz.ConfigurationLevel						= Thaliz.Configuration_Default_Level;

Thaliz.ROOT_OPTION_CharacterBasedSettings		= "CharacterBasedSettings";
Thaliz.OPTION_ResurrectionMessageTargetChannel	= "ResurrectionMessageTargetChannel";
Thaliz.OPTION_ResurrectionMessageTargetWhisper	= "ResurrectionMessageTargetWhisper";
Thaliz.OPTION_ResurrectionNameEnclosure			= "ResurrectionNameEnclosure";
Thaliz.OPTION_ResurrectionMessageOrder			= "ResurrectionMessageOrder";
Thaliz.OPTION_ResurrectionNextMessage			= "ResurrectionNextMessage";
Thaliz.OPTION_AlwaysIncludeDefaultGroup			= "AlwaysIncludeDefaultGroup";
Thaliz.OPTION_ResurrectionWhisperMessage		= "ResurrectionWhisperMessage";
Thaliz.OPTION_ResurrectionMessages				= "ResurrectionMessages";
Thaliz.OPTION_RezButtonPosX						= "RezButtonPosX";
Thaliz.OPTION_RezButtonPosY						= "RezButtonPosY";
Thaliz.OPTION_RezButtonVisible					= "ResurrectionButtonVisible";

Thaliz.OPTION_ResurrectionPriority				= "ResurrectionPriority";
Thaliz.Configuration_Default_Priority = {
	["Druid"]			= { ["Priority"] = 40 },
	["Hunter"]			= { ["Priority"] = 30 },
	["Mage"]			= { ["Priority"] = 40 },
	["Paladin"]			= { ["Priority"] = 50 },
	["Priest"]			= { ["Priority"] = 50 },
	["Rogue"]			= { ["Priority"] = 10 },
	["Shaman"]			= { ["Priority"] = 50 },
	["Warlock"]			= { ["Priority"] = 30 },
	["Warrior"]			= { ["Priority"] = 20 },
	["CurrentTarget"]	= { ["Priority"] = 100 },
	["MasterLooter"]	= { ["Priority"] = 60 },
	["FirstWarlock"]	= { ["Priority"] = 45 },
}

Thaliz.DebugFunction = nil;

-- Persisted information:
--	{realmname}{playername}{parameter}
Thaliz.Options = { }

-- First-time messages: use the DAD JOKES, beware! :-D
Thaliz.DefaultPresetGroup							= 5;		


--[[
	Echo in raid chat (if in raid) or party chat (if not)
]]
function Thaliz.partyEcho(msg)
	if Thaliz.API.IsInRaid() then
		Thaliz.API.SendChatMessage(msg, RAID_CHANNEL)
	elseif Thaliz.lib:isInParty() then
		Thaliz.API.SendChatMessage(msg, PARTY_CHANNEL)
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
		Thaliz.lib:echo(string.format("Unknown command: %s", option));
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
	Thaliz.SetConfigOption(Thaliz.OPTION_RezButtonVisible, "1");
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
	Thaliz.SetConfigOption(Thaliz.OPTION_RezButtonVisible, "0");
end

--[[
	Request client version information
	Syntax: /thalizversion
	Alternative: /thaliz version
	Added in: 0.2.1
]]
SLASH_THALIZ_VERSION1 = "/thalizversion"
SlashCmdList["THALIZ_VERSION"] = function(msg)
	if Thaliz.API.IsInRaid() or Thaliz.lib:isInParty() then
		Thaliz.lib:sendAddonMessage("TX_VERSION##");
	else
		Thaliz.lib:echo(string.format("%s is using Thaliz version %s", Thaliz.lib.localPlayerName, Thaliz.lib.addonVersion));
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
	Thaliz.OpenConfigurationDialogue();
end

--[[
	Disable Thaliz' messages
	Syntax: /thaliz disable
	Added in: 0.3.2
]]
SLASH_THALIZ_DISABLE1 = "/thalizdisable"
SlashCmdList["THALIZ_DISABLE"] = function(msg)
	Thaliz.Enabled = false;
	Thaliz.lib:echo("Resurrection announcements has been disabled.");
end

--[[
	Enable Thaliz' messages
	Syntax: /thaliz enable
	Added in: 0.3.2
]]
SLASH_THALIZ_ENABLE1 = "/thalizenable"
SlashCmdList["THALIZ_ENABLE"] = function(msg)
	Thaliz.Enabled = true;
	Thaliz.lib:echo("Resurrection announcements has been enabled.");
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

	if Thaliz.OPTION_RezButtonVisible_Default == "1" then
		RezButton:Show();
	end;

	Thaliz.SetConfigOption(Thaliz.OPTION_RezButtonPosX, 0);
	Thaliz.SetConfigOption(Thaliz.OPTION_RezButtonPosY, 0);

	Thaliz.lib:echo("The Resurrection button has been reset.");
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
		Thaliz.lib:echo(string.format("Enabling debug for %s", dbgfunc));
		Thaliz.ScanFrequency = 1.0;
		Thaliz.DebugFunction = dbgfunc;
	else
		Thaliz.lib:echo("Disabling debug");
		Thaliz.ScanFrequency = 0.2;
		Thaliz.DebugFunction = nil;
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
	Thaliz.lib:echo(string.format("Thaliz version %s options:", Thaliz.lib.addonVersion));
	Thaliz.lib:echo("Syntax:");
	Thaliz.lib:echo("    /thaliz [option]");
	Thaliz.lib:echo("Where options can be:");
	Thaliz.lib:echo("    Config       (default) Open the configuration dialogue,");
	Thaliz.lib:echo("    Disable      Disable Thaliz resurrection messages.");
	Thaliz.lib:echo("    Enable       Enable Thaliz resurrection messages again.");
	Thaliz.lib:echo("    ResetButton  Resets the position of the Rez Button.");
	Thaliz.lib:echo("    Help         This help.");
	Thaliz.lib:echo("    Show         Shows the resurrection button.");
	Thaliz.lib:echo("    Hide         Hides the resurrection button.");
	Thaliz.lib:echo("    Version      Request version info from all clients.");
end



--  *******************************************************
--
--	Configuration functions
--
--  *******************************************************

function Thaliz.ToggleConfigurationDialogue()
	if ThalizConfigDialogOpen then
		Thaliz_CloseButton_OnClick();
	else
		Thaliz.OpenConfigurationDialogue();
	end;
end

function Thaliz.OpenConfigurationDialogue()
	local whisperMsg = Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionWhisperMessage);

	if not whisperMsg then whisperMsg = ""; end;

	ThalizFrameWhisper:SetText(whisperMsg);
	ThalizFrameWhisper:SetAutoFocus(false);
	ThalizConfigDialogOpen = true;
	ThalizFrame:Show();
end

function Thaliz.CloseConfigurationDialogue()
	Thaliz_CloseMsgEditorButton_OnClick();
	Thaliz_CloseProfileButton_OnClick();
	Thaliz_ClosePresetButton_OnClick();
	Thaliz_ClosePriorityButton_OnClick();

	ThalizConfigDialogOpen = false;
	ThalizFrame:Hide();
end


function Thaliz.RefreshVisibleMessageList(offset)
--	echo(string.format("Thaliz.RefreshVisibleMessageList: Offset=%d", offset));
	local macros = Thaliz.GetResurrectionMessages();
	
	-- Set a priority on each spell, and then sort them accordingly:
	local macro, msg, grp, prm, prio
	for n=1, #macros, 1 do
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
			-- Forever:
			elseif prm == "Skyborne" then
				prio = 124
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
	
	Thaliz.SortTableDescending(macros, 4);
	
	for n=1, THALIZ_MAX_VISIBLE_MESSAGES, 1 do
		macro = macros[n + offset]
		if not macro then
			macro = { "", EMOTE_GROUP_DEFAULT, "" }
		end
		
		local msg = Thaliz.CheckMessage(macro[1]);
		local grp = Thaliz.CheckGroup(macro[2]);
		local prm = Thaliz.CheckGroupValue(macro[3]);
		
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

			local classinfo = Thaliz.ClassMatrix[prm];
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
	
	Thaliz.RefreshVisibleMessageList(offset);
end

function Thaliz.InitializeListElements()
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
local priorityFrameIsOpen;
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
	
	grp = Thaliz.CheckGroup(grp);
	prm = Thaliz.CheckGroupValue(prm);

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
		prm = Thaliz.UCFirst(prm)
	elseif grp == EMOTE_GROUP_RACE then
		-- Allow both "nightelf" and "night elf".
		-- This weird construction ensures all are shown with capital first letter.
		if string.upper(prm) == "NIGHTELF" or string.upper(prm) == "NIGHT ELF" then
			prm = "Night Elf"
		elseif string.upper(prm) == "BLOODELF" or string.upper(prm) == "BLOOD ELF" then
			prm = "Blood Elf"
		else
			prm = Thaliz.UCFirst(prm)
		end;
	end

	Thaliz_CloseMsgEditorButton_OnClick();	
	Thaliz.UpdateResurrectionMessage(currentObjectId, offset, msg, grp, prm);
	Thaliz_UpdateMessageList();
end


function Thaliz_HandleCheckbox(checkbox)
	local checkboxname = checkbox:GetName();

	--	If checked, then we need to uncheck others in same group:
	if checkboxname == "ThalizFrameCheckbuttonRaid" or checkboxname == "ThalizFrameCheckbuttonYell" or checkboxname == "ThalizFrameCheckbuttonSay" then	
		if checkbox:GetChecked() then
			if checkboxname == "ThalizFrameCheckbuttonRaid" then
				Thaliz.SetConfigOption(Thaliz.OPTION_ResurrectionMessageTargetChannel, "RAID");
				ThalizFrameCheckbuttonSay:SetChecked();
				ThalizFrameCheckbuttonYell:SetChecked();
			elseif checkboxname == "ThalizFrameCheckbuttonYell" then
				Thaliz.SetConfigOption(Thaliz.OPTION_ResurrectionMessageTargetChannel, "YELL");
				ThalizFrameCheckbuttonSay:SetChecked();
				ThalizFrameCheckbuttonRaid:SetChecked();
			elseif checkboxname == "ThalizFrameCheckbuttonSay" then
				Thaliz.SetConfigOption(Thaliz.OPTION_ResurrectionMessageTargetChannel, "SAY");
				ThalizFrameCheckbuttonRaid:SetChecked();
				ThalizFrameCheckbuttonYell:SetChecked();
			end
		else
			Thaliz.SetConfigOption(Thaliz.OPTION_ResurrectionMessageTargetChannel, "NONE");
			ThalizFrameCheckbuttonRaid:SetChecked();
			ThalizFrameCheckbuttonSay:SetChecked();
			ThalizFrameCheckbuttonYell:SetChecked();
		end
	end

	-- "single" checkboxes (checkboxes with no impact on other checkboxes):
	if ThalizFrameCheckbuttonWhisper:GetChecked() then
		Thaliz.SetConfigOption(Thaliz.OPTION_ResurrectionMessageTargetWhisper, 1);
	else
		Thaliz.SetConfigOption(Thaliz.OPTION_ResurrectionMessageTargetWhisper, 0);
	end	
	
	if ThalizFrameCheckbuttonIncludeDefault:GetChecked() then
		Thaliz.SetConfigOption(Thaliz.OPTION_AlwaysIncludeDefaultGroup, 1);
	else
		Thaliz.SetConfigOption(Thaliz.OPTION_AlwaysIncludeDefaultGroup, 0);
	end	
		
	if ThalizFrameCheckbuttonPerCharacter:GetChecked() then
		Thaliz.SetRootConfigOption(Thaliz.ROOT_OPTION_CharacterBasedSettings, "Character");
	else
		Thaliz.SetRootConfigOption(Thaliz.ROOT_OPTION_CharacterBasedSettings, "Realm");
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

function Thaliz.GetRootConfigOption(parameter, defaultValue)
	if Thaliz.Options then
		if Thaliz.Options[parameter] then
			local value = Thaliz.Options[parameter];
			if (type(value) == "table") or not(value == "") then
				return value;
			end
		end		
	end
	
	return defaultValue;
end

function Thaliz.SetRootConfigOption(parameter, value)
	if not parameter then
		return
	end;

	if not Thaliz.Options then
		Thaliz.Options = {};
	end
	
	Thaliz.Options[parameter] = value;
end

function Thaliz.GetConfigOption(parameter, defaultValue)
	local realmname = Thaliz.API.GetRealmName();
	local playername = Thaliz.API.UnitName("player");

	if Thaliz.ConfigurationLevel == "Character" then
		-- Character level
		if Thaliz.Options[realmname] then
			if Thaliz.Options[realmname][playername] then
				if Thaliz.Options[realmname][playername][parameter] then
					local value = Thaliz.Options[realmname][playername][parameter];
					if (type(value) == "table") or not(value == "") then
						return value;
					end
				end		
			end
		end
	else
		-- Realm level:
		if Thaliz.Options[realmname] then
			if Thaliz.Options[realmname][parameter] then
				local value = Thaliz.Options[realmname][parameter];
				if (type(value) == "table") or not(value == "") then
					return value;
				end
			end		
		end
	end
	
	return defaultValue;
end

function Thaliz.SetConfigOption(parameter, value)
	local realmname = Thaliz.API.GetRealmName();
	local playername = Thaliz.API.UnitName("player");

	if Thaliz.ConfigurationLevel == "Character" then
		-- Character level:
		if not Thaliz.Options[realmname] then
			Thaliz.Options[realmname] = {};
		end
		
		if not Thaliz.Options[realmname][playername] then
			Thaliz.Options[realmname][playername] = {};
		end
		
		Thaliz.Options[realmname][playername][parameter] = value;		
	else
		-- Realm level:
		if not Thaliz.Options[realmname] then
			Thaliz.Options[realmname] = {};
		end	
		
		Thaliz.Options[realmname][parameter] = value;
	end
end

function Thaliz.InitializeConfigSettings()
	if not Thaliz.Options then
		Thaliz.Options = { };
	end

	Thaliz.SetRootConfigOption(Thaliz.ROOT_OPTION_CharacterBasedSettings, Thaliz.GetRootConfigOption(Thaliz.ROOT_OPTION_CharacterBasedSettings, Thaliz.Configuration_Default_Level))
	Thaliz.ConfigurationLevel = Thaliz.GetRootConfigOption(Thaliz.ROOT_OPTION_CharacterBasedSettings, Thaliz.Configuration_Default_Level);
	
	Thaliz.SetConfigOption(Thaliz.OPTION_ResurrectionMessageTargetChannel, Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionMessageTargetChannel, Thaliz.Target_Channel_Default))
	Thaliz.SetConfigOption(Thaliz.OPTION_ResurrectionMessageTargetWhisper, Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionMessageTargetWhisper, Thaliz.Target_Whisper_Default))
	Thaliz.SetConfigOption(Thaliz.OPTION_ResurrectionWhisperMessage, Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionWhisperMessage, Thaliz.Resurrection_Whisper_Message_Default))
	Thaliz.SetConfigOption(Thaliz.OPTION_AlwaysIncludeDefaultGroup, Thaliz.GetConfigOption(Thaliz.OPTION_AlwaysIncludeDefaultGroup, Thaliz.Include_Default_Group_Default))

	Thaliz.SetConfigOption(Thaliz.OPTION_RezButtonVisible, Thaliz.GetConfigOption(Thaliz.OPTION_RezButtonVisible, Thaliz.OPTION_RezButtonVisible_Default))

	Thaliz.SetConfigOption(Thaliz.OPTION_ResurrectionNameEnclosure, Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionNameEnclosure, "NONE"));
	Thaliz.InitializeNameEnclosures();

	Thaliz.SetConfigOption(Thaliz.OPTION_ResurrectionMessageOrder, Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionMessageOrder, "RANDOM"));
	Thaliz.UpdateMessageOrderText();

	Thaliz.SetConfigOption(Thaliz.OPTION_ResurrectionNextMessage, Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionNextMessage, "1"));
	Thaliz.ResurrectionNextMessage = Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionNextMessage, "1");

	--	Resurrection priorities:
	--	Validate this is actually a valid structure:
	local priorities = Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionPriority, Thaliz.Configuration_Default_Priority);
	if	not priorities or 
		not priorities.Druid or not priorities.Druid.Priority or
		not priorities.Hunter or not priorities.Hunter.Priority or
		not priorities.Mage or not priorities.Mage.Priority or
		not priorities.Paladin or not priorities.Paladin.Priority or
		not priorities.Priest or not priorities.Priest.Priority or
		not priorities.Rogue or not priorities.Rogue.Priority or
		not priorities.Shaman or not priorities.Shaman.Priority or
		not priorities.Warlock or not priorities.Warlock.Priority or
		not priorities.Warrior or not priorities.Warrior.Priority or
		not priorities.CurrentTarget or not priorities.CurrentTarget.Priority or
		not priorities.MasterLooter or not priorities.MasterLooter.Priority or
		not priorities.FirstWarlock or not priorities.FirstWarlock.Priority then
		priorities = Thaliz.Configuration_Default_Priority;
	end;
	Thaliz.SetConfigOption(Thaliz.OPTION_ResurrectionPriority, priorities);

	Thaliz.ClassMatrix.DRUID.priority	= priorities.Druid.Priority;
	Thaliz.ClassMatrix.HUNTER.priority	= priorities.Hunter.Priority;
	Thaliz.ClassMatrix.MAGE.priority	= priorities.Mage.Priority;
	Thaliz.ClassMatrix.PALADIN.priority= priorities.Paladin.Priority;
	Thaliz.ClassMatrix.PRIEST.priority	= priorities.Priest.Priority;
	Thaliz.ClassMatrix.ROGUE.priority	= priorities.Rogue.Priority;
	Thaliz.ClassMatrix.SHAMAN.priority	= priorities.Shaman.Priority;
	Thaliz.ClassMatrix.WARLOCK.priority= priorities.Warlock.Priority;
	Thaliz.ClassMatrix.WARRIOR.priority= priorities.Warrior.Priority;
	Thaliz.ClassMatrix.TARGET.priority	= priorities.CurrentTarget.Priority;
	Thaliz.ClassMatrix.MASTER.priority	= priorities.MasterLooter.Priority;
	Thaliz.ClassMatrix.FIRSTLOCK.priority= priorities.FirstWarlock.Priority;


	local x,y = RezButton:GetPoint();
	Thaliz.SetConfigOption(Thaliz.OPTION_RezButtonPosX, Thaliz.GetConfigOption(Thaliz.OPTION_RezButtonPosX, x))
	Thaliz.SetConfigOption(Thaliz.OPTION_RezButtonPosY, Thaliz.GetConfigOption(Thaliz.OPTION_RezButtonPosY, y))

	if Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionMessageTargetChannel) == "RAID" then
		ThalizFrameCheckbuttonRaid:SetChecked(1)
	end
	if Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionMessageTargetChannel) == "SAY" then
		ThalizFrameCheckbuttonSay:SetChecked(1)
	end
	if Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionMessageTargetChannel) == "YELL" then
		ThalizFrameCheckbuttonYell:SetChecked(1)
	end
	if Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionMessageTargetWhisper) == 1 then
		ThalizFrameCheckbuttonWhisper:SetChecked(1)
	end
	if Thaliz.GetConfigOption(Thaliz.OPTION_AlwaysIncludeDefaultGroup) == 1 then
		ThalizFrameCheckbuttonIncludeDefault:SetChecked(1)
	end
	if Thaliz.GetRootConfigOption(Thaliz.ROOT_OPTION_CharacterBasedSettings) == "Character" then
		ThalizFrameCheckbuttonPerCharacter:SetChecked(1)
	end    
	if Thaliz.GetConfigOption(Thaliz.OPTION_RezButtonVisible) == "1" then
		RezButton:Show();
	else
		RezButton:Hide()
	end
	
	Thaliz.ParseProfileNames();

	Thaliz.ValidateResurrectionMessages();
end

function Thaliz.ValidateResurrectionMessages()
	local macros = Thaliz.GetResurrectionMessages();
	local changed = False;
	
	for n=1, #macros, 1 do
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
		Thaliz.SetResurrectionMessages(macros);	
	end;
end;

function Thaliz.ParseProfileNames()
	Thaliz.ProfileTable = { };

	for realmName, realmInfo in next, Thaliz.Options do
		if type(realmInfo) == "table" then
			for playerName, playerInfo in next, realmInfo do
				if type(playerInfo) == "table" then
					local messages = playerInfo["ResurrectionMessages"];
					if messages and type(messages) == "table" and #messages > 0 then	
						local playerRealm = playerName .."-".. string.gsub(realmName, " ", "");

						tinsert(Thaliz.ProfileTable, { ["realm"] = realmName, ["name"] = playerName, ["count"] = #messages, ["fullname"] = playerRealm });
					end;
				end
			end;
		end;
	end;
end;



--[[
	Convert a msg so first letter is uppercase, and rest as lower case.
]]
function Thaliz.UCFirst(playername)
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
function Thaliz.AnnounceResurrection(playername, unitid)

	if not Thaliz.Enabled then
		return;
	end

	playername = Thaliz.lib:getFullPlayerName(playername) or Thaliz.lib:getUnitidFromName(playername);

	if not unitid then
		return;
	end

	-- 3.4.0: Supports RANDOM and SEQUENTIAL:
	local messageOrder = Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionMessageOrder, "RANDOM");

	local playershortname = Thaliz.StripRealmName(playername);
	local guildname = Thaliz.API.GetGuildInfo(unitid);
	local race = string.upper(Thaliz.API.UnitRace(unitid));
	local class = Thaliz.unitClass(unitid);
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
	
	local macros = Thaliz.GetResurrectionMessages();
	for n=1, #macros, 1 do
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
	
	-- Now generate list, using the found criteria above:
	local macros = { }
	local index = 0;
	for n=1, #gmacro, 1 do
		index = index + 1;
		macros[index] = gmacro[n];
	end
	for n=1, #nmacro, 1 do
		index = index + 1;
		macros[index] = nmacro[n];
	end
	for n=1, #cmacro, 1 do
		index = index + 1;
		macros[index] = cmacro[n];
	end
	for n=1, #rmacro, 1 do
		index = index + 1;
		macros[index] = rmacro[n];
	end;
	

	-- Include the default macro list if
	-- * No macros matching group rules, or
	-- * The "Include Default" option is selected.
	if #macros == 0 or Thaliz.GetConfigOption(Thaliz.OPTION_AlwaysIncludeDefaultGroup) == 1 then
		for n=1, #dmacro, 1 do
			index = index + 1;
			macros[index] = dmacro[n];
		end;
	end;

	
	local validMessages = {}
	local validCount = 0;
	for n=1, #macros, 1 do
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
	local enclosure = Thaliz.GetNameEnclosure(Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionNameEnclosure, "NONE"));
	if enclosure then
		playershortname = string.format(enclosure[3], playershortname);
	end;

	local selectedMessageIndex = 1;
	if messageOrder == "SEQUENTIAL" then
		--	SEQUENTIAL message order:
		--	Note: special message (for guild for example) are not taken into account:
		selectedMessageIndex = Thaliz.ResurrectionNextMessage;
		Thaliz.ResurrectionNextMessage = Thaliz.ResurrectionNextMessage + 1;
		if (selectedMessageIndex > validCount) then
			selectedMessageIndex = 1;
		end;
		if (Thaliz.ResurrectionNextMessage > validCount) then
			Thaliz.ResurrectionNextMessage = 1;
		end;
	else
		--  RANDOM message order:
		--	This prevents the same message being shown twice:
		selectedMessageIndex = random(validCount);
		if selectedMessageIndex == Thaliz.LastRandomMessageIndex then
			selectedMessageIndex = selectedMessageIndex + 1;
			if selectedMessageIndex > validCount then
				selectedMessageIndex = 1;
			end;
		end;
		Thaliz.LastRandomMessageIndex = selectedMessageIndex;
	end


	local message = validMessages[ selectedMessageIndex ];

	--	%m (male/female specific message):
	--	Syntax: "%m{male text:female text}"
	if Thaliz.API.UnitSex(unitid) == 2 then
		--	(male) Use first string
		message = string.gsub(message, "%%m\{([^:^}]*):?([^}]*)\}", "%1");
	else
		--	(female) Use second string
		message = string.gsub(message, "%%m\{([^:^}]*):?([^}]*)\}", "%2");
	end;

	message = string.gsub(message, "%%c", UCFirst(class));
	message = string.gsub(message, "%%r", UCFirst(race));
	message = string.gsub(message, "%%g", guildname);
	message = string.gsub(message, "%%s", playershortname);

	local targetChannel = Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionMessageTargetChannel);

	--	FOREVER does not allow use of SAY and YELL in addons:
	if not Thaliz.API.IsInInstance() or lib.addonExpansionLevel == 60 then
		if targetChannel == "SAY" or targetChannel == "YELL" then
			targetChannel = "RAID";
		end;
	end;
	
	if targetChannel == "RAID" then
		partyEcho(message);
	elseif targetChannel == "SAY" then
		Thaliz.API.SendChatMessage(message, SAY_CHANNEL)
	elseif targetChannel == "YELL" then
		Thaliz.API.SendChatMessage(message, YELL_CHANNEL)
	else
		echo(message);
	end
	

	if Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionMessageTargetWhisper) == 1 and not InCombatLockdown() then
		local whisperMsg = Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionWhisperMessage);
		if whisperMsg and not(whisperMsg == "") then
			Thaliz.API.SendChatMessage(whisperMsg, "WHISPER", nil, playername);
		end;
	end
end

function Thaliz.GetResurrectionMessages()
	local messages = Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionMessages, nil);

	if (not messages) or not(type(messages) == "table") or (#messages == 0) then
		messages = Thaliz.ResetResurrectionMessages(); 
	end
	
	return messages;
end

function Thaliz.RenumberTable(sourcetable)
	local index = 1;
	local temptable = { };
	
	for key, value in next, sourcetable do
		temptable[index] = value;
		index = index + 1
	end
	return temptable;
end

function Thaliz.SetResurrectionMessages(resurrectionMessages)
	Thaliz.SetConfigOption(Thaliz.OPTION_ResurrectionMessages, Thaliz.RenumberTable(resurrectionMessages));
end

function Thaliz.ResetResurrectionMessages()
	local preset = Thaliz_PresetMessages[Thaliz.DefaultPresetGroup];

	local presetMessages = preset["messages"];
	if not presetMessages or type(presetMessages) ~= "table" then return; end;

	local resurrectionMessages = { };
	for _, message in next, presetMessages do
		tinsert(resurrectionMessages, { message, EMOTE_GROUP_DEFAULT, "" });
	end;

	Thaliz.SetResurrectionMessages(resurrectionMessages);
	Thaliz_UpdateMessageList();
	
	return resurrectionMessages;
end

function Thaliz.AddResurrectionMessage(message, group, param)
	if message and not (message == "") then
		group = Thaliz.CheckGroup(group);
		param = Thaliz.CheckGroupValue(param);

		local resMsgs = Thaliz.GetResurrectionMessages();		
		resMsgs[ #resMsgs + 1] = { message, group, param }
		
		Thaliz.SetResurrectionMessages(resMsgs);
	end
end

function Thaliz.CheckMessage(msg)
	if not msg or msg == "" then
		msg = THALIZ_EMPTY_MESSAGE;
	end
	return msg;
end

function Thaliz.CheckGroup(group)
	if not group or group == "" then
		group = EMOTE_GROUP_DEFAULT;
	end
	return group;
end

function Thaliz.CheckGroupValue(param)
	if not param then
		param = "";
	end
	return param;
end

function Thaliz.UpdateResurrectionMessage(index, offset, message, group, param)
	group = Thaliz.CheckGroup(group);
	param = Thaliz.CheckGroupValue(param);

	local messages = Thaliz.GetResurrectionMessages();
	messages[index + offset] = { message, group, param }
	
	Thaliz.SetResurrectionMessages( messages );

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
function Thaliz.ScanRaid()

	if not ThalizDoScanRaid then 
		Thaliz.SetRezTargetText();
		return;
	end;

	--	Jesus, this class can't even ress!! Disable event
	if not IsResser then
		ThalizDoScanRaid = false;
		Thaliz.HideResurrectionButton();
		return;
	end

	-- Doh, 1! Can't ress while dead!
	if Thaliz.API.UnitIsDeadOrGhost("player") then
		Thaliz.SetRezTargetText();
		Thaliz.SetRezButtonTexture(Thaliz.Icon_RezBtn_Dead);
		return;
	end;

	-- Doh, 2! Can't ress while in combat. Sorry druids, you get a LUA error if you try :-(
	if Thaliz.API.UnitAffectingCombat("player") then
		Thaliz.SetRezTargetText();
		Thaliz.SetRezButtonTexture(Thaliz.Icon_RezBtn_Combat);

		if(debug) then 
			echo("**DEBUG**: UnitAffectingCombat=true");
		end;
		return;
	end;

	local groupsize = Thaliz.API.GetNumGroupMembers();
	if groupsize == 0 then
		Thaliz.HideResurrectionButton();
		return;
	end

	local grouptype = "party";
	if Thaliz.API.IsInRaid() then
		grouptype = "raid";
	end;

	local unitid;
	local warlocksAlive = false;
	for n=1, groupsize, 1 do
		unitid = grouptype..n
		if not Thaliz.API.UnitIsDeadOrGhost(unitid) and Thaliz.API.UnitIsConnected(unitid) and Thaliz.API.UnitIsVisible(unitid) and Thaliz.lib:unitClass(unitid) == "WARLOCK" then
			warlocksAlive = true;
			break;
		end
	end

	Thaliz.CleanupBlacklistedPlayers();

	local classinfo = Thaliz.GetClassInfo(lib.localPlayerClass);

	local spellnameStr = Thaliz.API.GetSpellName(classinfo["spellid"]);

	local PriorityToCurrentTarget = Thaliz.ClassMatrix.TARGET.priority;			-- Prio over all if target i selected
	local PriorityToMasterLooter  = Thaliz.ClassMatrix.MASTER.priority;			-- Prio above ressers if master looter
	local PriorityToFirstWarlock  = Thaliz.ClassMatrix.FIRSTLOCK.priority;		-- Prio below ressers if no warlocks are alive


	--Fetch current assigned target (if any):
	local currentPrio = 0;
	local highestPrio = 0;
	local currentIsValid = false;
	local currentTarget = "";
	unitid = RezButton:GetAttribute("unit");
	if unitid then
		currentTarget = Thaliz.lib:getPlayerAndRealm(unitid);
	end;

	local masterLooter = nil;
	if Thaliz.API.IsInRaid() then
		local lootMethod, _, raidIndex = Thaliz.API.GetLootMethod();
		if lootMethod == 2 then
			masterLooter = Thaliz.lib:getPlayerAndRealm("raid"..raidIndex);
		end;
	end;

	local targetprio;
	local corpseTable = { };
	local playername, classinfo, targetname, isBlacklisted;
	for n=1, groupsize, 1 do
		unitid = grouptype..n
		playername = Thaliz.lib:getPlayerAndRealm(unitid);
		isBlacklisted = false;

		for b=1, #blacklistedTable, 1 do
			blacklistInfo = blacklistedTable[b];
			blacklistTick = blacklistInfo[2];
			
			if blacklistInfo[1] == playername then
				isBlacklisted = true;
				break;
			end
		end
		
		targetname = Thaliz.lib:getPlayerAndRealm("playertarget");

		if (isBlacklisted == false) and 
			Thaliz.API.UnitIsDeadOrGhost(unitid) and 
			not Thaliz.API.UnitHasIncomingResurrection(unitid) and 
			Thaliz.API.UnitIsConnected(unitid) and 
			Thaliz.API.UnitIsVisible(unitid) and 
			Thaliz.API.IsSpellInRange(spellnameStr, unitid) 
		then
			classinfo = Thaliz.GetClassInfo(Thaliz.lib:unitClass(unitid));
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
			corpseTable[#corpseTable + 1 ] = { unitid, targetprio } ;
		end
	end	

	if #corpseTable == 0 then
		Thaliz.HideResurrectionButton();
		return;
	end

	if highestPrio > currentPrio then
		currentIsValid = false;
	end;


	if not currentIsValid then
		-- We found someone (or a new person) to ress.
		-- Sort the corpses with highest priority in top:
		Thaliz.SortTableDescending(corpseTable, 2);

		unitid = corpseTable[1][1];

		if not Thaliz.API.InCombatLockdown() then
			RezButton:SetAttribute("unit", unitid);
			RezButton:SetAttribute("type", "spell");
			RezButton:SetAttribute("spell", spellnameStr);
		end;
	end;

	Thaliz.SetRezTargetText(Thaliz.lib:getPlayerAndRealm(unitid));
	Thaliz.SetRezButtonTexture(Icon_RezBtn_Active, true);
end;


function Thaliz_OnRezClick(self)
	local buttonName = Thaliz.API.GetMouseButtonClicked();
	if buttonName == "RightButton" then
		Thaliz.OpenConfigurationDialogue();
	else
		Thaliz.BroadcastResurrection(self);
	end;
end;


function Thaliz.BroadcastResurrection(self)
	local unitid = self:GetAttribute("unit");
	if not unitid then 
		return; 
	end;

	Thaliz.lib:sendAddonMessage(string.format("TX_RESBEGIN#%s#", Thaliz.lib:getPlayerAndRealm(unitid)));
end;


function Thaliz.SetRezTargetText(playername)
	if not playername then
		playername = "";
	end;

	RezButton.title:SetText(playername);
end;


function Thaliz.HideResurrectionButton()
	if not Thaliz.API.InCombatLockdown() then	
		Thaliz.SetRezButtonTexture(Thaliz.Icon_RezBtn_Passive);
		RezButton:SetAttribute("type", nil);
		RezButton:SetAttribute("unit", nil);
	end;
	Thaliz.SetRezTargetText();
end;


function Thaliz.InitializeClassSpecificStuff()
	local classname = Thaliz.lib.localPlayerClass;

	Thaliz.Icon_RezBtn_Passive = THALIZ_ICON_OTHER_PASSIVE;
	Thaliz.Icon_RezBtn_Active = THALIZ_ICON_OTHER_PASSIVE;
	if classname == "DRUID" then
		IsDruid = true;
		IsResser = true;
		Thaliz.Icon_RezBtn_Passive = THALIZ_ICON_DRUID_PASSIVE;
		Thaliz.Icon_RezBtn_Active = THALIZ_ICON_DRUID_ACTIVE;
	elseif classname == "MONK" then
		IsMonk = true;
		IsResser = true;
		Thaliz.Icon_RezBtn_Passive = THALIZ_ICON_MONK_PASSIVE;
		Thaliz.Icon_RezBtn_Active = THALIZ_ICON_MONK_ACTIVE;
	elseif classname == "PALADIN" then
		IsPaladin = true;
		IsResser = true;
		Thaliz.Icon_RezBtn_Passive = THALIZ_ICON_PALADIN_PASSIVE;
		Thaliz.Icon_RezBtn_Active = THALIZ_ICON_PALADIN_ACTIVE;
	elseif classname == "PRIEST" then
		IsPriest = true;
		IsResser = true;
		Thaliz.Icon_RezBtn_Passive = THALIZ_ICON_PRIEST_PASSIVE;
		Thaliz.Icon_RezBtn_Active = THALIZ_ICON_PRIEST_ACTIVE;
	elseif classname == "SHAMAN" then
		IsShaman = true;
		IsResser = true;
		Thaliz.Icon_RezBtn_Passive = THALIZ_ICON_SHAMAN_PASSIVE;
		Thaliz.Icon_RezBtn_Active = THALIZ_ICON_SHAMAN_ACTIVE;
	end;

	if not IsResser then
		Thaliz.OPTION_RezButtonVisible_Default = "0";
	end;
end;

Thaliz.RezButtonLastTexture = "";
function Thaliz.SetRezButtonTexture(textureName, isEnabled)
	local alphaValue = 0.5;
	if isEnabled then
		alphaValue = 1.0;
	end;

	if Thaliz.RezButtonLastTexture ~= textureName and not Thaliz.API.InCombatLockdown() then	
		Thaliz.RezButtonLastTexture = textureName;
		RezButton:SetAlpha(alphaValue);
		RezButton:SetNormalTexture(textureName);		
	end;
end;


function Thaliz.GetClassInfo(classname)
	return Thaliz.ClassMatrix[string.upper(classname)];
end



--  *******************************************************
--
--	Blacklisting functions
--
--  *******************************************************

--[[
	Blacklist specific player.
]]
function Thaliz.BlacklistPlayer(playername, blacklistTime)
	if not blacklistTime then
		blacklistTime = Thaliz.BlacklistTimeout;
	end;

	local timerTick = GetTimerTick();

	if Thaliz.IsPlayerBlacklisted(playername) then
		-- Player is already blacklisted; if the current blacklist time is higher than 
		-- the remaining blacklist value, we need to replace the current time with the
		-- requested time.
		for b=1, #blacklistedTable, 1 do
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
		blacklistedTable[ #blacklistedTable + 1 ] = { playername, timerTick + blacklistTime };
	end
end

--[[
	Remove player from Blacklist (if any)
]]
function Thaliz.WhitelistPlayer(playername)
	local WhitelistTable = { }

	for n=1, #blacklistedTable, 1 do
		blacklistInfo = blacklistedTable[n];
		if not (playername == blacklistInfo[1]) then
			WhitelistTable[ #WhitelistTable + 1 ] = blacklistInfo;
		end
	end
	blacklistedTable = WhitelistTable;
end


function Thaliz.IsPlayerBlacklisted(playername)
	Thaliz.CleanupBlacklistedPlayers();

	for n=1, #blacklistedTable, 1 do		 
		if blacklistedTable[n][1] == playername then
			return true;
		end
	end
	return false;
end


function Thaliz.CleanupBlacklistedPlayers()
	local BlacklistedTableNew = {}
	local blacklistInfo;	
	local timerTick = Thaliz.GetTimerTick();
	
	for n=1, #blacklistedTable, 1 do
		blacklistInfo = blacklistedTable[n];
		if timerTick < blacklistInfo[2] then
			BlacklistedTableNew[ #BlacklistedTableNew + 1 ] = blacklistInfo;
		end
	end
	blacklistedTable = BlacklistedTableNew;
end



--  *******************************************************
--
--	Helper functions
--
--  *******************************************************
function Thaliz.StripRealmName(playername)
	return string.gsub(playername, "(.*)-.*", "%1");
end;

function Thaliz.SortTableDescending(sourcetable, index)
	local doSort = true
	while doSort do
		doSort = false
		for n=1, #sourcetable - 1, 1 do
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
function Thaliz.OnGroupRosterUpdate(event, ...)
	if THALIZ_CURRENT_VERSION > 0 and not THALIZ_UPDATE_MESSAGE_SHOWN then
		if Thaliz.API.IsInRaid() or Thaliz.lib:isInParty() then
			Thaliz.lib:sendAddonMessage(string.format("TX_VERCHECK#%s#", lib.addonVersion));
		end
	end
end

function Thaliz.CheckIsNewVersion(versionstring)
	local incomingVersion = Thaliz.lib:calculateVersion( versionstring );

	if (THALIZ_CURRENT_VERSION > 0 and incomingVersion > 0) then
		if incomingVersion > THALIZ_CURRENT_VERSION then
			if not THALIZ_UPDATE_MESSAGE_SHOWN then
				THALIZ_UPDATE_MESSAGE_SHOWN = true;
				Thaliz.lib:echo(string.format("NOTE: A newer version of ".. Thaliz.lib.chatColorHot .."THALIZ".. Thaliz.lib.chatColorNormal .."! is available (version %s)!", versionstring));
				Thaliz.lib:echo("You can download latest version from https://www.curseforge.com/ or https://github.com/Sentilix/thaliz-classic.");
			end
		end	
	end
end


--  *******************************************************
--
--	Timer functions
--
--  *******************************************************
Thaliz.Timers = {}
Thaliz.TimerTick = 0
Thaliz.NextScanTime = 0;

function Thaliz_OnTimer(elapsed)
	Thaliz.TimerTick = Thaliz.TimerTick + elapsed

	if Thaliz.TimerTick > (Thaliz.NextScanTime + Thaliz.ScanFrequency) then
		Thaliz.ScanRaid();
		Thaliz.NextScanTime = Thaliz.TimerTick;
	end;
end

function Thaliz.GetTimerTick()
	return Thaliz.TimerTick;
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
function Thaliz.HandleTXVersion(message, sender)
	Thaliz.lib:sendAddonMessage("RX_VERSION#".. lib.addonVersion .."#"..sender)
end

function Thaliz.HandleTXResBegin(message, sender)
	-- Blacklist target unless ress was initated by me
	if not (sender == Thaliz.API.UnitName("player")) then
		--echo(string.format("*** Remote blacklisting %s (%s is ressing)", message, sender));
		Thaliz.BlacklistPlayer(message);
	end
end

--[[
	A version response (RX) was received. The version information is displayed locally.
]]
function Thaliz.HandleRXVersion(message, sender)
	Thaliz.lib:echo(string.format("[%s] is using Thaliz version %s", sender, message))
end

function Thaliz.HandleTXVerCheck(message, sender)
	Thaliz.CheckIsNewVersion(message);
end

function Thaliz.OnChatMsgAddon(event, ...)
	local prefix, msg, channel, sender = ...;

	if prefix == Thaliz.lib.addonPrefix then
		Thaliz.HandleThalizMessage(msg, sender);
	end
end

function Thaliz.GetMyRealm()
	local realmname = Thaliz.API.GetRealmName();
	
	if string.find(realmname, " ") then
		local _, _, name1, name2 = string.find(realmname, "([a-zA-Z]*) ([a-zA-Z]*)");
		realmname = name1 .. name2; 
	end;

	return realmname;
end;

function Thaliz.HandleThalizMessage(msg, sender)
	local _, _, cmd, message, recipient = string.find(msg, "([^#]*)#([^#]*)#([^#]*)");	

	--	Ignore message if it is not for me. 
	--	Receipient can be blank, which means it is for everyone.
	if recipient ~= "" then
		-- Note: recipient comes with realmname. We need to compare
		-- with realmname too, even GetUnitName() does not return one:
		recipient = Thaliz.lib:getFullPlayerName(recipient);

		if recipient ~= lib.localPlayerName then
			return
		end
	end


	if cmd == "TX_VERSION" then
		Thaliz.HandleTXVersion(message, sender)
	elseif cmd == "RX_VERSION" then
		Thaliz.HandleRXVersion(message, sender)
	elseif cmd == "TX_RESBEGIN" then
		Thaliz.HandleTXResBegin(message, sender)
	elseif cmd == "TX_VERCHECK" then
		Thaliz.HandleTXVerCheck(message, sender)
	end
end

function Thaliz.BeginsWith(String, Start)
   return string.sub(String, 1, string.len(Start)) == Start;
end


function Thaliz.IsResurrectionSpell(spellId)
	local resSpell = false;

	if spellId then
		local incRessName = Thaliz.API.GetSpellName(spellId);

		local classinfo = Thaliz.ClassMatrix[Thaliz.lib.localPlayerClass];

		local classRessName = "";
		if classinfo["spellid"] then
			classRessName = Thaliz.API.GetSpellName(classinfo["spellid"]);
		end;

		resSpell = (incRessName == classRessName);
	end;

	return resSpell;
end;


--[[
	Return # of seconds left of blacklist timer, nil if not blacklisted
--]]
function Thaliz.IsPlayerBlacklisted(playername)

	for b=1, #blacklistedTable, 1 do
		local blacklistInfo = blacklistedTable[b];
		if blacklistInfo[1] == playername then
			return (blacklistInfo[2] - TimerTick);
		end
	end
	return nil;
end;


Thaliz.CurrentRessedTarget = nil;
function Thaliz.ClearCurrentResurrectedTarget()
	Thaliz.SetCurrentResurrectedTarget(nil);
end;

function Thaliz.GetCurrentResurrectedTarget()
	return CurrentRessedTarget;
end;

function Thaliz.SetCurrentResurrectedTarget(target)
	CurrentRessedTarget = target;
end;


--[[
	UI events
--]]

function Thaliz_OKButton_OnClick()
	if Thaliz.API.InCombatLockdown() then
		return;
	end;

	Thaliz.CloseConfigurationDialogue();
	
	local whisperMsg = _G["ThalizFrameWhisper"]:GetText(whisperMsg);
	Thaliz.SetConfigOption(Thaliz.OPTION_ResurrectionWhisperMessage, whisperMsg);
	
	Thaliz.ConfigurationLevel = Thaliz.GetRootConfigOption(Thaliz.ROOT_OPTION_CharacterBasedSettings, Thaliz.Configuration_Default_Level);
end

function Thaliz_ProfileButton_OnClick()
	if Thaliz.API.InCombatLockdown() then
		return;
	end;

	if msgEditorIsOpen then
		Thaliz_CloseMsgEditorButton_OnClick();
	end;

	ThalizProfileFrame:Show();
end;

function Thaliz_PresetButton_OnClick()
	if Thaliz.API.InCombatLockdown() then
		return;
	end;

	if msgEditorIsOpen then
		Thaliz_CloseMsgEditorButton_OnClick();
	end;

	ThalizPresetFrame:Show();
end;

function Thaliz_PriorityButton_OnClick()
	if Thaliz.API.InCombatLockdown() then
		return;
	end;

	if msgEditorIsOpen then
		Thaliz_CloseMsgEditorButton_OnClick();
	end;

	Thaliz.UpdatePriorityFrameValues();

	ThalizPriorityFrame:Show();
end;

function Thaliz.UpdatePriorityFrameValues()
	ThalizPriorityFrameDruid:SetValue(Thaliz.ClassMatrix.DRUID.priority);
	ThalizPriorityFrameHunter:SetValue(Thaliz.ClassMatrix.HUNTER.priority);
	ThalizPriorityFrameMage:SetValue(Thaliz.ClassMatrix.MAGE.priority);
	ThalizPriorityFramePaladin:SetValue(Thaliz.ClassMatrix.PALADIN.priority);
	ThalizPriorityFramePriest:SetValue(Thaliz.ClassMatrix.PRIEST.priority);
	ThalizPriorityFrameRogue:SetValue(Thaliz.ClassMatrix.ROGUE.priority);
	ThalizPriorityFrameShaman:SetValue(Thaliz.ClassMatrix.SHAMAN.priority);
	ThalizPriorityFrameWarlock:SetValue(Thaliz.ClassMatrix.WARLOCK.priority);
	ThalizPriorityFrameWarrior:SetValue(Thaliz.ClassMatrix.WARRIOR.priority);

	ThalizPriorityFrameTarget:SetValue(Thaliz.ClassMatrix.TARGET.priority);
	ThalizPriorityFrameMaster:SetValue(Thaliz.ClassMatrix.MASTER.priority);
	ThalizPriorityFrameFirstLock:SetValue(Thaliz.ClassMatrix.FIRSTLOCK.priority);
end;



function ThalizPriorityFrame_OnPriorityChanged(object, className)
	local value = math.floor(object:GetValue());

	value = (math.floor(value / 5)) * 5;
	object:SetValueStep(5);
	object:SetValue(value);

	local uClassName = string.upper(className);
	if value ~= Thaliz.ClassMatrix[uClassName].priority then
		Thaliz.ClassMatrix[uClassName].priority = value;

		local priorities = Thaliz.Configuration_Default_Priority;
		priorities.Druid.Priority			= Thaliz.ClassMatrix.DRUID.priority;
		priorities.Hunter.Priority			= Thaliz.ClassMatrix.HUNTER.priority;
		priorities.Mage.Priority			= Thaliz.ClassMatrix.MAGE.priority;
		priorities.Paladin.Priority			= Thaliz.ClassMatrix.PALADIN.priority;
		priorities.Priest.Priority			= Thaliz.ClassMatrix.PRIEST.priority;
		priorities.Rogue.Priority			= Thaliz.ClassMatrix.ROGUE.priority;
		priorities.Shaman.Priority			= Thaliz.ClassMatrix.SHAMAN.priority;
		priorities.Warlock.Priority			= Thaliz.ClassMatrix.WARLOCK.priority;
		priorities.Warrior.Priority			= Thaliz.ClassMatrix.WARRIOR.priority;
		priorities.CurrentTarget.Priority	= Thaliz.ClassMatrix.TARGET.priority;
		priorities.MasterLooter.Priority	= Thaliz.ClassMatrix.MASTER.priority;
		priorities.FirstWarlock.Priority	= Thaliz.ClassMatrix.FIRSTLOCK.priority;
		Thaliz.SetConfigOption(Thaliz.OPTION_ResurrectionPriority, priorities);
	end;
	
	_G['ThalizPriorityFrame'..className..'Percent']:SetText(string.format('%s %%', value));
end;

function Thaliz_CloseButton_OnClick()
	if Thaliz.API.InCombatLockdown() then
		return;
	end;

	if msgEditorIsOpen then
		Thaliz_CloseMsgEditorButton_OnClick();
	elseif profileFrameIsOpen then
		Thaliz_CloseProfileButton_OnClick();
	elseif presetFrameIsOpen then
		Thaliz_ClosePresetButton_OnClick();
	elseif priorityFrameIsOpen then
		Thaliz_ClosePriorityButton_OnClick();
	else
		Thaliz.CloseConfigurationDialogue();
	end;
end

function Thaliz_CloseProfileButton_OnClick()
	if Thaliz.API.InCombatLockdown() then
		return;
	end;

	ThalizProfileFrame:Hide();
	profileFrameIsOpen = false;
end;

function Thaliz_ClosePresetButton_OnClick()
	if Thaliz.API.InCombatLockdown() then
		return;
	end;

	ThalizPresetFrame:Hide();
	presetFrameIsOpen = false;
end;

function Thaliz_ClosePriorityButton_OnClick()
	if Thaliz.API.InCombatLockdown() then
		return;
	end;

	ThalizPriorityFrame:Hide();
	priorityFrameIsOpen = false;
end;

function Thaliz_CloseMsgEditorButton_OnClick()
	if Thaliz.API.InCombatLockdown() then
		return;
	end;

	ThalizMsgEditorFrame:Hide();
	msgEditorIsOpen = false;
end

function Thaliz_DropDownNameEnclosureButton_OnClick(self, arg1, arg2, checked)
	if arg1 then
		Thaliz.SetConfigOption(Thaliz.OPTION_ResurrectionNameEnclosure, arg1);
	end;

	Thaliz.UpdateNameEnclosureText();
end;

function Thaliz.UpdateNameEnclosureText()
	local enclosure = Thaliz.GetNameEnclosure(Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionNameEnclosure, "NONE"));
	if enclosure then		
		UIDropDownMenu_SetText(DropDownNameEnclosureButton, enclosure[2]);
	end;
end;

function Thaliz.GetNameEnclosure(optionname)
	local enclosure = nil;

	for n=1, #THALIZ_NAME_ENCLOSURES, 1 do
		if THALIZ_NAME_ENCLOSURES[n][1] == optionname then
			enclosure = THALIZ_NAME_ENCLOSURES[n];
			break;
		end;
	end;	
	
	return enclosure;
end;

function Thaliz_DropDownMessageOrderButton_OnClick(self, arg1, arg2, checked)
	if arg1 then
		Thaliz.SetConfigOption(Thaliz.OPTION_ResurrectionMessageOrder, arg1);
	end;

	Thaliz.UpdateMessageOrderText();
end;

function Thaliz.UpdateMessageOrderText()
	local msgOrder = Thaliz.GetMessageOrder(Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionMessageOrder, "RANDOM"));
	if msgOrder then
		UIDropDownMenu_SetText(DropDownMessageOrderButton, msgOrder[2]);
	end;
end;

function Thaliz.GetMessageOrder(optionname)
	local msgOrder = nil;

	for n=1, #THALIZ_MESSAGE_ORDERS, 1 do
		if THALIZ_MESSAGE_ORDERS[n][1] == optionname then
			msgOrder = THALIZ_MESSAGE_ORDERS[n];
			break;
		end;
	end;	
	
	return msgOrder;
end;

function Thaliz_RepositionateButton(self)
	if Thaliz.API.InCombatLockdown() then
		return;
	end;

	local x, y = self:GetLeft(), self:GetTop() - UIParent:GetHeight();
		
	Thaliz.SetConfigOption(Thaliz.OPTION_RezButtonPosX, x);
	Thaliz.SetConfigOption(Thaliz.OPTION_RezButtonPosY, y);

	RezButton:SetSize(THALIZ_REZBUTTON_SIZE, THALIZ_REZBUTTON_SIZE);

	local classinfo = Thaliz.GetClassInfo(Thaliz.lib.localPlayerClass);
	if classinfo["spellid"] then
		RezButton:Show();
	else
		RezButton:Hide();
	end;
end


local Thaliz_SkipTaintCheck = true;
local Thaliz_delayed_owner = nil;

function Thaliz_DropDownProfiles_Initialize(frame, level, menuList)
	UIDropDownMenu_SetWidth(DropDownProfileButton, 300);

	for index=1, #Thaliz.ProfileTable, 1 do
		local profile = Thaliz.ProfileTable[index];

		local info = UIDropDownMenu_CreateInfo();
		info.text			= string.format("%s - %s (%d)", profile["realm"], profile["name"], profile["count"]);
		info.func			= function() Thaliz_DropDownProfiles_OnClick(this, profile) end;
		UIDropDownMenu_AddButton(info);
	end
end;

function Thaliz_DropDownPresets_Initialize(frame, level, menuList)
	UIDropDownMenu_SetWidth(DropDownPresetButton, 300);

	for index=1, #Thaliz_PresetMessages, 1 do
		local preset = Thaliz_PresetMessages[index];

		local info = UIDropDownMenu_CreateInfo();
		info.text			= string.format("%s - %s", preset["name"], preset["description"]);
		info.func			= function() Thaliz_DropDownPreset_OnClick(this, preset) end;
		UIDropDownMenu_AddButton(info);
	end;
end;

function Thaliz_DropDownProfiles_OnClick(sender, profile)
	Thaliz.SelectedImportProfile = profile;
	UIDropDownMenu_SetText(DropDownProfileButton, string.format("%s - %s (%d)", profile["realm"], profile["name"], profile["count"]));
	Thaliz.RefreshProfileButtons();
end;

function Thaliz_DropDownPreset_OnClick(sender, preset)
	Thaliz.SelectedImportPreset = preset;
	UIDropDownMenu_SetText(DropDownPresetButton, string.format("%s - %s", preset["name"], preset["description"]));
	Thaliz.RefreshPresetButtons();
end;

function Thaliz.InitializeNameEnclosures()
	local playername = Thaliz.API.UnitName('Player');
	for n=1, #THALIZ_NAME_ENCLOSURES, 1 do
		THALIZ_NAME_ENCLOSURES[n][2] = string.format(THALIZ_NAME_ENCLOSURES[n][2], playername);
	end;

	Thaliz.UpdateNameEnclosureText();
end;

function Thaliz.DropDownNameEnclosure_Initialize(frame, level, menuList)
	local CurOption = Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionNameEnclosure, "NONE");

	for n=1, #THALIZ_NAME_ENCLOSURES, 1 do
		local checked = false;
		if CurOption == THALIZ_NAME_ENCLOSURES[n][1] then 
			checked = true;
		end;

		local info = UIDropDownMenu_CreateInfo();
		info.func       = Thaliz_DropDownNameEnclosureButton_OnClick;
		info.arg1		= THALIZ_NAME_ENCLOSURES[n][1];
		info.text       = THALIZ_NAME_ENCLOSURES[n][2];
		UIDropDownMenu_AddButton(info);
	end
end

function Thaliz.DropDownMessageOrder_Initialize(frame, level, menuList)
	local CurOption = Thaliz.GetConfigOption(Thaliz.OPTION_ResurrectionMessageOrder, "RANDOM");

	for n=1, #THALIZ_MESSAGE_ORDERS, 1 do
		local checked = false;
		if CurOption == THALIZ_MESSAGE_ORDERS[n][1] then 
			checked = true;
		end;

		local info = UIDropDownMenu_CreateInfo();
		info.func       = Thaliz_DropDownMessageOrderButton_OnClick;
		info.arg1		= THALIZ_MESSAGE_ORDERS[n][1];
		info.text       = THALIZ_MESSAGE_ORDERS[n][2];
		UIDropDownMenu_AddButton(info);
	end
end



--[[
	Profile functions
--]]

function Thaliz.RefreshProfileButtons()
	if Thaliz.API.InCombatLockdown() then
		return;
	end;

	local profileText = UIDropDownMenu_GetText(DropDownProfileButton) or "";

	if profileText == "" then
		ReplaceWithProfileButton:Disable();
		MergeWithProfileButton:Disable();
	else
		ReplaceWithProfileButton:Enable();
		MergeWithProfileButton:Enable();
	end;
end;

function Thaliz.RefreshPresetButtons()
	if Thaliz.API.InCombatLockdown() then
		return;
	end;

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
	Thaliz.ImportProfile();
end;

function Thaliz_ReplaceWithPreset_OnClick()
	Thaliz.ImportPreset();
end;

function Thaliz_MergeWithProfile_OnClick()
	Thaliz.ImportProfile(true);
end;

function Thaliz_MergeWithPreset_OnClick()
	Thaliz.ImportPreset(true);
end;

function Thaliz.ImportProfile(keepExistingMessages)
	if not Thaliz.SelectedImportProfile then return; end;
	local profile = Thaliz.SelectedImportProfile;

	if not Thaliz.Options[profile["realm"]] then return; end;
	if not Thaliz.Options[profile["realm"]][profile["name"]] then return; end;
	local importedMessages = Thaliz.Options[profile["realm"]][profile["name"]]["ResurrectionMessages"];
	if not importedMessages or type(importedMessages) ~= "table" then return; end;

	local resurrectionMessages = { };
	if keepExistingMessages then
		resurrectionMessages = Thaliz.GetResurrectionMessages();
	end;

	--	Check if we already have this macro in our list:
	local messageAddedCounter = 0;
	for _, importMessage in next, importedMessages do

		--	Sanity check: in case original table is borken:
		if	type(importMessage) == "table" and 
			#importMessage >= 3 and 
			#importMessage <= 4 and 
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
		Thaliz.SetResurrectionMessages(resurrectionMessages);
		if keepExistingMessages then
			Thaliz.lib:echo(string.format("%d message(s) was merged from %s's profile.", messageAddedCounter, profile["fullname"]));
		else
			Thaliz.lib:echo(string.format("%d message(s) was imported from %s's profile.", messageAddedCounter, profile["fullname"]));
		end;

		Thaliz_UpdateMessageList();
	else
		Thaliz.lib:echo(string.format("No messages was imported from %s's profile.", profile["fullname"]));
	end;
end;

function Thaliz.ImportPreset(keepExistingMessages)
	if not Thaliz.SelectedImportPreset then return; end;
	local preset = Thaliz.SelectedImportPreset;

	local presetMessages = preset["messages"];
	if not presetMessages or type(presetMessages) ~= "table" then return; end;

	local resurrectionMessages = { };
	if keepExistingMessages then
		resurrectionMessages = Thaliz.GetResurrectionMessages();
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
		Thaliz.SetResurrectionMessages(resurrectionMessages);
		if keepExistingMessages then
			Thaliz.lib:echo(string.format("%d message(s) was merged from presets.", messageAddedCounter));
		else
			Thaliz.lib:echo(string.format("%d message(s) was imported from presets.", messageAddedCounter));
		end;

		Thaliz_UpdateMessageList();
	else
		Thaliz.lib:echo("No messages was imported from preset.");
	end;
end;



--  *******************************************************
--
--	Event handlers
--
--  *******************************************************

local SpellcastIsStarted = 0;
function Thaliz_OnEvent(self, event, ...)
	local timerTick = Thaliz.GetTimerTick();

	if (event == "ADDON_LOADED") then
		local addonname = ...;
		if addonname == Thaliz.lib.addonName then
		    Thaliz.InitializeConfigSettings();
		end

	elseif (event == "UNIT_SPELLCAST_SENT") then
		local resser, target, _, spellId = ...;
		if(resser == "player") then
			if (target ~= "Unknown") then
				if not Thaliz.IsPlayerBlacklisted(target) then
					if Thaliz.IsResurrectionSpell(spellId) then
						Thaliz.SetCurrentResurrectedTarget(target);
						Thaliz.BlacklistPlayer(target, Thaliz.BlacklistResurrectionTimeout);
						Thaliz.AnnounceResurrection(target);
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
			Thaliz.ClearCurrentResurrectedTarget();
		end;

	elseif(event == "UNIT_SPELLCAST_STOP") then
		local resser, _, _, _ = ...;
		if(resser ~= "player") then
			return;
		end;

		local target = Thaliz.GetCurrentResurrectedTarget();
		if target then
			Thaliz.WhitelistPlayer(target);
			Thaliz.ClearCurrentResurrectedTarget();
		end;

	elseif(event == "UNIT_SPELLCAST_FAILED") then
		Thaliz.ClearCurrentResurrectedTarget();

	elseif (event == "INCOMING_RESURRECT_CHANGED") then
		local arg1 = ...;

		local timeDiff = timerTick - SpellcastIsStarted;

		if (timeDiff < 0.001) and Thaliz.API.UnitIsGhost(arg1) then
			SpellcastIsStarted = timerTick;
			if Thaliz.API.IsInRaid() then
				if Thaliz.BeginsWith(arg1, 'raid') then
					Thaliz.SetCurrentResurrectedTarget(Thaliz.lib:getPlayerAndRealm(arg1));
				end;
			else
				if Thaliz.BeginsWith(arg1, 'party') then
					Thaliz.SetCurrentResurrectedTarget(Thaliz.lib:getPlayerAndRealm(arg1));
				end;
			end;

			local target = Thaliz.GetCurrentResurrectedTarget();
			if target then
				if Thaliz.IsPlayerBlacklisted(target) then
					Thaliz.lib:echo(string.format("Note: [%s] is already being resurrected.", target));
				else
					Thaliz.BlacklistPlayer(target, Thaliz.BlacklistSpellcastTime);
					Thaliz.AnnounceResurrection(target, arg1);
				end;
			end;
		end;

	elseif (event == "CHAT_MSG_ADDON") then
		Thaliz.OnChatMsgAddon(event, ...)

	elseif (event == "GROUP_ROSTER_UPDATE") then
		Thaliz.OnGroupRosterUpdate(event, ...)

	elseif (event == "COMBAT_LOG_EVENT_UNFILTERED") then
		--	SHOOSH!!! This one will haunt me in Forever!!
		if Thaliz.lib.addonExpansionLevel == 60 then
			--	Forever will not return anything usefull :-/
			return;
		end;

		local _, subevent, _, _, sourceName, _, _, _, destName, _, _, spellId = CombatLogGetCurrentEventInfo();

		if (subevent == "SPELL_CAST_START") then
			if (sourceName == Thaliz.lib.localPlayerName) then
				if Thaliz.IsResurrectionSpell(spellId) then
					SpellcastIsStarted = timerTick;
				end;
			end

		elseif subevent == "SPELL_RESURRECT" then
			if sourceName ~= Thaliz.lib.localPlayerName then
				Thaliz.BlacklistPlayer(destName, Thaliz.BlacklistResurrectionTimeout);
			end;
		end
	end
end

function Thaliz_OnLoad()
	msgEditorIsOpen = false;

	THALIZ_CURRENT_VERSION = Thaliz.lib:calculateVersion(Thaliz.lib.addonVersion);

	_G["ThalizVersionString"]:SetText(string.format("Thaliz version %s by %s", Thaliz.lib.addonVersion, Thaliz.lib.addonAuthor));

	Thaliz.lib:echo(string.format("Type %s/thaliz%s to configure the addon, or right-click the Thaliz button.", Thaliz.lib.chatColorHot, Thaliz.lib.chatColorNormal));

    ThalizEventFrame:RegisterEvent("ADDON_LOADED");
    ThalizEventFrame:RegisterEvent("CHAT_MSG_ADDON");
    ThalizEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
    ThalizEventFrame:RegisterEvent("UNIT_SPELLCAST_SENT");
	ThalizEventFrame:RegisterEvent("INCOMING_RESURRECT_CHANGED");
    ThalizEventFrame:RegisterEvent("UNIT_SPELLCAST_START");
    ThalizEventFrame:RegisterEvent("UNIT_SPELLCAST_STOP");
    ThalizEventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED");
    ThalizEventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");

	if Thaliz.lib.addonExpansionLevel < 60 then
		ThalizEventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	end;


	Thaliz.API.RegisterAddonMessagePrefix(Thaliz.lib.addonPrefix);

	Thaliz.InitializeClassSpecificStuff();
    Thaliz.InitializeListElements();
	Thaliz.RefreshProfileButtons();


	Thaliz_RepositionateButton(RezButton);
end


local frame = CreateFrame("Frame", "ThalizEventFrame")

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        
        if addonName == "Thaliz" then
            self:UnregisterEvent("ADDON_LOADED")
            
            -- HERE IS WHO CALLS IT NOW!
            if Thaliz_OnLoad then 
                Thaliz_OnLoad(self) 
            end
        end
    elseif Thaliz_OnEvent then
        Thaliz_OnEvent(self, event, ...)
    end
end)

frame:SetScript("OnUpdate", function(self, elapsed)
    if Thaliz_OnTimer then Thaliz_OnTimer(elapsed) end
end)


