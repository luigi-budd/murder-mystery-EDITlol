return function(p)
	local snapshot = {
		x = p.mo.x,
		y = p.mo.y,
		z = p.mo.z,
		radius = p.mo.radius
		height = p.mo.height
	}
	
	for i = TICRATE, 1, -1 do
		p.mm.lagsnapshot[i] = p.mm.lagsnapshot[i-1] or snapshot
	end
	
	p.mm.lagsnapshot[0] = snapshot
end