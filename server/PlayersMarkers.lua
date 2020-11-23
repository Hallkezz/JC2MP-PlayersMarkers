---------------
--By Hallkezz--
---------------

-----------------------------------------------------------------------------------
--Default Settings
local Interval = 2 -- Markers Update Time ( Default: 2 ) | Make the number larger if the players have delays.
local HideMeCmd = "/hideme" -- Command to Hide Me. ( Default: /hideme )
local SettingsCmd = "/markers" -- Command to Open Settings. ( Default: /markers )
-----------------------------------------------------------------------------------

-----------------------------------------------------------------------------------
--Script
class "PlayersMarkers"

function PlayersMarkers:__init()
	self.timer = Timer()

	self.invisiblePlayers = {}

	Events:Subscribe( "PostTick", self, self.PostTick )
	Events:Subscribe( "PlayerChat", self, self.PlayerChat )
end

function PlayersMarkers:PostTick()
	if self.timer:GetSeconds() > Interval then
        local playerPositions = {}

        for player in Server:GetPlayers() do
            local playerId = player:GetId()
            if self.invisiblePlayers[playerId] == nil then
                playerPositions[playerId] = { position = player:GetPosition(), color = player:GetColor(), worldId = player:GetWorld():GetId(), tringle = "none" }
             end
        end
        self.timer:Restart()
    	Network:Broadcast( "BMPlayerPositions", playerPositions )
    end
end

function PlayersMarkers:PlayerChat( args )
	local text = args.text
	local playerId = args.player:GetId()

	if text == HideMeCmd then
		if self.invisiblePlayers[playerId] == nil then
			self.invisiblePlayers[playerId] = true
			Chat:Send( args.player, "Hiding enabled.", Color.LawnGreen )
		else
			self.invisiblePlayers[playerId] = nil
			Chat:Send( args.player, "Hiding disabled.", Color.LawnGreen )
		end
	end

	if text == SettingsCmd then
		Network:Send( args.player, "OpenWindow" )
	end
end

playersmarkers = PlayersMarkers()

-----------------------------------------------------------------------------------
--Script Version
--v0.1--

--Release Date
--30.03.20--
-----------------------------------------------------------------------------------
