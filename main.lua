local mod_name = "More_Treasure";
local mod = RegisterMod(mod_name, 1);
local game = Game();

--------------------------------------------------------------------------------------------------------
--This function spawns an extra item in the treasure room for each extra player in the game
--------------------------------------------------------------------------------------------------------
function spawn_items_for_players(room, item_id)
    
    item_id = item_id or 0;

    local unit_name = "spawn_items";

    --Only spawn items on the first visit to the room
    if room:IsFirstVisit() then

        local room_type = room:GetType();

        --Get the seed for the game
        local seeds = game:GetSeeds();
        local game_seed = seeds:GetNextSeed();

        --Get the item pool for the room
        local item_pool = game:GetItemPool();
        local item_pool_for_room = item_pool:GetPoolForRoom(room_type, game_seed);
        
        --Get the number of players
        local num_players = game:GetNumPlayers();

        for i = 1, num_players - 1 do

            if item_id == 0 then
                --get an item id from the pool of the current room and the new_position to spawn
                local item_id = item_pool:GetCollectible(item_pool_for_room, false, game_seed);
            end;
            
            local new_position = room:FindFreePickupSpawnPosition(room:GetCenterPos(), 5);
            
            the_item = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, item_id, new_position, Vector(0,0), nil);
            
            --Only in devil deals should the price be set
            if room_type == RoomType.ROOM_DEVIL then
                the_item_entity_pickup = the_item:ToPickup();
                the_item_entity_pickup.AutoUpdatePrice = true;
                the_item_entity_pickup.Price = PickupPrice.PRICE_TWO_HEARTS;
            end;

        end;
    end;  
end;


--------------------------------------------------------------------------------------------------------
--This function is a wrapper that checks the room type and other criteria for spawning extra items for 
-- additional players in the game. If the criteria is met, it calls spawn_items_for_players
--------------------------------------------------------------------------------------------------------
function mod:spawn_items()

    --Get the current room
    local room = game:GetRoom();
    local room_type = room:GetType();

    if (room_type == RoomType.ROOM_TREASURE    or
        room_type == RoomType.ROOM_PLANETARIUM or
        room_type == RoomType.ROOM_BOSSRUSH)   then

            spawn_items_for_players(room);
    
    elseif (room_type == RoomType.ROOM_CHALLENGE or
            room_type == RoomType.ROOM_ANGEL     or
            room_type == RoomType.ROOM_DEVIL     or
            room_type == RoomType.ROOM_CURSE)    then

        entities = Isaac.GetRoomEntities();

        for _, entity in pairs(entities) do

            if entity.Variant == PickupVariant.PICKUP_COLLECTIBLE then
                spawn_items_for_players(room);
                break;
            end;
        end;   
    end;
end;


--------------------------------------------------------------------------------------------------------
--This function spawns extra items for each player if the room gives an item as a reward
--------------------------------------------------------------------------------------------------------
function mod:spawn_items_post_fight()
    
    --Get the current room
    local room = game:GetRoom();
    local room_type = room:GetType();

    if (room_type == RoomType.ROOM_MINIBOSS  or
        room_type == RoomType.ROOM_BOSSRUSH) then
            
        entities = Isaac.GetRoomEntities();
        for _, entity in pairs(entities) do
            if entity.Variant == PickupVariant.PICKUP_COLLECTIBLE then
                spawn_items_for_players(room, entity.SubType);
                break;
            end;
        end;   
    end;
end;


--------------------------------------------------------------------------------------------------------
--This function spawns extra chests on the 'Chest' and 'Dark Room' floors for each extra player
--------------------------------------------------------------------------------------------------------
function mod:spawn_chests()
   
    local unit_name = "spawn_chests";

    --Get the current room type
    local level = game:GetLevel();
    local absolute_stage = level:GetAbsoluteStage();

    --Only execute on the 'Chest' or 'Dark Room' floor
    if absolute_stage == LevelStage.STAGE6 then
    
        local entities = Isaac.GetRoomEntities();

        --Counter to indirectly determine whether the player is on the 'Chest' or 'Dark Room'
        local chest_counter = 0;
        local spawn_chests = false;
        local positions = {};
        local n_chests = 4;
        local chest_type = nil;

        --Loop over all the entities in the room and count the chests (if they're present)
        for _, entity in pairs(entities) do
            if entity.Variant == PickupVariant.PICKUP_REDCHEST then
                
                chest_counter = chest_counter + 1;
                positions[chest_counter] = entity.Position;

                if chest_counter == n_chests then
                    --We're in the 'Dark Room'
                    chest_type = PickupVariant.PICKUP_REDCHEST;
                    spawn_chests = true;
                    break;
                end;

            elseif entity.Variant == PickupVariant.PICKUP_LOCKEDCHEST then
        
                chest_counter = chest_counter + 1;
                positions[chest_counter] = entity.Position;

                if chest_counter == n_chests then
                    -- We're in the 'Chest' 
                    chest_type = PickupVariant.PICKUP_LOCKEDCHEST;
                    spawn_chests = true;
                    break;
                end;
            end; --if gold/red chest
        end; --Loop over entities

        if spawn_chests then

            --Get the current room
            local room = game:GetRoom();
        
            --Get the number of players
            local num_players = game:GetNumPlayers();
            for i = 1, (num_players - 1) * n_chests do
                
                local idx = n_chests - i % n_chests;
                local new_position = room:FindFreePickupSpawnPosition(positions[idx], 30); 

                Isaac.Spawn(EntityType.ENTITY_PICKUP, chest_type, 1, new_position, Vector(0,0), nil);              
            end; 
        end;
    end; -- only execute on the 'Dark Room' or 'Chest' floor
end; --End spawn_chests


--------------------------------------------------------------------------------------------------------
--This function clears the waves_done table each floor
--------------------------------------------------------------------------------------------------------
local waves_done = {};
function mod:set_wave_counter()
    for i = 1, game:GetGreedWavesNum() do
        waves_done[i] = false;
    end;
end;


require("math")
--------------------------------------------------------------------------------------------------------
--This function spawns an extra coin into the game for each player after each wave
--------------------------------------------------------------------------------------------------------
function mod:spawn_more_coins()
    
    if game:IsGreedMode() then
        local level = game:GetLevel();
        local wave = level.GreedModeWave;

        if not waves_done[wave] then
            
            local seeds = game:GetSeeds();

            math.randomseed(seeds:GetNextSeed());

            --Get the number of coins that should be dropped for each player
            local num_coins = 0
            if wave < game:GetGreedWavesNum() - 2 then
                num_coins = math.random(2,3);
            else
                num_coins = math.random(3,4); 
            end;
            
            waves_done[wave] = true;
            
            --Get the current room
            local room = game:GetRoom();
            local room_type = room:GetType();

            local position = Vector(320,280);
        
            --Spawn the coins
            for i = 1, num_coins * (game:GetNumPlayers() - 1)  do
                local free_position = room:FindFreePickupSpawnPosition(position, 20);
                Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 1, free_position, Vector(0,0), nil);              
            end;
        end;
    end;
end;

--Add the callback
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.spawn_items);
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.spawn_chests);
mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, mod.spawn_items_post_fight);
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.spawn_more_coins, PickupVariant.PICKUP_COIN);
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.set_wave_counter);
