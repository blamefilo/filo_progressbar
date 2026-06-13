local hasEscrowIgnore = false

for i = 0, GetNumResourceMetadata(GetCurrentResourceName(), "dependency") do
    local dep = GetResourceMetadata(GetCurrentResourceName(), "dependency", i)
    if dep == "/assetpacks" then
        hasEscrowIgnore = true
    end
end

local resourceName = GetResourceMetadata(GetCurrentResourceName(), "name", 0)
local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
local githubRepo = "blamefilo/filo_versions"

local function compareVersions(v1, v2)
    local parts1 = {}
    for part in v1:gmatch("%d+") do table.insert(parts1, tonumber(part)) end
    local parts2 = {}
    for part in v2:gmatch("%d+") do table.insert(parts2, tonumber(part)) end

    for i = 1, math.max(#parts1, #parts2) do
        local n1 = parts1[i] or 0
        local n2 = parts2[i] or 0
        if n1 < n2 then return -1 end
        if n1 > n2 then return 1 end
    end
    return 0
end


local function checkVersion()
    if not GlobalState.filo_version then
        GlobalState.filo_version = true
        local consolePrintUrl = ("https://raw.githubusercontent.com/%s/refs/heads/main/%s"):format(githubRepo, 'consolePrint')
        PerformHttpRequest(consolePrintUrl, function(err, responseText, headers)
            if responseText then
                print(responseText)
            end
        end, 'GET')
    end

    local url = ("https://raw.githubusercontent.com/%s/refs/heads/main/%s"):format(githubRepo, GetCurrentResourceName())
    PerformHttpRequest(url, function(err, responseText, headers)
        if responseText then
            local data = {}
            local lastKey = nil
            for line in responseText:gmatch("[^\r\n]+") do
                local indented = line:match("^%s+(.+)$")
                if indented and lastKey then
                    data[lastKey] = data[lastKey] .. "\n    " .. indented
                else
                    local key, value = line:match("^([%w_]+):%s*(.*)$")
                    if key then
                        data[key] = value
                        lastKey = key
                    end
                end
            end

            local newestVersion = data["version"]
            local description = data["version_description"] or "No description provided"
            local filesChanged = data["files_changed"] or ""

            if newestVersion then
                local comparison = compareVersions(currentVersion, newestVersion)

                if comparison == -1 then
                    print("\n^1-------------------------------------------------------^7")
                    print(("^1[Update Available] ^7%s^7"):format(GetCurrentResourceName()))
                    print(("^3Current: ^7%s | ^2Latest: ^7%s^7"):format(currentVersion, newestVersion))
                    print(("^5Notes: ^7%s^7"):format(description))
                    if filesChanged ~= "" then
                        print("^3Files Changed:")
                        for file in filesChanged:gmatch("([^,]+)") do
                            print(("^7 - %s^7"):format(file:gsub("^%s*(.-)%s*$", "%1")))
                        end
                    end

                    if hasEscrowIgnore then
                        print("^3Download: ^7https://portal.cfx.re/assets/^7")
                    else
                        print(("^3Download: ^7https://github.com/blamefilo/%s^7"):format(resourceName))
                    end

                    print("^1-------------------------------------------------------\n^7")
                elseif comparison == 1 then
                    print(("^3[Developer] ^7%s is running a higher version than the repo (v%s)^7"):format(GetCurrentResourceName(), currentVersion))
                else
                    print(("^2[Success] ^7%s is up to date (v%s)^7"):format(GetCurrentResourceName(), currentVersion))
                end
            end
        else
            print(("^1[Error] ^7Could not check version for %s^7"):format(GetCurrentResourceName()))
        end
    end, "GET", "", "")
end

AddEventHandler("onResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Wait(math.random(5000, 10000))

    checkVersion()
end)

CreateThread(function()
    if GetCurrentResourceName() ~= resourceName then
        while true do
            Wait(5000)
            print("Cannot check version for " .. GetCurrentResourceName() .. ", make sure you are using the correct resource name " .. resourceName)
        end
    end
end)