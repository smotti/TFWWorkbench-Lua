local json = require("json")
local UEHelpers = require("UEHelpers")
local Utils = require("utils")
local Settings = require("Settings")
local Converters = require("Converters")

local DumpFile = "ue4ss/Mods/TFWWorkbench/Dumps/ItemDetailsData.json"

local DataTable = {}

local function Log(message, funcName)
    Utils.Log(message, "ItemDetailsData", funcName)
end

local function InitHandler(dataTable)
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

function PrintTable(o)
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

local function ToJson(value)
    -- That needs to be refactored, because this ToJson function will be pulled out into
    -- a dedicated modules for common parsing functionality
    local kismetLib = DataTable.__kismetlib

    if value == nil then
        Log("value == nil", "ToJson")
        return nil
    end

    local valueType = type(value)

    if valueType == "string" or valueType == "number" or valueType == "boolean" then
        Log(string.format("non-custom type: %s\n", valueType), "ToJson")
        return value
    elseif valueType == "userdata" then
        local str = tostring(value)
        Log(string.format("userdata type: %s\n", str), "ToJson")

        if str:match("TSoftObjectPtr") then
            local success, result = pcall(function()
                return kismetLib:Conv_SoftObjectReferenceToString(value)
            end)
            if success then
                Log(string.format("TSoftObjectPtr: %s\n", result:ToString()), "ToJson")
                return result:ToString()
            end
        elseif str:match("UScriptStruct") then
            local result = {}
            value:ForEachProperty(function(property)
                local propertyName = property:GetFName():ToString()
                Log(string.format("UScriptStruct Property: %s\n", propertyName), "ToJson")
                result[propertyName] = ToJson(value[propertyName])
            end)
            return result
        elseif str:match("TArray") then
            local result = {}
            value:ForEach(function(index, element)
                result[index] = ToJson(element:get())
                Log(string.format("TArray: %d - %s\n", index, tostring(result[index])), "ToJson")
            end)
            return result
        elseif str:match("UDataTable") then
            Log(string.format("UDataTable: %s\n", string.match(value:GetFullName(), "^DataTable%s+(.*)")), "ToJson")
            return string.match(value:GetFullName(), "^DataTable%s+(.*)")
        end

        --- Try ToString method for FName, FText, and FString
        local success, result = pcall(function() return value:ToString() end)
        if success and result then
            Log(string.format("ToString(): %s\n", result), "ToJson")
            return result
        end
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
    return {
        Category = ToJson(data.Category),
        ItemName = ToJson(data.ItemName),
        ItemDescription = ToJson(data.ItemDescription),
        ItemMesh = ToJson(data.ItemMesh),
        ItemMeshTransform = ToJsonItemMeshTransform(data.ItemMeshTransform),
        -- We don't care about these two properties as they're always nil
        --ExtraMeshs = nil,
        --ExtraMeshTransform = nil,
        ItemLootRadius = ToJson(data.ItemLootRadius),
        ItemIconRadius = ToJson(data.ItemIconRadius),
        ItemIcon = ToJson(data.ItemIcon),
        ItemType = ToJsonEItemCategory(data.ItemType),
        ItemSubtype = ToJson(data.ItemSubtype),
        ExtraDetailsRowName = ToJson(data.ExtraDetailsRowName),
        LootSound = ToJson(data.LootSound),
        DropSound = ToJson(data.DropSound),
        ItemSize = ToJson(data.ItemSize),
        Volume = ToJson(data.Volume),
        Weight = ToJson(data.Weight),
        ValueRow = ToJson(data.ValueRow),
        -- Ignoring them because they are always 0
        --Value = ToJson(data.Value),
        --WaterValue = ToJson(data.WaterValue),
        DropOnDeath = ToJson(data.DropOnDeath),
        MaxStack = ToJson(data.MaxStack),
        ExtraTagData = ToJson(data.ExtraTagData),
        StartingStack = ToJson(data.StartingStack),
        ConsumableAbility = ToJson(data.ConsumableAbility),
        BattlepointsRowHandle = ToJson(data.BattlepointsRowHandle),
        TacCamHighlight = ToJsonTacCamHighlight(data.TacCamHighlight),
        RareLootCategory = ToJson(data.RareLootCategory),
        RareLootLocations = ToJson(data.RareLootLocations)
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
DataTable.Init = InitHandler
DataTable.DumpDataTable = DumpDataTable

return DataTable