-- AshenvalePvP.lua

-- Initialize main table
AshenvalePvP = {}
AshenvalePvP.inAshenvale = false
AshenvalePvP.lastGuildSentTime = 0
AshenvalePvP.lastPartySentTime = 0
AshenvalePvP.guildCooldownPeriod = 120 -- 2 minutes cooldown for guild
AshenvalePvP.partyCooldownPeriod = 30 -- 30 seconds cooldown for party
AshenvalePvP.lastCooldownMessageTime = 0
AshenvalePvP.cooldownMessageInterval = 60 -- 1 minute interval for cooldown message

-- Function to initialize the addon
function AshenvalePvP:Initialize()
    self:RegisterEvents()
    self:UpdateZoneStatus()  -- Update zone status at startup
    self:PrintStartupMessage()  -- Print startup message after updating zone status
    C_ChatInfo.RegisterAddonMessagePrefix("AshenvalePvP")
end

-- Function to register events
function AshenvalePvP:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("CHAT_MSG_GUILD")
    eventFrame:RegisterEvent("CHAT_MSG_PARTY")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("CHAT_MSG_ADDON")  -- Register the CHAT_MSG_ADDON event

    eventFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "CHAT_MSG_ADDON" then
            -- Handle addon messages separately
            AshenvalePvP:OnAddonMessage(...)
        else
            -- Handle other events
            AshenvalePvP:OnEvent(event, ...)
        end
    end)
end

-- Event handler function
function AshenvalePvP:OnEvent(event, ...)
    if event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_PARTY" then
        local msg, sender = ...
        if msg:lower() == "!ash" then
            self:SendPvPData(event)
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        self:UpdateZoneStatus()
    end
end

-- Function to handle addon messages
function AshenvalePvP:OnAddonMessage(prefix, message, distribution, sender)
    if prefix == "AshenvalePvP" and distribution == "GUILD" then
        local lastSentTime = tonumber(message)
        if lastSentTime then
            AshenvalePvP.lastGuildSentTime = lastSentTime
        end
    end
end

-- Function to send PvP data or a message indicating no users in Ashenvale
function AshenvalePvP:SendPvPData(event)
    local currentTime = GetTime()
    local lastSentTime = (event == "CHAT_MSG_GUILD") and self.lastGuildSentTime or self.lastPartySentTime
    local cooldownPeriod = (event == "CHAT_MSG_GUILD") and self.guildCooldownPeriod or self.partyCooldownPeriod

    if currentTime > (lastSentTime + cooldownPeriod) then
        local message = self:IsInAshenvale() and self:CreatePvPProgressMessage() or "No addon users in Ashenvale right now!"
        self:SendMessage(event, message)
        
        if event == "CHAT_MSG_GUILD" then
            self.lastGuildSentTime = currentTime
            C_ChatInfo.SendAddonMessage("AshenvalePvP", tostring(currentTime), "GUILD")
        else
            self.lastPartySentTime = currentTime
        end
    elseif event == "CHAT_MSG_GUILD" and currentTime > (self.lastCooldownMessageTime + self.cooldownMessageInterval) then
        local remainingCooldown = cooldownPeriod - (currentTime - lastSentTime)
        local cooldownMessage = string.format("ANTISPAM: Next status update available in %d seconds. Add-on will not react for 60 seconds", math.ceil(remainingCooldown))
        self:SendCooldownMessage(event, cooldownMessage)
        self.lastCooldownMessageTime = currentTime
    end
end

-- Function to send cooldown messages
function AshenvalePvP:SendCooldownMessage(event, message)
    if event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_PARTY" then
        local chatType = (event == "CHAT_MSG_GUILD") and "GUILD" or "PARTY"
        SendChatMessage(message, chatType)
    end
end

-- Function to create Ashenvale PvP progress message
function AshenvalePvP:CreatePvPProgressMessage()
    -- Fetch progress information for Alliance and Horde directly from UI widgets
    local allianceProgressInfo = C_UIWidgetManager.GetIconAndTextWidgetVisualizationInfo(5360)
    local hordeProgressInfo = C_UIWidgetManager.GetIconAndTextWidgetVisualizationInfo(5361)

    if allianceProgressInfo and hordeProgressInfo then
        local allianceProgress = allianceProgressInfo.text
        local hordeProgress = hordeProgressInfo.text
        return "*** Yò addon: ASHENVALE PROGRESS ***\nAlliance: " .. allianceProgress .. "\nHorde: " .. hordeProgress
    else
        return "Ashenvale progress information is currently unavailable."
    end
end

-- Function to send messages
function AshenvalePvP:SendMessage(event, message)
    if event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_PARTY" then
        local chatType = (event == "CHAT_MSG_GUILD") and "GUILD" or "PARTY"
        local lines = {strsplit("\n", message)}
        for _, line in ipairs(lines) do
            SendChatMessage(line, chatType)
        end
    end
end

-- Function to update the player's current zone status
function AshenvalePvP:UpdateZoneStatus()
    self.inAshenvale = self:IsInAshenvale()
end

-- Function to check if the player is in Ashenvale
function AshenvalePvP:IsInAshenvale()
    return GetRealZoneText() == "Ashenvale"
end

-- Function to print a startup message
function AshenvalePvP:PrintStartupMessage()
    local zoneText = self:IsInAshenvale() and "You are currently in Ashenvale." or "You are not in Ashenvale."
    DEFAULT_CHAT_FRAME:AddMessage("AshenvalePvP Addon Loaded! " .. zoneText, 1.0, 1.0, 0.0)
end

-- Call initialize function
AshenvalePvP:Initialize()
