--i swear we had this before...
local function clamp(minimum,value,maximum)
	if maximum < minimum
		local temp = minimum
		minimum = maximum
		maximum = temp
	end
	return max(minimum,min(maximum,value))
end

local function wrap(v,p,c)
	if not (p.mo and p.mo.valid) then return end
	if (p.spectator) then return end
	if (MM_N.gameover) then return end
	
	-- i hate splitscreen
	local sci_w = (v.width() / v.dupx())
	local sci_h = (v.height() / v.dupy())
	local sc_w = sci_w*FU
	local sc_h = sci_h*FU
	local sch_w = (sci_w - BASEVIDWIDTH)*FU/2
	local sch_h = (sci_h - BASEVIDHEIGHT)*FU/2
	
	for k, att in ipairs(p.mm.attract)
		local dest = {
			x = att.x,
			y = att.y,
			z = att.z
		}
		
		local to_screen = K_GetScreenCoords(v,p,c, dest, {anglecliponly = true})
		local x = to_screen.x
		local y = to_screen.y
		local patch = att.patch
		
		local offscreen = not to_screen.onscreen
		
		if offscreen
			local da = to_screen.camAngle - R_PointToAngle2(to_screen.camPos.x,to_screen.camPos.y, dest.x,dest.y)
			local borderx = 30
			local bordery = 50
			local center = {
				x = 160*FU,
				y = 100*FU,
			}
			local scr = {
				x = (160 - borderx)*FU + sch_w,
				y = (100 - bordery)*FU + sch_h,
			}
			x = center.x + FixedMul(scr.x, sin(da))
			y = center.y - FixedMul(scr.y, cos(da))
			
			-- whatever
			if (patch == "MM_BEARTRAP_OUT")
				MMHUD.interpolate(v,k)
				v.drawScaled(x, y,
					FU/2,
					v.getSpritePatch(SPR_BGLS, W, 0, 
						InvAngle(angdiff) + ANGLE_90
					),
					0
				)
				
				patch = "MM_BEARTRAP_OUT2"
			end
		end
		
		MMHUD.interpolate(v,k)
		if (att.str ~= nil)
			v.drawString(x, y,
				att.str,
				V_ALLOWLOWERCASE,
				"thin-fixed-center"
			)
		end
		if (patch ~= nil)
			v.drawScaled(x, y,
				att.scale or FU/2,
				v.cachePatch(patch),
				0
			)
		end
		if (patch == "MM_BEARTRAP_OUT"
		or patch == "MM_BEARTRAP_OUT2")
			if patch == "MM_BEARTRAP_OUT2" then y = $ + 10*FU; end
			v.drawString(x,y,
				((R_PointToDist2(p.mo.x, p.mo.y, dest.x,dest.y)/FU)/32).." fu",
				V_ALLOWLOWERCASE,
				"thin-fixed-center"
			)
		end
		MMHUD.interpolate(v,false)
	end
end

local function HUD_DrawGoHere(v,p,c)
	wrap(v,p,c)
end

return HUD_DrawGoHere