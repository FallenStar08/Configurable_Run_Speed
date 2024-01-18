local default_config={
    LOG_ENABLED = 0,
    COMBAT_ENABLED = 0,
    SNEAKING_ENABLED = 0,
    MOD_ENABLED = 1,
    DEBUG_MESSAGES = 3,
    Exploration_MovementSpeedMultiplier = 2,
    Exploration_ClimbSpeedMultiplier = 2,
    Exploration_AccelerationMultiplier = 2,
    Combat_Party_MovementSpeedMultiplier = 2,
    Combat_Party_ClimbSpeedMultiplier = 2,
    Combat_Party_AccelerationMultiplier = 2,
    Combat_Enemy_MovementSpeedMultiplier = 2,
    Combat_Enemy_ClimbSpeedMultiplier = 2,
    Combat_Enemy_AccelerationMultiplier = 2
}

MOD_INFO=ModInfo:new("Fall_RunSpeed","Fall_RunSpeed",true,default_config)