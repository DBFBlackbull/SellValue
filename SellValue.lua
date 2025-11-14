-- global SellValues = itemid -> price

local _G = getfenv(0)
local function hooksecurefunc(arg1, arg2, arg3)
	if type(arg1) == "string" then
		arg1, arg2, arg3 = _G, arg1, arg2
	end
	local orig = arg1[arg2]
	arg1[arg2] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)
		local x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, x17, x18, x19, x20 = orig(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)

		arg3(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18, a19, a20)

		return x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, x17, x18, x19, x20
	end
end

function SellValue_SetTooltip(tooltip, itemLink, stackCount)
	local itemID = SellValue_IDFromLink(itemLink)
	if not itemID then
		return
	end

	stackCount = math.max(stackCount, 1)

	local price = SellValues[itemID];
	if price then
		if price == 0 then
			tooltip:AddLine(ITEM_UNSELLABLE, 1.0, 1.0, 1.0);
		else
			SetTooltipMoney(tooltip, price * stackCount);
		end

		-- Adjust width and height to account for new lines
		tooltip:Show()
	end
end

function SellValue_OnLoad()
	this:RegisterEvent("MERCHANT_SHOW");
	this:RegisterEvent("ADDON_LOADED");

	SellValue_Saved_OnTooltipAddMoney = SellValue_Tooltip:GetScript("OnTooltipAddMoney");

	SellValue_Tooltip:SetScript("OnTooltipAddMoney", SellValue_OnTooltipAddMoney);

	-- Hook item links tooltip
	hooksecurefunc("ChatFrame_OnHyperlinkShow", function(itemLink, text, button)
		SellValue_SetTooltip(ItemRefTooltip, itemLink, 1);
	end)

	-- Hook loot tooltip
	hooksecurefunc(GameTooltip, "SetLootItem", function(tip, lootIndex)
		local _, _, stackCount = GetLootSlotInfo(lootIndex);
		SellValue_SetTooltip(GameTooltip, GetLootSlotLink(lootIndex), stackCount);
	end)

	-- Hook group loot roll tooltip
	hooksecurefunc(GameTooltip, "SetLootRollItem", function(tip, lootIndex)
		local _, _, stackCount = GetLootRollItemInfo(lootIndex);
		SellValue_SetTooltip(GameTooltip, GetLootRollItemLink(lootIndex), stackCount);
	end)

	-- Hook bag tooltip
	hooksecurefunc(GameTooltip, "SetBagItem", function(tip, bag, slot)
		if not MerchantFrame:IsVisible() then
			local _, stackCount = GetContainerItemInfo(bag, slot);
			SellValue_SetTooltip(GameTooltip, GetContainerItemLink(bag, slot), stackCount);
		end
	end)

	-- Hook bank tooltip
	hooksecurefunc(GameTooltip, "SetInventoryItem", function(tip, unit, slot)
		if not MerchantFrame:IsVisible() and slot > 19 then
			local stackCount = GetInventoryItemCount(unit, slot);
			SellValue_SetTooltip(GameTooltip, GetInventoryItemLink("player", slot), stackCount);
		end
	end)

	-- Hook hyper links, used for BankItems and Bagnon_Forever addons
	hooksecurefunc(GameTooltip, "SetHyperlink", function(tip, itemLink, count)
		local stackCount = 1
		if type(count) == "number" then
			stackCount = count
		end

		SellValue_SetTooltip(GameTooltip, itemLink, stackCount);
	end)

	if AtlasLootTooltip then
		hooksecurefunc(AtlasLootTooltip, "SetHyperlink", function(tip, itemLink, count)
			local stackCount = 1
			if type(count) == "number" then
				stackCount = count
			end

			SellValue_SetTooltip(AtlasLootTooltip, itemLink, stackCount);
		end)
	end

	-- Hook quest reward tooltip
	hooksecurefunc(GameTooltip, "SetQuestItem", function(tip, qtype, slot)
		if qtype == "reward" or qtype == "choice" then
			local _, _, stackCount = GetQuestItemInfo(qtype, slot);
			SellValue_SetTooltip(GameTooltip, GetQuestItemLink(qtype, slot), stackCount)
		end
	end)

	-- Hook questlog reward tooltip
	hooksecurefunc(GameTooltip, "SetQuestLogItem", function(tip, qtype, slot)
		local stackCount;

		if qtype == "reward" then
			_, _, stackCount = GetQuestLogRewardInfo(slot);
		elseif qtype == "choice" then
			_, _, stackCount = GetQuestLogChoiceInfo(slot);
		else
			return
		end

		SellValue_SetTooltip(GameTooltip, GetQuestLogItemLink(qtype, slot), stackCount);
	end)

	-- Hook trade skill tooltip
	hooksecurefunc(GameTooltip, "SetTradeSkillItem", function(tip, tradeItemIndex, reagentIndex)
		local stackCount;
		local itemLink;

		if reagentIndex then
			_, _, stackCount = GetTradeSkillReagentInfo(tradeItemIndex, reagentIndex);
			itemLink = GetTradeSkillReagentItemLink(tradeItemIndex, reagentIndex);
		else
			stackCount = GetTradeSkillNumMade(tradeItemIndex);
			itemLink = GetTradeSkillItemLink(tradeItemIndex);
		end

		SellValue_SetTooltip(GameTooltip, itemLink, stackCount);
	end)

	-- Trade from Player
	hooksecurefunc(GameTooltip, "SetTradePlayerItem", function(tip, index)
		local _, _, stackCount = GetTradePlayerItemInfo(index)
		SellValue_SetTooltip(GameTooltip, GetTradePlayerItemLink(index), stackCount)
	end)

	-- Trade from Target
	hooksecurefunc(GameTooltip, "SetTradeTargetItem", function(tip, index)
		local _, _, stackCount = GetTradeTargetItemInfo(index)
		SellValue_SetTooltip(GameTooltip, GetTradeTargetItemLink(index), stackCount)
	end)
end

function SellValue_OnEvent()
	if event == "ADDON_LOADED" and arg1 == "SellValue" then
		return SellValue_InitializeDB();
	end

	if event == "MERCHANT_SHOW" then
		return SellValue_MerchantScan(this);
	end
end

SellValue_Saved_GameTooltip_OnEvent = GameTooltip_OnEvent;
GameTooltip_OnEvent = function()
	if event ~= "CLEAR_TOOLTIP" then
		return SellValue_Saved_GameTooltip_OnEvent();
	end
end

function SellValue_OnTooltipAddMoney ()
	-- call the original function first
	SellValue_Saved_OnTooltipAddMoney();

	-- The money in repair mode is the cost to repair, not sell
	if InRepairMode() then
		return
	end

	SellValue_LastItemMoney = arg1;
end

function SellValue_SaveFor(bag, slot, itemID, money)
	if not (bag and slot and itemID and money) then
		return
	end

	local _, stackCount = GetContainerItemInfo(bag, slot);
	if stackCount and stackCount > 0 then
		local costOfOne = money / stackCount;

		if not SellValues then
			SellValues = {}
		end

		SellValues[itemID] = costOfOne
	end
end

function SellValue_MerchantScan(frame)

	for bag = 0, NUM_BAG_FRAMES do
		for slot = 1, GetContainerNumSlots(bag) do

			local itemID = SellValue_IDFromLink(GetContainerItemLink(bag, slot))
			if itemID then
				SellValue_LastItemMoney = 0;
				SellValue_Tooltip:SetBagItem(bag, slot);
				SellValue_SaveFor(bag, slot, itemID, SellValue_LastItemMoney);
			end  -- if item name
		end  -- for slot
	end -- for bag

end

function SellValue_OnHide()
	-- ClearMoney() expects this to point to the tooltip itself, and this here
	-- points to us, a child of the tip
	this = this:GetParent();
	return GameTooltip_ClearMoney();
end

function SellValue_IDFromLink(itemLink)
	if not itemLink then
		return
	end

	local foundID, _, itemID = string.find(itemLink, "item:(%d+)");
	if not foundID then
		return
	end

	return tonumber(itemID)
end
