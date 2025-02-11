-- Mapping component IDs to clothing names
local clothingNames = {
    [0] = "Head",
    [1] = "Beard",
    [2] = "Hair",
    [3] = "Arms",
    [4] = "Pants",
    [5] = "Parachute/Bag",
    [6] = "Shoes",
    [7] = "Tie/Scarf/Necklace",
    [8] = "T-Shirt",
    [9] = "Bulletproof Vest/Bag",
    [10] = "Decals",
    [11] = "Vest/Sweater/Jacket"
}

-- Mapping prop IDs to names
local propNames = {
    [0] = "Hat",
    [1] = "Glasses",
    [2] = "Earrings",
    [3] = "Unknown Prop 3",
    [4] = "Unknown Prop 4",
    [5] = "Wristwear",
    [6] = "Watches",
    [7] = "Bracelets"
}

local showingSpotlight = false
local cancelled = true
local location = vec4(-1411.43, 2632.86, 17.64, 50.79)

-- Skip options stored in a table
local skipOptions = {
    hair = true,
    arms = true,
    masks = true,
    pants = false,
    bag = true,
    hats = false,
    glasses = false,
    accessories = false
}

-- Start spotlight loop to focus on the player's face
local function startSpotlightLoop()
    CreateThread(function()
        while showingSpotlight do
            Wait(0)

            local ped = PlayerPedId()
            local pedCoords, pedHeading = cache.coords,

            SetEntityCoords(ped, location)
            SetEntityHeading(ped, location.w)

            local heading = GetEntityHeading(ped)
            if pedCoords then
                local spotlightPos = vector3(pedCoords.x, pedCoords.y, pedCoords.z + 4.0)

                -- Get the player's head position
                local boneIndex = GetPedBoneIndex(ped, 31086) -- Head bone index (face)
                local headCoords = GetWorldPositionOfEntityBone(ped, boneIndex)

                -- Calculate the direction to the player's head
                local direction = vector3(headCoords.x - spotlightPos.x, headCoords.y - spotlightPos.y, headCoords.z - spotlightPos.z)
                direction = direction / math.sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z)

                -- Draw the spotlight towards the player's face
                DrawSpotLight(spotlightPos.x, spotlightPos.y, spotlightPos.z, direction.x, direction.y, direction.z, 255, 255, 255,
                    155.0, 5.0, 5.0, 1000.0, 255.0)
            end
        end
    end)
end

local function resetToOriginal(ped)
    print("Resetting clothing and props to original state")
    for componentId = 0, 12 do
        SetPedComponentVariation(ped, componentId, 0, 0, 0)
    end

    for propId = 0, 7 do
        SetPedPropIndex(ped, propId, -1, -1, false)
    end
end

local function waitForClothingChange(ped, componentId)
    local isApplied = false
    while not isApplied do
        -- Check if the component is applied (you can adjust the logic as needed)
        -- For example, check if the component variation is applied properly
        local currentVariation = GetPedDrawableVariation(ped, componentId)
        if currentVariation ~= -1 then
            isApplied = true
        end
        Wait(60) -- Wait a bit before checking again
    end
end

local function applyComponentVariations(ped, componentId, bool)
    local validVariationFound = false
    local maxVariationId = GetNumberOfPedDrawableVariations(ped, componentId) - 1

    for variationId = 0, maxVariationId do
        if cancelled then break end

        local maxTextureId = GetNumberOfPedTextureVariations(ped, componentId, variationId) - 1
        for textureId = 0, maxTextureId do
            if cancelled then break end
            SetPedComponentVariation(ped, componentId, variationId, textureId, 0)
            local clothingName = clothingNames[componentId] or "Unknown Component"

            -- Busyspinner handling
            if BusyspinnerIsOn() or BusyspinnerIsDisplaying() then
                print("BUSY SPINNER DETECTED! Waiting for 5 seconds...")
                -- Wait for 5 seconds before continuing
                TriggerServerEvent("printCustomClothing", {
                    type = "clothing",
                    componentId = componentId,
                    variationId = variationId,
                    textureId = textureId,
                    componentName = clothingName
                })
                Wait(5000)

                -- Recheck the condition for busy spinner after waiting
                if BusyspinnerIsOn() or BusyspinnerIsDisplaying() then
                    print("Still busy, waiting another 5 seconds...")
                    Wait(5000)
                end
            end

            -- Wait for the clothing change to be applied before continuing
            waitForClothingChange(ped, componentId)

            print(string.format("[Clothing] Applied: %s | Variation: %d | Texture: %d", clothingName, variationId, textureId))
            validVariationFound = true
            Wait(0)
        end
    end
    return validVariationFound
end

local function applyClothingAndProps(bool)
    if not cancelled then return end
    local ped = cache.ped
    resetToOriginal(ped)
    startSpotlightLoop()
    showingSpotlight = true
    cancelled = false

    storedWaitTime = bool == "rapid" and 30 or bool
    FreezeEntityPosition(ped, true)

    for componentId = 1, 12 do
        if cancelled then break end
        resetToOriginal(ped)

        if (componentId == 1 and skipOptions.masks) or 
           (componentId == 2 and skipOptions.hair) or 
           (componentId == 3 and skipOptions.arms) or 
           (componentId == 5 and skipOptions.bag) or 
           (componentId == 4 and skipOptions.pants) then
            goto continue
        end

        local componentWaitTime = (componentId == 3 and 10) or (componentId == 7 and 75) or (componentId == 8 and 75) or storedWaitTime
        print(string.format("Processing Component %d (%s)", componentId, clothingNames[componentId] or "Unknown"))

        local validVariationFound = applyComponentVariations(ped, componentId, componentWaitTime)
        if not validVariationFound then
            print(string.format("No valid variation found for Component %d (%s)", componentId, clothingNames[componentId] or "Unknown"))
        end
        ::continue::
    end

    -- Apply props similarly with waiting loop
    for propId = 0, 7 do
        if cancelled then break end
        if (propId == 0 and skipOptions.hats) or (propId == 1 and skipOptions.glasses) then goto continue end
        local validPropFound = false

        local maxVariationId = GetNumberOfPedPropDrawableVariations(ped, propId) - 1
        for variationId = 0, maxVariationId do
            if cancelled then break end

            local maxTextureId = GetNumberOfPedPropTextureVariations(ped, propId, variationId) - 1
            for textureId = 0, maxTextureId do
                if cancelled then break end
                SetPedPropIndex(ped, propId, variationId, textureId, false)
                local propName = propNames[propId] or "Unknown Prop"

                -- Busyspinner handling
                if BusyspinnerIsOn() or BusyspinnerIsDisplaying() then
                    print("BUSY SPINNER DETECTED! Waiting for 5 seconds...")
                    -- Wait for 5 seconds before continuing
                    TriggerServerEvent("printCustomClothing", {
                        type = "clothing",
                        componentId = propId,
                        variationId = variationId,
                        textureId = textureId,
                        componentName = propName
                    })
                    Wait(5000)

                    -- Recheck the condition for busy spinner after waiting
                    if BusyspinnerIsOn() or BusyspinnerIsDisplaying() then
                        print("Still busy, waiting another 5 seconds...")
                        Wait(5000)
                    end
                end

                -- Wait for the prop application to be completed
                waitForClothingChange(ped, componentId)

                print(string.format("[Prop] Applied: %s | Variation: %d | Texture: %d", propName, variationId, textureId))
                validPropFound = true
                Wait(0)
            end
        end

        if not validPropFound then
            print(string.format("No valid prop found for Prop %d (%s)", propId, propNames[propId] or "Unknown"))
        end
        ::continue::
    end
    TriggerServerEvent("endedClothingCheck")
    FreezeEntityPosition(ped, false)
    showingSpotlight = false
end


RegisterCommand("applyclothing", function(_, args)
    ExecuteCommand("hideallhuds")
    TriggerServerEvent("startedClothingCheck")
    RenderScriptCams(false, false, 0, true, true)
    DestroyAllCams()
    exports.mainui:hideMainUI()
    applyClothingAndProps(args[1])
end, false)

RegisterCommand("cancelapplyClothing", function()
    ExecuteCommand("showallhuds")
    DestroyAllCams()
    exports.mainui:hideMainUI()
    cancelClothing()
end, false)

function cancelClothing()
    cancelled = true
    showingSpotlight = false
    resetToOriginal(cache.ped)
    FreezeEntityPosition(cache.ped, false)
end


local function applySpecificProp(ped, propId, variationId, textureId)
    print(string.format("Applying specific prop: %s | Variation: %d", propNames[propId] or "Unknown Prop", variationId))
    -- Apply the prop with the specified variation
    SetPedPropIndex(ped, propId, variationId, textureId, false)
    print(string.format("[Prop Applied] %s | Variation: %d", propNames[propId] or "Unknown Prop", variationId))
end


local function applySpecificComponent(ped, componentId, textureId)
    resetToOriginal(ped)
    SetPedComponentVariation(ped, componentId, textureId, 0, 0)
end

RegisterCommand("applyvest", function(_, args)
    local ped = cache.ped
    applySpecificComponent(ped, 9, tonumber(args[1]), tonumber(args[2]))
end, false)

RegisterCommand("applyshoes", function(_, args)
    local ped = cache.ped
    applySpecificComponent(ped, 6, tonumber(args[1]), tonumber(args[2]))
end, false)

RegisterCommand("applypants", function(_, args)
    local ped = cache.ped
    applySpecificComponent(ped, 4, tonumber(args[1]) , tonumber(args[2]))
end, false)

RegisterCommand("applyhair", function(_, args)
    local ped = cache.ped
    applySpecificComponent(ped, 2, tonumber(args[1]), tonumber(args[2]))
end, false)

RegisterCommand("applybeard", function(_, args)
    local ped = cache.ped
    applySpecificComponent(ped, 1, tonumber(args[1]), tonumber(args[2]))
end, false)

RegisterCommand("applyarms", function(_, args)
    local ped = cache.ped
    applySpecificComponent(ped, 3, tonumber(args[1]), tonumber(args[2]))
end, false)

RegisterCommand("applybag", function(_, args)
    local ped = cache.ped
    applySpecificComponent(ped, 5, tonumber(args[1]), tonumber(args[2]))
end, false)

RegisterCommand("applytie", function(_, args)
    local ped = cache.ped
    applySpecificComponent(ped, 7, tonumber(args[1]), tonumber(args[2]))
end, false)

RegisterCommand("applyshirt", function(_, args)
    local ped = cache.ped
    applySpecificComponent(ped, 8, tonumber(args[1]), tonumber(args[2]))
end, false)

RegisterCommand("applyhat", function(_, args)
    local ped = cache.ped
    applySpecificProp(ped, 0, tonumber(args[1]), tonumber(args[2]))
end, false)

RegisterCommand("applyglasses", function(_, args)
    local ped = cache.ped
    applySpecificProp(ped, 1, tonumber(args[1]), tonumber(args[2]))
end, false)

RegisterCommand("applyearrings", function(_, args)
    local ped = cache.ped
    applySpecificProp(ped, 2, tonumber(args[1]), tonumber(args[2]))
end, false)

RegisterCommand("applywristwear", function(_, args)
    local ped = cache.ped
    applySpecificProp(ped, 5, tonumber(args[1]), tonumber(args[2]))
end, false)

RegisterCommand("applywatch", function(_, args)
    local ped = cache.ped
    applySpecificProp(ped, 6, tonumber(args[1]), tonumber(args[2]))
end, false)

RegisterCommand("applybracelet", function(_, args)
    local ped = cache.ped
    applySpecificProp(ped, 7, tonumber(args[1]), tonumber(args[2]))
end, false)


--gsf vest = 9

RegisterCommand("server", function()
    TriggerServerEvent("printCustomClothing", {
        type = "clothing",
        componentId = 1,
        variationId = 2,
        textureId = 3,
        componentName = "test"
    })
end)
