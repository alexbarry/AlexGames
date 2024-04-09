local draw_celebration_anim = {}

local alexgames = require("alexgames")

local function get_random_fireworks_colour(is_fill)
	local fills = {
		"#fd7678",
		"#76fd78",
		"#7676fd",
		"#fd76fd",
		"#fdfd76",
		"#76fdfd",
		"#fdfdfd",
	}
	return fills[math.random(1,#fills)]
end

local function get_brightness_func(state, particle)
	local brightness = 255
	local time_threshold = state.params.anim_time*0.3
	if state.t >= time_threshold then
		brightness = math.floor(brightness*(state.params.anim_time - state.t)/(state.params.anim_time - time_threshold))
	end

	if brightness < 0 then return 0 end
	return brightness
end

local function firework_explosion(state, params)
	for i=1,params.particle_count do
		local angle = i*2*math.pi / params.particle_count
		local update_pos_func = function (state, particle, dt)
			local speed = (1 - state.t/params.anim_time + 0.2) * params.init_speed
			local y_vel = math.cos(angle + state.params.rotation) * speed
			local x_vel = math.sin(angle + state.params.rotation) * speed
			particle.y_vel_lost_due_to_gravity = particle.y_vel_lost_due_to_gravity + state.gravity * dt
			particle.vel_lost_due_to_drag = particle.vel_lost_due_to_drag + state.params.drag * dt
			y_vel = y_vel + particle.y_vel_lost_due_to_gravity
			y_vel = y_vel / particle.vel_lost_due_to_drag
			x_vel = x_vel / particle.vel_lost_due_to_drag
			local dy = y_vel * dt
			local dx = x_vel * dt
			particle.y = particle.y + dy
			particle.x = particle.x + dx

			if state.frame_idx % state.params.line_update_frame_interval == 0 and state.frame_idx ~= 0 then
				local line_info = {
					y1 = particle.prev_snapshot_pos.y,
					x1 = particle.prev_snapshot_pos.x,
					y2 = particle.y,
					x2 = particle.x,
					colour = state.params.colour_fill,
				}
				table.insert(particle.lines, line_info)
				while #particle.lines >= state.params.max_lines_per_particle do
					table.remove(particle.lines, 1)
				end
				particle.prev_snapshot_pos = { y = particle.y, x = particle.x }
			end
			
		end
		table.insert(state.particles, {
			update_pos_func = update_pos_func,
			y = params.start_y,
			x = params.start_x,
			get_brightness_func = get_brightness_func,
			radius = params.particle_radius,
			centre_radius = params.centre_radius,

			y_vel_lost_due_to_gravity = 0,
			vel_lost_due_to_drag = 0,
			angle = angle,


			lines = {},
			prev_snapshot_pos = { y = params.start_y, x = params.start_x },
		})
	end
end

local function get_line_colour(state, particle, idx, colour)
	--idx = state.params.max_lines_per_particle - idx + 1
	local brightness = particle.get_brightness_func(state, particle)
	local threshold_idx = state.params.line_brightness_threshold_idx
	if idx < threshold_idx then
		brightness = math.floor(brightness*(idx)/(threshold_idx))
	end
	return string.format("%s%02x", colour, brightness)
end

local function draw_firework_state(state)

	for _, particle in ipairs(state.particles) do
		for line_segment_idx, line_info in ipairs(particle.lines) do
			--print(string.format("line_info: %s %s %s %s", line_info.y1, line_info.x1, line_info.y2, line_info.x2))
			alexgames.draw_line(get_line_colour(state, particle, line_segment_idx, line_info.colour), state.params.line_width,
			                     line_info.y1, line_info.x1,
			                     line_info.y2, line_info.x2)
		end


		local start = {
			y = state.params.start_y,
			x = state.params.start_x,
		}
		if #particle.lines > 0 then
			start.y = particle.lines[#particle.lines].y1
			start.x = particle.lines[#particle.lines].x1
		end

		alexgames.draw_line(get_line_colour(state, particle, #particle.lines, state.params.colour_fill), state.params.line_width,
		                     start.y, start.x,
		                     particle.y, particle.x)


		--[[
		alexgames.draw_circle(state.params.colour_fill,
		                       state.params.colour_outline,
		                       particle.y, particle.x,
		                       state.params.particle_radius)
		alexgames.draw_circle(state.params.fill_centre,
		                       state.colour_outline,
		                       particle.y, particle.x,
		                       state.params.centre_radius)
		--]]
	end
end



function draw_celebration_anim.new_fireworks_state(params)
	local update_state_func = function (state, dt)
		if dt == 0 then return end
		--print("update_state_func: firework")

		if state.time_to_explosion <= 0 then
			if not state.detonated then
				firework_explosion(state, params)
				state.detonated = true
			end
			if state.time_remaining > 0 then
				state.t = state.t + dt
				state.frame_idx = state.frame_idx + 1
				state.time_remaining = state.time_remaining - dt

				for _, particle in ipairs(state.particles) do
					particle.update_pos_func(state, particle, dt)
				end
			else
				state.particles = {}
			end
		else
			state.time_to_explosion = state.time_to_explosion - dt
		end
	end
	local state = {
		params = params,
		detonated = false,
		time_to_explosion = params.time_to_explosion,
		gravity = params.gravity,
		lines = {},
		particles = {},
		update_state_func = update_state_func,
		draw = draw_firework_state,

		time_remaining = params.anim_time,
		colour_outline = params.colour_outline,
		t = 0,
		frame_idx = 0,
		on_finish = params.on_finish,
	}
	return state
end

function draw_celebration_anim.update_anim(state, dt)
	state.update_state_func(state, dt)
end

function draw_celebration_anim.new_state(params)
	local anim_state = {
		anims = {},
		on_finish = params.on_finish
	}
	return anim_state
end

function draw_celebration_anim.fireworks_display(anim_state, params)
	local max_anim_time = nil
	for i=1,20 do
		local size = math.random(3, 15)
		local anim_time = 1 + (3-1)*math.random()
		local firework_state = draw_celebration_anim.new_fireworks_state({
			--start_y = 240,
			--start_x = 240,
			start_y = math.random(20, 480-100),
			start_x = math.random(20, 480-100),
			gravity = 50,
			drag    = 0.9,
			init_speed = size,
			--time_to_explosion = math.random(0, 1),
			time_to_explosion = math.random(),
		
			--line_width = math.random(1,math.max(1,math.floor(size/50*5))),
			line_width = 2,
		
			particle_count = math.max(math.min(size,20),6),
			--particle_color = "#ffeeee",
			--particle_fill  = "#ffeeee",
			--colour_fill    = "#fd7678",
			colour_fill = get_random_fireworks_colour(),
			rotation = math.random()*2*math.pi,
			colour_outline = "#ffffff00",
			colour_fill_centre = "ffffff",
			fill_centre    = "#ffffff",
			--radius = 0.1 + math.random(0, 400),
			anim_time = anim_time,
			--anim_time = 0.5 + 1.0*math.random(),
		
			centre_radius   = 1,
			particle_radius = 5,
			max_lines_per_particle = 20,
			line_brightness_threshold_idx = 3,
			line_update_frame_interval = 5,

		})
		if max_anim_time == nil or max_anim_time < anim_time then
			max_anim_time = anim_time
		end
		table.insert(anim_state.anims, firework_state)
	end

	-- TODO I don't really like this ...
	-- the fireworks animation is actually animated separately per firework.
	-- I want a callback when they all finish.
	-- But I want a new callback for each fireworks animation.
	-- Perhaps it would make sense to add a single big "multiple fireworks" anim,
	-- which itself loops through each individual firework.
	if params ~= nil and params.on_finish ~= nil then
		anim_state.on_finish = params.on_finish
	end

	-- it's hard to see the light fireworks on a light screen, so add
	-- a black backdrop that fades away
	local colour_pref
	if params ~= nil then
		colour_pref = params.colour_pref
	end
	if colour_pref == nil then
		colour_pref = alexgames.get_user_colour_pref()
	end
	if not colour_pref or colour_pref == "light" then
		local backdrop_state = {
			anim_time = max_anim_time,
			time_remaining = max_anim_time,
			update_state_func = function (anim_state, dt)
				anim_state.time_remaining = anim_state.time_remaining - dt
				local threshold = anim_state.anim_time/2
				local init_brightness = 196
				anim_state.brightness = init_brightness
				if anim_state.time_remaining < threshold then
					anim_state.brightness = math.floor(init_brightness * (1 - (threshold - anim_state.time_remaining)/(anim_state.anim_time - threshold)))
				end
			end,
			draw = function (anim_state)
				local colour = string.format('#000000%02x', anim_state.brightness)
				alexgames.draw_rect(colour, 0, 0, 480, 480)
			end,
	
			brightness = 100,
		}
		table.insert(anim_state.anims, 1, backdrop_state)
	end
end

function draw_celebration_anim.draw(anim_state)
	for _, anim in ipairs(anim_state.anims) do
		anim.draw(anim)
	end
end

-- TODO change this to accept dt_ms
function draw_celebration_anim.update(anim_state, dt)
	--print(string.format("draw_celebration_anim.update called, %d anims", #anim_state.anims))

	if #anim_state.anims == 0 then
		return
	end

	for _, anim in ipairs(anim_state.anims) do
		anim.update_state_func(anim, dt)
	end

	local i = 1
	while i <= #anim_state.anims do
		--print("anim %d, time_remaining is: %s", i, anim_state.anims[i].time_remaining)
		if anim_state.anims[i].time_remaining <= 0 then
			print("anim finished", i)
			table.remove(anim_state.anims, i)
		else
			i = i + 1
		end
	end

	print(string.format("anim_state.anims remaining: %d", #anim_state.anims))
	if #anim_state.anims == 0 then
		print("anims finished")
		if anim_state.on_finish then
			print("calling anims finished")
			anim_state.on_finish()
		end

	end
end


return draw_celebration_anim
