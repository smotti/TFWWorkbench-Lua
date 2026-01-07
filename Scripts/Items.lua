--[[
A module that manages the concept of an in-game item. Meaning it adds it to
the `ItemDetailsData` data table. As well as `DT_ItemTags` and `DT_TagToRowHandle`.
In order to make the item available to other game systems. Like Vendors and Crafting.
]]
local json = require("json")
local Utils = require("utils")


local function MakeItemTag(itemRowName, itemData)
    local parentTag = itemData["ItemSubtype"]["ParentTags"][1]["TagName"]
    return string.format("Inventory.%s.%s", parentTag, itemRowName)
end

local function Add()
end

local function AddItems(items, itemDetailsDataHandler, itemTagsHandler)
    for _, item in ipairs(items) do
        Utils.Log(string.format("Adding item: %s\n", item["Name"]), "Items", "AddItems")
        itemDetailsDataHandler.AddRow(item["Name"], item["Data"])

        local itemTag = MakeItemTag(item["Name"], item["Data"])
        itemTagsHandler.AddRow(itemTag)
    end
end

return {
    Add = Add,
    AddItems = AddItems
}