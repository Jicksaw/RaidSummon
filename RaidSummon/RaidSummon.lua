RaidSummon = LibStub("AceAddon-3.0"):NewAddon("RaidSummon", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0", "AceComm-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("RaidSummon", true)

--set options
local options = {
	name = "RaidSummon",
	handler = RaidSummon,
	type = "group",
	args = {
		options = {
			type = "group",
			name = L["OptionGroupOptionsName"],
			order = 10,
			inline = true,
			args = {
				whisper = {
					type = "toggle",
					name = L["OptionWhisperName"],
					desc = L["OptionWhisperDesc"],
					get = "GetOptionWhisper",
					set = "SetOptionWhisper",
					order = 11,
				},
				zone = {
					type = "toggle",
					name = L["OptionZoneName"],
					desc = L["OptionZoneDesc"],
					get = "GetOptionZone",
					set = "SetOptionZone",
					order = 12,
				},
			}
		},
		commands = {
			type = "group",
			name = L["OptionGroupCommandsName"],
			order = 20,
			inline = true,
			args = {
				toggle = {
					type = "execute",
					name = L["OptionToggleName"],
					desc = L["OptionToggleDesc"],
					func = "ExecuteToggle",
					order = 21,
				},
				list = {
					type = "execute",
					name = L["OptionListName"],
					desc = L["OptionListDesc"],
					func = "ExecuteList",
					order = 22,
				},
				clear = {
					type = "execute",
					name = L["OptionClearName"],
					desc = L["OptionClearDesc"],
					func = "ExecuteClear",
					order = 23,
				},
				addall = {
					type = "execute",
					name = L["OptionAddAllName"],
					desc = L["OptionAddAllDesc"],
					func = "ExecuteAddAll",
					order = 24,
				},
				add = {
					type = "input",
					name = L["OptionAddName"],
					desc = L["OptionAddDesc"],
					set = "SetOptionAdd",
					multiline = false,
					order = 25,
				},
				remove = {
					type = "input",
					name = L["OptionRemoveName"],
					desc = L["OptionRemoveDesc"],
					set = "SetOptionRemove",
					multiline = false,
					guiHidden = true,
					order = 26,
				},
				removesel = {
					type = "select",
					name = L["OptionRemoveName"],
					desc = L["OptionRemoveDesc"],
					set = "SetOptionRemove",
					values = "ValuesRemoveSel",
					style = "dropdown",
					order = 27,
				},
			},
		},
		keywords = {
			type = "group",
			name = L["OptionGroupKeywordsName"],
			order = 30,
			inline = true,
			args = {
				kwdescription = {
					type = "description",
					name = L["OptionKWDescription"],
					order = 31,
				},
				kwlist = {
					type = "execute",
					name = L["OptionKWListName"],
					desc = L["OptionKWListDesc"],
					func = "ExecuteKWList",
					order = 32,
				},
				kwadd = {
					type = "input",
					name = L["OptionKWAddName"],
					desc = L["OptionKWAddDesc"],
					set = "SetKWAdd",
					multiline = false,
					order = 33,
				},
				kwremove = {
					type = "input",
					name = L["OptionKWRemoveName"],
					desc = L["OptionKWRemoveDesc"],
					set = "SetKWRemove",
					order = 34,
					guiHidden = true,
				},
				kwremovesel = {
					type = "select",
					name = L["OptionKWRemoveName"],
					desc = L["OptionKWRemoveDesc"],
					values = "ValuesKWRemoveSel",
					style = "dropdown",
					set = "SetKWRemoveSel",
					order = 35,
				},
			},
		},
		help = {
			type = "execute",
			name = L["OptionHelpName"],
			desc = L["OptionHelpDesc"],
			func = "ExecuteHelp",
			guiHidden = true,
		},
		config = {
			type = "execute",
			name = L["OptionConfigName"],
			desc = L["OptionConfigDesc"],
			func = "ExecuteConfig",
			guiHidden = true,
		},
	},
}

--set default options
local defaults = {
	profile = {
		whisper = false,
		zone = false,
		keywordsinit = false
	}
}

function RaidSummon:OnEnable()
	self:Print(L["AddonEnabled"](GetAddOnMetadata("RaidSummon", "Version"), GetAddOnMetadata("RaidSummon", "Author")))
	self:RegisterEvent("GROUP_JOINED", "GroupEvent")
	self:RegisterEvent("GROUP_LEFT", "GroupEvent")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("CHAT_MSG_RAID", "msgParser")
	self:RegisterEvent("CHAT_MSG_RAID_LEADER", "msgParser")
	
	--Right Click Hook
	local className, classFilename, classID = UnitClass("player")
	if classFilename == "WARLOCK" then
		self:SecureHook("UnitPopup_ShowMenu")
	end

end

function RaidSummon:OnDisable()
	self:Print(L["AddonDisabled"])
	RaidSummonSyncList = RaidSummonLinkedList:New()
end

function RaidSummon:OnInitialize()

	self.db = LibStub("AceDB-3.0"):New("RaidSummonOptionsDB", defaults, true)
	self.db.RegisterCallback(self, "OnNewProfile", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
	
	--frame needed to open it via /rs config
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(L["RaidSummon"], options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(L["RaidSummon"], L["RaidSummon"])

	--Commands
	--LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("RaidSummonCommands", options.args.commands)
	--LibStub("AceConfigDialog-3.0"):AddToBlizOptions("RaidSummonCommands", options.args.commands.name, "RaidSummon")
	
	--Profile
	local optionsProfile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(L["RaidSummon"] .. "-Profiles", optionsProfile)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(L["RaidSummon"]  .."-Profiles", "Profiles", "RaidSummon")

	self:RegisterChatCommand("rs", "ChatCommand")
	self:RegisterChatCommand("raidsummon", "ChatCommand")

	--load version in RaidSummon Frame
	RaidSummon_RequestFrameHeader:SetText(L["FrameHeader"](GetAddOnMetadata("RaidSummon", "Version")))

	MSG_PREFIX_ADD_MANUAL = "RSAddManual"
	MSG_PREFIX_REMOVE = "RSRemove"
	MSG_PREFIX_REMOVE_MANUAL = "RSRemoveManual"
	RaidSummonSyncList = RaidSummonLinkedList:New()
	
	--Ace3 Comm Channels max 16 chars
	COMM_PREFIX_ADD_MANUAL = "RSADDM"
	COMM_PREFIX_REMOVE = "RSRM"
	COMM_PREFIX_REMOVE_MANUAL = "RSRMM"
	COMM_PREFIX_ADD_ALL = "RSADDALL"
	
	--Ace3 Comm Registers
	self:RegisterComm(COMM_PREFIX_ADD_MANUAL) --add via /rs add
	self:RegisterComm(COMM_PREFIX_REMOVE) --remove via summoning / right click
	self:RegisterComm(COMM_PREFIX_REMOVE_MANUAL) --remove via ctrl + click
	self:RegisterComm(COMM_PREFIX_ADD_ALL) --via AddAll function
	
	--check if keywords have been initialized
	if (not self.db.profile.keywordsinit) then
		self.db.profile.keywords = { "^123$", "^sum", "^port" }
		self.db.profile.keywordsinit = true
	end
end

--Handle CHAT_MSG Events here
function RaidSummon:msgParser(eventName,...)
	if eventName == "CHAT_MSG_RAID" or eventName == "CHAT_MSG_RAID_LEADER" then
		local text, playerName, languageName, channelName, playerName2   = ...
		
		for i, v in ipairs(self.db.profile.keywords) do
			if string.find(text, v) then
				RaidSummon:AddToSummonList(playerName2)
			end		
		end
	end
end

--Clear the sync db and update the frame when joining or leaving a group/raid
function RaidSummon:GroupEvent(eventName,...)
	RaidSummonSyncList = RaidSummonLinkedList:New()
	RaidSummon:UpdateList()
end

--Hanlde raid changes and index changes
function RaidSummon:GROUP_ROSTER_UPDATE(eventName,...)
	RaidSummon:getRaidMembers()
	if RaidSummonMembersTable and RaidSummonSyncList then
		for name in RaidSummonSyncList:GetValuesIterator() do
			if not RaidSummonMembersTable[name] then
				RaidSummonSyncList:Remove(name)
			end
		end
	end
	RaidSummon:UpdateList()
end

function RaidSummon:AddToSummonList(member)
	if RaidSummonSyncList:HasValue(member) then
		return
	end
		
	--check if player is in the raid
	RaidSummon:getRaidMembers()
	if RaidSummonMembersTable and RaidSummonMembersTable[member] then
		if RaidSummonMembersTable[member].rFileName == "WARLOCK" then
			RaidSummonSyncList:Prepend(member)
		else
			RaidSummonSyncList:Append(member)
		end
		RaidSummon:UpdateList()
	end
end

--Ace3 Comm
function RaidSummon:OnCommReceived(prefix, message, distribution, sender)
	if not prefix then
		return
	end

	if prefix == COMM_PREFIX_ADD_MANUAL then
		--print("COMM_PREFIX_ADD_MANUAL "..message)
		--only add player once
		if not RaidSummonSyncList:HasValue(message) then
			--check if player is in the raid
			RaidSummon:getRaidMembers()
			if RaidSummonMembersTable and RaidSummonMembersTable[message] then
				if RaidSummonMembersTable[message].rFileName == "WARLOCK" then
					RaidSummonSyncList:Prepend(message)
				else
					RaidSummonSyncList:Append(message)
				end
				print(L["MemberAdded"](message,sender))
				RaidSummon:UpdateList()
			end
		end
	elseif prefix == COMM_PREFIX_REMOVE then
		--print("COMM_PREFIX_REMOVE "..message)
		if RaidSummonSyncList:Remove(message) then
			RaidSummon:UpdateList()
		end
	elseif prefix == COMM_PREFIX_REMOVE_MANUAL then
		--print("COMM_PREFIX_REMOVE_MANUAL "..message)
		if RaidSummonSyncList:Remove(message) then
			print(L["MemberRemoved"](message,sender))
			RaidSummon:UpdateList()
		end
	elseif prefix == COMM_PREFIX_ADD_ALL then
		--print("COMM_PREFIX_ADD_ALL "..message)
		if IsInRaid() then
			local members = GetNumGroupMembers()
			if (members > 0) then
			
			if GetZoneText() == "" then
				zonetext = nil
			else
				zonetext = GetZoneText()
			end

				for i = 1, members do
					local rName, rRank, rSubgroup, rLevel, rClass, rFileName, rZone = GetRaidRosterInfo(i)
					
					--only add the player if not in the current zone
					if rName and zonetext ~= rZone then
						if not RaidSummonSyncList:HasValue(rName) then
							--check if player is in the raid
							RaidSummon:getRaidMembers()
							if RaidSummonSyncList then
								RaidSummonSyncList:Append(rName)
							end
						end
					end
				end
				RaidSummon:UpdateList()
				print(L["AddAllMessage"])
			end
		end
	end
end

--GUI
function RaidSummon:NameListButton_PreClick(source, button)
	local buttonname = source:GetName()
	local name = _G[buttonname.."TextName"]:GetText()
	local buttonName = GetMouseButtonClicked()
	local targetname, targetrealm = UnitName("target")

	if RaidSummonMembersTable then
		raidIndex = RaidSummonMembersTable[name].rIndex

		if raidIndex then
			--set target when not in combat (securetemplate)
			if not InCombatLockdown() then
				if RaidSummonSyncList.start then
					source:SetAttribute("type1", "target")
					source:SetAttribute("unit", "raid" .. raidIndex)
				end
				source:SetAttribute("type2", "spell")
				source:SetAttribute("spell", "698") --698 - Ritual of Summoning
			else
				print(L["Lockdown"])
			end
		end
	end

	if buttonName == "RightButton" and targetname ~= nil and not InCombatLockdown() then

		if RaidSummonMembersTable then
		
			--Summoning does only work when the player has a target
			--check if the clicked name is the current target
			if targetname ~= name then
				print(L["TargetMissmatch"](targetname, name))
				return
			end
            
            if UnitInRange("target") then
                print(L["TargetNearby"](targetname))
                return
            end
            
            if UnitPower("player", SPELL_POWER_MANA ) < 300 then
                print(L["OutOfMana"])
                return
            end

			if GetZoneText() == "" then
				zonetext = nil
			else
				zonetext = GetZoneText()
			end

			if GetSubZoneText() == "" then
				subzonetext = nil
			else
				subzonetext = GetSubZoneText()
			end

			if self.db.profile.zone and self.db.profile.whisper and zonetext and subzonetext then
				SendChatMessage(L["SummonAnnounceRZS"](targetname, zonetext, subzonetext), "RAID")
				SendChatMessage(L["SummonAnnounceWZS"](zonetext, subzonetext), "WHISPER", nil, targetname)
			elseif self.db.profile.zone and self.db.profile.whisper and zonetext and not subzonetext then
				SendChatMessage(L["SummonAnnounceRZ"](targetname, zonetext), "RAID")
				SendChatMessage(L["SummonAnnounceWZ"](zonetext), "WHISPER", nil, targetname)
			elseif self.db.profile.zone and not self.db.profile.whisper and zonetext and subzonetext then
				SendChatMessage(L["SummonAnnounceRZS"](targetname, zonetext, subzonetext), "RAID")
			elseif self.db.profile.zone and not self.db.profile.whisper and zonetext and not subzonetext then
				SendChatMessage(L["SummonAnnounceRZ"](targetname, zonetext), "RAID")
			elseif not self.db.profile.zone and self.db.profile.whisper then
				SendChatMessage(L["SummonAnnounceR"](targetname), "RAID")
				SendChatMessage(L["SummonAnnounceW"], "WHISPER", nil, targetname)
			elseif not self.db.profile.zone and not self.db.profile.whisper then
				SendChatMessage(L["SummonAnnounceR"](targetname), "RAID")
			else
				print(L["SummonAnnounceError"])
			end
			if RaidSummonSyncList:HasValue(targetname) then
				RaidSummon:SendCommMessage(COMM_PREFIX_REMOVE, targetname, "RAID")
			end
		else
			print(L["noRaid"])
		end
	elseif buttonName == "LeftButton" and IsControlKeyDown() then
		if RaidSummonSyncList:HasValue(name) then
			RaidSummon:SendCommMessage(COMM_PREFIX_REMOVE_MANUAL, name, "RAID")
		end
	end

	RaidSummon:UpdateList()
end

function RaidSummon:UpdateList()
	--only Update and show if Player is Warlock
	local className, classFilename, classID = UnitClass("player")
	if classFilename ~= "WARLOCK" then
		return
	end

	local syncListSize = 0
	for name in RaidSummonSyncList:GetValuesIterator() do
		if RaidSummonMembersTable[name] then
			syncListSize = syncListSize + 1
			_G["RaidSummon_NameList"..syncListSize.."TextName"]:SetText(name)
	
			--Shamans are pink (like paladins) in Classic, we need to fix that, thanks to Molimo-Lucifron for testing
			if RaidSummonMembersTable[name].rFileName == "SHAMAN" then
				_G["RaidSummon_NameList"..syncListSize.."TextName"]:SetTextColor(0.00, 0.44, 0.87, 1)
			else
				local r,g,b,img = GetClassColor(RaidSummonMembersTable[name].rFileName)
				_G["RaidSummon_NameList"..syncListSize.."TextName"]:SetTextColor(r, g, b, 1)
			end
	
			if not InCombatLockdown() then
				_G["RaidSummon_NameList"..syncListSize]:Show()
			else
				RaidSummon:UpdateListCombatCheck()
			end
		end
	end

	for i = syncListSize + 1, 40 do
		if not InCombatLockdown() then
			_G["RaidSummon_NameList"..i.."TextName"]:SetText("")
			_G["RaidSummon_NameList"..i]:Hide()
		else
			RaidSummon:UpdateListCombatCheck()
		end
	end

	RaidSummon:updateWindowSize(syncListSize)
end

function RaidSummon:updateWindowSize(size)
	if not InCombatLockdown() then
		if not RaidSummonSyncList.start then
			if RaidSummon_RequestFrame:IsVisible() then
				RaidSummon_RequestFrame:Hide()
			end
		else
			ShowUIPanel(RaidSummon_RequestFrame, 1)
		end
	else
		RaidSummon:UpdateListCombatCheck()
	end

	RaidSummon_RequestFrame:SetHeight(20+16*size)
end

--collects raid member information to RaidSummonMembersTable
function RaidSummon:getRaidMembers()
	if IsInRaid() then

		local members = GetNumGroupMembers()

		if (members > 0) then
			RaidSummonMembersTable = {}

			for i = 1, members do
				local rName, rRank, rSubgroup, rLevel, rClass, rFileName = GetRaidRosterInfo(i)
				if rName and rClass and rFileName then
					RaidSummonMembersTable[rName] = { rIndex = i, rClass = rClass, rFileName = rFileName }
				end
			end
		end
	end
end

--checks for a value in a table
function RaidSummon:hasValue (tab, val)
	for i, v in ipairs (tab) do
		if v == val then
			return true
		end
	end
	return false
end

--finds the index of a value
function RaidSummon:getIndexbyValue (tab, val)
	for i,v in ipairs(tab) do
		if v == val then
			return i
		end
	end
	return nil
end

--checks for combat every 10 seconds and calls RaidSummon:UpdateList
function RaidSummon:UpdateListCombatCheck()
	if InCombatLockdown() then
		--button and frame did not hide while in combat, try again in 10 seconds
		self:ScheduleTimer("UpdateListCombatCheck",10)
		return
	else
		RaidSummon:UpdateList()
	end
end

function RaidSummon:ChatCommand(input)
	if not input or input:trim() == "" then
		self:ExecuteHelp()
	else
		LibStub("AceConfigCmd-3.0"):HandleCommand("rs", "RaidSummon", input)
	end
end

--Option Functions
function RaidSummon:GetOptionWhisper(info)
	return self.db.profile.whisper
end

function RaidSummon:GetOptionZone(info)
	return self.db.profile.zone
end

function RaidSummon:SetOptionWhisper(info, value)
	self.db.profile.whisper = value
	if value == true then
		print(L["OptionWhisperEnabled"])
	else
		print(L["OptionWhisperDisabled"])
	end
end

function RaidSummon:SetOptionZone(info, value)
	self.db.profile.zone = value
	if value == true then
		print(L["OptionZoneEnabled"])
	else
		print(L["OptionZoneDisabled"])
	end
end

function RaidSummon:ExecuteHelp()
	print(L["OptionHelpPrint"])
end

function RaidSummon:ExecuteConfig()
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrame) --BlizzBugSucks
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
end

function RaidSummon:ExecuteList()
	--show msg if list is empty
	if RaidSummonSyncList.start == nil then
		print(L["OptionListEmpty"])
	else
		print(L["OptionList"])
		for name in RaidSummonSyncList:GetValuesIterator() do
			print(name)
		end
	end
end

function RaidSummon:ExecuteClear()
  RaidSummonSyncList = RaidSummonLinkedList:New()
	RaidSummon:UpdateList()
	print(L["OptionClear"])
end

function RaidSummon:ExecuteToggle()
	if not InCombatLockdown() then
		if RaidSummon_RequestFrame:IsVisible() then
			RaidSummon_RequestFrame:Hide()
		else
			RaidSummon:UpdateList()
			ShowUIPanel(RaidSummon_RequestFrame, 1)
		end
	else
		print(L["Lockdown"])
	end
end

--Add / Remove Options Functions
function RaidSummon:SetOptionAdd(info, input)
	if (input) then
		RaidSummon:SendCommMessage(COMM_PREFIX_ADD_MANUAL, input, "RAID")
	end
end

function RaidSummon:SetOptionRemove(info, input)
	if (input) then
		RaidSummon:SendCommMessage(COMM_PREFIX_REMOVE_MANUAL, input, "RAID")
	end
end

function RaidSummon:ValuesRemoveSel(info)
	local playerlist = {}
	if RaidSummonSyncList.start == nil then
		return playerlist
	else
		for name in RaidSummonSyncList:GetValuesIterator() do
			playerlist[name] = name
		end
		return playerlist
	end
end

function RaidSummon:ExecuteAddAll()
	RaidSummon:SendCommMessage(COMM_PREFIX_ADD_ALL, COMM_PREFIX_ADD_ALL, "RAID")
end

--Keyword Options Functions
function RaidSummon:ExecuteKWList()
	if next(self.db.profile.keywords) == nil then
		print(L["OptionListEmpty"])
	else
		print(L["OptionKWList"])
		for i, v in ipairs(self.db.profile.keywords) do
			print(v)
		end
	end
end

function RaidSummon:SetKWAdd(info, input)
	if (input) and input ~= "" then
		if (RaidSummon:hasValue(self.db.profile.keywords, input)) then
			print(L["OptionKWAddDuplicate"](input))
		else
			print(L["OptionKWAddAdded"](input))
			table.insert(self.db.profile.keywords,input)
		end
	end
end

function RaidSummon:SetKWRemove(info, input)
	if (input) then
		if (RaidSummon:hasValue(self.db.profile.keywords, input)) then
			print(L["OptionKWRemoveRemoved"](input))
			local index = RaidSummon:getIndexbyValue(self.db.profile.keywords, input)
			table.remove(self.db.profile.keywords, index)
		else
			print(L["OptionKWRemoveNF"](input))
		end
	end	
end

function RaidSummon:ValuesKWRemoveSel(info)
	local kwlist = {}
	if self.db.profile.keywords then
		if next(self.db.profile.keywords) == nil then
			return kwlist
		else
			for i, v in ipairs(self.db.profile.keywords) do
				table.insert(kwlist,v)
			end
			return kwlist
		end
	end
end

function RaidSummon:SetKWRemoveSel(info, input)
	--input is the index of a the profile keywords table
	if (input) then
		if not self.db.profile.keywords then
			return
		else
			print(L["OptionKWRemoveRemoved"](self.db.profile.keywords[input]))
			table.remove(self.db.profile.keywords, input)
		end
	end	
end


--List functions
RaidSummonLinkedList = {start = nil}

function RaidSummonLinkedList:New(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function RaidSummonLinkedList:Append(value)
	if self.start == nil then
		self.start = {value = value, next = nil}
		return
	end

	local l = self.start
	while l.next do
		l = l.next
	end
	l.next = {value = value, next = nil}
end

function RaidSummonLinkedList:Prepend(value)
	self.start = {value = value, next = self.start}
end

--Returns true if the value was in the list
function RaidSummonLinkedList:Remove(value)
	if not self.start then
		return false
	end

	if self.start.value == value then
		self.start = self.start.next
		return true
	end

	local prev = self.start
	local l = self.start

	while l do 
		if l.value == value then
			prev.next = l.next
			return true
		end
		prev = l
		l = l.next
	end

	return false
end

function RaidSummonLinkedList:HasValue(value)
	if not self.start then
		return false
	end

	local l = self.start
	while l do
		if l.value == value then
			return true
		end
		l = l.next
	end

	return false
end

function RaidSummonLinkedList:GetValuesIterator()
	local l = self.start
	return function()
		if l then
			local value = l.value
			l = l.next
			return value
		else
			return nil
		end
	end
end

--fill the frame with dummy data for testing
--/script RaidSummon:DummyFill()
function RaidSummon:DummyFill()
	ShowUIPanel(RaidSummon_RequestFrame, 1)
	
	local RaidSummonDummy = {
		{
			name = "Nyx",
			class = "WARLOCK"
		},
		{
			name = "Zeus",
			class = "SHAMAN"
		},
		{
			name = "Eros",
			class = "PALADIN"
		},
		{
			name = "Hera",
			class = "MAGE"
		},
		{
			name = "Artemis",
			class = "HUNTER"
		},
		{
			name = "Athene",
			class = "PALADIN"
		},
		{
			name = "Demeter",
			class = "DRUID"
		},
		{
			name = "Aphrodite",
			class = "PRIEST"
		},
		{
			name = "Ares",
			class = "ROGUE"
		},
		{
			name = "Kronos",
			class = "WARRIOR"
		},
	}
	
	
	for i, v in ipairs(RaidSummonDummy) do
		if v.class == "SHAMAN" then
			r,g,b,img = 0.00, 0.44, 0.87, 1
		else
			r,g,b,img = GetClassColor(v.class)
		end
		_G["RaidSummon_NameList" .. i .. "TextName"]:SetText(v.name)
		_G["RaidSummon_NameList" .. i .. "TextName"]:SetTextColor(r, g, b, 1)
		_G["RaidSummon_NameList".. i]:Show()
	end
    RaidSummon:updateWindowSize(10)
end

--Hook Functions
function RaidSummon:UnitPopup_ShowMenu(dropdownMenu, which, unit, name, userData)
	if (UIDROPDOWNMENU_MENU_LEVEL > 1) then
		return
	end
	
	--which from BlizzUI UnitPopup.lua UnitPopupMenus
	if (which == "SELF" or which == "PARTY" or which == "RAID_PLAYER") then
		
		--Seperator
		UIDropDownMenu_AddSeparator(UIDROPDOWNMENU_MENU_LEVEL)

		--Title
		local infotitle = UIDropDownMenu_CreateInfo()
		infotitle.text = L["RaidSummon"]
		infotitle.notCheckable = true
		infotitle.isTitle = true
		UIDropDownMenu_AddButton(infotitle)

		--AddButton
		local addbutton = UIDropDownMenu_CreateInfo()
		addbutton.text = L["OptionAddName"]
		addbutton.owner = which
		addbutton.notCheckable = true
		addbutton.func = RaidSummon.RightClick
		addbutton.colorCode = "|cff9482c9"
		addbutton.value = "RaidSummonAddButton"

		UIDropDownMenu_AddButton(addbutton)
		
		--RemoveButton
		local removebutton = UIDropDownMenu_CreateInfo()
		removebutton.text = L["OptionRemoveName"]
		removebutton.owner = which
		removebutton.notCheckable = true
		removebutton.func = RaidSummon.RightClick
		removebutton.colorCode = "|cff9482c9"
		removebutton.value = "RaidSummonRemoveButton"

		UIDropDownMenu_AddButton(removebutton)
	end
end

function RaidSummon:RightClick()
	if self.value == "RaidSummonAddButton" then
		local dropdownMenu = _G["UIDROPDOWNMENU_INIT_MENU"]
		if (dropdownMenu.name ~= "") then
			RaidSummon:SetOptionAdd(_, dropdownMenu.name)
		end
	elseif self.value == "RaidSummonRemoveButton" then
		local dropdownMenu = _G["UIDROPDOWNMENU_INIT_MENU"]
		if (dropdownMenu.name ~= "") then
			RaidSummon:SetOptionRemove(_, dropdownMenu.name)
		end
	end
end

function RaidSummon:RefreshConfig()
	if (not self.db.profile.keywordsinit) then
		self.db.profile.keywords = { "^123$", "^sum", "^port" }
		self.db.profile.keywordsinit = true
	end
end