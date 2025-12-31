local json = require("json")
local Settings = require("Settings")
local ItemDetailsDataHandler = require("ItemDetailsData")

---@class UDataTable
local ItemDetailsData

RegisterConsoleCommandHandler("DumpDataTables", function(fullCmd, params, outputDevice)
    print("[TFWWorkbench] Handle console command 'DumpDataTables'\n")
    print(string.format("[TFWWorkbench] Full command: %s\n", fullCmd))

    outputDevice:Log("Dumping data tables")
    
    ItemDetailsData = StaticFindObject(Settings.DataTableClassNames.ItemDetailsData)
    if ItemDetailsData and ItemDetailsData:IsValid() then
        ItemDetailsDataHandler.Init(ItemDetailsData)
        ItemDetailsDataHandler.DumpDataTable()

        return true
    end

    return false
end)