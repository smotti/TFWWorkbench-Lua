--[[
This module implements a different interface to support multiple distinct
instances of a "handler". For each individual value data table.
It's probably better to refactor all the other data table modules to follow
the abstraction that this modules implements.
]]
local json = require("json")
local Parser = require("DataTableParser")
local UEHelpers = require("UEHelpers")
local Utils = require("utils")


local function Log(message, funcName)
    Utils.Log(message, "Value", funcName)
end

local DataTable = {
    __table = nil,
    __name = "",
    __dumpFile = "",
    __kismetlib = nil
}
DataTable.__index = DataTable

function DataTable.new(dataTable)
    local self = setmetatable({}, DataTable)
    self.__table = dataTable
    self.__name = Utils.GetDataTableName(dataTable)
    self.__kismetlib = UEHelpers.GetKismetSystemLibrary()

    local dirs = IterateGameDirectories()
    local modDirs = dirs.Game.Content.Paks.Mods.TFWWorkbench
    if not modDirs then
        Log("No such directory Contents/Paks/TFWWorkbench", "new")
    else
        self.__dumpFile = string.format("%s/Dumps/%s.json", modDirs.__absolute_path, self.__name)
        Log(string.format("DumpFile: %s\n", self.__dumpFile), "new")
    end

    return self
end

---@param data FValueOverride
function DataTable:ParseFValueOverride(data)
    local lib = self.__kismetlib
    return {
        ValueType = Parser.ToJson(data.ValueType, lib),
        Value = Parser.ToJson(data.Value, lib),
        ExtractionExperienceValue = Parser.ToJson(data.ExtractionExperienceValue, lib)
    }
end

function DataTable:ToFValueOverride(data)
    return {
        ValueType = data["ValueType"],
        Value = data["Value"],
        ExtractionExperienceValue = data["ExtractionExperienceValue"]
    }
end

function DataTable:DumpDataTable()
    ---@class UDataTable
    local dataTable = self.__table
    local output = {}
    local file = io.open(self.__dumpFile, "w")

    dataTable:ForEachRow(function(rowName, rowData)
        output[rowName] = self:ParseFValueOverride(rowData)
    end)

    if file then
        local success, encodedJson = pcall(function() return json.encode(output) end)
        if success then
            file:write(encodedJson)
            file:close()
            Log("Successfully wrote JSON file", "DumpDataTable")
        else
            file:close()
            Log("Failed to encode JSON", "DumpDataTable")
        end
    end
end

function DataTable:AddRow(name, data)
    local dataTable = self.__table
    dataTable:AddRow(name, self:ToFValueOverride(data))

    Log(string.format("Adding row %s\n", name), "AddRow")
end

return DataTable