-- planets.lua

local G = 6.67430e-11  -- Gravitational constant

local Planet = {}
Planet.__index = Planet

local planets = {}

function Planet:new(type, mass, diameter, distance, speed, ellipse, orbitEntity)
    local newObj = {
        type = type,
        mass = mass * 1000,  -- Convert Earth mass to kilograms
        diameter = diameter,
        size = diameter,  -- Added size attribute
        distance = distance,
        speed = speed,
        ellipse = ellipse,
        orbitEntity = orbitEntity,
        angle = 0,
        x = 0,  -- Initialize x and y coordinates
        y = 0,
        isPlanet = true,
        texture = nil
    }
    setmetatable(newObj, self)
    
    if type == "planet" then
      newObj.texture = self:generatePerlinTexture(diameter)
    end
        
    table.insert(planets, newObj)
    
    return newObj
end

--[[
function Planet:generatePerlinTexture(size)
    local imageData = love.image.newImageData(size, size)
    local noiseX = math.random(8,40)
    local noiseY = math.random(8,40)
    for x = 0, size - 1 do
        for y = 0, size - 1 do
            local nx = x / size - math.random(0.5,1)
            local ny = y / size - math.random(0.5,1)
            local noise = love.math.noise(nx * noiseX, ny * noiseY)
            local color = 255 * noise
            imageData:setPixel(x, y, color, color, color, math.random(1,255))
        end
    end
    return love.graphics.newImage(imageData)
end]]--

function Planet:generatePerlinTexture(size)
    local imageData = love.image.newImageData(size, size)
    local scale = 10 -- Adjust scale for visible patterns

    for x = 0, size - 1 do
        for y = 0, size - 1 do
            local nx = x / size
            local ny = y / size
            local noise = love.math.noise(nx * scale, ny * scale)

            local grey = noise * 255

            imageData:setPixel(x, y, grey, grey, grey, 255)
        end
    end

    return love.graphics.newImage(imageData)
end

function Planet:update(dt)
    self.angle = self.angle + self.speed * dt

    -- Update the position based on the orbitEntity if it exists
    if type(self.orbitEntity) == "table" and #self.orbitEntity == 2 then
        self.x = self.orbitEntity[1] or 0
        self.y = self.orbitEntity[2] or 0
    elseif self.orbitEntity then
        local x = self.orbitEntity.x or 0
        local y = self.orbitEntity.y or 0
        self.x = x + self.distance * math.cos(self.angle / self.ellipse)
        self.y = y + self.distance * math.sin(self.angle)
    end
end

function Planet:draw()
    -- Draw the planet texture within a circular mask
    if self.texture then
        love.graphics.stencil(function()
            love.graphics.circle("fill", self.x, self.y, self.diameter / 2)
        end, "replace", 1)
        
        -- Enable the stencil test to only draw within the circular mask
        love.graphics.setStencilTest("greater", 0)
        
        -- Draw the texture
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(self.texture, self.x - self.diameter / 2, self.y - self.diameter / 2, 0, self.diameter / self.texture:getWidth(), self.diameter / self.texture:getHeight())
        
        -- Disable the stencil test
        love.graphics.setStencilTest()

        -- Draw a yellow box around the texture for debugging
        love.graphics.setColor(1, 1, 0)
        love.graphics.rectangle("line", self.x - self.diameter / 2, self.y - self.diameter / 2, self.diameter, self.diameter)
    else
        -- Fallback to a simple circle if no texture is present
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", self.x, self.y, self.diameter / 2)
    end
end


function Planet:drawGravityWells() -- not mathematically bound to gravitational calculations. 
    local radius50 = self.diameter * 2.5  
    local radius10 = self.diameter * 5  
    local radius01 = self.diameter * 10
    
    love.graphics.setColor(0, 1, 0, 0.2)
    love.graphics.circle("fill", self.x, self.y, radius50)
    love.graphics.setColor(1, 1, 0, 0.2)
    love.graphics.circle("fill", self.x, self.y, radius10)
    love.graphics.setColor(1, 0, 1, 0.2)
    love.graphics.circle("fill", self.x, self.y, radius01)
end

function Planet:getType()
    return self.type
end

function Planet:getName()
    return self.name
end

function Planet.getAllObjects()
    return planets
end

return Planet
