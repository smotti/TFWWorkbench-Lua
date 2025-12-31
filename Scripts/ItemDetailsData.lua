local json = require("json")
local UEHelpers = require("UEHelpers")
local Settings = require("Settings")
local Converters = require("Converters")

local DumpFile = "ue4ss/Mods/TFWWorkbench/Dumps/ItemDetailsData.json"

local DataTable = {}

local function InitHandler(dataTable)
    DataTable.__table = dataTable
    DataTable.__name = "ItemDetailsData"
    DataTable.__kismetlib = UEHelpers.GetKismetSystemLibrary()
    
    local dirs = IterateGameDirectories()
    local modDirs = dirs.Game.Content.Paks.TFWWorkbench
    if not modDirs then
        print(string.format("[TFWWorkbench] No such directory Contents/Paks/TFWWorkbench\n"))
    else
        DataTable.__dumpFile = string.format("%s/Dumps/ItemDetailsData.json", modDirs.__absolute_path)
        print(string.format("[TFWWorkbench] DumpFile: %s\n", DataTable.__dumpFile))
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
    local kismetLib = DataTable.__kismetlib

    if value == nil then
        print("ToJson value == nil")
        return nil
    end

    local valueType = type(value)

    if valueType == "string" or valueType == "number" or valueType == "boolean" then
        print(string.format("[TFWWorkbench] ToJson non-custom type: %s\n", valueType))
        return value
    elseif valueType == "userdata" then
        local str = tostring(value)
        print(string.format("[TFWWorkbench] ToJson userdata type: %s\n", str))

        if str:match("TSoftObjectPtr") then
            local success, result = pcall(function()
                return kismetLib:Conv_SoftObjectReferenceToString(value)
            end)
            if success then
                print(string.format("[TFWWorkbench] ToJson TSoftObjectPtr: %s\n", result:ToString()))
                return result:ToString()
            end
        elseif str:match("UScriptStruct") then
            local result = {}
            value:ForEachProperty(function(property)
                local propertyName = property:GetFName():ToString()
                print(string.format("[TFWWorkbench] ToJson UScriptStruct Property: %s\n", propertyName))
                result[propertyName] = ToJson(value[propertyName])
            end)
            return result
        elseif str:match("TArray") then
            local result = {}
            value:ForEach(function(index, element)
                result[index] = ToJson(element:get())
                print(string.format("[TFWWorkbench] ToJson TArray: %d - %s\n", index, tostring(result[index])))
            end)
            return result
        elseif str:match("UDataTable") then
            print(string.format("[TFWWorkbench] ToJson UDataTable: %s\n", string.match(value:GetFullName(), "^DataTable%s+(.*)")))
            return string.match(value:GetFullName(), "^DataTable%s+(.*)")
        end

        --- Try ToString method for FName, FText, and FString
        local success, result = pcall(function() return value:ToString() end)
        if success and result then
            print(string.format("[TFWWorkbench] ToJson ToString(): %s\n", result))
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

    print(string.format("[TFWWorkbench] ToJsonItemMeshTransform Rotation: %s\n", PrintTable(result.Rotation)))
    print(string.format("[TFWWorkbench] ToJsonItemMeshTransform Translation: %s\n", PrintTable(result.Translation)))
    print(string.format("[TFWWorkbench] ToJsonItemMeshTransform Scale3D: %s\n", PrintTable(result.Scale3D)))

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
    print(string.format("[TFWWorkbench] ToJsonEItemCategory ItemType: %s - %d\n", categories[itemCategory], itemCategory))
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
    print(string.format("[TFWWorkbench] ToJsonTacCamHighlight TacCamHighlight: %s - %d\n", colors[tacCamColor], tacCamColor))
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
            print(string.format("[TFWWorkbench:%s] Successfully wrote JSON file", tableName))
        else
            print(string.format("[TFWWorkbench:%s] Failed to encode JSON: %s", tableName, tostring(encodedJson)))
            file:close()
        end
    end
end

-- Export module functions
--DataTable.convertFInventoryItemDetails = convertFInventoryItemDetails
DataTable.Init = InitHandler
DataTable.DumpDataTable = DumpDataTable

return DataTable