ESX   = exports['es_extended']:getSharedObject()
mCore = exports["mCore"]:getSharedObj()

lang  = Loc[Config.lan]


local grids         = {}
local streamed      = {}
local isRendering   = false
local gridShowPanel = false

local resourceName  = GetCurrentResourceName()

DEFAULT_GRID        = {
     streamDistance   = 15,
     width            = 0.5,
     height           = 0.5,
     rows             = 5,
     cols             = 5,
     rotationDeg      = 0.0,
     checkAimDistance = true,
}

function AddGrid(props)
     local invoker <const> = GetInvokingResource() or resourceName

     if not props.id then
          print(("[^1Err^0]: Id not givven when 'AddGrid' invoke: %s"):format(invoker))
          return false, { error = true, errMsg = "No id givven" }
     end

     if not props.pos then
          print(("[^1Err^0]: Position not givven when 'AddGrid' invoke: %s"):format(invoker))
          return false, { error = true, errMsg = "No position set" }
     end

     local id = invoker .. props.id

     for key, value in pairs(DEFAULT_GRID) do
          if not props[key] then
               props[key] = value
          end
     end

     local gridObj = Grid:new(props.pos, props.rows, props.cols, props.width, props.height, props.rotationDeg)

     -- Set grid base values

     if props.checkAimDistance then
          gridObj.checkAimDistance = props.checkAimDistance
     end

     -- Grid Functions
     if props.onClick then
          gridObj.onClick = function(...)
               props.onClick(...)
          end
     end

     if props.onHolding then
          gridObj.onHolding = function(...)
               props.onHolding(...)
          end
     end

     if props.onHoldCancelled then
          gridObj.onHoldCancelled = function(...)
               props.onHoldCancelled(...)
          end
     end

     if props.onHoldComplete then
          gridObj.onHoldComplete = function(...)
               props.onHoldComplete(...)
          end
     end

     if props.onHover then
          gridObj.onHover = function(...)
               props.onHover(...)
          end
     end

     if props.customDraw then
          gridObj.customDraw = function(...)
               props.customDraw(...)
          end
     end

     props.invoker = invoker
     props.gridObj = gridObj
     grids[id] = props
end

exports("AddGrid", AddGrid)

function RemoveGrid(id)
     local invoker <const> = GetInvokingResource() or resourceName
     local id = invoker .. id

     grids[id] = nil
end

exports("RemoveGrid", RemoveGrid)


function UpdateGridData(id, key, val)
     local invoker <const> = GetInvokingResource() or resourceName
     local id = invoker .. id

     if not grids[id] then return false end

     if not grids[id].gridObj then return false end

     local oldVal = grids[id].gridObj[key] or nil
     grids[id].gridObj[key] = val

     return oldVal, val, key
end

function ReadGridData(id, key)
     local invoker <const> = GetInvokingResource() or resourceName
     local id = invoker .. id

     if not grids[id] then return false end

     if not grids[id].gridObj then return false end

     return grids[id].gridObj[key]
end

exports("ReadGridData", ReadGridData)

function ReadCell(id, cell, key)
     if not id or not cell then return false end

     local invoker <const> = GetInvokingResource() or resourceName
     local id = invoker .. id

     if not grids[id] then return false end

     if not grids[id].gridObj then return false end


     return grids[id].gridObj:ReadCell(cell, key)
end

function WriteCell(id, cell, key, val, otherVal)
     if not id or not cell or not key then return false end

     local invoker <const> = GetInvokingResource() or resourceName
     local id = invoker .. id

     if not grids[id] then return false end
     if not grids[id].gridObj then return false end

     return grids[id].gridObj:WriteCell(cell, key, val, otherVal)
end

exports("WriteCell2", function(id, cell, table)
     for key, val in pairs(table) do
          WriteCell(id, cell, key, val)
     end
     print(("^1Successfully wrote %s at %s:%s with datas:^0\n"):format(id, cell.row, cell.col, table),
          json.encode(table, { indent = true }))
end)

exports("ReadCell", ReadCell)
exports("WriteCell", WriteCell)

exports("UpdateGridData", UpdateGridData)

AddEventHandler("onResourceStop", function(res)
     for id, props in pairs(grids) do
          if (props.invoker or "") == res then
               grids[id].gridObj.customDraw = nil
               grids[id] = nil
          end
     end
end)

function ShouldShowGrid(factionId)
     return true -- TODO: Check can show with Faction resource
end

local function render()
     isRendering = true

     while next(streamed) do
          for id, props in pairs(streamed) do
               if props.gridObj then
                    props.gridObj:update()
               end
          end
          Wait(0)
     end

     isRendering = false
end

exports("SetSquare", function(id, cell, color, fill)
     if not id or not cell then return false end

     local invoker <const> = GetInvokingResource() or resourceName
     local id = invoker .. id

     if not grids[id] then return false end
     if not grids[id].gridObj then return false end

     grids[id].gridObj:setSquare(cell.row, cell.col, color, fill)
end)

exports("getCurrentGrid", function()
     for id, props in pairs(streamed) do
          if props.inGrid then
               return {
                    id = id,
                    props = props
               }
          end
     end

     return nil
end)


local function hideGridPanel()
     gridShowPanel = false
end


CreateThread((function()
     while true do
          local playerPos <const> = GetEntityCoords(cache.ped)

          streamed = {}

          local inGrid = false

          for id, props in pairs(grids) do
               local pos <const> = props.pos
               local dist <const> = #(pos.xy - playerPos.xy)


               if dist < props.streamDistance then
                    if props.inGrid then
                         local where = props.helpWhere or function()
                              return true
                         end
                         if where() then
                              inGrid = true
                              gridShowPanel = true
                         end
                    end
                    streamed[id] = props
               end
          end

          if next(streamed) and not isRendering then
               CreateThread(render)
          end

          if not inGrid then
               hideGridPanel()
          end

          Wait(250)
     end
end))
