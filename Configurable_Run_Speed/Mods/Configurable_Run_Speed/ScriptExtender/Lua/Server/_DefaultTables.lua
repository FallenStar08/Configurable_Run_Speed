-- -------------------------------------------------------------------------- --
--                               Default tables                               --
-- -------------------------------------------------------------------------- --

local default_config_tbl = {
    LOG_ENABLED = 0,
    COMBAT_ENABLED = 0,
    SNEAKING_ENABLED = 0,
    MOD_ENABLED = 1,
    DEBUG_MESSAGES = 3,
    VERSION = CurrentVersion,
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

return default_config_tbl