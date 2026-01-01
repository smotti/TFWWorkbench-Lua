-- Parameter order
-- message
-- component
-- function
local function Log(...)
    local args = {...}
    local n = select('#', ...)

    if n == 0 then
        return
    elseif n == 1 then
        print(string.format("[TFWWorkbench] %s\n", args[1]))
    elseif n == 2 then
        print(string.format("[TFWWorkbench:%s] %s\n", args[2], args[1]))
    elseif n == 3 then
        print(string.format("[TFWWorkbench:%s:%s] %s\n", args[2], args[3], args[1]))
    end
end

return {
    Log = Log
}