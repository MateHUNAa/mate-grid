ESX   = exports['es_extended']:getSharedObject()
mCore = exports["mCore"]:getSharedObj()

lang  = Loc[Config.lan]

Citizen.CreateThread((function()
     local pos = vec4(2526.1523, -388.1937, 91.999, 164.3590)

     local myGrid = Grid:new(pos.xyz, 5, 5, .5, .5, pos.w)

     if not myGrid then
          return
     end

     myGrid.onClick = function(cell, btn)
          if cell then
               print(("onClick : %s:%s"):format(cell.row, cell.col))
               myGrid:ReadCell(cell)
          end
     end

     myGrid.onHoldComplete = function(cell)
          print(("Hold completed on %s:%s"):format(cell.row, cell.col))

          myGrid:setSquare(cell.row, cell.col, { 100, 200, 100, 100 }, true)

          myGrid:WriteCell(cell, "test", true)
     end

     myGrid.onHoldCancelled = (function(cell)
          print(("Hold ^1Cancelled^0 on %s:%s"):format(cell.row, cell.col))
     end)

     myGrid.onHolding = (function(cell, progress)
          print(("onHolding: %s:%s progress: %s"):format(cell.row, cell.col, progress))
     end)

     while true do
          Wait(0)

          myGrid:update()
     end
end))
