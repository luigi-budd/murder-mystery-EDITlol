local wrapadd = MM.require("Libs/wrappedadd")

return function(p)
	if not p.mm_save then return end
	
	if (p.mm_save.ringstopay)
	and (leveltime % 3 == 0)
		p.rings = 0
		local payout = 1 + (p.mm_save.ringstopay / 30)
		
		p.mm_save.rings = wrapadd($, payout)
		p.mm.rings = wrapadd($, payout)
		S_StartSoundAtVolume(nil, mobjinfo[MT_RING].deathsound, 255 * 3/4, p)
		
		p.mm_save.ringstopay = max($ - payout, 0)
	end
end