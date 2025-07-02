Functions = {
     ---@param identifier string|number
     ---@return boolean,string,string|number
     ParseIdentifiers = (function(identifier)
          local function hasIDTag(idf)
               if string.match(idf, '^discord:') then
                    return true, "discord", idf:sub(9)
               elseif string.match(idf, "^license:") then
                    return true, "license", idf:sub(9)
               end
               return false, nil, nil
          end

          if type(identifier) == "number" then
               for _, id in pairs(GetPlayers()) do
                    print("Checking for DiscordID")
                    local did = GetPlayerIdentifierByType(id, "discord"):sub(9)

                    if string.match(tostring(did), tostring(identifier)) then
                         return true, "discord", did
                    end
               end


               local len = #tostring(identifier)
               if len < 4 then -- Probably a PlayerID
                    for _, id in pairs(GetPlayers()) do
                         if string.match(tostring(id), tostring(identifier)) then
                              return true, "playerid", identifier
                         end
                    end
               end


               return false, nil, nil
          elseif type(identifier) == "string" then
               local hasTag, type, formated = hasIDTag(identifier)
               if hasTag then
                    return true, type, formated -- found, type, formatedLic
               else
                    return false, nil, nil
               end
          end
     end),
     ---@param identifier string|number
     ---@return boolean,number|nil
     GetPlayerIDByIdentifier = (function(identifier)
          local found, type, id = ParseIdentifier(identifier)
          if not found then return false end

          if type == "playerid" then return true, id end

          if type == "discord" then
               for _, pid in pairs(GetPlayers()) do
                    local did = GetPlayerIdentifierByType(pid, "discord")
                    if string.match(tostring(did), tostring(id)) then
                         return true, pid
                    end
               end
          elseif type == "license" then
               for _, pid in pairs(GetPlayers()) do
                    local did = GetPlayerIdentifierByType(pid, "license")
                    if string.match(tostring(did), tostring(id)) then
                         return true, pid
                    end
               end
          end

          return false, nil
     end),
     ---@param PlayerId number
     ---@return boolean
     IsAdmin = (function(PlayerId)
          if Config.MHAdminSystem then
               return exports["mate-admin"]:isAdmin(pid)
          else
               local identifiers = GetPlayerIdentifiers(pid)

               for _, v in pairs(Config.ApprovedLicenses) do
                    for _, lic in pairs(identifiers) do
                         if v == lic then
                              return true
                         end
                    end
               end

               return false
          end
     end),
     ---@param datetimeStr string
     ---@return number
     DateTimeToTimestamp = (function(datetimeStr)
          local year, month, day, hour, min, sec = string.match(datetimeStr, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")

          -- RETURN SECOUNDS
          return os.time({
               year  = tonumber(year),
               month = tonumber(month),
               day   = tonumber(day),
               hour  = tonumber(hour),
               min   = tonumber(min),
               sec   = tonumber(sec)
          })
     end),
     GenereateUniquePlate = (function()
          local function generateRandomPlate()
               local charset = {}
               -- Uppercase letters
               for c = 65, 90 do table.insert(charset, string.char(c)) end
               -- Numbers
               for n = 48, 57 do table.insert(charset, string.char(n)) end

               local plate = ''
               for i = 1, 8 do
                    plate = plate .. charset[math.random(1, #charset)]
               end

               return plate
          end

          local function IsVehiclePlateTaken(plate)
               local res = MySQL.scalar.await("SELECT COUNT(plate) FROM owned_vehicles WHERE plate = ?", { plate })
               return res > 0
          end

          local promise = promise.new()

          Citizen.CreateThread(function()
               local maxAttempts = 100
               local attempts = 0
               local plate

               repeat
                    plate = generateRandomPlate()
                    attempts = attempts + 1

                    local taken = IsVehiclePlateTaken(plate)

                    if not taken then
                         promise:resolve(plate)
                         return
                    end
               until attempts >= maxAttempts

               promise:resolve(nil)
          end)

          return Citizen.Await(promise)
     end),
}


function regServerNuiCallback(eventName, cb)
     local _eventName = ("%s:%s"):format(GetCurrentResourceName(), eventName)

     lib.callback.register(_eventName,
          (function(source, params, otherParams)
               local idf = GetPlayerIdentifierByType(source, "license"):sub(9)

               print(("[%s] ->"):format(eventName), json.encode(params, { indent = true }))
               print("\n\n\n")
               
               local res = cb(source, idf, params, otherParams)

               print(("[%s] response: \n"):format(eventName), res,
                    json.encode(res, { indent = true }),
                    "\n--------------------------------")

               return res
          end))
end

---@param table table
function PrintTable(table, name)
     if name then
          print(name, json.encode(table, { indent = true }))
     else
          print(table, json.encode(table, { indent = true }))
     end
end

---@params tbl table
function table.count(tbl)
     local c = 0
     for _, _ in pairs(tbl) do c += 1 end
     return c
end
