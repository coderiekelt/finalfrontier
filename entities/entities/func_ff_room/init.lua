local TEMPERATURE_LOSS_RATE = 0.00000382

ENT.Type = "brush"
ENT.Base = "base_brush"

ENT.Ship = nil
ENT.ShipName = nil
ENT.System = nil
ENT.Volume = 1000
ENT.SurfaceArea = 60

ENT.Corners = nil
ENT.Screens = nil
ENT.DoorNames = nil
ENT.Doors = nil

ENT._lastupdate = 0

ENT._temperature = 298
ENT._airvolume = 1000
ENT._maxshield = 20

function ENT:KeyValue( key, value )
	if key == "ship" then
		self.ShipName = tostring( value )
	elseif key == "system" then
		self.System = tostring( value )
	elseif key == "volume" then
		self.Volume = tonumber( value )
		self.SurfaceArea = math.sqrt( self.Volume ) * 6
	elseif string.find( key, "^door%d*" ) then
		self.DoorNames = self.DoorNames or {}
		table.insert( self.DoorNames, tostring( value ) )
	end
end

function ENT:InitPostEntity()
	self.Corners = {}
	self.Doors = {}
	self.Screens = {}
	
	if not self.DoorNames then
		MsgN( self:GetName() .. " has no doors!" )
	end
	
	self.DoorNames = self.DoorNames or {}

	if self.ShipName then
		self.Ship = Ships.FindByName( self.ShipName )
		if self.Ship then
			self.Ship:AddRoom( self )
		end
	end
	
	if not self.Ship then
		Error( "Room at " .. tostring( self:GetPos() ) .. " (" .. self:GetName() .. ") has no ship!\n" )
		return
	end
	
	for _, name in ipairs( self.DoorNames ) do
		local doors = ents.FindByName( name )
		if #doors > 0 then
			local door = doors[ 1 ]
			door:AddRoom( self )
			self:AddDoor( door )
		end
	end
	
	self._airvolume = math.random() * self.Volume
	self._temperature = math.random() * 300 + 300
	self._lastupdate = CurTime()
end

function ENT:Think()
	local curTime = CurTime()
	local dt = curTime - self._lastupdate
	self._lastupdate = curTime

	self._temperature = self._temperature * ( 1 - TEMPERATURE_LOSS_RATE * self.SurfaceArea * dt )
end

function ENT:AddCorner( index, x, y )
	local shipPos = self.Ship:GetPos()
	self.Corners[ index ] = { x = y - shipPos.y + 384, y = x - shipPos.x }
end

function ENT:AddDoor( door )
	table.insert( self.Doors, door )
end

function ENT:AddScreen( screen )
	table.insert( self.Screens, screen )
end

function ENT:GetTemperature()
	return self._temperature * self:GetAtmosphere()
end

function ENT:GetAirVolume()
	return self._airvolume
end

function ENT:GetAtmosphere()
	return self._airvolume / self.Volume
end

function ENT:TransmitTemperature( room, delta )
	if delta < 0 then room:TransmitTemperature( self, delta ) return end

	if delta > self._temperature then delta = self._temperature end
	
	self._temperature = self._temperature - delta
	room._temperature = room._temperature + delta
end

function ENT:TransmitAir( room, delta )
	if delta < 0 then room:TransmitAir( self, delta ) return end

	if delta > self._airvolume then delta = self._airvolume end
	
	self._airvolume = self._airvolume - delta
	room._airvolume = room._airvolume + delta
end

function ENT:GetMaxShield()
	return self._maxshield
end