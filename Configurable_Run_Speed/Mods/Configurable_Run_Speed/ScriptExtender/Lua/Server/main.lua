-- -------------------------------------------------------------------------- --
--                                   GLOBALS                                  --
-- -------------------------------------------------------------------------- --

DEFAULTS = {
    Run = {
        MovementSpeedDash = 6.0,   --Dash??? unused???
        MovementSpeedSprint = 6.0, --Sprint = going to attack something
        MovementSpeedRun = 3.75,   --Running, surprising
    },
    Sneak = {
        MovementSpeedWalk = 2.0,   --Walk & Sneak...ye..
        MovementSpeedStroll = 1.4, --No fucking idea
    },
    Climb = {
        WorldClimbingSpeed = 6.0,                    --How fast you climb small objects, not going up ladders
        LadderLoopSpeed = 3.75,                      --How fast you climb ladder style objects, doesn't include the speed of the initial and final "getting up" animations
    },
    Acceleration = { MovementAcceleration = 12.0, }, --Acceleration, not sure how it behave exactly, how fast you get speedy
}


MCMCONFIG = Mods.BG3MCM.MCMAPI


-- -------------------------------------------------------------------------- --
--                                General Stuff                               --
-- -------------------------------------------------------------------------- --

local function checkStateAndApplySpeedModifier(character)
    -- ---------------------------- Case Party member --------------------------- --
    if Osi.IsPartyMember(character, 1) == 1 then
        --Case combat enabled and in combat
        if Osi.IsInCombat(character) == 1 and MCMCONFIG:GetSettingValue("COMBAT_ENABLED", MOD_INFO.MOD_UUID) == true then
            BasicDebug("Speeding up the following party member (Combat started, Combat enabled) : " .. character)
            -- UpdateTemplateWithSpeedMultiplierForCharacter(character,
            --     MCMCONFIG["Combat_Party_MovementSpeedMultiplier"],
            --     MCMCONFIG["Combat_Party_ClimbSpeedMultiplier"],
            --     MCMCONFIG["Combat_Party_AccelerationMultiplier"])

            UpdateTemplateWithSpeedMultiplierForCharacter(character,
                MCMCONFIG:GetSettingValue("Combat_Party_MovementSpeedMultiplier", MOD_INFO.MOD_UUID),
                MCMCONFIG:GetSettingValue("Combat_Party_ClimbSpeedMultiplier", MOD_INFO.MOD_UUID),
                MCMCONFIG:GetSettingValue("Combat_Party_AccelerationMultiplier", MOD_INFO.MOD_UUID))
            --Case Combat disabled and in combat
        elseif Osi.IsInCombat(character) == 1 and MCMCONFIG:GetSettingValue("COMBAT_ENABLED", MOD_INFO.MOD_UUID) == false then
            BasicDebug("Speeding down the following party member (Combat started, Combat disabled) : " .. character)
            RestoreTemplateDefaultSpeedForCharacter(character)
            --Case not in combat
        else
            BasicDebug("Speeding up the following party member (not in Combat) : " .. character)
            UpdateTemplateWithSpeedMultiplierForCharacter(character,
                MCMCONFIG:GetSettingValue("Exploration_MovementSpeedMultiplier", MOD_INFO.MOD_UUID),
                MCMCONFIG:GetSettingValue("Exploration_ClimbSpeedMultiplier", MOD_INFO.MOD_UUID),
                MCMCONFIG:GetSettingValue("Exploration_AccelerationMultiplier", MOD_INFO.MOD_UUID))
        end
        -- --------------------- Case non party member in combat -------------------- --
    elseif Osi.IsCharacter(character) == 1 and Osi.IsInCombat(character) == 1 and MCMCONFIG:GetSettingValue("COMBAT_ENABLED", MOD_INFO.MOD_UUID) == true then
        BasicDebug("Speeding up the following enemy (Combat) : " .. character)
        UpdateTemplateWithSpeedMultiplierForCharacter(character,
            MCMCONFIG:GetSettingValue("Combat_Enemy_MovementSpeedMultiplier", MOD_INFO.MOD_UUID),
            MCMCONFIG:GetSettingValue("Combat_Enemy_ClimbSpeedMultiplier", MOD_INFO.MOD_UUID),
            MCMCONFIG:GetSettingValue("Combat_Enemy_AccelerationMultiplier", MOD_INFO.MOD_UUID))
        --Case end of combat if combat is enabled
    elseif Osi.IsCharacter(character) == 1 and Osi.IsInCombat(character) == 0 and MCMCONFIG:GetSettingValue("COMBAT_ENABLED", MOD_INFO.MOD_UUID) == true then
        BasicDebug("Speeding down the following enemy (end of Combat) : " .. character)
        RestoreTemplateDefaultSpeedForCharacter(character)
    end
end
function GetBattliesBaddies(ALLIES)
    local battlies = GetBattlies()
    local mergedList = ALLIES
    if not battlies then
        BasicDebug("GetBattliesBaddies() no battlies :( returning nothing")
        return nil
    end
    for _, mergedEntry in pairs(mergedList) do
        BasicDebug("GetBattliesBaddies() : entry : " .. mergedEntry)
        for i, battly in pairs(battlies) do
            BasicDebug("GetBattliesBaddies() : battly : " .. battly)
            if battly == mergedEntry then
                table.remove(battlies, i)
                break
            end
        end
    end
    BasicDebug("GetBattliesBaddies() - Badies : ")
    BasicDebug(battlies)
    return battlies
end

function MergeSquadiesAndSummonies()
    local mergedList = {}
    local squadies = GetSquadies()
    local summonies = GetSummonies()
    for _, squady in pairs(squadies) do
        table.insert(mergedList, squady)
    end
    for _, summon in pairs(summonies) do
        table.insert(mergedList, summon)
    end
    BasicDebug(mergedList)
    return mergedList
end

-- -------------------------------------------------------------------------- --
--                               Core functions                               --
-- -------------------------------------------------------------------------- --
function UpdateOriginalTemplatesWithMultiplier(merged_list, movement_speed_multi, climbing_speed_multi,
                                               acceleration_multi)
    for _, listItem in pairs(merged_list) do
        if #listItem >= 36 then
            UpdateTemplateWithSpeedMultiplierForCharacter(listItem, movement_speed_multi, climbing_speed_multi,
                acceleration_multi)
        end
    end
end

--For v10
--TODO store defaults template values and use them in restore, fall back to DEFAULTS otherwise
function UpdateTemplateWithSpeedMultiplierForCharacter(character, movement_speed_multi, climbing_speed_multi,
                                                       acceleration_multi)
    character = GUID(character)
    local sneakingEnabled = MCMCONFIG:GetSettingValue("SNEAKING_ENABLED", MOD_INFO.MOD_UUID) == true
    local characterTemplate = Ext.Template.GetTemplate(character) or
        Ext.Template.GetTemplate(GUID(Osi.GetTemplate(character)))
    local charEntity = Ext.Entity.Get(character)
    local transfoTemplate = charEntity and charEntity.GameObjectVisual and
        Ext.Template.GetTemplate(charEntity.GameObjectVisual.RootTemplateId)
    local function updateTemplate(template, transfo_template, defaults, multiplier)
        if template then
            for k, v in pairs(defaults) do
                template[k] = v * multiplier
                if transfo_template then transfo_template[k] = v * multiplier end
            end
        end
    end

    updateTemplate(characterTemplate, transfoTemplate, DEFAULTS.Run, movement_speed_multi)
    updateTemplate(characterTemplate, transfoTemplate, DEFAULTS.Acceleration, acceleration_multi)
    updateTemplate(characterTemplate, transfoTemplate, DEFAULTS.Climb, climbing_speed_multi)
    if sneakingEnabled then
        updateTemplate(characterTemplate, transfoTemplate, DEFAULTS.Sneak, movement_speed_multi)
    end
    local serializedTemplateInfo = Ext.Json.Stringify(Ext.Types.Serialize(characterTemplate))
    local serializedTransfoTemplateInfo = transfoTemplate and Ext.Json.Stringify(Ext.Types.Serialize(characterTemplate))
    Ext.Net.BroadcastMessage("Fallen_RunSpeed_TemplateChanged", serializedTemplateInfo)
    if serializedTransfoTemplateInfo then
        Ext.Net.BroadcastMessage("Fallen_RunSpeed_TemplateChanged",
            serializedTransfoTemplateInfo)
    end
end

function RestoreTemplateDefaultSpeedForCharacter(character)
    character = GUID(character)
    UpdateTemplateWithSpeedMultiplierForCharacter(character, 1, 1, 1)
end

function RestoreOriginalValues(mergedList)
    BasicDebug("RestoreOriginalValues() - Restoring original speed")
    for _, listItem in pairs(mergedList) do
        if #listItem >= 36 then
            RestoreTemplateDefaultSpeedForCharacter(listItem)
        end
    end
end

-- -------------------------------------------------------------------------- --
--                              State listeners                               --
-- -------------------------------------------------------------------------- --

--This is op, nerf pls.
Ext.Events.GameStateChanged:Subscribe(function(e)
    -- ----------------------------- Before Saving ------------------------------ --
    --BasicDebug("From state : " .. e.FromState .. " to state : " .. e.ToState)
    if e.FromState == "Running" and e.ToState == "Save" then
        ALLIES = MergeSquadiesAndSummonies()
        for _, ally in pairs(ALLIES) do
            checkStateAndApplySpeedModifier(ally)
        end
    end
end)

-- -------------------------------------------------------------------------- --
--                                COMBAT EVENTS                               --
-- -------------------------------------------------------------------------- --

--We don't use CombatStarted because enemies/players can join late
Ext.Osiris.RegisterListener("EnteredCombat", 2, "after", function(object, combatGuid)
    checkStateAndApplySpeedModifier(GUID(object))
end)

--TODO check if any remaining enemy in the combat shares the same template with one who left(died) to not slow down
--TODO duplicates before the end
--TODO ideally solve all of this with uservars
Ext.Osiris.RegisterListener("LeftCombat", 2, "after", function(object, combatGuid)
    checkStateAndApplySpeedModifier(GUID(object))
end)

-- -------------------------------------------------------------------------- --
--                             PARTY JOINED / LEFT / TRANSFORMED              --
-- -------------------------------------------------------------------------- --

--Yes the pcalls are necessary I don't remember why
Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", function(character)
    BasicDebug("Character " .. character .. " joined the party, attempting to speed them up!")

    local success, error_message = pcall(function()
        checkStateAndApplySpeedModifier(GUID(character))
    end)

    if not success then
        BasicDebug("Error while updating character speed: " .. error_message)
    end
end)

Ext.Osiris.RegisterListener("CharacterLeftParty", 1, "after", function(character)
    BasicDebug("Character " .. character .. " left the party, attempting to speed them down...")
    local success, error_message = pcall(function()
        RestoreTemplateDefaultSpeedForCharacter(character)
    end)

    if not success then
        BasicDebug("Error while restoring character speed: " .. error_message)
    end
end)

--Works most of the time...
Ext.Osiris.RegisterListener("ShapeshiftChanged", 4, "after", function(character, race, gender, shapeshiftStatus)
    BasicDebug("character shapeshifted...")
    checkStateAndApplySpeedModifier(GUID(character))
end)


local function start(level, isEditorMode)
    if level == "SYS_CC_I" then return end
    --if not MCMCONFIG then MCMCONFIG = InitConfig() end
    ALLIES = MergeSquadiesAndSummonies()
    --In case we load during a fight, apply the right multipliers.
    --TODO fix this for enemies, they don't get speed up yet if you load into a fight
    --TODO fix with uservars...
    BasicDebug("EV_LevelGameplayStarted : ")
    for _, ally in pairs(ALLIES) do
        checkStateAndApplySpeedModifier(ally)
    end
end

Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", start)
Ext.Events.ResetCompleted:Subscribe(start)


-- -------------------------------------------------------------------------- --
--                                     MCM                                    --
-- -------------------------------------------------------------------------- --

Ext.RegisterNetListener("MCM_Saved_Setting", function(call, payload)
    local data = Ext.Json.Parse(payload)
    if not data or data.modGUID ~= MOD_INFO.MOD_UUID or not data.settingId then
        return
    end
    --TODO fix this
    if string.find(data.settingId, "Party") or string.find(data.settingId, "Exploration") then
        start()
    end
end)
