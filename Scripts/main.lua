local json = require("json")
local UEHelpers = require("UEHelpers")
local Utils = require("utils")
local Settings = require("Settings")
local ItemDetailsDataHandler = require("ItemDetailsData")
local Items = require("Items")
local ItemTagsHandler = require("ItemTags")
local TagToRowHandleHandler = require("TagToRowHandle")
local ValueHandler = require("Value")
local ManufacturingGroups = require("ManufacturingGroups")
local ManufacturingRecipes = require("ManufacturingRecipes")
local ManufacturingTags = require("ManufacturingTags")
local CraftingRecipe = require("CraftingRecipe")


-- NOTE Required to parse RecipyCraftTime of ManufactoringRecipies
RegisterCustomProperty({
    ["Name"] = "RecipyCraftTime",
    ["Type"] = PropertyTypes.Int64Property,
    ["BelongsToClass"] = "/Script/FWHubWorld.ManufactoringRecipies",
    ["OffsetInternal"] = 0x68
})

---@class UDataTable
local ItemDetailsData
---@class UDataTable
local ItemTags
---@class UDataTable
local TagToRowHandle

local ManufacturingGroupsHandler = {}
local ManufacturingRecipesHandler = {}
local ManufacturingTagsHandler = {}
local ValueHandlers = {}

local DataCollections = {
    Item = {},
    ItemValue = {},
    CraftingRecipe = {},
    CraftingGroup = {}
}

local function FindOrCreateModDir()
    local dirs = IterateGameDirectories()
    local modDir = dirs.Game.Content.Paks.Mods.TFWWorkbench

    if modDir then
        return modDir
    else
        Utils.Log(string.format("No such directory %s/TFWWorkbench\n", dirs.Game.Content.Paks.Mods.__absolute_path),
            "main")
        Utils.Log(string.format("Creating directory %s/TFWWorkbench\n", dirs.Game.Content.Paks.Mods.__absolute_path),
            "main")
        local success, result, code = os.execute(string.format("mkdir \"%s\\TFWWorkbench\"",
            dirs.Game.Content.Paks.Mods.__absolute_path))
        if not success then
            Utils.Log(string.format("Failed to create directory: %s - %d\n", result, code))
            return nil
        else
            local dirs = IterateGameDirectories()
            return dirs.Game.Content.Paks.Mods.TFWWorkbench
        end
    end
end

local function CollectData(dir)
    Utils.Log(string.format("Collecting data from %s\n", dir.__absolute_path), "main", "CollectData")

    local collection = {
        Add = {},
        Modify = {},
        Remove = {}
    }

    for _, file in pairs(dir.__files) do
        local fp = io.open(file.__absolute_path, "r")
        local success, content = pcall(function() return fp:read("a") end)
        if not success then
            Utils.Log(string.format("Failed to read %s\n", file.__absolute_path))
            fp:close()
        else
            fp:close()
            local success, elementList = pcall(function() return json.decode(content) end)
            if not success then
                Utils.Log(string.format("Failed to parse contents of %s\n", file.__absolute_path), "main", "CollectData")
            else
                for _, element in pairs(elementList) do
                    if element["Action"] == "Add" then
                        Utils.Log(
                            string.format("Add %s - Name: %s\tFile: %s\n", dir.__name, element["Name"], file.__name),
                            "main",
                            "CollectData")
                        table.insert(collection.Add, { Name = element["Name"], Data = element["Data"] })
                    elseif element["Action"] == "Modify" then
                        Utils.Log(
                            string.format("Modify %s - Name: %s\tFile: %s\n", dir.__name, element["Name"], file.__name),
                            "main", "CollectData")
                        table.insert(collection.Modify, { Name = element["Name"], Data = element["Data"] })
                    elseif element["Action"] == "Remove" then
                        Utils.Log(
                            string.format("Remove %s - Item: %s\tFile: %s\n", dir.__name, element["Name"], file.__name),
                            "main", "CollectData")
                        table.insert(collection.Remove, { Name = element["Name"], Data = element["Data"] })
                    end
                end
            end
        end
    end

    return collection
end

local function IsDataTableValid(dataTable)
    return dataTable and dataTable:IsValid()
end

-- Some data tables aren't loaded when the game launches. But only via in-game
-- triggers.
-- Tables the need to be loaded on mod startup:
-- - DT_ManufactoringGroups
local function LoadDataTableAssets()
    local assetRegistryHelpers = StaticFindObject("/Script/AssetRegistry.Default__AssetRegistryHelpers")
    if not assetRegistryHelpers:IsValid() then
        Utils.Log("AssetRegistryHelpers is not valid\n", "main", "LoadDataTableAssets")
    end

    local assetRegistry = nil
    if assetRegistryHelpers then
        assetRegistry = assetRegistryHelpers:GetAssetRegistry()
        if not assetRegistry:IsValid() then
            assetRegistry = StaticFindObject("/Script/AssetRegistry.Default__AssetRegistryImpl")
        end
    end

    if not assetRegistry or not assetRegistry:IsValid() then
        Utils.Log("AssetRegistry is not valid. Can't load data table assets!\n", "main", "LoadDataTableAssets")
        return
    end

    local assetData = {
        ManufacturingGroups = {
            ["PackageName"] = UEHelpers.FindOrAddFName("/Game/FW/UI/Manufactoring/Data/DT_ManufactoringGroups"),
            ["AssetName"] = UEHelpers.FindOrAddFName("DT_ManufactoringGroups")
        }
    }

    for tableName, data in pairs(assetData) do
        Utils.Log(string.format("Loading data table asset for %s\n", tableName), "main", "LoadDataTableAssets")
        local assetClass = assetRegistryHelpers:GetAsset(data)
        if not assetClass:IsValid() then
            Utils.Log(string.format("Failed to load data table asset for %s\n", tableName), "main", "LoadDataTableAssets")
        else
            Utils.Log(
                string.format("Successfully loaded data table asset for %s: %s\n", tableName, assetClass:GetFullName()),
                "main",
                "LoadDataTableAssets")
            -- Adding to the GameInstance's ReferencedObjects so it doesn't get gargabe colllected
            local gameInstance = UEHelpers.GetGameInstance()
            local numRefObjects = gameInstance.ReferencedObjects:GetArrayNum()
            gameInstance.ReferencedObjects[numRefObjects + 1] = assetClass
        end
    end
end

-- Providing the DLL part of the mod with the required data table data
local function InitDataTables()
    for tableName, details in pairs(Settings.DataTables) do
        ConfigureDataTables(tableName, details.Path, details.SourceRow)
    end
end

RegisterConsoleCommandHandler("DumpDataTables", function(fullCmd, params, outputDevice)
    Utils.Log("Handle console command 'DumpDataTables'\n", "main")
    Utils.Log(string.format("Full command: %s\n", fullCmd), "main")

    outputDevice:Log("Dumping data tables")
    --NOTE: Using async calls here to don't lock up the game thread
    if IsDataTableValid(ItemDetailsData) then
        --ExecuteAsync(function() ItemDetailsDataHandler.DumpDataTable() end)
    end

    if IsDataTableValid(ItemTags) then
        --ExecuteAsync(function() ItemTagsHandler.DumpDataTable() end)
    end

    if IsDataTableValid(TagToRowHandle) then
        --ExecuteAsync(function() TagToRowHandleHandler.DumpDataTable() end)
    end

    for _, handler in pairs(ValueHandlers) do
        if IsDataTableValid(handler.__table) then
            --ExecuteAsync(function() handler:DumpDataTable() end)
        end
    end

    if IsDataTableValid(ManufacturingTagsHandler.__table) then
        ExecuteAsync(function() ManufacturingTagsHandler:DumpDataTable() end)
    end

    if IsDataTableValid(ManufacturingRecipesHandler.__table) then
        ExecuteAsync(function() ManufacturingRecipesHandler:DumpDataTable() end)
    end

    if IsDataTableValid(ManufacturingGroupsHandler.__table) then
        ExecuteAsync(function() ManufacturingGroupsHandler:DumpDataTable() end)
    end

    return true
end)

ExecuteInGameThread(function()
    -- Create mod dir if not present and collect data from mod dirs
    local modDir = FindOrCreateModDir()
    for dirName, dir in pairs(modDir) do
        if not (dirName == "Dumps") then
            DataCollections[dirName] = CollectData(dir)
        end
    end

    LoadDataTableAssets()
    InitDataTables()

    -- Initialize data table handlers
    ItemDetailsData = StaticFindObject(Settings.DataTableClassNames.ItemDetailsData)
    if IsDataTableValid(ItemDetailsData) then
        ItemDetailsDataHandler.Init(ItemDetailsData)
    end

    ItemTags = StaticFindObject(Settings.DataTableClassNames.ItemTags)
    if IsDataTableValid(ItemTags) then
        ItemTagsHandler.Init(ItemTags)
    end

    TagToRowHandle = StaticFindObject(Settings.DataTableClassNames.TagToRowHandle)
    if IsDataTableValid(TagToRowHandle) then
        TagToRowHandleHandler.Init(TagToRowHandle)
    end

    local dataTable = StaticFindObject(Settings.DataTableClassNames.ManufacturingTags)
    if IsDataTableValid(dataTable) then
        ManufacturingTagsHandler = ManufacturingTags.new(dataTable)
    end

    local dataTable = StaticFindObject(Settings.DataTableClassNames.ManufacturingRecipes)
    if IsDataTableValid(dataTable) then
        ManufacturingRecipesHandler = ManufacturingRecipes.new(dataTable)
    end

    local dataTable = StaticFindObject(Settings.DataTableClassNames.ManufacturingGroups)
    if IsDataTableValid(dataTable) then
        ManufacturingGroupsHandler = ManufacturingGroups.new(dataTable)
    end

    for _, path in ipairs(Settings.ValueTables) do
        local dataTable = StaticFindObject(path)
        if dataTable and dataTable:IsValid() then
            local dataTableName = Utils.GetDataTableName(dataTable)
            ValueHandlers[dataTableName] = ValueHandler.new(dataTable)
        end
    end

    -- NOTE: These Add/Modify/Remove function calls could potentially also be called asynchronously
    -- if there are ever any "performance" concerns. Though it's more a user experience thing.
    -- As a large amount of items could cause the game thread to be locked up. Meaning the game would
    -- take a bit longer to load into the main menu.
    if IsDataTableValid(ItemDetailsData) and IsDataTableValid(ItemTags) then
        Items.AddItems(dataCollections.Item.Add, ItemDetailsDataHandler, ItemTagsHandler, TagToRowHandleHandler)

        for _, itemData in ipairs(dataCollections.Item.Modify) do
            ItemDetailsDataHandler.ModifyRow(itemData["Name"], itemData["Data"])
        end

        Items.RemoveItems(dataCollections.Item.Remove, ItemDetailsDataHandler, ItemTagsHandler, TagToRowHandleHandler)
    end

    -- NOTE: Not sure if this is the right place to do here. As it requires knowledge about the datas shape.
    -- Which should probably be encapsulated in the corresponding module.
    for action, collection in pairs(dataCollections.ItemValue) do
        for _, element in ipairs(collection) do
            local dataTableName = Utils.GetDataTableName(element["Data"]["DataTable"])
            if dataTableName then
                local handler = ValueHandlers[dataTableName]
                if action == "Add" then
                    handler:AddRow(element["Name"], element["Data"])
                elseif action == "Modify" then
                    handler:ModifyRow(element["Name"], element["Data"])
                elseif action == "Remove" then
                    handler:RemoveRow(element["Name"])
                end
            end
        end
    end
    CraftingRecipe.AddRecipes(dataCollections.CraftingRecipe.Add, ManufacturingRecipesHandler, ManufacturingTagsHandler)
    CraftingRecipe.AddRecipes(DataCollections.CraftingRecipe.Add, ManufacturingRecipesHandler, ManufacturingTagsHandler)
    -- NOTE: Have to wait a bit for FName registration, otherwise parsing of newly added FName values can fail and cause a crash
    ExecuteWithDelay(3500, function()
        for _, element in ipairs(dataCollections.CraftingRecipe.Modify) do
    -- ManufacturingRecipes
    ExecuteWithDelay(100, function()
        CraftingRecipe.AddRecipes(DataCollections.CraftingRecipe.Add, ManufacturingRecipesHandler,
            ManufacturingTagsHandler)
    end)
    ExecuteWithDelay(100, function()
        for _, element in ipairs(DataCollections.CraftingRecipe.Modify) do
            ManufacturingRecipesHandler:ModifyRow(element["Name"], element["Data"])
        end
    end)

    -- ManufacturingGroups
    ExecuteWithDelay(100, function()
        for _, group in ipairs(DataCollections.CraftingGroup.Add) do
            ManufacturingGroupsHandler:AddRow(group["Name"], group["Data"])
        end
    end)

    ExecuteWithDelay(100, function()
        for _, group in ipairs(DataCollections.CraftingGroup.Modify) do
            ManufacturingGroupsHandler:ModifyRow(group["Name"], group["Data"])
        end
    end)

    ExecuteWithDelay(100, function()
        for _, group in ipairs(DataCollections.CraftingGroup.Remove) do
            ManufacturingGroupsHandler:RemoveRow(group["Name"])
        end
    end)
end)
