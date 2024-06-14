-- Importing necessary libraries and modules
local Planet = require("planets")
local Satellites = require("satellites")
local Debris = require("debris")

-- Define global variables
local G = 6.67430e-11  -- Gravitational constant

camera = {
    x = 0,
    y = 0,
    zoom = 0.3, -- normal zoom is 1
    rotation = 0,
    panSpeed = 300,
    drag = false,
    dragStartX = 0,
    dragStartY = 0
}

local isPaused = false
local showGravityWells = false
local plottedPath = nil

local timeSpeed = 1 -- This will be the multiplier for the normal time speed of 0.1

-- Define the debug dialog for spawning satellites
debugDialog = {
    isVisible = false,
    x = 0,
    y = 0,
    worldX = 0,
    worldY = 0,
    width = 150,
    height = 100
}

-- Define the options menu
local optionsMenu = {
    isVisible = false,
    x = 100,
    y = 100,
    width = 200,
    height = 150,
    options = {
        "Planetary Orbits",
        "Satellite Path",
        "Gravity Well",
        "Object Context"
    }
}

-- Define the satellite status window
local satStatusWindow = {
    isVisible = false,
    satellite = nil,
    x = 0,
    y = love.graphics.getHeight() - 100,
    width = love.graphics.getWidth(),
    height = 100
}

local gridSize = 25
local gridColor = {0,1,0}
local axisColor = {1,1,0}

-- Initialize planets and satellites
--Planet:new(type, mass, diameter, distance, speed, ellipse, orbitEntity)
local starOne = Planet:new("star", 10000, 1000, 0, 0.5, 1, {0,0})  -- Centered in the world
local planetOne = Planet:new("planet", 250, 150, 16000, 0.05, 1, starOne)

function love.load()
    math.randomseed(os.time())
end

function love.update(dt)
    if camera.drag then
        local mx, my = love.mouse.getPosition()
        camera.x = camera.x - (mx - camera.dragStartX) / camera.zoom
        camera.y = camera.y - (my - camera.dragStartY) / camera.zoom
        camera.dragStartX, camera.dragStartY = mx, my
    end

    if satStatusWindow.isVisible and satStatusWindow.satellite then
        local sat = satStatusWindow.satellite
        camera.x = sat.x
        camera.y = sat.y
    else
        if love.keyboard.isDown("left") then
            camera.x = camera.x - camera.panSpeed * dt / camera.zoom
        end
        if love.keyboard.isDown("right") then
            camera.x = camera.x + camera.panSpeed * dt / camera.zoom
        end
        if love.keyboard.isDown("up") then
            camera.y = camera.y - camera.panSpeed * dt / camera.zoom
        end
        if love.keyboard.isDown("down") then
            camera.y = camera.y + camera.panSpeed * dt / camera.zoom
        end
    end

    if not isPaused then
        local simulationDt = dt * timeSpeed * 0.1
        for _, obj in ipairs(Planet.getAllObjects()) do
            obj:update(simulationDt)
        end

        Satellites.updateAll(simulationDt, Planet.getAllObjects())
        Debris.updateAll(simulationDt)
    end
end

function love.draw()
    love.graphics.push()
    love.graphics.translate(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
    love.graphics.scale(camera.zoom, camera.zoom)
    love.graphics.translate(-camera.x, -camera.y)
    
    for _, obj in ipairs(Planet.getAllObjects()) do
        obj:draw()
    end

    if showGravityWells then
        for _, obj in ipairs(Planet.getAllObjects()) do
            obj:drawGravityWells()
        end
    end

    Satellites.drawAll()
    Debris.drawAll()

    if plottedPath then
        drawPath(plottedPath, 200)
    end
    
    love.graphics.pop()

    -- Draw the time control interface
    drawTimeControlInterface()

    if debugDialog.isVisible then
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", debugDialog.x, debugDialog.y, debugDialog.width, debugDialog.height)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Sat. Spawn", debugDialog.x + 10, debugDialog.y + 10)
        love.graphics.print("Small", debugDialog.x + 10, debugDialog.y + 30)
        love.graphics.print("Medium", debugDialog.x + 10, debugDialog.y + 50)
        love.graphics.print("Large", debugDialog.x + 10, debugDialog.y + 70)
    end

    if optionsMenu.isVisible then
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", optionsMenu.x, optionsMenu.y, optionsMenu.width, optionsMenu.height)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Sim Options", optionsMenu.x + 10, optionsMenu.y + 10)
        for i, option in ipairs(optionsMenu.options) do
            love.graphics.print(option, optionsMenu.x + 10, optionsMenu.y + 30 + (i - 1) * 20)
        end
    end

    if satStatusWindow.isVisible and satStatusWindow.satellite then
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", satStatusWindow.x, satStatusWindow.y, satStatusWindow.width, satStatusWindow.height)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Sat Options", satStatusWindow.x + 10, satStatusWindow.y + 10)
        love.graphics.print("Plot Course", satStatusWindow.x + 10, satStatusWindow.y + 30)
        love.graphics.print("Clear Course", satStatusWindow.x + 10, satStatusWindow.y + 50)
        love.graphics.print("Explode", satStatusWindow.x + 10, satStatusWindow.y + 70)
        
        local sat = satStatusWindow.satellite
        love.graphics.print("Telemetry:", satStatusWindow.x + 150, satStatusWindow.y + 10)
        love.graphics.print("Position: (" .. string.format("%.2f", sat.x) .. ", " .. string.format("%.2f", sat.y) .. ")", satStatusWindow.x + 150, satStatusWindow.y + 30)
        love.graphics.print("Velocity: (" .. string.format("%.2f", sat.xVel) .. ", " .. string.format("%.2f", sat.yVel) .. ")", satStatusWindow.x + 150, satStatusWindow.y + 50)
        love.graphics.print("Orientation: " .. string.format("%.2f", math.deg(sat.orientation)) .. "°", satStatusWindow.x + 150, satStatusWindow.y + 70)
    end

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", love.graphics.getWidth() - 150, 10, 140, 70)
    love.graphics.setColor(1, 1, 1)
    local centerX = camera.x
    local centerY = camera.y
    local zoomPercentage = camera.zoom * 100
    love.graphics.print("Center X: " .. string.format("%.2f", centerX), love.graphics.getWidth() - 140, 20)
    love.graphics.print("Center Y: " .. string.format("%.2f", centerY), love.graphics.getWidth() - 140, 40)
    love.graphics.print("Zoom: " .. string.format("%.2f", zoomPercentage) .. "%", love.graphics.getWidth() - 140, 60)

    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("fill", love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, 2)
    --uncomment to see sample noise texture
    --love.graphics.draw(planetOne.texture, 0, 0)
end

function love.mousepressed(x, y, button)
    if button == 2 then -- Right mouse button
        camera.drag = true
        camera.dragStartX, camera.dragStartY = x, y
    end

    -- Check if clicking outside the debug dialogue
    if debugDialog.isVisible and (x < debugDialog.x or x > debugDialog.x + debugDialog.width or y < debugDialog.y or y > debugDialog.y + debugDialog.height) then
        debugDialog.isVisible = false
    end

    -- Check if clicking the time control arrows
    if button == 1 then
        if isPointInRectangle(x, y, 10, 10, 20, 20) then -- Left arrow
            timeSpeed = math.max(timeSpeed - 0.1, 0.1)
        elseif isPointInRectangle(x, y, 230, 10, 20, 20) then -- Right arrow
            timeSpeed = timeSpeed + 0.1
        end
    end

    -- Check if clicking inside the debug dialogue options
    if debugDialog.isVisible and button == 1 then
        if x >= debugDialog.x + 10 and x <= debugDialog.x + 140 then
            if y >= debugDialog.y + 30 and y <= debugDialog.y + 45 then
                spawnSatellite("small")
            elseif y >= debugDialog.y + 50 and y <= debugDialog.y + 65 then
                spawnSatellite("medium")
            elseif y >= debugDialog.y + 70 and y <= debugDialog.y + 85 then
                spawnSatellite("large")
            end
        end
    end

    -- Check if clicking inside the options menu
    if optionsMenu.isVisible and button == 1 then
        if x >= optionsMenu.x + 10 and x <= optionsMenu.x + 190 then
            if y >= optionsMenu.y + 30 and y <= optionsMenu.y + 45 then
                print("Planetary Orbits selected")
                optionsMenu.isVisible = false
            elseif y >= optionsMenu.y + 50 and y <= optionsMenu.y + 65 then
                print("Satellite Path selected")
                optionsMenu.isVisible = false
            elseif y >= optionsMenu.y + 70 and y <= optionsMenu.y + 85 then
                showGravityWells = not showGravityWells
                print("Gravity Well toggled:", showGravityWells)
                optionsMenu.isVisible = false
            elseif y >= optionsMenu.y + 90 and y <= optionsMenu.y + 105 then
                print("Object Context selected")
                optionsMenu.isVisible = false
            end
        end
    end

    -- Check if clicking on a satellite to show the status window
    if button == 1 then
        local worldX, worldY = trueCoords(love.mouse:getPosition())
        for _, satellite in ipairs(Satellites.satellites) do
            if isPointInSatellite(worldX, worldY, satellite) then
                -- Show satellite status window
                satStatusWindow.isVisible = true
                satStatusWindow.satellite = satellite
                return
            end
        end
    end

    -- Check if clicking inside the satellite status window
    if satStatusWindow.isVisible and button == 1 then
        if x >= satStatusWindow.x + 10 and x <= satStatusWindow.x + 140 then
            if y >= satStatusWindow.y + 30 and y <= satStatusWindow.y + 50 then
                plotCourse(satStatusWindow.satellite)
            elseif y >= satStatusWindow.y + 50 and y <= satStatusWindow.y + 70 then
                plottedPath = nil
            elseif y >= satStatusWindow.y + 70 and y <= satStatusWindow.y + 90 then
                satStatusWindow.satellite:explode()
            end
        end
    end
    love.graphics.draw(planetOne.texture, 0, 0)
end

function love.mousereleased(x, y, button)
    if button == 2 then
        camera.drag = false
    end
end

function love.mousemoved(x, y, dx, dy)
    -- Placeholder for future mouse move logic
end

function love.wheelmoved(x, y)
    if y > 0 then
        camera.zoom = camera.zoom * 1.1
    elseif y < 0 then
        camera.zoom = camera.zoom / 1.1
    end
end

function love.keypressed(key)
    if key == 'd' then
        local x, y = love.mouse.getPosition()
        debugDialog.x = x
        debugDialog.y = y
        debugDialog.isVisible = true
    elseif key == 'escape' then
        debugDialog.isVisible = false
        optionsMenu.isVisible = false
        hideSatelliteOptions()
        satStatusWindow.isVisible = false
        satStatusWindow.satellite = nil
    elseif key == 'tab' then
        optionsMenu.isVisible = not optionsMenu.isVisible
    elseif key == 'p' then
        isPaused = not isPaused
        hideSatelliteOptions()
        if not isPaused then
            plottedPath = nil
        end
    elseif key == '=' then
        camera.zoom = camera.zoom * 1.1
    elseif key == '-' then
        camera.zoom = camera.zoom / 1.1
    end
end

function randomNumber(min, max)
    return math.random(min, max)
end

function isPointInRectangle(px, py, x, y, w, h)
    return px >= x and px <= x + w and py >= y and py <= y + h
end

function drawPath(path, length)
    love.graphics.setColor(1, 150 / 255, 255 / 255)
    love.graphics.setLineWidth(10)
    
    for i = 2, length do
        local p1 = path[i - 1]
        local p2 = path[i]

        love.graphics.line(p1.x, p1.y, p2.x, p2.y)
    end
end

function hideSatelliteOptions()
    satStatusWindow.isVisible = false
    satStatusWindow.satellite = nil
end

function trueCoords(screenX, screenY)
    local screenWidth, screenHeight = love.graphics.getWidth(), love.graphics.getHeight()
    local worldX = screenX - screenWidth / 2
    local worldY = screenY - screenHeight / 2

    worldX = worldX / camera.zoom
    worldY = worldY / camera.zoom
    
    local cosR = math.cos(-camera.rotation)
    local sinR = math.sin(-camera.rotation)
    local x = worldX * cosR - worldY * sinR
    local y = worldX * sinR + worldY * cosR

    worldX = x + camera.x
    worldY = y + camera.y

    return worldX, worldY
end

function drawTimeControlInterface()
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("fill", 10, 10, 20, 20)  -- Left arrow
    love.graphics.rectangle("fill", 230, 10, 20, 20)  -- Right arrow

    love.graphics.setColor(0, 0, 0)
    love.graphics.polygon("fill", 30, 10, 30, 30, 10, 20)  -- Left arrow shape
    love.graphics.polygon("fill", 230, 10, 250, 20, 230, 30)  -- Right arrow shape

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Time: " .. string.format("%.1f", timeSpeed * 100) .. "%", 40, 10)
end
