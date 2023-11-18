Ext.Require("Server/_ModInfos.lua")
Ext.Require("Shared/_Globals.lua")
Ext.Require("Shared/_Utils.lua")
Ext.Require("Server/_Config.lua")
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


-- -------------------------------------------------------------------------- --
--                                General Stuff                               --
-- -------------------------------------------------------------------------- --
function GetBattlies()
    local battlies = {}
    local baddies = Osi.DB_Is_InCombat:Get(nil, nil)
    for _, bad in pairs(baddies) do
        table.insert(battlies, bad[1])
        print(bad[1])
        return battlies
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
    local sneakingEnabled = Config.GetValue(Config.config_tbl, "SNEAKING_ENABLED") == 1
    local characterTemplate = Ext.Template.GetTemplate(character)
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
end

function RestoreTemplateDefaultSpeedForCharacter(character)
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


Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function(level, isEditorMode)
    if level == "SYS_CC_I" then return end
    ALLIES = MergeSquadiesAndSummonies()
    --In case we load during a fight, apply the right multipliers.
    --(They should already be set since save/load doesn't reset them but you never know)
    BasicDebug("EV_LevelGameplayStarted : ")
    for _, ally in pairs(ALLIES) do
        if Osi.IsInCombat(ally) == 1 and Config.config_tbl.COMBAT_ENABLED == 1 then
            UpdateTemplateWithSpeedMultiplierForCharacter(ally,
                Config.config_tbl["Combat_Party_MovementSpeedMultiplier"],
                Config.config_tbl["Combat_Party_ClimbSpeedMultiplier"],
                Config.config_tbl["Combat_Party_AccelerationMultiplier"])
        elseif Osi.IsInCombat(ally) == 1 and Config.config_tbl.COMBAT_ENABLED == 0 then
            RestoreTemplateDefaultSpeedForCharacter(ally)
        else
            UpdateTemplateWithSpeedMultiplierForCharacter(ally,
                Config.config_tbl["Exploration_MovementSpeedMultiplier"],
                Config.config_tbl["Exploration_ClimbSpeedMultiplier"],
                Config.config_tbl["Exploration_AccelerationMultiplier"])
        end
    end
end)

--This is op, nerf pls.
Ext.Events.GameStateChanged:Subscribe(function(e)
    if e.FromState == "LoadModule" and e.ToState == "LoadSession" then
        if not Config.initDone then Config.Init() end
    end
    -- ----------------------------- Before Saving ------------------------------ --
    --BasicDebug("From state : " .. e.FromState .. " to state : " .. e.ToState)
    if e.FromState == "Running" and e.ToState == "Save" then
        BasicDebug("Pretending we're slow to fool the game before saving")
        ALLIES = MergeSquadiesAndSummonies()
        RestoreOriginalValues(ALLIES)
        -- -------------------------------- Post Save ------------------------------- --
    elseif e.FromState == "Save" and e.ToState == "Running" then
        BasicDebug("Stupid game, I was merely pretending to be slow!")
        ALLIES = MergeSquadiesAndSummonies()
        for _, ally in pairs(ALLIES) do
            if Osi.IsInCombat(ally) == 1 and Config.config_tbl.COMBAT_ENABLED == 1 then
                UpdateTemplateWithSpeedMultiplierForCharacter(ally,
                    Config.config_tbl["Combat_Party_MovementSpeedMultiplier"],
                    Config.config_tbl["Combat_Party_ClimbSpeedMultiplier"],
                    Config.config_tbl["Combat_Party_AccelerationMultiplier"])
            elseif Osi.IsInCombat(ally) == 1 and Config.config_tbl.COMBAT_ENABLED == 0 then
                RestoreTemplateDefaultSpeedForCharacter(ally)
            else
                UpdateTemplateWithSpeedMultiplierForCharacter(ally,
                    Config.config_tbl["Exploration_MovementSpeedMultiplier"],
                    Config.config_tbl["Exploration_ClimbSpeedMultiplier"],
                    Config.config_tbl["Exploration_AccelerationMultiplier"])
            end
        end
        -- ------------------ Gonna load a save or go back to main ------------------ --
    elseif e.FromState == "Running" and e.ToState == "UnloadLevel" then
        --Probably not needed
        BasicDebug("Pretending we're slow to fool the game before unload level")
        ALLIES = MergeSquadiesAndSummonies()
        RestoreOriginalValues(ALLIES)
        -- -------------------------------- for reloads ------------------------------- --
    elseif e.FromState == "UnloadSession" and e.ToState == "LoadSession" then
        if not Config.initDone then Config.Init() end
    end
end)


-- -------------------------------------------------------------------------- --
--                                COMBAT EVENTS                               --
-- -------------------------------------------------------------------------- --

--We don't use CombatStarted because enemies/players can join late
Ext.Osiris.RegisterListener("EnteredCombat", 2, "after", function(object, combatGuid)
    if Config.config_tbl.COMBAT_ENABLED == 1 then
        if Osi.IsPartyMember(object, 1) == 1 then
            BasicDebug("EV_EnteredCombat event fired for party member : " .. object)
            UpdateTemplateWithSpeedMultiplierForCharacter(object,
                Config.config_tbl["Combat_Party_MovementSpeedMultiplier"],
                Config.config_tbl["Combat_Party_ClimbSpeedMultiplier"],
                Config.config_tbl["Combat_Party_AccelerationMultiplier"])
            return
        elseif Osi.IsCharacter(object) == 1 then
            BasicDebug("EV_EnteredCombat event fired for entity : " .. object)
            UpdateTemplateWithSpeedMultiplierForCharacter(object,
                Config.config_tbl["Combat_Enemy_MovementSpeedMultiplier"],
                Config.config_tbl["Combat_Enemy_ClimbSpeedMultiplier"],
                Config.config_tbl["Combat_Enemy_AccelerationMultiplier"])
            return
        else
            return
        end
    else
        RestoreTemplateDefaultSpeedForCharacter(object)
    end
end)

--TODO check if any remaining enemy in the combat shares the same template with one who left(died) to not slow down
--TODO duplicates before the end
Ext.Osiris.RegisterListener("LeftCombat", 2, "after", function(object, combatGuid)
    --Always set speed to exploration after leaving combat
    if Osi.IsPartyMember(object, 1) == 1 then
        BasicDebug("EV_LeftCombat event fired for party member : " .. object)
        UpdateTemplateWithSpeedMultiplierForCharacter(object,
            Config.config_tbl["Exploration_MovementSpeedMultiplier"],
            Config.config_tbl["Exploration_ClimbSpeedMultiplier"],
            Config.config_tbl["Exploration_AccelerationMultiplier"])
        return
    elseif Osi.IsCharacter(object) == 1 and Config.config_tbl.COMBAT_ENABLED == 1 then
        BasicDebug("EV_LeftCombat event fired for entity : " .. object)
        RestoreTemplateDefaultSpeedForCharacter(object)
        return
    else
        return
    end
end)

-- -------------------------------------------------------------------------- --
--                             PARTY JOINED / LEFT / TRANSFORMED              --
-- -------------------------------------------------------------------------- --


Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", function(character)
    BasicDebug("Character " .. character .. " joined the party, speeding them up!")

    local success, error_message = pcall(function()
        UpdateTemplateWithSpeedMultiplierForCharacter(character,
            Config.config_tbl["Exploration_MovementSpeedMultiplier"],
            Config.config_tbl["Exploration_ClimbSpeedMultiplier"],
            Config.config_tbl["Exploration_AccelerationMultiplier"])
    end)

    if not success then
        BasicDebug("Error while updating character speed: " .. error_message)
    end
end)

Ext.Osiris.RegisterListener("CharacterLeftParty", 1, "after", function(character)
    BasicDebug("Character " .. character .. " left the party, speeding them down...")

    local success, error_message = pcall(function()
        RestoreTemplateDefaultSpeedForCharacter(character)
    end)

    if not success then
        BasicDebug("Error while restoring character speed: " .. error_message)
    end
end)

Ext.Osiris.RegisterListener("ObjectTransformed", 2, "after", function(object, toTemplate)
    if Osi.IsPartyMember(object, 1) == 1 then
        if Osi.IsInCombat(object) == 1 and Config.config_tbl.COMBAT_ENABLED == 1 then
            UpdateTemplateWithSpeedMultiplierForCharacter(object,
                Config.config_tbl["Combat_Party_MovementSpeedMultiplier"],
                Config.config_tbl["Combat_Party_ClimbSpeedMultiplier"],
                Config.config_tbl["Combat_Party_AccelerationMultiplier"])
        elseif Osi.IsInCombat(object) == 0 then
            UpdateTemplateWithSpeedMultiplierForCharacter(object,
                Config.config_tbl["Exploration_MovementSpeedMultiplier"],
                Config.config_tbl["Exploration_ClimbSpeedMultiplier"],
                Config.config_tbl["Exploration_AccelerationMultiplier"])
        end
    end
end)

Ext.Events.ResetCompleted:Subscribe(function()
    if not Config.initDone then Config.Init() end
end)