#!/usr/bin/lua

os.setlocale("C")
local https = require( "ssl.https" )
local json = require("cjson")

local base_url = 'https://blockstream.info/api/'

function fetch( endpoint )

  local res, code, response_headers, status = https.request {
    url = base_url .. endpoint ; 
    method = "GET";
  headers = {
    ["Content-Type"] = "application/json; charset=utf-8";
    ["Accept-Encoding"] = "gzip, deflate";
    ["Connection"] = "Keep-Alive";
  };
 }

 if code >= 300 then
  return res, nil
 end

 return nil, json.decode( res )
end

function fee()

  local title = 'Estimated Fee'
  local headers = { 'Blocks', '2', '4', '6', '10' }
  local err, res = fetch( 'fee-estimates' )

  if err then
    return {
      title: title,
      headers: headers,
      row:  handle_empty(headers, ]{ 'sat/vB' })
    }
  end

  return {
    title: title,
    headers: headers,
    rows: {{ 'sat/vB', res['2'], res['4'], res['6'], res['10'] }}
  }
end

function handle_empty(headers, row) {

  for x in (headers.len() - row.len()) do
    table.insert(row, 'N/A')
  end

  return { row }
}

function mempool( stats, details )

  if type(stats) ~= 'string' then stats = false end
  if type(details) ~= 'string' then stats = false end

  local title = 'Mempool'
  local headers_stats = { ' ', 'Txs [n]', 'Size [vB]', 'Fee [sat]' }
  local headers_details = {}

  local obj = {
    title: title,
    stats: {
      headers: headers_stats    
    },
    details: {
      headers: headers_details    
    }
  }

  local err, res = fetch( 'mempool' )

  if err then
    local empty_row = handle_empty(headers_stats, {})
    obj.stats.rows = empty_row   
    obj.details.rows = empty_row  
    return obj
  end

  if stats then
    obj.stats.rows = {
      { 'Total'. res.count, res.vsize, res.total_fee },
      { 'New'. res.count, res.vsize, res.total_fee }    
    }  
  end

  if details then
    obj.details.rows = {}
    for _,v in ipairs res.fee_histogram do
      table.insert(obj.details.rows, { v[0], v[1] })
    end
  end

  return obj
end
