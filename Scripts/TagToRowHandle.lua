--[[
A module to manage rows in the `DT_TagToRowHandle` data table
]]
local DataTableParser = require("DataTableParser")
local json = require("json")
local UEHelpers = require("UEHelpers")
local Utils = require("utils")

local function Log(message, funcName)
    Utils.Log(message, "TagToRowHandle", funcName)
end

local DataTable = {}

local function Init(dataTable)
    DataTable.__table = dataTable
    DataTable.__name = "TagToRowHandle"
    DataTable.__kismetlib = UEHelpers.GetKismetSystemLibrary()
    DataTable.__kismetText = UEHelpers.GetKismetTextLibrary()

    local dirs = IterateGameDirectories()
    local modDirs = dirs.Game.Content.Paks.Mods.TFWWorkbench
    if not modDirs then
        Utils.Log("No such directory Contents/Paks/TFWWorkbench", "Init")
    else
        DataTable.__dumpFile = string.format("%s/Dumps/DT_TagToRowHandle.json", modDirs.__absolute_path)
        Log(string.format("DumpFile: %s\n", DataTable.__dumpFile), "Init")
    end
end

local EStoreCategory = {
    Item = 0,
    QuestItem = 1,
    Weapon = 2,
    Container = 3,
    Rig = 4,
    Dangly = 5,
    Frame = 6,
    Buddy = 7
}

local function ToJsonEStoreCategory(storeCategory)
    local categories = {
        [0] = "Item",
        [1] = "QuestItem",
        [2] = "Weapon",
        [3] = "Container",
        [4] = "Rig",
        [5] = "Dangly",
        [6] = "Frame",
        [7] = "Buddy"
    }
    Log(string.format("EStoreCategroy: %s - %d\n", categories[storeCategory], storeCategory), "ToJsonEStoreCategory")
    return categories[storeCategory]
end

---Parse FWItemType to table that can be json encoded.
---@param data FFWItemType
---@return table
local function ParseFWItemType(data)
    local kismetLib = DataTable.__kismetlib
    return {
        DataRow = DataTableParser.ToJson(data.DataRow, kismetLib),
        DataType = ToJsonEStoreCategory(data.DataType)
    }
end

local function DumpDataTable()
    ---@class UDataTable
    local dataTable = DataTable.__table
    local output = {}
    local file = io.open(DataTable.__dumpFile, "w")

    dataTable:ForEachRow(function(rowName, rowData)
        ---@cast rowName string
        ---@cast rowData FFWItemType
        output[rowName] = ParseFWItemType(rowData)
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

local function AddRow(itemTag, data)
    local fwItemType = {
        DataType = EStoreCategory[data["DataType"]],
        DataRow = {
            RowName = FName(data["Name"], EFindName.FNAME_Add),
            DataTable = StaticFindObject(data["DataTable"])
        }
    }
    DataTable.__table:AddRow(itemTag, fwItemType)
    Log(string.format("Adding row %s\n", itemTag), "AddRow")
end

DataTable.Init = Init
DataTable.AddRow = AddRow
DataTable.DumpDataTable = DumpDataTable

return DataTable