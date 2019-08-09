#!/usr/bin/lua

os.setlocale("C")

local http = require( "ssl.https" )
local json = require("cjson")
-- local blockstream = require('./btc_chain')

function conky_get_ip()

	local ip, code, headers, status = http.request( "https://api.ipify.org/" )

	if ip then
		local geo = geo_ip( ip )
		if type(geo) ~= 'string' then geo = '??' end
		return ip .. ' [ ' .. geo  .. ' ]'
	else
		return code
	end
end

function geo_ip( ip )

	return read_cmd( "geoiplookup " .. ip )
end

function read_cmd( cmd )

	local result
	local pipe = io.popen( cmd )
	local response = pipe:read()
	pipe:close()

	if (response ~= 'GeoIP Country Edition: IP Address not found') then
		result = response:match "%b:,":gsub(": ", ""):gsub(",", "")
	end

	return result
end


function conky_pad( number )

	return string.format( '%3i' , conky_parse( number ) )
end

function get_high(price, high)

 	if type(high) == 'string' then 
		return 0 - tonumber(price) / tonumber(high) * 100
	else
		return 	0
	end
end

function format_price( price )
	return price:sub(1,7)
end 

function format_variation( x, decimals, period, currency )
	
	local foo, color
	if ( type(x) == 'string' ) then
		local formatter = "%." .. decimals .. "f"
		foo = string.format(formatter, tonumber(x) * 100)
		if (foo:sub(1,1) == '-') then
			color = '${color red}'
		else 
			color = '${color green}'
		end
		foo = foo:gsub('-','')
	else
		foo = '0.00'
		color = '${color white}'
	end
	local white_string = ''
	local n = 0
	local loops = 6 - string.len( foo )
	repeat
		white_string = white_string .. '  '
		n = n + 1
	until (n >= loops )

	return color .. white_string .. foo ..  '${color}'
end


function format_ath( x, decimals )
	local formatter = "%." .. decimals .. "f"
	local foo = string.format(formatter, tonumber(x))
	foo = foo:gsub('-','')
	local white_string = ''
	local n = 0
	local loops = 6 - string.len( foo )
	repeat
		white_string = white_string .. '  '
		n = n + 1
	until (n >= loops )
	return white_string .. foo
end


function conky_crypto_market( limit )

	if ( type(limit) ~= 'string' ) then limit = '15' end

	local api_url = "https://nomics.com/data/currencies/ticker?interval=1d,7d,30d,365d&limit=" ..
		limit ..
		"&quote-currency=USD&sort-by=2&sort-direction=1&start=0"

	local body, code, headers, status = http.request(api_url)

	local results = '${font LCDMono:normal:size=8}'

	if body then
		local currencies = json.decode(body).items

		results = "${font LCDMono:normal:size=9}${goto 80}USD${goto 145}1D${goto 205}7D${goto 255}30D${goto 310}365D${alignr}ATH\n${stippled_hr}\n"

		for _,obj in ipairs(currencies) do 
			results = results ..
				obj.currency ..
				'${goto 60}' .. format_price(obj.price) ..
				'${goto 125}' .. format_variation( obj['1d']['price_change_pct'], 2 , '1d', obj.currency) ..
				'${goto 185}' .. format_variation( obj['7d']['price_change_pct'], 2, '7d') ..
				'${goto 245}' .. format_variation( obj['30d']['price_change_pct'], 2, '30d' ) ..
				'${goto 305}' .. format_variation( obj['365d']['price_change_pct'], 2, '365d') ..
				'${alignr}' .. format_ath( get_high(obj.price, obj.high), 2 ) ..
				'\n'
		end
	else 
		results = status
	end
	return results
end
-- cairo_show_text (cr,results)
-- cairo_stroke (cr)
--  lua_draw_hook_pre = 'crypto_market',

-- OS $alignr ${exec lsb_release -d | cut -f 2| tr "[:upper:]" "[:lower:]"}
-- KERNEL $alignr ${no_update $sysname} ${no_update $kernel}
-- ARCHITECTURE $alignr ${no_update $machine}
-- CPU $alignr ${no_update ${execi 1000 grep model /proc/cpuinfo | cut -d : -f2 | cut -c19-40 | tail -1 | sed 's/\s//'}}



function conky_top_processes( loops )

	local n = 1
	local response = 'TOP CPU PROCESSES ${goto 310} CPU ${alignr}MEM\n${stippled_hr}\n'
	repeat
		response = response .. '${top name ' .. n .. '} ${goto 310}${top cpu ' .. n .. '} $alignr ${top mem ' .. n .. '}\n'
		n = n + 1
	until (n > tonumber(loops) )
	return response
end
-- NAME ${goto 255} PID ${goto 310} CPU ${alignr}MEM
-- ${top name 1} ${goto 255}${top pid 1} ${goto 310}${top cpu 1} $alignr ${top mem 1}
