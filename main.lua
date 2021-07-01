--references: 
--           documentation: https://wofsauge.github.io/IsaacDocs/rep/index.html



--don't try and store the name in a variable. It doesn't like that
local mod = RegisterMod("Dane and Devin's Co-op", 1);
local game = Game();
local the_seed = Seeds.InitSeedInfo();

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

function mod:spawn_item_at_start_of_floor()
    local player = Isaac.GetPlayer(0);

    local left_spawn_point = Vector(-50,-50) +  player.Position; 
    local right_spawn_point = Vector(-50, 50) +  player.Position;
    local zero = Vector(0,0);

    item1 = math.random(1, 298);

    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, item1, left_spawn_point, zero, nil);
end

--------------------------------------------------------------------------------------------------------
--This function controls a count of items that should be spawned for each additional player in the game
--------------------------------------------------------------------------------------------------------

function mod:set_items_to_spawn_for_floor()
    
    unit_name = "set_items_to_spawn_for_floor";
    print("Entering: " .. unit_name);

    local items_to_spawn = 0;
    local num_players = game:GetNumPlayers();
    local level = game:GetLevel();
    local rooms = level:GetRooms();

    for i = 1, #rooms do

        local room_descriptor = rooms:Get(i);
        
        if room_descriptor ~= nil then
        
            local room = room_descriptor.Data;
            if room.Type == RoomType.ROOM_TREASURE then
                items_to_spawn = items_to_spawn + (num_players - 1);
            end;
        end;
    end;
    print("items_to_spawn: " .. items_to_spawn);
    return items_to_spawn;
end;


--------------------------------------------------------------------------------------------------------
--This function spawns an extra item in the treasure room for each extra player in the game
--------------------------------------------------------------------------------------------------------
function mod:spawn_items_in_treasure_room()
    
    unit_name = "spawn_items_in_treasure_room";
    print("Entering: " .. unit_name);

    local items_to_spawn = mod.set_items_to_spawn_for_floor();

    local num_players = game:GetNumPlayers();
    local player = Isaac.GetPlayer(0);

    local in_front_of_player = Vector(20, 20) +  player.Position; 
    local zero = Vector(0,0);

    --Get the seed for the game
    local seeds = game:GetSeeds();
    local game_seed = seeds:GetNextSeed();
    
    --Get the current room type
    local the_room  = game:GetRoom();
    local room_type = the_room:GetType();

    --Get the item pool for the game
    local item_pool = game:GetItemPool();
    
    --Get the item pool for the current room
    local item_pool_for_room = item_pool:GetPoolForRoom(room_type, game_seed)

    --Check if the current room is a treasure room
    print("items_to_spawn: " .. items_to_spawn);
    print("is_first_visit: " .. tostring(the_room:IsFirstVisit()));
    print("room_type: " .. room_type);
    if room_type == RoomType.ROOM_TREASURE and items_to_spawn > 0 and the_room:IsFirstVisit() then
        for i = 1, num_players - 1 do
            --get an item id from the pool of the current room
            local item_id = item_pool:GetCollectible(item_pool_for_room, false, game_seed)

            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, item_id, in_front_of_player, zero, nil);
            items_to_spawn = items_to_spawn - 1;
        end;
    end;
end;

-- mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.give_the_trinket, EntityType.ENTITY_PLAYER);
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.spawn_items_in_treasure_room, EntityType.ENTITY_PLAYER);
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.set_items_to_spawn_for_floor, EntityType.ENTITY_PLAYER);
