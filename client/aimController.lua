AimController            = {}
AimController._aiming    = false
AimController._aimedData = nil
AimController._inRange   = true

RegisterCommand("aiming", function(source, args, raw)
    AimController._aiming = not AimController._aiming

    if not AimController._aiming then
        AimController._aimedData = nil
    end


    if AimController._aiming then
        SetMouseCursorSprite(Config.AimEntity.CursorSpriteDefault)

        if Config.AimEntity.CenterCursorOnOpen then
            SetCursorLocation(0.5, 0.5)
        end


        Citizen.CreateThread((function()
            while AimController._aiming do
                Citizen.Wait(0)

                DisableAllControlActions(2)

                EnableControlAction(2, 30, true)
                EnableControlAction(2, 31, true)
                EnableControlAction(2, 32, true)
                EnableControlAction(2, 33, true)
                EnableControlAction(2, 34, true)
                EnableControlAction(2, 35, true)
                EnableControlAction(2, 24, true)

                SetMouseCursorActiveThisFrame()

                if AimController._aimedData then
                    if IsControlJustPressed(0, 24) then
                        local data = GetGridAtWorldPos(AimController._aimedData.hitcoords)

                        if data then
                            TriggerEvent(("mate-grid:onCellClick"), data.uid, data)
                            TriggerServerEvent(("mate-grid:onCellClick"), data.uid, data)
                        end
                    end

                    if Config.AimEntity.EnableDrawLine then
                        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId()))
                        local ox, oy, oz = table.unpack(AimController._aimedData.hitcoords)
                        DrawLine(x, y, z, ox, oy, oz, 255, 255, 255, 255)
                    end

                    if Config.AimEntity.EnableSprite then
                        local onScreen, rx, ry = GetScreenCoordFromWorldCoord(ox, oy, oz)
                        if onScreen then
                            RequestStreamedTextureDict(Config.AimEntity.SpriteDict, false)
                            DrawSprite(Config.AimEntity.SpriteDict, Config.AimEntity.SpriteName, rx, ry, 0.015, 0.03,
                                0.0, 255, 255, 255, 255)
                        end
                    end
                end
            end
        end))


        Citizen.CreateThread((function()
            while AimController._aiming do
                Wait(Config.AimEntity.RefreshRateMS)

                if IsHoldingCell() then
                    SetMouseCursorSprite(Config.AimEntity.CursorSpriteOnHold)
                    goto continue
                end

                local found, hitcoords, entity = screenToWorld(1, 0)

                if found >= 1 then
                    local dist = #(GetEntityCoords(PlayerPedId()) - hitcoords)
                    AimController._inRange = Config.AimEntity.Distance > dist
                    if Config.AimEntity.Distance > dist then
                        local data = GetGridAtWorldPos(hitcoords)
                        if data and data.clickable then
                            if data.clickable then
                                SetMouseCursorSprite(Config.AimEntity.CursorSpriteOnClickable)
                            end

                            AimController._aimedData = data
                            AimController._aimedData.hitcoords = hitcoords
                            goto continue
                        else
                            if data then
                                SetMouseCursorSprite(Config.AimEntity.CursorSpriteOnAim)
                            end
                        end
                    end
                end

                if AimController._aimedData ~= nil then
                    AimController._aimedData = nil
                    SetMouseCursorSprite(Config.AimEntity.CursorSpriteDefault)
                end

                ::continue::
            end
        end))
    end
end)
RegisterKeyMapping('aiming', 'Enable Entity Cursor', 'keyboard', Config.AimEntity.Key)
