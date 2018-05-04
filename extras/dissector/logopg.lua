-------------------------------------------------------------------------------
-- This dissector decodes an LOGO PG protocol.
-- use with: Wireshark -Xlua_script:logopg.lua example.pcap
-------------------------------------------------------------------------------
--
-- author: J.Schneider <https://github.com/brickpool/logo>
-- Copyright (c) 2018, J.Schneider
-- The dissector is licensed under the GNU Lesser General Public License v3.0.
--
-- However, this dissector distributes and uses code from
-- other Open Source Projects that have their own licenses:
--  dissectFPM.lua  by Hadriel Kaplan, 2015
--  example.lua     by Torsten Traenkner, 02.04.2015
--  p_frag.lua      by mj99, https://osqa-ask.Wireshark.org/answer_link/55764/
--
-- History:
--  0.1   04.04.2018      inital version
--  0.2   05-11.04.2018   desegmentation of packets
--  0.2.1 11.04.2018      bug fixing
--  0.2.2 12-14.04.2018   optimisations of reasembling
--  0.3   14.04.2018      dissection of message type 0x06
--  0.3.1 15.04.2018      optimisations of dissecting
--  0.3.2 16-17.04.2018   bug fixing
--  0.4   18-24.04.2018   update desegmentation
--  0.4.1 25.04.2018      bug fixing
--  0.4.2 25-26.04.2018   optimisations of dissecting
--  0.5   26.04.2018      dissection of function code 0x11 and 0x13
--  0.5.1 27.04.2018      display src, dest and info
--  0.5.2 27.04.2018      bug fixing 0x00 and 0x05, add checksum
--  0.5.3 29.04.2018      bug fixing 0x05 and 0x06
--  0.5.4 29.04.2018      bug fixing 0x04
--  0.5.5 30.04.2018      bitcount for data in function code 0x11
--  0.5.6 01-02.05.2018   bug fixing
--
-------------------------------------------------------------------------------

local dbg = require 'debug'

----------------------------------------
-- do not modify this table
local debug_level = {
  DISABLED  = 0,
  LEVEL_4   = 4,  -- warning
  LEVEL_6   = 6,  -- info
  LEVEL_7   = 7,  -- debug
}

-- set this DEBUG to debug_level.LEVEL_6 to enable printing debug_level info
-- set it to debug_level.LEVEL_7 to enable really verbose printing
-- note: this will be overridden by user's preference settings
local DEBUG = debug_level.LEVEL_4

-- a table of our default settings - these can be changed by changing
-- the preferences through the GUI or command-line; the Lua-side of that
-- preference handling is at the end of this script file
local default_settings = {
  debug_level   = DEBUG,
  subdissect    = true,   -- display data as tree info in wireshark
  max_msg_len   = 2000+7, -- this is the maximum size of a message
  address_len   = 2,      -- address field is 2 bytes
  ident_number  = 0,      -- ident_number is unknown (0)
  value         = 1,      -- start value for message counting
}

local null_function = function() end
local dprint4 = null_function
local dprint6 = null_function
local dprint7 = null_function
local function reset_debug_level()
  if default_settings.debug_level > debug_level.DISABLED then
    dprint4 = function(...) warn(table.concat({...}," ")) end
  else
    dprint4 = null_function
  end

  if default_settings.debug_level > debug_level.LEVEL_4 then
    dprint6 = function(...) info(table.concat({...}," ")) end
  else
    dprint6 = null_function
  end

  if default_settings.debug_level > debug_level.LEVEL_6 then
    dprint7 = function(...) debug(table.concat({...}," ")) end
  else
    dprint7 = null_function
  end
end
-- call it now
reset_debug_level()

---------------------------------------- 
-- creates the Proto object, but doesn't register it yet
LOGOPPI = Proto("logoppi", "LOGO Point to Point Interface")
LOGOPG = Proto("logopg", "LOGO Programming Device Protocol")

----------------------------------------
-- a table of our PPI-Protocol fields
local ppi_fields = LOGOPPI.fields

-- Message fields
local FLAG_VALUE  = {
  [0] = "Not Set",
  [1] = "Set"
}
local FL_FRAGMENT = 0x01

ppi_fields.sequence_number  = ProtoField.uint32("LOGOPPI.sequence_number",  "Sequence number")
ppi_fields.flags            = ProtoField.uint8 ("LOGOPPI.Flags",            "Flags",          base.HEX)
ppi_fields.fragmented       = ProtoField.uint8 ("LOGOPPI.fragmented",       "More Fragment",  base.DEC, FLAG_VALUE, FL_FRAGMENT)

----------------------------------------
-- a table of our PG-Protocol fields
local pg_fields = LOGOPG.fields

local transaction_id = 0
local ident_number = default_settings.ident_number
local address_len = default_settings.address_len

-- ADU fields
local IDENTIFIERS = {
  [0x40] = "0BA4",
  [0x42] = "0BA5",
  [0x43] = "0BA6",
  [0x44] = "0BA6",
}

pg_fields.transaction_id  = ProtoField.uint16("LOGOPG.transaction_id",  "Transaction identifier", base.DEC)
pg_fields.unit_id         = ProtoField.uint8 ("LOGOPG.unit_id",         "Unit identifier",        base.HEX, IDENTIFIERS)
pg_fields.pdu_length      = ProtoField.uint16("LOGOPG.pdu_length",      "PDU Length",             base.DEC)

-- PDU fields
local MESSAGE_CODES = {
  [0x00] = "No Operation",
  [0x01] = "Write Byte",
  [0x02] = "Read Byte",
  [0x04] = "Write Block",
  [0x05] = "Read Block",
  [0x06] = "Acknowledge Response",
  [0x15] = "Exception Response",
  [0x20] = "Clear Program",
  [0x21] = "Connect Request",
  [0x22] = "Restart",
  [0x55] = "Control Command",
}

local ACK_RESPONSES = {
  [0x01] = "Operation Mode RUN",
  [0x03] = "Read Data Response",
  [0x20] = "Operation Mode EDIT",
  [0x42] = "Operation Mode STOP",
  [0x55] = "Control Command Response",
}

local EXCEPTION_CODES = {
  [1] = "Device Busy",
  [2] = "Device Timeout",
  [3] = "Illegal Access",
  [4] = "Parity Error",
  [5] = "Unknown Command",
  [6] = "XOR Incorrect",
  [7] = "Simulation Error"
}

local FUNCTION_CODES = {
  [0x1111] = "Fetch Data Response",
  [0x1212] = "Stop Operating",
  [0x1313] = "Start Fetch Data",
  [0x1414] = "Stop Fetch Data",
  [0x1717] = "Operation Mode",
  [0x1818] = "Start Operating",
  [0x1b1b] = "Diagnostic",
}

local LOGICAL_VALUE = {
  [0] = "Low",
  [1] = "High",
}

local TRAILER_CODES = {
  [0xAA] = "End Delimiter"
}

pg_fields.message_type    = ProtoField.uint8 ("LOGOPG.message_type",    "Message Type",   base.HEX, MESSAGE_CODES)
pg_fields.address         = ProtoField.bytes ("LOGOPG.address",         "Address")
pg_fields.response_code   = ProtoField.uint8 ("LOGOPG.response_code",   "Response Code",  base.HEX, ACK_RESPONSES)
pg_fields.exception_code  = ProtoField.uint8 ("LOGOPG.exception_code",  "Exception Code", base.DEC, EXCEPTION_CODES)
pg_fields.function_code   = ProtoField.uint16("LOGOPG.function_code",   "Function Code",  base.HEX, FUNCTION_CODES)
pg_fields.byte_count      = ProtoField.uint16("LOGOPG.byte_count",      "Byte Count",     base.DEC)
pg_fields.data            = ProtoField.bytes ("LOGOPG.data",            "Data")
pg_fields.bit0            = ProtoField.uint8 ("LOGOPG.bit0",            "b0",             base.DEC, LOGICAL_VALUE, 0x01)
pg_fields.bit1            = ProtoField.uint8 ("LOGOPG.bit1",            "b1",             base.DEC, LOGICAL_VALUE, 0x02)
pg_fields.bit2            = ProtoField.uint8 ("LOGOPG.bit2",            "b2",             base.DEC, LOGICAL_VALUE, 0x04)
pg_fields.bit3            = ProtoField.uint8 ("LOGOPG.bit3",            "b3",             base.DEC, LOGICAL_VALUE, 0x08)
pg_fields.bit4            = ProtoField.uint8 ("LOGOPG.bit4",            "b4",             base.DEC, LOGICAL_VALUE, 0x10)
pg_fields.bit5            = ProtoField.uint8 ("LOGOPG.bit5",            "b5",             base.DEC, LOGICAL_VALUE, 0x20)
pg_fields.bit6            = ProtoField.uint8 ("LOGOPG.bit6",            "b6",             base.DEC, LOGICAL_VALUE, 0x40)
pg_fields.bit7            = ProtoField.uint8 ("LOGOPG.bit7",            "b7",             base.DEC, LOGICAL_VALUE, 0x80)
pg_fields.checksum        = ProtoField.uint8 ("LOGOPG.checksum",        "Checksum XOR",   base.HEX)
pg_fields.trailer         = ProtoField.uint8 ("LOGOPG.trailer",         "Trailer",        base.HEX, TRAILER_CODES)


--------------------------------------------------------------------------------
-- https://www.lua.org/pil/19.3.html
-- With this function, it is easy to loop in order
--------------------------------------------------------------------------------
function pairsByKeys(t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end


--------------------------------------------------------------------------------
-- This function calc the XOR Checksum, Parameter "data" is a ByteAarry
--------------------------------------------------------------------------------
function checkSum8Xor(data)
  local cval = 0
  for i = 0, data:len()-1 do
    cval = bit.bxor(cval, data:get_index(i))
  end
  return cval
end


--------------------------------------------------------------------------------
-- This function Cout the number of bits,
-- Parameter "data" is a ByteAarry, "bits" is the number of bits (optional)
--------------------------------------------------------------------------------
function NumberOfSetBits(data, bits)
  local count = 0
  if bits ~= nil and bits > 0 and bits < data:len()*8 then
	-- local q,r = bits /% 8
	local r = math.fmod(bits, 8)
	local q = (bits - r) / 8
	if r > 0 then
	  data:set_size(q + 1)
	  data:set_index(q, bit32.band(data:get_index(q), r))
	else
 	  data:set_size(q)
	end
  end
  for i = 0, data:len()-1 do
	local n = data:get_index(i)
	while n > 0 do
	  count = count + bit.band(n, 0x01)
	  n = bit.rshift(n, 1)
	end
  end
  return count
end

--------------------------------------------------------------------------------
-- The Serial Capture Service splits large packets over the serial interface 
-- into several packets. In this case the dissection can’t be carried out
-- correctly until we have all the data. Sometime the first packet doesn’t have
-- enough data, and the subsequent packets don’t have the expect format. To
-- dissect these packets we need to wait until all the parts have arrived and
-- then start the dissection. The following section described all possible
-- cases:
-- 1. A single PDU may span multiple packets.
-- 2. A single header may also span multiple packets
-- 3. A packet may also contain multiple PDUs, both complete and fragmented
-- 4. The length of a PDU is determined by a header field,
--    but an unknown number of bytes must be read before getting to that value,
--    as the header is preceded by a variable length delimiter
-- 5. There are no sequence numbers or other ways of uniquely identifying a PDU
-- 6. There is no flag indicating whether a PDU will be fragmented,
--    or whether multiple PDUs will appear in a packet,
--    other than by reading the length
-- 7. All communications are between a single sender and receiver
--------------------------------------------------------------------------------
local PacketHelper = {}
local PacketHelper_mt = { __index = PacketHelper }

-- Wrapping up the packet dissection
function PacketHelper.new()
  dprint7("PacketHelper:new() called")
  -- Let’s step through adding a basic packet header.
  -- It consists of the following basic items
  local new_class = {  -- the new instance
    -- A message counter (valid values are > 0)
    message_counter = default_settings.value,

    -- The following tables needs to be cleared by the
    -- protocol "init()" function whenever a capture is reloaded

    -- The following local table holds the packet info;
    -- this is needed to create and keep trackof pseudo headers
    -- for messages that went over the serial interface,
    -- for example for sequence number info.
    -- The key index will be a number - the pinfo.number.
    packet_infos = {},

    -- The following local table holds the sequences of a fragmented PDU message.
    -- The key index for this is the sequence numper+pinfo.number concatenated.
    -- The value is a table, ByteArray style, holding the fragment of the PDU message.
    fragments = {},

  }
  setmetatable( new_class, PacketHelper_mt ) -- all instances share the same metatable
  return new_class
end

--------------------------------------------------------------------------------
-- reference to #5
-- It is important that a sequence number can always be uniquely assigned to a
-- PDU message so that fragments of a PDU message are mapped correctly. Since
-- the protocol has no sequence number, we need to generated our own sequence
-- number. There are different approaches to creating a sequence number. We use
-- the storage of the number used first.
--
-- The parameter "pinfo" and "message_id" are optional.
-- If message_id is specified, this message_id will be assign to pinfo, 
-- otherwise the current sequence number will be assigned (if not previously 
-- assigned).If pinfo isn't specified, the current sequence number will be set 
-- to message_id. 
--
-- The sequence number of pinfo will be returned or 0 for errors.
--------------------------------------------------------------------------------
function PacketHelper:set_number(param1, param2)
  dprint7("PacketHelper:set_number() function called, parameter:", type(param1), type(param2))

  -- set the parameters according to the types
  local pinfo = nil
  if type(param1) == "userdata" then
    pinfo = param1
  elseif type(param2) == "userdata" then
    pinfo = param2
  end
  local message_id = nil
  if type(param2) == "number" then
    message_id = param2
  elseif type(param1) == "number" then
    message_id = param1
  end

  -- simple type checking
  if (pinfo == nil and message_id == nil)
  or (pinfo ~= nil and pinfo["number"] == nil)
  then return 0 end

  if pinfo == nil then
    -- set current sequence number to message_id
    self.message_counter = message_id
  elseif message_id ~= nil and self.packet_infos[pinfo.number] ~= nil then
    -- set new sequence number
    dprint6("Upddate sequence number", message_id, "to packet", pinfo.number)
    self.packet_infos[pinfo.number].sequence_number = message_id
  elseif not pinfo.visited then
    -- if not already available, set flag "start packet" and save the current
    -- sequence number
    message_id = self.message_counter
    dprint6("Assign sequence number", message_id, "to packet", pinfo.number)
    self.packet_infos[pinfo.number] = {
      -- A sequence number - 16 bits.
      sequence_number = message_id,
    }
  else
    -- set current sequence number to the previous saved value
    self.message_counter = self.packet_infos[pinfo.number].sequence_number
  end
  
  -- return the sequence number for pinfo (or nil)
  return self:get_number(pinfo)
end

--------------------------------------------------------------------------------
-- reference to #5
-- Since the protocol has no sequence number, we need to generated our own
-- sequence number.
--
-- The parameter "pinfo" is optional. If pinfo is specified, the first sequence
-- number of pinfo will be returned, otherwise the current sequence number will
-- be returned
--------------------------------------------------------------------------------
function PacketHelper:get_number(pinfo)
  local message_id
  if type(pinfo) == "userdata" and pinfo["number"] ~= nil then
    message_id = self.packet_infos[pinfo.number] and self.packet_infos[pinfo.number].sequence_number or 0
  else
    message_id = self.message_counter
  end
  dprint7("PacketHelper:get_number() function called, returned:", message_id)
  return message_id
end

--------------------------------------------------------------------------------
-- reference to #1
-- A single PDU may span multiple packets (fragmented = true).
--
-- The parameter "pinfo" is optional. If pinfo is specified and we have
-- fragments for parameter pinfo, the function returned true, otherwise false.
-- If pinfo isn't specified the function returns the same info for the current
-- sequence number
--------------------------------------------------------------------------------
function PacketHelper:fragmented(pinfo)
  -- Check if there are any fragmentations for the sequence number of pinfo
  local message_id = self:get_number(pinfo)
  local is_fragmented = self.fragments[message_id] ~= nil
  dprint7("PacketHelper:fragmented() function called, returned:", is_fragmented and "true" or "false")
  return is_fragmented
end

--------------------------------------------------------------------------------
-- reference to #6
-- We need to have some way of knowing when the PDU ends (more_fragment = false)
--
-- The function returned true if packets for parameter "pinfo" has more
-- fragments, otherwiese false.
--------------------------------------------------------------------------------
function PacketHelper:more_fragment(pinfo)
  -- simple type checking
  if type(pinfo) ~= "userdata" or pinfo["number"] == nil then return false end
  message_id = self:get_number(pinfo)
  -- Check if we have fragments of this message id
  if self.fragments[message_id] == nil then return false end
  -- Check if we have more fragments of this message id
  -- As a reminder, we don't store the last fragment in our structure
  local last_fragment = self.fragments[message_id][pinfo.number] == nil
  dprint7("PacketHelper:more_fragment() function called, returned:", last_fragment and "false" or "true")
  return not last_fragment
end

--------------------------------------------------------------------------------
-- reference to #1
-- Wireshark isn't set up to have dissectors look at any frame other than the
-- current frame. So we need to reassembly the fragmented message. 
--------------------------------------------------------------------------------
function PacketHelper:desegment(tvb, pinfo)
  dprint7("PacketHelper:desegment() function called")

  -- simple type checking
  if type(tvb) ~= "userdata"
  or type(pinfo) ~= "userdata"
  or pinfo["number"] == nil
  then return 0 end

  local buffer = tvb
  local message_id = self.message_counter
  -- Check if there are any fragmentations for this sequence number and if the buffer is the last fragment
  if self.fragments[message_id] ~= nil and self.fragments[message_id][pinfo.number] == nil then
    -- If there are no more fragments, load the saved data and create a composite "ByteArray"
    local reassembled = ByteArray.new()
    -- Read all previous fragments from our stored structure
    for key,data in pairsByKeys(self.fragments[self.message_counter]) do
      dprint6("Read fragment ["..self.message_counter..":"..key.."]")
      reassembled = reassembled .. data
    end
    -- We're going to our "dissect()" function with a composite tvb buffer
    reassembled = reassembled .. tvb:bytes()
    buffer = reassembled:tvb("Reassembled")
  end
  return buffer
end
  
--------------------------------------------------------------------------------
-- reference to #1
-- The correct way to process information in earlier frames is to save it in a
-- data structure for future reference.
--------------------------------------------------------------------------------
function PacketHelper:set_fragment(tvb, pinfo)
  dprint7("PacketHelper:set_fragment() function called, parameter:", type(tvb), type(pinfo))

  -- simple type checking
  if type(tvb) ~= "userdata"
  or type(pinfo) ~= "userdata"
  or pinfo["number"] == nil
  then return 0 end

  local offset = pinfo.desegment_offset
  local length = pinfo.desegment_len
  if length == 0 then return 0 end
  if self.fragments[self.message_counter] == nil then
    -- there are no fragments yet for this sequence number
    dprint6("Creating fragment table for sequence number:", self.message_counter)
    self.fragments[self.message_counter] = {}
  else
    -- we already have fragments, so "tvb" is a composite Tvb buffer
    for key,data in pairs(self.fragments[self.message_counter]) do
      offset = offset + data:len()
      length = length - data:len()
    end
  end
  -- check if limits are exceeded
  if length < 0 then length = 0 end
  if offset > tvb:len() then offset = tvb:len() end
  if offset + length > tvb:len() then length = tvb:len() - offset end
  dprint7("Packet offset:", offset, "and length:", length)
  -- If "length" is greater than 0, it is a fragment
  if length > 0 then
    dprint6("Save fragment ["..self.message_counter..":"..pinfo.number.."]")
    self.fragments[self.message_counter][pinfo.number] = tvb(offset, length):bytes()
  end
  return length
end

-- this holds our "helper"
local packet_helper = nil

-- this holds the plain "data" Dissector, in case we can't dissect it as LOGOPG
local data = Dissector.get("data")

local lookup_function_code = {
  [0x1111] = {
    -- Fetch Data Response
    pdu_length = function(tvb)
      if tvb:len() < 5 then return -1 end
      -- Confirmation Code + Control Code + Function Code + Byte Count (16bit Little Endian) + Data + End Delimiter
      return 1 + 1 + 2 + 2 + tvb(4,2):le_uint() + 1
    end,
    dissect = function(tvb, pinfo, tree)
      -- Header: Confirmation Code + Control Code + Function Code + Byte Count (16bit Little Endian) + ...
      local pdu_header_len = 1 + 1 + 2 + 2
      if tvb:len() < pdu_header_len then return 0 end
      tree:add(pg_fields.response_code, tvb(1,1))
      tree:add(pg_fields.function_code, tvb(2,2))
      -- Number of Bytes (16bit value)
      local number_of_bytes = tvb(4,2):le_uint()
      tree:add_le(pg_fields.byte_count, tvb(4,2))

      -- ... Data + ...
      local pdu_length = pdu_header_len + number_of_bytes + 1
      if tvb:len() < pdu_length then return 0 end

      if not default_settings.subdissect then
        tree:add(pg_fields.data, tvb(pdu_header_len, pdu_length - pdu_header_len - 1))
      else
        -- display data as tree info in wireshark
        local offset = pdu_header_len
        local datatree = tree:add(tvb(pdu_header_len, pdu_length - pdu_header_len - 1), "Data bytes")
        datatree:add(tvb(offset,2), string.format("Program checksum: 0x%04x", tvb(offset,2):uint()))
        offset = offset + 2
        local block_length = tvb(offset,1):uint()
        datatree:add(tvb(offset,1), string.format("Block Length: %d", block_length))
        offset = offset + 1
        datatree:add(tvb(offset,1), string.format("Constant Length: %d", tvb(offset,1):uint()))
        offset = offset + 1
        local additional_bytes = tvb(offset,1):uint()
        datatree:add(tvb(offset, 1), string.format("Additional Length: %d", additional_bytes))
        offset = offset + 1
  
        -- check if it is a Response of a 0ba6 or 0ba4/0ba5
        local end_delimiter = tvb(pdu_length-1, 1):uint()
        if end_delimiter == 0xAA then
          address_len = block_length > 17 and 4 or 2
        end

        -- block outputs
        local number_of_bits = address_len == 4 and 200 or 130
        local bytes_to_consume = address_len == 4 and 25 or 17
		local bitcount = NumberOfSetBits(tvb(offset, bytes_to_consume):bytes(), number_of_bits)
        local subtree = datatree:add(tvb(offset, bytes_to_consume), string.format("Block outputs [Bitcount %d]", bitcount))
        local bit = 1
        while bytes_to_consume > 0 do
          subtree:add(tvb(offset,1), string.format("B%03u-B%03u", bit+7 > number_of_bits and number_of_bits or bit+7, bit))
          subtree:add(pg_fields.bit0, tvb(offset,1))
          subtree:add(pg_fields.bit1, tvb(offset,1))
          bit = bit + 2
          if bit < number_of_bits then
            subtree:add(pg_fields.bit2, tvb(offset,1))
            subtree:add(pg_fields.bit3, tvb(offset,1))
            subtree:add(pg_fields.bit4, tvb(offset,1))
            subtree:add(pg_fields.bit5, tvb(offset,1))
            subtree:add(pg_fields.bit6, tvb(offset,1))
            subtree:add(pg_fields.bit7, tvb(offset,1))
            bit = bit + 6
          end
          offset = offset + 1
          bytes_to_consume = bytes_to_consume - 1
        end
  
        -- digital inputs
        number_of_bits = 24
        bytes_to_consume = 3
		bitcount = NumberOfSetBits(tvb(offset, bytes_to_consume):bytes())
        subtree = datatree:add(tvb(offset, bytes_to_consume), string.format("Digital inputs [Bitcount %d]", bitcount))
        bit = 1
        while bytes_to_consume > 0 do
          subtree:add(tvb(offset,1), string.format("I%02u-I%02u", bit+7, bit))
          subtree:add(pg_fields.bit0, tvb(offset,1))
          subtree:add(pg_fields.bit1, tvb(offset,1))
          subtree:add(pg_fields.bit2, tvb(offset,1))
          subtree:add(pg_fields.bit3, tvb(offset,1))
          subtree:add(pg_fields.bit4, tvb(offset,1))
          subtree:add(pg_fields.bit5, tvb(offset,1))
          subtree:add(pg_fields.bit6, tvb(offset,1))
          subtree:add(pg_fields.bit7, tvb(offset,1))
          bit = bit + 8
          offset = offset + 1
          bytes_to_consume = bytes_to_consume - 1
        end
        
        -- function keys
        if address_len == 4 then
		  bitcount = NumberOfSetBits(tvb(offset,1):bytes(), 4)
          subtree = datatree:add(tvb(offset,1), string.format("Function keys [Bitcount %d]", bitcount))
          subtree:add(tvb(offset,1), "F04-F01")
          subtree:add(pg_fields.bit0, tvb(offset,1))
          subtree:add(pg_fields.bit1, tvb(offset,1))
          subtree:add(pg_fields.bit2, tvb(offset,1))
          subtree:add(pg_fields.bit3, tvb(offset,1))
          offset = offset + 1
        end
  
        -- digital outputs
        number_of_bits = 16
        bytes_to_consume = 2
		bitcount = NumberOfSetBits(tvb(offset, bytes_to_consume):bytes())
        subtree = datatree:add(tvb(offset, bytes_to_consume), string.format("Digital outputs [Bitcount %d]", bitcount))
        bit = 1
        while bytes_to_consume > 0 do
          subtree:add(tvb(offset,1), string.format("Q%02u-Q%02u", bit+7, bit))
          subtree:add(pg_fields.bit0, tvb(offset,1))
          subtree:add(pg_fields.bit1, tvb(offset,1))
          subtree:add(pg_fields.bit2, tvb(offset,1))
          subtree:add(pg_fields.bit3, tvb(offset,1))
          subtree:add(pg_fields.bit4, tvb(offset,1))
          subtree:add(pg_fields.bit5, tvb(offset,1))
          subtree:add(pg_fields.bit6, tvb(offset,1))
          subtree:add(pg_fields.bit7, tvb(offset,1))
          bit = bit + 8
          offset = offset + 1
          bytes_to_consume = bytes_to_consume - 1
        end
        
        -- digital merkers
        number_of_bits = address_len == 4 and 27 or 24
        bytes_to_consume = address_len == 4 and 4 or 3
		bitcount = NumberOfSetBits(tvb(offset, bytes_to_consume):bytes(), number_of_bits)
        subtree = datatree:add(tvb(offset, bytes_to_consume), string.format("Digital merkers [Bitcount %d]", bitcount))
        bit = 1
        while bytes_to_consume > 0 do
          subtree:add(tvb(offset,1), string.format("M%02u-M%02u", bit+7 > number_of_bits and number_of_bits or bit+7, bit))
          subtree:add(pg_fields.bit0, tvb(offset,1))
          subtree:add(pg_fields.bit1, tvb(offset,1))
          subtree:add(pg_fields.bit2, tvb(offset,1))
          bit = bit + 3
          if bit < number_of_bits then
            subtree:add(pg_fields.bit3, tvb(offset,1))
            subtree:add(pg_fields.bit4, tvb(offset,1))
            subtree:add(pg_fields.bit5, tvb(offset,1))
            subtree:add(pg_fields.bit6, tvb(offset,1))
            subtree:add(pg_fields.bit7, tvb(offset,1))
            bit = bit + 5
          end
          offset = offset + 1
          bytes_to_consume = bytes_to_consume - 1
        end
        
        -- shift register
		bitcount = NumberOfSetBits(tvb(offset,1):bytes())
        subtree = datatree:add(tvb(offset,1), string.format("Shift register [Bitcount %d]", bitcount))
        subtree:add(tvb(offset,1), "S08-S01")
        subtree:add(pg_fields.bit0, tvb(offset,1))
        subtree:add(pg_fields.bit1, tvb(offset,1))
        subtree:add(pg_fields.bit2, tvb(offset,1))
        subtree:add(pg_fields.bit3, tvb(offset,1))
        subtree:add(pg_fields.bit4, tvb(offset,1))
        subtree:add(pg_fields.bit5, tvb(offset,1))
        subtree:add(pg_fields.bit6, tvb(offset,1))
        subtree:add(pg_fields.bit7, tvb(offset,1))
        offset = offset + 1
        
        -- cursor keys
		bitcount = NumberOfSetBits(tvb(offset,1):bytes(), 4)
        subtree = datatree:add(tvb(offset,1), string.format("Cursor keys [Bitcount %d]", bitcount))
        subtree:add(tvb(offset,1), "C04-C01")
        subtree:add(pg_fields.bit0, tvb(offset,1))
        subtree:add(pg_fields.bit1, tvb(offset,1))
        subtree:add(pg_fields.bit2, tvb(offset,1))
        subtree:add(pg_fields.bit3, tvb(offset,1))
        offset = offset + 1
  
        -- analog inputs (16bit Little Endian)
        bytes_to_consume = 16
		local flag = 0
		for i = offset, offset+bytes_to_consume-1 do
		  if tvb(i,1):uint() ~= 0 then
			flag = 1
			break
		  end
		end
        subtree = datatree:add(tvb(offset,bytes_to_consume), string.format("Analog inputs [%s]", FLAG_VALUE[flag]))
        local analog = 1
        while bytes_to_consume > 0 do
          subtree:add(tvb(offset,2), string.format("AI%u: %d", analog, tvb(offset,2):le_int()))
          analog = analog + 1
          offset = offset + 2
          bytes_to_consume = bytes_to_consume - 2
        end
  
        -- analog outputs (16bit Little Endian)
		flag = 0
		for i = offset, offset+4-1 do
		  if tvb(i,1):uint() ~= 0 then
			flag = 1
			break
		  end
		end
        subtree = datatree:add(tvb(offset,4), string.format("Analog outputs [%s]", FLAG_VALUE[flag]))
        subtree:add(tvb(offset,2), string.format("AQ1: %d", tvb(offset,2):le_int()))
        offset = offset + 2
        subtree:add(tvb(offset,2), string.format("AQ2: %d", tvb(offset,2):le_int()))
        offset = offset + 2
  
        -- analog merkers (16bit Little Endian)
        bytes_to_consume = 12
		flag = 0
		for i = offset, offset+bytes_to_consume-1 do
		  if tvb(i,1):uint() ~= 0 then
			flag = 1
			break
		  end
		end
        subtree = datatree:add(tvb(offset,bytes_to_consume), string.format("Analog merkers [%s]", FLAG_VALUE[flag]))
        local analog = 1
        while bytes_to_consume > 0 do
          subtree:add(tvb(offset,2), string.format("AM%u: %d", analog, tvb(offset,2):le_int()))
          analog = analog + 1
          offset = offset + 2
          bytes_to_consume = bytes_to_consume - 2
        end
  
        -- ... Extra Bytes + 
		flag = additional_bytes > 0 and 1 or 0
        subtree = datatree:add(tvb(offset, additional_bytes), string.format("Additional bytes [%s]", FLAG_VALUE[flag]))
        if additional_bytes > 0 then
          subtree:add(pg_fields.data, tvb(offset, additional_bytes))
        end
      end

      -- ... End Delimiter
      tree:add(pg_fields.trailer, tvb(pdu_length - 1, 1))
      return pdu_length
    end
  },
  [0x1212] = {
    -- Stop Operating
    pdu_length = function(...)
      -- Control Code + Function Code + End Delimiter
      return 4
    end,
    dissect = function(tvb, pinfo, tree)
      -- Control Code + Function Code + End Delimiter
      if tvb:len() < 4 then return 0 end
      tree:add(pg_fields.function_code, tvb(1,2))
      tree:add(pg_fields.trailer, tvb(3,1))
      return 4
    end
  },
  [0x1313] = {
    -- Start Fetch Data
    pdu_length = function(tvb)
      if tvb:len() < 4 then return -1 end
      -- Control Code + Function Code + Byte Count (8bit) + Data + End Delimiter
      return 1 + 2 + 1 + tvb(3,1):uint() + 1
    end,
    dissect = function(tvb, pinfo, tree)
      -- Control Code + Function Code + Byte Count (8bit) + ...
      local pdu_header_len = 1 + 2 + 1
      if tvb:len() < pdu_header_len then return 0 end
      local function_code = tvb(1,2):uint()
      tree:add(pg_fields.function_code, tvb(1,2))
      -- Number of Bytes (8bit value)
      local number_of_bytes = tvb(3,1):uint()
      tree:add(pg_fields.byte_count, tvb(3,1))

      -- ... Data + ...
      local pdu_length = pdu_header_len + number_of_bytes + 1
      if tvb:len() < pdu_length then return 0 end

      if not default_settings.subdissect then
        tree:add(pg_fields.data, tvb(pdu_header_len, pdu_length - pdu_header_len - 1))
      else
        -- display data as tree info in wireshark
        local subtree = tree:add(tvb(pdu_header_len, pdu_length - pdu_header_len - 1), "Data bytes")
        for offset = pdu_header_len, pdu_length - 2, 1 do
          local block_number = tvb(offset, 1):uint() - 9
          subtree:add(tvb(offset, 1), string.format("Block: B%03u", block_number))
        end
      end
      -- ... + End Delimiter
      tree:add(pg_fields.trailer, tvb(pdu_length - 1, 1))
      return pdu_length
    end
  },
  [0x1414] = {
    -- Stop Fetch Data
    pdu_length = function(...)
      -- Control Code + Function Code + End Delimiter
      return 4
    end,
    dissect = function(tvb, pinfo, tree)
      -- Control Code + Function Code + End Delimiter
      if tvb:len() < 4 then return 0 end
      tree:add(pg_fields.function_code, tvb(1,2))
      tree:add(pg_fields.trailer, tvb(3,1))
      return 4
    end
  },
  [0x1717] = {
    -- Operation Mode
    pdu_length = function(...)
      -- Control Code + Function Code + End Delimiter
      return 4
    end,
    dissect = function(tvb, pinfo, tree)
      -- Control Code + Function Code + End Delimiter
      if tvb:len() < 4 then return 0 end
      tree:add(pg_fields.function_code, tvb(1,2))
      tree:add(pg_fields.trailer, tvb(3,1))
      return 4
    end
  },
  [0x1818] = {
    -- Start Operating
    pdu_length = function(...)
      -- Control Code + Function Code + End Delimiter
      return 4
    end,
    dissect = function(tvb, pinfo, tree)
      -- Control Code + Function Code + End Delimiter
      if tvb:len() < 4 then return 0 end
      tree:add(pg_fields.function_code, tvb(1,2))
      tree:add(pg_fields.trailer, tvb(3,1))
      return 4
    end
  },
  [0x1b1b] = {
    -- Diagnostic
    pdu_length = function(...)
      -- Control Code + Function Code + End Delimiter
      return 4
    end,
    dissect = function(tvb, pinfo, tree)
      -- Control Code + Function Code + End Delimiter
      if tvb:len() < 4 then return 0 end
      tree:add(pg_fields.function_code, tvb(1,2))
      tree:add(pg_fields.trailer, tvb(3,1))
      return 4
    end
  },
}

local lookup_message_type = {}
local lookup_ack_response = {
  [0x01] = {
    -- Mode RUN
    pdu_length = function(tvb)
      if tvb:len() < 2 then return -1 end
      if tvb:len() > 2 then
		local next_code = tvb(2,1):uint()
		if lookup_message_type[next_code] == nil then return 1 end
	  end
      return 2
    end,
    dissect = function(tvb, pinfo, tree)
      if tvb:len() < 2 then return 0 end
      if tvb:len() > 2 then
		local next_code = tvb(2,1):uint()
		if lookup_message_type[next_code] == nil then return 1 end
	  end
	  tree:add(pg_fields.response_code, tvb(1,1))
      return 2
    end
  },
  [0x03] = {
    -- Read Data Response
    pdu_length = function(tvb)
      -- Confirmation Code + Data Response + ...
      if tvb:len() < 3 then return -1 end
      -- check if it is a Connection Response of a 0ba6
      if tvb(2,1):uint() == 0x21 then
        -- at 0ba6 all addresses are 32bit
        address_len = 4
        -- Confirmation Code + Data Response + Connection Response + Ident Number
        return 4
      else
        -- Confirmation Code + Data Response + Address + Data Byte
        return 1 + 1 + address_len + 1
      end
    end,
    dissect = function(tvb, pinfo, tree)
      -- Confirmation Code + Data Response + Connection Response (8bit) + Ident Number
      if tvb:len() < 4 then return 0 end
      tree:add(pg_fields.response_code, tvb(1,1))
      -- check if it is a Connection Response of a 0ba6
      if tvb(2,1):uint() == 0x21 then
        tree:add(tvb(2,1), "Connection Response (0x21)")
        tree:add(tvb(3,1), string.format("Unit identifierer: 0BA6 (0x%02x)", tvb(3,1):uint()))
        return 4
      else
        -- Confirmation Code + Data Response + Address (16/32bit) + ...
        local pdu_header_len = 2 + address_len
        local pdu_length = pdu_header_len + 1
        if tvb:len() < pdu_length then return 0 end
        -- Address (16/32bit value Big-Endian)
        tree:add(pg_fields.address, tvb(2, address_len))
        tree:add(pg_fields.data, tvb(pdu_header_len, 1))
        return pdu_length
      end
    end
  },
  [0x20] = {
    -- Mode EDIT
    pdu_length = function(...)
      return 2
    end,
    dissect = function(tvb, pinfo, tree)
      if tvb:len() < 2 then return 0 end
      tree:add(pg_fields.response_code, tvb(1,1))
      return 2
    end
  },
  [0x42] = {
    -- Mode STOP
    pdu_length = function(...)
      return 2
    end,
    dissect = function(tvb, pinfo, tree)
      if tvb:len() < 2 then return 0 end
      tree:add(pg_fields.response_code, tvb(1,1))
      return 2
    end
  },
  [0x55] = {
    -- Control Command Response
    pdu_length = function(tvb)
      if tvb:len() < 4 then return -1 end
      -- Confirmation Code + Control Code + Function Code + ...
      local function_code = tvb(2,2):uint()
      -- Acknowledgement
      if function_code ~= 0x1111 then return 1 end
      if lookup_function_code[function_code] == nil then return 0 end
      return lookup_function_code[function_code].pdu_length(tvb)
    end,
    dissect = function(tvb, pinfo, tree)
      if tvb:len() < 4 then return 0 end
      -- Confirmation Code + Control Code + Function Code + ...
      local function_code = tvb(2,2):uint()
      -- Acknowledgement
      if function_code ~= 0x1111 then return 1 end
      if lookup_function_code[function_code] == nil then return 0 end
      return lookup_function_code[function_code].dissect(tvb, pinfo, tree)
    end
  },
}

lookup_message_type = {
  [0x00] = {
    -- No Operation
    pdu_length = function(...)
      -- NOP
      return 1
    end,
    dissect = function(tvb, pinfo, tree)
      -- NOP
      if tvb:len() < 1 then return 0 end
      tree:add(pg_fields.message_type, tvb(0,1))
      return 1
    end
  },
  [0x01] = {
    -- Write Byte
    pdu_length = function(...)
      -- Data Code + Address (16/32bit) + Data Byte
      return 1 + address_len + 1
    end,
    dissect = function(tvb, pinfo, tree)
      -- Data Code + Address (16/32bit) + Data Byte
      local pdu_header_len = 1 + address_len
      local pdu_length = pdu_header_len + 1
      if tvb:len() < pdu_length then return 0 end
      tree:add(pg_fields.message_type, tvb(0,1))
      tree:add(pg_fields.address, tvb(1, address_len))
      tree:add(pg_fields.data, tvb(pdu_header_len, 1))
      return pdu_length
    end
  },
  [0x02] = {
    -- Read Byte
    pdu_length = function(...)
      -- Data Code + Address (16/32bit)
      return 1 + address_len
    end,
    dissect = function(tvb, pinfo, tree)
      -- Data Code + Address (16/32bit)
      local pdu_header_len = 1 + address_len
      if tvb:len() < pdu_header_len then return 0 end
      tree:add(pg_fields.message_type, tvb(0,1))
      tree:add(pg_fields.address, tvb(1, address_len))
      return pdu_header_len
    end
  },
  [0x04] = {
    -- Write Block
    pdu_length = function(tvb)
      -- Data Code + Address (16/32bit) + Byte Count (16bit Big Endian) + ...
      local pdu_header_len = 1 + address_len + 2
      if tvb:len() < pdu_header_len then return -1 end
      local offset = 1 + address_len
      if tvb(1,1):uint() == 0x06 then
        -- Q:[Data Code] + R:[Acknowledge Response] + Q:[Address + Byte Count + Data Block + Checksum]
        -- skip Acknowledge Response
        offset = offset + 1
      end
      local number_of_bytes = tvb(offset, 2):uint()
      -- Data Code + Address (16/32bit) + Byte Count (16bit Big Endian) + Data Block + Checksum + Acknowledge Response
      return 1 + address_len + 2 + number_of_bytes + 1 + 1
    end,
    dissect = function(tvb, pinfo, tree)
      -- Data Code + Address (16/32bit) + Byte Count (16bit Big Endian)
      local pdu_header_len = 1 + address_len + 2
      if tvb:len() < pdu_header_len + 1 then return 0 end
      -- Data Code + ...
      local offset = 0
      tree:add(pg_fields.message_type, tvb(offset,1))
      offset = offset + 1
      -- if present skip Acknowledge Response
      if tvb(1,1):uint() == 0x06 then offset = offset + 1 end
      -- ... Address (16/32bit) + ...
      tree:add(pg_fields.address, tvb(offset,address_len))
      offset = offset + address_len
      -- ... Byte Count (16bit Big-Endian) + ...
      tree:add(pg_fields.byte_count, tvb(offset,2))
      local number_of_bytes = tvb(offset,2):uint()
      offset = offset + 2

      -- PDU Header + ...
      local pdu_length = pdu_header_len + number_of_bytes + 1
      if tvb:len() < pdu_length + 1 then return offset end
      -- ... Data + Checksum
      tree:add(pg_fields.data, tvb(offset, number_of_bytes))
      local checksum = checkSum8Xor(tvb(offset, number_of_bytes):bytes())
      offset = offset + number_of_bytes
      local xor_byte = tvb(offset, 1):uint()
      if xor_byte == checksum then
        tree:add(pg_fields.checksum, tvb(offset, 1), xor_byte, nil, "[correct]")
      else
        local incorrect = string.format("[incorrect, should be 0x%02x]", checksum)
        tree:add(pg_fields.checksum, tvb(offset, 1), xor_byte, nil, incorrect)
      end
      offset = offset + 1

      -- PDU + Acknowledge Response
      if tvb(1,1):uint() == 0x06 then
        tree:add(pg_fields.message_type, tvb(1,1))
      else
        tree:add(pg_fields.message_type, tvb(offset,1))
      end
      return pdu_length + 1
    end
  },
  [0x05] = {
    -- Read Block
    pdu_length = function(tvb)
      -- Data Code + Address (16/32bit) + Byte Count (16bit Big-Endian)
      local query_len = 1 + address_len + 2
      if tvb:len() < query_len + 1 then return -1 end
      local offset = 1 + address_len
      if tvb(1,1):uint() == 0x06 then
        -- Q:[Data Code] + R:[Acknowledge Response] + Q:[Address + Byte Count] + R:[Data Block + Checksum]
        -- skip Acknowledge Response
        offset = offset + 1
      end
      local number_of_bytes = tvb(offset,2):uint()
      -- Q:[Data Code + Address + Byte Count] + R:[Acknowledge Response + Data Block + Checksum]
      local response_len = 1 + number_of_bytes + 1
      return query_len + response_len
    end,
    dissect = function(tvb, pinfo, tree)
      -- Q:[Data Code + Address (16/32bit) + Byte Count (16bit Big-Endian)]
      local query_len = 1 + address_len + 2
      if tvb:len() < query_len + 1 then return 0 end
      local offset = 0
      -- Q:[Data Code + ...
      tree:add(pg_fields.message_type, tvb(offset,1))
      offset = offset + 1
      -- if present skip Acknowledge Response
      if tvb(1,1):uint() == 0x06 then offset = offset + 1 end
      -- ... Address (16/32bit) + ...
      tree:add(pg_fields.address, tvb(offset,address_len))
      offset = offset + address_len
      -- ... Byte Count (16bit Big-Endian)]
      tree:add(pg_fields.byte_count, tvb(offset,2))
      local number_of_bytes = tvb(offset,2):uint()
      offset = offset + 2

      -- R:[Acknowledge Response + Data Block + Checksum]
      local response_len = 1 + number_of_bytes + 1
      if tvb:len() < query_len + response_len then return offset end
      -- R:[Acknowledge Response + ...
      if tvb(1,1):uint() == 0x06 then
        tree:add(pg_fields.message_type, tvb(1,1))
      else
        tree:add(pg_fields.message_type, tvb(offset,1))
        offset = offset + 1
      end
      -- ... Data + Checksum]
      tree:add(pg_fields.data, tvb(offset, number_of_bytes))
      local checksum = checkSum8Xor(tvb(offset, number_of_bytes):bytes())
      offset = offset + number_of_bytes
      local xor_byte = tvb(offset, 1):uint()
      if xor_byte == checksum then
        tree:add(pg_fields.checksum, tvb(offset, 1), xor_byte, nil, "[correct]")
      else
        local incorrect = string.format("[incorrect, should be 0x%02x]", checksum)
        tree:add(pg_fields.checksum, tvb(offset, 1), xor_byte, nil, incorrect)
      end
      return query_len + response_len
    end
  },
  [0x06] = {
    -- Acknowledge Response
    pdu_length = function(tvb)
      -- Confirmation Code + Response Code + ...
      if tvb:len() < 2 then return -1 end
      local response_code = tvb(1,1):uint()
      if lookup_ack_response[response_code] == nil then return 1 end
      return lookup_ack_response[response_code].pdu_length(tvb)
    end,
    dissect = function(tvb, pinfo, tree)
      -- Confirmation Code + Response Code + ...
      if tvb:len() < 2 then return 0 end
      tree:add(pg_fields.message_type, tvb(0,1))
      local response_code = tvb(1,1):uint()
      if lookup_ack_response[response_code] == nil then return 1 end
      return lookup_ack_response[response_code].dissect(tvb, pinfo, tree)
    end
  },
  [0x15] = {
    -- Exception Response
    pdu_length = function(...)
      -- Confirmation Code + Exception Code
      return 2
    end,
    dissect = function(tvb, pinfo, tree)
      -- Confirmation Code + Exception Code
      if tvb:len() < 2 then return 0 end
      tree:add(pg_fields.message_type, tvb(0,1))
      tree:add(pg_fields.exception_code, tvb(1,1))
      return 2
    end
  },
  [0x20] = {
    -- Clear Program
    pdu_length = function(...)
      return 1
    end,
    dissect = function(tvb, pinfo, tree)
      -- Command Code
      if tvb:len() < 1 then return 0 end
      tree:add(pg_fields.message_type, tvb(0,1))
      return 1
    end
  },
  [0x21] = {
    -- Connect Request
    pdu_length = function(...)
      return 1
    end,
    dissect = function(tvb, pinfo, tree)
      -- Command Code
      if tvb:len() < 1 then return 0 end
      tree:add(pg_fields.message_type, tvb(0,1))
      return 1
    end
  },
  [0x22] = {
    -- Restart
    pdu_length = function(...)
      return 1
    end,
    dissect = function(tvb, pinfo, tree)
      -- Command Code
      if tvb:len() < 1 then return 0 end
      tree:add(pg_fields.message_type, tvb(0,1))
      return 1
    end
  },
  [0x55] = {
    -- Control Command
    pdu_length = function(tvb)
      if tvb:len() < 3 then return -1 end
      -- Control Code + Function Code + ...
      local function_code = tvb(1,2):uint()
      -- Return 0 (error) if it is a Confirmation Response
      if function_code == 0x1111 then return 0 end
      if lookup_function_code[function_code] == nil then return 0 end
      return lookup_function_code[function_code].pdu_length(tvb)
    end, 
    dissect = function(tvb, pinfo, tree)
      -- Control Code + Function Code + ...
      if tvb:len() < 3 then return 0 end
      tree:add(pg_fields.message_type, tvb(0,1))
      local function_code = tvb(1,2):uint()
      -- Return 0 (error) if it is a Confirmation Response
      if function_code == 0x1111 then return 0 end
      if lookup_function_code[function_code] == nil then return 0 end
      return lookup_function_code[function_code].dissect(tvb, pinfo, tree)
    end
  },
}

local lookup_queries = {
  [0x00] = true, -- No Operation
  -- Data Commands
  [0x01] = true, -- Write Byte
  [0x02] = true, -- Read Byte
  [0x04] = true, -- Write Block
  [0x05] = true, -- Read Block
  -- Tools Commands
  [0x20] = true, -- Clear Program
  [0x21] = true, -- Connect Request
  [0x22] = true, -- Restart
  -- Control Commands
  [0x551212] = true, -- Stop Operating
  [0x551313] = true, -- Start Fetch Data
  [0x551414] = true, -- Stop Fetch Data
  [0x551717] = true, -- Operation Mode
  [0x551818] = true, -- Start Operating
  [0x551b1b] = true, -- Diagnostic
}

--------------------------------------------------------------------------------
-- The following function returns the length of a PDU message
--
-- This function returns the length of the PDU, or DESEGMENT_ONE_MORE_SEGMENT
-- if the Tvb doesn't have enough information to get the length, or a 0 for error.
local function get_pdu_length(tvb, pinfo, offset)
  dprint7("get_pdu_length() function called")

  local length = 0

  -- "length" is the number of bytes remaining in the Tvb buffer 
  local length = tvb:len() - offset

  -- check if the Tvb buffer has enough remaining bytes
  if length <= 0 then
    dprint7("Remaining bytes were shorter than original")
    return 0
  end

  -- if we got here, then we know we have at least 1 byte in the tvb
  -- to figure out the messages type
  local message_type = tvb(offset, 1):uint()

  local msg = lookup_message_type[message_type]
  if not msg then
    dprint6("Unknown message type:", message_type)
    return 0
  end

  if not msg.pdu_length then
    dprint4("Function pdu_length() not found for message_type:", message_type)
    return 0
  end

  length = msg.pdu_length(tvb(offset, length))
  
  if length < 0 then
    -- we need more bytes, so tell the main function that we
    -- didn't get the pdu_length, and we need an unknown number of more
    -- bytes (which is what "DESEGMENT_ONE_MORE_SEGMENT" is used for)
    dprint7("Need more bytes to figure out PDU length")
    return DESEGMENT_ONE_MORE_SEGMENT
  end
  
  if length > default_settings.max_msg_len then
    -- too many bytes, invalid message
    dprint4("Message length is too long:", length)
    return 0
  end

  dprint7("PDU length:", length)
  return length
end

--------------------------------------------------------------------------------
-- We need initialization routine, to reset the var(s) whenever a capture
-- is restarted or a capture file loaded.
-- The vars would just be local to our whole script. That's why we need to
-- set or reset it, because Wireshark doesn't provide anything to do that for
-- us automatically
--------------------------------------------------------------------------------
function LOGOPG.init()
  dprint6("PG (re-)initialise")
  
  -- ADU header helper
  transaction_id  = 0
  trxn_id_table   = {}
  ident_number    = default_settings.ident_number

  -- PDU helper
  address_len     = default_settings.address_len
end

--------------------------------------------------------------------------------
-- The following creates the callback function for the PG dissector.
--
-- The 'tvb' contains the packet data, 'pinfo' is a packet info object,
-- and 'tree' is the object of the Wireshark tree view which are create in the
-- PPI Proto's dissector.
--
-- 1. If the packet does not belong to our dissector, we return 0.
--    We must not set the Pinfo's "desegment_len" nor the "desegment_offset". 
-- 2. If we need more bytes, we set the Pinfo's "desegment_len/desegment_offset"
---   and return the length of the Tvb.
-- 3. If we don't need more bytes, we return the number of bytes of the tvb
--    that belong to this protocol.
--------------------------------------------------------------------------------
function LOGOPG.dissector(tvb, pinfo, tree)
  dprint6("PG Protocol dissector() called, message id:", packet_helper:get_number())

  -- "length" is the number of bytes remaining in the Tvb buffer
  local length = tvb:len()
  -- return 0, if the packet does not have a valid length
  if length == 0 then return 0 end

  -- "pdu_length" is the number of bytes for the PDU
  local pdu_length = get_pdu_length(tvb, pinfo, 0)
  -- return 0, if the packet does not belong to your dissector
  if pdu_length == 0 then return 0 end

  if length < pdu_length then
    -- print Tvb as data, because we don't have the full PDU message
    data:call(tvb, pinfo, tree)

    -- we need more bytes to get the full message
    dprint6("Need more bytes to desegment full PDU message")

    if pdu_length == DESEGMENT_ONE_MORE_SEGMENT then
      -- we don't know exactly how many more bytes we need
      -- set the Pinfo "desegment_len" to the predefined value "DESEGMENT_ONE_MORE_SEGMENT"
      pinfo.desegment_len = DESEGMENT_ONE_MORE_SEGMENT
    else
      -- set Pinfo's "desegment_len" to how many more bytes we need to decode the full message
      pinfo.desegment_len = pdu_length - length
    end
    -- We also need to set the "dessegment_offset",
    -- so that the dissector can continue processing at the same position.
    pinfo.desegment_offset = 0

    -- We set desegment_len/desegment_offset as described earlier,
    -- so we return the length of the Tvb
    return length
  end
  -- if we got here, then we have a whole PDU in the Tvb buffer

  -- 1) We start by setting our protocol name, info and tree
  -- set the protocol column to show our protocol name
  pinfo.cols.protocol = LOGOPG.name

  -- set the INFO column too, but only if we haven't already set it before for
  -- this packet, because this function can be called multiple times per packet
  local message_type = tvb(0,1):uint()
  if string.find(tostring(pinfo.cols.info), "(0x%d%d)") == nil and MESSAGE_CODES[message_type] ~= nil then
    pinfo.cols.info:set(string.format("%s (0x%02x)", MESSAGE_CODES[message_type], message_type))
  end
  -- add our protocol to the dissection display tree.
  local subtree = tree:add(LOGOPG)

  -- 2) Next, the ADU header will be displayed

  -- 2a) Transaction identifier
  -- since the protocol has no transaction id, we need to generated our own identifier
  if not pinfo.visited and trxn_id_table[pinfo.number] == nil then
    -- if not already available, save the current identifier
    dprint7("Store identifier:", transaction_id, "to packet number:", pinfo.number)
    trxn_id_table[pinfo.number] = transaction_id
  end
  if trxn_id_table[pinfo.number] ~= nil then
    -- load the saved identifier if available
    transaction_id = trxn_id_table[pinfo.number]
  end

  if (pdu_length >= 3 and length >= 3 and lookup_queries[tvb(0,3):uint()])
  or (pdu_length >= 1 and length >= 1 and lookup_queries[tvb(0,1):uint()])
  then
    -- query: direction DTE > DCE
    pinfo.cols.src:set("DTE")
    pinfo.cols.dst:set("DCE")
    -- set new transaction id
    if message_type > 0 then transaction_id = transaction_id + 1 end
  else
    -- response: direction DCE > DTE
    pinfo.cols.src:set("DCE")
    pinfo.cols.dst:set("DTE")
  end
  -- display the current transaction id
  subtree:add(pg_fields.transaction_id, transaction_id):set_generated()

  -- 2b) Unit identifier
  if length >= 4 and address_len == 4 and tvb(0,3):uint() == 0x060321 then
    -- if we are here, then it is a Connection Response of a 0ba6
    ident_number = tvb(3,1):uint()
    subtree:add(pg_fields.unit_id, tvb(3,1))
  elseif length >= 5 and tvb(0,4):uint() == 0x06031f02 then
    -- if we are here, then it is a Connection Response of a 0ba4 or 0ba5
    ident_number = tvb(4,1):uint()
    subtree:add(pg_fields.unit_id, tvb(4,1))
  elseif ident_number > 0 then
    -- display the current ident number
    subtree:add(pg_fields.unit_id, ident_number):set_generated()
  end
  -- 2c) PDU Length
  subtree:add(pg_fields.pdu_length, pdu_length):set_generated()

  -- 3) Now, let's dissecting the PDU data
  local pdutree = subtree:add(tvb(), "Protocol Data Unit (PDU)")
  local offset = 0
  if lookup_message_type[message_type] ~= nil then
    offset = lookup_message_type[message_type].dissect(tvb, pinfo, pdutree)
  end

  -- if we got here, then we have only data bytes in the Tvb buffer
  data:call(tvb(offset, pdu_length - offset):tvb(), pinfo, subtree)

  -- we don't need more bytes, so we return the number of bytes of the PDU
  return pdu_length
end

--------------------------------------------------------------------------------
-- We need initialization routine, to reset the var(s) whenever a capture
-- is restarted or a capture file loaded.
--------------------------------------------------------------------------------
function LOGOPPI.init()
  dprint6("PPI (re-)initialise")
  -- PPI packet helper
  packet_helper = PacketHelper.new()
end

--------------------------------------------------------------------------------
-- The following creates the callback function for the PPI dissector.
-- It's implemented as a separate Protocal because we run over a serial
-- interface and thus might need to parse a single message over multiple packets.
-- So we invoke this function for desegmented messages.
--
-- The 'tvb' contains the packet data, 'pinfo' is a packet info object,
-- and 'root' is the root of the Wireshark tree view.
--
-- Whenever Wireshark dissects a packet that our Proto is hooked into, it will
-- call this function and pass it these arguments for the packet it's dissecting.
--------------------------------------------------------------------------------
function LOGOPPI.dissector(tvb, pinfo, root)
  dprint7("PPI dissector() called, length:", tvb:len())

  -- get the length of the packet tvb
  local length = tvb:len()
  if length == 0 then return end

  -- check if capture was only capturing partial packet size
  if length ~= tvb:reported_len() then
    -- captured packets are being sliced/cut-off, so don't try to desegment/reassemble
    dprint4("Captured packet was shorter than original, can't reassemble")
    -- Returning 0 tells Wireshark this packet is not for
    -- us, and it will try heuristic dissectors or the plain "data"
    -- one, which is what should happen in this case.
    return 0
  end

  -- set the protocol column to show our protocol name
  pinfo.cols.protocol = LOGOPPI.name

  -- update the current packet info to our structure
  local result = packet_helper:set_number(pinfo)
  if result == 0 then return 0 end

  local flags = 0
  -- display the fragments as data
  if packet_helper:fragmented() and packet_helper:more_fragment(pinfo) then
    -- From here we know that the frame is part of a PDU message (but not the last on).
    -- The tvb is a fragment of a PDU message, so display only the message fields and the data to the tree
    pinfo.cols.info:set("Message Fragment")
    local subtree = root:add(LOGOPPI)
    flags = bit.bor(flags, FL_FRAGMENT)
    subtree:add(ppi_fields.sequence_number, packet_helper:get_number()):set_generated()
    local flagtree = subtree:add(ppi_fields.flags, flags):set_generated()
    flagtree:add(ppi_fields.fragmented, flags)
    -- call the data dissector
    data:call(tvb, pinfo, root)
    return length
  end

  -- Now, we dissect the (original or composite) Tvb buffer
  local buffer = tvb
  -- reassembly the message if needed
  if packet_helper:fragmented() then
    buffer = packet_helper:desegment(tvb, pinfo)
    -- update the length, beacause we can have a new buffer
    length = buffer:len()
    if length == 0 then return 0 end
  end
  
  -- reference to #3
  -- That's similar to many protocols running atop TCP, so that's not inherently insoluble.
  local bytes_consumed = 0
  while bytes_consumed < length do
    -- reference to #4
    local result = get_pdu_length(buffer, pinfo, bytes_consumed)
    if result == 0 then
      -- If the result is 0, then it means we hit an error of some kind,
      -- so increment sequence and return 0.
      packet_helper:set_number(packet_helper:get_number() + 1)
      return 0
    end

    -- if we got here, then we know we have a PG message in the Tvb buffer
    local subtree = root:add(LOGOPPI)
    -- check if the remaning bytes in buffer are a part of PDU message or not
    local fragmented = bytes_consumed + result > length
    -- Inserted the message fields to the tree
    flags = 0
    if not fragmented then flags = bit.band(flags, bit.bnot(FL_FRAGMENT)) end
    subtree:add(ppi_fields.sequence_number, packet_helper:get_number()):set_generated()
    local flagtree = subtree:add(ppi_fields.flags, flags):set_generated()
    flagtree:add(ppi_fields.fragmented, flags)

    -- reference to #1 and #3
    -- We might have to implement something similar to tcp in our dissector.
    -- For that we using old desegment_offset/desegment_len method
    if fragmented then
      -- call the data dissector
      data:call(buffer(bytes_consumed, length - bytes_consumed):tvb(), pinfo, root)

      -- we need more bytes, so set the desegment_offset to what we
      -- already consumed, and the desegment_len to how many more
      -- are needed and save the fragment to our structure
      pinfo.desegment_offset = bytes_consumed
      pinfo.desegment_len = result
      packet_helper:set_fragment(buffer, pinfo)

      -- even though we need more bytes, this packet is for us, so we
      -- tell Wireshark all of its bytes are for us by returning the
      -- number of tvb bytes we "successfully processed", namely the
      -- length of the tvb
      return length
    end

    -- The real dissector starts here
    result = Dissector.get("logopg"):call(buffer(bytes_consumed, length - bytes_consumed):tvb(), pinfo, root)
    if result == 0 then
      -- If the result is 0, then it means we hit an error
      return 0
    end
  
    -- we successfully processed an PG message, of 'result' length
    bytes_consumed = bytes_consumed + result

    -- reference to #5 increment sequence number
    packet_helper:set_number(packet_helper:get_number() + 1)
  end

  -- Do NOT return the number 0, or else Wireshark will interpret that to mean
  -- this packet did not belong to your protocol, and will try to dissect it
  -- with other protocol dissectors (such as heuristic ones)
  return bytes_consumed
end

--------------------------------------------------------------------------------
-- We want to have our protocol dissection invoked for a specific USER,
-- so get the wtap_encap dissector table and add our protocol to it.
dprint6("Initialization of PPI protocol")

-- load the wtap_encap table
local wtap_encap_table = DissectorTable.get("wtap_encap")

-- register our protocol to USER0
dprint7("Register PPI protocol for USER0")
wtap_encap_table:add(wtap.USER0, LOGOPPI)


--------------------------------------------------------------------------------
-- preferences handling stuff
--------------------------------------------------------------------------------

local debug_pref_enum = {
  { 1, "Console disabled", debug_level.DISABLED },
  { 2, "Warning",          debug_level.LEVEL_4 },
  { 3, "Informational",    debug_level.LEVEL_6 },
  { 4, "Debug",            debug_level.LEVEL_7 },
}

--------------------------------------------------------------------------------
-- register our preferences
LOGOPPI.prefs.value       = Pref.uint("Value", default_settings.value, "Start value for counting")

LOGOPPI.prefs.subdissect  = Pref.bool("Enable sub-dissectors", default_settings.subdissect, 
                                     "Whether the data content should be dissected or not")

LOGOPPI.prefs.debug       = Pref.enum("Debug", default_settings.debug_level,
                                     "The debug printing level", debug_pref_enum)

--------------------------------------------------------------------------------
-- the function for handling preferences being changed
function LOGOPPI.prefs_changed()
  dprint6("PPI prefs_changed() called")

  default_settings.value = LOGOPPI.prefs.value
  default_settings.subdissect = LOGOPPI.prefs.subdissect
  default_settings.debug_level = LOGOPPI.prefs.debug
  reset_debug_level()
  
  -- have to reload the capture file for this type of change
  reload()
end

dprint7("PCapfile Prefs registered")
