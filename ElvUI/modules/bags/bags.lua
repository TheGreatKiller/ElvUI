﻿local E, L, V, P, G = unpack(select(2, ...)); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local B = E:NewModule('Bags', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0');

local len, sub, find, format, floor, lower = string.len, string.sub, string.find, string.format, math.floor, string.lower
local tinsert = table.insert

B.ProfessionColors = {
	[0x0008] = {224/255, 187/255, 74/255}, -- Leatherworking
	[0x0010] = {74/255, 77/255, 224/255}, -- Inscription
	[0x0020] = {18/255, 181/255, 32/255}, -- Herbs
	[0x0040] = {160/255, 3/255, 168/255}, -- Enchanting
	[0x0080] = {232/255, 118/255, 46/255}, -- Engineering
	[0x0200] = {8/255, 180/255, 207/255}, -- Gems
	[0x0400] = {105/255, 79/255,  7/255}, -- Mining
	[0x010000] = {222/255, 13/255,  65/255} -- Cooking
}

function B:GetContainerFrame(arg)
	if type(arg) == 'boolean' and arg == true then
		return self.BankFrame;
	elseif type(arg) == 'number' then
		if self.BankFrame then
			for _, bagID in ipairs(self.BankFrame.BagIDs) do
				if bagID == arg then
					return self.BankFrame;
				end
			end
		end
	end
	
	return self.BagFrame;
end

function B:Tooltip_Show()
	GameTooltip:SetOwner(self);
	GameTooltip:ClearLines();
	GameTooltip:AddLine(self.ttText);
	
	if(self.ttText2) then
		GameTooltip:AddLine(' ');
		GameTooltip:AddDoubleLine(self.ttText2, self.ttText2desc, 1, 1, 1);
	end
	
	GameTooltip:Show();
end

function B:Tooltip_Hide()
	GameTooltip:Hide();
end

function B:DisableBlizzard()
	BankFrame:UnregisterAllEvents();
	
	for i=1, NUM_CONTAINER_FRAMES do
		_G['ContainerFrame'..i]:Kill();
	end
end

function B:SearchReset()
	for _, bagFrame in pairs(self.BagFrames) do
		for _, bagID in ipairs(bagFrame.BagIDs) do
			for slotID = 1, GetContainerNumSlots(bagID) do
				local button = bagFrame.Bags[bagID][slotID];
				SetItemButtonDesaturated(button, 0, 1, 1, 1);
				button:SetAlpha(1);
			end
		end
	end
end

function B:UpdateSearch(str)
	str = lower(str)
	for _, bagFrame in pairs(self.BagFrames) do
		for _, bagID in ipairs(bagFrame.BagIDs) do
			for slotID = 1, GetContainerNumSlots(bagID) do
				local button = bagFrame.Bags[bagID][slotID];
				if button.name then
					if not find(lower(button.name), str) then
						SetItemButtonDesaturated(button, 1, 1, 1, 1);
						button:SetAlpha(0.4);
					else
						SetItemButtonDesaturated(button, 0, 1, 1, 1);
						button:SetAlpha(1);
					end
				end
			end
		end	
	end
end

function B:OpenEditbox()
	self.BagFrame.detail:Hide();
	self.BagFrame.editBox:Show();
	self.BagFrame.editBox:SetText(SEARCH);
	self.BagFrame.editBox:HighlightText();
end

function B:ResetAndClear()
	self:GetParent().editBox:SetText(SEARCH);
	
	self:ClearFocus();
	B:SearchReset();
end

function B:UpdateSlot(bagID, slotID)
	if (self.Bags[bagID] and self.Bags[bagID].numSlots ~= GetContainerNumSlots(bagID)) or not self.Bags[bagID] or not self.Bags[bagID][slotID] then		
		return; 
	end

	local slot, _ = self.Bags[bagID][slotID], nil;
	local bagType = self.Bags[bagID].type;
	local texture, count, locked = GetContainerItemInfo(bagID, slotID);
	local clink = GetContainerItemLink(bagID, slotID);
	local specialType = select(2, GetContainerNumFreeSlots(bagID))
	
	slot:Show();
	slot.name, slot.rarity = nil, nil;
	
	local start, duration, enable = GetContainerItemCooldown(bagID, slotID)
	CooldownFrame_SetTimer(slot.cooldown, start, duration, enable)
	if ( duration > 0 and enable == 0 ) then
		SetItemButtonTextureVertexColor(slot, 0.4, 0.4, 0.4);
	else
		SetItemButtonTextureVertexColor(slot, 1, 1, 1);
	end				
	
	if B.ProfessionColors[bagType] then
		slot:SetBackdropBorderColor(unpack(B.ProfessionColors[bagType]))
	elseif (clink) then
		local iType;
		slot.name, _, slot.rarity, _, _, iType = GetItemInfo(clink);
		
		local isQuestItem, questId, isActiveQuest = GetContainerItemQuestInfo(bagID, slotID);
	
		-- color slot according to item quality
		if questId and not isActive then
			slot:SetBackdropBorderColor(1.0, 0.3, 0.3);
		elseif questId or isQuestItem then
			slot:SetBackdropBorderColor(1.0, 0.3, 0.3);
		elseif slot.rarity and slot.rarity > 1 then
			local r, g, b = GetItemQualityColor(slot.rarity);
			slot:SetBackdropBorderColor(r, g, b);
		else
			slot:SetBackdropBorderColor(unpack(E.media.bordercolor));
		end
	else
		slot:SetBackdropBorderColor(unpack(E.media.bordercolor));
	end
	
	SetItemButtonTexture(slot, texture);
	SetItemButtonCount(slot, count);
	SetItemButtonDesaturated(slot, locked, 0.5, 0.5, 0.5);	
end

function B:UpdateBagSlots(bagID)
	for slotID = 1, GetContainerNumSlots(bagID) do
		if self.UpdateSlot then
			self:UpdateSlot(bagID, slotID);	
		else
			self:GetParent():UpdateSlot(bagID, slotID);
		end
	end
end

function B:UpdateCooldowns()
	for _, bagID in ipairs(self.BagIDs) do
		for slotID = 1, GetContainerNumSlots(bagID) do
			local start, duration, enable = GetContainerItemCooldown(bagID, slotID)
			CooldownFrame_SetTimer(self.Bags[bagID][slotID].cooldown, start, duration, enable)
			if ( duration > 0 and enable == 0 ) then
				SetItemButtonTextureVertexColor(self.Bags[bagID][slotID], 0.4, 0.4, 0.4);
			else
				SetItemButtonTextureVertexColor(self.Bags[bagID][slotID], 1, 1, 1);
			end					
		end
	end
end

function B:UpdateAllSlots()
	for _, bagID in ipairs(self.BagIDs) do
		if self.Bags[bagID] then
			self.Bags[bagID]:UpdateBagSlots(bagID);
		end
	end
end

function B:SetSlotAlphaForBag(f)
	for _, bagID in ipairs(f.BagIDs) do
		if f.Bags[bagID] then
			local numSlots = GetContainerNumSlots(bagID);
			for slotID = 1, numSlots do
				if f.Bags[bagID][slotID] then
					if bagID == self.id then
						f.Bags[bagID][slotID]:SetAlpha(1)
					else
						f.Bags[bagID][slotID]:SetAlpha(0.1)
					end
				end
			end
		end
	end
end

function B:ResetSlotAlphaForBags(f)
	for _, bagID in ipairs(f.BagIDs) do
		if f.Bags[bagID] then
			local numSlots = GetContainerNumSlots(bagID);
			for slotID = 1, numSlots do
				if f.Bags[bagID][slotID] then
					f.Bags[bagID][slotID]:SetAlpha(1)
				end
			end
		end
	end
end

function B:Layout(isBank)
	if E.private.bags.enable ~= true then return; end
	local f = self:GetContainerFrame(isBank);
	
	if not f then return; end
	local buttonSize = isBank and self.db.bankSize or self.db.bagSize;
	local buttonSpacing = E.PixelMode and 2 or 4;
	local containerWidth = self.db.alignToChat == true and (E.db.chat.panelWidth - (E.PixelMode and 6 or 10)) or isBank and self.db.bankWidth or self.db.bagWidth
	local numContainerColumns = floor(containerWidth / (buttonSize + buttonSpacing));
	local holderWidth = ((buttonSize + buttonSpacing) * numContainerColumns) - buttonSpacing;
	local numContainerRows = 0;
	local bottomPadding = (containerWidth - holderWidth) / 2;
	f.holderFrame:Width(holderWidth);
	
	f.totalSlots = 0
	local lastButton;
	local lastRowButton;
	local lastContainerButton;
	local numContainerSlots, fullContainerSlots = GetNumBankSlots();
	for i, bagID in ipairs(f.BagIDs) do
		--Bag Containers
		if (not isBank and bagID <= 3 ) or (isBank and bagID ~= -1 and numContainerSlots >= 1 and not (i - 1 > numContainerSlots)) then
			if not f.ContainerHolder[i] then
				if isBank then
					f.ContainerHolder[i] = CreateFrame("CheckButton", "ElvUIBankBag" .. bagID - 4, f.ContainerHolder, "BankItemButtonBagTemplate")
				else
					f.ContainerHolder[i] = CreateFrame("CheckButton", "ElvUIMainBag" .. bagID .. "Slot", f.ContainerHolder, "BagSlotButtonTemplate")
				end
					
				f.ContainerHolder[i]:CreateBackdrop('Default', true)
				f.ContainerHolder[i].backdrop:SetAllPoints();
				f.ContainerHolder[i]:StyleButton()
				f.ContainerHolder[i]:SetNormalTexture("")
				f.ContainerHolder[i]:SetCheckedTexture(nil)
				f.ContainerHolder[i]:SetPushedTexture("")
				f.ContainerHolder[i]:SetScript('OnClick', nil)
				f.ContainerHolder[i].id = isBank and bagID or bagID + 1
				f.ContainerHolder[i]:HookScript("OnEnter", function(self) B.SetSlotAlphaForBag(self, f) end)
				f.ContainerHolder[i]:HookScript("OnLeave", function(self) B.ResetSlotAlphaForBags(self, f) end)

				
				if isBank then
					f.ContainerHolder[i]:SetID(bagID)
					if not f.ContainerHolder[i].tooltipText then
						f.ContainerHolder[i].tooltipText = ""
					end			
				end
				
				f.ContainerHolder[i].iconTexture = _G[f.ContainerHolder[i]:GetName()..'IconTexture'];
				f.ContainerHolder[i].iconTexture:SetInside()
				f.ContainerHolder[i].iconTexture:SetTexCoord(unpack(E.TexCoords))
			end
			
			f.ContainerHolder:Size(((buttonSize + buttonSpacing) * (isBank and i - 1 or i)) + buttonSpacing,buttonSize + (buttonSpacing * 2))
			
			if isBank then
				BankFrameItemButton_Update(f.ContainerHolder[i])
				BankFrameItemButton_UpdateLocked(f.ContainerHolder[i])					
			end
			
			f.ContainerHolder[i]:Size(buttonSize)
			f.ContainerHolder[i]:ClearAllPoints()
			if (isBank and i == 2) or (not isBank and i == 1) then
				f.ContainerHolder[i]:SetPoint('BOTTOMLEFT', f.ContainerHolder, 'BOTTOMLEFT', buttonSpacing, buttonSpacing)
			else
				f.ContainerHolder[i]:SetPoint('LEFT', lastContainerButton, 'RIGHT', buttonSpacing, 0)
			end
			
			lastContainerButton = f.ContainerHolder[i];	
		end
		
		--Bag Slots
		local numSlots = GetContainerNumSlots(bagID);
		if numSlots > 0 then
			if not f.Bags[bagID] then
				f.Bags[bagID] = CreateFrame('Frame', f:GetName()..'Bag'..bagID, f);
				f.Bags[bagID]:SetID(bagID);
				f.Bags[bagID].UpdateBagSlots = B.UpdateBagSlots;
				f.Bags[bagID].UpdateSlot = UpdateSlot;
			end
			
			f.Bags[bagID].numSlots = numSlots;
			f.Bags[bagID].type = select(2, GetContainerNumFreeSlots(bagID));
			
			--Hide unused slots
			for i = 1, MAX_CONTAINER_ITEMS do
				if f.Bags[bagID][i] then
					f.Bags[bagID][i]:Hide();
				end
			end			
			
			for slotID = 1, numSlots do
				f.totalSlots = f.totalSlots + 1;
				if not f.Bags[bagID][slotID] then
					f.Bags[bagID][slotID] = CreateFrame('CheckButton', f.Bags[bagID]:GetName()..'Slot'..slotID, f.Bags[bagID], bagID == -1 and 'BankItemButtonGenericTemplate' or 'ContainerFrameItemButtonTemplate');
					f.Bags[bagID][slotID]:StyleButton();
					f.Bags[bagID][slotID]:SetTemplate('Default', true);
					f.Bags[bagID][slotID]:SetNormalTexture(nil);
					f.Bags[bagID][slotID]:SetCheckedTexture(nil);
					
					f.Bags[bagID][slotID].iconTexture = _G[f.Bags[bagID][slotID]:GetName()..'IconTexture'];
					f.Bags[bagID][slotID].iconTexture:SetInside(f.Bags[bagID][slotID]);
					f.Bags[bagID][slotID].iconTexture:SetTexCoord(unpack(E.TexCoords));
					
					f.Bags[bagID][slotID].cooldown = _G[f.Bags[bagID][slotID]:GetName()..'Cooldown'];
					E:RegisterCooldown(f.Bags[bagID][slotID].cooldown)
					f.Bags[bagID][slotID].bagID = bagID
					f.Bags[bagID][slotID].slotID = slotID
				end
				
				f.Bags[bagID][slotID]:SetID(slotID);
				f.Bags[bagID][slotID]:Size(buttonSize);

				f:UpdateSlot(bagID, slotID);
				
				if f.Bags[bagID][slotID]:GetPoint() then
					f.Bags[bagID][slotID]:ClearAllPoints();
				end
				
				if lastButton then
					if (f.totalSlots - 1) % numContainerColumns == 0 then
						f.Bags[bagID][slotID]:Point('TOP', lastRowButton, 'BOTTOM', 0, -buttonSpacing);
						lastRowButton = f.Bags[bagID][slotID];
						numContainerRows = numContainerRows + 1;
					else
						f.Bags[bagID][slotID]:Point('LEFT', lastButton, 'RIGHT', buttonSpacing, 0);
					end
				else
					f.Bags[bagID][slotID]:Point('TOPLEFT', f.holderFrame, 'TOPLEFT');
					lastRowButton = f.Bags[bagID][slotID];
					numContainerRows = numContainerRows + 1;
				end
				
				lastButton = f.Bags[bagID][slotID];
			end		
		else
			--Hide unused slots
			for i = 1, MAX_CONTAINER_ITEMS do
				if f.Bags[bagID] and f.Bags[bagID][i] then
					f.Bags[bagID][i]:Hide();
				end
			end		
			
			if f.Bags[bagID] then
				f.Bags[bagID].numSlots = numSlots;
			end
			
			if self.isBank then
				if self.ContainerHolder[i] then
					BankFrameItemButton_Update(self.ContainerHolder[i])
					BankFrameItemButton_UpdateLocked(self.ContainerHolder[i])
				end
			end					
		end
	end

	f:Size(containerWidth, (((buttonSize + buttonSpacing) * numContainerRows) - buttonSpacing) + f.topOffset + f.bottomOffset); -- 8 is the cussion of the f.holderFrame
end

function B:UpdateAll()
	if self.BagFrame then
		self:Layout();
	end
	
	if self.BankFrame then
		self:Layout(true);
	end
end

function B:OnEvent(event, ...)
	if event == 'ITEM_LOCK_CHANGED' or event == 'ITEM_UNLOCKED' then
		self:UpdateSlot(...);
	elseif event == 'BAG_UPDATE' then
		for _, bagID in ipairs(self.BagIDs) do
			local numSlots = GetContainerNumSlots(bagID)
			if (not self.Bags[bagID] and numSlots ~= 0) or (self.Bags[bagID] and numSlots ~= self.Bags[bagID].numSlots) then
				B:Layout(self.isBank);
				return;
			end
		end
		
		self:UpdateBagSlots(...);
	elseif event == 'BAG_UPDATE_COOLDOWN' then
		self:UpdateCooldowns();
	elseif event == 'PLAYERBANKSLOTS_CHANGED' then
		self:UpdateAllSlots()
	end
end

function B:UpdateTokens()
	local f = self.BagFrame;
	
	local numTokens = 0
	for i = 1, MAX_WATCHED_TOKENS do
		local name, count, type, icon = GetBackpackCurrencyInfo(i)
		local button = f.currencyButton[i];
		
		if(type == 1) then
			icon = 'Interface\\PVPFrame\\PVP-ArenaPoints-Icon';
		elseif(type == 2) then
			icon = 'Interface\\PVPFrame\\PVP-Currency-'..UnitFactionGroup('player');
		end
		
		button:ClearAllPoints();
		if name then
			button.icon:SetTexture(icon);
			
			if self.db.currencyFormat == 'ICON_TEXT' then
				button.text:SetText(name..': '..count);
			elseif self.db.currencyFormat == 'ICON' then
				button.text:SetText(count);
			end
			
			button.currencyID = currencyID;
			button:Show();
			numTokens = numTokens + 1;
		else
			button:Hide();
		end
	end
	
	if numTokens == 0 then
		f.bottomOffset = 8;
		
		if f.currencyButton:IsShown() then
			f.currencyButton:Hide();
			self:Layout();
		end
		
		return;
	elseif not f.currencyButton:IsShown() then
		f.bottomOffset = 28;
		f.currencyButton:Show();
		self:Layout();
	end

	f.bottomOffset = 28;
	if numTokens == 1 then
		f.currencyButton[1]:Point('BOTTOM', f.currencyButton, 'BOTTOM', -(f.currencyButton[1].text:GetWidth() / 2), 3);
	elseif numTokens == 2 then
		f.currencyButton[1]:Point('BOTTOM', f.currencyButton, 'BOTTOM', -(f.currencyButton[1].text:GetWidth()) - (f.currencyButton[1]:GetWidth() / 2), 3);
		f.currencyButton[2]:Point('BOTTOMLEFT', f.currencyButton, 'BOTTOM', f.currencyButton[2]:GetWidth() / 2, 3);
	else
		f.currencyButton[1]:Point('BOTTOMLEFT', f.currencyButton, 'BOTTOMLEFT', 3, 3);
		f.currencyButton[2]:Point('BOTTOM', f.currencyButton, 'BOTTOM', -(f.currencyButton[2].text:GetWidth() / 3), 3);	
		f.currencyButton[3]:Point('BOTTOMRIGHT', f.currencyButton, 'BOTTOMRIGHT', -(f.currencyButton[3].text:GetWidth()) - (f.currencyButton[3]:GetWidth() / 2), 3);
	end
end

function B:Token_OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetBackpackToken(self:GetID());
end

function B:Token_OnClick()
	if ( IsModifiedClick("CHATLINK") ) then
		HandleModifiedItemClick(GetCurrencyLink(self.currencyID));
	end
end

function B:UpdateGoldText()
	self.BagFrame.goldText:SetText(GetCoinTextureString(GetMoney(), 12))
end

function B:GetGraysValue()
	local c = 0;
	
	for b = 0, 4 do
		for s = 1, GetContainerNumSlots(b) do
			local l = GetContainerItemLink(b, s);
			if(l and select(11, GetItemInfo(l))) then
				local p = select(11, GetItemInfo(l)) * select(2, GetContainerItemInfo(b, s));
				if(select(3, GetItemInfo(l)) == 0 and p > 0) then
					c = c + p;
				end
			end
		end
	end
	
	return c;
end

function B:VendorGrays(delete, nomsg, getValue)
	if (not MerchantFrame or not MerchantFrame:IsShown()) and not delete and not getValue then
		E:Print(L['You must be at a vendor.'])
		return
	end

	local c = 0
	local count = 0
	for b=0,4 do
		for s=1,GetContainerNumSlots(b) do
			local l = GetContainerItemLink(b, s)
			if l and select(11, GetItemInfo(l)) then
				local p = select(11, GetItemInfo(l))*select(2, GetContainerItemInfo(b, s))
				
				if delete then
					if find(l,"ff9d9d9d") then
						if not getValue then
							PickupContainerItem(b, s)
							DeleteCursorItem()
						end
						c = c+p
						count = count + 1
					end
				else
					if select(3, GetItemInfo(l))==0 and p>0 then
						if not getValue then
							UseContainerItem(b, s)
							PickupMerchantItem()
						end
						c = c+p
					end
				end
			end
		end
	end
	
	if getValue then
		return c
	end

	if c>0 and not delete then
		local g, s, c = floor(c/10000) or 0, floor((c%10000)/100) or 0, c%100
		E:Print(L['Vendored gray items for:'].." |cffffffff"..g..L.goldabbrev.." |cffffffff"..s..L.silverabbrev.." |cffffffff"..c..L.copperabbrev..".")
	end
end

function B:VendorGrayCheck()
	local value = B:GetGraysValue();
	
	if(value == 0) then
		E:Print(L['No gray items to delete.']);
	elseif(not MerchantFrame or not MerchantFrame:IsShown()) then
		E.PopupDialogs['DELETE_GRAYS'].Money = value;
		E:StaticPopup_Show('DELETE_GRAYS');
	else
		B:VendorGrays();
	end
end

function B:ContructContainerFrame(name, isBank)
	local f = CreateFrame('Button', name, E.UIParent);
	f:SetTemplate('Transparent');
	f:SetFrameStrata('DIALOG');
	f.UpdateSlot = B.UpdateSlot;
	f.UpdateAllSlots = B.UpdateAllSlots;
	f.UpdateBagSlots = B.UpdateBagSlots;
	f.UpdateCooldowns = B.UpdateCooldowns;
	f:RegisterEvent('ITEM_LOCK_CHANGED');
	f:RegisterEvent('ITEM_UNLOCKED');	
	f:RegisterEvent('BAG_UPDATE_COOLDOWN')
	f:RegisterEvent('BAG_UPDATE');
	f:RegisterEvent('PLAYERBANKSLOTS_CHANGED');
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton", "RightButton")
	f:RegisterForClicks("AnyUp");
	f:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartMoving() end end)
	f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	f:SetScript("OnClick", function(self) if IsControlKeyDown() then B:PositionBagFrames() end end)
	f:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 4)
		GameTooltip:ClearLines()
		GameTooltip:AddDoubleLine(L['Hold Shift + Drag:'], L['Temporary Move'], 1, 1, 1)
		GameTooltip:AddDoubleLine(L['Hold Control + Right Click:'], L['Reset Position'], 1, 1, 1)
		
		GameTooltip:Show()	
	end)
	f:SetScript('OnLeave', function(self) GameTooltip:Hide() end)
	f.isBank = isBank
	
	f:SetScript('OnEvent', B.OnEvent);	
	f:Hide();
	
	f.bottomOffset = isBank and 8 or 28;
	f.topOffset = isBank and 45 or 50;
	f.BagIDs = isBank and {-1, 5, 6, 7, 8, 9, 10, 11} or {0, 1, 2, 3, 4};
	f.Bags = {};
	
	f.closeButton = CreateFrame('Button', name..'CloseButton', f, 'UIPanelCloseButton');
	f.closeButton:Point('TOPRIGHT', -4, -4);

	E:GetModule('Skins'):HandleCloseButton(f.closeButton);
	
	f.holderFrame = CreateFrame('Frame', nil, f);
	f.holderFrame:Point('TOP', f, 'TOP', 0, -f.topOffset);
	f.holderFrame:Point('BOTTOM', f, 'BOTTOM', 0, 8);
	
	f.ContainerHolder = CreateFrame('Button', name..'ContainerHolder', f)
	f.ContainerHolder:Point('BOTTOMLEFT', f, 'TOPLEFT', 0, 1)
	f.ContainerHolder:SetTemplate('Transparent')
	f.ContainerHolder:Hide()
	
	if(isBank) then
		f.bagText = f:CreateFontString(nil, 'OVERLAY');
		f.bagText:FontTemplate();
		f.bagText:Point('BOTTOMRIGHT', f.holderFrame, 'TOPRIGHT', -2, 4);
		f.bagText:SetJustifyH('RIGHT');
		f.bagText:SetText(L['Bank']);
		
		f.sortButton = CreateFrame('Button', name..'SortButton', f);
		f.sortButton:SetSize(16 + E.Border, 16 + E.Border);
		f.sortButton:SetTemplate();
		f.sortButton:SetPoint('RIGHT', f.bagText, 'LEFT', -5, E.Border * 2);
		f.sortButton:SetNormalTexture('Interface\\ICONS\\INV_Pet_RatCage');
		f.sortButton:GetNormalTexture():SetTexCoord(unpack(E.TexCoords));
		f.sortButton:GetNormalTexture():SetInside();
		f.sortButton:SetPushedTexture('Interface\\ICONS\\INV_Pet_RatCage');
		f.sortButton:GetPushedTexture():SetTexCoord(unpack(E.TexCoords));
		f.sortButton:GetPushedTexture():SetInside()		;
		f.sortButton:StyleButton(nil, true);
		f.sortButton.ttText = L['Sort Bags'];
		f.sortButton:SetScript('OnEnter', self.Tooltip_Show);
		f.sortButton:SetScript('OnLeave', self.Tooltip_Hide);
		f.sortButton:SetScript('OnClick', function() B:CommandDecorator(B.SortBags, 'bank')(); end);
		
		f.bagsButton = CreateFrame('Button', name..'BagsButton', f.holderFrame);
		f.bagsButton:SetSize(16 + E.Border, 16 + E.Border);
		f.bagsButton:SetTemplate();
		f.bagsButton:SetPoint('RIGHT', f.sortButton, 'LEFT', -5, 0);
		f.bagsButton:SetNormalTexture('Interface\\Buttons\\Button-Backpack-Up');
		f.bagsButton:GetNormalTexture():SetTexCoord(unpack(E.TexCoords));
		f.bagsButton:GetNormalTexture():SetInside();
		f.bagsButton:SetPushedTexture('Interface\\Buttons\\Button-Backpack-Up');
		f.bagsButton:GetPushedTexture():SetTexCoord(unpack(E.TexCoords));
		f.bagsButton:GetPushedTexture():SetInside();
		f.bagsButton:StyleButton(nil, true);
		f.bagsButton.ttText = L['Toggle Bags'];
		f.bagsButton:SetScript('OnEnter', self.Tooltip_Show);
		f.bagsButton:SetScript('OnLeave', self.Tooltip_Hide);
		f.bagsButton:SetScript('OnClick', function()
			local numSlots, full = GetNumBankSlots();
			PlaySound('igMainMenuOption');
			if(numSlots >= 1) then
				ToggleFrame(f.ContainerHolder)
			else
				E:StaticPopup_Show('NO_BANK_BAGS');
			end
		end);
		
		f.purchaseBagButton = CreateFrame('Button', nil, f.holderFrame);
		f.purchaseBagButton:SetSize(16 + E.Border, 16 + E.Border);
		f.purchaseBagButton:SetTemplate();
		f.purchaseBagButton:SetPoint('RIGHT', f.bagsButton, 'LEFT', -5, 0);
		f.purchaseBagButton:SetNormalTexture('Interface\\ICONS\\INV_Misc_Coin_01');
		f.purchaseBagButton:GetNormalTexture():SetTexCoord(unpack(E.TexCoords));
		f.purchaseBagButton:GetNormalTexture():SetInside();
		f.purchaseBagButton:SetPushedTexture('Interface\\ICONS\\INV_Misc_Coin_01');
		f.purchaseBagButton:GetPushedTexture():SetTexCoord(unpack(E.TexCoords));
		f.purchaseBagButton:GetPushedTexture():SetInside();
		f.purchaseBagButton:StyleButton(nil, true);
		f.purchaseBagButton.ttText = L['Purchase Bags'];
		f.purchaseBagButton:SetScript('OnEnter', self.Tooltip_Show);
		f.purchaseBagButton:SetScript('OnLeave', self.Tooltip_Hide);
		f.purchaseBagButton:SetScript('OnClick', function()
			local _, full = GetNumBankSlots();
			if(full) then
				E:StaticPopup_Show('CANNOT_BUY_BANK_SLOT');
			else
				E:StaticPopup_Show('BUY_BANK_SLOT');
			end
		end);
		
		f:SetScript('OnHide', CloseBankFrame);
		
		f.editBox = CreateFrame('EditBox', name..'EditBox', f);
		f.editBox:SetFrameLevel(f.editBox:GetFrameLevel() + 2);
		f.editBox:CreateBackdrop('Default');
		f.editBox.backdrop:SetPoint('TOPLEFT', f.editBox, 'TOPLEFT', -20, 2);
		f.editBox:Height(15);
		f.editBox:Point('BOTTOMLEFT', f.holderFrame, 'TOPLEFT', (E.Border * 2) + 18, E.Border * 2 + 2);
		f.editBox:Point('RIGHT', f.purchaseBagButton, 'LEFT', -5, 0);
		f.editBox:SetAutoFocus(false);
		f.editBox:SetScript('OnEscapePressed', self.ResetAndClear);
		f.editBox:SetScript('OnEnterPressed', self.ResetAndClear);
		f.editBox:SetScript('OnEditFocusLost', self.ResetAndClear);
		f.editBox:SetScript('OnEditFocusGained', f.editBox.HighlightText);
		
		local updateSearch = function(self, t)
			if(t == true) then
				B:UpdateSearch(self:GetText());
			end
		end
		
		f.editBox:SetScript('OnTextChanged', updateSearch);
		f.editBox:SetScript('OnChar', updateSearch);
		f.editBox:SetText(SEARCH);
		f.editBox:FontTemplate();

		f.editBox.searchIcon = f.editBox:CreateTexture(nil, 'OVERLAY');
		f.editBox.searchIcon:SetTexture('Interface\\Common\\UI-Searchbox-Icon');
		f.editBox.searchIcon:SetPoint('LEFT', f.editBox.backdrop, 'LEFT', E.Border + 1, -1);
		f.editBox.searchIcon:SetSize(15, 15);
	else
		f.goldText = f:CreateFontString(nil, 'OVERLAY');
		f.goldText:FontTemplate();
		f.goldText:Point('BOTTOMRIGHT', f.holderFrame, 'TOPRIGHT', -2, 4);
		f.goldText:SetJustifyH("RIGHT");
		
		f.sortButton = CreateFrame('Button', name..'SortButton', f);
		f.sortButton:SetSize(16 + E.Border, 16 + E.Border);
		f.sortButton:SetTemplate();
		f.sortButton:SetPoint('RIGHT', f.goldText, 'LEFT', -5, E.Border * 2);
		f.sortButton:SetNormalTexture('Interface\\ICONS\\INV_Pet_RatCage');
		f.sortButton:GetNormalTexture():SetTexCoord(unpack(E.TexCoords));
		f.sortButton:GetNormalTexture():SetInside();
		f.sortButton:SetPushedTexture('Interface\\ICONS\\INV_Pet_RatCage');
		f.sortButton:GetPushedTexture():SetTexCoord(unpack(E.TexCoords));
		f.sortButton:GetPushedTexture():SetInside();
		f.sortButton:StyleButton(nil, true);
		f.sortButton.ttText = L['Sort Bags'];
		f.sortButton:SetScript('OnEnter', self.Tooltip_Show);
		f.sortButton:SetScript('OnLeave', self.Tooltip_Hide);
		f.sortButton:SetScript('OnClick', function() B:CommandDecorator(B.SortBags, 'bags')(); end);
		
		f.bagsButton = CreateFrame('Button', name..'BagsButton', f);
		f.bagsButton:SetSize(16 + E.Border, 16 + E.Border);
		f.bagsButton:SetTemplate();
		f.bagsButton:SetPoint('RIGHT', f.sortButton, 'LEFT', -5, 0);
		f.bagsButton:SetNormalTexture('Interface\\Buttons\\Button-Backpack-Up');
		f.bagsButton:GetNormalTexture():SetTexCoord(unpack(E.TexCoords));
		f.bagsButton:GetNormalTexture():SetInside();
		f.bagsButton:SetPushedTexture('Interface\\Buttons\\Button-Backpack-Up');
		f.bagsButton:GetPushedTexture():SetTexCoord(unpack(E.TexCoords));
		f.bagsButton:GetPushedTexture():SetInside();
		f.bagsButton:StyleButton(nil, true);
		f.bagsButton.ttText = L['Toggle Bags'];
		f.bagsButton:SetScript('OnEnter', self.Tooltip_Show);
		f.bagsButton:SetScript('OnLeave', self.Tooltip_Hide);
		f.bagsButton:SetScript('OnClick', function() ToggleFrame(f.ContainerHolder) end);
		
		f.vendorGraysButton = CreateFrame('Button', nil, f.holderFrame);
		f.vendorGraysButton:SetSize(16 + E.Border, 16 + E.Border);
		f.vendorGraysButton:SetTemplate();
		f.vendorGraysButton:SetPoint('RIGHT', f.bagsButton, 'LEFT', -5, 0);
		f.vendorGraysButton:SetNormalTexture('Interface\\ICONS\\INV_Misc_Coin_01');
		f.vendorGraysButton:GetNormalTexture():SetTexCoord(unpack(E.TexCoords));
		f.vendorGraysButton:GetNormalTexture():SetInside();
		f.vendorGraysButton:SetPushedTexture('Interface\\ICONS\\INV_Misc_Coin_01');
		f.vendorGraysButton:GetPushedTexture():SetTexCoord(unpack(E.TexCoords));
		f.vendorGraysButton:GetPushedTexture():SetInside();
		f.vendorGraysButton:StyleButton(nil, true);
		f.vendorGraysButton.ttText = L['Vendor Grays'];
		f.vendorGraysButton:SetScript('OnEnter', self.Tooltip_Show);
		f.vendorGraysButton:SetScript('OnLeave', self.Tooltip_Hide);
		f.vendorGraysButton:SetScript('OnClick', B.VendorGrayCheck);
		
		f.editBox = CreateFrame('EditBox', name..'EditBox', f);
		f.editBox:SetFrameLevel(f.editBox:GetFrameLevel() + 2);
		f.editBox:CreateBackdrop('Default');
		f.editBox.backdrop:SetPoint("TOPLEFT", f.editBox, "TOPLEFT", -20, 2);
		f.editBox:Height(15);
		f.editBox:Point('BOTTOMLEFT', f.holderFrame, 'TOPLEFT', (E.Border * 2) + 18, E.Border * 2 + 2);
		f.editBox:Point('RIGHT', f.vendorGraysButton, 'LEFT', -5, 0);
		f.editBox:SetAutoFocus(false);
		f.editBox:SetScript('OnEscapePressed', self.ResetAndClear);
		f.editBox:SetScript('OnEnterPressed', self.ResetAndClear);
		f.editBox:SetScript('OnEditFocusLost', self.ResetAndClear);
		f.editBox:SetScript('OnEditFocusGained', f.editBox.HighlightText);
		
		local updateSearch = function(self, t)
			if(t == true) then
				B:UpdateSearch(self:GetText());
			end
		end
		
		f.editBox:SetScript('OnTextChanged', updateSearch);
		f.editBox:SetScript('OnChar', updateSearch);
		f.editBox:SetText(SEARCH);
		f.editBox:FontTemplate();
		
		f.editBox.searchIcon = f.editBox:CreateTexture(nil, 'OVERLAY');
		f.editBox.searchIcon:SetTexture('Interface\\Common\\UI-Searchbox-Icon');
		f.editBox.searchIcon:SetPoint('LEFT', f.editBox.backdrop, 'LEFT', E.Border + 1, -1);
		f.editBox.searchIcon:SetSize(15, 15);
		
		--Currency
		f.currencyButton = CreateFrame('Frame', nil, f);
		f.currencyButton:Point('BOTTOM', 0, 4);
		f.currencyButton:Point('TOPLEFT', f.holderFrame, 'BOTTOMLEFT', 0, 18);
		f.currencyButton:Point('TOPRIGHT', f.holderFrame, 'BOTTOMRIGHT', 0, 18);
		f.currencyButton:Height(22);
		for i = 1, MAX_WATCHED_TOKENS do
			f.currencyButton[i] = CreateFrame('Button', nil, f.currencyButton);
			f.currencyButton[i]:Size(16);
			f.currencyButton[i]:SetTemplate('Default');
			f.currencyButton[i]:SetID(i);
			f.currencyButton[i].icon = f.currencyButton[i]:CreateTexture(nil, 'OVERLAY');
			f.currencyButton[i].icon:SetInside();
			f.currencyButton[i].icon:SetTexCoord(unpack(E.TexCoords));
			f.currencyButton[i].text = f.currencyButton[i]:CreateFontString(nil, 'OVERLAY');
			f.currencyButton[i].text:Point('LEFT', f.currencyButton[i], 'RIGHT', 2, 0);
			f.currencyButton[i].text:FontTemplate();
			
			f.currencyButton[i]:SetScript('OnEnter', B.Token_OnEnter);
			f.currencyButton[i]:SetScript('OnLeave', function() GameTooltip:Hide() end);
			f.currencyButton[i]:SetScript('OnClick', B.Token_OnClick);
			f.currencyButton[i]:Hide();
		end	
		
		f:SetScript('OnHide', CloseAllBags)
	end
	
	tinsert(UISpecialFrames, f:GetName()) --Keep an eye on this for taints..
	tinsert(self.BagFrames, f)
	return f
end

function B:PositionBagFrames()
	if self.BagFrame then
		self.BagFrame:ClearAllPoints()
		if E.db.datatexts.rightChatPanel then
			self.BagFrame:Point('BOTTOMRIGHT', RightChatToggleButton, 'TOPRIGHT', 0 + E.db.bags.xOffset, (E.PixelMode and 1 or 4) + E.db.bags.yOffset);
		else
			self.BagFrame:Point('BOTTOMRIGHT', RightChatToggleButton, 'BOTTOMRIGHT', 0 + E.db.bags.xOffset, 0 + E.db.bags.yOffset);
		end
	end
	
	if self.BankFrame then
		self.BankFrame:ClearAllPoints()
		if E.db.datatexts.leftChatPanel then
			self.BankFrame:Point('BOTTOMLEFT', LeftChatToggleButton, 'TOPLEFT', 0 + E.db.bags.xOffsetBank, (E.PixelMode and 1 or 4) + E.db.bags.yOffsetBank);
		else
			self.BankFrame:Point('BOTTOMLEFT', LeftChatToggleButton, 'BOTTOMLEFT', 0 + E.db.bags.xOffsetBank, 0 + E.db.bags.yOffsetBank);
		end
	end
end

function B:ToggleBags(id)
	if id and GetContainerNumSlots(id) == 0 then return; end --Closes a bag when inserting a new container..
	
	if self.BagFrame:IsShown() then
	--	self:CloseBags();
	else
		self:OpenBags();
	end
end

function B:ToggleBackpack()
	if ( IsOptionFrameOpen() ) then
		return;
	end
	
	if IsBagOpen(0) then
		self:OpenBags()
	else
		self:CloseBags()
	end
end

function B:OpenBags()
	self.BagFrame:Show();
	self.BagFrame:UpdateAllSlots();
	E:GetModule('Tooltip'):GameTooltip_SetDefaultAnchor(GameTooltip)
end

function B:CloseBags()
	self.BagFrame:Hide();
	
	if self.BankFrame then
		self.BankFrame:Hide();
	end
	
	E:GetModule('Tooltip'):GameTooltip_SetDefaultAnchor(GameTooltip)
end

function B:OpenBank()
	if not self.BankFrame then
		self.BankFrame = self:ContructContainerFrame('ElvUI_BankContainerFrame', true);
		self:PositionBagFrames();
	end
	
	self:Layout(true)
	self.BankFrame:Show();
	self.BankFrame:UpdateAllSlots();
	self.BagFrame:Show();
	self:UpdateTokens()
end

function B:PLAYERBANKBAGSLOTS_CHANGED()
	self:Layout(true)
end

function B:CloseBank()
	if not self.BankFrame then return; end -- WHY???, WHO KNOWS!
	self.BankFrame:Hide()
end

function B:Initialize()
	self:LoadBagBar();

	if not E.private.bags.enable then return; end
	
	E.bags = self;
	
	self.db = E.db.bags;
	self.BagFrames = {};
	
	self.BagFrame = self:ContructContainerFrame('ElvUI_ContainerFrame');
	
	--Hook onto Blizzard Functions
	self:SecureHook('ToggleBackpack', 'ToggleBackpack');
	self:SecureHook('ToggleBag', 'ToggleBags');
	self:SecureHook('OpenAllBags', 'ToggleBackpack');
	self:SecureHook('OpenBackpack', 'OpenBags');
	self:SecureHook('CloseAllBags', 'CloseBags');
	self:SecureHook('CloseBackpack', 'CloseBags');
	
	-- self:SecureHook('OpenAllBags', 'OpenBags');
	-- self:SecureHook('CloseAllBags', 'CloseBags');
	-- self:SecureHook('ToggleBag', 'ToggleBags');
	--self:SecureHook('OpenAllBags', 'ToggleBackpack');
	-- self:SecureHook('ToggleBackpack')
	-- self:SecureHook('BackpackTokenFrame_Update', 'UpdateTokens');

	self:PositionBagFrames();
	self:Layout();

	E.Bags = self;

	self:DisableBlizzard();
	self:RegisterEvent("PLAYER_MONEY", "UpdateGoldText")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateGoldText")
	self:RegisterEvent("PLAYER_TRADE_MONEY", "UpdateGoldText")
	self:RegisterEvent("TRADE_MONEY_CHANGED", "UpdateGoldText")	
	self:RegisterEvent("BANKFRAME_OPENED", "OpenBank")
	self:RegisterEvent("BANKFRAME_CLOSED", "CloseBank")
	self:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED")

	StackSplitFrame:SetFrameStrata('DIALOG')
end

E:RegisterModule(B:GetName())