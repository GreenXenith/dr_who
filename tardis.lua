-- Doctor Who mod for Minetest
-- 
-- TARDIS module

dr_who.tardis = {}

dr_who.tardis.mod_prefix = "tardis"

function dr_who.tardis:gen_name(n)
	return dr_who:gen_name(dr_who.tardis.mod_prefix .. "_" .. n)
end

dr_who.tardis.box = dr_who:register_node(dr_who.tardis:gen_name("box"), {
	drawtype = "nodebox",
	description = "TARDIS",
	sunlight_propagates = false,
	paramtype = "light",
	paramtype2 = "facedir",
	walkable = true,
	tiles = {"tardis_bottom.png", "tardis_bottom.png", "tardis_front.png", "tardis_front.png", "tardis_front.png", "tardis_front.png"},	
	node_box = {
		type = "fixed",
		fixed = {
				{ -0.5, -0.5, -0.5, 1.5, 2.5, 1.5 },
				{ 0.25, 2.5, 0.25, 0.75, 3, 0.75 }
			}
	},
	on_construct = function(pos)
		dr_who:gen_collision_box(pos, {x=2, y=3, z=2})
	end,
	after_place_node = function(pos, user, itemstack)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("owner", user)
	end,
	on_destruct = function(pos)
		dr_who:gen_collision_box(pos, {x=2, y=3, z=2}, true)
	end,
	on_punch = function(pos, node, user)
		if user == nil then
			return
		end
		local meta = minetest.env:get_meta(pos):to_table().fields
		dr_who:dump(meta)
		if meta.owner and meta.L and dr_who.tardis:lever_convert(meta.L) and user == meta.owner then
			return
		end
		if meta.nx and meta.ny and meta.nz then
			user:setpos({x=tonumber(meta.nx), y=tonumber(meta.ny), z=tonumber(meta.nz)})
		end
	end
})

dr_who.tardis.door = dr_who:register_node(dr_who.tardis:gen_name("door"), {
	drawtype = "nodebox",
	description = "TARDIS Interior door",
	sunlight_propatages = false,
	paramtype = "light",
	paramtype2 = "facedir",
	walkable = true,
	node_box = {
		type = "fixed",
		fixed = {
				{-0.5, -0.5, 0.4, 0.5, 2.5, 0.5 }
			}
	},
	groups = {cracky = 1},
	on_punch = function(pos, node, user)
		dr_who:dump(pos)
		local meta = minetest.env:get_meta(pos):to_table().fields
		if meta.nx and meta.ny and meta.nz then
			user:setpos({x=tonumber(meta.nx), y=tonumber(meta.ny), z=tonumber(meta.nz)})
		end
	end
})

dr_who.tardis.up_down = dr_who:register_node(dr_who.tardis:gen_name("up_down_thingy"), {
	drawtype = "nodebox",
	description = "Uppy-Downy-Timey-Wimey thingy",
	sunlight_propagates = true,
	paramtype = "light",
	walkable = true,
	tiles = {"nonexistant.png"},
	groups = {cracky = 3},
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.5, -0.5, -0.5, 1.5, 8.5, 1.5 }
		}
	},
	light_source = 13
})

dr_who.tardis.lever_def = {
	drawtype = "nodebox",
	description = "Lever",
	sunlight_propagates = true,
	paramtype = "light",
	paramtype2 = "facedir",
	walkable = true,
	tiles = {"nonexistant.png"},
	groups = {cracky = 3},
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.2, -0.4, 0.25, 0.2, 0.4, 0.5 },
			{ -0.1, -0.1, 0.1, 0.1, 0.1, 0.25 }
		}
	}
}

function dr_who.tardis:lever_convert(tfs)
	if type(tfs) == "string" then
		if tfs == "true" or tfs == "on" or tfs == "yes" then
			return true
		elseif tfs == "false" or tfs == "off" or tfs == "no" then
			return false
		else
			return nil
		end
	else
		if tfs then
			return "true"
		else
			return "false"
		end
	end
end
dr_who.tardis.lever_true = dr_who.tardis:lever_convert(true)
dr_who.tardis.lever_false = dr_who.tardis:lever_convert(false)
dr_who.tardis.true_str = dr_who.tardis:lever_convert(true)
dr_who.tardis.false_str = dr_who.tardis:lever_convert(false)

function dr_who.tardis:lever_get_state(name)
	if string.find(name, "off", -4) then
		return false
	elseif string.find(name, "on", -3) then
		return true
	end
	return nil
end

function dr_who.tardis:lever_set_on(pos, tf)
	local name = minetest.env:get_node(pos).name
	local off = ""
	local on = ""
	if string.find(name, "off", -4) then
		off = name
		on = string.sub(name, 1, -4)
		on = on.."on"
	else
		on = name
		off = string.sub(name, 1, -3)
		off = off.."off"
	end
	local meta = minetest.env:get_meta(pos)
	if tf then
		dr_who:swap_node(pos, on)
		meta:set_string("checked", dr_who.tardis:lever_convert(true))
	else
		dr_who:swap_node(pos, off)
		meta:set_string("checked", dr_who.tardis:lever_convert(false))
	end
	local t = {}
	t[meta:get_string("name")] = meta:get_string("checked")
	dr_who:dump(dr_who.tardis.electric:send_data_to_computer(pos, t))
end

function dr_who.tardis:new_lever(name, desc, punch)
	if not punch then
		punch = function() end
	end
	local p = dr_who.tardis:gen_name("lever_"..name.."_")
	local on = p.."on"
	local off = p.."off"
	d = dr_who:copy_table(dr_who.tardis.lever_def)
	dr_who:dump(d)
	d.description = desc
	d.on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("checked", false)
		meta:set_string("name", name)
		meta:set_string("infotext", desc)
	end
	d.on_punch = function(pos, node, user)
		dr_who.tardis:lever_set_on(pos, true)
		punch(pos, node, user, true)
	end
	dr_who:register_node(off, dr_who:copy_table(d))
	d.node_box.fixed[2] = { -0.1, -0.1, 0.15, 0.1, 0.1, 0.25 }
	d.light_source = 13
	d.on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("checked", true)
		meta:set_string("name", name)
		meta:set_string("infotext", desc)
	end
	d.on_punch = function(pos, node, user)
		dr_who.tardis:lever_set_on(pos, false)
		punch(pos, node, user, false)
	end
	dr_who:register_node(on, d)
	return off, on
end

dr_who.tardis.levers = {}

dr_who.tardis.levers.brakes_off, dr_who.tardis.levers.brakes_on = dr_who.tardis:new_lever("brakes", "Brakes")
dr_who.tardis.levers.shields_off, dr_who.tardis.levers.shields_on = dr_who.tardis:new_lever("shields", "Shields")
dr_who.tardis.levers.g_stab_off, dr_who.tardis.levers.g_stab_on = dr_who.tardis:new_lever("g_stab", "Gravity Stabilizer")
dr_who.tardis.levers.e_stab_off, dr_who.tardis.levers.e_stab_on = dr_who.tardis:new_lever("e_stab", "Environment Stabilizer")
dr_who.tardis.levers.ready_off, dr_who.tardis.levers.ready_on = dr_who.tardis:new_lever("ready", "Ready?", function(p, n, u)
	print("RUNNING")
	dr_who:dump(dr_who.tardis.electric:run(p, u))
	minetest.after(.5, function(p) dr_who.tardis:lever_set_on(p, false) end, p)
end)
dr_who.tardis.levers.t_cufflinks_off, dr_who.tardis.levers.t_cufflinks_on = dr_who.tardis:new_lever("t_cufflinks", "Thermal Cufflinks")
dr_who.tardis.levers.lock_off, dr_who.tardis.levers.lock_on = dr_who.tardis:new_lever("lock", "Lock", function(p, n, u, s)
	local st = "XL"
	if not s then
		print("UNLOCKING")
		st = st .. dr_who.tardis.lever_false
	else
		print("LOCKING")
		st = st .. dr_who.tardis.lever_true
	end
	dr_who.tardis.electric:send_data_to_matrix(p, st, u)
end)

dr_who.tardis.f_c = dr_who:register_node(dr_who.tardis:gen_name("f_c"), {
	drawtype = "nodebox",
	description = "Flight Controller",
	sunlight_propagates = true,
	paramtype = "light",
	paramtype2 = "facedir",
	walkable = true,
	groups = {snappy = 3},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, 0.4, 0.5, 0.5, 0.5 }
		}
	},
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("formspec", "size[3,5]"..
						"label[0,1;X:]field[1,1;2,1;nx;;${nx}]"..
						"label[0,2;Y:]field[1,2;2,1;ny;;${ny}]"..
						"label[0,3;Z:]field[1,3;2,1;nz;;${nz}]"..
						"button_exit[0,4;3,1;exit;Set]")
		meta:set_string("infotext", "Flight Controller")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.env:get_meta(pos)
		fields.nx = fields.nx or ""
		fields.ny = fields.ny or ""
		fields.nz = fields.nz or ""
		meta:set_string("nx", fields.nx)
		meta:set_string("ny", fields.ny)
		meta:set_string("nz", fields.nz)
		print("SETTING FIELDS")
		dr_who:dump(dr_who.tardis.electric:send_data_to_computer(pos, {nx = fields.nx, ny = fields.ny, nz = fields.nz}))
	end
})

dr_who.tardis.flight_comp = dr_who:register_node(dr_who.tardis:gen_name("flight_comp"), {
	drawtype = "nodebox",
	description = "Flight Computer",
	sunlight_propagates = false,
	walkable = true,
	groups = {cracky=2},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 1.5, 0.5, 1.5}
		}
	}
})

dr_who.tardis.eye_block = dr_who:register_node(dr_who.tardis:gen_name("eye_block"), {
	description = "Eyeblock",
	sunlight_propagates = false,
	walkable = true,
	tiles = {"tardis_eye_block.png"},
	groups = {cracky = 2},
	light_source = 11
})

dr_who.tardis.console_block = dr_who:register_node(dr_who.tardis:gen_name("console_block"), {
	description = "Console block",
	sunlight_propagates = false,
	walkable = true,
	tiles = {"tardis_console_block.png"},
	groups = {cracky = 2},
	light_source = 12
})

require("tardis_matrix")
require("tardis_electric")

