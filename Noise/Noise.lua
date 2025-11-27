
local settings = ac.storage {
    advanced = false,
    speed = 0.5,
    octaves = 1,
    persistence = 0.5,
    opacity = 1,
    frost = false,
    tint = rgb(0, 0, 0),
    sizeMult = 1,

    stepsX = 50,
    stepsY = 50,

    sizeX = 0.01,
    sizeY = 0.01,

    tooltipPadding = vec2(5, 5),
}

local time = 0

---@param p1 vec2
---@param p2 vec2
---@param dt number Delta time
---@param octaves? number
---@param persistence? number [0..1]
---@param opacity? number
local function drawNoise(p1, p2, dt, octaves, persistence, opacity)
    local dx = (p2.x - p1.x) / settings.stepsX
    local dy = (p2.y - p1.y) / settings.stepsY

    for i = 0, settings.stepsX - 1 do
        for j = 0, settings.stepsY - 1 do
            local x = p1.x + i * dx
            local y = p1.y + j * dy

            local n = math.perlin(vec3(x * settings.sizeX, y * settings.sizeY, time), octaves, persistence)
            local brightness = (n + 1) / 2

            local color = rgbm(brightness - settings.tint.r, brightness - settings.tint.g, brightness - settings.tint.b, opacity or 1)
            ui.drawRectFilled(vec2(x, y), vec2(x + dx, y + dy), color)
        end
    end

    time = time + settings.speed * dt
end

---@param p1 vec2
---@param p2 vec2
---@param changeCursor boolean?
---@param changeCursorTo ui.MouseCursor?
---@param callback fun()
local function checkHovered(p1, p2, changeCursor, changeCursorTo, callback)
    if ui.rectHovered(p1, p2) then
        if changeCursor then ui.setMouseCursor(changeCursorTo) end
        callback()
    end
end

---@param text string Text displayed in the tooltip
local function tooltip(text)
    if ui.itemHovered() then
        ui.tooltip(settings.tooltipPadding, function() ui.text(text) end)
    end
end

function script.windowMain(dt)
    if settings.frost then ui.forceSimplifiedComposition(true) end
    drawNoise(vec2(0, 0), vec2(300, 300) * settings.sizeMult, dt, settings.octaves, settings.persistence, settings.opacity)
end

-- spaghetti code ahead
function script.settings()
    ui.beginGroup(400)

    --ac.debug('mp', ui.mouseLocalPos())

    local sliderX = 20
    local sliderY = 279

    ui.dwriteText('Noise shader settings:', 18)

    --

    ui.sameLine(400)
    ui.configureStyle(ac.getUI().accentColor, false, true, 0.6)

    if ui.iconButton(ui.Icons.Reset, vec2(50, 25), 5) then
        settings.speed = 0.5
        settings.octaves = 1
        settings.persistence = 0.5
        settings.opacity = 1
        settings.frost = false
        settings.tint.r = 0
        settings.tint.g = 0
        settings.tint.b = 0
        settings.sizeMult = 1
        settings.sizeX = 0.01
        settings.sizeY = 0.01
        settings.stepsX = 50
        settings.stepsY = 50
    end

    --

    local speedRef = refnumber(settings.speed)
    checkHovered(vec2(sliderX, 57), vec2(sliderY, 79), true, ui.MouseCursor.ResizeEW, function()
        if ui.mouseReleased(ui.MouseButton.Right) then
            settings.speed = 0.5
        end
    end)

    if ui.slider('Noise speed', speedRef, 0.1, 1, '%.2f') then
        settings.speed = speedRef.value
    end

    --

    local sizeRef = refnumber(settings.sizeX)
    checkHovered(vec2(sliderX, 83), vec2(sliderY, 105), true, ui.MouseCursor.ResizeEW, function()
        if ui.mouseReleased(ui.MouseButton.Right) then
            settings.sizeX = 0.01
            settings.sizeY = 0.01
        end
    end)

    if ui.slider('Noise size', sizeRef, 0.001, 0.1, '%.3f') then
        settings.sizeX = sizeRef.value
        settings.sizeY = sizeRef.value
    end

    --

    local resolutionRef = refnumber(settings.stepsX)
    checkHovered(vec2(sliderX, 109), vec2(sliderY, 131), true, ui.MouseCursor.ResizeEW, function()
        if ui.mouseReleased(ui.MouseButton.Right) then
            settings.stepsX = 50
            settings.stepsY = 50
        end
    end)

    if ui.slider('Noise resolution', resolutionRef, 1, 200, '%.0f', true) then
        settings.stepsX = resolutionRef.value
        settings.stepsY = resolutionRef.value
    end

    --

    checkHovered(vec2(sliderX, 140), vec2(42, 162), true, ui.MouseCursor.Hand, function() end)

    ui.offsetCursorY(5)
    if ui.checkbox('Advanced', settings.advanced) then
        settings.advanced = not settings.advanced
    end

    if not settings.advanced then
        ui.offsetCursorY(1)
        ui.endGroup()
        return
    end

    --

    ui.offsetCursorY(3)

    local octaves = refnumber(settings.octaves)
    checkHovered(vec2(sliderX, 169), vec2(sliderY, 191), true, ui.MouseCursor.ResizeEW, function()
        if ui.mouseReleased(ui.MouseButton.Right) then
            settings.octaves = 1
        end
    end)

    if ui.slider('octaves', octaves, 1, 5, '%.0f', true) then
        settings.octaves = octaves.value
    end
    tooltip('More octaves add detail to the noise.')

    --

    local persistence = refnumber(settings.persistence)
    checkHovered(vec2(sliderX, 195), vec2(sliderY, 217), true, ui.MouseCursor.ResizeEW, function()
        if ui.mouseReleased(ui.MouseButton.Right) then
            settings.persistence = 0.5
        end
    end)

    if ui.slider('persistence', persistence, 0, 1, '%.2f') then
        settings.persistence = persistence.value
    end

    --

    local opacity = refnumber(settings.opacity)
    checkHovered(vec2(sliderX, 221), vec2(sliderY, 243), true, ui.MouseCursor.ResizeEW, function()
        if ui.mouseReleased(ui.MouseButton.Right) then
            settings.opacity = 1
        end
    end)

    if ui.slider('opacity', opacity, 0, 1, '%.2f') then
        settings.opacity = opacity.value
    end

    --

    ui.offsetCursorY(10)
    ui.dwriteText('General settings:', 18)

    --

    checkHovered(vec2(sliderX, 287), vec2(42, 309), true, ui.MouseCursor.Hand, function() end)

    ui.offsetCursorY(3)
    if ui.checkbox('Pause frost effect', settings.frost) then
        settings.frost = not settings.frost
    end

    ui.endGroup()

    --

    ui.beginGroup(125)
    ui.offsetCursorY(5)

    local redTintRef = refnumber(settings.tint.r)
    local greenTintRef = refnumber(settings.tint.g)
    local blueTintRef = refnumber(settings.tint.b)

    ui.dwriteText('Tint', 14)

    checkHovered(vec2(sliderX, 340), vec2(101, 362), true, ui.MouseCursor.ResizeEW, function()
        if ui.mouseReleased(ui.MouseButton.Right) then
            settings.tint.r = 0
        end
    end)

    if ui.slider('R', redTintRef, 0, 1, '%.2f') then
        settings.tint.r = redTintRef.value
    end


    checkHovered(vec2(130, 340), vec2(211, 362), true, ui.MouseCursor.ResizeEW, function()
        if ui.mouseReleased(ui.MouseButton.Right) then
            settings.tint.g = 0
        end
    end)

    ui.sameLine(110)
    if ui.slider('G', greenTintRef, 0, 1, '%.2f') then
        settings.tint.g = greenTintRef.value
    end


    checkHovered(vec2(240, 340), vec2(321, 362), true, ui.MouseCursor.ResizeEW, function()
        if ui.mouseReleased(ui.MouseButton.Right) then
            settings.tint.b = 0
        end
    end)

    ui.sameLine(220)
    if ui.slider('B', blueTintRef, 0, 1, '%.2f') then
        settings.tint.b = blueTintRef.value
    end

    ui.endGroup()

    ui.beginGroup(400)
    ui.offsetCursorY(10)

    local sizeMultRef = refnumber(settings.sizeMult)
    checkHovered(vec2(sliderX, 376), vec2(sliderY, 398), true, ui.MouseCursor.ResizeEW, function()
        if ui.mouseReleased(ui.MouseButton.Right) then
            settings.sizeMult = 1
        end
    end)

    if ui.slider('Size Multiplier', sizeMultRef, 0.3, 2, '%.2f') then
        settings.sizeMult = sizeMultRef.value
    end

    ui.offsetCursorY(5) -- extra padding
    ui.endGroup()
end
