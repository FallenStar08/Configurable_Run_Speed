-- -------------------------------------------------------------------------- --
--                                   GLOBALS                                  --
-- -------------------------------------------------------------------------- --

local DEFAULTS = {
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

local speedStatus = { ["LONGSTRIDER"] = true, ["DASH"] = true, ["HASTE"] = true, ["MAG_MOMENTUM"] = true }

local MCMCONFIG = Mods.BG3MCM.MCMAPI


local function containsActionResourceMovement(str)
    local pattern1 = "ActionResource%(Movement,([1-9]%d*%.?%d*),0%)"
    --Hopefully no floating points?
    local pattern2 = "ActionResourceMultiplier%(Movement,([1-9]%d*),0%)"

    return string.match(str, pattern1) ~= nil or string.match(str, pattern2) ~= nil
end

local function statusHasMovementBoost(statusName)
    local success, stats = pcall(function() return Ext.Stats.Get(statusName) end)
    if success and stats and stats.Boosts then
        if containsActionResourceMovement(stats.Boosts) then
            return true
        end
    end
    return false
end



-- -------------------------------------------------------------------------- --
--                                General Stuff                               --
-- -------------------------------------------------------------------------- --

local function checkStateAndApplySpeedModifier(character)
    local isCharacter = Osi.IsCharacter(character) == 1
    if not isCharacter then return end
    local isPartyMember = Osi.IsPartyMember(character, 1) == 1
    local MCMSettings = GetMCMTable()
    if not MCMSettings["MOD_ENABLED"] then return end
    --local applyOnSpeedStatus = GetMCM("ON_SPEED_STATUS")
    local applyOnSpeedStatus = MCMSettings["ON_SPEED_STATUS"]
    local hasSpeedStatus
    if applyOnSpeedStatus then
        local characterStatuses = GetAppliedStatus(_GE(character))
        BasicDebug(characterStatuses)
        for statusName, v in pairs(characterStatuses) do
            if statusHasMovementBoost(statusName) then
                hasSpeedStatus = true
                break
            end
        end
    end
    local combatEnabled = MCMSettings["COMBAT_ENABLED"]
    local combatPartyMovementSpeedMultiplier = MCMSettings["Combat_Party_MovementSpeedMultiplier"]
    local combatPartyClimbSpeedMultiplier = MCMSettings["Combat_Party_ClimbSpeedMultiplier"]
    local combatPartyAccelerationMultiplier = MCMSettings["Combat_Party_AccelerationMultiplier"]
    local explorationMovementSpeedMultiplier = MCMSettings["Exploration_MovementSpeedMultiplier"]
    local explorationClimbSpeedMultiplier = MCMSettings["Exploration_ClimbSpeedMultiplier"]
    local explorationAccelerationMultiplier = MCMSettings["Exploration_AccelerationMultiplier"]
    local combatEnemyMovementSpeedMultiplier = MCMSettings["Combat_Enemy_MovementSpeedMultiplier"]
    local combatEnemyClimbSpeedMultiplier = MCMSettings["Combat_Enemy_ClimbSpeedMultiplier"]
    local combatEnemyAccelerationMultiplier = MCMSettings["Combat_Enemy_AccelerationMultiplier"]
    -- Case Party member
    if Osi.IsPartyMember(character, 1) == 1 then
        if applyOnSpeedStatus and not hasSpeedStatus then
            BasicDebug("Restoring default speed for party member (no speed status) : " .. character)
            RestoreTemplateDefaultSpeedForCharacter(character)
        else
            if Osi.IsInCombat(character) == 1 then
                if combatEnabled then
                    BasicDebug("Speeding up the following party member (Combat started, Combat enabled) : " .. character)
                    UpdateTemplateWithSpeedMultiplierForCharacter(character,
                        combatPartyMovementSpeedMultiplier,
                        combatPartyClimbSpeedMultiplier,
                        combatPartyAccelerationMultiplier)
                else
                    BasicDebug("Speeding down the following party member (Combat started, Combat disabled) : " ..
                        character)
                    RestoreTemplateDefaultSpeedForCharacter(character)
                end
            else
                BasicDebug("Speeding up the following party member (not in Combat) : " .. character)
                UpdateTemplateWithSpeedMultiplierForCharacter(character,
                    explorationMovementSpeedMultiplier,
                    explorationClimbSpeedMultiplier,
                    explorationAccelerationMultiplier)
            end
        end
        -- Case non party member in combat
    elseif Osi.IsCharacter(character) == 1 then
        if applyOnSpeedStatus and not hasSpeedStatus then
            BasicDebug("Restoring default speed for enemy (no speed status) : " .. character)
            RestoreTemplateDefaultSpeedForCharacter(character)
        else
            if Osi.IsInCombat(character) == 1 and combatEnabled then
                BasicDebug("Speeding up the following enemy (Combat) : " .. character)
                UpdateTemplateWithSpeedMultiplierForCharacter(character,
                    combatEnemyMovementSpeedMultiplier,
                    combatEnemyClimbSpeedMultiplier,
                    combatEnemyAccelerationMultiplier)
            elseif Osi.IsInCombat(character) == 0 and combatEnabled then
                BasicDebug("Speeding down the following enemy (end of Combat) : " .. character)
                RestoreTemplateDefaultSpeedForCharacter(character)
            end
        end
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
    local sneakingEnabled = GetMCM("SNEAKING_ENABLED")
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
    Net.Send("Fallen_RunSpeed_TemplateChanged", serializedTemplateInfo)
    if serializedTransfoTemplateInfo then
        Net.Send("Fallen_RunSpeed_TemplateChanged",
            serializedTransfoTemplateInfo)
    end
end

function RestoreTemplateDefaultSpeedForCharacter(character)
    character = GUID(character)
    UpdateTemplateWithSpeedMultiplierForCharacter(character, 1, 1, 1)
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
--                                  STATUSES                                  --
-- -------------------------------------------------------------------------- --
local function registerStatusesListener()
    Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
        BasicDebug(status)
        if statusHasMovementBoost(status) then
            BasicDebug("Yes")
            checkStateAndApplySpeedModifier(object)
        end
    end)

    Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function(object, status, causee, applyStoryActionID)
        BasicDebug(status)
        if statusHasMovementBoost(status) then
            BasicDebug("Yes")
            checkStateAndApplySpeedModifier(object)
        end
    end)
end

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
    if GetMCM("MOD_ENABLED") then
        ALLIES = MergeSquadiesAndSummonies()
        --TODO fix this for enemies, they don't get speed up yet if you load into a fight
        --TODO fix with uservars...
        BasicDebug("EV_LevelGameplayStarted : ")
        for _, ally in pairs(ALLIES) do
            checkStateAndApplySpeedModifier(ally)
        end

        if GetMCM("ON_SPEED_STATUS") then
            registerStatusesListener()
        end
    end
end

Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", start)
Ext.Events.ResetCompleted:Subscribe(start)


-- -------------------------------------------------------------------------- --
--                                     MCM                                    --
-- -------------------------------------------------------------------------- --


Net.ListenFor("MCM_Saved_Setting", function(payload, user)
    local data = Ext.Json.Parse(payload)
    if not data or data.modGUID ~= MOD_INFO.MOD_UUID or not data.settingId then
        return
    end

    local settingId = data.settingId
    local value = data.value

    if settingId == "ON_SPEED_STATUS" then
        if value then
            registerStatusesListener()
        end
    elseif settingId == "MOD_ENABLED" then
        if value then
            --...
        else
            ALLIES = MergeSquadiesAndSummonies()
            for _, ally in pairs(ALLIES) do
                RestoreTemplateDefaultSpeedForCharacter(ally)
            end
        end
    end
    start()
end)
