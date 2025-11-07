function DrawTriangle(p1, p2, p3, r, g, b, a)
    DrawPoly(
        p1.x, p1.y, p1.z,
        p2.x, p2.y, p2.z,
        p3.x, p3.y, p3.z,
        r, g, b, a
    )
end

function DrawSquare(centerPos, width, height, rotationDeg, color, fill, lineColor)
    if not color then color = {} end
    local halfW, halfH = width / 2, height / 2
    local rotRad = math.rad(rotationDeg)

    local cosR = math.cos(rotRad)
    local sinR = math.sin(rotRad)

    local function rotate(dx, dy)
        local x = dx * cosR - dy * sinR
        local y = dx * sinR + dy * cosR

        return x, y
    end

    local dx, dy = rotate(-halfW, -halfH)
    local p1 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)

    dx, dy = rotate(halfW, -halfH)
    local p2 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)

    dx, dy = rotate(halfW, halfH)
    local p3 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)

    dx, dy = rotate(-halfW, halfH)
    local p4 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)

    if fill then
        DrawTriangle(p1, p2, p3, color[1] or 255, color[2] or 255, color[3] or 255, color[4] or 255)
        DrawTriangle(p1, p3, p4, color[1] or 255, color[2] or 255, color[3] or 255, color[4] or 255)
    end
    DrawLine(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z, lineColor[1] or 255, lineColor[2] or 255, lineColor[3] or 255,
        lineColor[4] or 255)
    DrawLine(p2.x, p2.y, p2.z, p3.x, p3.y, p3.z, lineColor[1] or 255, lineColor[2] or 255, lineColor[3] or 255,
        lineColor[4] or 255)
    DrawLine(p3.x, p3.y, p3.z, p4.x, p4.y, p4.z, lineColor[1] or 255, lineColor[2] or 255, lineColor[3] or 255,
        lineColor[4] or 255)
    DrawLine(p4.x, p4.y, p4.z, p1.x, p1.y, p1.z, lineColor[1] or 255, lineColor[2] or 255, lineColor[3] or 255,
        lineColor[4] or 255)
end

exports("DrawSquare", DrawSquare)

--- Draws a simple horizontal progress bar in 3D space.
-- @param x, y, z  Center position of the bar.
-- @param width    Total bar width.
-- @param height   Total bar height.
-- @param progress Current progress value.
-- @param maxProgress Maximum progress value.
-- @param bgColor  Background color table: {r, g, b, a}
-- @param fgColor  Fill color table: {r, g, b, a}
function DrawProgress(x, y, z, width, height, progress, maxProgress, bgColor, fgColor)
    -- Normalize progress
    local pct = math.min(progress / maxProgress, 1.0)

    local halfW = width / 2
    local halfH = height / 2

    -- Bar background quad corners
    local bgP1 = vector3(x - halfW, y - halfH, z)
    local bgP2 = vector3(x + halfW, y - halfH, z)
    local bgP3 = vector3(x + halfW, y + halfH, z)
    local bgP4 = vector3(x - halfW, y + halfH, z)

    -- Draw background
    DrawTriangle(bgP1, bgP2, bgP3, bgColor[1], bgColor[2], bgColor[3], bgColor[4])
    DrawTriangle(bgP1, bgP3, bgP4, bgColor[1], bgColor[2], bgColor[3], bgColor[4])

    -- Filled portion width
    local filledW = width * pct
    local halfFilledW = filledW / 2

    -- Filled quad corners
    local fgP1 = vector3(x - halfW, y - halfH, z)
    local fgP2 = vector3(x - halfW + filledW, y - halfH, z)
    local fgP3 = vector3(x - halfW + filledW, y + halfH, z)
    local fgP4 = vector3(x - halfW, y + halfH, z)

    -- Draw filled portion
    DrawTriangle(fgP1, fgP2, fgP3, fgColor[1], fgColor[2], fgColor[3], fgColor[4])
    DrawTriangle(fgP1, fgP3, fgP4, fgColor[1], fgColor[2], fgColor[3], fgColor[4])

    -- Optional: draw outline
    DrawLine(bgP1.x, bgP1.y, bgP1.z, bgP2.x, bgP2.y, bgP2.z, 255, 255, 255, 255)
    DrawLine(bgP2.x, bgP2.y, bgP2.z, bgP3.x, bgP3.y, bgP3.z, 255, 255, 255, 255)
    DrawLine(bgP3.x, bgP3.y, bgP3.z, bgP4.x, bgP4.y, bgP4.z, 255, 255, 255, 255)
    DrawLine(bgP4.x, bgP4.y, bgP4.z, bgP1.x, bgP1.y, bgP1.z, 255, 255, 255, 255)
end

--- Draws a progress bar with configurable fill direction.
-- @param centerPos vector3 Center of the bar in world space.
-- @param width number Total width.
-- @param height number Total height.
-- @param rotationDeg number Rotation in degrees.
-- @param progress number Progress (0-1).
-- @param bgColor table {r,g,b,a}
-- @param fgColor table {r,g,b,a}
-- @param fillDirection string 'left', 'right', 'up', 'down'
function DrawProgressBar(centerPos, width, height, rotationDeg, progress, bgColor, fgColor, fillDirection)
    local halfW = width / 2
    local halfH = height / 2
    local rotRad = math.rad(rotationDeg)

    local cosR = math.cos(rotRad)
    local sinR = math.sin(rotRad)

    local function rotate(dx, dy)
        local x = dx * cosR - dy * sinR
        local y = dx * sinR + dy * cosR
        return x, y
    end

    -- Background corners
    local dx, dy = rotate(-halfW, -halfH)
    local p1 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)

    dx, dy = rotate(halfW, -halfH)
    local p2 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)

    dx, dy = rotate(halfW, halfH)
    local p3 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)

    dx, dy = rotate(-halfW, halfH)
    local p4 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)

    -- Draw background
    DrawTriangle(p1, p2, p3, bgColor[1], bgColor[2], bgColor[3], bgColor[4])
    DrawTriangle(p1, p3, p4, bgColor[1], bgColor[2], bgColor[3], bgColor[4])

    -- Clamp progress
    local pct = math.min(math.max(progress, 0.0), 1.0)

    -- Fill quad
    local f1, f2, f3, f4

    if fillDirection == 'left' then
        local filledW = width * pct
        dx, dy = rotate(-halfW, -halfH)
        f1 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)

        dx, dy = rotate(-halfW + filledW, -halfH)
        f2 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)

        dx, dy = rotate(-halfW + filledW, halfH)
        f3 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)

        dx, dy = rotate(-halfW, halfH)
        f4 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)
    elseif fillDirection == 'right' then
        local filledW = width * pct
        dx, dy = rotate(halfW - filledW, -halfH)
        f1 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)

        dx, dy = rotate(halfW, -halfH)
        f2 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)

        dx, dy = rotate(halfW, halfH)
        f3 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)

        dx, dy = rotate(halfW - filledW, halfH)
        f4 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)
    elseif fillDirection == 'up' then
        local filledH = height * pct
        dx, dy = rotate(-halfW, halfH - filledH)
        f1 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)

        dx, dy = rotate(halfW, halfH - filledH)
        f2 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)

        dx, dy = rotate(halfW, halfH)
        f3 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)

        dx, dy = rotate(-halfW, halfH)
        f4 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)
    elseif fillDirection == 'down' then
        local filledH = height * pct
        dx, dy = rotate(-halfW, -halfH)
        f1 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)

        dx, dy = rotate(halfW, -halfH)
        f2 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)

        dx, dy = rotate(halfW, -halfH + filledH)
        f3 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)

        dx, dy = rotate(-halfW, -halfH + filledH)
        f4 = vector3(centerPos.x + dx, centerPos.y + dy, centerPos.z)
    end

    -- Draw fill
    DrawTriangle(f1, f2, f3, fgColor[1], fgColor[2], fgColor[3], fgColor[4])
    DrawTriangle(f1, f3, f4, fgColor[1], fgColor[2], fgColor[3], fgColor[4])
end
