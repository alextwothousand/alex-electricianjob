local QBCore = exports["qb-core"]:GetCoreObject()

lib.callback.register('alex-electricianjob:reward', function ()
    local player = QBCore.Functions.GetPlayer(source)
    local reward = math.random(Config.RewardMin, Config.RewardMax)

    player.Functions.AddMoney("bank", reward)
end)
