return function(v)
	if MenuLib and (not MenuLib.noMenuOpenAtAll())
		MMHUD.DoRegularSlide(v,true)
		MMHUD.DoWeaponSlide(v,true)
		MMHUD.dontslidein = true
	end
end