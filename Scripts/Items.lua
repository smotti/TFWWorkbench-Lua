--[[
A module that manages the concept of an in-game item. Meaning it adds it to
the `ItemDetailsData` data table. As well as `DT_ItemTags` and `DT_TagToRowHandle`.
In order to make the item available to other game systems. Like Vendors and Crafting.
]]
local json = require("json")
local Utils = require("utils")

local function Add()
end

local function AddItems(items, itemDetailsDataHandler)
    for _, item in ipairs(items) do
        Utils.Log(string.format("Adding item: %s\n", item["Name"]), "Items", "AddItems")
        itemDetailsDataHandler.AddRow(item["Name"], item["Data"])
    end
end

return {
    Add = Add,
    AddItems = AddItems
}