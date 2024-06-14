-- debris.lua
local Planet = require("planets")

local Debris = {}
Debris.__index = Debris

local debrisList = {}

local G = 6.67430e-11 -- Gravitational constant in m^3 kg^-1 s^-2

function Debris.new(x, y, mass, size, xVel, yVel, collisionData)
    local self = setmetatable({}, Debris)
    self.x = x
    self.y = y
    self.mass = mass
    self.size = size
    self.xVel = xVel or 0
    self.yVel = yVel or 0
    self.collisionDelay = 5  -- Delay before checking for collisions
    self.collisionData = collisionData or {}
    table.insert(debrisList, self)
    return self
end

function Debris:update(dt)
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

function Debris:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle('fill', self.x, self.y, self.size, self.size)
end

function Debris:destroy()
    for i, d in ipairs(debrisList) do
        if d == self then
            table.remove(debrisList, i)
            break
        end
    end
end

function Debris:checkCollision(other)
    if not other or self.collisionDelay > 0 then return end  -- Ensure other is valid and delay has passed
    local dx = self.x - other.x
    local dy = self.y - other.y
    local distanceSquared = dx * dx + dy * dy
    local combinedSize = (self.size + (other.size or 0)) / 2

    if distanceSquared < combinedSize * combinedSize then
        self:destroy()
        if other.isDebris then
            other:destroy()
        else
            other.collided = true
        end
    end
end

function Debris.updateAll(dt)
    for i = #debrisList, 1, -1 do
        debrisList[i]:update(dt)
    end
    Debris.checkCollisions()
end

function Debris.drawAll()
    for _, d in ipairs(debrisList) do
        d:draw()
    end
end

function Debris.checkCollisions()
    for i = 1, #debrisList - 1 do
        for j = i + 1, #debrisList do
            debrisList[i]:checkCollision(debrisList[j])
        end
    end
    for _, d in ipairs(debrisList) do
        for _, s in ipairs(require("satellites").satellites) do
            if not s.collided then
                d:checkCollision(s)
            end
        end
        for _, p in ipairs(require("planets").getAllObjects()) do
            d:checkCollision(p)
        end
    end
end

Debris.debrisList = debrisList

return Debris
