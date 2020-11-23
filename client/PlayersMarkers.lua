---------------
--By Hallkezz--
---------------

-----------------------------------------------------------------------------------
--Default Settings
local Active = true -- Show Markers at Startup ( Use: True/False )
local Triangles = true -- Show Markers Height at Startup ( Use: True/False )
local MarkersDist = 5000 -- Default Marker Distance ( Default: 5000 )
-----------------------------------------------------------------------------------

-----------------------------------------------------------------------------------
--Script
class "PlayersMarkers"

function PlayersMarkers:__init()
	self.playerPositions = {}
	self.currentPlayerId = LocalPlayer:GetId()

	self:CreateSettings()

	Network:Subscribe( "BMPlayerPositions", self, self.PlayerPositions )
	Network:Subscribe( "OpenWindow", self, self.OpenWindow )
	Events:Subscribe( "LocalPlayerInput", self, self.LocalPlayerInput )
	Events:Subscribe( "Render", self, self.Render )
	Events:Subscribe( "ModulesLoad", self, self.ModulesLoad )
	Events:Subscribe( "ModuleUnload", self, self.ModuleUnload )
end

function PlayersMarkers:OpenWindow()
	self:SetWindowOpen( not self:GetWindowOpen() )
end

function PlayersMarkers:CreateSettings()
	self.window_open = false

	self.window = Window.Create()
	self.window:SetSize( Vector2( 300, 150 ) )
	self.window:SetPosition( (Render.Size - self.window:GetSize())/2 )

	self.window:SetTitle( "Markers Settings" )
	self.window:SetVisible( self.window_open )
	self.window:Subscribe( "WindowClosed", function() self:SetWindowOpen( false ) end )

	local enabled_checkbox = LabeledCheckBox.Create( self.window )
	enabled_checkbox:SetSize( Vector2( 300, 20 ) )
	enabled_checkbox:SetDock( GwenPosition.Top )
	enabled_checkbox:GetLabel():SetText( "Enabled" )
	enabled_checkbox:GetCheckBox():SetChecked( Active )
	enabled_checkbox:GetCheckBox():Subscribe( "CheckChanged", 
		function() Active = enabled_checkbox:GetCheckBox():GetChecked() end )

	local triangle_checkbox = LabeledCheckBox.Create( self.window )
	triangle_checkbox:SetSize( Vector2( 300, 20 ) )
	triangle_checkbox:SetDock( GwenPosition.Top )
	triangle_checkbox:GetLabel():SetText( "Display Height (Triangles)" )
	triangle_checkbox:GetCheckBox():SetChecked( Triangles )
	triangle_checkbox:GetCheckBox():Subscribe( "CheckChanged", 
		function() Triangles = triangle_checkbox:GetCheckBox():GetChecked() end )

	local distance_text = Label.Create( self.window )
	distance_text:SetSize( Vector2( 160, 32 ) )
	distance_text:SetDock( GwenPosition.Top )
	distance_text:SetText( "Markers Distance (m)" )
	distance_text:SetAlignment( GwenPosition.CenterV )

	local distance_numeric = Numeric.Create( self.window )
	distance_numeric:SetSize( Vector2( 160, 32 ) )
	distance_numeric:SetDock( GwenPosition.Top )
	distance_numeric:SetRange( 500, 50000 )
	distance_numeric:SetValue( MarkersDist )
	distance_numeric:Subscribe( "Changed", 
		function() MarkersDist = distance_numeric:GetValue() end )
end

function PlayersMarkers:GetWindowOpen()
	return self.window_open
end

function PlayersMarkers:SetWindowOpen( state )
	self.window_open = state
	self.window:SetVisible( self.window_open )
	Mouse:SetVisible( self.window_open )
end

function PlayersMarkers:LocalPlayerInput( args )
	if self:GetWindowOpen() and Game:GetState() == GUIState.Game then
		if args.input == Action.GuiPause then
			self:OpenWindow()
		end
        return false
	end
end

function PlayersMarkers:PlayerPositions( positions )
	self.playerPositions = positions

	for playerId, data in pairs(self.playerPositions) do
		local posp = data.position.y + 30
		local posm = data.position.y - 30

		if Triangles then
			if ( LocalPlayer:GetPosition().y > posp ) then
				data.triangle = "down"
			elseif ( LocalPlayer:GetPosition().y < posm ) then
				data.triangle = "up"
			else
				triangle = "none"
			end
		else
			triangle = "none"
		end
	end
end

function Vector3:IsNaN()
	return (self.x ~= self.x) or (self.y ~= self.y) or (self.z ~= self.z)
end

function PlayersMarkers:Render()
	if Game:GetState() ~= GUIState.Game then return end
	if not Active then return end
	local pos, ok = Render:WorldToMinimap(Vector3(5465, 282, -7699))

	local updatedPlayers = {}
	for player in Client:GetStreamedPlayers() do
		local position = player:GetPosition()
		local tringle = "none"
		if not position:IsNaN() then
			updatedPlayers[player:GetId()] = true
			local posp = position.y + 30
			local posm = position.y - 30

			if Triangles then
				if (LocalPlayer:GetPosition().y > posp) then
					triangle = "down"
				elseif (LocalPlayer:GetPosition().y < posm) then
					triangle = "up"
				else
					triangle = "none"
				end
			else
				triangle = "none"
			end
			PlayersMarkers.DrawPlayer(position, triangle, player:GetColor())
		end
	end

	for playerId, data in pairs(self.playerPositions) do
		if not updatedPlayers[playerId] and self.currentPlayerId ~= playerId and LocalPlayer:GetWorld():GetId() == data.worldId then
			PlayersMarkers.DrawPlayer( data.position, data.triangle, data.color )
		end
	end
end

function PlayersMarkers.DrawPlayer( position, triangle, color )
	local pos, ok = Render:WorldToMinimap( position )
	local playerPosition = LocalPlayer:GetPosition()
	local distance = Vector3.Distance( playerPosition, position )

	if Game:GetSetting(4) >= 1 then
		if distance <= MarkersDist then
			local size = Render.Size.x / 350
			local sSize = Render.Size.x / 280

			if triangle == "up" then
				Render:FillTriangle( Vector2( pos.x,pos.y - sSize-3 ), Vector2( pos.x - sSize-1,pos.y + sSize-1 ), Vector2( pos.x + sSize,pos.y + sSize-1 ), Color( 0, 0, 0, Game:GetSetting(4) * 2.25 ) )
				Render:FillTriangle( Vector2( pos.x,pos.y - size-2 ), Vector2( pos.x - size-1,pos.y + size-1 ), Vector2( pos.x + size,pos.y + size-1 ), color + Color( 0, 0, 0, Game:GetSetting(4) * 2.25 ) )
			elseif triangle == "down" then
				Render:FillTriangle( Vector2( pos.x,pos.y + sSize-0 ), Vector2( pos.x - sSize-1,pos.y - sSize-1 ), Vector2( pos.x + sSize-1,pos.y - sSize-1 ), Color( 0, 0, 0, Game:GetSetting(4) * 2.25 ) )
				Render:FillTriangle( Vector2( pos.x,pos.y + size-1 ), Vector2( pos.x - size-1,pos.y - size-1 ), Vector2( pos.x + size-1,pos.y - size-1 ), color + Color( 0, 0, 0, Game:GetSetting(4) * 2.25 ) )
			else
				Render:FillCircle( pos, sSize, Color( 0, 0, 0, Game:GetSetting(4) * 2.25 ) )
				Render:FillCircle( pos, size, color + Color( 0, 0, 0, Game:GetSetting(4) * 2.25 ) )
			end
		end
	end
end

--Help
function PlayersMarkers:ModulesLoad()
	Events:Fire( "HelpAddItem",
		{
			name = "Players Markers",
			text = 
				"/hideme - Hide you on Minimap.\n" ..
				"/markers - Open Markers Settings.\n \n" ..
				"- Created By Hallkezz"
		} )
end

function PlayersMarkers:ModuleUnload()
    Events:Fire( "HelpRemoveItem",
		{
			name = "Players Markers"
		} )
end

playersmarkers = PlayersMarkers()

-----------------------------------------------------------------------------------
--Script Version
--v0.1--

--Release Date
--30.03.20--
-----------------------------------------------------------------------------------
