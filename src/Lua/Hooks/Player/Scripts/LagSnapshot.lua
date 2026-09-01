return function(p)
	local snapshot = {
		x = p.mo.x,
		y = p.mo.y,
		z = p.mo.z,
		radius = p.mo.radius,
		height = p.mo.height
	}
	
	table.insert(p.mm.lagsnapshots, 1, snapshot)
	if #p.mm.lagsnapshots > TICRATE
		table.remove(p.mm.lagsnapshots, TICRATE + 1)
	end
	
	p.mm.lagsnapshots[0] = snapshot
end