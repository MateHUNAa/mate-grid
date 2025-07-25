---@class Grid
---@field centerPos vector3
---@field id string
---@field rows number
---@field cols number
---@field cellW number
---@field cellH number
---@field rotationDeg number
---@field spaceing number
---@field cells table<number, table<number, GridCell>>
---@field hoveredCell GridCell|nil
---@field lastHoveredRow number|nil
---@field lastHoveredCol number|nil
---@field onHover fun(cell:{row: number, col: number}, newHover: boolean)|nil
---@field onClick fun(cell:{row: number, col: number}, button:number)|nil
---@field onHoldComplete fun(cell:{row: number, col: number})|nil
---@field onHolding fun(cell:{row: number, col: number}, progress:number)|nil
---@field onHoldCancelled fun(cell:{row: number, col: number})|nil
---@field customDraw fun(cell:{row: number, col: number}, ...)|nil
---@field blinkingCell GridCell|nil
---@field blinkEndTime number
---@field holdDuration number
---@field holdingCell GridCell|nil
---@field checkAimDistance boolean
---@field isHolding boolean
---@field holdStartTime number
---@field hoverColor table
---@field clickColor table
---@field blinkColor table
---@field holdColor  table
---@field forceColor table
---@field holdProgress number|nil
Grid         = {}
Grid.__index = Grid

---@class GridCell
---@field color table
---@field lineColor table
---@field fill boolean
---@field originalColor table|nil
---@field originalFill boolean|nil
---@field clickable boolean
---@field metadata table
---@field position vector3|nil


local Grids = {}

exports("GetGridById", function(id)
    if not id then return end

    for _, grid in ipairs(Grids) do
        if grid.id == id then
            return grid
        end
    end
end)

---@param worldPos vector3
---@return table|nil
function GetGridAtWorldPos(worldPos)
    for _, grid in ipairs(Grids) do
        local row, col = grid:GetCellAtWorldPos(worldPos)
        if row and col then
            return {
                grid      = grid,
                row       = row,
                col       = col,
                cell      = grid.cells[row][col],
                uid       = grid.id,
                clickable = grid.cells[row][col].clickable or false
            }
        end
    end

    return nil
end

exports("GetGridAtWorldPos", GetGridAtWorldPos)

---@return boolean
function IsHoldingCell()
    for _, grid in ipairs(Grids) do
        if grid.isHolding then
            return true
        end
    end
    return false
end

exports("IsHoldingCell", IsHoldingCell)

---@param centerPos vector3
---@param rows number
---@param cols number
---@param cellW number
---@param cellH number
---@param rotationDeg number
---@return Grid|nil
function Grid:new(centerPos, rows, cols, cellW, cellH, rotationDeg)
    local self = setmetatable({}, Grid)

    -- if cellW < 0.5 or cellH < 0.5 then
    --     print("[^3Warning^0]: cellW/H smaller than 0.5 the cursor is false detecting grid cells")
    -- end


    if not centerPos or type(centerPos) ~= "vector3" then
        return print(("[^1Err^0]: `centerPos` Expected vector3 got '%s' invoke: '%s'"):format(type(centerPos),
            GetInvokingResource()))
    end

    self.id               = ("mh_%s"):format(Shared.RandomID(12))

    self.centerPos        = centerPos
    self.rows             = rows or 5
    self.cols             = cols or 5
    self.cellW            = cellW or 0.5
    self.cellH            = cellH or 0.5
    self.rotationDeg      = rotationDeg or 0.0
    self.spaceing         = 0.1
    self.cells            = {}

    self.hoveredCell      = nil
    self.lastHoveredRow   = nil
    self.lastHoveredCol   = nil

    self.onHover          = nil
    self.onClick          = nil

    self.customDraw       = nil

    self.blinkingCell     = nil
    self.blinkEndTime     = 0

    self.holdDuration     = 3000
    self.holdingCell      = nil
    self.isHolding        = false
    self.holdStartTime    = 0
    self.checkAimDistance = true


    -- Colors
    self.hoverColor = { 0, 200, 255, 180 }
    self.clickColor = { 80, 120, 160, 160 }
    self.blinkColor = { 80, 255, 0, 160 }
    self.holdColor  = { 255, 0, 220, 160 }
    self.forceColor = nil

    for row = 0, rows - 1 do
        self.cells[row] = {}
        for col = 0, cols - 1 do
            self.cells[row][col] = {
                color         = { 240, 240, 240, 255 },
                lineColor     = { 240, 240, 240, 255 },
                fill          = false,
                originalColor = nil,
                originalFill  = nil,
                clickable     = true,
                metadata      = {}
            }
        end
    end

    table.insert(Grids, self)

    return self
end

--- Set the color and fill of a specific square
---@param row number
---@param col number
---@param color table|nil
---@param fill boolean|nil
function Grid:setSquare(row, col, color, fill)
    if self.cells[row] and self.cells[row][col] then
        self.cells[row][col].color = color or self.cells[row][col].color
        if fill ~= nil then
            self.cells[row][col].fill = fill
        end
    end
end

---@param worldPos vector3
---@return number|nil, number|nil
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

---@param row number
---@param col number
---@return vector3|nil
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
                local lineColor   = cell.lineColor
                local fill        = cell.fill


                if isHovered then
                    color = self.hoverColor
                    fill  = true
                end

                if isHovered and not self.cells[row][col].clickable then
                    color = self.clickColor
                    fill  = true
                end

                if blinkActive then
                    color = self.blinkColor
                    fill  = true
                end

                if isHeld and self.isHolding then
                    color = self.holdColor
                    fill  = true
                end

                if self.forceColor then
                    color = self.forceColor
                end

                -- Special State { 255, 100, 50, 200 }

                local dx = (col) * (self.cellW + self.spaceing) - totalW / 2
                local dy = (row) * (self.cellH + self.spaceing) - totalH / 2

                local ox, oy = rotate(dx, dy)

                local squarePos = vec3(
                    self.centerPos.x + ox,
                    self.centerPos.y + oy,
                    self.centerPos.z
                )

                cell.position = squarePos

                if self.customDraw then
                    self.customDraw({ row = row, col = col, position = squarePos })
                end

                DrawSquare(squarePos, self.cellW, self.cellH, self.rotationDeg, color, fill, lineColor)

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

---@param worldPos vector3
function Grid:UpdateHover(worldPos)
    local row, col = self:GetCellAtWorldPos(worldPos)

    -- if mCore.isDebug() then
    --     if row and col then
    --         local cellPos = self:GetCellWorldPos(row, col)
    --         mCore.Draw3DText(cellPos.x, cellPos.y, cellPos.z + 0.3, "HOVER", 255, 0, 0, false, 4)
    --     end
    -- end

    local isNewHover = (row ~= self.lastHoveredRow or col ~= self.lastHoveredCol)



    if isNewHover then
        self.hoverCell = nil

        if row and col then
            self.hoverCell = { row = row, col = col }
        end

        self.lastHoveredRow = row
        self.lastHoveredCol = col
    end

    if self.onHover then
        self.onHover(self.hoverCell, isNewHover)
    end
end

function Grid:resetHold()
    self.isHolding     = false
    self.holdingCell   = nil
    self.holdStartTime = 0
    self.holdProgress  = 0
end

function Grid:update()
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

---@param cell {row: number, col: number}
---@param button number
function Grid:handleClick(cell, button)
    if not cell then return end

    if not self.cells[cell.row][cell.col].clickable then
        return
    end

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

---@param cell {row: number, col: number}
---@param key string
---@param val any
---@param otherVal any|nil
---@return boolean
function Grid:WriteCell(cell, key, val, otherVal)
    if not self.cells[cell.row][cell.col] then
        print(("[^1Err^0]:WriteCell No cell on %s:%s"):format(cell.row, cell.col))
        return false
    end

    if otherVal then
        self.cells[cell.row][cell.col].metadata[key] = self.cells[cell.row][cell.col][key] or {}
        self.cells[cell.row][cell.col].metadata[key][val] = otherVal
        return true
    end
    self.cells[cell.row][cell.col].metadata[key] = val
    return true
end

---@param cell {row: number, col: number}
---@param key string|nil
---@return any
function Grid:ReadCell(cell, key)
    if not cell then
        print(("[^1Err^0]:ReadCell: No cell givven"))

        return
    end
    if not self.cells[cell.row][cell.col] then
        print(("[^1Err^0]:ReadCell: No cell on %s:%s"):format(cell.row, cell.col))
        return false
    end

    if not key then
        return self.cells[cell.row][cell.col].metadata
    end

    return self.cells[cell.row][cell.col].metadata[key] or {}
end
