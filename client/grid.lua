Grid         = {}
Grid.__index = Grid

local Grids  = {}

exports("GetClass", function(...)
    return Grid
end)

function GetGridAtWorldPos(worldPos)
    for _, grid in ipairs(Grids) do
        local row, col = grid:GetCellAtWorldPos(worldPos)
        if row and col then
            return {
                grid = grid,
                row = row,
                col = col,
                cell = grid.cells[row][col],
                uid = ("grid_%d_%d_%d"):format(_, row, col),
                clickable = true
            }
        end
    end

    return nil
end

exports("GetGridAtWorldPos", GetGridAtWorldPos)

function IsHoldingCell()
    for _, grid in ipairs(Grids) do
        if grid.isHolding then
            return true
        end
    end
    return false
end

exports("IsHoldingCell", IsHoldingCell)

---@param centerPos vector3 -- center of grid
---@param rows number -- how many rows
---@param cols number -- how many cols
---@param cellW number -- width of each square
---@param cellH number -- height of each square
---@param rotationDeg number -- rotation of grid in deg
---@param color table|nil -- {r,g,b,a} or nil
---@param fill boolean -- true = filled, false = border
function Grid:new(centerPos, rows, cols, cellW, cellH, rotationDeg)
    local self          = setmetatable({}, Grid)

    self.centerPos      = centerPos
    self.rows           = rows
    self.cols           = cols
    self.cellW          = cellW
    self.cellH          = cellH
    self.rotationDeg    = rotationDeg
    self.spaceing       = 0.1
    self.cells          = {}

    self.hoveredCell    = nil
    self.lastHoveredRow = nil
    self.lastHoveredCol = nil

    self.onHover        = nil
    self.onClick        = nil

    self.blinkingCell   = nil
    self.blinkEndTime   = 0

    self.holdDuration   = 3000
    self.holdingCell    = nil
    self.isHolding      = false
    self.holdStartTime  = 0

    for row = 0, rows - 1 do
        self.cells[row] = {}
        for col = 0, cols - 1 do
            self.cells[row][col] = {
                color         = { 255, 255, 255, 255 },
                fill          = false,
                originalColor = nil,
                originalFill  = nil,
            }
        end
    end

    table.insert(Grids, self)

    return self
end

--- Set the color and fill of a specific square
---@param row number
---@param col number
---@param color table
---@param fill boolean
function Grid:setSquare(row, col, color, fill)
    if self.cells[row] and self.cells[row][col] then
        self.cells[row][col].color = color or self.cells[row][col].color
        if fill ~= nil then
            self.cells[row][col].fill = fill
        end
    end
end

function Grid:GetCellAtWorldPos(worldPos)
    if (#(GetEntityCoords(cache.ped).xy - worldPos.xy) > Config.AimEntity.Distance) then
        return nil
    end

    local totalW, totalH = self.cols * (self.cellW + self.spaceing), self.rows * (self.cellH + self.spaceing)
    local dx, dy = worldPos.x - self.centerPos.x, worldPos.y - self.centerPos.y

    local rotRad = math.rad(-self.rotationDeg)
    local cosR = math.cos(rotRad)
    local sinR = math.sin(rotRad)

    local rx = dx * cosR - dy * sinR
    local ry = dx * sinR + dy * cosR

    local x = rx + totalW / 2
    local y = ry + totalH / 2

    if x < 0 or x > totalW or y < 0 or y > totalH then
        return nil
    end

    local cellFullW = self.cellW + self.spaceing
    local cellFullH = self.cellH + self.spaceing

    local col = math.floor(x / cellFullW)
    local row = math.floor(y / cellFullH)

    local cellStartX = col * cellFullW
    local cellStartY = row * cellFullH

    local withinCellX = x - cellStartX < self.cellW
    local withinCellY = y - cellStartY < self.cellH

    if not (withinCellX and withinCellY) then
        return nil
    end

    return row, col
end

function Grid:GetCellWorldPos(row, col)
    if not row or not col then return nil end

    if row < 0 or row > self.rows then return nil end
    if col < 0 or col > self.cols then return nil end

    local cell = self.cells[row][col]

    if cell then
        return cell.position
    end

    return nil
end

function Grid:draw()
    local totalW = self.cols * self.cellW
    local totalH = self.rows * self.cellH
    local rotRad = math.rad(self.rotationDeg)

    local cosR = math.cos(rotRad)
    local sinR = math.sin(rotRad)


    local function rotate(dx, dy)
        local x = dx * cosR - dy * sinR
        local y = dx * sinR + dy * cosR

        return x, y
    end

    local dist = #(GetEntityCoords(cache.ped).xy - self.centerPos.xy)

    if dist <= 10.0 then
        for row = 0, self.rows - 1 do
            for col = 0, self.cols - 1 do
                local cell       = self.cells[row][col]

                local isBlinking = self.blinkingCell and self.blinkingCell.row == row and self.blinkingCell.col == col
                local isHovered  = self.hoverCell and self.hoverCell.row == row and self.hoverCell.col == col
                local isHeld     = self.holdingCell and self.holdingCell.row == row and self.holdingCell.col == col


                local blinkActive = isBlinking and GetGameTimer() < self.blinkEndTime

                local color       = cell.color
                local fill        = cell.fill


                if isHovered then
                    color = { 255, 200, 0, 160 }
                    fill = true
                end

                if blinkActive then
                    color = { 0, 255, 0, 100 }
                    fill = true
                end

                if isHeld and self.isHolding then
                    color = { 200, 0, 200, 100 }
                    fill = true
                end


                local dx = (col + 0.5) * (self.cellW + self.spaceing) - totalW / 2
                local dy = (row + 0.5) * (self.cellH + self.spaceing) - totalH / 2

                local ox, oy = rotate(dx, dy)

                local squarePos = vec3(
                    self.centerPos.x + ox,
                    self.centerPos.y + oy,
                    self.centerPos.z
                )

                cell.position = squarePos

                DrawSquare(squarePos, self.cellW, self.cellH, self.rotationDeg, color, fill)

                if mCore.isDebug() then
                    mCore.Draw3DText(squarePos.x, squarePos.y, squarePos.z, ("%s:%s"):format(row, col), 255, 255, 0,
                        false, 4)
                end

                -- Draw progress bar on held cell
                if isHeld and self.holdProgress and self.holdProgress > 0 then
                    mCore.Draw3DText(squarePos.x, squarePos.y, squarePos.z + 0.2, "Holding!", 255, 0, 0, false, 4)

                    local barWidth = self.cellW * 0.8
                    local barHeight = self.cellH * 0.1
                    local barOffset = self.cellH / 2 + barHeight / 2 + 0.01

                    local rotRad = math.rad(self.rotationDeg)
                    local offsetX = math.sin(rotRad) * -barOffset
                    local offsetY = math.cos(rotRad) * barOffset

                    local barPos = vector3(
                        squarePos.x + offsetX,
                        squarePos.y + offsetY,
                        squarePos.z
                    )

                    DrawProgressBar(
                        barPos,
                        barWidth,
                        barHeight,
                        self.rotationDeg,
                        self.holdProgress,
                        { 50, 50, 50, 200 },  -- bg
                        { 0, 200, 100, 220 }, -- fg
                        "right"
                    )
                end
            end
        end
    end
end

function Grid:UpdateHover(worldPos)
    local row, col = self:GetCellAtWorldPos(worldPos)

    if row and col then
        local cellPos = self:GetCellWorldPos(row, col)
        if mCore.isDebug() then
            mCore.Draw3DText(cellPos.x, cellPos.y, cellPos.z + 0.3, "HOVER", 255, 0, 0, false, 4)
        end
    end

    if row ~= self.lastHoveredRow or col ~= self.lastHoveredCol then
        self.hoverCell = nil

        if row and col then
            self.hoverCell = { row = row, col = col }
        end

        self.lastHoveredRow = row
        self.lastHoveredCol = col
    end

    if self.onHover then
        self.onHover(row, col)
    end
end

function Grid:resetHold()
    self.isHolding     = false
    self.holdingCell   = nil
    self.holdStartTime = 0
    self.holdProgress  = 0
end

function Grid:update()
    local isMouseHeld = IsControlPressed(2, 24)


    if AimController._aiming then
        local hit, cursorWorldPos, entityHit, to = screenToWorld(1, 0)

        -- UpdateHover
        self:UpdateHover(cursorWorldPos)

        -- Hold stuff
        if self.holdingCell and not self.isHolding then
            local holdDuration = GetGameTimer() - self.holdStartTime
            if holdDuration >= 100 then
                self.isHolding = true
            end
        end

        if self.isHolding and self.holdingCell then
            local elapsed = GetGameTimer() - self.holdStartTime
            local progress = math.min(elapsed / self.holdDuration, 1.0)
            self.holdProgress = progress

            if progress >= 1.0 then
                if self.onHoldComplete then
                    self.onHoldComplete(self.holdingCell)
                end
                self:resetHold()
            elseif self.onHolding then
                self.onHolding(self.holdingCell, progress)
            end
        end


        if IsControlJustPressed(2, 24) and self.hoverCell and not self.isHolding then
            self:handleClick(self.hoverCell, 0)
        end


        if IsControlJustReleased(2, 24) and self.isHolding and self.holdingCell then
            if self.onHoldCancelled then
                self.onHoldCancelled(self.holdingCell)
            end

            self:resetHold()
        end

        if IsControlJustReleased(2, 24) and self.holdingCell and not self.isHolding then
            self:resetHold()
        end

        -- When no longer aiming the turn of the hover effect .
    elseif self.hoverCell then
        self:UpdateHover(vec3(-100000, -100000, -100000))

        if self.isHolding and self.holdingCell then
            if self.onHoldCancelled then
                self.onHoldCancelled(self.holdingCell)
            end
            self:resetHold()
        end
    end


    self:draw()
end

function Grid:handleClick(cell, button)
    if not cell then return end

    self.blinkingCell = cell
    self.blinkEndTime = GetGameTimer() + 80

    if button == 0 then
        self.holdingCell   = cell
        self.holdStartTime = GetGameTimer()
    end

    CreateThread(function(threadId)
        Wait(300)
        if self.onClick and not self.isHolding then
            self.onClick(cell, button)
        end
    end)
end

function Grid:UpdateCell(cell, key, val, otherVal)
    if not self.cells[cell.row][cell.col] then
        print(("[^1Err^0]: No cell on %s:%s"):format(cell.row, cell.col))
        return false
    end
    if otherVal then
        self.cells[cell.row][cell.col][key] = self.cells[cell.row][cell.col][key] or {}
        self.cells[cell.row][cell.col][key][val] = otherVal
        return true
    end
    self.cells[cell.row][cell.col][key] = val
    return true
end
