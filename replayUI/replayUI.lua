
local replay = {
    play = false,
    frame = 0,
    length = 0, --in seconds
    speed = 1 --speed multiplier
}

local background = {
    pos = vec2(),
    size = vec2()
}

local colors = {
    timeline = {
        unplayed = rgbm(0.3, 0.3, 0.3, 1),
        played = rgbm(0.9, 0.9, 0.9, 1),
        circle = rgbm(0.85, 0.85, 0.85, 1),
        circleBorder = rgbm(0.95, 0.95, 0.95, 0.95)
    }
}

local app = {
    font = ui.DWriteFont('Geist', './assets/Geist-Regular.ttf'):spacing(-0.5, 0, 4)
}

local replayQualityPresets = {
    [0] = 8,
    [1] = 12,
    [2] = 16,
    [3] = 33,
    [4] = 67,
}

local sim = ac.getSim()

local replayConfigIni = ac.INIConfig.load(ac.getFolder(ac.FolderID.Cfg) .. '/replay.ini', ac.INIFormat.Extended)
local replayQuality = replayConfigIni:get('QUALITY', 'LEVEL', 3)
local replayHz = replayQualityPresets[replayQuality]

--#region helper functions

---@param padding? vec2 Default padding `vec2(5, 5)`
---@param text string Text displayed in the tooltip.
local function tooltip(text, padding)
    if ui.itemHovered() then
        ui.tooltip(padding or vec2(5, 5), function() ui.text(text) end)
    end
end

---@param cursorType ui.MouseCursor
local function setCursorlastItemHovered(cursorType)
    if ui.itemHovered() then
        ui.setMouseCursor(cursorType)
    end
end

---@param s number
---@return number min
---@return number sec
local function toMinSec(s)
    local min, sec = math.floor(s / 60), math.floor(s % 60)
    return min, sec
end

---@return number replayLength @replay length in seconds.
local function getReplayLength()
    return sim.replayFrames / replayHz
end

--#endregion helper functions

local function drawTimeline()
    local progress = replay.frame / sim.replayFrames
    local lineStart = vec2(75, 30)
    local lineEnd = vec2(background.size.x - 75, lineStart.y)
    local lineThickness = 4

    ui.drawSimpleLine(lineStart, lineEnd, colors.timeline.unplayed, lineThickness)
    ui.drawSimpleLine(lineStart, vec2(math.clamp(75 + (progress * (background.size.x - 150)), 0, lineEnd.x), lineEnd.y), colors.timeline.played, lineThickness)

    local cursor = vec2(math.clamp(75 + (progress * (background.size.x - 150)), 0, background.size.x - 75), lineStart.y)
    ui.drawCircleFilled(cursor, 5, colors.timeline.circle)
    ui.drawCircle(cursor, 5, colors.timeline.circleBorder)

    ui.pushDWriteFont(app.font)

    local currentMin, currentSec = toMinSec(math.clampN(replay.frame / replayHz, 0, getReplayLength()))
    ui.dwriteDrawText(string.format('%d:%.2d', currentMin, currentSec), 14, vec2(30, lineStart.y - 10))

    local min, sec = toMinSec(getReplayLength())
    ui.dwriteDrawText(string.format('%d:%.2d', min, sec), 14, vec2(background.size.x - 60, lineEnd.y - 10))

    ui.popDWriteFont()
end

local function drawReplayHUD()
    background.size = vec2(1200, 130)
    background.pos = vec2((sim.windowSize.x / 2) - (background.size.x / 2), (sim.windowSize.y - 165) - (background.size.y / 2))

    ui.drawRectFilled(vec2(0, 0), background.size, rgbm(0, 0, 0, 0.3), 7, ui.CornerFlags.Top)

    drawTimeline()


    ui.offsetCursorY(75)

    local playString = replay.play and 'pause' or 'play'

    if ui.button(playString, vec2(), replay.play) then
        replay.play = not replay.play
    end
    setCursorlastItemHovered(ui.MouseCursor.Hand)
end

ui.onExclusiveHUD(function(mode)
    if mode ~= 'replay' then return end

    ui.transparentWindow('background', background.pos, background.size, false, true, function()
        drawReplayHUD()
    end)
end)

function script.update(dt)
    replay.length = getReplayLength()
    ac.debug('replay length', getReplayLength())

    if replay.play then
        replay.frame = replay.frame + (dt * replayHz) * replay.speed
        ac.setReplayPosition(replay.frame, 1)
    end
end
