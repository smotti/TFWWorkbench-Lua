local json = require("json")
local Utils = require("utils")
local Settings = require("Settings")
local ItemDetailsDataHandler = require("ItemDetailsData")
local Items = require("Items")
local ItemTagsHandler = require("ItemTags")

---@class UDataTable
local ItemDetailsData
---@class UDataTable
local ItemTags

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

RegisterConsoleCommandHandler("DumpDataTables", function(fullCmd, params, outputDevice)
    Utils.Log("Handle console command 'DumpDataTables'\n", "main")
    Utils.Log(string.format("Full command: %s\n", fullCmd), "main")

    outputDevice:Log("Dumping data tables")

    if ItemDetailsData and ItemDetailsData:IsValid() then
        ItemDetailsDataHandler.DumpDataTable()
    end

    if ItemTags and ItemTags:IsValid() then
        ItemTagsHandler.DumpDataTable()
    end

    return true
end)

ExecuteInGameThread(function()
    ItemDetailsData = StaticFindObject(Settings.DataTableClassNames.ItemDetailsData)
    if ItemDetailsData and ItemDetailsData:IsValid() then
        ItemDetailsDataHandler.Init(ItemDetailsData)
        local itemCollection = CollectItems()
        Items.AddItems(itemCollection.Add, ItemDetailsDataHandler)
    end

    ItemTags = StaticFindObject(Settings.DataTableClassNames.ItemTags)
    if ItemTags and ItemTags:IsValid() then
        ItemTagsHandler.Init(ItemTags)
    end
end)