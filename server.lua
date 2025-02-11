RegisterNetEvent("printCustomClothing", function(data)
    local filePath = "D:/FiveM Servers/DOME/resources/resources/[dome]/mainui/server/clothing_logs.json"
    local date = os.date("%Y-%m-%d %H:%M:%S") -- Get current timestamp

    -- Read existing data from JSON file (if it exists)
    local file = io.open(filePath, "r")
    local logTable = {}

    if file then
        local content = file:read("*a") -- Read entire file
        file:close()
        if content and content ~= "" then
            local success, decoded = pcall(json.decode, content)
            if success and type(decoded) == "table" then
                logTable = decoded -- Use existing log data
            end
        end
    end

    -- Append new log entry
    table.insert(logTable, {
        timestamp = date,
        type = data.type,
        componentId = data.componentId or data.propId,
        variationId = data.variationId,
        textureId = data.textureId,
        name = data.componentName or data.propName
    })

    -- Save updated data back to JSON file
    file = io.open(filePath, "w") -- Open in write mode (overwrite)
    if file then
        file:write(json.encode(logTable, { indent = true })) -- Pretty-print JSON
        file:close()
    else
        print("Error: Could not write to " .. filePath)
    end
end)


RegisterNetEvent("startedClothingCheck", function()
    print("Started clothing check")
end)

RegisterNetEvent("endedClothingCheck", function()
    print("Ended clothing check")
end)
