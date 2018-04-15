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
--  0.2.2 12-14.04.2018   optimisations of reasembling
--  0.3   14.04.2018      dissection of message type 0x06
--  0.3.1 15.04.2018      optimisations of dissection
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

local message_id  = default_settings.value
local address_len = default_settings.address_len

local FLAG_VALUE  = {
  [0] = "Not Set",
  [1] = "Set"
}
local FL_FRAGMENT = 0x01

-- Message fields
ppi_fields.sequence_number  = ProtoField.uint32("LOGOPPI.sequence_number",  "Sequence number")
ppi_fields.flags            = ProtoField.uint8 ("LOGOPPI.Flags",            "Flags",          base.HEX)
ppi_fields.fragmented       = ProtoField.uint8 ("LOGOPPI.fragmented",       "More Fragment",  base.DEC, FLAG_VALUE, FL_FRAGMENT)

----------------------------------------
-- a table of our PG-Protocol fields
local pg_fields = LOGOPG.fields

local ident_number = default_settings.ident_number

local ACK_RESPONSES = {
  [0x01] = "Operation Mode RUN",
  [0x03] = "Read Data Response",
  [0x20] = "Operation Mode EDIT",
  [0x42] = "Operation Mode STOP",
  [0x55] = "Control Command Response",
}

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
}

local IDENTIFIERS = {
  [0x40] = "0BA4",
  [0x42] = "0BA5",
  [0x43] = "0BA6",
  [0x44] = "0BA6",
}

-- ADU fields
pg_fields.transaction_id  = ProtoField.uint16("LOGOPG.transaction_id",  "Transaction identifier", base.DEC)
pg_fields.unit_id         = ProtoField.uint8 ("LOGOPG.unit_id",         "Unit identifier",        base.HEX, IDENTIFIERS)
pg_fields.pdu_length      = ProtoField.uint16("LOGOPG.pdu_length",      "PDU Length",             base.DEC)

-- PDU fields
pg_fields.message_type    = ProtoField.uint8 ("LOGOPG.message_type",    "Message Type",   base.HEX, MESSAGE_CODES)
pg_fields.address         = ProtoField.bytes ("LOGOPG.address",         "Address")
pg_fields.response_code   = ProtoField.uint8 ("LOGOPG.response_code",   "Response Code",  base.HEX, ACK_RESPONSES)
pg_fields.exception_code  = ProtoField.uint8 ("LOGOPG.exception_code",  "Exception Code", base.DEC, EXCEPTION_CODES)
pg_fields.function_code   = ProtoField.uint16("LOGOPG.function_code",   "Function Code",  base.HEX, FUNCTION_CODES)
pg_fields.byte_count      = ProtoField.uint16("LOGOPG.byte_count",      "Byte Count",     base.DEC)
pg_fields.checksum        = ProtoField.uint8 ("LOGOPG.checksum",        "Checksum XOR",   base.HEX)
pg_fields.trailer         = ProtoField.uint8 ("LOGOPG.trailer",         "Trailer",        base.HEX, {[0xAA] = "End Delimiter"})

--------------------------------------------------------------------------------
-- We need initialization routine, to reset the var(s) whenever a capture
-- is restarted or a capture file loaded.
-- The vars would just be local to our whole script. That's why we need to
-- set or reset it, because wireshark doesn't provide anything to do that for
-- us automatically
--------------------------------------------------------------------------------
function LOGOPPI.init()
  dprint7("PPI (re-)initialise")

  message_id = default_settings.value
  address_len = default_settings.address_len
  ident_number = default_settings.ident_number
  message_counter = {}
  fragments = {}
end

-- this holds the plain "data" Dissector, in case we can't dissect it as LOGOPG
local data = Dissector.get("data")

local lookup_function_code = {
  [0x1111] = {
    -- Fetch Data Response
	pdu_length = function(tvb)
      if tvb:len() < 6 then return -1 end
      -- Confirmation Code + Control Code + Function Code + Byte Count + Data + End Delimiter
      return 1 + 1 + 2 + 2 + tvb(4,2):le_uint() + 1
    end
  },
  [0x1212] = {
    -- Stop Operating
	pdu_length = function(...)
      -- Control Code + Function Code + End Delimiter
      return 4
    end
  },
  [0x1313] = {
    -- Start Fetch Data
	pdu_length = function(tvb)
      if tvb:len() < 4 then return -1 end
      -- Control Code + Function Code + Byte Count + Data + End Delimiter
      return 1 + 2 + 1 + tvb(3,1):uint() + 1
    end
  },
  [0x1414] = {
    -- Stop Fetch Data
	pdu_length = function(...)
      -- Control Code + Function Code + End Delimiter
      return 4
    end
  },
  [0x1717] = {
    -- Operation Mode
	pdu_length = function(...)
      -- Control Code + Function Code + End Delimiter
      return 4
    end
  },
  [0x1818] = {
    -- Start Operating
	pdu_length = function(...)
      -- Control Code + Function Code + End Delimiter
      return 4
    end
  },
}

local lookup_ack_response = {
  [0x01] = {
    -- Mode RUN
	pdu_length = function(...)
      return 2
    end
  },
  [0x03] = {
    -- Read Data Response
	pdu_length = function(tvb)
      if tvb:len() < 3 then return -1 end
      -- check if it is a Connection Response of a 0ba6
      if tvb(2,1):uint() == 0x21 then
        -- at 0ba6 all addresses are 32bit
        address_len = 4
        -- Confirmation Code + Data Response + Connection Request + Ident Number
        return 4
      else
        -- Confirmation Code + Data Response + Address + Data Byte
        return 1 + 1 + address_len + 1
      end
    end
  },
  [0x20] = {
    -- Mode EDIT
	pdu_length = function(...)
      return 2
    end
  },
  [0x42] = {
    -- Mode STOP
	pdu_length = function(...)
      return 2
    end
  },
  [0x55] = {
    -- Control Command Response
	pdu_length = function(tvb)
      if tvb:len() < 4 then return -1 end
      -- Control Code + Function Code + ...
      local function_code = tvb(2,2):uint()
      if function_code ~= 0x1111 then return 1 end
      return lookup_function_code[function_code] and lookup_function_code[function_code].pdu_length(tvb) or 0
    end
  },
}

local lookup_message_type = {
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
      -- Data Code + Address (16/32bit value Big-Endian) + Data Byte
      local pdu_length = 1 + address_len + 1
      if tvb:len() < pdu_length then return 0 end
      tree:add(pg_fields.message_type, tvb(0,1))
      tree:add(pg_fields.address, tvb(1,address_len))
      data:call(tvb(1+address_len,1):tvb(), pinfo, tree)
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
      -- Data Code + Address (16/32bit value Big-Endian)
      local pdu_length = 1 + address_len
      if tvb:len() < pdu_length then return 0 end
      tree:add(pg_fields.message_type, tvb(0,1))
      tree:add(pg_fields.address, tvb(1,address_len))
      return pdu_length
    end
  },
  [0x04] = {
    -- Write Block
	pdu_length = function(tvb)
      -- Data Code + Address (16/32bit) + Byte Count + ...
      local pdu_header_len = 1 + address_len + 2
      if tvb:len() < pdu_header_len then return -1 end
      local number_of_bytes = tvb(1+address_len,2):le_uint()
      -- Data Code + Address (16/32bit) + Byte Count (Little Endian) + Data + Checksum
      return 1 + address_len + 2 + number_of_bytes + 1
    end,
	dissect = function(tvb, pinfo, tree)
      -- Data Code + Address (16/32bit value Big-Endian) + Byte Count (Little Endian) + ...
      local pdu_header_len = 1 + address_len + 2
      if tvb:len() < pdu_header_len then return 0 end
      tree:add(pg_fields.message_type, tvb(0,1))
      tree:add(pg_fields.address, tvb(1,address_len))
      local number_of_bytes = tvb(1+address_len,2):le_uint()
      tree:add_le(pg_fields.byte_count, tvb(1+address_len,2))
      local max_length = tvb:len() - pdu_header_len
      if number_of_bytes < max_length then
        -- ... Data + Checksum
        data:call(tvb(pdu_header_len, number_of_bytes):tvb(), pinfo, tree)
        tree:add(pg_fields.checksum, tvb(pdu_header_len+number_of_bytes,1))
        return pdu_header_len + number_of_bytes + 1
      else
        -- ... Data(0..max_length)
        data:call(tvb(pdu_header_len, max_length):tvb(), pinfo, tree)
        return pdu_header_len + max_length
      end
    end
  },
  [0x05] = {
    -- Read Block
	pdu_length = function(...)
      -- Data Code + Address (16/32bit) + Byte Count
      return 1 + address_len + 2
    end,
	dissect = function(tvb, pinfo, tree)
      -- Data Code + Address (16/32bit value Big-Endian) + Byte Count (Little Endian)
      local pdu_length = 1 + address_len + 2
      if tvb:len() < pdu_length then return 0 end
      tree:add(pg_fields.message_type, tvb(0,1))
      tree:add(pg_fields.address, tvb(1,address_len))
      tree:add_le(pg_fields.byte_count, tvb(1+address_len,2))
      return pdu_length
    end
  },
  [0x06] = {
    -- Acknowledge Response
	pdu_length = function(tvb)
      -- Confirmation Code + Response Code + ...
      if tvb:len() < 2 then return -1 end
      local response_code = tvb(1,1):uint()
      return lookup_ack_response[response_code] and lookup_ack_response[response_code].pdu_length(tvb) or 1
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
      -- Tool Code
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
      -- Tool Code
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
      -- Tool Code
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
      return lookup_function_code[function_code] and lookup_function_code[function_code].pdu_length(tvb) or 0
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

  dprint6("PG Protocol dissector called, message id:", message_id)

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
  -- set the protocol column to show our protocol name
  pinfo.cols.protocol = LOGOPG.name

  -- We start by adding our protocol to the dissection display tree.
  local subtree = tree:add(LOGOPG)

  -- Next, the ADU header will be displayed
  if length >= 4 and address_len == 4 and tvb(0,3):uint() == 0x060321 then
    -- if we are here, then it is a Connection Response of a 0ba6
    ident_number = tvb(3,1):uint()
    subtree:add(pg_fields.unit_id, tvb(3,1))
  elseif length >= 5 and tvb(0,4):uint() == 0x06031F02 then
    -- if we are here, then it is a Connection Response of a 0ba4 or 0ba5
    ident_number = tvb(4,1):uint()
    subtree:add(pg_fields.unit_id, tvb(4,1))
  elseif ident_number > 0 then
    -- display the current ident number
    subtree:add(pg_fields.unit_id, ident_number):set_generated()
  end
  subtree:add(pg_fields.pdu_length, pdu_length):set_generated()

  -- Now, let's dissecting the PDU data
  local offset = 0
  local pdutree = subtree:add(tvb(), "Protocol Data Unit (PDU)")
  local message_type = tvb(0,1):uint()

  if message_type == 0x06 then
    -- Acknowledge Response
    pdutree:add(pg_fields.message_type, tvb(0,1))
    offset = 1
    if length >= 4 and address_len == 4 and tvb(1,2):uint() == 0x0321 then
      -- Connection Response of a 0ba6
      pdutree:add(pg_fields.response_code, tvb(1,1))
      pdutree:add(tvb(2,1), "Connection Response")
      offset = offset + 2
    elseif pdu_length > 1 then
      if length >= 2 then
        local response_code = tvb(offset,1):uint()
        pdutree:add(pg_fields.response_code, tvb(offset,1))
        offset = offset + 1
        if response_code == 0x03 and length >= offset+address_len then
          -- Address (16/32bit value Big-Endian)
          pdutree:add(pg_fields.address, tvb(offset,address_len))
          offset = offset + address_len
        end
      end
    end
  elseif message_type == 0x55 then
    pdutree:add(pg_fields.message_type, tvb(0,1))
    offset = 1
    if length >= 3 then
      function_code = tvb(1,2):uint()
      pdutree:add(pg_fields.function_code, tvb(1,2))
      offset = 3
      if function_code == 0x1313 and length >= 4 then
        -- Number of Bytes (8bit value)
        byte_count = tvb(3,1):uint()
        pdutree:add(pg_fields.byte_count, tvb(3,1))
        offset = 4
      end
    end
    if pdu_length-1 < length then
      data:call(tvb(offset, pdu_length - offset-1):tvb(), pinfo, pdutree)
      pdutree:add(pg_fields.trailer, tvb(pdu_length-1, 1))
      offset = pdu_length
    end
  else
    offset = lookup_message_type[message_type] and lookup_message_type[message_type].dissect(tvb, pinfo, pdutree) or 0
  end

  -- if we got here, then we have only data bytes in the Tvb buffer
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
    subtree:add(ppi_fields.sequence_number, message_id):set_generated()
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
    -- increment message_id
    message_id = message_id + 1
      
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

  -- since the protocol has no index, we need to generated a message id
  if not pinfo.visited and message_counter[pinfo.number] == nil then
    -- if not already available, save the current message index
    dprint7("Store message index:", message_id, "to packet number:", pinfo.number)
    message_counter[pinfo.number] = message_id
  elseif message_counter[pinfo.number] ~= nil then
    -- load the saved message index if available
    message_id = message_counter[pinfo.number]
  end

  local buffer = tvb
  -- check if there are any fragmentations for this message id
  if fragments[message_id] ~= nil then
    -- if data exists, load the saved data and create a composite "ByteArray"
    local more_fragment = fragments[message_id][pinfo.number] ~= nil
    if not more_fragment then
      -- Read all previous fragments from our stored structure
      local reassembled = ByteArray.new()
      for key,data in pairs(fragments[message_id]) do
        dprint7("Read fragment ["..message_id..":"..key.."]")
        reassembled = reassembled .. data
      end
      -- We're going to our "dissect()" function with a composite Tvb buffer
      reassembled = reassembled .. tvb:bytes()
      buffer = reassembled:tvb("Reassembled")
    end
  end

  -- Now, we call our "dissect()" which is defined above in this script file
  -- with the original or composite Tvb buffer
  local result = dissect(buffer, pinfo, root)

  -- Only return values other than 0 are valid values.
  -- If "desegment_len" is greater than 0, it is a fragment
  if result ~= 0 and pinfo.desegment_len > 0 then
    -- Wireshark isn't set up to have dissectors look at any frame other than the current frame;
    -- the correct way to process information in earlier frames is to save it in a data structure for future reference.
    if fragments[message_id] == nil then
      dprint7("Save fragment ["..message_id..":"..pinfo.number.."]")
      fragments[message_id] = {}
    end
    -- determine the actual length and the associated offset of the current packet
    local offset = pinfo.desegment_offset - (buffer:len() - tvb:len())
    local length = tvb:len() - offset
    fragments[message_id][pinfo.number] = tvb(offset, length):bytes()
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
