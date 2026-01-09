local DataTable = require("DataTable")
local Parser = require("DataTableParser")
local Utils = require("utils")


local function Log(message, funcName)
    Utils.Log(message, "ManufacturingRecipes", funcName)
end

local ManufacturingRecipes = setmetatable({}, {__index = DataTable})
ManufacturingRecipes.__index = ManufacturingRecipes

function ManufacturingRecipes.new(dataTable)
    local self = DataTable.new(dataTable)
    setmetatable(self, ManufacturingRecipes)
    return self
end

---@param data FManufactoringRecipies
function ManufacturingRecipes:ParseRowData(data)
    local lib = self.__kismetlib
    return {
        UsedComponents = Parser.ToJson(data.UsedComponents, lib),
        CreatedItems = Parser.ToJson(data.CreatedItems, lib),
        RecipyName = Parser.ToJson(data.RecipyName, lib),
        RecipyTag = Parser.ToJson(data.RecipyTag, lib),
        RecipyGroupTag = Parser.ToJson(data.RecipyGroupTag, lib),
        RequiredTags = Parser.ToJson(data.RequiredTags, lib),
        RecipyCraftTime = Parser.ToJson(data.RecipyCraftTime, lib)
    }
end

return ManufacturingRecipes