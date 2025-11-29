local settings = ac.storage {
    advanced = false,
    speed = 0.5,
    octaves = 1,
    persistence = 0.5,
    opacity = 1,
    frost = false,
    tint = rgb(0, 0, 0),
    sizeMult = 1,

    steps = vec2(50, 50),
    size = vec2(0.01, 0.01),

    tooltipPadding = vec2(5, 5),
}

local time = 0
local lastSpeed = 0
local appwindow = ac.accessAppWindow('IMGUI_LUA_Noise_main')

---@param p1 vec2
---@param p2 vec2
---@param dt number Delta time
---@param octaves? number
---@param persistence? number [0..1]
---@param opacity? number
local function drawNoise(p1, p2, dt, octaves, persistence, opacity)
    local dx = (p2.x - p1.x) / settings.steps.x
    local dy = (p2.y - p1.y) / settings.steps.y

    for i = 0, settings.steps.x - 1 do
        for j = 0, settings.steps.y - 1 do
            local x = p1.x + i * dx
            local y = p1.y + j * dy

            local n = math.perlin(vec3(x * settings.size.x, y * settings.size.y, time), octaves, persistence)
            local brightness = (n + 1) / 2

            local color = rgbm(brightness - settings.tint.r, brightness - settings.tint.g, brightness - settings.tint.b, opacity or 1)
            ui.drawRectFilled(vec2(x, y), vec2(x + dx, y + dy), color)
        end
    end

    time = time + settings.speed * dt
end

local function resizeApp()
    if not appwindow:valid() then return end
    appwindow:resize(vec2(300, 300) * settings.sizeMult)
end

---@param p1 vec2
---@param p2 vec2
---@param changeCursor boolean
---@param cursor ui.MouseCursor?
---@param callback fun()
---@return boolean hovered
local function onHover(p1, p2, changeCursor, cursor, callback)
    if ui.rectHovered(p1, p2) then
        if changeCursor then ui.setMouseCursor(cursor) end
        callback()
        return true
    end
    return false
end

---@param text string Text displayed in the tooltip
local function tooltip(text)
    if ui.itemHovered() then
        ui.tooltip(settings.tooltipPadding, function() ui.text(text) end)
    end
end

---@param dt number Delta time
---@param filepath string File path to save the image in
local function savePatternAsImage(dt, filepath)
    local canvas = ui.ExtraCanvas(vec2(300, 300) * settings.sizeMult, 0, render.AntialiasingMode.CMAA, render.TextureFormat.R8G8B8A8.UNorm)

    canvas:update(function()
        drawNoise(vec2(0, 0), vec2(300, 300) * settings.sizeMult, dt, settings.octaves, settings.persistence, settings.opacity)
    end)
    canvas:save(filepath, ac.ImageFormat.PNG)
end

function script.windowMain(dt)
    if settings.frost then ui.forceSimplifiedComposition(true) end
    drawNoise(vec2(0, 0), vec2(300, 300) * settings.sizeMult, dt, settings.octaves, settings.persistence, settings.opacity)
    resizeApp()
end

--spaghetti code
function script.settings(dt)
    ac.debug('mp', ui.mouseLocalPos())

    local sliderStart = 20
    local sliderEnd = 279

    ui.beginGroup(400)

    ui.dwriteText('Noise shader settings:', 18)

    ---

    ui.sameLine(400)
    ui.configureStyle(ac.getUI().accentColor, false, false, 0.7)

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
        settings.size.x = 0.01
        settings.size.y = 0.01
        settings.steps.x = 50
        settings.steps.y = 50
    end

    ---

    local speedRef = refnumber(settings.speed)
    onHover(vec2(sliderStart, 59), vec2(sliderEnd, 81), true, ui.MouseCursor.ResizeEW, function()
        if ui.mouseReleased(ui.MouseButton.Right) then
            settings.speed = 0.5
        end
    end)

    if ui.slider('Noise speed', speedRef, 0.05, 1, '%.2f') then
        settings.speed = speedRef.value
    end

    ---

    local sizeRef = refnumber(settings.size.x)
    onHover(vec2(sliderStart, 85), vec2(sliderEnd, 107), true, ui.MouseCursor.ResizeEW, function()
        if ui.mouseReleased(ui.MouseButton.Right) then
            settings.size.x = 0.01
            settings.size.y = 0.01
        end
    end)

    if ui.slider('Noise size', sizeRef, 0.001, 0.1, '%.3f') then
        settings.size.x = sizeRef.value
        settings.size.y = sizeRef.value
    end

    ---

    local resolutionRef = refnumber(settings.steps.x)
    onHover(vec2(sliderStart, 111), vec2(sliderEnd, 133), true, ui.MouseCursor.ResizeEW, function()
        if ui.mouseReleased(ui.MouseButton.Right) then
            settings.steps.x = 50
            settings.steps.y = 50
        end
    end)

    if ui.slider('Noise resolution', resolutionRef, 1, 200, '%.0f', true) then
        settings.steps.x = resolutionRef.value
        settings.steps.y = resolutionRef.value
    end

    ---

    onHover(vec2(sliderStart, 142), vec2(42, 164), true, ui.MouseCursor.Hand, function() end)

    ui.offsetCursorY(5)
    if ui.checkbox('Advanced', settings.advanced) then
        settings.advanced = not settings.advanced
    end

    if not settings.advanced then
        ui.offsetCursorY(1)
        ui.endGroup()
        return
    end

    ---

    ui.offsetCursorY(3)

    local octaves = refnumber(settings.octaves)
    onHover(vec2(sliderStart, 171), vec2(sliderEnd, 193), true, ui.MouseCursor.ResizeEW, function()
        if ui.mouseReleased(ui.MouseButton.Right) then
            settings.octaves = 1
        end
    end)

    if ui.slider('octaves', octaves, 1, 5, '%.0f', true) then
        settings.octaves = octaves.value
    end
    tooltip('More octaves add detail to the noise.')

    ---

    local persistence = refnumber(settings.persistence)
    onHover(vec2(sliderStart, 197), vec2(sliderEnd, 219), true, ui.MouseCursor.ResizeEW, function()
        if ui.mouseReleased(ui.MouseButton.Right) then
            settings.persistence = 0.5
        end
    end)

    if ui.slider('persistence', persistence, 0, 1, '%.2f') then
        settings.persistence = persistence.value
    end

    ---

    local opacity = refnumber(settings.opacity)
    onHover(vec2(sliderStart, 223), vec2(sliderEnd, 245), true, ui.MouseCursor.ResizeEW, function()
        if ui.mouseReleased(ui.MouseButton.Right) then
            settings.opacity = 1
        end
    end)

    if ui.slider('opacity', opacity, 0, 1, '%.2f') then
        settings.opacity = opacity.value
    end

    ---

    ui.offsetCursorY(10)
    ui.dwriteText('General settings:', 18)

    ---

    onHover(vec2(sliderStart, 289), vec2(42, 311), true, ui.MouseCursor.Hand, function() end)

    ui.offsetCursorY(3)
    if ui.checkbox('Pause frost effect', settings.frost) then
        settings.frost = not settings.frost
    end

    ui.endGroup()

    ---

    ui.beginGroup(125)
    ui.offsetCursorY(5)

    local redTintRef = refnumber(settings.tint.r)
    local greenTintRef = refnumber(settings.tint.g)
    local blueTintRef = refnumber(settings.tint.b)

    ui.dwriteText('Tint', 14)

    onHover(vec2(sliderStart, 342), vec2(101, 364), true, ui.MouseCursor.ResizeEW, function()
        if ui.mouseReleased(ui.MouseButton.Right) then
            settings.tint.r = 0
        end
    end)

    if ui.slider('R', redTintRef, 0, 1, '%.2f') then
        settings.tint.r = redTintRef.value
    end


    onHover(vec2(130, 342), vec2(211, 364), true, ui.MouseCursor.ResizeEW, function()
        if ui.mouseReleased(ui.MouseButton.Right) then
            settings.tint.g = 0
        end
    end)

    ui.sameLine(110)
    if ui.slider('G', greenTintRef, 0, 1, '%.2f') then
        settings.tint.g = greenTintRef.value
    end


    onHover(vec2(240, 342), vec2(321, 364), true, ui.MouseCursor.ResizeEW, function()
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
    onHover(vec2(sliderStart, 378), vec2(sliderEnd, 400), true, ui.MouseCursor.ResizeEW, function()
        if ui.mouseReleased(ui.MouseButton.Right) then
            settings.sizeMult = 1
        end
    end)

    if ui.slider('Size Multiplier', sizeMultRef, 0.3, 2, '%.2f') then
        settings.sizeMult = sizeMultRef.value
    end

    ---

    ui.offsetCursorY(30)

    local flags = 0
    local screenshotFolder = ac.getFolder(ac.FolderID.Screenshots)
    local folderExists = io.dirExists(screenshotFolder .. '/noise')
    local windowPos = ui.windowPos()

    if settings.steps.x > 125 then
        flags = ui.ButtonFlags.Disabled
    end

    local hovered = onHover(vec2(20, 434), vec2(240, 464), true, ui.MouseCursor.Hand, function() end)
    if flags == 0 then
        if hovered and settings.speed ~= 0 then
            lastSpeed = settings.speed
            settings.speed = 0
        elseif not hovered and settings.speed == 0 then
            settings.speed = lastSpeed
        end
    end

    if ui.button('Export current pattern to image', vec2(220, 30), flags) then
        if folderExists then goto exists end

        io.createDir(screenshotFolder .. '/noise')
        --ac.log(folderExists)

        ::exists::

        os.saveFileDialog({
                title = 'Save noise pattern as an image',
                defaultFolder = screenshotFolder .. '/noise',
                fileTypes = { { name = 'Images', mask = '*.png' } },
                defaultExtension = 'png',
                addAllFilesFileType = false,
                okButtonLabel = 'Save',
                flags = os.DialogFlags.PathMustExist
            },
            function(err, filename)
                if err or not filename then
                    return
                end

                savePatternAsImage(dt, filename)

                ui.popup(function()
                    ui.offsetCursorY(3)
                    ui.text('Image saved!')
                    ui.sameLine()
                    ui.offsetCursorY(-3)
                    if ui.button('View in folder') then
                        os.openInExplorer(screenshotFolder .. '/noise')
                    end
                end, {
                    position = vec2(windowPos.x + 275, windowPos.y + 430),
                    size = vec2(200, 38),
                    padding = vec2(8, 8)
                })
            end
        )
    end
    tooltip('Exports the current noise pattern to a PNG image.')

    ui.offsetCursorY(5)
    ui.endGroup()
end