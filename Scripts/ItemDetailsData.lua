local json = require("json")
local UEHelpers = require("UEHelpers")
local Utils = require("utils")
local DataTableParser = require("DataTableParser")
local Settings = require("Settings")

local DataTable = {}

local function Log(message, funcName)
    Utils.Log(message, "ItemDetailsData", funcName)
end

local function Init(dataTable)
    DataTable.__table = dataTable
    DataTable.__name = "ItemDetailsData"
    DataTable.__kismetlib = UEHelpers.GetKismetSystemLibrary()
    
    local dirs = IterateGameDirectories()
    local modDirs = dirs.Game.Content.Paks.Mods.TFWWorkbench
    if not modDirs then
        Utils.Log("No such directory Contents/Paks/TFWWorkbench", "InitHandler")
    else
        DataTable.__dumpFile = string.format("%s/Dumps/ItemDetailsData.json", modDirs.__absolute_path)
        Log(string.format("DumpFile: %s\n", DataTable.__dumpFile), "InitHandler")
    end
end

local function PrintTable(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. PrintTable(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
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

    Log(string.format("Rotation: %s\n", PrintTable(result.Rotation)), "ToJsonItemMeshTransform")
    Log(string.format("Translation: %s\n", PrintTable(result.Translation)), "ToJsonItemMeshTransform")
    Log(string.format("Scale3D: %s\n", PrintTable(result.Scale3D)), "ToJsonItemMeshTransform")

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

local function ToJsonTacCamHighlight(tacCamColor)
    local colors = {
        [0] = "Default",
        [1] = "Green",
        [2] = "Red",
        [3] = "Yellow",
        [4] = "TacCamColours_Max"
    }
    Log(string.format("TacCamHighlight: %s - %d\n", colors[tacCamColor], tacCamColor), "ToJsonTacCamHighlight")
    return colors[tacCamColor]
end

---@param data FInventoryItemDetails
local function ParseFInventorItemDetails(data)
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
        TacCamHighlight = ToJsonTacCamHighlight(data.TacCamHighlight),
        RareLootCategory = DataTableParser.ToJson(data.RareLootCategory, kismetLib),
        RareLootLocations = DataTableParser.ToJson(data.RareLootLocations, kismetLib)
    }
end

local function DumpDataTable()
    ---@class UDataTable
    local dataTable = DataTable.__table
    local tableName = DataTable.__name

    -- Get KismetSystemLibrary for type conversions
    local kismetLib = UEHelpers.GetKismetSystemLibrary()

    local output = {}
    local file = io.open(DataTable.__dumpFile, "w")

    local item = dataTable:FindRow("FirstAid")
    output["FirstAid"] = ParseFInventorItemDetails(item)
--    dataTable:ForEachRow(function(rowName, rowData)
--        ---@cast rowName string
--        ---@cast rowData FInventoryItemDetails
--        -- Convert userdata to plain table before adding to output
--        output[rowName] = ParseFInventorItemDetails(rowData)
--    end)

    if file then
        local success, encodedJson = pcall(function() return json.encode(output) end)
        if success then
            file:write(encodedJson)
            file:close()
            Log("Successfully wrote JSON file", "DumpDataTable")
        else
            Log(string.format("Failed to encode JSON: %s", tostring(encodedJson)), "DumpDataTable")
            file:close()
        end
    end
end

-- Export module functions
--DataTable.convertFInventoryItemDetails = convertFInventoryItemDetails
DataTable.Init = Init
DataTable.DumpDataTable = DumpDataTable

return DataTable