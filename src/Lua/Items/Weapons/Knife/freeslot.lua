states[freeslot("S_MM_KNIFE")] = {
	sprite = freeslot("SPR_KNFE"),
	frame = A,
	tics = -1
}
states[freeslot("S_MM_KNIFE_SPIN")] = {
	sprite = SPR_KNFE,
	frame = C|FF_FULLBRIGHT|FF_ANIMATE,
	var1 = 3,
	var2 = 1,
	tics = 4,
	nextstate = S_MM_KNIFE_SPIN
}

local function impactfx(mo)
	local sfx = P_SpawnGhostMobj(mo)
	sfx.tics = TR; sfx.fuse = TR
	sfx.flags2 = $|MF2_DONTDRAW
	S_StartSound(sfx, P_RandomRange(sfx_kimp0, sfx_kimp2))
	
	mo.momx,mo.momy,mo.momz = 0,0,0
end

states[freeslot("S_MM_KNIFE_STUCK")] = {
	sprite = SPR_KNFE,
	frame = G|FF_FULLBRIGHT,
	tics = 2 * TICRATE,
	action = impactfx
}

sfxinfo[freeslot("sfx_kequip")].caption = "Knife equip"
sfxinfo[freeslot("sfx_kffire")] = { 
	caption = "Stab",
	flags = SF_X4AWAYSOUND
}
sfxinfo[freeslot("sfx_kwhiff")].caption = "Whiff"
sfxinfo[freeslot("sfx_kcharg")].caption = "Charging"
sfxinfo[freeslot("sfx_kfly")] = {
	caption = "Knife flying",
	flags = SF_X2AWAYSOUND
}
for i = 0,2
	sfxinfo[freeslot("sfx_kimp" .. i)] = {
		caption = "Knife impact"
	}
end

--Sprite credit: instashield by pastel
states[freeslot("S_MM_KNIFE_WHIFF")] = {
	sprite = freeslot("SPR_MMWH"),
	frame = A|FF_FLOORSPRITE|FF_ANIMATE|FF_SEMIBRIGHT,
	var1 = G,
	var2 = 1,
	tics = G + 1
}

mobjinfo[freeslot("MT_MM_KNIFE_PROJECT")] = {
	radius = 12*FU,
	height = 24*FU,
	spawnstate = S_MM_KNIFE_SPIN,
	flags = MF_NOGRAVITY,
	--move in quarter steps
	speed = 100*FU / 4,
	deathstate = S_MM_KNIFE_STUCK
}

local tics_til_grav = 12
addHook("MobjThinker",function(mo)
	if not (mo and mo.valid) then return end
	if not mo.health
		mo.renderflags = $|RF_FULLBRIGHT
		S_StopSound(mo)
		if mo.tics < TICRATE / 2
			mo.flags2 = $^^MF2_DONTDRAW
		end
		if mo.hitsomething
			mo.flags = $ &~MF_NOGRAVITY
			if P_IsObjectOnGround(mo)
				mo.momz = -(mo.lastmomz or 0) * 5/6
				P_InstaThrust(mo, mo.angle, -2 * mo.scale)
			end
			mo.lastmomz = mo.momz
			mo.rollangle = $ + ANG10
		else
			mo.momx,mo.momy,mo.momz = 0,0,0
		end
		return
	end
	if mo.timealive == nil
		mo.timealive = 0
		mo.nosmoke = true
		mo.nodeathsound = true
		
		--speed
		P_InstaThrust(mo, mo.angle,
			FixedMul(mo.info.speed, cos(mo.aiming))
		)
		mo.momz = FixedMul(mo.info.speed, sin(mo.aiming))
		S_StartSound(mo, sfx_cdfm35)
	end
	
	if not S_SoundPlaying(mo, sfx_kfly)
		S_StartSound(mo, sfx_kfly)
	end
	mo.timealive = $ + 1
	/*
	if mo.timealive == tics_til_grav
		mo.flags = $ &~MF_NOGRAVITY
	end
	if mo.timealive == TICRATE * 3/2
		P_KillMobj(mo)
		return
	end
	*/
	
	for i = 1,3
		P_XYMovement(mo)
		if not (mo and mo.valid) then return end
		P_ZMovement(mo)
		if not (mo and mo.valid) then return end
	end
	
	do --if leveltime % 3 == 0
		local g = P_SpawnGhostMobj(mo)
		g.blendmode = AST_ADD
		g.renderflags = $|RF_FULLBRIGHT
		g.destscale = 0
		g.translation = "Grayscale"
	end
	
	if (mo.z <= mo.floorz)
	or (mo.z + mo.height >= mo.ceilingz)
		impactfx(mo)
		MM.BulletDies(mo)
		P_KillMobj(mo)
		return
	end
	
	local scaleup = (mo.scale * 3/4)
	mo.radius = $ + scaleup/2
	if not (mo and mo.valid)
		return
	end
	mo.height = $ + scaleup

end,MT_MM_KNIFE_PROJECT)

addHook("MobjMoveBlocked",function(mo, against,line)
	if (mo and mo.valid and mo.health and not mo.safeknife)
		impactfx(mo)
		MM.BulletDies(mo, against, line)
		P_KillMobj(mo)
	end
end,MT_MM_KNIFE_PROJECT)
addHook("MobjMoveCollide",MM.BulletHit,MT_MM_KNIFE_PROJECT)

return S_MM_KNIFE