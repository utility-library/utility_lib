local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
	["TAB"] = 37, ["Q"] = 44, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

DrawDialogueTexts = function(questionCoords, playerCoords, dialogue)
    DrawText3Ds(questionCoords, dialogue.questions[1][dialogue.curQuestion], nil, nil, true)
    DrawText3Ds(playerCoords, dialogue.response.formatted[dialogue.curQuestion], nil, nil, true)
end

DrawLastQuestion = function(dialogue, time)
    -- Delete dialogue
    Utility.Cache.Dialogue[dialogue.entity] = nil                   
    TriggerEvent("Utility:DeleteDialogue", dialogue.entity)

    if dialogue.lastQuestion ~= nil then
        local startTime = GetGameTimer()

        CreateLoop(function(loopId)
            local entityCoords = GetEntityCoords(dialogue.entity) + vector3(0.0, 0.0, 1.0)
            
            ClearPedTasks(dialogue.entity)
            SetEntityAsMissionEntity(dialogue.entity)

            DrawText3Ds(entityCoords, dialogue.lastQuestion, nil, nil, true)

            if (GetGameTimer() - startTime) > time then
                SetEntityAsNoLongerNeeded(dialogue.entity)
                Utility.Cache.LastEntityDialogued = nil
                StopLoop(loopId)
            end
        end)
    end
end

ItsLastQuestion = function(dialogue)
    return #dialogue.questions[1]+1 == dialogue.curQuestion
end

CheckDialogueInteraction = function(dialogue)
    for k,response in pairs(dialogue.response.no_formatted[dialogue.curQuestion]) do
        if old_IsControlJustPressed(0, Keys[k:upper()]) then -- on key press
            dialogue.callback(dialogue.curQuestion, response)

            -- Switching to the next question
            dialogue.curQuestion = dialogue.curQuestion + 1
            
            -- Prevent multiple interaction
            Citizen.Wait(100)
        end
    end
end

StopEntityWithIsTalking = function(entity)
    if Utility.Cache.LastEntityDialogued ~= entity then
        if Utility.Cache.LastEntityDialogued then
            SetEntityAsNoLongerNeeded(Utility.Cache.LastEntityDialogued)
        end

        ClearPedTasks(entity)
        StopCurrentTaskAndWatchPlayer(entity)
        SetEntityAsMissionEntity(entity)
    end

    Utility.Cache.LastEntityDialogued = entity
end

StartDialoguesDrawingLoop = function()
    CreateLoop(function(loopId)
        local drawing = false

        if SliceUsed(currentSlice) then
            for entity,v in pairs(Utility.Cache.Dialogue) do
                if currentSlice == v.slice then
                    local questionCoords = GetEntityCoords(entity) + vector3(0.0, 0.0, 1.0)
                    local playerCoords = GetEntityCoords(player) + vector3(0.0, 0.0, 1.0)

                    if #(playerCoords - questionCoords) < v.distance then
                        drawing = true

                        if v.stopWhenTalking then
                            StopEntityWithIsTalking(entity)
                        end

                        if not ItsLastQuestion(v) then
                            DrawDialogueTexts(questionCoords, playerCoords, v)
                            CheckDialogueInteraction(v)
                        else
                            DrawLastQuestion(v, 3000)
                        end
                    end
                end
            end
        end

        if not drawing then
            if Utility.Cache.LastEntityDialogued then
                SetEntityAsNoLongerNeeded(Utility.Cache.LastEntityDialogued)
                Utility.Cache.LastEntityDialogued = nil
            end
            
            Citizen.Wait(Config.UpdateCooldown)
        end
    end)
end