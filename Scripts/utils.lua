local function GetDataTableName(dataTable)
    if not (type(dataTable) == "string") then
        return string.match(
            string.match(dataTable:GetFullName(), "^DataTable%s+(.*)"),
            "%.(.+)$")
    else
        -- Handling the case where dataTable is a string path without the "DataTable" prefix
        local path = string.match(dataTable, "^DataTable%s+(.*)")
        if not path then
            return string.match(dataTable, "%.(.+)$")
        else
            return string.match(path, "%.(.+)$")
        end
    end
end

-- Parameter order
-- message
-- component
-- function
local function Log(...)
    local args = { ... }
    local n = select('#', ...)

    if n == 0 then
        return
        -- Only `message` was provided
    elseif n == 1 then
        print(string.format("[TFWWorkbench] %s\n", args[1]))
        -- `message` and `component`
    elseif n == 2 then
        print(string.format("[TFWWorkbench:%s] %s\n", args[2], args[1]))
        -- `message`, `component` and `function`
    elseif n == 3 then
        print(string.format("[TFWWorkbench:%s:%s] %s\n", args[2], args[3], args[1]))
    end
end

local function PrintTable(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. PrintTable(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

return {
    GetDataTableName = GetDataTableName,
    Log = Log,
    PrintTable = PrintTable
}
