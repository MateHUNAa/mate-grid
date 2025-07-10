ESX   = exports['es_extended']:getSharedObject()
mCore = exports["mCore"]:getSharedObj()

lang  = Loc[Config.lan]


local grids         = {}
local streamed      = {}
local isRendering   = false
local gridShowPanel = false

local resourceName  = GetCurrentResourceName()

DEFAULT_GRID        = {
     streamDistance = 15,
     width          = 0.5,
     height         = 0.5,
     rows           = 5,
     cols           = 5,
     rotationDeg    = 0.0
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

     if props.onClick then
          gridObj.onClick = function(cell, button)
               props.onClick(cell, button)
          end
     end

     if props.onHolding then
          gridObj.onHolding = function(cell, progress)
               props.onHolding(cell, progress)
          end
     end

     if props.onHoldCancelled then
          gridObj.onHoldCancelled = function(cell)
               props.onHoldCancelled(cell)
          end
     end

     if props.onHoldComplete then
          gridObj.onHoldComplete = function(cell)
               props.onHoldComplete(cell)
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


function UpdateGridData(id, key, val, otherVal)
     local invoker <const> = GetInvokingResource() or resourceName
     local id = invoker .. id

     if grids[id] then
          grids[id][key] = val
     end
end

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

exports("ReadCell", ReadCell)
exports("WriteCell", WriteCell)

exports("UpdateGridData", UpdateGridData)

AddEventHandler("onResourceStop", function(res)
     for id, props in pairs(grids) do
          if (props.invoker or "") == res then
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
