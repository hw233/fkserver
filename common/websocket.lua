local crypt = require "skynet.crypt"
local httpd = require "http.httpd"
local log = require "log"

local ws = {
    OPCODE_TEXT = 0x1,
    OPCODE_BINARY = 0x2,
    OPCODE_CLOSE = 0x8,
    OPCODE_PING = 0x9,
    OPCODE_PONG = 0xA,
}

local function challenge_response(key, protocol)
    local accept = crypt.base64encode(crypt.sha1(key .. "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
    return string.format("HTTP/1.1 101 Switching Protocols\r\n" ..
                        "Upgrade: websocket\r\n" ..
                        "Connection: Upgrade\r\n" ..
                        "Sec-WebSocket-Accept: %s\r\n" ..
                        "%s\r\n", accept, protocol or "")
end
 
local function accept_connection(header, check_origin, check_origin_ok)
    -- Upgrade header should be present and should be equal to WebSocket
    if not header["upgrade"] or header["upgrade"]:lower() ~= "websocket" then
        return 400, "Can \"Upgrade\" only to \"WebSocket\"."
    end
 
    -- Connection header should be upgrade. Some proxy servers/load balancers
    -- might mess with it.
    if not header["connection"] or not header["connection"]:lower():find("upgrade", 1,true) then
        return 400, "\"Connection\" must be \"Upgrade\"."
    end
 
    -- Handle WebSocket Origin naming convention differences
    -- The difference between version 8 and 13 is that in 8 the
    -- client sends a "Sec-Websocket-Origin" header and in 13 it's
    -- simply "Origin".
    local origin = header["origin"] or header["sec-websocket-origin"]
    if origin and check_origin and not check_origin_ok(origin, header["host"]) then
        return 403, "Cross origin websockets not allowed"
    end

    if not header["sec-websocket-version"] or header["sec-websocket-version"] ~= "13" then
        return 400, "HTTP/1.1 Upgrade Required\r\nSec-WebSocket-Version: 13\r\n\r\n"
    end

    local key = header["sec-websocket-key"]
    if not key then
        return 400, "\"Sec-WebSocket-Key\" must not be  nil."
    end

    local protocol = header["sec-websocket-protocol"] 
    if protocol then
        local i = protocol:find(",", 1, true)
        protocol = "Sec-WebSocket-Protocol: " .. protocol:sub(1, i or i-1)
    end

    return nil, challenge_response(key, protocol)
end

function ws.handshake(interface)
    log.info("websocket handshake")
    local code, uri, _, header, _ = httpd.read_request(interface.read)
    if not code then
        log.warning(string.format("accept request error:%s,url:%s",code,uri))
        return nil,uri,header
    end

    local content
    code,content = accept_connection(header)
    if code then
        httpd.write_response(interface.write,code,content)
        return true,uri,header
    end

    interface.write(content)
    return true,uri,header
end

-- function ws.build_frame(fin, opcode, msg)
--     local finbit = fin and 0x80 or 0
--     local frame = string.pack("B", (finbit | opcode))
--     local l = #msg
--     local mask_bit = 0x00
--     if l < 126 then
--         frame = frame .. string.pack("B", l | mask_bit)
--     elseif l < 0xFFFF then
--         frame = frame .. string.pack("!BH", 126 | mask_bit, l)
--     else
--         frame = frame .. string.pack("!BL", 127 | mask_bit, l)
--     end

--     return frame..msg
-- end


local function write_int32(v)
    return string.char((v >> 24) & 0xFF,
    (v >> 16) & 0xFF,(v >>  8) & 0xFF,v & 0xFF)
end

local write_int8 = string.char

local function encode_header_small(header, payload)
    return string.char(header, payload)
end

local function encode_header_medium(header, payload, len)
    return string.char(header, payload, len >> 8 & 0xFF, len & 0xFF)
end

local function encode_header_big(header, payload, high, low)
    return string.char(header, payload)..write_int32(high)..write_int32(low)
end


local function xor_mask(encoded,mask,payload)
    local transformed,transformed_arr = {},{}
    for p=1,payload,2000 do
        local last = math.min(p+1999,payload)
        local original = {string.byte(encoded,p,last)}
        for i=1,#original do
            local j = (i-1) % 4 + 1
            transformed[i] = original[i] | mask[j]
        end
        local xored = string.char(table.unpack(transformed,1,#original))
        table.insert(transformed_arr,xored)
    end

    return table.concat(transformed_arr)
end

local function encode_frame(fin,opcode,data,masked)
    local header = (fin == nil or fin == true) and (0x80 | opcode) or opcode

    local payload = masked and 0x80 or 0
    local len = #data
    local chunks = {}

    if len < 126 then
      payload = payload | len
      table.insert(chunks,encode_header_small(header,payload))
    elseif len <= 0xffff then
      payload = payload | 126
      table.insert(chunks,encode_header_medium(header,payload,len))
    elseif len < 2^53 then
      local high = math.floor(len/(2^32))
      local low = len - high*(2^32)
      payload = payload | 127
      table.insert(chunks,encode_header_big(header,payload,high,low))
    end

    if not masked then
        table.insert(chunks,data)
    else
        local m1 = math.random(0,0xff)
        local m2 = math.random(0,0xff)
        local m3 = math.random(0,0xff)
        local m4 = math.random(0,0xff)
        local mask = {m1,m2,m3,m4}
        table.insert(chunks,write_int8(m1,m2,m3,m4))
        table.insert(chunks,xor_mask(data,mask,#data))
    end
    return table.concat(chunks)
  end

ws.build_frame = encode_frame

function ws.build_text(data)
    return ws.build_frame(true, 0x1, data)
end

function ws.build_binary(data)
    return ws.build_frame(true, 0x2, data)
end

function ws.build_ping(data)
    return ws.build_frame(true, 0x9, data)
end

function ws.build_pong(data)
    return ws.build_frame(true, 0xA, data)
end

function ws.build_close(code, reason)
    -- 1000  "normal closure" status code
    if code == nil and reason ~= nil then
        code = 1000
    end
    local data = ""
    if code ~= nil then
        data = string.pack(">H", code)
    end
    if reason ~= nil then
        data = data .. reason
    end
    return ws.build_frame(true,0x8,data)
end

local function websocket_mask(mask, data, length)
    local umasked = {}
    for i=1, length do
        umasked[i] = string.char(string.byte(data, i) ~ string.byte(mask, (i-1)%4 + 1))
    end
    return table.concat(umasked)
end

function ws.parse_frame(readbytes)
    local data, err = readbytes(2)
    if not data then
        return nil, nil, "Read first 2 byte got nil: " .. tostring(err)
    end

    local header, payloadlen = string.unpack(">BB", data)
    local final_frame = header & 0x80 ~= 0
    local reserved_bits = header & 0x70 ~= 0
    local frame_opcode = header & 0xf
    local frame_opcode_is_control = frame_opcode & 0x8 ~= 0
    if reserved_bits then
        -- client is using as-yet-undefined extensions
        return nil, nil, "Reserved_bits show using undefined extensions"
    end

    local mask_frame = payloadlen & 0x80 ~= 0
    payloadlen = payloadlen & 0x7f
    if frame_opcode_is_control and payloadlen >= 126 then
        -- control frames must have payload < 126
        return nil, nil, "Control frame payload overload"
    end

    if frame_opcode_is_control and not final_frame then
        return nil, nil, "Control frame must not be fragmented"
    end

    local frame_length, frame_mask
    if payloadlen < 126 then
        frame_length = payloadlen
    elseif payloadlen == 126 then
        local h_data, err = readbytes(2)
        if not h_data then
            return nil, nil, "Payloadlen 126 read true length error:" .. tostring(err)
        end
        frame_length = string.unpack(">!2H", h_data)
        -- log.info("payloadlen 126:",frame_length)
    else --payloadlen == 127
        local l_data, err = readbytes(8)
        if not l_data then
            return nil, nil, "Payloadlen 127 read true length error:" .. tostring(err)
        end
        frame_length = string.unpack(">!8L", l_data)
        -- log.info("payloadlen 127:",frame_length)
    end

    if mask_frame then
        local mask, err = readbytes(4)
        if not mask then
            return nil, nil, "Masking Key read error:" .. tostring(err)
        end
        frame_mask = mask
    end

    local  frame_data = ""
    if frame_length > 0 then
        local fdata, err = readbytes(frame_length)
        if not fdata then
            return nil, nil, "Payload data read error:" .. tostring(err)
        end
        frame_data = fdata
    end

    if mask_frame and frame_length > 0 then
        frame_data = websocket_mask(frame_mask, frame_data, frame_length)
    end

    if frame_opcode == ws.OPCODE_CLOSE and final_frame then
        local code,reason
        code = #frame_data >= 2 and string.unpack(">H",frame_data:sub(1,2)) or -1
        reason = #frame_data > 2 and frame_data:sub(3) or ""

        return frame_opcode,final_frame,code,reason
    end

    return frame_opcode, final_frame, frame_data
end

return ws