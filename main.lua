--references: 
--           documentation: https://wofsauge.github.io/IsaacDocs/rep/index.html
--           log file: C:\Users\danem\Documents\"My Games"\"Binding of Isaac Repentance"
--           tail command in windows powershell: Get-Content log.txt -Wait -Tail 10

local mod_name = "More_Treasure";
local mod = RegisterMod(mod_name, 1);
local game = Game();

--------------------------------------------------------------------------------------------------------
--This function spawns the golden horseshoe and the gulp pill at the start of the game. (not used)
--------------------------------------------------------------------------------------------------------
function mod:give_the_trinket()

    if game:GetFrameCount() == 1 then

        local player = Isaac.GetPlayer(0);

        local left_spawn_point = Vector(-50,-50) +  player.Position; 
        local right_spawn_point = Vector(-50, 50) +  player.Position;

        --spawn the golden horse shoe
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, TrinketType.TRINKET_GOLDEN_HORSE_SHOE, left_spawn_point, player.Velocity, nil);

        --add the pill to the current pool, returns the pill color
        the_pill_color = Isaac.AddPillEffectToPool(PillEffect.PILLEFFECT_GULP);

        --spawn the pill that was just added
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, the_pill_color, right_spawn_point, player.Velocity, nil);
    end
end


--------------------------------------------------------------------------------------------------------
--This function controls a count of items that should be spawned for each additional player in the game
--for each floor. ( Not used)
--------------------------------------------------------------------------------------------------------
function mod:count_items()
    
    local unit_name = "count_items:";
    Isaac.DebugString(mod_name .. ":" .. unit_name .. ":" .. " Entering: " .. unit_name);

    local items_to_spawn = 0;
    local num_players = game:GetNumPlayers();
    local level = game:GetLevel();
    local rooms = level:GetRooms();

    for i = 1, #rooms - 1 do

        local room_descriptor = rooms:Get(i);
        
        if room_descriptor ~= nil then
        
            local room = room_descriptor.Data;
            if room.Type == RoomType.ROOM_TREASURE or room.Type == RoomType.ROOM_PLANETARIUM then
                items_to_spawn = items_to_spawn + (num_players - 1);
            end;
        end;
    end;
    Isaac.DebugString(mod_name  .. ":" .. unit_name  .. ":" .. " Finished: " .. unit_name .. " items_to_spawn: " .. items_to_spawn);
    return items_to_spawn;
end;


--------------------------------------------------------------------------------------------------------
--This function spawns an extra item in the treasure room for each extra player in the game
--------------------------------------------------------------------------------------------------------
function mod:spawn_items()
    
    local unit_name = "spawn_items";
    Isaac.DebugString(mod_name  .. ":" .. " Entering: " .. unit_name);

    --Get the current room type
    local room = game:GetRoom();
    
    --Only spawn items on the first visit to the room
    if room:IsFirstVisit() then

        local room_type = room:GetType();

        if (room_type == RoomType.ROOM_TREASURE    or
            room_type == RoomType.ROOM_PLANETARIUM or
            room_type == RoomType.ROOM_ANGEL       or
            room_type == RoomType.ROOM_DEVIL       or
            room_Type == RoomType.ROOM_BOSSRUSH)   then
            
            --Get the seed for the game
            local seeds = game:GetSeeds();
            local game_seed = seeds:GetNextSeed();

            --Get the item pool for the room
            local item_pool = game:GetItemPool();
            local item_pool_for_room = item_pool:GetPoolForRoom(room_type, game_seed)
            
            --Get the number of players
            local num_players = game:GetNumPlayers();

            for i = 1, num_players - 1 do

                --get an item id from the pool of the current room and the location to spawn
                local item_id = item_pool:GetCollectible(item_pool_for_room, false, game_seed);
                local location = room:FindFreePickupSpawnPosition(room:GetCenterPos(), 2);
                
                Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, item_id, location, Vector(0,0), nil);

            end;
        end;
    end;  

    Isaac.DebugString(mod_name  .. ":" .. " is_first_visit: " .. tostring(room:IsFirstVisit())); 
    Isaac.DebugString(mod_name  .. ":" .. " room_type: "      .. tostring(room_type)); 
end;


--Add the callback
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.spawn_items, EntityType.ENTITY_PLAYER);

