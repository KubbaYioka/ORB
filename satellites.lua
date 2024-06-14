-- satellites.lua
local G = 6.67430e-11 -- Gravitational constant in m^3 kg^-1 s^-2

local Planet = require("planets")
local Debris = require("debris")

local Satellites = {}

sizeEnum = {
    tiny = 2,
    small = 4,
    medium = 8,
    large = 16,
    huge = 32,
    station = 64
}

-- List of potential names for satellites
local satelliteNames = {"Apollo", "Gemini", "Voyager", "Pioneer", "Galileo", "Cassini", "Hubble", "Kepler", "NewHorizons", "Curiosity", "Perseverance", "Spirit", "Opportunity", "Juno", "Dawn", "Rosetta", "Philae", "Chandra", "Spitzer", "JamesWebb"}

-- Define the Satellite class
local Satellite = {}
Satellite.__index = Satellite

function Satellite.new(x, y, mass, size, xVel, yVel, orientation)
    local self = setmetatable({}, Satellite)
    self.x = x
    self.y = y
    self.mass = mass
    self.size = size
    self.xVel = xVel or 0
    self.yVel = yVel or 0
    self.orientation = orientation or 0  -- Orientation in radians
    self.collided = false
    self.name = generateRandomName()
    print("Satellite created: " .. self.name .. " at (" .. self.x .. ", " .. self.y .. ")")
    return self
end

function Satellite:update(dt)
    if self.collided then return end

    local totalForceX, totalForceY = 0, 0
    for _, planet in ipairs(Planet.getAllObjects()) do
        local dx = planet.x - self.x
        local dy = planet.y - self.y
        local distanceSquared = dx^2 + dy^2
        if distanceSquared > 0 then
            local forceMagnitude = (G * self.mass * planet.mass) / distanceSquared
            local distance = math.sqrt(distanceSquared)
            local forceX = forceMagnitude * (dx / distance)
            local forceY = forceMagnitude * (dy / distance)
            totalForceX = totalForceX + forceX
            totalForceY = totalForceY + forceY
        end
    end

    local accelerationX = totalForceX / self.mass
    local accelerationY = totalForceY / self.mass

    self.xVel = self.xVel + accelerationX * dt
    self.yVel = self.yVel + accelerationY * dt

    self.x = self.x + self.xVel * dt
    self.y = self.y + self.yVel * dt
end

function Satellite:draw()
    if self.collided then return end

    local halfSize = self.size / 2
    
    -- Define colors for each side
    local foreColor = {1, 0, 0}  -- Red
    local starboardColor = {0, 1, 0}  -- Green
    local portColor = {0, 0, 1}  -- Blue
    local sternColor = {1, 1, 0}  -- Yellow

    -- Calculate the vertices of the square
    local cosO = math.cos(self.orientation)
    local sinO = math.sin(self.orientation)
    
    local vertices = {
        {self.x + halfSize * cosO - halfSize * sinO, self.y + halfSize * sinO + halfSize * cosO},  -- Top Right
        {self.x - halfSize * cosO - halfSize * sinO, self.y - halfSize * sinO + halfSize * cosO},  -- Top Left
        {self.x - halfSize * cosO + halfSize * sinO, self.y - halfSize * sinO - halfSize * cosO},  -- Bottom Left
        {self.x + halfSize * cosO + halfSize * sinO, self.y + halfSize * sinO - halfSize * cosO},  -- Bottom Right
    }

    -- Draw each side with a different color
    love.graphics.setColor(foreColor)
    love.graphics.polygon('fill', self.x, self.y, vertices[1][1], vertices[1][2], vertices[2][1], vertices[2][2])
    love.graphics.setColor(starboardColor)
    love.graphics.polygon('fill', self.x, self.y, vertices[2][1], vertices[2][2], vertices[3][1], vertices[3][2])
    love.graphics.setColor(sternColor)
    love.graphics.polygon('fill', self.x, self.y, vertices[3][1], vertices[3][2], vertices[4][1], vertices[4][2])
    love.graphics.setColor(portColor)
    love.graphics.polygon('fill', self.x, self.y, vertices[4][1], vertices[4][2], vertices[1][1], vertices[1][2])

    -- Optionally, draw a small line to indicate direction
    love.graphics.setColor(1, 1, 1)
    local arrowLength = self.size * 1.5
    love.graphics.line(self.x, self.y, self.x + arrowLength * cosO, self.y + arrowLength * sinO)
end

function Satellite:checkCollision(other)
    local dx = self.x - other.x
    local dy = self.y - other.y
    local distanceSquared = dx^2 + dy^2
    local combinedSize = (self.size + (other.size or 0)) / 2

    if distanceSquared < combinedSize^2 then
        self.collided = true
        other.collided = true
        if other.isPlanet then
          print(other.type)
            if other.type == "placeholderObject" then
              -- do calculations to check for damage or complete destruction.
              self:explode()
            elseif other.type == "star" or other.type == "planet" then
              if other.type == "planet" then
                print(self.name.." crashed on "..other.type.. "and was destroyed.")
              elseif other.type == "star" then
                print(self.name.." collided with "..other.type.. "and was incinerated.")
              self:destroy()
            end
        end
    end
end

-- Handle the destruction of the satellite when it collides with a star
function Satellite:destroy()
    for i, satellite in ipairs(Satellites.satellites) do
        if satellite == self then
            table.remove(Satellites.satellites, i)
            break
        end
    end
end

-- Handle the explosion of the satellite when it collides with a planet
function Satellite:explode()
    local pieces = math.random(3, 4) + math.floor(self.size / 4)
    local pieceSize = math.random(1, 3) + math.floor(self.size / 8)
    local impactSpeed = math.sqrt(self.xVel^2 + self.yVel^2)
    for i = 1, pieces do
        local angle = self.orientation + (math.random() - 0.5) * math.pi / 2  -- Arc around impact direction
        local speed = math.random(0.5,2) * impactSpeed
        local xVel = speed * math.cos(angle)
        local yVel = speed * math.sin(angle)
        Debris.new(self.x, self.y, self.mass / pieces, pieceSize, xVel, yVel)
    end
    self:destroy()
end

-- Generate a random name for the satellite
function generateRandomName()
    local name = satelliteNames[math.random(1, #satelliteNames)]
    local number = math.random(0, 20)
    return name .. " " .. number
end

-- Add the Satellite class to the Satellites module
Satellites.Satellite = Satellite

-- Table to store all instances of the Satellite class
Satellites.satellites = {}

function Satellites.addSatellite(x, y, mass, size, xVel, yVel, orientation)
    local satellite = Satellite.new(x, y, mass, size, xVel, yVel, orientation)
    table.insert(Satellites.satellites, satellite)
end

function Satellites.updateAll(dt, planets)
    for i, satellite in ipairs(Satellites.satellites) do
        satellite:update(dt, planets)
    end
    Satellites.checkCollisions(planets)
end

function Satellites.drawAll()
    for _, satellite in ipairs(Satellites.satellites) do
        satellite:draw()
    end
end

function Satellites.checkCollisions(planets)
    for i = 1, #Satellites.satellites - 1 do
        for j = i + 1, #Satellites.satellites do
            local sat1 = Satellites.satellites[i]
            local sat2 = Satellites.satellites[j]
            sat1:checkCollision(sat2)
        end
    end
    for _, satellite in ipairs(Satellites.satellites) do
        for _, planet in ipairs(planets) do
            if not satellite.collided then
                satellite:checkCollision(planet)
            end
        end
    end
end

function spawnSatellite(size)
    local x, y = trueCoords(debugDialog.x, debugDialog.y)
    if size == "small" then
        Satellites.addSatellite(x, y, 100, 5, randomNumber(0, 10), randomNumber(0, 10), math.rad(randomNumber(0, 360)))
    elseif size == "medium" then
        Satellites.addSatellite(x, y, 200, 10, randomNumber(0, 10), randomNumber(0, 10), math.rad(randomNumber(0, 360)))
    elseif size == "large" then
        Satellites.addSatellite(x, y, 300, 15, randomNumber(0, 10), randomNumber(0, 10), math.rad(randomNumber(0, 360)))
    end
    debugDialog.isVisible = false
end

function isPointInSatellite(x, y, satellite)
    local dx = x - satellite.x
    local dy = y - satellite.y
    return dx * dx + dy * dy <= satellite.size * satellite.size
end

function plotCourse(satellite)
    local time_step = 0.1
    local total_steps = 1000
    print("Plotting course for satellite:", satellite)
    plottedPath = calculatePath(satellite, Planet.getAllObjects(), time_step, total_steps)
    if plottedPath then
        print("Path calculated with", #plottedPath, "points")
        for i = 1, math.min(10, #plottedPath) do
            print("Point", i, ":", plottedPath[i].x, plottedPath[i].y)
        end
    else
        print("Failed to calculate path")
    end
end

function calculatePath(satellite, planets, time_step, total_steps)
    local path = {}
    local posX, posY = satellite.x, satellite.y
    local xVel, yVel = satellite.xVel, satellite.yVel
    local mass = satellite.mass
    
    for step = 1, total_steps do
        local totalForceX, totalForceY = 0, 0
        
        for _, planet in ipairs(planets) do
            local dx = planet.x - posX
            local dy = planet.y - posY
            local distanceSquared = dx^2 + dy^2
            if distanceSquared > 0 then
                local forceMagnitude = (G * mass * planet.mass) / distanceSquared
                local distance = math.sqrt(distanceSquared)
                local forceX = forceMagnitude * (dx / distance)
                local forceY = forceMagnitude * (dy / distance)
                totalForceX = totalForceX + forceX
                totalForceY = totalForceY + forceY
            end
        end
        
        xVel = xVel + (totalForceX / mass) * time_step
        yVel = yVel + (totalForceY / mass) * time_step
        
        posX = posX + xVel * time_step
        posY = posY + yVel * time_step
        
        table.insert(path, {x = posX, y = posY})
    end
    
    return path
end

return Satellites
