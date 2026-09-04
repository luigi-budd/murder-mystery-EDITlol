local path = "Items/Weapons/"

local spread = 10
MM.BulletDies = function(mo, moagainst, line)
	if (line and line.valid)
		--no puffs against thok barriers
		if P_CheckSkyHit(mo,line) then return end
	end
	if mo.nobulletfx then return end
	
	if not mo.nosmoke
		for i = 0, P_RandomRange(2,5)
			local ghs = P_SpawnMobjFromMobj(mo,
				P_RandomRange(-spread,spread)*FU,
				P_RandomRange(-spread,spread)*FU,
				P_RandomRange(-spread,spread)*FU,
				MT_SMOKE
			)
			--get rid of interp
			P_SetOrigin(ghs, ghs.x,ghs.y,ghs.z)
		end
	end
	
	local sfx = P_SpawnGhostMobj(mo)
	sfx.flags2 = $|MF2_DONTDRAW
	sfx.fuse = TICRATE
	
	if not mo.nodeathsound
		if (mo.info.deathsound == nil or mo.info.deathsound == sfx_none) then
			S_StartSound(sfx,P_RandomRange(sfx_mmbi0,sfx_mmbi3))
		else
			S_StartSound(sfx,mo.info.deathsound)
		end
	end
	
	local angle = mo.angle + ANGLE_90
	if (moagainst and moagainst.valid)
		angle = R_PointToAngle2(
			mo.x, mo.y,
			moagainst.x, moagainst.y
		) + ANGLE_90
	elseif (line and line.valid)
		angle = R_PointToAngle2(line.v1.x, line.v1.y, line.v2.x, line.v2.y)
	end
	
	local floormode = false
	if mo.z <= mo.floorz
	or mo.z+mo.height >= mo.ceilingz
		floormode = true
	end
	
	local spark = P_SpawnMobjFromMobj(mo, 0,0,0, MT_PARTICLE)
	spark.state = S_MM_BULLETIMP
	if mo.info.sparkvfx_func then
		mo.info.sparkvfx_func(spark)
	end
	
	--[[
	local spokes = mo.info.sparkvfx_spokes or 8
	local fa = FixedDiv(360*FU, spokes*FU)
	local speed = 6*mo.scale
	
	local rev_x = P_ReturnThrustX(nil, mo.angle, -mo.scale * 3)
	local rev_y = P_ReturnThrustY(nil, mo.angle, -mo.scale * 3)
	
	for i = 1, spokes
		local my_ang = FixedAngle(fa * i)
		
		local spark = P_SpawnMobjFromMobj(mo, rev_y, rev_x,
			FixedDiv((41*mo.height)/48, mo.scale),
			MT_MINECARTSPARK
		)
		if not floormode
			P_InstaThrust(spark, angle, FixedMul(cos(my_ang), speed))
			spark.momz = FixedMul(sin(my_ang), speed)
			
			P_Thrust(spark, angle + ANGLE_90,
				speed / 3
			)
		else
			local sign = (mo.z+mo.height >= mo.ceilingz) and -1 or 1
			P_SetObjectMomZ(spark, speed * sign)
			P_InstaThrust(spark, my_ang, speed / 3)
		end
		
		spark.flags = $ &~MF_NOGRAVITY
		spark.fuse = TICRATE * 2 --/3
		/*
		spark.blendmode = AST_ADD
		spark.alpha = FU * 3/4
		spark.destscale = 0
		spark.scalespeed = FixedDiv(spark.scale, spark.fuse*FU)
		*/
		
		if mo.info.sparkvfx_func then
			mo.info.sparkvfx_func(spark)
		end
		
		P_SetOrigin(spark, spark.x, spark.y, spark.z)
	end
	]]
	
	--bullet holes
	if (moagainst and moagainst.valid) then return end
	if (mo.nobulletholes) then return end
	
	local bull_x = mo.x
	local bull_y = mo.y
	local bull_z = mo.z
	local bull_frame = K
	if (line and line.valid)
		bull_x,bull_y = P_ClosestPointOnLine(bull_x,bull_y, line)
	end
	do
		local hole = P_SpawnMobjFromMobj(mo, 0,0,0, MT_THOK)
		hole.radius = mo.scale
		hole.height = 2 * mo.scale
		
		hole.frame = FF_SEMIBRIGHT|FF_PAPERSPRITE
		hole.sprite = SPR_BGLS
		hole.frame = $|bull_frame
		hole.mirrored = P_RandomChance(FU/2)
		hole.flags = $|MF_SCENERY
		
		hole.angle = angle
		hole.fuse = 5 * TICRATE
		hole.tics = hole.fuse
		
		if floormode
			local floorz = mo.floorz
			local sign = 1
			if (mo.z+mo.height >= mo.ceilingz)
				sign = -1
				floorz = mo.ceilingz
			end
			
			P_SetOrigin(hole,
				bull_x,
				bull_y,
				floorz + mo.scale*sign
			)
			bull_frame = M
			hole.frame = bull_frame|FF_SEMIBRIGHT|FF_FLOORSPRITE
			hole.renderflags = $|RF_NOSPLATBILLBOARD
		else
			P_SetOrigin(hole,
				bull_x - P_ReturnThrustX(nil, mo.angle, mo.scale),
				bull_y - P_ReturnThrustY(nil, mo.angle, mo.scale),
				bull_z
			)
		end
		
		--shadow
		local fx = P_SpawnMobjFromMobj(mo, 0,0,0, MT_THOK)
		fx.radius = mo.scale
		fx.height = 2 * mo.scale
		
		fx.frame = hole.frame
		fx.sprite = SPR_BGLS
		fx.frame = ($ &~FF_FRAMEMASK)|(bull_frame + 1)
		fx.blendmode = AST_REVERSESUBTRACT
		fx.renderflags = hole.renderflags
		fx.mirrored = hole.mirrored
		fx.flags = $|MF_SCENERY
		
		fx.angle = angle
		fx.fuse = hole.fuse
		fx.tics = hole.fuse
		
		P_SetOrigin(fx, hole.x, hole.y, hole.z)
	end
end

local whippedframe = -1
local function R_PointTo3DDist(x1,y1,z1, x2,y2,z2)
	return FixedHypot(FixedHypot(x2 - x1, y2 - y1), z2 - z1)
end

MM.CheckBulletWhips = function(shot)
	if not (shot and shot.valid and shot.health) then return end
	local sfxid = P_RandomRange(sfx_mmbw0,sfx_mmbw3)
	
	local p = displayplayer
	if not (p and p.valid) then return end
	if p.spectator then return end
	local me = p.mo
	if not (me and me.valid and me.health) then return end
	if (shot.target == me) then return end
	
	local use_iframes = MM.Gametypes[MM_N.gametype].allow_iframes
	if (p.powers[pw_flashing] and use_iframes)
		return
	end
	
	local friendly = false
	if (shot.target and shot.target.valid)
	and p.mm.role == shot.target.player.mm.role
	and shot.target.player.mm.role ~= MMROLE_INNOCENT
		friendly = true
	end
	if friendly then return end
	if shot.whipped then return end
	if whippedframe == leveltime then return end
	
	if R_PointTo3DDist(shot.x,shot.y,shot.z, me.x,me.y,me.z + me.height*4/5) > 200*shot.scale then return end
	
	local sfx = P_SpawnGhostMobj(shot)
	sfx.flags2 = $|MF2_DONTDRAW
	sfx.fuse = TR
	sfx.tics = sfx.fuse
	S_StartSoundAtVolume(sfx, sfxid, 255, p)
	-- S_StartSoundAtVolume(sfx, sfxid, 255, dp)
	shot.whizzed = true
	whippedframe = leveltime
end

local function P_Lerp(frac, from, to)
	return from + FixedMul(to - from, frac)
end
local function TraceRay(lstart,lend, iter,clr, iscaleadd, fscaleadd, totalstep)
	for i = 1,iter
		local frac = FixedDiv(i*FU, iter*FU)
		local t = P_SpawnMobj(
			P_Lerp(frac, lstart.x, lend.x),
			P_Lerp(frac, lstart.y, lend.y),
			P_Lerp(frac, lstart.z, lend.z),
			MT_THOK
		)
		t.sprite = SPR_BGLS
		t.frame = X|FF_FULLBRIGHT|FF_ADD
		t.scale = ($ / 9) + P_Lerp(frac, iscaleadd, fscaleadd)
		t.fuse = 2 + (totalstep/52)
		t.tics = t.fuse
		t.flags = $|MF_NOBLOCKMAP
		t.destscale = 0
		t.scalespeed = FixedDiv(t.scale, t.fuse*FU)
		t.color = clr
		totalstep = $ + 1
	end
	return totalstep
end
MM.GenericHitscan = function(mo)
	if not mo.valid then return end
	
	local def = MM.Items[mo.origin.id]
	local caught = 0
	
	mo.bullframe = A
	local startpos = Vec3.MobjPosToVec(mo)
	mo.startpos = startpos
	local lastpos = Vec3.MobjPosToVec(mo)
	
	local vfxiterations = mo.info.bullettracer_num or 18
	local vfxclr = mo.info.bullettracer_color or SKINCOLOR_ORANGE
	local vfxscale = 0
	local vfxstep = 0
	for i = 0,255 do
		if not (mo and mo.valid) then
			return
		end
		if (not mo.health) then
			P_RemoveMobj(mo)
			return
		end
		
		--we do this so its easier to hit players from farther away, while also 
		--being able to hit players closer up in small areas
		local gs = P_SpawnGhostMobj(mo)
		gs.flags2 = $|MF2_DONTDRAW
		gs.fuse = 1
		
		mo.radius = $ + mo.scale/4
		if not (mo and mo.valid)
			MM.BulletDies(gs)
			return
		end
		mo.height = $ + mo.scale/2
		
		if def.bulletthinker
			if def.bulletthinker(mo, i)
				return
			end
			
			--thinker removed the bullet
			if not (mo and mo.valid) then
				return
			end
		end
		
		if mo.z <= mo.floorz
		or mo.z+mo.height >= mo.ceilingz
		and (i > 0) then
			mo.forcehit = true
			MM.CheckLagReduction(mo, startpos, Vec3.MobjPosToVec(mo), mo.radius, mo.height, MM.BulletHit)
			MM.BulletDies(mo)
			P_RemoveMobj(mo)
			return
		end
		
		if i % 4 == 0 then
			local thispos = {x = mo.x, y = mo.y, z = mo.z}
			local scaleinc = FU/64
			vfxstep = TraceRay(thispos, lastpos, vfxiterations,vfxclr, vfxscale, vfxscale + scaleinc, $)
			lastpos.x = mo.x
			lastpos.y = mo.y
			lastpos.z = mo.z
			vfxscale = $ + scaleinc
		end
		
		P_XYMovement(mo)
		if not (mo and mo.valid) then
			return
		end
		
		P_ZMovement(mo)
		if not (mo and mo.valid) then
			return
		end
		
		--dont step up stairs
		if (mo.eflags & MFE_JUSTSTEPPEDDOWN)
			mo.forcehit = true
			MM.CheckLagReduction(mo, startpos, Vec3.MobjPosToVec(mo), mo.radius, mo.height, MM.BulletHit)
			MM.BulletDies(mo)
			P_RemoveMobj(mo)
			return			
		end
		
		if FixedHypot(mo.momx,mo.momy) == 0
			if caught >= 8
				mo.forcehit = true
				MM.CheckLagReduction(mo, startpos, Vec3.MobjPosToVec(mo), mo.radius, mo.height, MM.BulletHit)
				MM.BulletDies(mo)
				P_RemoveMobj(mo)
				return
			end
			caught = $ + 1
		end
		MM.CheckBulletWhips(mo)
	end
	
	if mo and mo.valid then
		MM.BulletDies(mo)
		P_RemoveMobj(mo)
	end
end

-- fires a ray from startpos to endpos, checking if any players intersected it
MM.CheckLagReduction = function(mo, startpos, endpos, radius, height, callback)
	for p in players.iterate
		if p.spectator then return end
		local me = p.mo
		if not (me and me.valid and me.health) then continue end
		
		local snapshot = p.mm.lagsnapshots[mo.spawnlatency]
		local intersect = P_ClosestPointOnLine3D(Vec3.New(snapshot.x,snapshot.y,snapshot.z), startpos, endpos)
		
		if abs(intersect.x - snapshot.x) <= snapshot.radius + radius
		and abs(intersect.y - snapshot.y) <= snapshot.radius + radius
		and (
			snapshot.z <= intersect.z + height -- check overhead
			and snapshot.z+snapshot.height >= intersect.z -- check underhead
		)
			callback(mo, me, startpos, endpos)
			return
		end
	end

	if MMCAM and MMCAM.TOTALCAMS
		for k,cam in pairs(MMCAM.TOTALCAMS)
			if not (cam and cam.valid) then continue end
			if not (cam.health) then continue end
			if not (cam.args) then continue end
			if (cam.args.viewpoint) then continue end
			if not (cam.args.hitbox and cam.args.hitbox.valid) then continue end
			
			-- like the guy
			-- the yoshi swallowing guy
			local hbox = cam.args.hitbox
			local intersect = P_ClosestPointOnLine3D(Vec3.New(hbox.x,hbox.y,hbox.z), startpos, endpos)
			
			if abs(intersect.x - hbox.x) <= hbox.radius + radius
			and abs(intersect.y - hbox.y) <= hbox.radius + radius
			and (
				hbox.z <= intersect.z + height -- check overhead
				and hbox.z+hbox.height >= intersect.z -- check underhead
			)
				callback(mo, me, startpos, endpos)
				return
			end
		end
	end
end

MM.BulletHit = function(ring,pmo)
	if not (ring and ring.valid) then return end
	if not (pmo and pmo.valid) then return end
	if (pmo == ring.target) then return end
	if not (ring.target and ring.target.valid) then return end
	
	if not ring.forcehit
		if ring.z > pmo.z+pmo.height then return end
		if pmo.z > ring.z+ring.height then return end
	end
	
	-- check solid objects
	if (pmo.flags & (MF_SOLID|MF_SHOOTABLE) == MF_SOLID)
		MM.BulletDies(ring)
		P_KillMobj(ring)
		return
	end
	
	if not (pmo.health) then return end
	
	if not (pmo.player and pmo.player.valid)
		if (pmo.flags & MF_SHOOTABLE)
		or pmo.camhitbox
			
			--if this is a generic shootable (monitors, enemies, etc...),
			--damage it with the ring's target (the player) or the ring itself as the source
			if not pmo.camhitbox
				-- tripmines get hitlag
				if pmo.type == MT_MM_TRIPMINE
					pmo.markedfordeath = TICRATE / 2
					pmo.deathvar = {ring, ring.target}
					S_StartSound(pmo, sfx_buzz3)
				else
					P_DamageMobj(pmo, ring, (ring.target and ring.target.valid) and ring.target or ring, 2)
				end
			--otherwise, we're shooting a camera, so kill it and make it offline
			elseif (ring.target.player.mm.role == MMROLE_MURDERER)
				P_KillMobj(pmo.tracer, ring, (ring.target and ring.target.valid) and ring.target or ring, 2)
			end
			
            ring.nobulletholes = true
			ring.hitsomething = true
			MM.BulletDies(ring)
			P_KillMobj(ring)
		end
		return
	end
	
	if not (pmo.player and pmo.player.mm) then return end

	local use_iframes = MM.Gametypes[MM_N.gametype].allow_iframes
	if (pmo.player.powers[pw_flashing] and use_iframes) then
		return
	end

	if pmo.player and pmo.player.mm
	and pmo.player.mm.role == ring.target.player.mm.role
	and ring.target.player.mm.role ~= MMROLE_INNOCENT
		ring.nobulletholes = true
		ring.hitsomething = true
		MM.BulletDies(ring)
		P_KillMobj(ring)
		return
	end
	
	P_DamageMobj(pmo, ring, (ring.target and ring.target.valid) and ring.target or ring, 999, DMG_INSTAKILL)
	ring.nobulletholes = true
	ring.hitsomething = true
	
	local def = MM.Items[ring.origin.id]
	if def.hitplayer
		def.hitplayer(ring, pmo)
	end

    MM.BulletDies(ring)
	P_KillMobj(ring)
end

-- Sheriff weapons
MM:CreateItem(dofile(path.."Revolver/def"))
MM:CreateItem(dofile(path.."Shotgun/def"))
MM:CreateItem(dofile(path.."Sword/def"))
MM:CreateItem(dofile(path.."HyperlaserGun/def"))

-- Murderer & Perk items
MM:CreateItem(dofile(path.."Knife/def"))
MM:CreateItem(dofile(path.."Luger/def"))
MM:CreateItem(dofile(path.."Swap_Gear/def"))
MM:CreateItem(dofile(path.."HotPotato/def"))
MM:CreateItem(dofile(path.."Tripmine/def"))
MM:CreateItem(dofile(path.."BearTrap/def"))

-- Tier 2 clue items
MM:CreateItem(dofile(path.."LoudSpeaker/def"))
MM:CreateItem(dofile(path.."ToyKnife/def"))
MM:CreateItem(dofile(path.."Balloon/def"))
MM:CreateItem(dofile(path.."Snowball/def"))

-- Junk items
MM:CreateItem(dofile(path.."Burger/def"))
MM:CreateItem(dofile(path.."BloxyCola/def"))
MM:CreateItem(dofile(path.."Radio/def"))

-- Admin backdoors
MM:CreateItem(dofile(path.."DevLuger/def"))
MM:CreateItem(dofile(path.."DevShotgun/def"))
MM:CreateItem(dofile(path.."DevThok/def"))
