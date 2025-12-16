MM.Gametypes = {}

local DEFAULT_MAX_TIME = 3*60*TICRATE

-- TODO: default variables should go here
local gametype_t = {
	tol = TOL_SAXAMM,
	max_time = DEFAULT_MAX_TIME,
	
	disable_duels = false,
	allow_iframes = false, -- if true, players cannot be damaged with iframes
	allow_payouts = true, -- if true, pay people at the end of rounds
}
registerMetatable(gametype_t)

function MM.RegisterGametype(name, _data)
	local gametype_id = #MM.Gametypes + 1
	_data = $ or {}
	
	setmetatable(_data, {
		__index = gametype_t,
	})
	MM.Gametypes[gametype_id] = _data
	MM.Gametypes[gametype_id].name = name
	MM.Gametypes[gametype_id].id = gametype_id
	
	return MM.Gametypes[gametype_id]
end

-- TODO: arg1 is the gametype_id, which returns that gametype's table.
function MM.returnGametype(arg1)
	return MM.Gametypes[MM_N.gametype]
end

-- MM_N.maxtime has a different variable name than Gametype[id].max_time

MM.RegisterGametype("Classic")

dofile("Gametypes/Team Versus/main")