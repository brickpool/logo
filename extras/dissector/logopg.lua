-------------------------------------------------------------------------------
-- This dissector decodes an LOGO PG protocol.
-- use with: wireshark -Xlua_script:logopg.lua example.pcap
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
--  p_frag.lua      by mj99, https://osqa-ask.wireshark.org/answer_link/55764/
--
-- History:
--  0.1   04.04.2018      inital version
--  0.2   05-11.04.2018   desegmentation of packets
--  0.2.1 11.04.2018      bug fixing
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
local DEBUG = debug_level.LEVEL_7

-- a table of our default settings - these can be changed by changing
-- the preferences through the GUI or command-line; the Lua-side of that
-- preference handling is at the end of this script file
local default_settings = {
  debug_level   = DEBUG,
  enabled       = true,   -- whether this dissector is enabled or not
  max_msg_len   = 2002,   -- this is the maximum size of a message
  value         = 1,      -- start value for message counting
}

local dprint4 = function() end
local dprint6 = function() end
local dprint7 = function() end
local function reset_debug_level()
  if default_settings.debug_level > debug_level.DISABLED then
    dprint4 = function(...) warn(table.concat({...}," ")) end
  else
    dprint4 = function() end
  end

  if default_settings.debug_level > debug_level.LEVEL_4 then
    dprint6 = function(...) info(table.concat({...}," ")) end
  else
    dprint6 = function() end
  end

  if default_settings.debug_level > debug_level.LEVEL_6 then
    dprint7 = function(...) debug(table.concat({...}," ")) end
  else
    dprint7 = function() end
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

local msg_index = 0
local FLAG_VALUE    = { [0] = "Not Set", [1] = "Set" }
local FL_FRAGMENT   = 0x01

-- Message fields
ppi_fields.sequence_number  = ProtoField.uint32("LOGOPPI.sequence_number",  "Sequence number")
ppi_fields.flags            = ProtoField.uint8 ("LOGOPPI.Flags",            "Flags",          base.HEX)
ppi_fields.fragmented       = ProtoField.uint8 ("LOGOPPI.fragmented",       "More Fragment",  base.DEC, FLAG_VALUE, 0x01)

----------------------------------------
-- a table of our PG-Protocol fields
local pg_fields = LOGOPG.fields

-- ADU fields
pg_fields.transaction_id  = ProtoField.uint16("LOGOPG.transaction_id",  "Transaction identifier", base.DEC)
pg_fields.unit_id         = ProtoField.uint8 ("LOGOPG.unit_id",         "Unit identifier",        base.HEX)
pg_fields.pdu_length      = ProtoField.uint16("LOGOPG.pdu_length",      "PDU Length",             base.DEC)

-- PDU fields
pg_fields.message_type    = ProtoField.uint8 ("LOGOPG.message_type",    "Message Type",   base.HEX)
pg_fields.address         = ProtoField.uint32("LOGOPG.address",         "Address",        base.HEX)
pg_fields.function_code   = ProtoField.uint16("LOGOPG.function_code",   "Function Code",  base.HEX)
pg_fields.byte_count      = ProtoField.uint16("LOGOPG.byte_count",      "Byte Count",     base.DEC)
pg_fields.end_delimiter   = ProtoField.uint8 ("LOGOPG.end_delimiter",   "End Delimiter",  base.HEX)

--------------------------------------------------------------------------------
-- We need initialization routine, to reset the var(s) whenever a capture
-- is restarted or a capture file loaded.
-- The vars would just be local to our whole script. That's why we need to
-- set or reset it, because wireshark doesn't provide anything to do that for
-- us automatically
--------------------------------------------------------------------------------
function LOGOPPI.init()
  dprint7("PPI (re-)initialise")

  msg_index = default_settings.value
  packet_info = {}
  packet_info[0] = {
    next_seq_number   = msg_index,
    desegment_len     = 0,
    desegment_offset  = 0,
  }
  fragments = {}
end

-- this holds the plain "data" Dissector, in case we can't dissect it as LOGOPG
local data = Dissector.get("data")

local lookup_function_code = {
  [0x1111] = {
    name = "Data Response",
	pdu_length = function(tvb)
      if tvb:len() < 6 then return -1 end
      -- Confirmation Code + Control Code + Function Code + Byte Count + Data + End Delimiter
      return 1 + 1 + 2 + 2 + tvb(4,2):le_uint() + 1
    end
  },
  [0x1212] = {
    name = "Stop Operating",
	pdu_length = function(...)
      -- Control Code + Function Code + End Delimiter
      return 4
    end
  },
  [0x1313] = {
    name = "Start Fetch Data",
	pdu_length = function(tvb)
      if tvb:len() < 4 then return -1 end
      -- Control Code + Function Code + Byte Count + Data + End Delimiter
      return 1 + 2 + 1 + tvb(3,1):uint() + 1
    end
  },
  [0x1414] = {
    name = "Stop Fetch Data",
	pdu_length = function(...)
      -- Control Code + Function Code + End Delimiter
      return 4
    end
  },
  [0x1717] = {
    name = "Operation Mode",
	pdu_length = function(...)
      -- Control Code + Function Code + End Delimiter
      return 4
    end
  },
  [0x1818] = {
    name = "Start Operating",
	pdu_length = function(...)
      -- Control Code + Function Code + End Delimiter
      return 4
    end
  },
}

local lookup_message_type = {
  [0x00] = {
    name = "No Operation",
	pdu_length = function(...)
      return 1
    end
  },
  [0x01] = {
    name = "Write Byte",
	pdu_length = function(...)
      -- Data Code + Address + Data Byte
      return 4
    end
  },
  [0x02] = {
    name = "Read Byte",
	pdu_length = function(...)
      -- Data Code + Address
      return 3
    end
  },
  [0x04] = {
    name = "Write Block",
	pdu_length = function(tvb)
      if tvb:len() < 5 then return -1 end
      -- Data Code + Address + Byte Count + Data + Checksum
      return 1 + 2 + 2 + tvb(3,2):le_uint() + 1
    end
  },
  [0x05] = {
    name = "Read Block",
	pdu_length = function(...)
      -- Data Code + Address + Byte Count
      return 5
    end
  },
  [0x06] = {
    name = "Acknowledge Response",
	pdu_length = function(...)
      -- Confirmation Code + ...
      return 1
    end
  },
  [0x15] = {
    name = "Exception Response",
	pdu_length = function(...)
      -- Confirmation Code + Exception Code
      return 2
    end
  },
  [0x20] = {
    name = "Clear Program",
	pdu_length = function(...)
      return 1
    end
  },
  [0x21] = {
    name = "Connect Request",
	pdu_length = function(...)
      return 1
    end
  },
  [0x22] = {
    name = "Restart",
	pdu_length = function(...)
      return 1
    end
  },
  [0x55] = {
    name = "Control Command",
	pdu_length = function(tvb)
      if tvb:len() < 3 then return -1 end
      -- Control Code + Function Code + ...
      local func = lookup_function_code[tvb(1,2):uint()]
      if func and func.pdu_length then
        return func.pdu_length(tvb)
      else
        return -1
      end
    end
  },
}

--------------------------------------------------------------------------------
-- the following function returns the length of a PDU message
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
    dprint6("Message length is too long:", length)
    return 0
  end

  dprint7("PDU length:", length)
  return length
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

  dprint6("PG Protocol dissector called")

  -- "length" is the number of bytes remaining in the Tvb buffer
  local length = tvb:len()
  -- return 0, if the packet does not have a valid length
  if length == 0 then return 0 end

  -- "pdu_length" is the number of bytes for the PDU
  local pdu_length = get_pdu_length(tvb, pinfo, 0)
  -- return 0, if the packet does not belong to your dissector
  if pdu_length == 0 then return pdu_length end

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

  -- set the protocol column to show our protocol name
  pinfo.cols.protocol = LOGOPG.name

  -- We start by adding our protocol to the dissection display tree.
  local subtree = tree:add(LOGOPG)

  -- if we got here, then we have a whole ADU header in the Tvb buffer
  -- so let's dissecting the ADU header
  subtree:add(pg_fields.pdu_length, pdu_length):set_generated()

  -- Next, the PDU data will be displayed
  local offset = 0
  local pdutree = subtree:add(tvb(), "Protocol Data Unit (PDU)")
  local message_type = tvb(0,1):uint()
  pdutree:add(pg_fields.message_type, tvb(0,1))
  offset = 1

  if message_type == 0x01
  or message_type == 0x02
  or message_type == 0x04
  or message_type == 0x05
  then
    if length >= 3 then
      -- Address (16bit value Big-Endian)
      address = tvb(1, 2):uint()
      pdutree:add(pg_fields.address, tvb(1,2))
      offset = 3
    end
  end

  if message_type == 0x04
  or message_type == 0x05
  then
    if length >= 5 then
      -- Number of Bytes (16bit value Little-Endian)
      pdutree:add_le(pg_fields.byte_count, tvb(3,2))
      offset = 5
    end
  end

  if message_type == 0x06 then
    -- Acknowledge Response
  end

  if message_type == 0x15 then
    -- Exception Response
  end

  if message_type == 0x55 then
    if length >= 3 then
      function_code = tvb(1,2):uint()
      pdutree:add(pg_fields.function_code, tvb(1,2))
      if function_code == 0x1313 and length >= 4 then
        -- Number of Bytes (8bit value)
        byte_count = tvb(3, 1):uint()
        pdutree:add(pg_fields.byte_count, tvb(3,1))
        offset = 3
      end
    end
    if pdu_length-1 < length then
      pdutree:add(pg_fields.end_delimiter, tvb(pdu_length-1, 1))
      offset = pdu_length
    end
  end

  -- if we got here, then we have a whole PDU in the Tvb buffer
  data:call(tvb(offset, pdu_length - offset):tvb(), pinfo, subtree)

  -- we don't need more bytes, so we return the number of bytes of the PDU
  return pdu_length
end


--------------------------------------------------------------------------------
-- The 'tvb' contains the packet data, 'pinfo' is a packet info object,
-- and 'root' is the object of the Wireshark tree view which are create in the
-- PPI Proto's dissector.
--------------------------------------------------------------------------------
local function dissect(tvb, pinfo, root)

  dprint7("dissect() function called")

  local length = tvb:len()

  local bytes_consumed = 0

  -- set the protocol column to show our protocol name
  pinfo.cols.protocol = LOGOPPI.name

  while bytes_consumed < length do

    local result = get_pdu_length(tvb, pinfo, bytes_consumed)
    if result == 0 then
      -- If the result is 0, then it means we hit an error of some kind,
      -- so return 0. Returning 0 tells Wireshark this packet is not for
      -- us, and it will try heuristic dissectors or the plain "data"
      -- one, which is what should happen in this case.
      return 0
    end

    -- if we got here, then we know we have a PG message in the Tvb buffer
    local subtree = root:add(LOGOPPI)

    -- Inserted the message fields to the tree
    subtree:add(ppi_fields.sequence_number, msg_index):set_generated()
    local flags = 0
    if result < 0 or bytes_consumed + result > length then
      flags = bit.bor(flags, FL_FRAGMENT)
    else
      flags = bit.band(flags, bit.bnot(FL_FRAGMENT))
    end
    local flagtree = subtree:add(ppi_fields.flags, flags):set_generated()
    flagtree:add(ppi_fields.fragmented, flags)

    -- Te real dissector starts here
    result = Dissector.get("logopg"):call(tvb(bytes_consumed, length - bytes_consumed):tvb(), pinfo, root)
    if result == 0 then
      -- If the result is 0, then it means we hit an error
      return 0
    end
    
    if pinfo.desegment_len > 0 then
      -- we need more bytes, so set the desegment_offset to what we
      -- already consumed, and the desegment_len to how many more
      -- are needed
      pinfo.desegment_offset = bytes_consumed

      -- even though we need more bytes, this packet is for us, so we
      -- tell wireshark all of its bytes are for us by returning the
      -- number of tvb bytes we "successfully processed", namely the
      -- length of the tvb
      return length
    end

    -- we successfully processed an PG message, of 'result' length
    bytes_consumed = bytes_consumed + result
    -- increment msg_index
    msg_index = msg_index + 1
      
  end

  -- Do NOT return the number 0, or else Wireshark will interpret that to mean
  -- this packet did not belong to your protocol, and will try to dissect it
  -- with other protocol dissectors (such as heuristic ones)
  return bytes_consumed
end


--------------------------------------------------------------------------------
-- The following creates the callback function for the PPI dissector.
-- It's implemented as a separate Protocal because we run over a serial
-- interface and thus might need to parse a single message over multiple packets.
-- So we invoke this function for desegmented messages.

-- The 'tvb' contains the packet data, 'pinfo' is a packet info object,
-- and 'root' is the root of the Wireshark tree view.
--
-- Whenever Wireshark dissects a packet that our Proto is hooked into, it will
-- call this function and pass it these arguments for the packet it's dissecting.
--------------------------------------------------------------------------------
function LOGOPPI.dissector(tvb, pinfo, root)

  dprint6("PPI dissector called, length:", tvb:len())

  -- get the length of the packet tvb
  local length = tvb:len()
  if length == 0 then return end

  -- check if capture was only capturing partial packet size
  if length ~= tvb:reported_len() then
    -- captured packets are being sliced/cut-off, so don't try to desegment/reassemble
    dprint6("Captured packet was shorter than original, can't reassemble")
    return 0
  end

  -- Wireshark isn't set up to have dissectors look at any packet other than the current packet
  -- the correct way to process information in earlier packets is to save it for future reference
  if not pinfo.visited then
    -- create new desegment info pg_fields for this packet
    if packet_info[pinfo.number] == nil then
      packet_info[pinfo.number] = {
        next_seq_number   = msg_index,
        desegment_len     = 0,
        desegment_offset  = 0,
      }
      dprint7("Creating packet info:", pinfo.number)
    end

    if fragments[pinfo.number] == nil then
      local bytes = tvb():bytes()
      fragments[pinfo.number] = bytes
      dprint7("Store packet:", pinfo.number)
    end
  end

  local offset, bytes_needed = 0, 0
  if packet_info[pinfo.number-1] ~= nil then
    -- get packet_info
    bytes_needed  = packet_info[pinfo.number-1].desegment_len
    offset        = packet_info[pinfo.number-1].desegment_offset
    msg_index     = packet_info[pinfo.number-1].next_seq_number

    dprint7("pinfo(n-1) offset:", pinfo.desegment_offset, "bytes needed:", bytes_needed, "last seq", msg_index)
  end

  local result = 0
  -- We're going to call our "dissect()" function, which is defined
  -- above in this script file.
  if bytes_needed > 0 then
    dprint7("using desegment_offset/desegment_len method")

    if fragments[pinfo.number-1] ~= nil then
      dprint7("Read fragment(n-1):", pinfo.number-1)
      local full_frame = fragments[pinfo.number-1]
      local remaining_bytes = full_frame(offset, full_frame:len()-offset)
      remaining_bytes:append(tvb:bytes())
      local new_tvb = remaining_bytes:tvb("Reassembled")
      result = dissect(new_tvb, pinfo, root)
    end
  else
    result = dissect(tvb, pinfo, root)
  end

  -- update stored packet info
  if result > 0 then
    -- update next_seq_number
    dprint7("Update Sequence number:", msg_index)
    packet_info[pinfo.number].next_seq_number = msg_index

    -- desegment_len/desegment_offset may be updated
    if pinfo.desegment_len ~= 0 or pinfo.desegment_offset ~= 0 then
      dprint7("Update desegment_offset/desegment_len")
      packet_info[pinfo.number].desegment_offset  = pinfo.desegment_offset
      packet_info[pinfo.number].desegment_len     = pinfo.desegment_len
    end
  end

  return result
end


--------------------------------------------------------------------------------
-- We want to have our protocol dissection invoked for a specific USER,
-- so get the wtap_encap dissector table and add our protocol to it.
dprint7("Initialization of PPI protocol")

-- load the wtap_encap table
local wtap_encap_table = DissectorTable.get("wtap_encap")

-- register our protocol to USER0
dprint7("Register PPI protocol for USER0")
wtap_encap_table:add(wtap.USER1, LOGOPPI)


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

LOGOPPI.prefs.subdissect  = Pref.bool("Enable sub-dissectors", default_settings.add_tree_info, 
                                     "Whether the PG packet's content" ..
                                     " should be dissected or not")

LOGOPPI.prefs.debug       = Pref.enum("Debug", default_settings.debug_level,
                                     "The debug printing level", debug_pref_enum)

--------------------------------------------------------------------------------
-- the function for handling preferences being changed
function LOGOPPI.prefs_changed()
  dprint7("prefs_changed called")

  example_add_tree_info = LOGOPPI.prefs.subdissect

  default_settings.debug_level = LOGOPPI.prefs.debug
  reset_debug_level()
  
  -- have to reload the capture file for this type of change
  reload()
end

dprint7("PCapfile Prefs registered")
