local DataTable = require("DataTable")
local Parser = require("DataTableParser")
local Utils = require("utils")


local function Log(message, funcName)
    Utils.Log(message, "ManufacturingGroups", funcName)
end

local ManufacturingGroups = setmetatable({}, {__index = DataTable})
ManufacturingGroups.__index = ManufacturingGroups

function ManufacturingGroups.new(dataTable)
    local self = DataTable.new(dataTable)
    setmetatable(self, ManufacturingGroups)
    return self
end

---@param data FManufactoringGroups
function ManufacturingGroups:ParseRowData(data)
    local lib = self.__kismetlib
    return {
        ManufactoringGroupName = Parser.ToJson(data.ManufactoringGroupName, lib),
        ManufactoringGroupSubtext = Parser.ToJson(data.ManufactoringGroupSubtext, lib),
        ManufactoringGroupIcon = Parser.ToJson(data.ManufactoringGroupIcon, lib),
        ManufactoringGroupDetailsText = Parser.ToJson(data.ManufactoringGroupDetailsText, lib),
        ManufactoringDetailsGroupIcon = Parser.ToJson(data.ManufactoringDetailsGroupIcon, lib),
        ManufactoringRecipies = Parser.ToJson(data.ManufactoringRecipies, lib),
        FilterTag = Parser.ToJson(data.FilterTag, lib)
    }
end

function ManufacturingGroups:AddRow(name, data)
end

function ManufacturingGroups:ModifyRow(name, data)
end

return ManufacturingGroups