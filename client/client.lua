local isRunning = false
local p = nil

-- https://github.com/overextended/ox_lib/blob/db1ce7f603ad4655ff2f55f1215c6deebaa8923b/resource/interface/client/progress.lua#L52-L58
local function interruptProgress(data)
    local ped = PlayerPedId()
    if not data.useWhileDead and IsEntityDead(ped) then return true end
    if not data.allowRagdoll and IsPedRagdoll(ped) then return true end
    if not data.allowCuffed and IsPedCuffed(ped) then return true end
    if not data.allowFalling and IsPedFalling(ped) then return true end
    if not data.allowSwimming and IsPedSwimming(ped) then return true end
end

---@class ProgressBarOptions
---@field label? string
---@field duration number
---@field canCancel? boolean
---@field useWhileDead? boolean
---@field allowRagdoll? boolean
---@field allowCuffed? boolean
---@field allowFalling? boolean
---@field allowSwimming? boolean

---@param label    string   Text shown above the bar
---@param duration number   Duration in milliseconds
---@param options  ProgressBarOptions
function ProgressBar(options)
    if isRunning then return false end

    options = options or {}
    local canCancel = options.canCancel
    local duration = options.duration or 5000
    local label = options.label or "..."

    isRunning = true
    p = promise.new()

    SetNuiFocus(false, false)
    SendNUIMessage({
        type     = 'progressbar:start',
        label    = label,
        duration = duration
    })

    CreateThread(function()
        local startTime = GetGameTimer()

        while isRunning do
            if interruptProgress(options) then
                CancelProgressBar()
                break
            end

            if canCancel and (IsControlJustPressed(0, 202) or IsControlJustPressed(0, 73)) then
                CancelProgressBar()
                break
            end

            if GetGameTimer() - startTime >= duration then
                if isRunning then
                    TriggerEvent("ox_lib:progressComplete")
                    isRunning = false
                    if p then p:resolve(true) end
                end
                break
            end

            Wait(0)
        end
    end)

    local result = Citizen.Await(p)
    p = nil
    isRunning = false
    return result
end

function CancelProgressBar()
    TriggerEvent("ox_lib:progressCancelled")

    if not isRunning then return end
    isRunning = false
    SendNUIMessage({ type = 'progressbar:cancel' })
    if p then p:resolve(false) end
end

RegisterNUICallback('finished', function(data, cb)
    if isRunning then
        TriggerEvent("ox_lib:progressComplete")
        isRunning = false
        if p then p:resolve(true) end
    end
    cb({})
end)

exports('ProgressBar',       ProgressBar)
exports('CancelProgressBar', CancelProgressBar)

RegisterCommand("progress", function()
    ProgressBar({
        label = "Progress",
        duration = 2000,
    })
end)