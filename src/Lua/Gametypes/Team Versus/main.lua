local RESPAWNTIME = 5*TICRATE
local respawn_anim = 0
local halfsecond = TICRATE/2
local POINTINC = 100
local SCOREGOAL = 25 * POINTINC -- 25 kills
local TR = TICRATE
local playedsound = false

local teamversus_mode = MM.RegisterGametype("Team Versus", {
	tol = TOL_SAXAMM|TOL_MATCH;
	max_time = 3*60*TICRATE;
	required_players = 8;
	inventory_count = 2;
	fill_teams = true;
	disable_item_mapthing = true; -- includes interactions that drop items.
	disable_perks = true;
	disable_proximity_chat = true;
	disable_clues = true;
	disable_killgoal = true;
	disable_showdown = true;
	disable_gun_countdown = true;
	force_overtime = true;
	reveal_roles = true;
	all_droppable_items = true;
	instant_body_discover = true;
	allow_respawn = true;
	allow_corpses = true;
	force_small_role_hud = true;
	items = {"revolver", "shotgun", "sword", "knife", "hyperlaser"};
	rare_items = {"tripmine", "beartrap", "balloon", "luger"};
	thinker = function()
		if (MM_N.time <= 0 or MM_N.showdown)
		and MM_N.allow_respawn then
			MM_N.allow_respawn = false
			S_StartSound(nil, sfx_s3k9c)
			respawn_anim = RESPAWNTIME
		end
	end;
	canGameEnd = function()
		if (MM_N.tvs_mscore == nil or MM_N.tvs_sscore == nil)
			return
		end
		
		if (MM_N.tvs_mscore >= SCOREGOAL)
		or (MM_N.tvs_sscore >= SCOREGOAL)
			if not playedsound
				S_StartSound(nil,sfx_lvpass)
				S_StartSound(nil,sfx_nxbump)
			end
			playedsound = true
		end
		if (MM_N.tvs_mscore >= SCOREGOAL)
			return true, 2
		elseif (MM_N.tvs_sscore >= SCOREGOAL)
			return true, 1
		end
	end;
})

local dohitmarker = 0
sfxinfo[freeslot("sfx_hitmrk")].caption = "Hitmarker"

local ANIM = 2*TICRATE
local FADEIN = 6
local msgstatus = {
	str = "",
	tics = 0,
}

local function ShowStandings()
	local count = MM.countPlayers()
	if (consoleplayer and consoleplayer.valid and consoleplayer.mm)
		if consoleplayer.mm.role == MMROLE_MURDERER
			msgstatus.str = "\x85"..count.murderers.."\x80 vs \x84"..count.sheriffs
		else
			msgstatus.str = "\x84"..count.sheriffs.."\x80 vs \x85"..count.murderers
		end
		msgstatus.tics = ANIM
	end	
end

local temp_ms = 0
local temp_ss = 0
local function intlerp(frac,from,to)
	if abs(to - from) <= frac then return to; end
	if ((to - from)/frac == 0) and (to ~= from)
		return to
	end
	return from + (to - from)/frac
end
local function lerp(frac,from,to)
	return from + FixedDiv(to - from, frac)
end

-- Show how many we're fighting against on round start
MM.addHook("RoundStart", do
	MM_N.tvs_mscore = 0
	MM_N.tvs_sscore = 0
	temp_ms,temp_ss = 0,0
	playedsound = false
	
	local gt = MM.returnGametype()
	if gt.name ~= "Team Versus" then return end
	
	ShowStandings()
end)
MM.addHook("KilledPlayer", function(attacking_p, player)
	local gt = MM.returnGametype()
	if gt.name ~= "Team Versus" then return end
	--if MM_N.time > 90*TICRATE then return end
	
	if (consoleplayer and consoleplayer.valid)
	and (attacking_p and attacking_p.valid)
	and (consoleplayer == attacking_p)
		dohitmarker = 8
		S_StartSound(nil, sfx_hitmrk, consoleplayer)
		S_StartSoundAtVolume(nil, sfx_hitmrk, 255/2, consoleplayer) --Bruh
	end
	
	if player.mm.role == MMROLE_MURDERER
		-- Point sheriffs
		MM_N.tvs_sscore = $ + POINTINC
	else
		-- Point murderers
		MM_N.tvs_mscore = $ + POINTINC
	end
	
	if not MM_N.allow_respawn
		ShowStandings()
	end
end)

MM.addHook("PlayerDies", function(player)
	local gt = MM.returnGametype()
	if gt.name ~= "Team Versus" then return end
	
	for k,v in pairs(player.mm.inventory.items) do
		local mobj = MM:DropItem(player, k, false, true, true)
		if mobj and mobj.valid
			mobj.fuse = 5 * TR
		end
	end
end)

MM.addHook("PlayerSpawn", function(p)
	local gt = MM.returnGametype()
	if gt.name ~= "Team Versus" then return end
	local mm = p.mm
	
	-- 30% chance to get something else
	if P_RandomChance(FU*3/10)
		local item = gt.rare_items[P_RandomRange(1, #gt.rare_items)]
		MM:GiveItem(p, item, 2)
	end
	
	-- Only run this when we respawn
	if not mm.got_weapon then return end
	
	local item = gt.items[P_RandomRange(1, #gt.items)]
	MM:GiveItem(p, item)
end)

MM.addHook("DropItemThinker", function(item, mobj)
	local gt = MM.returnGametype()
	if gt.name ~= "Team Versus" then return end
	
	if mobj.fuse < 0
		mobj.fuse = 10 * TR
	end
end)

local byteLUT = {}
for i = 26, 126
	byteLUT[i] = ("%.3d"):format(i)
end

MMHUD.addHud("TVS_Hitmarker", false,false, function(v,p,c)
	if not dohitmarker then return end
	
	local alpha = 0
	if dohitmarker < 5
		alpha = (10 - (2 * dohitmarker))<<V_ALPHASHIFT
	end
	
	if not c.chase
		v.drawScaled(160*FU,100*FU, FU/4, v.cachePatch("MM_HITMARK"),alpha, v.getColormap(nil, p.skincolor,nil))
	end
	dohitmarker = $ - 1
end, "game")

MMHUD.addHud("TVS_GeneralHUD", false,false, function(v,p,c)
	local gt = MM.returnGametype()
	if gt.name ~= "Team Versus" then return end
	
	if MM:pregame() and (leveltime >= TR)
		local anim = leveltime - TR
		local vidwidth = v.width()
		local vidheight = v.height()
		local dup = v.dupx()
		
		local x = vidwidth/2
		local y = (vidheight/2) + 20*dup
		
		local fhei = 10*FU
		if anim <= 14
			local frac = (FU/14)
			x		= ease.linear(frac*anim, vidwidth*3/2, $)
			fhei	= ease.linear(frac*anim, 1, $)
		end
		if anim >= (2*TR)
			local dur = 20
			local tics = min((anim - 2*TR), dur)
			y = ease.outquad((FU/dur)*tics, $, 12*dup)
			local offset = FixedDiv(MMHUD.weaponslidein, 380*FU) -- we love magic numbers around here
			y = $ - FixedMul(vidheight, offset)
		end
		
		v.drawStretched(0, y*FU + 10*FU*dup + FixedMul(10*dup, FU - FixedDiv(fhei, 10*FU))/2, vidwidth*FU,fhei,
			v.cachePatch("1PIXEL"), V_NOSCALESTART|V_50TRANS
		)
		v.drawString(x,y + 11*dup,
			"First team to \x82"..SCOREGOAL.."\x80 points wins!",
			V_ALLOWLOWERCASE|V_NOSCALESTART,
			"thin-center"
		)
	end
	
	-- score counters
	do
		local x = 160*FU
		local y = 5*FU
		local flags = V_SNAPTOTOP
		local scale = FU/2
		local pat, frac
		local stroff = 0
		
		temp_ms = lerp(4*FU, (MM_N.tvs_mscore or 0)*FU, $)
		temp_ss = lerp(4*FU, (MM_N.tvs_sscore or 0)*FU, $)
		
		if not MM_N.gameover
			y = $ - MMHUD.xoffset
		else
			if MM_N.voting then return end
			local animfrac = FU
			local murdwin
			if not (MM_N.tvs_mscore >= SCOREGOAL
			or MM_N.tvs_sscore >= SCOREGOAL)
				murdwin = MM_N.endType == 2
				if not murdwin
					temp_ms = 0
				else
					temp_ss = 0
				end
			else
				murdwin = (MM_N.tvs_mscore >= SCOREGOAL)
			end
			
			if MM_N.end_ticker < TR/2
				animfrac = FixedDiv(MM_N.end_ticker*FU, (TR/2)*FU)
			end
			
			scale = ease.outquad(animfrac, $, FU * 4/5)
			y = ease.outback(animfrac, $, 20*FU, FU)
			stroff = 3 * (scale - (FU/2))
			
			v.drawString(x, y - 10*FU, (murdwin and "Murderers" or "Sheriffs").." Win!", flags|V_ALLOWLOWERCASE|(murdwin and V_REDMAP or V_BLUEMAP), "thin-fixed-center")
		end
		local width = 140*scale
		v.drawScaled(x,y, scale, v.cachePatch("MM_TVS_BG"), flags)
		v.drawString(x,y + stroff, SCOREGOAL, V_YELLOWMAP|flags, "thin-fixed-center", true)
		
		-- murderers
		pat = v.cachePatch("MM_TVS_MFILL")
		frac = FixedDiv(min(temp_ms,SCOREGOAL*FU), SCOREGOAL*FU)
		v.drawCropped(x,y, scale,scale, pat,flags,nil, 0,0, FixedMul(pat.width*FU, frac),pat.height*FU)
		v.drawString(x - width, y + stroff, temp_ms/FU, flags, "thin-fixed-center", true)
		
		-- sheriffs
		pat = v.cachePatch("MM_TVS_SFILL")
		frac = FixedDiv(min(temp_ss,SCOREGOAL*FU), SCOREGOAL*FU)
		v.drawCropped(x+FixedMul(pat.width*scale, FU - frac),y, scale,scale, pat,flags,nil, FixedMul(pat.width*FU, max(FU - frac, 0)),0, pat.width*FU,pat.height*FU)
		v.drawString(x + width, y + stroff, temp_ss/FU, flags, "thin-fixed-center", true)
	end
	
	if (MM_N.gameover)
		msgstatus.tics = 0
		respawn_anim = 0
		return
	end
	
	if (respawn_anim)
		local x = 160*FU
		local y = 20*FU
		
		if (RESPAWNTIME - respawn_anim <= halfsecond)
			x = ease.outquad((FU/(halfsecond)) * (RESPAWNTIME - respawn_anim),
				300*FU,
				$
			)
		elseif respawn_anim <= halfsecond
			x = ease.inback((FU/(halfsecond)) * (halfsecond - respawn_anim),
				$,
				-300*FU,
				FU/2
			)
		end
		
		v.drawString(x, y, "Respawning Disabled!", V_SNAPTOTOP|V_ORANGEMAP, "thin-fixed-center")
		respawn_anim = $ - 1
	end
	
	if not (msgstatus.tics) then return end
	
	local x = 160*FU
	local y = 30*FU
	local str = msgstatus.str
	
	local flags = V_SNAPTOTOP
	local scale = FU
	if (ANIM - msgstatus.tics < FADEIN)
		local tics = ANIM - msgstatus.tics
		local progress = FixedDiv(tics*FU, FADEIN*FU)
		
		scale = ease.incubic(progress, 3*FU, FU)
		y = $ - (4 * (scale - FU))
		
		local fade = ease.incubic(progress, 10*FU, 0)/FU
		flags = $|(min(fade, 9)<<V_ALPHASHIFT)
	end
	
	if (msgstatus.tics < 10)
		flags = $|(10 - msgstatus.tics)<<V_ALPHASHIFT
	end
	
	x = $ - (v.stringWidth(str,0,"normal")*scale)/2
	
	local cmap
	for i = 1, str:len()
		local char = str:sub(i,i)
		local byte = char:byte()
		if (byte < 26 or byte > 126)
			if byte == 132 -- "\x84"
				cmap = v.getStringColormap(V_BLUEMAP)
			elseif byte == 133 -- "\x85"
				cmap = v.getStringColormap(V_REDMAP)
			else
				cmap = nil
			end
			continue
		end
		if (char == " ")
			x = $ + 4*scale
			continue
		end
		local letter = v.cachePatch("STCFN" .. byteLUT[byte])
		v.drawScaled(x,y, scale, letter, flags, cmap)
		x = $ + (letter.width*scale)
	end
	
	msgstatus.tics = max($ - 1, 0)
end, "game")