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
    ManufacturingRecipes = "/Game/FW/UI/Manufactoring/Data/DT_ManufactoringRecipies.DT_ManufactoringRecipies",
    TagToRowHandle = "/Game/Blueprints/Data/DataReference/DT_TagToRowHandle.DT_TagToRowHandle",
    ManufacturingRecipes = "/Game/FW/UI/Manufactoring/Data/DT_ManufactoringRecipies.DT_ManufactoringRecipies"
}
Settings.ValueTables = {
    "/Game/Blueprints/Data/Value/LEGACY_ItemValueOverrideData.LEGACY_ItemValueOverrideData",
    "/Game/Blueprints/Data/Value/ValueV2_AMMO.ValueV2_AMMO",
    "/Game/Blueprints/Data/Value/ValueV2_Ingredients.ValueV2_Ingredients",
    "/Game/Blueprints/Data/Value/ValueV2_Junk.ValueV2_Junk",
    "/Game/Blueprints/Data/Value/ValueV2_RareLoot.ValueV2_RareLoot",
    "/Game/Blueprints/Data/Value/ValueV2_RIGEQUIPMENT.ValueV2_RIGEQUIPMENT",
    "/Game/Blueprints/Data/Value/ValueV2_RIGS.ValueV2_RIGS",
    "/Game/Blueprints/Data/Value/ValueV2_WEAPONS_DROPPED.ValueV2_WEAPONS_DROPPED",
    "/Game/Blueprints/Data/Value/ValueV2_WEAPONS_PARTS.ValueV2_WEAPONS_PARTS",
    "/Game/Blueprints/Data/Value/ValueV2_WEAPONS.ValueV2_WEAPONS"
}

return Settings
