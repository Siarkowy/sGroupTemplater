--------------------------------------------------------------------------------
-- sGroupTemplater (c) 2013 by Siarkowy
-- Released under the terms of BSD 2-Clause license.
--------------------------------------------------------------------------------

local Templater = sGroupTemplater
local GetRaidRosterInfo = GetRaidRosterInfo
local SetRaidSubgroup = SetRaidSubgroup
local UnitInRaid = UnitInRaid
local assert = assert
local tonumber = tonumber

function Templater:OnCommReceived(prefix, msg, channel, sender)
    if channel == "WHISPER" and UnitInRaid(sender) and (
        select(2, GetRaidRosterInfo(UnitInRaid(sender) + 1)) == 2
        or self.db.profile.remotes[sender]
    ) then
        local name, group = msg:match("(%w+)%->(%d)")
        group = tonumber(group) or 0

        if name and group > 0 and group <= 8 and UnitInRaid(name) then
            SetRaidSubgroup(UnitInRaid(name) + 1, group)
        end
    end
end

function Templater:AllowRemoteShuffle(name, state)
    assert(name, "You have to specify remote player's name.")

    if name ~= "" then
        self.db.profile.remotes[name] = state and true or nil
        return true
    end

    return false
end

function Templater:GetRemoteShuffler()
    return self.db.profile.shuffler
end

function Templater:SetRemoteShuffler(name)
    self.db.profile.shuffler = name
end

Templater.slash.args.remote = {
    name = "sGroupTemplater Remote shuffling",
    handler = Templater,
    type = "group",
    guiInline = true,
    guiHidden = true,
    args = {
        allow = {
            name = "Allow",
            desc = "Allows receiving of shuffle messages from given character.",
            type = "input",
            set = function(info, v)
                if Templater:AllowRemoteShuffle(v, true) then
                    Templater:Print("Remote shuffling from", v, "allowed.")
                end
            end,
            order = 5
        },
        disallow = {
            name = "Disallow",
            desc = "Disallows receiving of shuffle messages from given character.",
            type = "input",
            set = function(info, v)
                if Templater:AllowRemoteShuffle(v, false) then
                    Templater:Print("Remote shuffling from", v, "disallowed.")
                end
            end,
            order = 10
        },
        list = {
            name = "List",
            desc = "Lists characters that are allowed to issue shuffling commands for you.",
            type = "execute",
            func = function(info)
                Templater:Print("Allowed remote shufflers:")

                local AceConsole = LibStub("AceConsole-3.0")
                for name in pairs(Templater.db.profile.remotes) do
                    AceConsole:Print("   ", name)
                end
            end,
            guiHidden = true,
            order = 15
        },
        list_gui = {
            name = "List",
            desc = "List of characters that are allowed to issue shuffling commands for you.",
            type = "input",
            get = function(info)
                local tmp = Templater.table()

                for name in pairs(Templater.db.profile.remotes) do
                    tinsert(tmp, name)
                end

                sort(tmp)
                local list = table.concat(tmp, "\n")
                Templater.dispose(tmp)

                return list
            end,
            set = function(info, v)
                local remotes = Templater.db.profile.remotes

                Templater.wipe(remotes)

                for name in v:gmatch("%w+") do
                    remotes[name] = true
                end
            end,
            width = "full",
            multiline = true,
            cmdHidden = true,
            order = 16
        },
        shuffler = {
            name = "Shuffler",
            desc = "Character to send raid subgroup swap commands to if in combat lockdown.",
            type = "input",
            get = function(info)
                return Templater:GetRemoteShuffler()
            end,
            set = function(info, v)
                Templater:SetRemoteShuffler(v ~= "" and v or nil)
                Templater:Print("Remote shuffler set to", (v ~= "" and v or NONE) .. ".")
            end,
            order = 20
        },
    }
}
