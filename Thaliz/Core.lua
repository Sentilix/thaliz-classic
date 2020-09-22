--[[
Author:			Mimma @ <EU-Pyrewood Village>
Create Date:	2015-05-10 17:50:57

The latest version of Thaliz can always be found at:
(tbd)

The source code can be found at Github:
https://github.com/Sentilix/thaliz-classic

Please see the ReadMe.txt for addon details.
]]

Thaliz = LibStub("AceAddon-3.0"):NewAddon("Thaliz", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Thaliz", true)

local PARTY_CHANNEL							= "PARTY"
local RAID_CHANNEL							= "RAID"
local YELL_CHANNEL							= "YELL"
local SAY_CHANNEL							= "SAY"
local WARN_CHANNEL							= "RAID_WARNING"
local GUILD_CHANNEL							= "GUILD"
local CHAT_END								= "|r"
local COLOUR_BEGINMARK						= "|c80"
local COLOUR_CHAT							= COLOUR_BEGINMARK.."40A0F8"
local COLOUR_INTRO							= COLOUR_BEGINMARK.."B040F0"
local THALIZ_NAME							= "Thaliz"
local THALIZ_TITAN_TITLE					= "Thaliz - Ress dem deads!"
local THALIZ_MESSAGE_PREFIX					= "Thalizv1"
local CTRA_PREFIX							= "CTRA"
local THALIZ_MAX_MESSAGES					= 200
local THALIZ_MAX_VISIBLE_MESSAGES			= 20
local THALIZ_EMPTY_MESSAGE					= "(Empty)"

local THALIZ_CURRENT_VERSION				= 0
local THALIZ_UPDATE_MESSAGE_SHOWN			= false

local EMOTE_GROUP_DEFAULT					= "Default";
local EMOTE_GROUP_GUILD						= "Guild";
local EMOTE_GROUP_CHARACTER					= "Name";
local EMOTE_GROUP_CLASS						= "Class";
local EMOTE_GROUP_RACE						= "Race";

--	List of valid class names with priority and resurrection spell name (if any)
--	classname, priority, ress spellname
local classInfo = {
	{ "Druid",   40, L["Rebirth"]			},
	{ "Hunter",  30, nil					},
	{ "Mage",    40, nil					},
	{ "Paladin", 50, L["Redemption"]		},
	{ "Priest",  50, L["Resurrection"]		},
	{ "Rogue",   10, nil					},
	{ "Shaman",  50, L["Ancestral Spirit"]	},
	{ "Warlock", 30, nil					},
	{ "Warrior", 20, nil					}
};



local IsPaladin = false;
local IsPriest = false;
local IsShaman = false;
local IsDruid = false;
local IsResser = false;

local THALIZ_RezBtn_Passive			= "";
local THALIZ_RezBtn_Active			= "";
local THALIZ_RezBtn_Combat			= "Interface\\Icons\\Ability_dualwield";
local THALIZ_RezBtn_Dead			= "Interface\\Icons\\Ability_rogue_feigndeath";

local THALIZ_ICON_OTHER_PASSIVE		= "Interface\\Icons\\INV_Misc_Gear_01";
local THALIZ_ICON_DRUID_PASSIVE		= "Interface\\Icons\\INV_Misc_Monsterclaw_04";
local THALIZ_ICON_DRUID_ACTIVE		= "Interface\\Icons\\spell_holy_resurrection";
local THALIZ_ICON_PALADIN_PASSIVE	= "Interface\\Icons\\INV_Hammer_01";
local THALIZ_ICON_PALADIN_ACTIVE	= "Interface\\Icons\\spell_holy_resurrection";
local THALIZ_ICON_PRIEST_PASSIVE	= "Interface\\Icons\\INV_Staff_30";
local THALIZ_ICON_PRIEST_ACTIVE		= "Interface\\Icons\\spell_holy_resurrection";
local THALIZ_ICON_SHAMAN_PASSIVE	= "Interface\\Icons\\INV_Jewelry_Talisman_04";
local THALIZ_ICON_SHAMAN_ACTIVE		= "Interface\\Icons\\spell_holy_resurrection";


local PriorityToFirstWarlock  = 45;     -- Prio below ressers if no warlocks are alive
local PriorityToGroupLeader   = 45;     -- Prio below ressers if raid leader or assistant
local PriorityToCurrentTarget = 100;	-- Prio over all if target is selected

-- List of blacklisted (already ressed) people
local blacklistedTable = {}
-- Corpses are blacklisted for 40 seconds (10 seconds cast time + 30 seconds waiting) as default
local Thaliz_Blacklist_Spellcast = 10;
local Thaliz_Blacklist_Resurrect = 30;
local Thaliz_Blacklist_Timeout = Thaliz_Blacklist_Spellcast + Thaliz_Blacklist_Resurrect;

local Thaliz_Enabled = true;
local ThalizConfigDialogOpen = false;
local ThalizDoScanRaid = true;
local ThalizScanFrequency = 0.2;		-- Scan 5 times per second

-- Configuration constants:
local Thaliz_Configuration_Default_Level				= "Character";	-- Can be "Character" or "Realm"
local Thaliz_Target_Channel_Default						= "RAID";
local Thaliz_Target_Whisper_Default						= "0";
local Thaliz_Resurrection_Whisper_Message_Default		= "Resurrection incoming in 10 seconds!";
local Thaliz_Include_Default_Group_Default				= "1";

local Thaliz_ConfigurationLevel							= Thaliz_Configuration_Default_Level;

local Thaliz_ROOT_OPTION_CharacterBasedSettings			= "CharacterBasedSettings";
local Thaliz_OPTION_ResurrectionMessageTargetChannel	= "ResurrectionMessageTargetChannel";
local Thaliz_OPTION_ResurrectionMessageTargetWhisper	= "ResurrectionMessageTargetWhisper";
local Thaliz_OPTION_AlwaysIncludeDefaultGroup			= "AlwaysIncludeDefaultGroup";
local Thaliz_OPTION_ResurrectionWhisperMessage			= "ResurrectionWhisperMessage";
local Thaliz_OPTION_ResurrectionMessages				= "ResurrectionMessages";
local Thaliz_OPTION_RezButtonPosX						= "RezButtonPosX";
local Thaliz_OPTION_RezButtonPosY						= "RezButtonPosY";

local Thaliz_DebugFunction = nil;

-- Persisted information:
Thaliz_Options = { }


-- List of resurrection messages
--	{ "Message", "Group", "Group parameter value" }
local Thaliz_DefaultResurrectionMessages = {
	-- UBRS
	{ "(Ressing) THIS CANNOT BE!!! %s, deal with these insects.",		EMOTE_GROUP_DEFAULT, "" },	-- Rend Blackhand (UBRS)
	-- ZG
	{ "(Ressing) I\'m keeping my eye on you, %s!",						EMOTE_GROUP_DEFAULT, "" },	-- Bloodlord Mandokir (Raptor boss)
	{ "(Ressing) %s, fill me with your RAGE!",							EMOTE_GROUP_DEFAULT, "" },	-- High Priest Thekal (Tiger boss)
	{ "(Ressing) Fleeing will do you no good, %s!",						EMOTE_GROUP_DEFAULT, "" },	-- Hakkar
	-- AQ20
	{ "(Ressing) Master %c %s, continue the fight!",					EMOTE_GROUP_DEFAULT, "" },	-- General Rajaxx
	-- MC
	{ "(Ressing) Perhaps you'll need another lesson in pain, %s!",		EMOTE_GROUP_DEFAULT, "" },	-- Majordomo Executus
	{ "(Ressing) Too soon, %s - you have died too soon!",				EMOTE_GROUP_DEFAULT, "" },	-- Ragnaros
	{ "(Ressing) You have failed me, %s! Justice is met, indeed!",		EMOTE_GROUP_DEFAULT, "" }, 	-- Ragnaros
	-- BWL
	{ "(Ressing) Forgive me %s, your death only adds to my failure.",	EMOTE_GROUP_DEFAULT, "" },	-- Vaelastrasz
	-- AQ40
	{ "(Ressing) Let your death serve as an example, %s!",				EMOTE_GROUP_DEFAULT, "" },	-- Prophet Skeram
	{ "(Ressing) Only flesh and bone. %cs are such easy prey, %s!",		EMOTE_GROUP_DEFAULT, "" },	-- Emperor Vek'lor (Twins)
	{ "(Ressing) Your friends will abandon you, %s!",					EMOTE_GROUP_DEFAULT, "" },	-- C'Thun
	-- Naxx
	{ "(Ressing) Shhh, %s... it will all be over soon.",				EMOTE_GROUP_DEFAULT, "" },	-- Anub'Rekhan
	{ "(Ressing) Slay %s in the masters name!",							EMOTE_GROUP_DEFAULT, "" },	-- Grand Widow Faerlina
	{ "(Ressing) Rise, %s! Rise and fight once more!",					EMOTE_GROUP_DEFAULT, "" },	-- Noth the Plaguebringer
	{ "(Ressing) You should have stayed home, %s!",						EMOTE_GROUP_DEFAULT, "" },	-- Instructor Razuvious
	{ "(Ressing) Death is the only escape, %s.",						EMOTE_GROUP_DEFAULT, "" },	-- Gothik the Harvester
	{ "(Ressing) The first res goes to %s! Anyone care to wager?",		EMOTE_GROUP_DEFAULT, "" },	-- Lady Blaumeux (4HM)
	{ "(Ressing) No more play, %s?",									EMOTE_GROUP_DEFAULT, "" },	-- Patchwerk
	{ "(Ressing) %s, you are too late... I... must... OBEY!",			EMOTE_GROUP_DEFAULT, "" } 	-- Thaddius
}

local function Thaliz_GetOptions()
	return  {
		type = "group",
		args = {
			config = {
				name = "Configuration",
				desc = "Show/Hide configuration options",
				type = "toggle",
				guiHidden = true,
				set = Thaliz_ToggleConfigurationDialogue,
				get = function (value) return ThalizConfigDialogOpen end,
			},
			channel = {
				name = "Target channel",
				desc = "Channel where the announcements will be send",
				type = "select",
				values = { NONE = "None", RAID = "Raid/Party", SAY = "Say", YELL = "Yell" },
				set = function (info, value) Thaliz_SetOption(Thaliz_OPTION_ResurrectionMessageTargetChannel, value) end,
				get = function (value) return Thaliz_GetOption(Thaliz_OPTION_ResurrectionMessageTargetChannel) end,
			},
			debug = {
				name = "Debug",
				desc = "Debug a Thaliz method",
				type = "input",
				pattern = "(%S*)",
				hidden = true,
				set = function (info, value)
					if value and value ~= '' then
						Thaliz_Echo(string.format("Enabling debug for %s", value))
						ThalizScanFrequency = 1.0
						Thaliz_DebugFunction = value
					else
						Thaliz_Echo("Disabling debug")
						ThalizScanFrequency = 0.2
						Thaliz_DebugFunction = nil
					end
				end,
			},
			enabled = {
				name = "Resurrection announcements",
				desc = "Enable/Disable resurrection announcements",
				type = "toggle",
				set = function(info, value)
					Thaliz_Enabled = not Thaliz_Enabled

					if Thaliz_Enabled then
						Thaliz_Echo("Resurrection announcements has been enabled.")
					else
						Thaliz_Echo("Resurrection announcements has been disabled.")
					end
				end,
				get = function (value) return Thaliz_Enabled end,
			},
			version = {
				name = "Version",
				desc = "Displays Thaliz version",
				type = "execute",
				guiHidden = true,
				func = function()
					if IsInRaid() or Thaliz_IsInParty() then
						Thaliz_SendAddonMessage("TX_VERSION##")
					else
						Thaliz_Echo(string.format("%s is using Thaliz version %s", UnitName("player"), GetAddOnMetadata("Thaliz", "Version")))
					end
				end
			}
		}
	}
end


function Thaliz:OnInitialize()
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Thaliz", Thaliz_GetOptions(), { "thaliz" })
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Thaliz")
end

function Thaliz:OnEnable()
    -- Called when the addon is enabled
end

function Thaliz:OnDisable()
    -- Called when the addon is disabled
end


--[[
	Echo a message for the local user only.
]]
local function echo(msg)
	if msg then
		DEFAULT_CHAT_FRAME:AddMessage(COLOUR_CHAT .. msg .. CHAT_END)
	end
end

--[[
	Echo in raid chat (if in raid) or party chat (if not)
]]
local function partyEcho(msg)
	if IsInRaid() then
		SendChatMessage(msg, RAID_CHANNEL)
	elseif Thaliz_IsInParty() then
		SendChatMessage(msg, PARTY_CHANNEL)
	end
end

--[[
	Echo a message for the local user only, including Thaliz "logo"
]]
function Thaliz_Echo(msg)
	echo("<"..COLOUR_INTRO.."THALIZ"..COLOUR_CHAT.."> "..msg);
end


--  *******************************************************
--
--	Configuration functions
--
--  *******************************************************

function Thaliz_ToggleConfigurationDialogue()
	-- LibStub("AceConfigDialog-3.0"):Open("Thaliz")
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
	ThalizConfigDialogOpen = false;
	ThalizMsgEditorFrame:Hide();
	ThalizFrame:Hide();
end


function Thaliz_RefreshVisibleMessageList(offset)
--	echo(string.format("Thaliz_RefreshVisibleMessageList: Offset=%d", offset));
	local macros = Thaliz_GetResurrectionMessages();

	-- Set a priority on each spell, and then sort them accordingly:
	local macro, grp, prm, prio
	for n=1, table.getn(macros), 1 do
		grp = macros[n][2];
		prm = macros[n][3];
		if grp == EMOTE_GROUP_GUILD then
			prio = 20
		elseif grp == EMOTE_GROUP_CHARACTER then
			prio = 30
		elseif grp == EMOTE_GROUP_CLASS then
			-- Class names are listed alphabetically:
			prio = 50
			if prm == "Druid" then
				prio = 59
			elseif prm == "Hunter" then
				prio = 58
			elseif prm == "Mage" then
				prio = 57
			elseif prm == "Paladin" then
				prio = 56
			elseif prm == "Priest" then
				prio = 55
			elseif prm == "Rogue" then
				prio = 54
			elseif prm == "Shaman" then
				prio = 53
			elseif prm == "Warlock" then
				prio = 52
			elseif prm == "Warrior" then
				prio = 51
			end;
		elseif grp == EMOTE_GROUP_RACE then
			prio = 40
			-- Racess are listed by faction, race name:
			if prm == "Dwarf" then
				prio = 49
			elseif prm == "Gnome" then
				prio = 48
			elseif prm == "Human" then
				prio = 47
			elseif prm == "Night Elf" then
				prio = 46
			elseif prm == "Orc" then
				prio = 45
			elseif prm == "Tauren" then
				prio = 44
			elseif prm == "Troll" then
				prio = 43
			elseif prm == "Undead" then
				prio = 42
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

			if prm == "DRUID" then
				prmColor = { 1.00, 0.49, 0.04 }
			elseif prm == "HUNTER" then
				prmColor = { 0.67, 0.83, 0.45 }
			elseif prm == "MAGE" then
				prmColor = { 0.41, 0.80, 0.94 }
			elseif prm == "PALADIN" then
				prmColor = { 0.96, 0.55, 0.73 }
			elseif prm == "PRIEST" then
				prmColor = { 1.00, 1.00, 1.00 }
			elseif prm == "ROGUE" then
				prmColor = { 1.00, 0.96, 0.41 }
			elseif prm == "SHAMAN" then
				prmColor = { 0.96, 0.55, 0.73 }
			elseif prm == "WARLOCK" then
				prmColor = { 0.58, 0.51, 0.79 }
			elseif prm == "WARRIOR" then
				prmColor = { 0.78, 0.61, 0.43 }
			end;
		elseif grp == EMOTE_GROUP_RACE then
			grpColor = { 0.80, 0.80, 0.00 }
			if prm == "DWARF" or prm == "GNOME" or prm == "HUMAN"  or prm == "NIGHT ELF" then
				grpColor = { 0.00, 0.50, 1.00 }
			elseif prm == "ORC" or prm == "TAUREN" or prm == "TROLL"  or prm == "UNDEAD" then
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
		else
			prm = Thaliz_UCFirst(prm)
		end;
	end

	--echo(string.format("Saving, ID=%d, Offset=%d, Msg=%s, Grp=%s, Val=%s", currentObjectId, offset, msg, grp, prm));
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
		Thaliz_options = { };
	end

	Thaliz_SetRootOption(Thaliz_ROOT_OPTION_CharacterBasedSettings, Thaliz_GetRootOption(Thaliz_ROOT_OPTION_CharacterBasedSettings, Thaliz_Configuration_Default_Level))
	Thaliz_ConfigurationLevel = Thaliz_GetRootOption(Thaliz_ROOT_OPTION_CharacterBasedSettings, Thaliz_Configuration_Default_Level);

	Thaliz_SetOption(Thaliz_OPTION_ResurrectionMessageTargetChannel, Thaliz_GetOption(Thaliz_OPTION_ResurrectionMessageTargetChannel, Thaliz_Target_Channel_Default))
	Thaliz_SetOption(Thaliz_OPTION_ResurrectionMessageTargetWhisper, Thaliz_GetOption(Thaliz_OPTION_ResurrectionMessageTargetWhisper, Thaliz_Target_Whisper_Default))
	Thaliz_SetOption(Thaliz_OPTION_ResurrectionWhisperMessage, Thaliz_GetOption(Thaliz_OPTION_ResurrectionWhisperMessage, Thaliz_Resurrection_Whisper_Message_Default))
	Thaliz_SetOption(Thaliz_OPTION_AlwaysIncludeDefaultGroup, Thaliz_GetOption(Thaliz_OPTION_AlwaysIncludeDefaultGroup, Thaliz_Include_Default_Group_Default))

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

function Thaliz_GetUnitID(playername)
	local groupsize, grouptype;

	groupsize = GetNumGroupMembers();
	if IsInRaid() then
		grouptype = "raid";
	else
		grouptype = "party";
	end;

	for n=1, groupsize, 1 do
		unitid = grouptype..n
		if UnitName(unitid) == playername then
			return unitid;
		end
	end

	return nil;
end

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

	if not unitid then
		unitid = Thaliz_GetUnitID(playername);

		if not unitid then
			return;
		end
	end

	local guildname = GetGuildInfo(unitid);
	local race = string.upper(UnitRace(unitid));
	local classname = string.upper(Thaliz_UnitClass(unitid));
	local charname = string.upper(playername);

	if guildname then
		UCGuildname = string.upper(guildname);
	else
		-- Note: guildname is unfortunately not detected for released corpses.
		guildname = "(No Guild)";
		UCGuildname = "";
	end;

	--echo(string.format("Ressing: player=%s, unitid=%s", playername, unitid));
	--echo(string.format("Guild=%s, class=%s, race=%s", guildname, class, race));

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
			if param == classname then
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

	local message = validMessages[ random(validCount) ];
	message = string.gsub(message, "%%c", Thaliz_UCFirst(classname));
	message = string.gsub(message, "%%r", Thaliz_UCFirst(race));
	message = string.gsub(message, "%%g", guildname);
	message = string.gsub(message, "%%s", playername);

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
	Thaliz_SetResurrectionMessages( Thaliz_DefaultResurrectionMessages );

	return Thaliz_DefaultResurrectionMessages;
end

function Thaliz_AddResurrectionMessage(message, group, param)
	if message and not (message == "") then
		group = Thaliz_CheckGroup(group);
		param = Thaliz_CheckGroupValue(param);

		--echo(string.format("Adding Res.Msg: msg=%s, grp=%s, val=%s", message, group, param));

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
	--echo(string.format("Updating message, Index=%d, offset=%d, msg=%s, grp=%s, val=%s", index, offset, message, group, param));

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

	classinfo = Thaliz_GetClassinfo(Thaliz_UnitClass("player"));
	local spellname = classinfo[3];

	local grouptype = "party";
	if IsInRaid() then
		grouptype = "raid";
	end;

	local unitid;
	local warlocksAlive = false;
	for n=1, groupsize, 1 do
		unitid = grouptype..n
		if not UnitIsDead(unitid) and UnitIsConnected(unitid) and UnitIsVisible(unitid) and Thaliz_UnitClass(unitid) == "WARLOCK" then
			warlocksAlive = true;
			break;
		end
	end

	Thaliz_CleanupBlacklistedPlayers();

	--Fetch current assigned target (if any):
	local currentPrio = 0;
	local highestPrio = 0;
	local currentIsValid = false;
	local currentTarget = "";
	unitid = RezButton:GetAttribute("unit");
	if unitid then
		currentTarget = UnitName(unitid);
	end;

	local targetprio;
	local corpseTable = { };
	local playername, classinfo;
	for n=1, groupsize, 1 do
		unitid = grouptype..n
		playername = UnitName(unitid)

		local isBlacklisted = false;
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

		targetname = UnitName("playertarget");

		if (isBlacklisted == false) and
				UnitIsDead(unitid) and
				(UnitHasIncomingResurrection(unitid) == false) and
				UnitIsConnected(unitid) and
				UnitIsVisible(unitid) and
				(IsSpellInRange(spellname, unitid) == 1) then
			classinfo = Thaliz_GetClassinfo(Thaliz_UnitClass(unitid));
			targetprio = classinfo[2];
			if targetname and targetname == playername then
				targetprio = PriorityToCurrentTarget;
			end

--	IsRaidLeader(): removed in wow 5.0 and thereby Classic!
--			if IsRaidLeader(playername) and targetprio < PriorityToGroupLeader then
--				targetprio = PriorityToGroupLeader;
--			end
			if not warlocksAlive and classinfo[1] == "Warlock" then
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
			if not spellname then spellname = "nil"; end;
			echo(string.format("**DEBUG**: corpse=%s, unitid=%s, spell=%s", UnitName(unitid), unitid, spellname));
		end;

		RezButton:SetAttribute("type", "spell");
		RezButton:SetAttribute("spell", spellname);
		RezButton:SetAttribute("unit", unitid);
	end;

	Thaliz_SetRezTargetText(UnitName(unitid));
	Thaliz_SetButtonTexture(THALIZ_RezBtn_Active, true);
end;


function Thaliz_OnRezClick(self)
	Thaliz_BroadcastResurrection(self);
end;


function Thaliz_BroadcastResurrection(self)
	local unitid = self:GetAttribute("unit");
	if not unitid then
		return;
	end;

	local playername = UnitName(unitid);

	Thaliz_SendAddonMessage(string.format("TX_RESBEGIN#%s#", playername));
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
	local debug = (Thaliz_DebugFunction and Thaliz_DebugFunction == "Thaliz_Init");
	local classname = Thaliz_UnitClass("player");

	if(debug) then
		if not classname then classname = "nil"; end;
		echo(string.format("**DEBUG**: [Thaliz_InitClassSpecificStuff] classname=%s", classname));
	end;


	THALIZ_RezBtn_Passive = THALIZ_ICON_OTHER_PASSIVE;
	THALIZ_RezBtn_Active = THALIZ_ICON_OTHER_PASSIVE;
	if classname == "DRUID" then
		IsDruid = true;
		IsResser = true;
		THALIZ_RezBtn_Passive = THALIZ_ICON_DRUID_PASSIVE;
		THALIZ_RezBtn_Active = THALIZ_ICON_DRUID_ACTIVE;
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
	local debug = (Thaliz_DebugFunction and Thaliz_DebugFunction == "Thaliz_GetClassinfo");

	classname = Thaliz_UCFirst(classname);
	for key, val in next, classInfo do
		if val[1] == classname then
			if(debug) then
				if not classname then classname = "nil"; end;
				echo(string.format("**DEBUG**: classname=%s, info=True", classname));
			end;

			return val;
		end
	end

	if(debug) then
		if not classname then classname = "nil"; end;
		echo(string.format("**DEBUG**: classname=%s, info=False", classname));
	end;

	return nil;
end



--  *******************************************************
--
--	Blacklisting functions
--
--  *******************************************************
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
	local WhitelistTable = {}
	--echo("Whitelisting "..playername);

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
function Thaliz_GetPlayerName(nameAndRealm)
	local _, _, name = string.find(nameAndRealm, "([^-]*)-%s*");
	if not name then
		name = nameAndRealm;
	end;

	return name;
end;

function Thaliz_IsInParty()
	if not IsInRaid() then
		return ( GetNumGroupMembers() > 0 );
	end
	return false
end

function Thaliz_UnitClass(unitid)
	local _, classname = UnitClass(unitid);
	return classname;
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
function Thaliz_OnRaidRosterUpdate(event, ...)
	if THALIZ_CURRENT_VERSION > 0 and not THALIZ_UPDATE_MESSAGE_SHOWN then
		if IsInRaid() or Thaliz_IsInParty() then
			local versionstring = GetAddOnMetadata("Thaliz", "Version");
			Thaliz_SendAddonMessage(string.format("TX_VERCHECK#%s#", versionstring));
		end
	end
end

function Thaliz_CalculateVersion(versionString)
	local _, _, major, minor, patch = string.find(versionString, "([^\.]*)\.([^\.]*)\.([^\.]*)");
	local version = 0;

	if (tonumber(major) and tonumber(minor) and tonumber(patch)) then
		version = major * 100 + minor;
		--echo(string.format("major=%s, minor=%s, patch=%s, version=%d", major, minor, patch, version));
	end

	return version;
end

function Thalix_CheckIsNewVersion(versionstring)
	local incomingVersion = Thaliz_CalculateVersion( versionstring );

	if (THALIZ_CURRENT_VERSION > 0 and incomingVersion > 0) then
		if incomingVersion > THALIZ_CURRENT_VERSION then
			if not THALIZ_UPDATE_MESSAGE_SHOWN then
				THALIZ_UPDATE_MESSAGE_SHOWN = true;
				Thaliz_Echo(string.format("NOTE: A newer version of ".. COLOUR_INTRO .."THALIZ"..COLOUR_CHAT.."! is available (version %s)!", versionstring));
				Thaliz_Echo("NOTE: Go to https://github.com/Sentilix/thaliz-classic to download latest version.");
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

	for n=1,table.getn(Timers),1 do
		local timer = Timers[n]
		if TimerTick > timer[2] then
			Timers[n] = nil
			timer[1]()
		end
	end
end

function Thaliz_GetTimerTick()
	return TimerTick;
end





--  *******************************************************
--
--	Internal Communication Functions
--
--  *******************************************************

function Thaliz_SendAddonMessage(message)
	local memberCount = GetNumGroupMembers();
	if memberCount > 0 then
		local channel = nil;
		if IsInRaid() then
			channel = "RAID";
		elseif Thaliz_IsInParty() then
			channel = "PARTY";
		end;
		C_ChatInfo.SendAddonMessage(THALIZ_MESSAGE_PREFIX, message, channel);
	end;
end



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
	local response = GetAddOnMetadata("Thaliz", "Version")
	Thaliz_SendAddonMessage("RX_VERSION#"..response.."#"..sender)
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
	Thaliz_Echo(string.format("%s is using Thaliz version %s", sender, message))
end

function Thaliz_HandleTXVerCheck(message, sender)
	Thalix_CheckIsNewVersion(message);
end

function Thaliz_OnChatMsgAddon(event, ...)
	local prefix, msg, channel, sender = ...;
	if prefix == THALIZ_MESSAGE_PREFIX then
		Thaliz_HandleThalizMessage(msg, Thaliz_GetPlayerName(sender));
	end
end

function Thaliz_HandleThalizMessage(msg, sender)
	local _, _, cmd, message, recipient = string.find(msg, "([^#]*)#([^#]*)#([^#]*)");

	--	Ignore message if it is not for me.
	--	Receipient can be blank, which means it is for everyone.
	if not (recipient == "") then
		if not (recipient == UnitName("player")) then
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
		spellId = 1 * spellId;

		if IsPriest then
			--Resurrection, rank 1=2006, 2=2010, 3=10880, 4=10881, 5=20770:
			if (spellId == 2006) or (spellId == 2010) or (spellId == 10880) or (spellId == 10881) or (spellId == 20770) then
				resSpell = true;
			end;
		elseif IsPaladin then
			if (spellId == 7328) or (spellId == 10322) or (spellId == 10324) or (spellId == 20772) or (spellId == 20773) then
				resSpell = true;
			end;
		elseif IsShaman then
			--Ancestral Spirit, rank 1=2008, 2=20609, 3=20610, 4=20776, 5=20777:
			if (spellId == 2008) or (spellId == 20609) or (spellId == 20610) or (spellId == 20776) or (spellId == 20777) then
				resSpell = true;
			end;
		elseif IsDruid then
			--Rebirth, rank 1=20484, 2=20739, 3=20742, 4=20747, 5=20748:
			if (spellId == 20484) or (spellId == 20739) or (spellId == 20742) or (spellId == 20747) or (spellId == 20748) then
				resSpell = true;
			end;
		end;
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


--  *******************************************************
--
--	Event handlers
--
--  *******************************************************

local SpellcastIsStarted = 0;
function Thaliz_OnEvent(self, event, ...)
	local debug = (Thaliz_DebugFunction and Thaliz_DebugFunction == "Thaliz_OnEvent");

	if (event == "ADDON_LOADED") then
		local addonname = ...;
		if addonname == "Thaliz" then
		    Thaliz_InitializeConfigSettings();
		end
	elseif (event == "UNIT_SPELLCAST_SENT") then
		local resser, target, _, spellId = ...;
		if(resser == "player") then
			if (target ~= "Unknown") then
				if(debug) then
					echo(string.format("**DEBUG**: UNIT_SPELLCAST_SENT, SpellId=%s", spellId));
				end;
				if not Thaliz_IsPlayerBlacklisted(target) then
					if Thaliz_SpellIsResurrect(spellId) then
						Thaliz_BlacklistPlayer(target);
						Thaliz_AnnounceResurrection(target);
					end;
				end;
			end;
		end;

	elseif (event == "UNIT_SPELLCAST_START") then
		SpellcastIsStarted = TimerTick;
		if(debug) then
			echo(string.format("**DEBUG**: UNIT_SPELLCAST_START,sc=%d", SpellcastIsStarted));
		end;

	elseif (event == "UNIT_SPELLCAST_STOP") then
		SpellcastIsStarted = 0;
		if(debug) then
			echo(string.format("**DEBUG**: UNIT_SPELLCAST_STOP,sc=%d", SpellcastIsStarted));
		end;

	elseif (event == "INCOMING_RESURRECT_CHANGED") then
		local arg1 = ...;
		local target = nil;

		-- Hack: we assume this is someone ressing; we can't see the spellId on the event!
		local timeDiff = TimerTick - SpellcastIsStarted;
		if(debug) then
			echo(string.format("**DEBUG**: INCOMING_RESURRECT_CHANGED,sc=%d, td=%f", SpellcastIsStarted, timeDiff));
		end;

		if (timeDiff < 0.001) and UnitIsGhost(arg1) then
			if(debug) then
				echo("**DEBUG**: INCOMING_RESURRECT_CHANGED,starting");
			end;

			SpellcastIsStarted = 0;
			if IsInRaid() then
				if Thaliz_BeginsWith(arg1, 'raid') then
					target = UnitName(arg1);
				end;
			else
				if Thaliz_BeginsWith(arg1, 'party') then
					target = UnitName(arg1);
				end;
			end;

			if target then
				if(debug) then
					echo(string.format("**DEBUG**: INCOMING_RESURRECT_CHANGED,casting, tg=%s", target));
				end;

				if not Thaliz_IsPlayerBlacklisted(target) then
					Thaliz_BlacklistPlayer(target, 10);
					Thaliz_AnnounceResurrection(target, arg1);
				end;
			end;
		end;

	elseif (event == "CHAT_MSG_ADDON") then
		Thaliz_OnChatMsgAddon(event, ...)

	elseif (event == "RAID_ROSTER_UPDATE") then
		Thaliz_OnRaidRosterUpdate(event, ...)

	elseif (event == "COMBAT_LOG_EVENT_UNFILTERED") then
		local _, subevent, _, _, sourceName, _, _, _, destName = CombatLogGetCurrentEventInfo();

		if subevent == "SPELL_RESURRECT" then
			if sourceName ~= UnitName("player") then
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
	THALIZ_CURRENT_VERSION = Thaliz_CalculateVersion( GetAddOnMetadata("Thaliz", "Version") );

	_G["ThalizVersionString"]:SetText(string.format("Thaliz version %s by %s", GetAddOnMetadata("Thaliz", "Version"), GetAddOnMetadata("Thaliz", "Author")));

	Thaliz_Echo(string.format("version %s by %s", GetAddOnMetadata("Thaliz", "Version"), GetAddOnMetadata("Thaliz", "Author")));
    ThalizEventFrame:RegisterEvent("ADDON_LOADED");
    ThalizEventFrame:RegisterEvent("CHAT_MSG_ADDON");
    ThalizEventFrame:RegisterEvent("RAID_ROSTER_UPDATE");
    ThalizEventFrame:RegisterEvent("UNIT_SPELLCAST_START");
    ThalizEventFrame:RegisterEvent("UNIT_SPELLCAST_STOP");
    ThalizEventFrame:RegisterEvent("UNIT_SPELLCAST_SENT");
	ThalizEventFrame:RegisterEvent("INCOMING_RESURRECT_CHANGED");
	ThalizEventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");

	C_ChatInfo.RegisterAddonMessagePrefix(THALIZ_MESSAGE_PREFIX);

	Thaliz_InitClassSpecificStuff();
    Thaliz_InitializeListElements();

	Thaliz_RepositionateButton(RezButton);
end

function Thaliz_RepositionateButton(self)
	local x, y = self:GetLeft(), self:GetTop() - UIParent:GetHeight();

	Thaliz_SetOption(Thaliz_OPTION_RezButtonPosX, x);
	Thaliz_SetOption(Thaliz_OPTION_RezButtonPosY, y);
end

function Thaliz_OKButton_OnClick()
	Thaliz_CloseConfigurationDialogue();
	msgEditorIsOpen = false;

	local whisperMsg = _G["ThalizFrameWhisper"]:GetText(whisperMsg);
	Thaliz_SetOption(Thaliz_OPTION_ResurrectionWhisperMessage, whisperMsg);

	Thaliz_ConfigurationLevel = Thaliz_GetRootOption(Thaliz_ROOT_OPTION_CharacterBasedSettings, Thaliz_Configuration_Default_Level);
end

function Thaliz_CloseButton_OnClick()
	if msgEditorIsOpen then
		Thaliz_CloseMsgEditorButton_OnClick();
	else
		Thaliz_CloseConfigurationDialogue();
	end;
end

function Thaliz_CloseMsgEditorButton_OnClick()
	ThalizMsgEditorFrame:Hide();
	msgEditorIsOpen = false;
end
