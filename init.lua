-- Doctor Who mod for Minetest
-- 
-- Base module

dr_who = {}

dr_who.modpath = minetest.get_modpath("dr_who")
dr_who.mod_prefix = "dr_who"

function dr_who:gen_name(n)
	return dr_who.mod_prefix .. ":" .. n
end

function dr_who:flatten_array(arr)
	l = {min=0, max=0}
	for i, v in ipairs(arr) do
		if v < l.min
		then
			l.min = v
		end
		if v > l.max
		then
			l.max = v
		end
	end
	return l
end

function dr_who:roundup(n)
	if (n - math.floor(n)) == 0
	then
		return n
	else
		return math.floor(n) + 1
	end
end

function dr_who:toboolean(v)
	return not not v -- Quickest way?
end

function dr_who:copy_table(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[dr_who:copy_table(orig_key)] = dr_who:copy_table(orig_value)
		end
		setmetatable(copy, dr_who:copy_table(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

function dr_who:stringify(o, pretty)
	local d = ""
	if pretty then
		d = "\n"
	end
	if type(o) == 'table' then
		local s = '{'..d
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..dr_who:stringify(k, false)..'"' end
			s = s .. '['..k..'] = ' .. dr_who:stringify(v, true) .. ','..d
		end
		return s .. '}'
	else
		return tostring(dr_who:copy_table(o))
	end
end

function dr_who:dump(o)
	print(dr_who:stringify(o, true))
end

function dr_who:extend_table(orig, more)
	for k,v in pairs(more) do
		orig[k] = v
	end
	return orig -- Return a copy
end

function dr_who:search_table(i, t)
	for k,x in ipairs(t) do
		if x == i then
			return k
		end
	end
	return nil
end

function dr_who:register_node(n, d)
	if d.drawtype == "nodebox" then
		d.selection_box = d.node_box
	end
	minetest.register_node(n, d)
	return n
end

dr_who.collision_block = dr_who:register_node(dr_who:gen_name("collision_block"), {
	drawtype = "airlike", -- Invisible
	paramtype = "light",
	pointable = true,
	diggable = true,
	groups = {cracky=3},
	sunlight_propagates = true,
	walkable = true -- For collision
})

function dr_who:find_blocks_in_region(pos, size, invert, opt)
	local x = nil
	local y = nil
	local z = nil
	local p = nil
	local o = nil
	local r = nil
	local on = nil
	local nb = nil
	local nodes = {}
	local i = 1
	for x = pos.x, pos.x + size.x - 1 do
		for y = pos.y, pos.y + size.y - 1 do
			for z = pos.z, pos.z + size.z - 1 do
				p = {x=x, y=y, z=z}
				o = minetest.env:get_node(p)
				on = o.name
				r = minetest.registered_nodes[on]
				nb = (on == "air" or (on == "ignore" and opt ~= "w/ign") or r.buildable_to or r.walkable == false)
				if opt == "all" or (not invert and on == "ignore" and opt == "w/ign") or (invert and nb) or (not invert and not nb) then
					nodes[i] = {name=on, pos=p}
					i = i + 1
				end
			end
		end
	end
	return nodes
end

function dr_who:gen_collision_box(pos, size, clear)
	local k = nil
	local v = nil
	for k, v in ipairs(dr_who:find_blocks_in_region(pos, size, not clear)) do
		if clear and v.name == dr_who.collision_block then
			minetest.env:remove_node(v.pos)
		elseif not clear then
			minetest.env:set_node(v.pos, {name=dr_who.collision_block})
		end
	end
end

function dr_who:register_liquid(n, d)
	-- Names
	local f = "" .. n .. "_flowing"
	local s = n
	d.special_tiles = {
		{name = d.tiles[1], backface_culling = false}
	}
	d.walkable = d.walkable or false
	d.pointable = d.pointable or false
	d.diggable = d.diggable or false
	if d.buildable_to == nil then
		d.buildable_to = true
	end
	d.groups = {liquid=3}
	d.liquid_alternative_flowing = f
	d.liquid_alternative_source = s
	-- Source
	d.drawtype = "liquid"
	d.liquidtype = "source"
	print("Source:")
	dr_who:dump(d)
	dr_who:register_node(s, dr_who:copy_table(d))
	-- Flowing
	d.drawtype = "flowingliquid"
	d.special_tiles[2] = {name = d.tiles[1], backface_culling = true}
	d.liquidtype = "flowing"
	print("Flowing:")
	dr_who:dump(d)
	dr_who:register_node(f, d)
	return s, f
end

function dr_who:swap_node(pos, name)
	local node = minetest.env:get_node(pos)
	--local data = minetest.env:get_meta(pos):to_table()
	--dr_who:dump(data)
	node.name = name
	minetest.env:add_node(pos, node)
	--minetest.env:get_meta(pos):from_table(data)
end

minetest.register_privilege("timelord", {
	description = "Timelord",
	give_to_singleplayer = false
})


minetest.register_craftitem(dr_who:gen_name("timelord_watch"), {
	description = "Timelord Watch",
	wield_image = "timelord_watch.png",
	inventory_image = "timelord_watch.png",
	visual = "sprite",
	physical = true,
	textures = {"timelord_watch.png"},
	on_use = function(itemstack, user, pointed)	
		minetest.set_player_privs(user:get_player_name(), {timelord = true})
	end
})

package.path = dr_who.modpath.."/?.lua;"..package.path
require("tardis")

