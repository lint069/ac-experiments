
local replay = {
    play = false,
    rewind = false,
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
    [2] = 16.6666667,
    [3] = 33.3333333,
    [4] = 66.6666667,
}

local sim = ac.getSim()

local replayConfigIni = ac.INIConfig.load(ac.getFolder(ac.FolderID.Cfg) .. '/replay.ini', ac.INIFormat.Extended)
local replayQuality = replayConfigIni:get('QUALITY', 'LEVEL', 3)
local replayHz = replayQualityPresets[replayQuality]

--#region helper functions

---@param text string Text displayed in the tooltip.
---@param padding? vec2 Default padding `vec2(5, 5)`
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

--#region drawing functions

local function drawTimeline()
    local progress = replay.frame / sim.replayFrames
    local lineStart = vec2(75, 30)
    local lineEnd = vec2(background.size.x - 75, lineStart.y)
    local lineThickness = 4

    ui.drawSimpleLine(lineStart, lineEnd, colors.timeline.unplayed, lineThickness)
    ui.drawSimpleLine(lineStart, vec2(math.clampN(75 + (progress * (background.size.x - 150)), lineStart.x, lineEnd.x), lineEnd.y), colors.timeline.played, lineThickness)

    local cursor = vec2(math.clampN(75 + (progress * (background.size.x - 150)), lineStart.x, background.size.x - 75), lineStart.y)
    ui.drawCircleFilled(cursor, 5, colors.timeline.circle)
    ui.drawCircle(cursor, 5, colors.timeline.circleBorder)

    ui.pushDWriteFont(app.font)

    local currentMin, currentSec = toMinSec(math.clampN(replay.frame / replayHz, 0, getReplayLength()))
    ui.dwriteDrawText(string.format('%d:%.2d', currentMin, currentSec), 14, vec2(30, lineStart.y - 10))

    local min, sec = toMinSec(getReplayLength())
    ui.dwriteDrawText(string.format('%d:%.2d', min, sec), 14, vec2(background.size.x - 60, lineEnd.y - 10))

    ui.popDWriteFont()
end

local showTextInput = false
local function drawButtons()
    local date = os.date('%d.%m.%y-%H:%M')
    local carName, trackName = ac.getCarName(0), ac.getTrackName()
    local replayName = 'replayUI-' .. date .. '-' .. carName .. '-' .. trackName
    replayName = replayName:gsub("%s+", "-")

    local saveString = showTextInput and 'Cancel' or 'Save Replay'
    local pressedEnter = false
    local nameChanged = false
    local fileName = replayName

    if ui.button(saveString, vec2()) then
        showTextInput = not showTextInput
    end
    setCursorlastItemHovered(ui.MouseCursor.Hand)

    ui.sameLine()

    if showTextInput then
        if ui.button('Save', vec2()) then
            ui.toast(ui.Icons.Save, 'Saved replay in: ' .. ac.getFolder(ac.FolderID.Replays))
            showTextInput = not showTextInput
        end
        setCursorlastItemHovered(ui.MouseCursor.Hand)
    end

    if showTextInput then
        fileName, nameChanged, pressedEnter = ui.inputText('', fileName)
    end

    if nameChanged then
        fileName = fileName
    end

    if pressedEnter then
        --saveReplay()
        showTextInput = false
        ui.toast(ui.Icons.Save, 'Replay saved in: ' .. ac.getFolder(ac.FolderID.Replays))
    end

    ui.sameLine()

    local playString = replay.play and 'Pause' or 'Play'

    if ui.button(playString, vec2()) then
        replay.speed = 1
        replay.play = not replay.play
    end
    setCursorlastItemHovered(ui.MouseCursor.Hand)

    ui.sameLine()

    if ui.button('Stop', vec2()) then
        replay.frame = 0
        ac.setReplayPosition(replay.frame, 1)
        replay.play = false
    end
    setCursorlastItemHovered(ui.MouseCursor.Hand)

    ui.sameLine()

    if ui.button('Skip', vec2()) then
        replay.frame = replay.frame + 1
        ac.setReplayPosition(replay.frame, 1)
        replay.play = false
    end
    setCursorlastItemHovered(ui.MouseCursor.Hand)

    ui.sameLine()

    local mult = replay.speed

    if ui.button(mult .. 'x FF', vec2()) then
        replay.speed = replay.speed + 1
        replay.play = true
    end
    setCursorlastItemHovered(ui.MouseCursor.Hand)

    ui.sameLine()

    if ui.button(mult .. 'x Rewind', vec2()) then
        replay.speed = replay.speed + 1
        replay.rewind = true
        replay.play = true
    end
    setCursorlastItemHovered(ui.MouseCursor.Hand)
end

--#endregion

ui.onExclusiveHUD(function(mode)
    if mode ~= 'replay' then return end

    ui.transparentWindow('replayUI', background.pos, background.size, false, true, function()
        background.size = vec2(1200, 130)
        background.pos = vec2((sim.windowSize.x / 2) - (background.size.x / 2), (sim.windowSize.y - 165) - (background.size.y / 2))

        ui.drawRectFilled(vec2(0, 0), background.size, rgbm(0, 0, 0, 0.3), 7, ui.CornerFlags.Top)

        drawTimeline()
        ui.offsetCursorY(50)
        drawButtons()
    end)
end)

function script.update(dt)
    replay.length = getReplayLength()

    if replay.frame == sim.replayFrames then
        replay.play = false
    end

    if replay.play then
        replay.frame = replay.frame + (dt * replayHz) * replay.speed
        ac.setReplayPosition(replay.frame, 1)
    end

    if replay.rewind then
        replay.frame = replay.frame - (dt * replayHz) * replay.speed
        ac.setReplayPosition(replay.frame, 1)
    end
end
