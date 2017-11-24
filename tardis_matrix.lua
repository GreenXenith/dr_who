-- Doctor Who mod for Minetest
-- 
-- TARDIS Matrix module

-- Mlang (Matrix Language) reference:
-- O = Instruction
-- o = Set value (sets a meta-string)
-- X = Set value to exterior TARDIS
--
-- Instructions:
-- D = Dematerialize
-- M = Materialize
-- E = Stabilize Environment
--
-- Variables interpreted:
-- P = Set position (use with o), use like this:
--         oPx50y20z60
--     Also can be used like this (for safety):
--         oPs
-- B = Set brakes
-- G = Stabilize Gravity
--
-- Example:
-- ODoPx0y0z0oBOM  <- Dematerializes, sets the position to 0, 0, 0, sets brakes on, and materializes
--
-- or
--
-- ODoPsOM  <- Dematerializes, sets the position to the safest place available (i.e. inside the TARDIS), and then materializes

dr_who.tardis.sound_max_hear_distance = 128.0

dr_who.tardis.matrix = {}

function dr_who.tardis.matrix:P_to_pos(p_str)
	local i = nil
	local c = nil
	local r = {}
	local o = nil
	local a = nil
	for i = 1, #p_str do
		c = p_str:sub(i, i)
		if c == "x" or c == "y" or c == "z" then
			if o then
				r[o] = tonumber(a)
			end
			o = c
			a = ""
		else
			a = a .. c
		end
	end
	if not o or not a or not r.x or not r.y or not r.z then
		return {x=-30000, y=-30000, z=-30000}
	end
	r[o] = tonumber(a)
	return r
end

function dr_who.tardis.matrix:pos_to_P(pos)
	return "x"..pos.x.."y"..pos.y.."z"..pos.z
end

function dr_who.tardis.matrix:convert_safe_pos(pos)
	local meta = minetest.env:get_meta(pos)
	if meta:get_string("P") ~= "s" then
		return
	end
	meta:set_string("P", meta:get_string("safepos"))
end

function dr_who.tardis.matrix:play_breaks_sound(pos, matrix_metat)
	if not matrix_metat.B or not dr_who.tardis:lever_convert(matrix_metat.B) then
		dr_who:dump(matrix_metat)
		return
	end
	local meta = minetest.env:get_meta(pos)
	local metat = meta:to_table().fields	
	if metat.tardis_sound_handle and metat.tardis_sound_handle ~= "nan" then
		minetest.sound_stop(tonumber(metat.tardis_sound_handle))
	end
	meta:set_string("tardis_sound_handle", tostring(minetest.sound_play("tardis", {
		pos = pos,
		gain = 1.0,
		max_hear_distance = dr_who.tardis.sound_max_hear_distance,
		loop = false
	})))
	minetest.after(10, function(m)
		m:set_string("tardis_sound_handle", "nan")
	end, meta)
end

function dr_who.tardis.matrix:can_materialize(pos, ign)
	local i = false
	if ign then
		i = "w/ign"
	end
	local t = dr_who:find_blocks_in_region(pos, {x=2, y=3, z=2}, false, i)
	if table.getn(t) <= 0 then
		return true
	end
	local k = nil
	local v = nil
	local n = 0
	for k, v in ipairs(t) do
		if v.name ~= dr_who.collision_block then
			n = n + 1
		end
	end
	return n <= 0
end

function dr_who.tardis.matrix:stabilize_environment(pos)
	local meta = minetest.env:get_meta(pos)
	dr_who.tardis.matrix:convert_safe_pos(pos)
	local npos = dr_who.tardis.matrix:P_to_pos(meta:get_string("P"))
	local k = nil
	local v = nil
	for k, v in ipairs(dr_who:find_blocks_in_region({x=npos.x, y=npos.y, z=npos.z - 1}, {x=2, y=3, z=2}, false, "all")) do
		minetest.env:remove_node(v.pos)
	end
end

function dr_who.tardis.matrix:fall(origpos)
	local pos = dr_who:copy_table(origpos)
	local npos = dr_who:copy_table(pos)
	local can_fall = dr_who.tardis.matrix:can_materialize(pos, true)
	while can_fall do
		npos = {x=pos.x, y=pos.y - 1, z=pos.z}
		if dr_who.tardis.matrix:can_materialize(npos, true) then
			pos = npos
		else
			can_fall = false
			break
		end
	end
	return pos
end

function dr_who.tardis.matrix:dematerialize(pos)
	local meta = minetest.env:get_meta(pos)
	dr_who.tardis.matrix:convert_safe_pos(pos)
	local npos = dr_who.tardis.matrix:P_to_pos(meta:get_string("P"))
	minetest.env:remove_node(npos)
	dr_who.tardis.matrix:play_breaks_sound(npos, meta:to_table().fields)
end

function dr_who.tardis.matrix:materialize(pos, user)
	local meta = minetest.env:get_meta(pos)
	local metat = meta:to_table().fields
	local safe = false	
	dr_who.tardis.matrix:convert_safe_pos(pos)
	dr_who:dump("NEWPOS: " .. meta:get_string("P"))
	local npos = dr_who.tardis.matrix:P_to_pos(meta:get_string("P"))	
	if not dr_who.tardis.matrix:can_materialize(npos) then
		return false
	end
	if not dr_who.tardis:lever_convert(meta:get_string("G")) then
		npos = dr_who.tardis.matrix:fall(npos)
		meta:set_string("P", dr_who.tardis.matrix:pos_to_P(npos))
	end
	dr_who:dump(npos)
	minetest.env:set_node(npos, {name=dr_who.tardis.box})
	dr_who.tardis.matrix:play_breaks_sound(npos, metat)
	dr_who.tardis.matrix:play_breaks_sound(pos, metat)
	local landing = dr_who.tardis.matrix:P_to_pos(meta:get_string("teleport"))
	local nmeta = minetest.env:get_meta(npos)
	nmeta:set_string("nx", tostring(landing.x))
	nmeta:set_string("ny", tostring(landing.y - 0.5))
	nmeta:set_string("nz", tostring(landing.z))
	nmeta:set_string("owner", user:get_player_name())
	local dmeta = minetest.env:get_meta(dr_who.tardis.matrix:P_to_pos(meta:get_string("door")))
	dmeta:set_string("nx", tostring(npos.x+.5))
	dmeta:set_string("ny", tostring(npos.y-.5))
	dmeta:set_string("nz", tostring(npos.z-1))
end

function dr_who.tardis.matrix:interpret_mlang(mlangstr, pos, user)
	local i = nil
	local c = nil
	local lc = nil
	local oper = nil
	local soper = nil
	local args = nil
	local meta = minetest.env:get_meta(pos)
	-- Dummy values, used on my server. Will be variable later ;)
	meta:set_string("teleport", "x-129y43z14")
	meta:set_string("door", "x-129y43z13")
	meta:set_string("safepos", "x-133y43z20")
	mlangstr = mlangstr .. "O"
	for i = 1, #mlangstr do
		c = mlangstr:sub(i, i)
		if c == "O" or c == "o" or c == "X" then
			if oper and soper then
				if oper == "o" then
					meta:set_string(soper, args or dr_who.tardis.lever_true)
					print(soper .. args)
				elseif oper == "X" then
					local meta2 = minetest.env:get_meta(dr_who.tardis.matrix:P_to_pos(meta:get_string("P")))
					meta2:set_string(soper, args or dr_who.tardis.lever_true)
					print("EX: " .. soper .. args)
					dr_who:dump(meta:get_string("P"))
					dr_who:dump(meta2:to_table())
				elseif oper == "O" then
					if soper == "D" then
						dr_who.tardis.matrix:dematerialize(pos)
					elseif soper == "E" then
						dr_who.tardis.matrix:stabilize_environment(pos)
					elseif soper == "M" then
						dr_who.tardis.matrix:materialize(pos, user)
					end
				end
			end
			oper = c
			soper = nil
			args = ""
		elseif oper and not soper then
			soper = c
		elseif oper and soper then
			args = args .. c
		else
			print("ERROR")
			dr_who:dump(lc..c)
			return
		end
		lc = c
	end
end

dr_who.tardis.matrix.source, dr_who.tardis.matrix.flowing = dr_who:register_liquid(dr_who.tardis:gen_name("matrix"), {
	description = "Matrix",
	inventory_image = minetest.inventorycube("tardis_matrix.png"),
	tiles = {"tardis_matrix.png"},
	alpha = 230,
	paramtype = "light",
	liquid_viscosity = 1,
	post_effect_color = {a = 200, r = 200, g = 200, b = 200},
	light_source = LIGHT_MAX
})

dr_who.tardis.matrix.protector = dr_who:register_node(dr_who.tardis:gen_name("matrix_protector"), {
	description = "Matrix Protector",
	sunlight_propagates = true,
	paramtype = "light",
	walkable = true,
	groups = {cracky = 2},
	tiles = {"tardis_matrix_protector.png"},
	light_source = 13
})

