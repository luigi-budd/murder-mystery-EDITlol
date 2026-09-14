return function(p, item_id, allowsound)
	local item_t = MM.Shop.items[item_id]
	
	if item_t == nil then return end
	if (p.mm_save == nil) then return end
	
	local res
	local price = item_t.price
	if (item_t.priceadjust ~= nil)
		res = item_t.priceadjust(p)
		if tonumber(res) ~= nil then price = res; end
	end
	
	--cant afford
	if p.mm_save.rings < price then return end
	if not item_t.multiple
		if p.mm_save.purchased[item_id] == true then return end
	end
	
	p.mm_save.rings = $ - price
	if item_t.multiple
		p.mm_save.purchased[item_id] = ($ or 0) + 1
	else
		p.mm_save.purchased[item_id] = true
	end
	
	if (item_t.purchase ~= nil)
		item_t.purchase(p)
	end
	
	if allowsound
		S_StartSound(nil,sfx_chchng,p)
	end
end