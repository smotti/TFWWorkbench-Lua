--- Global settings and configuration for TFWData mod
--- This module provides centralized configuration for debug flags and data table paths

local Settings = {}

-- Debug configuration flags
Settings.DEBUG = true
Settings.DEBUG_PRINT_ALL = false
Settings.DEBUG_PRINT_ROWNAMES = false
Settings.DEBUG_PRINT_ROWS = true

-- Data table class names/paths
Settings.DataTableClassNames = {
    ItemDetailsData = "/Game/Blueprints/Data/ItemDetailsData.ItemDetailsData",
    ItemGameplayTags = "/Game/Blueprints/Data/ItemGameplayTags.ItemGameplayTags",
    ItemTags = "/Game/Blueprints/Data/DataReference/DT_ItemTags.DT_ItemTags",
    TagToRowHandle = "/Game/Blueprints/Data/DataReference/DT_TagToRowHandle.DT_TagToRowHandle"
}

return Settings
