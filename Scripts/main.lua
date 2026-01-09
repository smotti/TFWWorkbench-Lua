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

--[[
Read all files of the mods `Items` directory. Collect all items
in a table with the keys being the action (`Add`, `Modify`, `Remove`)
and the values being the list of items on which that action needs to
be performed.
]]
local function CollectItems()
    local dirs = IterateGameDirectories()
    local itemsDir = dirs.Game.Content.Paks.Mods.TFWWorkbench.Items

    if not itemsDir then
        Utils.Log(string.format("No such directory %s\n", itemsDir.__absolute_path), "main", "AddItems")
        return
    end

    local itemCollection = {
        Add = {},
        Modify = {},
        Remove = {}
    }
    for _, itemFile in pairs(itemsDir.__files) do
        --Utils.Log(string.format("Adding items from %s\n", itemFile.__name), "main", "AddItems")

        local fp = io.open(itemFile.__absolute_path, "r")
        local success, content = pcall(function() return fp:read("a") end)
        if not success then
            Utils.Log(string.format("Failed to read %s\n", itemFile.__absolute_path))
            fp:close()
        else
            fp:close()
            local success, itemList = pcall(function() return json.decode(content) end)
            if not success then
                Utils.Log(string.format("Failed to parse contents of %s\n", itemFile.__absolute_path), "main", "AddItems")
            else
                for _, itemData in pairs(itemList) do
                    if itemData["Action"] == "Add" then
                        Utils.Log(string.format("Add item - ItemName: %s\tFile: %s\n", itemData["Name"], itemFile.__name), "main", "CollectItems")
                        table.insert(itemCollection.Add, { Name = itemData["Name"], Data = itemData["Data"] })
                    elseif itemData["Action"] == "Modify" then
                        Utils.Log(string.format("Modify item - Item: %s\tFile: %s\n", itemData["Name"], itemFile.__name), "main", "CollectItems")
                        table.insert(itemCollection.Modify, { Name = itemData["Name"], Data = itemData["Data"] })
                    elseif itemData["Action"] == "Remove" then
                        Utils.Log(string.format("Remove item - Item: %s\tFile: %s\n", itemData["Name"], itemFile.__name), "main", "CollectItems")
                        -- NOTE: Probably need some additional data when removing an "Item". Because its
                        -- tags should also be removed.
                        table.insert(itemCollection.Remove, { Name = itemData["Name"], Data = itemData["Data"] })
                    end
                end
            end
        end
    end

    return itemCollection
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
        local itemCollection = CollectItems()

        Items.AddItems(itemCollection.Add, ItemDetailsDataHandler, ItemTagsHandler, TagToRowHandleHandler)

        for _, itemData in ipairs(itemCollection.Modify) do
            ItemDetailsDataHandler.ModifyRow(itemData["Name"], itemData["Data"])
        end

        Items.RemoveItems(itemCollection.Remove, ItemDetailsDataHandler, ItemTagsHandler, TagToRowHandleHandler)
    end
end)