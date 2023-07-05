local QBCore = exports["qb-core"]:GetCoreObject()

local jobs = {}
local showJobs = false

-- STATION

local function isSpawnPointClear(coords, distance)
    local vehiclePool = GetGamePool("CVehicle")
    local pedPool = GetGamePool("CPed")

    local clear = true

    for i = 1, #vehiclePool do
        local vehicle = vehiclePool[i]
        local dist = Vdist(coords, GetEntityCoords(vehicle))

        if dist <= distance then
            clear = false
            goto continue
        end
    end

    for i = 1, #pedPool do
        local ped = pedPool[i]
        local dist = Vdist(coords, GetEntityCoords(ped))

        if dist <= distance then
            clear = false
            goto continue
        end
    end

    ::continue::
    return clear
end

for k, v in ipairs(Config.Station) do
    -- SPAWNER BLIP --
    local blip = AddBlipForCoord(v.pedcoords)

    SetBlipSprite(blip, 524)
    SetBlipColour(blip, 60)
    SetBlipScale(blip, 0.95)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Technician Station")
    EndTextCommandSetBlipName(blip)

    -- SPAWNER BLIP END --

    -- SPAWNER --

    local sphere = lib.zones.sphere({
        coords = v.zone,
        radius = 1.5,
        debug = false,
        inside = function()
            if IsControlJustPressed(38, 38) and not showJobs and isSpawnPointClear(v.spawnPoint, 6.0) then
                QBCore.Functions.SpawnVehicle(v.carModel, nil, vector4(v.spawnPoint, v.heading), true)
                showJobs = true
                works()
                local alert = lib.alertDialog({
                    header = 'Welcome to us!',
                    content = 'You will find lightning blips on the GPS, go there and repair the generators!',
                    centered = true,
                    cancel = false,
                })
            -- else
            --     lib.notify({
            --         title = 'Technician Job',
            --         description = 'Something is blocking the spawnpoint!',
            --         type = 'error',
            --         position = 'center-right'
            --     })
            end
        end,
        onEnter = function()
            if not showJobs then
                lib.showTextUI('[E] - Car ')
            end
        end,
        onExit = function()
            lib.hideTextUI()
        end,
    })

    -- SPAWNER END --

    -- DELETER BLIP --

    local blip = AddBlipForCoord(v.deletePoint)

    SetBlipSprite(blip, 357)
    SetBlipColour(blip, 60)
    SetBlipScale(blip, 0.5)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Technician Garage")
    EndTextCommandSetBlipName(blip)

    -- DELETER BLIP END --

    -- DELETER --
    local sphere = lib.zones.sphere({
        coords = v.deletePoint,
        radius = 3,
        debug = false,
        inside = function()
            if cache.vehicle then
                if IsControlJustPressed(38, 38) and showJobs then
                    local vehicle = GetVehiclePedIsIn(cache.ped, false)
                    QBCore.Functions.DeleteVehicle(vehicle)
                    showJobs = false
                    for k, v in ipairs(jobs) do
                        RemoveBlip(v)
                    end
                end
            else
                lib.hideTextUI()
            end
        end,
        onEnter = function()
            if showJobs then
                lib.showTextUI('[E] - Return ')
            end
        end,
        onExit = function()
            lib.hideTextUI()
        end,
    })

    -- DELETER END --

    -- PED --

    lib.RequestModel(v.model)
    ped = CreatePed(1, v.model, v.pedcoords, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    -- PED END --
end

-- STATION END

function works()
    if showJobs then
        for k, v in ipairs(Config.Points) do
            local box = lib.zones.box({
                coords = v.coords,
                size = v.size,
                rotation = v.rotation,
                debug = false,
                inside = function()
                    lib.showTextUI('[G] - Repair')
                    if IsControlJustPressed(47, 47) and showJobs then
                        TriggerEvent("myAnimation")
                        local success = lib.skillCheck(Config.skillDifficulty, { 'w', 'a', 's', 'd' })
                        if success then
                            lib.callback('alex-electricianjob:reward')
                            lib.notify({
                                title = 'Technician',
                                description = 'You have successfully fixed the problem!',
                                type = 'success',
                                position = 'center-right'
                            })
                            ClearPedTasks(cache.ped)
                            lib.notify({
                                title = 'Tired, wait a while!',
                                type = 'warning',
                                position = 'top'
                            })
                            Citizen.Wait(Config.Cooldown)
                            lib.notify({
                                title = 'Technician',
                                description = 'You can continue working!',
                                type = 'success',
                                position = 'center-right'
                            })
                        else
                            lib.notify({
                                title = 'Technician',
                                description = 'Fail',
                                type = 'error',
                                position = 'center-right'
                            })
                            lib.notify({
                                title = 'Tired, wait a while!',
                                type = 'warning',
                                position = 'top'
                            })
                            ClearPedTasks(cache.ped)
                            Citizen.Wait(Config.Cooldown)
                        end
                    end
                end,
                onEnter = function()
                    lib.showTextUI('[G] - Repair')
                end,
                onExit = function()
                    lib.hideTextUI()
                end
            })

            -- blip
            local blip = AddBlipForCoord(v.coords)

            SetBlipSprite(blip, 354)
            SetBlipColour(blip, 60)
            SetBlipScale(blip, 0.8)
            SetBlipAsShortRange(blip, true)

            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Technician Job")
            EndTextCommandSetBlipName(blip)

            table.insert(jobs, blip)
        end
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    works()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    works()
end)
