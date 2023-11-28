-- -------------------------------------------------------------------------- --
--                               Default tables                               --
-- -------------------------------------------------------------------------- --

Config.default_config_tbl = {
    LOG_ENABLED = 0,
    COMBAT_ENABLED = 0,
    SNEAKING_ENABLED = 0,
    MOD_ENABLED = 1,
    DEBUG_MESSAGES = 3,
    VERSION = Config.CurrentVersion,
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

-- -------------------------------------------------------------------------- --
--                             Config IO functions                            --
-- -------------------------------------------------------------------------- --

--- Save a config table to a json file
---@param filePath string the path of the json file
---@param config table  the configuration table to save
function Config.SaveConfig(filePath, config)
    filePath=filePath or Config.config_json_file_path
    config=config or Config.config_tbl
    local success, error_message = pcall(function()
        BasicPrint("Config.SaveConfig() - Config file saved")
        BasicDebug(config)
        JSON.LuaTableToFile(config, filePath)
    end)
    if not success then BasicWarning("Config.SaveConfig() - " .. error_message) end
end

--- Load a json configuration file and return a table
---@param filePath string the path of the json file
---@return table config the configuration table
function Config.LoadConfig(filePath)
    local config = {}

    local success, error_message = pcall(function()
        config = JSON.LuaTableFromFile(filePath) or {}
    end)

    if not success then
        BasicWarning("Config.LoadConfig() - " .. error_message)
        config = {}
    end

    return config
end
---@param config table Configuration table
---@param key string Key we're trying to get the value from
---@return ... The Key value
function Config.GetValue(config, key)
    if config[key] ~= nil then
        return config[key]
    else
        BasicError("GetValue() - The following key was not found : " .. key)
        BasicError(config)
        return nil
    end
end

function Config.SetValue(config, key, value)
    config[key] = value
end

-- TODO Better name, make a separate function to validate the lists
function CheckConfigStructure(config)
    local configChanged = false
    local defaultConfig = Config.default_config_tbl
    -- Remove useless keys
    for key, value in pairs(config) do
        if defaultConfig[key] == nil then
            config[key] = nil
            BasicWarning("CheckConfigStructure() - Removed extra key : " .. key .. " from the configuration file")
            configChanged = true
        end
    end
    -- Write the missing keys
    for key, value in pairs(defaultConfig) do
        if config[key] == nil then
            config[key] = value
            BasicWarning("CheckConfigStructure() - Added missing key : " .. key .. " to the configuration file")
            configChanged = true
        end
    end
    -- Check if value type is correct
    for key, value in pairs(defaultConfig) do
        if type(config[key]) ~= type(value) then
            BasicWarning(string.format(
                "CheckConfigStructure() - Config key '%s' has incorrect type. Reverting to default.", key))
            config[key] = value
            configChanged = true
        end
    end
    -- If anything had to change, also update the actual file
    if configChanged then
        BasicPrint("CheckConfigStructure() - Config repaired!")
        Config.SaveConfig(Config.config_json_file_path, config)
    end
    -- Return the potentially repaired table :')
    return config
end

-- Shouldn't be called too often if ever, fine to manually do the things when needed
function Config.UpgradeConfig(config)
    config["VERSION"] = Config.CurrentVersion
    Config.SaveConfig(Config.config_json_file_path, config)
end

-- -------------------------------------------------------------------------- --
--                          Initialization functions                          --
-- -------------------------------------------------------------------------- --

function Config.InitDefaultConfig(filePath, defaultConfig)
    BasicDebug("Config.InitDefaultConfig() - Creating default config file at :" .. filePath)
    Config.SaveConfig(filePath, defaultConfig)
end

function Config.Init()
    Files.ClearLogFile()
    -- Until we read the user's log level just pretend it's the default one
    DEBUG_MESSAGES = Config.default_config_tbl["DEBUG_MESSAGES"]
    BasicPrint(string.format("Config.Init() - %s mod by FallenStar VERSION : %s starting up... ",MOD_NAME,Config.CurrentVersion),"INFO",nil,nil,true)
    local loadedConfig = Files.Load(Config.config_json_file_path)
    -- Check if the config file doesn't exist, Initialize it
    if not loadedConfig then Config.InitDefaultConfig(Config.config_json_file_path, Config.default_config_tbl) end
    -- Load its contents
    BasicPrint("Config.Init() - Loading config from Config.json")
    local loaded = Config.LoadConfig(Config.config_json_file_path)
    -- Check the Config Structure and correct it if needed, using default value for missing keys / wrong types
    loaded = CheckConfigStructure(loaded)
    DEBUG_MESSAGES = Config.GetValue(loaded, "DEBUG_MESSAGES")
    if loaded["VERSION"] ~= Config.CurrentVersion then
        BasicWarning("Config.Init() - Detected version mismatch, upgrading file...")
        Config.UpgradeConfig(loaded)
        Config.config_tbl = loaded
    else
        BasicPrint("Config.Init() - VERSION check passed")
        Config.config_tbl = loaded
    end
    BasicDebug("Config.Init() - DEBUG MESSAGES ARE ENABLED")
    BasicDebug(Config.config_tbl)
    Config.initDone = true
end
