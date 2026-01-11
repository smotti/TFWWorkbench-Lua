local DataTable = require("DataTable")
local Parser = require("DataTableParser")
local Utils = require("utils")


local function Log(message, funcName)
    Utils.Log(message, "ManufacturingTags", funcName)
end

local ManufacturingTags = setmetatable({}, {__index = DataTable})
ManufacturingTags.__index = ManufacturingTags

function ManufacturingTags.new(dataTable)
    local self = DataTable.new(dataTable)
    setmetatable(self, ManufacturingTags)
    return self
end

---@param data FGameplayTagTableRow
function ManufacturingTags:ParseRowData(data)
    local lib = self.__kismetlib
    return {
        Tag = Parser.ToJson(data.Tag, lib),
        DevComment = Parser.ToJson(data.DevComment, lib)
    }
end

function ManufacturingTags:AddRow(name, data)
    Log(string.format("DATA: %s\n", Utils.PrintTable(data)), "AddRow")
    ---@class FGameplayTagTableRow
    local rowData = {
        Tag = FName(data["Tag"], EFindName.FNAME_Add),
        DevComment = data["DevComment"]
    }

    self.__table:AddRow(name, rowData)
    Log(string.format("Added row %s\n", name), "AddRow")
end

function ManufacturingTags:ModifyRow(name, data)
    self:AddRow(name, data)
    Log(string.format("Modified row %s\n", name), "ModifyRow")
end

return ManufacturingTags