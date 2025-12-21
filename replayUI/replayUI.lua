
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
        circleBorder = rgbm(0.94, 0.94, 0.94, 0.94)
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

---@param sec number
---@return number hrs
---@return number min
---@return number sec
local function timeFromSeconds(sec)
    local h, m, s = math.floor(sec / 3600), math.floor((sec % 3600) / 60), math.floor(sec % 60)
    return h, m, s
end

---@param h number
---@param m number
---@param s number
local function formatTime(h, m, s)
    if h > 0 then
        return string.format('%d:%02d:%02d', h, m, s)
    else
        return string.format('%d:%02d', m, s)
    end
end

---@return number replayLength @replay length in seconds.
local function getReplayLength()
    return sim.replayFrames / replayHz
end

--#endregion helper functions

--#region drawing functions

local padding = vec2(4, 7)
local function drawTimeline()
    local progress = replay.frame / sim.replayFrames
    local lineStart = vec2(80, 30)
    local lineEnd = vec2(background.size.x - lineStart.x, lineStart.y)
    local lineThickness = 4

    ui.drawSimpleLine(lineStart, lineEnd, colors.timeline.unplayed, lineThickness)
    ui.drawSimpleLine(lineStart, vec2(lineStart.x + progress * (lineEnd.x - lineStart.x), lineEnd.y), colors.timeline.played, lineThickness)

    local cursor = vec2(lineStart.x + progress * (lineEnd.x - lineStart.x), lineStart.y)
    ui.drawCircleFilled(cursor, 5, colors.timeline.circle)
    ui.drawCircle(cursor, 5, colors.timeline.circleBorder)

    ui.pushDWriteFont(app.font)

    local currentHrs, currentMin, currentSec = timeFromSeconds(math.clampN(replay.frame / replayHz, 0, getReplayLength()))
    ui.dwriteDrawText(formatTime(currentHrs, currentMin, currentSec), 14, vec2(22, lineStart.y - 10))

    local hrs, min, sec = timeFromSeconds(getReplayLength())
    ui.dwriteDrawText(formatTime(hrs, min, sec), 14, vec2(background.size.x - 60, lineEnd.y - 10))

    ui.popDWriteFont()

    local timelineWidth = (lineEnd.x - lineStart.x)
    if ui.rectHovered(lineStart - padding, lineEnd + padding) then
        ui.setMouseCursor(ui.MouseCursor.Hand)

        if ui.mouseDown(ui.MouseButton.Left) or ui.isMouseDragging(ui.MouseButton.Left) then
            padding = vec2(30, 30)
            local mouseRelative = math.clampN(ui.mouseLocalPos().x - lineStart.x, 0, timelineWidth)
            local frame = (mouseRelative / timelineWidth) * sim.replayFrames

            replay.frame = frame
            ac.setReplayPosition(replay.frame, 1)
        else
            padding = vec2(4, 7)
        end
    end
end

local fileName = ''
local showTextInput = false
local function drawButtons()
    local date = os.date('%d.%m.%y-%H:%M')
    local carName, trackName = ac.getCarName(0), ac.getTrackName()
    local replayName = 'replayUI-' .. date .. '-' .. carName .. '-' .. trackName

    replayName = replayName:gsub("%s+", "-")

    local pressedEnter = false
    local saveButtonString = showTextInput and 'Cancel' or 'Save Replay'

    if ui.button(saveButtonString, vec2()) then
        showTextInput = not showTextInput
        if showTextInput then fileName = replayName end
    end

    ui.sameLine()

    if showTextInput then
        ui.setCursor(vec2(20, 85))
        fileName, _, pressedEnter = ui.inputText('', fileName)
    end

    ui.sameLine()

    if showTextInput then
        if ui.button('Save', vec2()) then
            --saveReplay()
            showTextInput = false
            ui.toast(ui.Icons.Save, 'Replay saved in: ' .. ac.getFolder(ac.FolderID.Replays))
        end
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

    ui.sameLine()

    if ui.button('Stop', vec2()) then
        replay.frame = 0
        ac.setReplayPosition(replay.frame, 1)
        replay.play = false
    end

    ui.sameLine()

    if ui.button('Skip', vec2()) then
        replay.frame = replay.frame + 1
        ac.setReplayPosition(replay.frame, 1)
        replay.play = false
    end

    ui.sameLine()

    local mult = replay.speed

    if ui.button(mult .. 'x FF', vec2()) then
        replay.speed = replay.speed + 1
        replay.play = true
    end

    ui.sameLine()

    if ui.button(mult .. 'x Rewind', vec2()) then
        replay.speed = replay.speed + 1
        replay.rewind = true
        replay.play = true
    end
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
