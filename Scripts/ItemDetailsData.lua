local json = require("json")
local UEHelpers = require("UEHelpers")
local Utils = require("utils")
local DataTableParser = require("DataTableParser")


local DataTable = {}

local EItemCategory = {
    Loot = 0,
    Weapon = 1,
    Ammo = 2,
    MedicalSupplies = 3,
    General = 4,
    Dangle = 5,
    EItemCategory_MAX = 6,
}

local function Log(message, funcName)
    Utils.Log(message, "ItemDetailsData", funcName)
end

local function Init(dataTable)
    DataTable.__table = dataTable
    DataTable.__name = "ItemDetailsData"
    DataTable.__kismetlib = UEHelpers.GetKismetSystemLibrary()
    DataTable.__kismetText = UEHelpers.GetKismetTextLibrary()

    local dirs = IterateGameDirectories()
    local modDirs = dirs.Game.Content.Paks.Mods.TFWWorkbench
    if not modDirs then
        Utils.Log("No such directory Contents/Paks/TFWWorkbench", "InitHandler")
    else
        DataTable.__dumpFile = string.format("%s/Dumps/ItemDetailsData.json", modDirs.__absolute_path)
        Log(string.format("DumpFile: %s\n", DataTable.__dumpFile), "InitHandler")
    end
end

local function ToJsonItemMeshTransform(itemMeshTransform)
    local result = {
        Rotation = {},
        Translation = {},
        Scale3D = {}
    }

    for key, value in pairs(result) do
        itemMeshTransform[key]:ForEachProperty(function(property)
            local propertyName = property:GetFName():ToString()
            value[propertyName] = itemMeshTransform[key][propertyName]
        end)
    end

    Log(string.format("Rotation: %s\n", Utils.PrintTable(result.Rotation)), "ToJsonItemMeshTransform")
    Log(string.format("Translation: %s\n", Utils.PrintTable(result.Translation)), "ToJsonItemMeshTransform")
    Log(string.format("Scale3D: %s\n", Utils.PrintTable(result.Scale3D)), "ToJsonItemMeshTransform")

    return result
end

local function ToJsonEItemCategory(itemCategory)
    local categories = {
        [0] = "Loot",
        [1] = "Weapon",
        [2] = "Ammo",
        [3] = "MedicalSupplies",
        [4] = "General",
        [5] = "Dangle",
        [6] = "EItemCategory_Max"
    }
    Log(string.format("ItemType: %s - %d\n", categories[itemCategory], itemCategory), "ToJsonEItemCategory")
    return categories[itemCategory]
end

---@param data FInventoryItemDetails
local function ParseFInventorItemDetails(data)
    if not data then
        return {}
    end

    local kismetLib = DataTable.__kismetlib
    return {
        Category = DataTableParser.ToJson(data.Category, kismetLib),
        ItemName = DataTableParser.ToJson(data.ItemName, kismetLib),
        ItemDescription = DataTableParser.ToJson(data.ItemDescription, kismetLib),
        ItemMesh = DataTableParser.ToJson(data.ItemMesh, kismetLib),
        ItemMeshTransform = ToJsonItemMeshTransform(data.ItemMeshTransform),
        -- We don't care about these two properties as they're always nil
        --ExtraMeshs = nil,
        --ExtraMeshTransform = nil,
        ItemLootRadius = DataTableParser.ToJson(data.ItemLootRadius, kismetLib),
        ItemIconRadius = DataTableParser.ToJson(data.ItemIconRadius, kismetLib),
        ItemIcon = DataTableParser.ToJson(data.ItemIcon, kismetLib),
        ItemType = ToJsonEItemCategory(data.ItemType),
        ItemSubtype = DataTableParser.ToJson(data.ItemSubtype, kismetLib),
        ExtraDetailsRowName = DataTableParser.ToJson(data.ExtraDetailsRowName, kismetLib),
        LootSound = DataTableParser.ToJson(data.LootSound, kismetLib),
        DropSound = DataTableParser.ToJson(data.DropSound, kismetLib),
        ItemSize = DataTableParser.ToJson(data.ItemSize, kismetLib),
        Volume = DataTableParser.ToJson(data.Volume, kismetLib),
        Weight = DataTableParser.ToJson(data.Weight, kismetLib),
        ValueRow = DataTableParser.ToJson(data.ValueRow, kismetLib),
        -- Ignoring them because they are always 0
        --Value = ToJson(data.Value),
        --WaterValue = ToJson(data.WaterValue),
        DropOnDeath = DataTableParser.ToJson(data.DropOnDeath, kismetLib),
        MaxStack = DataTableParser.ToJson(data.MaxStack, kismetLib),
        ExtraTagData = DataTableParser.ToJson(data.ExtraTagData, kismetLib),
        StartingStack = DataTableParser.ToJson(data.StartingStack, kismetLib),
        ConsumableAbility = DataTableParser.ToJson(data.ConsumableAbility, kismetLib),
        BattlepointsRowHandle = DataTableParser.ToJson(data.BattlepointsRowHandle, kismetLib),
        TacCamHighlight = DataTableParser.ToJsonTacCamHighlight(data.TacCamHighlight),
        RareLootCategory = DataTableParser.ToJson(data.RareLootCategory, kismetLib),
        RareLootLocations = DataTableParser.ToJson(data.RareLootLocations, kismetLib)
    }
end

local function DumpDataTable()
    ---@class UDataTable
    local dataTable = DataTable.__table
    local output = {}
    local file = io.open(DataTable.__dumpFile, "w")

    dataTable:ForEachRow(function(rowName, rowData)
        ---@cast rowName string
        ---@cast rowData FInventoryItemDetails
        output[rowName] = ParseFInventorItemDetails(rowData)
    end)

    if file then
        local success, encodedJson = pcall(function() return json.encode(output) end)
        if success then
            file:write(encodedJson)
            file:close()
            Log("Successfully wrote JSON file", "DumpDataTable")
        else
            file:close()
            Log(string.format("Failed to encode JSON: %s", tostring(encodedJson)), "DumpDataTable")
        end
    end
end

local function AddRow(name, data)
    ---@class FInventoryItemDetails
    local rowData = {
        Category = data["Category"],
        ItemName = data["ItemName"],
        ItemDescription = data["ItemDescription"],
        ItemMesh = data["ItemMesh"],
        ItemMeshTransform = data["ItemMeshTransform"],
        ExtraMeshs = {},
        ExtraMeshTransform = {},
        ItemLootRadius = data["ItemLootRadius"],
        ItemIconRadius = data["ItemIconRadius"],
        ItemIcon = data["ItemIcon"],
        ItemType = EItemCategory[data["ItemType"]],
        ItemSubtype = data["ItemSubtype"],
        ExtraDetailsRowName = "None",
        LootSound = data["LootSound"],
        DropSound = data["DropSound"],
        ItemSize = data["ItemSize"],
        Volume = data["Volume"],
        Weight = data["Weight"],
        ValueRow = data["ValueRow"],
        Value = 0,
        WaterValue = 0,
        DropOnDeath = data["DropOnDeath"],
        MaxStack = data["MaxStack"],
        ExtraTagData = data["ExtraTagData"],
        StartingStack = data["StartingStack"],
        ConsumableAbility = data["ConsumableAbility"],
        BattlepointsRowHandle = data["BattlepointsRowHandle"],
        TacCamHighlight = DataTableParser.TacCamColours[data["TacCamHighlight"]],
        RareLootCategory = data["RareLootCategory"],
        RareLootLocations = data["RareLootLocations"]
    }

    -- Need to use custom function that's implemented in the C++ part of this mod.
    AddDataTableRow("InventoryItemDetails", name, rowData)

    Log(string.format("Added row %s\n", name), "AddRow")
end

local function ReplaceRow(name, data)
    local row = DataTable.__table:FindRow(name)
    if not row then
        Log(string.format("Row with name %s not found\n", name), "ReplaceRow")
        return
    end

    local parsedRow = ParseFInventorItemDetails(row)
    for field, value in pairs(data) do
        if field == "ItemType" then
            parsedRow[field] = EItemCategory[value]
        elseif field == "TacCamHighlight" then
            parsedRow[field] = DataTableParser.TacCamColours[value]
        else
            parsedRow[field] = value
        end
    end

    Log(string.format("Replaced row %s by calling AddRow\n", name), "ReplaceRow")
    AddRow(name, parsedRow)
end

local function RemoveRow(itemId)
    DataTable.__table:RemoveRow(itemId)
    Log(string.format("Removed row %s\n", itemId), "RemoveRow")
end

-- Export module functions
DataTable.Init = Init
DataTable.DumpDataTable = DumpDataTable
DataTable.AddRow = AddRow
DataTable.ReplaceRow = ReplaceRow
DataTable.RemoveRow = RemoveRow

return DataTable
