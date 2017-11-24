-- Doctor Who mod for Minetest
-- 
-- TARDIS Electricity module

dr_who.tardis.electric = {}

dr_who.tardis.electric.conductors = {
	dr_who.tardis.console_block,
	dr_who.tardis.flight_comp,
	dr_who.tardis.up_down,
	dr_who.tardis.matrix.source,
	dr_who.tardis.matrix.fluid
}

function dr_who.tardis.electric:get_connected_nodes(pos)
	local x = pos.x - 1
	local y = pos.y - 1
	local z = pos.z - 1
	local node = nil
	local allnodes = {}
	local i = 1
	while x <= (pos.x + 1) do
		y = pos.y - 1
		while y <= (pos.y + 1) do
			z = pos.z - 1
			while z <= (pos.z + 1) do
				node = minetest.env:get_node({x=x, y=y, z=z})
				if dr_who:search_table(node.name, dr_who.tardis.electric.conductors) then
					allnodes[i] = {name=node.name, pos={x=x, y=y, z=z}}
					i = i + 1
				end	
				z = z + 1
			end
			y = y + 1
		end
		x = x + 1
	end
	return allnodes
end

function dr_who.tardis.electric:find_node(pos, nodename, nodes_investigated)
	local computer_found = false
	local computer_pos = {x=0, y=0, z=0}
	if not nodes_investigated then
		nodes_investigated = {}
	end
	nodes_investigated[dr_who:stringify(pos, false)] = true
	for k,i in pairs(dr_who.tardis.electric:get_connected_nodes(pos)) do
		if not nodes_investigated[dr_who:stringify(i.pos, false)] then
			if i.name == nodename then
				return true, i.pos
			end
			computer_found, computer_pos = dr_who.tardis.electric:find_node(i.pos, nodename, nodes_investigated)
			if computer_found then
				break
			end
		end
	end
	return computer_found, computer_pos
end

function dr_who.tardis.electric:send_data_to_node(pos, name, data)
	local node_found = false
	local node_pos = {x=0, y=0, z=0}
	node_found, node_pos = dr_who.tardis.electric:find_node(pos, name)
	if not node_found then
		return false
	end
	local meta = minetest.env:get_meta(node_pos)
	local meta_table = meta:to_table()
	dr_who:extend_table(meta_table.fields, data)
	meta:from_table(meta_table)
	dr_who:dump(meta:to_table().fields)
	return true
end

function dr_who.tardis.electric:send_data_to_computer(pos, data)
	return dr_who.tardis.electric:send_data_to_node(pos, dr_who.tardis.flight_comp, data)
end

function dr_who.tardis.electric:send_data_to_matrix(pos, data, user)
	local matrix_found = false
	local matrix_pos = {x=0, y=0, z=0}
	matrix_found, matrix_pos = dr_who.tardis.electric:find_node(pos, dr_who.tardis.matrix.source)
	if not matrix_found then
		return false
	end
	dr_who.tardis.matrix:interpret_mlang(data, pos, user)
	return true
end

function dr_who.tardis.electric:computer_translate_to_mlang(t)
	mlangstr = ""
	if not dr_who.tardis:lever_convert(t.ready) then
		dr_who:dump("NOT READY")
		return mlangstr
	end
	if dr_who.tardis:lever_convert(t.brakes) then
		dr_who:dump("BRAKES")
		mlangstr = mlangstr .. "oB" .. dr_who.tardis.true_str -- Add brakes
	else
		dr_who:dump("NOBRAKES")
		mlangstr = mlangstr .. "oB" .. dr_who.tardis.false_str -- Remove brakes
	end
	mlangstr = mlangstr .. "OD" -- Dematerialize
	if not dr_who.tardis:lever_convert(t.t_cufflinks) then
		dr_who:dump("SAFE")
		mlangstr = mlangstr .. "oPs" -- Find the safest spot to land
	elseif t.nx and t.ny and t.nz then
		dr_who:dump("RPOS")
		mlangstr = mlangstr .. "oP" .. ("x" .. t.nx) .. ("y" .. t.ny) .. ("z" .. t.nz)
	else
		dr_who:dump("NOPOS")
		return ""
	end
	if dr_who.tardis:lever_convert(t.e_stab) then
		dr_who:dump("E_STAB")
		mlangstr = mlangstr .. "OE" -- Environment Stabilizer
	end
	mlangstr = mlangstr .. "oG" .. t.g_stab -- Gravity Stabilizer
	mlangstr = mlangstr .. "OM" -- Materialize
	dr_who:dump("STR")
	dr_who:dump(mlangstr)
	return mlangstr
end

function dr_who.tardis.electric:gen_power(pos, matrix_pos)
	function t(pos)
		local meta = minetest.env:get_meta(pos)
		if meta:get_string("done") then
			print("DONE")
			return
		end
		local p = meta:get_string("power")
		meta:set_string("power", tonumber(p) + 10)
		minetest.after(.3, t, pos)
	end
	minetest.after(.3, t, matrix_pos)
end

function dr_who.tardis.electric:run(pos, user)
	local found = false
	local up_down_pos = nil
	local matrix_pos = nil
	local matrix_meta = nil
	local computer_pos = nil
	local computer_meta = nil
	found, up_down_pos = dr_who.tardis.electric:find_node(pos, dr_who.tardis.up_down)
	if not found then return false end
	found, matrix_pos = dr_who.tardis.electric:find_node(pos, dr_who.tardis.matrix.source)
	if not found then return false end
	found, computer_pos = dr_who.tardis.electric:find_node(pos, dr_who.tardis.flight_comp)
	if not found then return false end
	matrix_meta = minetest.env:get_meta(matrix_pos)
	computer_meta = minetest.env:get_meta(computer_pos)
	matrix_meta:set_string("done", false)
	dr_who.tardis.electric:gen_power(up_down_pos, matrix_pos)
	dr_who.tardis.matrix:interpret_mlang(dr_who.tardis.electric:computer_translate_to_mlang(computer_meta:to_table().fields), matrix_pos, user)
	matrix_meta:set_string("done", true)
	return true
end

