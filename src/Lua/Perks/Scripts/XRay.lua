local perk_name = "X-Ray"
local perk_price = 525 --1500

local TR = TICRATE
local cv_fov = CV_FindVar("fov")
local xraytics = 0

sfxinfo[freeslot("sfx_mmsnr")].caption = "\x89X-Ray ping\x80"

local function perk_thinker(p, freq)
	xraytics = max($ - 1, 0)
	if (leveltime > 0 and leveltime % freq == 0)
		xraytics = 8 * TR
		S_StartSound(nil, sfx_mmsnr, p)
	end
end
local function prim(p)
	perk_thinker(p, 30*TR)
end
local function sec(p)
	perk_thinker(p, 55*TR)
end

MM_PERKS[MMPERK_XRAY] = {
	primary = prim,
	secondary = sec,
	
	drawer = function(v,p,cam, order)
		if not (MM:isMM()) then return end
		if not (p.mm) then return end
		if not (p.mm_save) then return end
		if (p.spectator) then return end
		if (MM_N.gameover) then return end
		if (MM_N.showdown) then return end
		if (MM_N.dueling) then return end
		if not xraytics then return end
		
		if (p.mm.role ~= MMROLE_MURDERER) then return end
		
		local me = p.mo
		local alpha = 0
		if xraytics < 20
			alpha = (20 - xraytics) / 2
		end
		if alpha >= 10 then return end
		alpha = $ << V_ALPHASHIFT
		
		local drawwork = {}
		for play in players.iterate()
			if not (play.mm) then continue end
			if not (play.mm_save) then continue end
			if (play.spectator) then continue end
			if not (play.mo and play.mo.valid) then continue end
			if not (play.mo.health) then continue end
			if (play.mm.role == MMROLE_MURDERER) then continue end
			
			if (P_CheckSight(me, play.mo)) then continue end
			local dist = R_PointToDist(play.mo.x,play.mo.y)
			
			/*
			do
				local adiff = FixedAngle(
					AngleFixed(R_PointToAngle(play.mo.x, play.mo.y) - cam.angle)
				)
				if AngleFixed(adiff) > 180*FU
					adiff = InvAngle($)
				end
				if (AngleFixed(adiff) > cv_fov.value)
					continue
				end
			end
			*/
			
			table.insert(drawwork, {
				dist = dist,
				player = play,
				color = play.skincolor
			})
		end
		
		table.sort(drawwork,function(a,b)
			return a.dist > b.dist
		end)
		
		local mark = v.cachePatch("MM_SHOWDOWNMARK")
		for k,item in pairs(drawwork)
			local play = item.player
			
			local facingang = R_PointToAngle(play.mo.x, play.mo.y) - play.drawangle
			local patch,flip = v.getSprite2Patch(play.skin,
				play.mo.sprite2,
				false,
				play.mo.frame,
				((facingang + ANGLE_202h)>>29) + 1,
				play.mo.rollangle
			)
			local w2s = K_GetScreenCoords(v, p, cam, play.mo, {anglecliponly = true})
			if not w2s.onscreen then continue end
			
			local scale = w2s.scale
			scale = FixedMul($, skins[play.skin].highresscale)
			scale = FixedMul($, play.mo.scale)
			
			MMHUD.interpolate(v, #play)
			v.drawScaled(w2s.x, w2s.y, abs(scale),
				patch,
				(flip and V_FLIP or 0)|alpha,
				v.getColormap(TC_BLINK,item.color)
			)
			v.drawScaled(w2s.x, w2s.y - 60*w2s.scale,
				abs(scale), mark, alpha,
				v.getColormap(nil,item.color)
			)
			MMHUD.interpolate(v, false)
			
		end
		MMHUD.interpolate(v,false)
	end,

	icon = "MM_PI_XRAY",
	icon_scale = FU/2,
	name = perk_name,

	description = {
		"\x82Primary:\x80 See everyone through walls",
		"every 30 seconds!",
		
		"",
		
		"\x82Secondary:\x80 See everyone through walls",
		"every 55 seconds!"
	},
	cost = perk_price,
}

local id = MM.Shop.addItem({
	name = perk_name,
	price = perk_price,
	category = MM_PERKS.category_id
})
MM.Shop.items[id].perk_id = MMPERK_XRAY