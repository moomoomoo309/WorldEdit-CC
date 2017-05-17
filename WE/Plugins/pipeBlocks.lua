WE.pipeBlocks = {
    ["minecraft:standing_sign"] = function(pipeTbl)
        return { Text1 = pipeTbl[1], Text2 = pipeTbl[2], Text3 = pipeTbl[3], Text4 = pipeTbl[4] }
    end,
    ["minecraft:wall_sign"] = function(pipeTbl)
        return WE.pipeBlocks["minecraft:standing_sign"](pipeTbl)
    end,
    ["minecraft:mob_spawner"] = function(pipeTbl)
        return {
            EntityId = pipeTbl[1],
            MaxNearbyEntities = 6,
            RequiredPlayerRange = 16,
            SpawnCount = 4,
            id = "MobSpawner",
            MaxSpawnDelay = 800,
            SpawnRange = 4,
            Delay = 0,
            MinSpawnDelay = 200
        }
    end
}
return true