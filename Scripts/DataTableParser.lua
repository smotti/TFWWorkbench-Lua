local Utils = require("utils")


local function Log(message, funcName)
    Utils.Log(message, "DataTableParser", funcName)
end

local function ToJson(value, kismetLib)
    -- That needs to be refactored, because this ToJson function will be pulled out into
    -- a dedicated modules for common parsing functionality
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

return {
    ToJson = ToJson
}