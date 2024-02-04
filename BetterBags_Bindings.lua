-- This will get a handle to the BetterBags addon.
---@class BetterBags: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon("BetterBags")

-- This will get a handle to the Categories module, which exposes
-- the API for creating categories.
---@class Categories: AceModule
local categories = addon:GetModule('Categories')

-- This will get a handle to the localization module, which should be
-- used for all text your users will see. For all category names,
-- you should use the L:G() function to get the localized string.
---@class Localization: AceModule
local L = addon:GetModule('Localization')

-- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoSharedDocumentation.lua
---@class BindingMap
---@type table<number, string>
local BINDING_MAP = {
    [Enum.TooltipDataItemBinding.Quest] = ITEM_BIND_QUEST,
    [Enum.TooltipDataItemBinding.Account] = ITEM_ACCOUNTBOUND,
    [Enum.TooltipDataItemBinding.BnetAccount] = ITEM_BNETACCOUNTBOUND, -- Obsolete
    [Enum.TooltipDataItemBinding.Soulbound] = ITEM_SOULBOUND,
    [Enum.TooltipDataItemBinding.BindToAccount] = ITEM_BIND_TO_ACCOUNT,
    [Enum.TooltipDataItemBinding.BindToBnetAccount] = ITEM_BIND_TO_BNETACCOUNT, -- Obsolete
    [Enum.TooltipDataItemBinding.BindOnPickup] = ITEM_BIND_ON_PICKUP,
    [Enum.TooltipDataItemBinding.BindOnEquip] = ITEM_BIND_ON_EQUIP,
    [Enum.TooltipDataItemBinding.BindOnUse] = ITEM_BIND_ON_USE,
  }

---@param TooltipData TooltipData
---@return boolean
function GetItemTradeTimerFromTooltipData(TooltipData)
    local matchString = string.format(BIND_TRADE_TIME_REMAINING, ".*")
    matchString = (string.gsub(matchString,"%(","%%%("))  -- remove magic chars "(" and ")"
    matchString = (string.gsub(matchString,"%)","%%%)"))  -- fingers crossed that this works for other locales

    for i = 2, 20 do  -- small assumption on where binding shows
      local line = TooltipData.lines[i]
      if (not line) then
        break
      end
      if line.type == Enum.TooltipDataLineType.None then
        if (string.find(line.leftText, matchString)) then
          return true
        end
      end
    end
    return false
end

---@param TooltipData TooltipData
---@return Enum.TooltipDataItemBinding|nil
function GetItemBindingFromTooltipData(TooltipData)
  return TooltipUtil.FindLinesFromData({Enum.TooltipDataLineType.ItemBinding},TooltipData)[1].bonding
end

categories:RegisterCategoryFunction("Zeptognome Binding function", function (data)
  local bindType = data.itemInfo.bindType
  if (bindType == Enum.ItemBind.OnAcquire) or (bindType == Enum.ItemBind.OnEquip) or (bindType == Enum.ItemBind.OnUse) then
    local TooltipData = C_TooltipInfo.GetItemByGUID(data.itemInfo.itemGUID)
    if not TooltipData then return nil end
    local tradable = GetItemTradeTimerFromTooltipData(TooltipData)
    if tradable then
      return "TimedBind"
    end
    local binding = GetItemBindingFromTooltipData(TooltipData)
    if binding then
      return BINDING_MAP[binding]
    end
  end
  return nil
end)
