ESX   = exports['es_extended']:getSharedObject()
mCore = exports["mCore"]:getSharedObj()

lang  = Loc[Config.lan]

Citizen.CreateThread((function()
     local pos = vec4(2526.1523, -388.1937, 92.0928, 164.3590)

     local myGrid = Grid:new(pos.xyz, 4, 4, 0.8, 0.8, pos.w)

     myGrid.onClick = function(cell, btn)
          if cell then
               print(("onClick : %s:%s"):format(cell.row, cell.col))
               myGrid:setSquare(cell.row, cell.col, { 0, 0, 255, 150 }, true)
               print(json.encode(myGrid.cells[cell.row][cell.col], {
                    indent = true
               }))
          end
     end

     myGrid.onHoldComplete = function(cell)
          print(("Hold completed on %s:%s"):format(cell.row, cell.col))

          myGrid:setSquare(cell.row, cell.col, { 100, 200, 100, 100 }, true)

          myGrid:UpdateCell(cell, "test", true)
     end


     myGrid.onHover = (function(row, col)
          local cellPos = myGrid:GetCellWorldPos(row, col)
          if cellPos then
               -- mCore.Draw3DText(cellPos.x, cellPos.y, cellPos.z-0.1, "Custom: Hovering", 16, 99, 111, false, 4)
          end
     end)

     while true do
          Wait(0)

          myGrid:update()
     end
end))


Citizen.CreateThread((function()
     local myGrid = Grid:new(vec3(2536.2563, -383.0119, 92.0928), 3, 3, .8, .8, 146.3792)

     myGrid.onClick = (function(cell)
          if cell then
               myGrid:setSquare(cell.row, cell.col, { 0, 0, 255, 150 }, true)
          end
     end)

     myGrid.onHoldComplete = (function(cell)
          print(("Hold completed on %s:%s"):format(cell.row, cell.col))

          myGrid:setSquare(cell.row, cell.col, { 100, 200, 100, 100 }, true)
     end)

     myGrid.onHoldCancelled = (function(cell)
          print(("Hold ^1Cancelled^0 on %s:%s"):format(cell.row, cell.col))
     end)

     myGrid.onHolding = (function(cell, progress)
          print(("onHolding: %s:%s progress: %s"):format(cell.row, cell.col, progress))
     end)

     while true do
          Wait(1)
          myGrid:update()
     end
end))
