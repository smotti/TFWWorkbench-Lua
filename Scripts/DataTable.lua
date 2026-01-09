local json = require("json")
local UEHelpers = require("UEHelpers")
local Utils = require("utils")


local function Log(message, funcName)
    Utils.Log(message, "DataTable", funcName)
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

function DataTable:ParseRowData(data)
    Log("Function not implemented", "ParseRowData")
end

function DataTable:DumpDataTable()
    ---@class UDataTable
    local dataTable = self.__table
    local output = {}
    local file = io.open(self.__dumpFile, "w")

    dataTable:ForEachRow(function(rowName, rowData)
        output[rowName] = self:ParseRowData(rowData)
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
    Log("Function not implemented", "AddRow")
end

function DataTable:ModifyRow(name, data)
    Log("Function not implemented", "ModifyRow")
end

function DataTable:RemoveRow(name)
    Log("Function not implemented", "RemoveRow")
end

return DataTable