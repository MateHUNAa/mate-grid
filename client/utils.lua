--- https://github.com/freamee/Serverside-ObjectController/blob/master/client/cl_w2s.lua
function mulNumber(vector1, value)
     local result = {}
     result.x = vector1.x * value
     result.y = vector1.y * value
     result.z = vector1.z * value
     return result
end

-- Add one vector to another.
function addVector3(vector1, vector2)
     return {
          x = vector1.x + vector2.x,
          y = vector1.y + vector2.y,
          z = vector1.z + vector2.z
     }
end

-- Subtract one vector from another.
function subVector3(vector1, vector2)
     return {
          x = vector1.x - vector2.x,
          y = vector1.y - vector2.y,
          z = vector1.z - vector2.z
     }
end

function rotationToDirection(rotation)
     local z = degToRad(rotation.z)
     local x = degToRad(rotation.x)
     local num = math.abs(math.cos(x))

     local result = {}
     result.x = -math.sin(z) * num
     result.y = math.cos(z) * num
     result.z = math.sin(x)
     return result
end

function w2s(position)
     local onScreen, _x, _y = GetScreenCoordFromWorldCoord(position.x, position.y, position.z)
     if not onScreen then
          return nil
     end

     local newPos = {}
     newPos.x = (_x - 0.5) * 2
     newPos.y = (_y - 0.5) * 2
     newPos.z = 0
     return newPos
end

function processCoordinates(x, y)
     local screenX, screenY = GetActiveScreenResolution()

     local relativeX = 1 - (x / screenX) * 1.0 * 2
     local relativeY = 1 - (y / screenY) * 1.0 * 2

     if relativeX > 0.0 then
          relativeX = -relativeX;
     else
          relativeX = math.abs(relativeX)
     end

     if relativeY > 0.0 then
          relativeY = -relativeY
     else
          relativeY = math.abs(relativeY)
     end

     return {
          x = relativeX,
          y = relativeY
     }
end

function s2w(camPos, relX, relY)
     local camRot = GetGameplayCamRot(0)
     local camForward = rotationToDirection(camRot)
     local rotUp = addVector3(camRot, {
          x = 10,
          y = 0,
          z = 0
     })
     local rotDown = addVector3(camRot, {
          x = -10,
          y = 0,
          z = 0
     })
     local rotLeft = addVector3(camRot, {
          x = 0,
          y = 0,
          z = -10
     })
     local rotRight = addVector3(camRot, {
          x = 0,
          y = 0,
          z = 10
     })

     local camRight = subVector3(rotationToDirection(rotRight), rotationToDirection(rotLeft))
     local camUp = subVector3(rotationToDirection(rotUp), rotationToDirection(rotDown))

     local rollRad = -degToRad(camRot.y)
     -- print(rollRad)
     local camRightRoll = subVector3(mulNumber(camRight, math.cos(rollRad)), mulNumber(camUp, math.sin(rollRad)))
     local camUpRoll = addVector3(mulNumber(camRight, math.sin(rollRad)), mulNumber(camUp, math.cos(rollRad)))

     local point3D = addVector3(addVector3(addVector3(camPos, mulNumber(camForward, 10.0)), camRightRoll), camUpRoll)

     local point2D = w2s(point3D)

     if point2D == undefined then
          return addVector3(camPos, mulNumber(camForward, 10.0))
     end

     local point3DZero = addVector3(camPos, mulNumber(camForward, 10.0))
     local point2DZero = w2s(point3DZero)

     if point2DZero == nil then
          return addVector3(camPos, mulNumber(camForward, 10.0))
     end

     local eps = 0.001

     if math.abs(point2D.x - point2DZero.x) < eps or math.abs(point2D.y - point2DZero.y) < eps then
          return addVector3(camPos, mulNumber(camForward, 10.0))
     end

     local scaleX = (relX - point2DZero.x) / (point2D.x - point2DZero.x)
     local scaleY = (relY - point2DZero.y) / (point2D.y - point2DZero.y)
     local point3Dret = addVector3(addVector3(addVector3(camPos, mulNumber(camForward, 10.0)),
          mulNumber(camRightRoll, scaleX)), mulNumber(camUpRoll, scaleY))

     return point3Dret
end

function degToRad(deg)
     return (deg * math.pi) / 180.0
end

function screenToWorld(flags, ignore)
     local x, y            = GetNuiCursorPosition()

     local absoluteX       = x
     local absoluteY       = y

     local camPos          = GetGameplayCamCoord()
     local processedCoords = processCoordinates(absoluteX, absoluteY)
     local target          = s2w(camPos, processedCoords.x, processedCoords.y)

     local dir             = subVector3(target, camPos)
     local from            = addVector3(camPos, mulNumber(dir, 0.05))
     local to              = addVector3(camPos, mulNumber(dir, 300))

     local ray             = StartShapeTestRay(from.x, from.y, from.z, to.x, to.y, to.z, flags, ignore, 0)
     local a, b, c, d, e   = GetShapeTestResult(ray)
     return b, c, e, to
end

function RotationToDirection(rot)
     local z = math.rad(rot.z)
     local x = math.rad(rot.x)
     local num = math.abs(math.cos(x))

     return vec3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

---Draw3DText
---@param x number
---@param y number
---@param z number
---@param text string
---@param r integer | nil
---@param g integer | nil
---@param b integer | nil
---@param useScale boolean
---@param font string | number
Draw3DText = (function(x, y, z, text, r, g, b, useScale, font)
     if not x or not y or not z or not text then return end
     SetDrawOrigin(x, y, z)

     local scale = .80
     if useScale then
          local camCoords = GetGameplayCamCoord()
          local dist = #(vec3(x, y, z) - camCoords)
          scale = 200 / (GetGameplayCamFov() * dist)
     end

     local useFont = 4


     if font then
          useFont = font
     end

     SetTextScale(0.35 * scale, 0.35 * scale)
     SetTextFont(useFont or 4)
     SetTextProportional(true)
     SetTextDropshadow(0, 0, 0, 0, 255)
     SetTextEdge(2, 0, 0, 0, 150)
     SetTextDropShadow()

     SetTextWrap(0.0, 1.0)
     SetTextColour(r or 255, g or 255, b or 255, 255)
     SetTextOutline()
     SetTextCentre(true)
     BeginTextCommandDisplayText("STRING")
     AddTextComponentString(text)
     EndTextCommandDisplayText(0.0, 0.0)

     ClearDrawOrigin()
end)
