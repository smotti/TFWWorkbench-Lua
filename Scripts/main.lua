local json = require("json")
local UEHelpers = require("UEHelpers")
local Utils = require("utils")
local Settings = require("Settings")
local Parser = require("DataTableParser")
local ItemDetailsDataHandler = require("ItemDetailsData")
local Items = require("Items")
local ItemTagsHandler = require("ItemTags")
local TagToRowHandleHandler = require("TagToRowHandle")

---@class UDataTable
local ItemDetailsData
---@class UDataTable
local ItemTags
---@class UDataTable
local TagToRowHandle

--TODO Write a function that checks if the mod's directory exists.
--If not it should be created.

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

RegisterConsoleCommandHandler("DumpDataTables", function(fullCmd, params, outputDevice)
    Utils.Log("Handle console command 'DumpDataTables'\n", "main")
    Utils.Log(string.format("Full command: %s\n", fullCmd), "main")

    outputDevice:Log("Dumping data tables")
    --NOTE: Using async calls here to don't lock up the game thread
    if IsDataTableValid(ItemDetailsData) then
        ExecuteAsync(function() ItemDetailsDataHandler.DumpDataTable() end)
    end

    if IsDataTableValid(ItemTags) then
        ExecuteAsync(function() ItemTagsHandler.DumpDataTable() end)
    end

    if IsDataTableValid(TagToRowHandle) then
        ExecuteAsync(function() TagToRowHandleHandler.DumpDataTable() end)
    end

    return true
end)

ExecuteInGameThread(function()
    local modDir = FindOrCreateModDir()
    local dataCollections = {}
    for dirName, dir in pairs(modDir) do
        if not (dirName == "Dumps") then
            dataCollections[dirName] = CollectData(dir)
        end
    end

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
    end
end)