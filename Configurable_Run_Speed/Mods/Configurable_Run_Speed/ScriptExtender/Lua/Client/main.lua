ALLOWED_FIELDS = {
    "MovementSpeedDash",
    "MovementSpeedSprint",
    "MovementSpeedRun",
    "MovementSpeedWalk",
    "MovementSpeedStroll",
    "WorldClimbingSpeed",
    "LadderLoopSpeed",
    "LadderLoopSpeed"
}


Ext.RegisterNetListener("Fallen_RunSpeed_TemplateChanged", function(_, payload)
    local receivedtemplate = Ext.Json.Parse(payload)
    local templateId = receivedtemplate.Id
    local clientTemplate = Ext.Template.GetTemplate(templateId)
    if clientTemplate then
        for index, field in pairs(ALLOWED_FIELDS) do
            clientTemplate[field] = receivedtemplate[field]
        end
    end
end)
