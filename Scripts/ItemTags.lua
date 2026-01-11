--[[
A module to manage rows in the `DT_ItemTags` data table
]]
local DataTableParser = require("DataTableParser")
local json = require("json")
local UEHelpers = require("UEHelpers")
local Utils = require("utils")

local function Log(message, funcName)
    Utils.Log(message, "ItemTags", funcName)
end

local DataTable = {}

local function RegisterTests()
    RegisterConsoleCommandHandler("TestItemTagsHandler", function(fullCmd, params, outputDevice)
        Log(string.format("Handle console command: %s\n", fullCmd), "TestItemTagsHandler")

        local itemTag = "Inventory.Item.TestItem"
        local testData = {
            Tag = "Test",
            DevComment = "Test"
        }

        DataTable.ModifyRow(itemTag, testData)
        local row = DataTable.__table:FindRow(itemTag)
        if row then
            if row.Tag:ToString() == testData.Tag and row.DevComment:ToString() == testData.DevComment then
                outputDevice:Log("[x] Test ModifyRow\n")
            else
                outputDevice:Log("[-] Test ModifyRow\n")
            end
        else
            outputDevice:Log("[-] Test ModifyRow\n")
        end

        DataTable.RemoveRow(itemTag)
        local row = DataTable.__table:FindRow(itemTag)
        if not row then
            outputDevice:Log("[x] Test RemoveRow\n")
        else
            outputDevice:Log("[-] Test RemoveRow\n")
        end

        return true
    end)
end

local function Init(dataTable)
    DataTable.__table = dataTable
    DataTable.__name = "ItemTags"
    DataTable.__kismetlib = UEHelpers.GetKismetSystemLibrary()
    DataTable.__kismetText = UEHelpers.GetKismetTextLibrary()

    local dirs = IterateGameDirectories()
    local modDirs = dirs.Game.Content.Paks.Mods.TFWWorkbench
    if not modDirs then
        Log("No such directory Contents/Paks/TFWWorkbench", "Init")
    else
        DataTable.__dumpFile = string.format("%s/Dumps/DT_ItemTags.json", modDirs.__absolute_path)
        Log(string.format("DumpFile: %s\n", DataTable.__dumpFile), "Init")
    end

    RegisterTests()
end

---Parse FGameplayTagTableRow to table that can be json encoded.
---@param data FGameplayTagTableRow
---@return table
local function ParseFGameplayTagTableRow(data)
    local kismetLib = DataTable.__kismetlib
    return {
        Tag = DataTableParser.ToJson(data.Tag, kismetLib),
        DevComment = DataTableParser.ToJson(data.DevComment, kismetLib)
    }
end

local function DumpDataTable()
    ---@class UDataTable
    local dataTable = DataTable.__table
    local output = {}
    local file = io.open(DataTable.__dumpFile, "w")

    dataTable:ForEachRow(function(rowName, rowData)
        ---@cast rowName string
        ---@cast rowData FGameplayTagTableRow
        output[rowName] = ParseFGameplayTagTableRow(rowData)
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

local function AddRow(itemTag)
    DataTable.__table:AddRow(itemTag, { Tag = FName(itemTag, EFindName.FNAME_Add), DevComment = "" })
    Log(string.format("Added row %s\n", itemTag), "AddRow")
end

--NOTE: Not sure if we should really have that. I guess it could come in handy eventually. To redirect
--the game to another item instead of the original.
local function ModifyRow(itemTag, tagData)
    DataTable.__table:AddRow(
        itemTag,
        { Tag = FName(tagData.Tag, EFindName.FNAME_Add), DevComment = tagData.DevComment })
    Log(string.format("Modifed row %s - %s\n", itemTag, Utils.PrintTable(tagData)), "ModifyRow")
end

local function RemoveRow(itemTag)
    DataTable.__table:RemoveRow(itemTag)
    Log(string.format("Removed row %s\n", itemTag), "RemoveRow")
end

DataTable.Init = Init
DataTable.AddRow = AddRow
DataTable.DumpDataTable = DumpDataTable
DataTable.ModifyRow = ModifyRow
DataTable.RemoveRow = RemoveRow

return DataTable
