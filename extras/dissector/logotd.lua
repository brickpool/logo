-------------------------------------------------------------------------------
-- This dissector decodes an LOGO TD protocol.
-- use with: Wireshark -Xlua_script:logotd.lua example.pcap
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
--  0.1   03-04.06.2018	inital version
--  0.1.1 04.06.2018		bug fixing
--  0.2 	04.06.2018    INFO colum, command code 0x08
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

-- set this DEBUG to debug_level.LEVEL_6 to enable printing debug_level info set
-- it to debug_level.LEVEL_7 to enable really verbose printing note: this will
-- be overridden by user's preference settings
local DEBUG = debug_level.LEVEL_4

-- a table of our default settings - these can be changed by changing the
-- preferences through the GUI or command-line; the Lua-side of that preference
-- handling is at the end of this script file
local default_settings = {
  debug_level       = DEBUG,
  subdissect        = true,   -- display data as tree info in wireshark
  max_telegram_len  = 249,    -- this is the maximum size of a telegram
  value             = 1,      -- start value for telegram counting
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
PROFIBUS  = Proto("pbus",   "PROFIBUS-DP Telegram")
LOGOTD    = Proto("logotd", "LOGO Text Display Protocol")

----------------------------------------
-- a table of fields for FDL 
local fdl_fields = PROFIBUS.fields

local FLAG_VALUE  = {
  [0] = "Not Set",
  [1] = "Set"
}
local FL_FRAGMENT = 0x01

local FDL_CODES = {
  [0x10] = "SD1",
  [0x68] = "SD2",
  [0xA2] = "SD3",
  [0xDC] = "SD4",
  [0xE5] = "SC",
}

local ADDRESS_VALUE = {
  [0x7F] = "Master",
  [0x80] = "Slave",
}

local SAP_VALUE = {
  [0x01] = "TD",
  [0x06] = "LOGO!",
}

local FC_CODES = {
  [0x04] = "SDN high",
  [0x06] = "SDN low",
  [0x0C] = "SRD low",
  [0x0D] = "SRD high",
}

local ED_CODES = {
  [0x16] = "ED"
}

-- this is the size of the FDL header (SD+LE+LEr+SD = 6 bytes)
local PBUS_FDL_HDR_LEN = 1 + 2 + 2 + 1
-- size of the SD2 header (SD2+LE+LEr+SD2+DA+SA+FC = 9 bytes)
local PBUS_SD2_HDR_LEN = PBUS_FDL_HDR_LEN + 1 + 1 + 1
-- size of the SAP fields (DSAP+SSAP = 2 bytes)
local PBUS_DDLM_HDR_LEN = 1 + 1
-- size of the FDL trailer (DCS+ED = 2 bytes)
local PBUS_TRAILER_LEN = 1 + 1
-- size of the ALI header (01+00+BC+CND = 4 bytes)
local PBUS_ALI_HDR_LEN = 1 + 1 + 1 + 1

fdl_fields.telegram_number  = ProtoField.uint32("PROFIBUS.number",        "Telegram number")
fdl_fields.flags            = ProtoField.uint8 ("PROFIBUS.flags",         "Flags",                              base.HEX)
fdl_fields.fragmented       = ProtoField.uint8 ("PROFIBUS.fragmented",    "More Fragment",                      base.DEC, FLAG_VALUE, FL_FRAGMENT)
fdl_fields.telegram         = ProtoField.uint8 ("PROFIBUS.type",          "Telegram",                           base.HEX, FDL_CODES)
fdl_fields.le               = ProtoField.uint16("PROFIBUS.LE",            "Length",                             base.DEC)
fdl_fields.ler              = ProtoField.uint16("PROFIBUS.LEr",           "Length repeated",                    base.DEC)
fdl_fields.telegram2        = ProtoField.uint8 ("PROFIBUS.type_repeated", "Telegram repeated",                  base.HEX, FDL_CODES)
fdl_fields.da               = ProtoField.uint8 ("PROFIBUS.DA",            "Destination Address",                base.HEX, ADDRESS_VALUE)
fdl_fields.sa               = ProtoField.uint8 ("PROFIBUS.SA",            "Source Address",                     base.HEX, ADDRESS_VALUE)
fdl_fields.fc               = ProtoField.uint8 ("PROFIBUS.FC",            "Frame Control",                      base.HEX, FC_CODES)
fdl_fields.dsap             = ProtoField.uint8 ("PROFIBUS.DSAP",          "Destination Service Access Points",  base.HEX, SAP_VALUE)
fdl_fields.ssap             = ProtoField.uint8 ("PROFIBUS.SSAP",          "Source Service Access Points",       base.HEX, SAP_VALUE)
fdl_fields.fcs              = ProtoField.uint8 ("PROFIBUS.FCS",           "Frame Check Sequence",               base.HEX)
fdl_fields.ed               = ProtoField.uint8 ("PROFIBUS.ED",            "End Delimiter",                      base.HEX, ED_CODES)

----------------------------------------
-- a table of fields for ALI
local ali_fields = LOGOTD.fields

local COMMAND_CODES = {
--  [0x01] = "Init Start",
--  [0x02] = "Init Complete",
--  [0x03] = "Diagnosis",
  [0x04] = "Stop",
  [0x05] = "Start",
  [0x08] = "Online Test",
  [0x09] = "Function Key",
  [0x10] = "Clock",
--  [0x14] = "",
--  [0x18] = "Message Text",
--  [0x3c] = "",
--  [0x3d] = "",
--  [0x40] = "",
--  [0x5a] = "",
--  [0x5b] = "",
--  [0x61] = "",
--  [0x70] = "",
--  [0x77] = "Update Display",
--  [0x78] = "",
--  [0x81] = "",
}

local LOGICAL_VALUE = {
  [0] = "Low",
  [1] = "High",
}

ali_fields.byte_count     = ProtoField.uint16("LOGOTD.BC",    "Byte Count",     base.DEC)
ali_fields.command_code   = ProtoField.uint8 ("LOGOTD.CMD",   "Command Code",  	base.HEX, COMMAND_CODES)
ali_fields.data           = ProtoField.bytes ("LOGOTD.data",  "Data")
ali_fields.bit0           = ProtoField.uint8 ("LOGOTD.bit0",  "b0",             base.DEC, LOGICAL_VALUE, 0x01)
ali_fields.bit1           = ProtoField.uint8 ("LOGOTD.bit1",  "b1",             base.DEC, LOGICAL_VALUE, 0x02)
ali_fields.bit2           = ProtoField.uint8 ("LOGOTD.bit2",  "b2",             base.DEC, LOGICAL_VALUE, 0x04)
ali_fields.bit3           = ProtoField.uint8 ("LOGOTD.bit3",  "b3",             base.DEC, LOGICAL_VALUE, 0x08)
ali_fields.bit4           = ProtoField.uint8 ("LOGOTD.bit4",  "b4",             base.DEC, LOGICAL_VALUE, 0x10)
ali_fields.bit5           = ProtoField.uint8 ("LOGOTD.bit5",  "b5",             base.DEC, LOGICAL_VALUE, 0x20)
ali_fields.bit6           = ProtoField.uint8 ("LOGOTD.bit6",  "b6",             base.DEC, LOGICAL_VALUE, 0x40)
ali_fields.bit7           = ProtoField.uint8 ("LOGOTD.bit7",  "b7",             base.DEC, LOGICAL_VALUE, 0x80)

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
-- This function calc the Modulo Checksum, Parameter "data" is a ByteAarry
--------------------------------------------------------------------------------
function checkSum8Modulo256(data)
  local cval = 0
  for i = 0, data:len()-1 do
    cval = (cval + data:get_index(i)) % 256
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
-- into several packets. In this case the dissection can�t be carried out
-- correctly until we have all the data. Sometime the first packet doesn�t have
-- enough data, and the subsequent packets don�t have the expect format. To
-- dissect these packets we need to wait until all the parts have arrived and
-- then start the dissection. The following section described all possible
-- cases:
-- 1. A single Telegram may span multiple packets.
-- 2. A single header may also span multiple packets
-- 3. A packet may also contain multiple Telegrams, both complete and fragmented
-- 4. The length of a Telegram is determined by a header field,
--    but an unknown number of bytes must be read before getting to that value,
--    as the header is preceded by a variable length delimiter
-- 5. There are no sequence numbers or other ways of uniquely identifying a
--    Telegram
-- 6. There is no flag indicating whether a Telegram will be fragmented, or
--    whether multiple Telegrams will appear in a packet, other than by reading
--    the length
-- 7. All communications are between a single sender and receiver
--------------------------------------------------------------------------------
local PacketHelper = {}
local PacketHelper_mt = { __index = PacketHelper }

-- Wrapping up the packet dissection
function PacketHelper.new()
  dprint7("PacketHelper:new() called")
  -- Let�s step through adding a basic packet header.
  -- It consists of the following basic items
  local new_class = {  -- the new instance
    -- A telegram counter (valid values are > 0)
    telegram_counter = default_settings.value,

    -- The following tables needs to be cleared by the
    -- protocol "init()" function whenever a capture is reloaded

    -- The following local table holds the packet info;
    -- this is needed to create and keep trackof pseudo headers
    -- for telegrams that went over the serial interface,
    -- for example for sequence number info.
    -- The key index will be a number - the pinfo.number.
    packet_infos = {},

    -- The following local table holds the sequences of a fragmented PDU telegram.
    -- The key index for this is the sequence numper+pinfo.number concatenated.
    -- The value is a table, ByteArray style, holding the fragment of the PDU telegram.
    fragments = {},

  }
  setmetatable( new_class, PacketHelper_mt ) -- all instances share the same metatable
  return new_class
end

--------------------------------------------------------------------------------
-- reference to #5
-- It is important that a sequence number can always be uniquely assigned to a
-- DP telegram so that fragments of a DP telegram are mapped correctly. Since
-- the protocol has no sequence number, we need to generated our own sequence
-- number. There are different approaches to creating a sequence number. We use
-- the storage of the number used first.
--
-- The parameter "pinfo" and "telegram_id" are optional.
-- If telegram_id is specified, this telegram_id will be assign to pinfo, 
-- otherwise the current sequence number will be assigned (if not previously 
-- assigned).If pinfo isn't specified, the current sequence number will be set 
-- to telegram_id. 
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
  local telegram_id = nil
  if type(param2) == "number" then
    telegram_id = param2
  elseif type(param1) == "number" then
    telegram_id = param1
  end

  -- simple type checking
  if (pinfo == nil and telegram_id == nil)
  or (pinfo ~= nil and pinfo["number"] == nil)
  then return 0 end

  if pinfo == nil then
    -- set current sequence number to telegram_id
    self.telegram_counter = telegram_id
  elseif telegram_id ~= nil and self.packet_infos[pinfo.number] ~= nil then
    -- set new sequence number
    dprint6("Upddate sequence number", telegram_id, "to packet", pinfo.number)
    self.packet_infos[pinfo.number].telegram_number = telegram_id
  elseif not pinfo.visited then
    -- if not already available, set flag "start packet" and save the current
    -- sequence number
    telegram_id = self.telegram_counter
    dprint6("Assign sequence number", telegram_id, "to packet", pinfo.number)
    self.packet_infos[pinfo.number] = {
      -- A sequence number - 16 bits.
      telegram_number = telegram_id,
    }
  else
    -- set current sequence number to the previous saved value
    self.telegram_counter = self.packet_infos[pinfo.number].telegram_number
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
  local telegram_id
  if type(pinfo) == "userdata" and pinfo["number"] ~= nil then
    telegram_id = self.packet_infos[pinfo.number] and self.packet_infos[pinfo.number].telegram_number or 0
  else
    telegram_id = self.telegram_counter
  end
  dprint7("PacketHelper:get_number() function called, returned:", telegram_id)
  return telegram_id
end

--------------------------------------------------------------------------------
-- reference to #1
-- A single Telegram may span multiple packets (fragmented = true).
--
-- The parameter "pinfo" is optional. If pinfo is specified and we have
-- fragments for parameter pinfo, the function returned true, otherwise false.
-- If pinfo isn't specified the function returns the same info for the current
-- sequence number
--------------------------------------------------------------------------------
function PacketHelper:fragmented(pinfo)
  -- Check if there are any fragmentations for the sequence number of pinfo
  local telegram_id = self:get_number(pinfo)
  local is_fragmented = self.fragments[telegram_id] ~= nil
  dprint7("PacketHelper:fragmented() function called, returned:", is_fragmented and "true" or "false")
  return is_fragmented
end

--------------------------------------------------------------------------------
-- reference to #6
-- We need to have some way of knowing when the Telegram ends
-- (more_fragment = false)
--
-- The function returned true if packets for parameter "pinfo" has more
-- fragments, otherwiese false.
--------------------------------------------------------------------------------
function PacketHelper:more_fragment(pinfo)
  -- simple type checking
  if type(pinfo) ~= "userdata" or pinfo["number"] == nil then return false end
  telegram_id = self:get_number(pinfo)
  -- Check if we have fragments of this telegram id
  if self.fragments[telegram_id] == nil then return false end
  -- Check if we have more fragments of this telegram id
  -- As a reminder, we don't store the last fragment in our structure
  local last_fragment = self.fragments[telegram_id][pinfo.number] == nil
  dprint7("PacketHelper:more_fragment() function called, returned:", last_fragment and "false" or "true")
  return not last_fragment
end

--------------------------------------------------------------------------------
-- reference to #1
-- Wireshark isn't set up to have dissectors look at any Telegram other than the
-- current telegram. So we need to reassembly the fragmented telegram. 
--------------------------------------------------------------------------------
function PacketHelper:desegment(tvb, pinfo)
  dprint7("PacketHelper:desegment() function called")

  -- simple type checking
  if type(tvb) ~= "userdata"
  or type(pinfo) ~= "userdata"
  or pinfo["number"] == nil
  then return 0 end

  local buffer = tvb
  local telegram_id = self.telegram_counter
  -- Check if there are any fragmentations for this sequence number and if the buffer is the last fragment
  if self.fragments[telegram_id] ~= nil and self.fragments[telegram_id][pinfo.number] == nil then
    -- If there are no more fragments, load the saved data and create a composite "ByteArray"
    local reassembled = ByteArray.new()
    -- Read all previous fragments from our stored structure
    for key,data in pairsByKeys(self.fragments[self.telegram_counter]) do
      dprint6("Read fragment ["..self.telegram_counter..":"..key.."]")
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
-- The correct way to process information in earlier Telegrams is to save it in
-- a data structure for future reference.
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
  if self.fragments[self.telegram_counter] == nil then
    -- there are no fragments yet for this sequence number
    dprint6("Creating fragment table for sequence number:", self.telegram_counter)
    self.fragments[self.telegram_counter] = {}
  else
    -- we already have fragments, so "tvb" is a composite Tvb buffer
    for key,data in pairs(self.fragments[self.telegram_counter]) do
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
    dprint6("Save fragment ["..self.telegram_counter..":"..pinfo.number.."]")
    self.fragments[self.telegram_counter][pinfo.number] = tvb(offset, length):bytes()
  end
  return length
end

-- this holds our "helper"
local packet_helper = nil

-- this holds the plain "data" Dissector, in case we can't dissect it as LOGOTD
local data = Dissector.get("data")

lookup_command_code = {
  [0x08] = {
    dissect = function(tvb, pinfo, tree)
      if tvb:len() < PBUS_ALI_HDR_LEN then return 0 end
      -- 01 + 00 + Byte Count (8bit value)
      local number_of_bytes = tvb(2,1):uint()
      tree:add(ali_fields.data, tvb(0,2))
      tree:add(ali_fields.byte_count, tvb(2,1))
      -- Command Code + ...
      local cmd_code = tvb(3,1):uint()
      tree:add(ali_fields.command_code, tvb(3,1))
      -- If this telegram has no data, then we are done here
      if number_of_bytes == 1 then return PBUS_ALI_HDR_LEN end

      -- ... Data + ...
      local pdu_length = PBUS_ALI_HDR_LEN - 1 + number_of_bytes
      if tvb:len() < pdu_length then return 0 end

      if not default_settings.subdissect then
        tree:add(pg_fields.data, tvb(PBUS_ALI_HDR_LEN, pdu_length - PBUS_ALI_HDR_LEN))
      else
        local offset = PBUS_ALI_HDR_LEN
        local datatree = tree:add(tvb(PBUS_ALI_HDR_LEN, pdu_length - PBUS_ALI_HDR_LEN), "Data bytes")

        -- digital inputs
        local number_of_bits = 24
        local bytes_to_consume = 3
        local bitcount = NumberOfSetBits(tvb(offset, bytes_to_consume):bytes())
        local subtree = datatree:add(tvb(offset, bytes_to_consume), string.format("Digital inputs [Bitcount %d]", bitcount))
        local bit = 1
        while bytes_to_consume > 0 do
          subtree:add(tvb(offset,1), string.format("I%02u-I%02u", bit+7, bit))
          subtree:add(ali_fields.bit0, tvb(offset,1))
          subtree:add(ali_fields.bit1, tvb(offset,1))
          subtree:add(ali_fields.bit2, tvb(offset,1))
          subtree:add(ali_fields.bit3, tvb(offset,1))
          subtree:add(ali_fields.bit4, tvb(offset,1))
          subtree:add(ali_fields.bit5, tvb(offset,1))
          subtree:add(ali_fields.bit6, tvb(offset,1))
          subtree:add(ali_fields.bit7, tvb(offset,1))
          bit = bit + 8
          offset = offset + 1
          bytes_to_consume = bytes_to_consume - 1
        end

        -- function keys
        bitcount = NumberOfSetBits(tvb(offset,1):bytes(), 4)
        subtree = datatree:add(tvb(offset,1), string.format("Function keys [Bitcount %d]", bitcount))
        subtree:add(tvb(offset,1), "F04-F01")
        subtree:add(ali_fields.bit0, tvb(offset,1))
        subtree:add(ali_fields.bit1, tvb(offset,1))
        subtree:add(ali_fields.bit2, tvb(offset,1))
        subtree:add(ali_fields.bit3, tvb(offset,1))
        offset = offset + 1
  
        -- digital outputs
        number_of_bits = 16
        bytes_to_consume = 2
        bitcount = NumberOfSetBits(tvb(offset, bytes_to_consume):bytes())
        subtree = datatree:add(tvb(offset, bytes_to_consume), string.format("Digital outputs [Bitcount %d]", bitcount))
        bit = 1
        while bytes_to_consume > 0 do
          subtree:add(tvb(offset,1), string.format("Q%02u-Q%02u", bit+7, bit))
          subtree:add(ali_fields.bit0, tvb(offset,1))
          subtree:add(ali_fields.bit1, tvb(offset,1))
          subtree:add(ali_fields.bit2, tvb(offset,1))
          subtree:add(ali_fields.bit3, tvb(offset,1))
          subtree:add(ali_fields.bit4, tvb(offset,1))
          subtree:add(ali_fields.bit5, tvb(offset,1))
          subtree:add(ali_fields.bit6, tvb(offset,1))
          subtree:add(ali_fields.bit7, tvb(offset,1))
          bit = bit + 8
          offset = offset + 1
          bytes_to_consume = bytes_to_consume - 1
        end
        
        -- digital merkers
        number_of_bits = 27
        bytes_to_consume = 4
        bitcount = NumberOfSetBits(tvb(offset, bytes_to_consume):bytes(), number_of_bits)
        subtree = datatree:add(tvb(offset, bytes_to_consume), string.format("Digital merkers [Bitcount %d]", bitcount))
        bit = 1
        while bytes_to_consume > 0 do
          subtree:add(tvb(offset,1), string.format("M%02u-M%02u", bit+7 > number_of_bits and number_of_bits or bit+7, bit))
          subtree:add(ali_fields.bit0, tvb(offset,1))
          subtree:add(ali_fields.bit1, tvb(offset,1))
          subtree:add(ali_fields.bit2, tvb(offset,1))
          bit = bit + 3
          if bit < number_of_bits then
            subtree:add(ali_fields.bit3, tvb(offset,1))
            subtree:add(ali_fields.bit4, tvb(offset,1))
            subtree:add(ali_fields.bit5, tvb(offset,1))
            subtree:add(ali_fields.bit6, tvb(offset,1))
            subtree:add(ali_fields.bit7, tvb(offset,1))
            bit = bit + 5
          end
          offset = offset + 1
          bytes_to_consume = bytes_to_consume - 1
        end
        
        -- shift register
    		bitcount = NumberOfSetBits(tvb(offset,1):bytes())
        subtree = datatree:add(tvb(offset,1), string.format("Shift register [Bitcount %d]", bitcount))
        subtree:add(tvb(offset,1), "S08-S01")
        subtree:add(ali_fields.bit0, tvb(offset,1))
        subtree:add(ali_fields.bit1, tvb(offset,1))
        subtree:add(ali_fields.bit2, tvb(offset,1))
        subtree:add(ali_fields.bit3, tvb(offset,1))
        subtree:add(ali_fields.bit4, tvb(offset,1))
        subtree:add(ali_fields.bit5, tvb(offset,1))
        subtree:add(ali_fields.bit6, tvb(offset,1))
        subtree:add(ali_fields.bit7, tvb(offset,1))
        offset = offset + 1
        
        -- cursor keys
    		bitcount = NumberOfSetBits(tvb(offset,1):bytes(), 4)
        subtree = datatree:add(tvb(offset,1), string.format("Cursor keys [Bitcount %d]", bitcount))
        subtree:add(tvb(offset,1), "C04-C01")
        subtree:add(ali_fields.bit0, tvb(offset,1))
        subtree:add(ali_fields.bit1, tvb(offset,1))
        subtree:add(ali_fields.bit2, tvb(offset,1))
        subtree:add(ali_fields.bit3, tvb(offset,1))
        offset = offset + 1
  
        -- analog inputs (16bit Big Endian)
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
          subtree:add(tvb(offset,2), string.format("AI%u: %d", analog, tvb(offset,2):int()))
          analog = analog + 1
          offset = offset + 2
          bytes_to_consume = bytes_to_consume - 2
        end
  
        -- analog outputs (16bit Big Endian)
        flag = 0
        for i = offset, offset+4-1 do
          if tvb(i,1):uint() ~= 0 then
          flag = 1
          break
          end
        end
        subtree = datatree:add(tvb(offset,4), string.format("Analog outputs [%s]", FLAG_VALUE[flag]))
        subtree:add(tvb(offset,2), string.format("AQ1: %d", tvb(offset,2):int()))
        offset = offset + 2
        subtree:add(tvb(offset,2), string.format("AQ2: %d", tvb(offset,2):int()))
        offset = offset + 2
  
        -- analog merkers (16bit Big Endian)
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
          subtree:add(tvb(offset,2), string.format("AM%u: %d", analog, tvb(offset,2):int()))
          analog = analog + 1
          offset = offset + 2
          bytes_to_consume = bytes_to_consume - 2
        end
      end

      return pdu_length
    end
  },
  [0x09] = {
    dissect = function(tvb, pinfo, tree)
      if tvb:len() < PBUS_ALI_HDR_LEN then return 0 end
      -- 01 + 00 + Byte Count (8bit value)
      local number_of_bytes = tvb(2,1):uint()
      tree:add(ali_fields.data, tvb(0,2))
      tree:add(ali_fields.byte_count, tvb(2,1))
      -- Command Code + ...
      local cmd_code = tvb(3,1):uint()
      tree:add(ali_fields.command_code, tvb(3,1))
      -- If this telegram has no data, then we are done here
      if number_of_bytes == 1 then return PBUS_ALI_HDR_LEN end

      -- ... Data + ...
      local pdu_length = PBUS_ALI_HDR_LEN - 1 + number_of_bytes
      if tvb:len() < pdu_length then return 0 end
      tree:add(ali_fields.data, tvb(PBUS_ALI_HDR_LEN, pdu_length - PBUS_ALI_HDR_LEN))
      return pdu_length
    end
  },
}

--------------------------------------------------------------------------------
-- The following function returns the length of the PROFIBUS-DP FDL (Layer 2)
--
-- This function returns the length of the telegram, or
-- DESEGMENT_ONE_MORE_SEGMENT if the Tvb doesn't have enough information to get
-- the length, or a 0 for error.
local function get_fdl_length(tvb, pinfo, offset)
  dprint7("get_fdl_length() function called")

  local length = 0

  -- "length" is the number of bytes remaining in the Tvb buffer 
  local length = tvb:len() - offset

  -- check if the Tvb buffer has enough remaining bytes
  if length <= 0 then
    dprint7("Remaining bytes were shorter than original")
    return 0
  end

  -- if we got here, then we know we have at least 1 byte in the tvb
  -- to figure out the fdl type
  local fdl_type = tvb(offset, 1):uint()
  offset = offset + 1
  
  if fdl_type == 0x68 then
    -- SD2 (68h) has a variable data length
    if length >= 3 then
      -- if we got here, then we know we have enough bytes in the tvb
      -- to get the "LE" field
      local le = tvb(offset, 2):uint()
      -- SD2 + LE (2 Bytes) + LEr (2 Bytes) + SD2 + ... + FCS + ED
      length = 1 + 2 + 2 + 1 + le + 1 + 1
    else
      length = -1
    end
  else
    dprint6("Unknown FDL type:", fdl_type)
    return 0
  end

  if length < 0 then
    -- we need more bytes, so tell the main function that we
    -- didn't get the length, and we need an unknown number of more
    -- bytes (which is what "DESEGMENT_ONE_MORE_SEGMENT" is used for)
    dprint7("Need more bytes to figure out the Telegram length")
    return DESEGMENT_ONE_MORE_SEGMENT
  end
  
  if length > default_settings.max_telegram_len then
    -- too many bytes, invalid telegram
    dprint4("Telegram length is too long:", length)
    return 0
  end

  dprint7("Telegram length:", length)
  return length
end

--------------------------------------------------------------------------------
-- The following function returns the length of the PROFIBUS-DP ALI (Layer 7)
--
-- This function returns the length of the telegram, or
-- DESEGMENT_ONE_MORE_SEGMENT if the Tvb doesn't have enough information to get
-- the length, or a 0 for error.
local function get_ali_length(tvb, pinfo, offset)
  dprint7("get_ali_length() function called")

  local length = 0

  -- "length" is the number of bytes remaining in the Tvb buffer 
  local length = tvb:len() - offset

  -- check if the Tvb buffer has enough remaining bytes
  if length <= 0 then
    dprint7("Remaining bytes were shorter than original")
    return 0
  end

  if length >= 3 then
    offset = offset + 2
    -- if we got here, then we know we have enough bytes in the tvb
    -- to get the "BC" field
    local bc = tvb(offset, 1):uint()
    -- 01 + 00 + BC + ...
    length = 1 + 1 + 1 + bc
  else
    length = -1
  end

  if length < 0 then
    -- we need more bytes, so tell the main function that we
    -- didn't get the length, and we need an unknown number of more
    -- bytes (which is what "DESEGMENT_ONE_MORE_SEGMENT" is used for)
    dprint7("Need more bytes to figure out the ALI length")
    return DESEGMENT_ONE_MORE_SEGMENT
  end
  
  dprint7("Application Layer Interface length:", length)
  return length
end

--------------------------------------------------------------------------------
-- The following creates the callback function for the TD dissector.
--
-- The 'tvb' contains the packet data, 'pinfo' is a packet info object,
-- and 'tree' is the object of the Wireshark tree view which are create in the
-- PROFIBUS Proto's dissector.
--
-- 1. If the packet does not belong to our dissector, we return 0.
--    We must not set the Pinfo's "desegment_len" nor the "desegment_offset". 
-- 2. If we need more bytes, we set the Pinfo's "desegment_len/desegment_offset"
---   and return the length of the Tvb.
-- 3. If we don't need more bytes, we return the number of bytes of the Tvb
--    that belong to this protocol.
--------------------------------------------------------------------------------
function LOGOTD.dissector(tvb, pinfo, tree)
  dprint6("TD Protocol dissector() called, Telegram id:", packet_helper:get_number())

  -- "length" is the number of bytes remaining in the Tvb buffer
  local length = tvb:len()
  -- return 0, if the packet does not have a valid length
  if length == 0 then return 0 end

  -- "ali_length" is the number of bytes for the ALI
  local ali_length = get_ali_length(tvb, pinfo, 0)
  -- return 0, if the packet does not belong to your dissector
  if ali_length == 0 then return 0 end

  if length < ali_length then
    -- print Tvb as data, because we don't have the full ALI
    data:call(tvb, pinfo, tree)

    -- we need more bytes to get the full ALI
    dprint6("Need more bytes to desegment TD-Protocol")

    if ali_length == DESEGMENT_ONE_MORE_SEGMENT then
      -- we don't know exactly how many more bytes we need
      -- set the Pinfo "desegment_len" to the predefined value "DESEGMENT_ONE_MORE_SEGMENT"
      pinfo.desegment_len = DESEGMENT_ONE_MORE_SEGMENT
    else
      -- set Pinfo's "desegment_len" to how many more bytes we need to decode the full ALI
      pinfo.desegment_len = ali_length - length
    end
    -- We also need to set the "dessegment_offset",
    -- so that the dissector can continue processing at the same position.
    pinfo.desegment_offset = 0

    -- We set desegment_len/desegment_offset as described earlier,
    -- so we return the length of the Tvb
    return length
  end
  -- if we got here, then we have a whole ALI in the Tvb buffer

  -- We start by setting our protocol name, info and tree
  -- set the protocol column to show our protocol name
  pinfo.cols.protocol = LOGOTD.name

  -- add our protocol to the dissection display tree.
  local subtree = tree:add(LOGOTD)
  local offset = 0
  local cmd_code = tvb(3,1):uint()
  if lookup_command_code[cmd_code] then
    offset = lookup_command_code[cmd_code].dissect(tvb, pinfo, subtree)
  else
    -- 01 + 00 + Byte Count (8bit value) + Command Code + ...
    subtree:add(ali_fields.data, tvb(0,2))
    subtree:add(ali_fields.byte_count, tvb(2,1))
    subtree:add(ali_fields.command_code, tvb(3,1))
    offset = PBUS_ALI_HDR_LEN
  end

  -- append the INFO column
  if string.find(tostring(pinfo.cols.info), " Len=") == nil then
    if COMMAND_CODES[cmd_code] then
      pinfo.cols.info:append(string.format(", %s", COMMAND_CODES[cmd_code]))
    else
      pinfo.cols.info:append(string.format(", CMD=0x%02x", cmd_code))
    end
    pinfo.cols.info:append(string.format(" Len=%d", ali_length))
  end
  
  -- if we got here, then we have only data bytes in the Tvb buffer
  data:call(tvb(offset, ali_length - offset):tvb(), pinfo, subtree)

  -- we don't need more bytes, so we return the number of bytes of the ALI
  return ali_length
end

--------------------------------------------------------------------------------
-- We need initialization routine, to reset the var(s) whenever a capture is
-- restarted or a capture file loaded.
--------------------------------------------------------------------------------
function PROFIBUS.init()
  dprint6("PROFIBUS (re-)initialise")
  -- PROFIBUS packet helper
  packet_helper = PacketHelper.new()
end

--------------------------------------------------------------------------------
-- The following is a local function used for dissecting our PROFIBUS-DP
-- telegrams inside the PROFIBUS frames using the desegment_offset/desegment_len
-- method. It's a separate function because we run over a Serial Interface and
-- thus might need to parse multiple messages in a single segment/packet. So we
-- invoke this function only dissects one PROFIBUS-DP message and we invoke it
-- in a while loop from the Proto's main disector function.
--
-- This function is passed in the original Tvb, Pinfo, and TreeItem from the
-- Proto's dissector function, as well as the offset in the Tvb that this
-- function should start dissecting from.
--
-- This function returns the length of the PROFIBUS-DP telegram it dissected as
-- a positive number, or DESEGMENT_ONE_MORE_SEGMENT if the Tvb doesn't have
-- enough information to get the length, or a 0 for error.
--------------------------------------------------------------------------------
local function dissectPBUS(tvb, pinfo, tree, offset)
  dprint7("PROFIBUS dissect() function called")

  local length = get_fdl_length(tvb, pinfo, offset)

  if length <= 0 then
    return 0
  elseif length >= DESEGMENT_ONE_MORE_SEGMENT then
    return DESEGMENT_ONE_MORE_SEGMENT
  end

  -- currently only SD2 telegrams must be decoded
  local fdl_type = tvb(offset, 1):uint()
  if fdl_type ~= 0x68 then
    return 0
  end

  -- if we got here, then we have a SD2 telegram in the Tvb buffer
  -- so let's finish dissecting it...

  -- dissect the header (SD2) incl. there length fields (LE, LEr)
  local telegram = tvb(offset, 1):uint()
  tree:add(fdl_fields.telegram, tvb(offset, 1))
  offset = offset + 1
  tree:add(fdl_fields.le, tvb(offset, 2))
  offset = offset + 2
  tree:add(fdl_fields.ler, tvb(offset, 2))
  offset = offset + 2
  tree:add(fdl_fields.telegram2, tvb(offset, 1))
  offset = offset + 1

  -- calculate the checksum starting from DA including DU
  local checksum = checkSum8Modulo256(tvb(offset, length - PBUS_FDL_HDR_LEN - PBUS_TRAILER_LEN):bytes())

  -- dissect the "source and destination address" fields (DA and SA)
  local dst_addr = tvb(offset, 1):uint()
  tree:add(fdl_fields.da, tvb(offset, 1))
  offset = offset + 1
  local src_addr = tvb(offset, 1):uint()
  tree:add(fdl_fields.sa, tvb(offset, 1))
  offset = offset + 1

  -- set the SOURCE and DESITNATION columns
  if string.find(tostring(pinfo.cols.src), "0x%x%x") == nil then
    pinfo.cols.src:set(string.format("0x%02x", src_addr))
    pinfo.cols.dst:set(string.format("0x%02x", dst_addr))
  end

  -- dissect the "frame control" field (FC)
  local frame_control = tvb(offset, 1):uint()
  tree:add(fdl_fields.fc, tvb(offset, 1))
  offset = offset + 1

 -- dissect the "data unit" fields (DSAP and SSAP)
  local subtree = tree:add(tvb(offset, length - PBUS_SD2_HDR_LEN - PBUS_TRAILER_LEN), "Data Unit (DU)")
  subtree:add(fdl_fields.dsap, tvb(offset, 1))
  subtree:add(fdl_fields.ssap, tvb(offset + 1, 1))
  offset = offset + length - PBUS_SD2_HDR_LEN - PBUS_TRAILER_LEN

  -- dissect the "trailer" fields (FCS and ED)
  local fcs_byte = tvb(offset, 1):uint()
  if fcs_byte == checksum then
    tree:add(fdl_fields.fcs, tvb(offset, 1), fcs_byte, nil, "[correct]")
  else
    local incorrect = string.format("[incorrect, should be 0x%02x]", checksum)
    tree:add(fdl_fields.fcs, tvb(offset, 1), fcs_byte, nil, incorrect)
  end
  offset = offset + 1
  tree:add(fdl_fields.ed, tvb(offset, 1))

  -- set the INFO column, but only if we haven't already set it before for this
  -- packet, because this function can be called multiple times per packet
  if string.find(tostring(pinfo.cols.info), "Seq=%d") == nil then
    local src = string.sub(ADDRESS_VALUE[src_addr], 1, 1)
    local dst = string.sub(ADDRESS_VALUE[dst_addr], 1, 1)
    if src and dst then
      pinfo.cols.info:set(string.format("%s > %s", src, dst))
    else
      pinfo.cols.info:set(string.format("%d > %d", src_addr, dst_addr))
    end
    if FDL_CODES[telegram] then
      pinfo.cols.info:append(string.format(" [%s", FDL_CODES[telegram]))
    else
      pinfo.cols.info:append(string.format(" [FDL=%0x%02x", telegram))
    end
    if FC_CODES[frame_control] then
      pinfo.cols.info:append(string.format(", %s]", FC_CODES[frame_control]))
    else
      pinfo.cols.info:append(string.format(", FC=%0x%02x]", frame_control))
    end
    pinfo.cols.info:append(string.format(" Seq=%d", packet_helper:get_number()))
  end

  -- we are finished, now the dissected length will be returned
  return length
end

--------------------------------------------------------------------------------
-- The following creates the callback function for the PROFIBUS dissector.
-- It's implemented as a separate Protocal because we run over a serial
-- interface and thus might need to parse a single telegram over multiple
-- packets. So we invoke this function for desegmented telegrams.
--
-- The 'tvb' contains the packet data, 'pinfo' is a packet info object, and
-- 'root' is the root of the Wireshark tree view.
--
-- Whenever Wireshark dissects a packet that our Proto is hooked into, it will
-- call this function and pass it these arguments for the packet it's
-- dissecting.
--------------------------------------------------------------------------------
function PROFIBUS.dissector(tvb, pinfo, root)
  dprint7("PROFIBUS dissector() called, length:", tvb:len())

  -- get the length of the packet tvb
  local length = tvb:len()
  if length == 0 then return end

  -- check if capture was only capturing partial packet size
  if length ~= tvb:reported_len() then
    -- captured packets are being sliced/cut-off, so don't try to
    -- desegment/reassemble
    dprint4("Captured packet was shorter than original, can't reassemble")
    -- Returning 0 tells Wireshark this packet is not for us, and it will try
    -- heuristic dissectors or the plain "data" one, which is what should happen
    -- in this case.
    return 0
  end

  -- set the protocol column to show our protocol name
  pinfo.cols.protocol = PROFIBUS.name

  -- update the current packet info to our structure
  local result = packet_helper:set_number(pinfo)
  if result == 0 then return 0 end

  local flags = 0
  -- display the fragments as data
  if packet_helper:fragmented() and packet_helper:more_fragment(pinfo) then
    -- From here we know that the frame is part of a PROFINET telegram (but not
    -- the last on).
    pinfo.cols.info:set(string.format("[Telegram Fragment] Seq=%d", packet_helper:get_number()))
    -- The Tvb buffer is a fragment of a PROFINET telegram, so display only the
    -- meta fields and the data to the tree
    local subtree = root:add(PROFIBUS)
    flags = bit.bor(flags, FL_FRAGMENT)
    subtree:add(fdl_fields.telegram_number, packet_helper:get_number()):set_generated()
    local flagtree = subtree:add(fdl_fields.flags, flags):set_generated()
    flagtree:add(fdl_fields.fragmented, flags)
    -- call the data dissector
    data:call(tvb, pinfo, root)
    return length
  end

  -- Now, we dissect the (original or composite) Tvb buffer
  local buffer = tvb
  -- reassembly the telegram if needed
  if packet_helper:fragmented() then
    buffer = packet_helper:desegment(tvb, pinfo)
    -- update the length, beacause we can have a new buffer
    length = buffer:len()
    if length == 0 then return 0 end
  end
  
  -- reference to #3
  -- That's similar to many protocols running atop TCP, so that's not inherently
  -- insoluble.
  local bytes_consumed = 0
  while bytes_consumed < length do
    -- reference to #4
    result = get_fdl_length(buffer, pinfo, bytes_consumed)
    if result == 0 then
      -- If the result is 0, then it means we hit an error of some kind,
      -- so increment sequence and return 0.
      packet_helper:set_number(packet_helper:get_number() + 1)
      return 0
    end

    -- if we got here, then we know we have a PROFIBUS-DP telegram in the Tvb buffer
    local subtree = root:add(PROFIBUS)
    -- check if the remaning bytes in buffer are a part of a PROFIBUS-DP
    -- telegram or not
    local fragmented = bytes_consumed + result > length
    -- Inserted the telegram fields to the tree
    flags = 0
    if not fragmented then flags = bit.band(flags, bit.bnot(FL_FRAGMENT)) end
    subtree:add(fdl_fields.telegram_number, packet_helper:get_number()):set_generated()
    local flagtree = subtree:add(fdl_fields.flags, flags):set_generated()
    flagtree:add(fdl_fields.fragmented, flags)

    -- reference to #1 and #3
    -- We might have to implement something similar to TCP in our dissector.
    -- For that we using old desegment_offset/desegment_len method
    if fragmented then
      -- call the data dissector
      data:call(buffer(bytes_consumed, length - bytes_consumed):tvb(), pinfo, root)

      -- we need more bytes, so set the desegment_offset to what we already
      -- consumed, and the desegment_len to how many more are needed and save
      -- the fragment to our structure
      pinfo.desegment_offset = bytes_consumed
      pinfo.desegment_len = result
      packet_helper:set_fragment(buffer, pinfo)

      -- even though we need more bytes, this packet is for us, so we tell
      -- Wireshark all of its bytes are for us by returning the number of Tvb
      -- bytes we "successfully processed", namely the length of the Tvb buffer
      return length
    end

    -- the real PROFIBUS-DP dissector starts here

    -- We're going to call our "dissect()" function, which is defined earlier in
    -- this script file. The dissect() function returns the length of the
    -- PROFIBUS-DP SD2 telegram it dissected as a positive number, or if the
    -- value is DESEGMENT_ONE_MORE_SEGMENT then we need additional bytes. If it
    -- returns a 0, it's a dissection error.
    if dissectPBUS(buffer, pinfo, subtree, bytes_consumed) == 0 then
      -- If the result is 0, then it means we hit an error
      return 0
    end

    -- we successfully processed the PROFIBUS-DP telegram fields, now invoke the
    -- LOGOTD dissector
    local proto_offset = bytes_consumed + PBUS_SD2_HDR_LEN + PBUS_DDLM_HDR_LEN
    local proto_length = result - PBUS_SD2_HDR_LEN - PBUS_DDLM_HDR_LEN - PBUS_TRAILER_LEN
    result = Dissector.get("logotd"):call(buffer(proto_offset, proto_length):tvb(), pinfo, root)
    if result == 0 then
      -- If the result is 0, then it means we hit an error
      return 0
    end
    -- we successfully processed the LOGOTD dissector, of 'result' length
    bytes_consumed = bytes_consumed + PBUS_SD2_HDR_LEN + PBUS_DDLM_HDR_LEN + result + PBUS_TRAILER_LEN
    
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
dprint6("Initialization of PROFIBUS protocol")

-- load the wtap_encap table
local wtap_encap_table = DissectorTable.get("wtap_encap")

-- register our protocol to USER0
dprint7("Register PROFIBUS protocol for USER0")
wtap_encap_table:add(wtap.USER0, PROFIBUS)


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
PROFIBUS.prefs.value      = Pref.uint("Value", default_settings.value, "Start value for counting")

PROFIBUS.prefs.subdissect = Pref.bool("Enable sub-dissectors", default_settings.subdissect, 
                                      "Whether the data content should be dissected or not")

PROFIBUS.prefs.debug      = Pref.enum("Debug", default_settings.debug_level,
                                      "The debug printing level", debug_pref_enum)

--------------------------------------------------------------------------------
-- the function for handling preferences being changed
function PROFIBUS.prefs_changed()
  dprint6("PROFIBUS prefs_changed() called")

  default_settings.value = PROFIBUS.prefs.value
  default_settings.subdissect = PROFIBUS.prefs.subdissect
  default_settings.debug_level = PROFIBUS.prefs.debug
  reset_debug_level()
  
  -- have to reload the capture file for this type of change
  reload()
end

dprint7("PCapfile Prefs registered")
