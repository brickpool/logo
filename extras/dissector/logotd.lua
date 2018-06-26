-------------------------------------------------------------------------------
-- This dissector decodes the Siemens LOGO! TD protocol.
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
--  0.1   03-04.06.2018 inital version
--  0.1.1 04.06.2018    bug fixing
--  0.2   05.06.2018    update INFO colum; impl. first opcode code 0x08
--  0.2.1 06.06.2018    bug fixing
--  0.2.2 07.06.2018    bug fixing byte count
--  0.3   07.06.2018    opcode 0x04, 0x05, 0x09, 0x10
--  0.3.1 11.06.2018    opcode 0x03; bug fixing 0x10
--  0.3.2 12.06.2018    opcode 0x21, 0x41; bug fixing 0x08
--  0.3.3 13-15.06.2018 opcode 0x30, 0x40, 0x42; update 0x03
--  0.3.4 15.06.2018    opcode 0x3d
--  0.3.5 18.06.2018    opcode 0x3c; update 0x09; bug fixing 0x08
--  0.3.6 19.06.2018    update 0x03
--  0.3.7 20-21.06.2018 opcode 0x5b, 0x61
--  0.3.8 22-26.06.2018 update 0x40, opcode 0x01, 0x02, 0x18
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
  max_telegram_len  = 1024,   -- this is the maximum size of a telegram
  conn_value        = 1,      -- start conn_value for telegram counting
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
  [0x16] = "ED",
}

-- this is the size of the FDL header (SD+LE+LEr+SD = 6 bytes)
local PBUS_FDL_HDR_LEN = 1 + 2 + 2 + 1
-- size of the SD2 header (SD2+LE+LEr+SD2+DA+SA+FC = 9 bytes)
local PBUS_SD2_HDR_LEN = PBUS_FDL_HDR_LEN + 1 + 1 + 1
-- size of the SAP fields (DSAP+SSAP = 2 bytes)
local PBUS_DDLM_HDR_LEN = 1 + 1
-- size of the FDL trailer (DCS+ED = 2 bytes)
local PBUS_TRAILER_LEN = 1 + 1
-- size of the ALI header (01+BC+CND = 4 bytes)
local PBUS_ALI_HDR_LEN = 1 + 2 + 1
-- size of the Diag header (operation mode+unkown+checksum = 7 bytes)
local OP_DIAGNOSIS_LEN = 1 + 4 + 2
-- size of the Datetime header (DD+MM+YY+mm+hh-Wd+SW = 7 bytes)
local OP_DATETIME_LEN = 7
-- size of the Param header (block+register+BC = 6 bytes)
local OP_PARAM_HDR_LEN = 2 + 2 + 2
-- size of one Blockname (8 bytes)
local OP_BLK_NAME_LEN = 8
-- size of the Program header (register+BC+blocktype+blockparam = 6 bytes)
local OP_PRGMEM_HDR_LEN = 2 + 2 + 1 + 1
-- size of one Conn row (header+data+trailer = 20 bytes)
local OP_CONN_ROW_LEN = 2 + 16 + 2

-- size of one Message line (24*char = 24 bytes)
local OP_MSG_LINE_LEN = 24
-- size of one Message row (line+rowdata = 32 bytes)
local OP_MSG_ROW_LEN = OP_MSG_LINE_LEN + 8
-- number of Message lines (4 lines)
local OP_MSG_LINES = 4
-- size of Message display (col*row = 128 bytes)
local OP_MSG_DISPLAY_LEN = OP_MSG_LINES * OP_MSG_ROW_LEN

fdl_fields.telegram_number =
  ProtoField.uint32("PROFIBUS.number", "Telegram number")
fdl_fields.flags =
  ProtoField.uint8 ("PROFIBUS.flags", "Flags", base.HEX)
fdl_fields.fragmented =
  ProtoField.uint8 ("PROFIBUS.fragmented", "More Fragment", base.DEC,
                    FLAG_VALUE, FL_FRAGMENT)
fdl_fields.telegram =
  ProtoField.uint8 ("PROFIBUS.type", "Telegram", base.HEX, FDL_CODES)
fdl_fields.le =
  ProtoField.uint16("PROFIBUS.LE", "Length", base.DEC)
fdl_fields.ler =
  ProtoField.uint16("PROFIBUS.LEr", "Length repeated", base.DEC)
fdl_fields.telegram2 =
  ProtoField.uint8 ("PROFIBUS.type_repeated", "Telegram repeated", base.HEX,
                    FDL_CODES)
fdl_fields.da =
  ProtoField.uint8 ("PROFIBUS.DA", "Destination Address", base.HEX,
                    ADDRESS_VALUE)
fdl_fields.sa =
  ProtoField.uint8 ("PROFIBUS.SA", "Source Address", base.HEX, ADDRESS_VALUE)
fdl_fields.fc =
  ProtoField.uint8 ("PROFIBUS.FC", "Frame Control", base.HEX, FC_CODES)
fdl_fields.dsap =
  ProtoField.uint8 ("PROFIBUS.DSAP", "Destination Service Access Points",
                    base.HEX, SAP_VALUE)
fdl_fields.ssap =
  ProtoField.uint8 ("PROFIBUS.SSAP", "Source Service Access Points", base.HEX,
                    SAP_VALUE)
fdl_fields.fcs =
  ProtoField.uint8 ("PROFIBUS.FCS", "Frame Check Sequence", base.HEX)
fdl_fields.ed =
  ProtoField.uint8 ("PROFIBUS.ED", "End Delimiter",  base.HEX, ED_CODES)

----------------------------------------
-- a table of fields for ALI
local ali_fields = LOGOTD.fields

local OP_CODES = {
  [0x01] = "Init Start",
  [0x02] = "Init Complete",
  [0x03] = "Diagnosis",
  [0x04] = "Stop Operating",
  [0x05] = "Start Operating",
  [0x08] = "Online Test",
  [0x09] = "Button Key",
  [0x10] = "Date Time",
--  [0x14] = "",
  [0x18] = "Update Display",
  [0x21] = "Set Parameter",
  [0x30] = "Addressing",
  [0x3c] = "Block Name Reference",
  [0x3d] = "Block Name Memory",
  [0x40] = "Connectors",
  [0x41] = "Program Memory",
  [0x42] = "Program Memory",
--  [0x5a] = "",
  [0x5b] = "Message Text Reference",
  [0x61] = "Message Texts",
--  [0x70] = "",
--  [0x76] = "Parameter Display",
--  [0x77] = "",
--  [0x78] = "",
--  [0x81] = "",
}

local LOGICAL_VALUE = {
  [0] = "Low",
  [1] = "High",
}

local OPERATION_CODES = {
  [0x01] = "RUN Mode",
  [0x02] = "STOP Mode",
  [0x20] = "Parameter Mode",
  [0x42] = "Programming Mode",
}

local PROGRAMMING_CODE = {
  [0x00] = "Idle",
  [0x02] = "PUSH Notification",
  [0x04] = "PUSH Complete",
}

local BUTTON_KEY_CODES = {
  [0x05] = "C1 pressed",
  [0x06] = "Ack Response (S>M) / C2 pressed (M>S)",
  [0x07] = "C3 pressed",
  [0x08] = "C4 pressed",
  [0x11] = "F1 pressed",
  [0x12] = "F2 pressed",
  [0x13] = "F3 pressed",
  [0x14] = "F4 pressed",
  [0x19] = "Cursor released",
  [0x21] = "F1 released",
  [0x22] = "F2 released",
  [0x23] = "F3 released",
  [0x24] = "F4 released",
}

local WEEKDAY = {
  [0x00] = "Sunday",
  [0x01] = "Monday",
  [0x02] = "Tuesday",
  [0x03] = "Wednesday",
  [0x04] = "Thursday",
  [0x05] = "Friday",
  [0x06] = "Saturday",
}

local CONNECTOR_TYPES = {
  [0] = "Digital outputs 1-8",
  [1] = "Digital outputs 9-16",
  [2] = "Digital merkers 1-8",
  [3] = "Digital merkers 9-16",
  [4] = "Digital merkers 17-24",
  [5] = "Analog outputs 1-2, merkers 1-6",
  [6] = "Open connectors 1-8",
  [7] = "Open connectors 9-16",
  [8] = "Digital merkers 25-27",
  [9] = "reserved",
}

local LINK_INPUT_TYPE = {
  [0x00] = "Connector",
  [0x40] = "Connector (negated)",
  [0x80] = "Block",
  [0xC0] = "Block (negated)",
  [0xFC] = "Float",
  [0xFD] = "Level hi",
  [0xFE] = "Level lo",
  [0xFF] = "Not connected",
}

local CONNECTOR_CODES = {
  [0x00] = "I1",   [0x01] = "I2",   [0x02] = "I3",   [0x03] = "I4",
  [0x04] = "I5",   [0x05] = "I6",   [0x06] = "I7",   [0x07] = "I8",
  [0x08] = "I9",   [0x09] = "I10",  [0x0A] = "I11",  [0x0B] = "I12",
  [0x0C] = "I13",  [0x0D] = "I14",  [0x0E] = "I15",  [0x0F] = "I16",
  [0x10] = "I17",  [0x11] = "I18",  [0x12] = "I19",  [0x13] = "I20",
  [0x14] = "I21",  [0x15] = "I22",  [0x16] = "I23",  [0x17] = "I24",
  [0x30] = "Q1",   [0x31] = "Q2",   [0x32] = "Q3",   [0x33] = "Q4",
  [0x34] = "Q5",   [0x35] = "Q6",   [0x36] = "Q7",   [0x37] = "Q8",
  [0x38] = "Q9",   [0x39] = "Q10",  [0x3A] = "Q11",  [0x3B] = "Q12",
  [0x3C] = "Q13",  [0x3D] = "Q14",  [0x3E] = "Q15",  [0x3F] = "Q16",
  [0x50] = "M1",   [0x51] = "M2",   [0x52] = "M3",   [0x53] = "M4",
  [0x54] = "M5",   [0x55] = "M6",   [0x56] = "M7",   [0x57] = "M8",
  [0x58] = "M9",   [0x59] = "M10",  [0x5A] = "M11",  [0x5B] = "M12",
  [0x5C] = "M13",  [0x5D] = "M14",  [0x5E] = "M15",  [0x5F] = "M16",
  [0x60] = "M17",  [0x61] = "M18",  [0x62] = "M19",  [0x63] = "M20",
  [0x64] = "M21",  [0x65] = "M22",  [0x66] = "M23",  [0x67] = "M24",
  [0x80] = "AI1",  [0x81] = "AI2",  [0x82] = "AI3",  [0x83] = "AI4",
  [0x84] = "AI5",  [0x85] = "AI6",  [0x86] = "AI7",  [0x87] = "AI8",
  [0x80] = "AQ1",  [0x81] = "AQ2",  [0x82] = "AM1",  [0x83] = "AM2",
  [0x84] = "AM3",  [0x85] = "AM4",  [0x86] = "AM5",  [0x87] = "AM6",
  [0xA0] = "C1",   [0xA1] = "C2",   [0xA2] = "C3",   [0xA3] = "C4",
  [0xB0] = "S1",   [0xB1] = "S2",   [0xB2] = "S3",   [0xB3] = "S4",
  [0xB4] = "S5",   [0xB5] = "S6",   [0xB6] = "S7",   [0xB7] = "S8",
}

local BLOCK_TYPE_CODES = {
  [0x01] = "AND",
  [0x02] = "OR",
  [0x03] = "NOT",
  [0x04] = "NAND",
  [0x05] = "NOR",
  [0x06] = "XOR",
  [0x07] = "AND (edge-controlled)",
  [0x08] = "NAND (edge-controlled)",
  [0x21] = "On-delay", 
  [0x22] = "Off-delay",
  [0x23] = "Pulse relay",
  [0x24] = "Weekly timer",
  [0x25] = "Latching relay",
  [0x27] = "Retentive on-delay",
  [0x2B] = "Up/down counter",
  [0x2D] = "Asynchronous pulse generator",
  [0x2F] = "On-/Off-delay",
  [0x31] = "Stairway lighting switch",
  [0x34] = "Message texts",
  [0x35] = "Analog threshold trigger",
  [0x39] = "Analog value monitoring",
}

local BLOCK_PARAM_CODES = {
  [0x00] = "not set",
  [0x40] = "nonpermanent, unprotected",
  [0x80] = "permanent, protected",
  [0xC0] = "permanent, unprotected",
}

-- ALI header fields
ali_fields.header     = ProtoField.uint8 ("LOGOTD.Header", "Header", base.HEX)
ali_fields.byte_count = ProtoField.uint16("LOGOTD.BC", "Byte Count", base.DEC)
ali_fields.op_code    = ProtoField.uint8 ("LOGOTD.OP", "Operation Code"
  , base.HEX, OP_CODES)

-- Diagnostic fields (0x03)
ali_fields.operation_mode = ProtoField.uint8 ("LOGOTD.operation_mode"
  , "Operation Mode", base.HEX, OPERATION_CODES)
ali_fields.programming_mode = ProtoField.uint8 ("LOGOTD.programming_mode"
  , "Programming Mode", base.HEX, PROGRAMMING_CODE)
ali_fields.prg_checksum   = ProtoField.uint16("LOGOTD.prg_checksum"
  , "Program checksum", base.HEX)

-- Function Keys fields (0x09)
ali_fields.button_key = ProtoField.uint8("LOGOTD.button_key", "Button Key"
  , base.HEX, BUTTON_KEY_CODES)

-- Date Time fields (0x10)
ali_fields.dt_day     = ProtoField.uint8("LOGOTD.dt_day", "Day", base.DEC)
ali_fields.dt_month   = ProtoField.uint8("LOGOTD.dt_month", "Month", base.DEC)
ali_fields.dt_year    = ProtoField.uint8("LOGOTD.dt_year", "Year", base.DEC)
ali_fields.dt_minute  = ProtoField.uint8("LOGOTD.dt_minute", "Minute", base.DEC)
ali_fields.dt_hour    = ProtoField.uint8("LOGOTD.dt_hour", "Hour", base.DEC)
ali_fields.dt_weekday = ProtoField.uint8("LOGOTD.dt_weekday", "Day of the week"
  , base.DEC, WEEKDAY)
ali_fields.dt_swtime  = ProtoField.bool ("LOGOTD.dt_swtime", "Summertime")

-- Set Parameter (0x21), Addressing (0x30) and Program Memory (0x4x) fields
ali_fields.register   = ProtoField.uint16("LOGOTD.register", "Register"
  , base.HEX)
ali_fields.link_input = ProtoField.uint8 ("LOGOTD.link_input", "Link Input"
  , base.HEX, LINK_INPUT_TYPE)

-- Block fields (0x4x)
ali_fields.connector        = ProtoField.uint8("LOGOTD.connector"
  , "Connector", base.HEX, CONNECTOR_CODES)
ali_fields.block_type       = ProtoField.uint8("LOGOTD.block_type"
  , "Block Type", base.HEX, BLOCK_TYPE_CODES)
ali_fields.block_param      = ProtoField.uint8("LOGOTD.block_param"
  , "Block Parameter", base.HEX, BLOCK_PARAM_CODES)
ali_fields.blk_retentivity  = ProtoField.bool ("LOGOTD.blk_retentivity"
  , "Retentivity", 8, nil, 0x80)
ali_fields.blk_protection   = ProtoField.bool ("LOGOTD.blk_protection"
  , "No Parameter Protection", 8, nil, 0x40)

-- Message Text Reference fields (0x5b)
ali_fields.msg_index  = ProtoField.uint8("LOGOTD.msg_index"
  , "Message Text", base.DEC)
ali_fields.char_set   = ProtoField.uint8("LOGOTD.char_set"
  , "Character Set", base.DEC)

-- ALI data fields
ali_fields.data = ProtoField.bytes("LOGOTD.data", "Data")
ali_fields.bit0 = ProtoField.uint8("LOGOTD.bit0", "b0", base.DEC, LOGICAL_VALUE
  , 0x01)
ali_fields.bit1 = ProtoField.uint8("LOGOTD.bit1", "b1", base.DEC, LOGICAL_VALUE
  , 0x02)
ali_fields.bit2 = ProtoField.uint8("LOGOTD.bit2", "b2", base.DEC, LOGICAL_VALUE
  , 0x04)
ali_fields.bit3 = ProtoField.uint8("LOGOTD.bit3", "b3", base.DEC, LOGICAL_VALUE
  , 0x08)
ali_fields.bit4 = ProtoField.uint8("LOGOTD.bit4", "b4", base.DEC, LOGICAL_VALUE
  , 0x10)
ali_fields.bit5 = ProtoField.uint8("LOGOTD.bit5", "b5", base.DEC, LOGICAL_VALUE
  , 0x20)
ali_fields.bit6 = ProtoField.uint8("LOGOTD.bit6", "b6", base.DEC, LOGICAL_VALUE
  , 0x40)
ali_fields.bit7 = ProtoField.uint8("LOGOTD.bit7", "b7", base.DEC, LOGICAL_VALUE
  , 0x80)

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
-- The Serial Capture Service splits large packets over the serial connector 
-- into several packets. In this case the dissection can’t be carried out
-- correctly until we have all the data. Sometime the first packet doesn’t have
-- enough data, and the subsequent packets don’t have the expect format. To
-- dissect these packets we need to wait until all the parts have arrived and
-- then start the dissection. The following section described all possible
-- cases:
-- 1. A single Telegram may span multiple packets.
-- 2. A single header may also span multiple packets
-- 3. A packet may also contain multiple Telegrams, both complete and fragmented
-- 4. The length of a Telegram is determined by a header field,
--    but an unknown number of bytes must be read before getting to that
--    conn_value, as the header is preceded by a variable length delimiter
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
  -- Let’s step through adding a basic packet header.
  -- It consists of the following basic items
  local new_class = {  -- the new instance
    -- A telegram counter (valid conn_values are > 0)
    telegram_counter = default_settings.conn_value,

    -- The following tables needs to be cleared by the protocol "init()"
    -- function whenever a capture is reloaded

    -- The following local table holds the packet info; this is needed to create
    -- and keep trackof pseudo headers for telegrams that went over the serial
    -- connector, for example for sequence number info. The key index will be a
    -- number - the pinfo.number.
    packet_infos = {},

    -- The following local table holds the sequences of a fragmented PDU
    -- telegram. The key index for this is the sequence numper+pinfo.number
    -- concatenated. The conn_value is a table, ByteArray style, holding the
    -- fragment of the PROFIBUS telegram.
    fragments = {},

  }
  -- all instances share the same metatable
  setmetatable( new_class, PacketHelper_mt )
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
  dprint7("PacketHelper:set_number() function called, parameter:",
          type(param1), type(param2))

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
    -- set current sequence number to the previous saved conn_value
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
    telegram_id = self.packet_infos[pinfo.number] and
      self.packet_infos[pinfo.number].telegram_number or 0
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
  dprint7("PacketHelper:fragmented() function called, returned:",
          is_fragmented and "true" or "false")
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
  -- Check if we have more fragments of this telegram id. As a reminder, we
  -- don't store the last fragment in our structure
  local last_fragment = self.fragments[telegram_id][pinfo.number] == nil
  dprint7("PacketHelper:more_fragment() function called, returned:",
          last_fragment and "false" or "true")
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
  -- Check if there are any fragmentations for this sequence number and if the
  -- buffer is the last fragment
  if  self.fragments[telegram_id] ~= nil
  and self.fragments[telegram_id][pinfo.number] == nil
  then
    -- If there are no more fragments, load the saved data and create a
    -- composite "ByteArray"
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
  dprint7("PacketHelper:set_fragment() function called, parameter:",
          type(tvb), type(pinfo))

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
    dprint6("Creating fragment table for sequence number:",
            self.telegram_counter)
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
    self.fragments[self.telegram_counter][pinfo.number] =
      tvb(offset, length):bytes()
  end
  return length
end

-- this holds our "helper"
local packet_helper = nil

-- this holds the plain "data" Dissector, in case we can't dissect it as LOGOTD
local data = Dissector.get("data")

lookup_op_code = {
  [0x01] = {
    dissect = function(tvb, pinfo, tree)
      -- Header fields
      if tvb:len() < PBUS_ALI_HDR_LEN then return 0 end
      -- 01 + Byte Count (16bit Big Endian)
      local number_of_bytes = tvb(1,2):uint()-1
      tree:add(ali_fields.header, tvb(0,1))
      tree:add(ali_fields.byte_count, tvb(1,2))
      -- Operation Code + ...
      local op_code = tvb(3,1):uint()
      tree:add(ali_fields.op_code, tvb(3,1))
      -- If this telegram has no data, then we are done here
      if number_of_bytes == 0 then return PBUS_ALI_HDR_LEN end

      -- Payload fields
      local pdu_length = PBUS_ALI_HDR_LEN + number_of_bytes
      if tvb:len() < pdu_length then return 0 end
      local data = tvb(PBUS_ALI_HDR_LEN, 1)
      if data:uint() == 0x06 then
        tree:add(data, "Acknowledge Response (0x06)")
      else
        tree:add(ali_fields.data, tvb(PBUS_ALI_HDR_LEN, number_of_bytes))
      end
      return pdu_length
    end
  },
  [0x02] = {
    dissect = function(tvb, pinfo, tree)
      return lookup_op_code[0x01].dissect(tvb, pinfo, tree)
    end
  },
  [0x03] = {
    dissect = function(tvb, pinfo, tree)
      -- Header fields
      if tvb:len() < PBUS_ALI_HDR_LEN then return 0 end
      -- 01 + Byte Count (16bit Big Endian)
      local number_of_bytes = tvb(1,2):uint()-1
      tree:add(ali_fields.header, tvb(0,1))
      tree:add(ali_fields.byte_count, tvb(1,2))
      -- Operation Code + ...
      local op_code = tvb(3,1):uint()
      tree:add(ali_fields.op_code, tvb(3,1))
      -- If this telegram has no data, then we are done here
      if number_of_bytes == 0 then return PBUS_ALI_HDR_LEN end

      -- Payload fields
      local pdu_length = PBUS_ALI_HDR_LEN + number_of_bytes
      if tvb:len() < pdu_length then return 0 end
      if number_of_bytes < OP_DIAGNOSIS_LEN then return 0 end
      local offset = PBUS_ALI_HDR_LEN
      tree:add(ali_fields.operation_mode, tvb(offset, 1))
      offset = offset + 1
      tree:add(ali_fields.data, tvb(offset, 1))
      offset = offset + 1
      tree:add(ali_fields.programming_mode, tvb(offset, 1))
      offset = offset + 1
      tree:add(ali_fields.data, tvb(offset, 2))
      offset = offset + 2
      tree:add(ali_fields.prg_checksum, tvb(offset, 2))
      offset = offset + 2
      return pdu_length
    end
  },
  [0x04] = {
    dissect = function(tvb, pinfo, tree)
      -- Header fields
      if tvb:len() < PBUS_ALI_HDR_LEN then return 0 end
      -- 01 + Byte Count (16bit Big Endian)
      local number_of_bytes = tvb(1,2):uint()-1
      tree:add(ali_fields.header, tvb(0,1))
      tree:add(ali_fields.byte_count, tvb(1,2))
      -- Operation Code + ...
      local op_code = tvb(3,1):uint()
      tree:add(ali_fields.op_code, tvb(3,1))
      -- If this telegram has no data, then we are done here
      if number_of_bytes == 0 then return PBUS_ALI_HDR_LEN end

      -- Payload fields
      local pdu_length = PBUS_ALI_HDR_LEN + number_of_bytes
      if tvb:len() < pdu_length then return 0 end
      local data = tvb(PBUS_ALI_HDR_LEN, 1)
      if data:uint() == 0x06 then
        tree:add(data, "Acknowledge Response (0x06)")
      else
        tree:add(ali_fields.data, data)
      end
      return pdu_length
    end
  },
  [0x05] = {
    dissect = function(tvb, pinfo, tree)
      return lookup_op_code[0x04].dissect(tvb, pinfo, tree)
    end
  },
  [0x08] = {
    dissect = function(tvb, pinfo, tree)
      -- Header fields
      if tvb:len() < PBUS_ALI_HDR_LEN then return 0 end
      -- 01 + Byte Count (16bit Big Endian)
      local number_of_bytes = tvb(1,2):uint()-1
      tree:add(ali_fields.header, tvb(0,1))
      tree:add(ali_fields.byte_count, tvb(1,2))
      -- Operation Code + ...
      local op_code = tvb(3,1):uint()
      tree:add(ali_fields.op_code, tvb(3,1))
      -- If this telegram has no data, then we are done here
      if number_of_bytes == 0 then return PBUS_ALI_HDR_LEN end

      -- Payload fields
      local pdu_length = PBUS_ALI_HDR_LEN + number_of_bytes
      if tvb:len() < pdu_length then return 0 end
      -- ... Data + ...
      if not default_settings.subdissect then
        tree:add(pg_fields.data, tvb(PBUS_ALI_HDR_LEN
                                     , pdu_length - PBUS_ALI_HDR_LEN))
      else
        local offset = PBUS_ALI_HDR_LEN
        local datatree = tree:add(tvb(PBUS_ALI_HDR_LEN
                                      , pdu_length - PBUS_ALI_HDR_LEN)
                                  , "Data bytes")

        -- digital inputs
        local number_of_bits = 24
        local bytes_to_consume = 3
        local bitcount = NumberOfSetBits(tvb(offset
                                             , bytes_to_consume):bytes(), nil)
        local subtree = datatree:add(tvb(offset, bytes_to_consume)
                      , string.format("Digital inputs [Bitcount %d]", bitcount))
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

        -- digital outputs
        number_of_bits = 16
        bytes_to_consume = 2
        bitcount = NumberOfSetBits(tvb(offset, bytes_to_consume):bytes(), nil)
        subtree = datatree:add(tvb(offset, bytes_to_consume)
                               , string.format("Digital outputs [Bitcount %d]"
                                               , bitcount))
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
        
        -- function keys
        bitcount = NumberOfSetBits(tvb(offset,1):bytes(), 4)
        subtree = datatree:add(tvb(offset,1),
                  string.format("Function keys [Bitcount %d]", bitcount))
        subtree:add(tvb(offset,1), "F04-F01")
        subtree:add(ali_fields.bit0, tvb(offset,1))
        subtree:add(ali_fields.bit1, tvb(offset,1))
        subtree:add(ali_fields.bit2, tvb(offset,1))
        subtree:add(ali_fields.bit3, tvb(offset,1))
        offset = offset + 1

        -- digital merkers 1-24
        number_of_bits = 24
        bytes_to_consume = 3
        bitcount = NumberOfSetBits(tvb(offset, bytes_to_consume):bytes(), nil)
        subtree = datatree:add(tvb(offset, bytes_to_consume)
                               , string.format("Digital merkers [Bitcount %d]"
                                               , bitcount))
        bit = 1
        while bytes_to_consume > 0 do
          subtree:add(tvb(offset,1), string.format("M%02u-M%02u", bit+7, bit))
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
        
        -- cursor keys
    		bitcount = NumberOfSetBits(tvb(offset,1):bytes(), 4)
        subtree = datatree:add(tvb(offset,1)
                               , string.format("Cursor keys [Bitcount %d]"
                                               , bitcount))
        subtree:add(tvb(offset,1), "C04-C01")
        subtree:add(ali_fields.bit0, tvb(offset,1))
        subtree:add(ali_fields.bit1, tvb(offset,1))
        subtree:add(ali_fields.bit2, tvb(offset,1))
        subtree:add(ali_fields.bit3, tvb(offset,1))
        offset = offset + 1
  
        -- shift register
        bitcount = NumberOfSetBits(tvb(offset,1):bytes(), nil)
        subtree = datatree:add(tvb(offset,1)
                               , string.format("Shift register [Bitcount %d]"
                                               , bitcount))
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
        
        -- digital merkers 25-27
    		bitcount = NumberOfSetBits(tvb(offset,1):bytes(), 3)
        subtree = datatree:add(tvb(offset,1)
                               , string.format("Digital merkers [Bitcount %d]"
                                               , bitcount))
        subtree:add(tvb(offset,1), "M25-M27")
        subtree:add(ali_fields.bit0, tvb(offset,1))
        subtree:add(ali_fields.bit1, tvb(offset,1))
        subtree:add(ali_fields.bit2, tvb(offset,1))
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
        subtree = datatree:add(tvb(offset,bytes_to_consume)
                               , string.format("Analog inputs [%s]"
                                               , FLAG_VALUE[flag]))
        local analog = 1
        while bytes_to_consume > 0 do
          subtree:add(tvb(offset,2)
                      , string.format("AI%u: %d", analog, tvb(offset,2):int()))
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
        subtree = datatree:add(tvb(offset,4)
                               , string.format("Analog outputs [%s]"
                                               , FLAG_VALUE[flag]))
        subtree:add(tvb(offset,2)
                    , string.format("AQ1: %d", tvb(offset,2):int()))
        offset = offset + 2
        subtree:add(tvb(offset,2)
                    , string.format("AQ2: %d", tvb(offset,2):int()))
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
        subtree = datatree:add(tvb(offset,bytes_to_consume)
                               , string.format("Analog merkers [%s]"
                                               , FLAG_VALUE[flag]))
        local analog = 1
        while bytes_to_consume > 0 do
          subtree:add(tvb(offset,2)
                      , string.format("AM%u: %d", analog, tvb(offset,2):int()))
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
      -- Header fields
      if tvb:len() < PBUS_ALI_HDR_LEN then return 0 end
      -- 01 + Byte Count (16bit Big Endian)
      local number_of_bytes = tvb(1,2):uint()-1
      tree:add(ali_fields.header, tvb(0,1))
      tree:add(ali_fields.byte_count, tvb(1,2))
      -- Operation Code + ...
      local op_code = tvb(3,1):uint()
      tree:add(ali_fields.op_code, tvb(3,1))
      -- If this telegram has no data, then we are done here
      if number_of_bytes == 0 then return PBUS_ALI_HDR_LEN end

      -- Payload fields
      local pdu_length = PBUS_ALI_HDR_LEN + number_of_bytes
      if tvb:len() < pdu_length then return 0 end
      -- ... Data + ...
      tree:add(ali_fields.button_key, tvb(PBUS_ALI_HDR_LEN, 1))
      return pdu_length
    end
  },
  [0x10] = {
    dissect = function(tvb, pinfo, tree)
      -- Header fields
      if tvb:len() < PBUS_ALI_HDR_LEN then return 0 end
      -- 01 + Byte Count (16bit Big Endian)
      local number_of_bytes = tvb(1,2):uint()-1
      tree:add(ali_fields.header, tvb(0,1))
      tree:add(ali_fields.byte_count, tvb(1,2))
      -- Operation Code + ...
      local op_code = tvb(3,1):uint()
      tree:add(ali_fields.op_code, tvb(3,1))
      -- If this telegram has no data, then we are done here
      if number_of_bytes == 0 then return PBUS_ALI_HDR_LEN end

      -- Payload fields
      local pdu_length = PBUS_ALI_HDR_LEN + number_of_bytes
      if tvb:len() < pdu_length then return 0 end
      -- ... Data + ...
      local data = tvb(PBUS_ALI_HDR_LEN, 1)
      if data:uint() == 0x06 then
        tree:add(data, "Acknowledge Response (0x06)")
      else
        if number_of_bytes < OP_DATETIME_LEN then return 0 end
        data = tvb(PBUS_ALI_HDR_LEN, OP_DATETIME_LEN)
        local day     = data(0,1)
        local month   = data(1,1)
        local year    = data(2,1)
        local minute  = data(3,1)
        local hour    = data(4,1)
        local weekday = data(5,1)
        local swtime  = data(6,1)
        local datatree = tree:add(data,
          string.format("Date Time: 20%02d-%02d-%02d %02d:%02d"
                        , year:uint(), month:uint(), day:uint()
                        , hour:uint(), minute:uint() ))
        datatree:add(ali_fields.dt_day, day)
        datatree:add(ali_fields.dt_month, month)
        datatree:add(ali_fields.dt_year, year)
        datatree:add(ali_fields.dt_minute, minute)
        datatree:add(ali_fields.dt_hour, hour)
        datatree:add(ali_fields.dt_weekday, weekday)
        datatree:add(ali_fields.dt_swtime, swtime)
      end
      return pdu_length
    end
  },
  [0x18] = {
    dissect = function(tvb, pinfo, tree)
      -- Header fields
      if tvb:len() < PBUS_ALI_HDR_LEN then return 0 end
      -- 01 + Byte Count (16bit Big Endian)
      local number_of_bytes = tvb(1,2):uint()-1
      tree:add(ali_fields.header, tvb(0,1))
      tree:add(ali_fields.byte_count, tvb(1,2))
      -- Operation Code + ...
      local op_code = tvb(3,1):uint()
      tree:add(ali_fields.op_code, tvb(3,1))
      -- If this telegram has no data, then we are done here
      if number_of_bytes == 0 then return PBUS_ALI_HDR_LEN end

      -- Payload fields
      local pdu_length = PBUS_ALI_HDR_LEN + number_of_bytes
      if tvb:len() < pdu_length then return 0 end
      -- ... Data + ...
      for offset = PBUS_ALI_HDR_LEN,pdu_length-1,4 do
        tree:add(ali_fields.data, tvb(offset, 4))
      end
      return pdu_length
    end
  },
  [0x21] = {
    dissect = function(tvb, pinfo, tree)
      -- Header fields
      if tvb:len() < PBUS_ALI_HDR_LEN then return 0 end
      -- 01 + Byte Count (16bit Big Endian)
      local number_of_bytes = tvb(1,2):uint()-1
      tree:add(ali_fields.header, tvb(0,1))
      tree:add(ali_fields.byte_count, tvb(1,2))
      -- Operation Code + ...
      local op_code = tvb(3,1):uint()
      tree:add(ali_fields.op_code, tvb(3,1))
      -- If this telegram has no data, then we are done here
      if number_of_bytes == 0 then return PBUS_ALI_HDR_LEN end

      -- Payload fields
      local pdu_length = PBUS_ALI_HDR_LEN + number_of_bytes
      if tvb:len() < pdu_length then return 0 end
      -- ... Data + ...
      local data = tvb(PBUS_ALI_HDR_LEN, 1)
      if data:uint() == 0x06 then
        tree:add(data, "Acknowledge Response (0x06)")
      else
        local datatree = tree:add(tvb(PBUS_ALI_HDR_LEN, number_of_bytes)
                                 , string.format("Parameter (%d bytes)"
                                                 , number_of_bytes))
        if default_settings.subdissect then
          -- display opcode header
          if number_of_bytes < OP_PARAM_HDR_LEN then return 0 end
          local header      = tvb(PBUS_ALI_HDR_LEN, OP_PARAM_HDR_LEN)
          local block       = header(0,2)
          local register    = header(2,2)
          local byte_count  = header(4,2)
          datatree:add(block, string.format("Block B%03d", block:uint()-9))
          datatree:add(ali_fields.register, register)
          datatree:add(ali_fields.byte_count, byte_count)
          -- display opcode data
          local length = byte_count:uint()-2
          if number_of_bytes < OP_PARAM_HDR_LEN + length then return 0 end
          local data = tvb(PBUS_ALI_HDR_LEN + OP_PARAM_HDR_LEN, length)
          datatree:add(ali_fields.data, data)
        end
      end
      return pdu_length
    end
  },
  [0x30] = {
    dissect = function(tvb, pinfo, tree)
      -- Header fields
      if tvb:len() < PBUS_ALI_HDR_LEN then return 0 end
      -- 01 + Byte Count (16bit Big Endian)
      local number_of_bytes = tvb(1,2):uint()-1
      tree:add(ali_fields.header, tvb(0,1))
      tree:add(ali_fields.byte_count, tvb(1,2))
      -- Operation Code + ...
      local op_code = tvb(3,1):uint()
      tree:add(ali_fields.op_code, tvb(3,1))
      -- If this telegram has no data, then we are done here
      if number_of_bytes == 0 then return PBUS_ALI_HDR_LEN end

      -- Payload fields
      local pdu_length = PBUS_ALI_HDR_LEN + number_of_bytes
      if tvb:len() < pdu_length then return 0 end
      -- ... Data + ...
      local datatree = tree:add(tvb(PBUS_ALI_HDR_LEN, number_of_bytes)
                               , string.format("Addressing (%d bytes)"
                                               , number_of_bytes))
      -- display the details if desired
      if default_settings.subdissect then
        local offset = PBUS_ALI_HDR_LEN
        local index = 0
        while offset + 2 <= pdu_length do
          -- display opcode data
          local register  = tvb(offset, 2)
          local reg_value = register:le_uint()
          if reg_value ~= 0xFFFF then
            local subtree = datatree:add_le(ali_fields.register, register)
            if CONNECTOR_TYPES[index] ~= nil then
              subtree:add(register, string.format("[%s]", CONNECTOR_TYPES[index]))
            elseif index >= 10 then
              subtree:add(register, string.format("[Block B%03d]", index-9))
            end
          end
          offset = offset + 2
          index = index + 1
        end
      end
      return pdu_length
    end
  },
  [0x3c] = {
    dissect = function(tvb, pinfo, tree)
      -- Header fields
      if tvb:len() < PBUS_ALI_HDR_LEN then return 0 end
      -- 01 + Byte Count (16bit Big Endian)
      local number_of_bytes = tvb(1,2):uint()-1
      tree:add(ali_fields.header, tvb(0,1))
      tree:add(ali_fields.byte_count, tvb(1,2))
      -- Operation Code + ...
      local op_code = tvb(3,1):uint()
      tree:add(ali_fields.op_code, tvb(3,1))
      -- If this telegram has no data, then we are done here
      if number_of_bytes == 0 then return PBUS_ALI_HDR_LEN end

      -- Payload fields
      local pdu_length = PBUS_ALI_HDR_LEN + number_of_bytes
      if tvb:len() < pdu_length then return 0 end
      -- ... Data + ...
      local data = tvb(PBUS_ALI_HDR_LEN, 1)

      -- Payload fields
      local pdu_length = PBUS_ALI_HDR_LEN + number_of_bytes
      if tvb:len() < pdu_length then return 0 end
      -- ... Data + ...
      local data = tvb(PBUS_ALI_HDR_LEN, 1)
      local datatree = tree:add(tvb(PBUS_ALI_HDR_LEN, number_of_bytes)
                               , string.format("References (%d bytes)"
                                               , number_of_bytes))
      -- display the details if desired
      if default_settings.subdissect then
        local offset = PBUS_ALI_HDR_LEN
        datatree:add(ali_fields.byte_count, tvb(offset,1))
        offset = offset + 1
        local index = 1
        while offset < pdu_length do
          -- display opcode data
          local block     = tvb(offset, 1)
          local block_no  = block:uint()-9
          datatree:add(block, string.format("Name %d: B%03d", index, block_no))
          offset = offset + 1
          index = index + 1
        end
      end
      return pdu_length
    end
  },
  [0x3d] = {
    dissect = function(tvb, pinfo, tree)
      -- Header fields
      if tvb:len() < PBUS_ALI_HDR_LEN then return 0 end
      -- 01 + Byte Count (16bit Big Endian)
      local number_of_bytes = tvb(1,2):uint()-1
      tree:add(ali_fields.header, tvb(0,1))
      tree:add(ali_fields.byte_count, tvb(1,2))
      -- Operation Code + ...
      local op_code = tvb(3,1):uint()
      tree:add(ali_fields.op_code, tvb(3,1))
      -- If this telegram has no data, then we are done here
      if number_of_bytes == 0 then return PBUS_ALI_HDR_LEN end

      -- Payload fields
      local pdu_length = PBUS_ALI_HDR_LEN + number_of_bytes
      if tvb:len() < pdu_length then return 0 end
      -- ... Data + ...
      local data = tvb(PBUS_ALI_HDR_LEN, 1)
      local datatree = tree:add(tvb(PBUS_ALI_HDR_LEN, number_of_bytes)
                               , string.format("Block Names (%d bytes)"
                                               , number_of_bytes))
      -- display the details if desired
      if default_settings.subdissect then
        local offset = PBUS_ALI_HDR_LEN
        local index = 1
        while offset + OP_BLK_NAME_LEN <= pdu_length do
          -- block name text (8 bytes)
          local text = tvb(offset, OP_BLK_NAME_LEN)
          local char = text(0,1):uint()
          if char > 0 and char < 0xFF then
            datatree:add(text, string.format("Name %d (%d bytes): '%s'", index
                                             , OP_BLK_NAME_LEN, text:stringz()
                                             ))
          end
          -- increment offset
          offset = offset + OP_BLK_NAME_LEN
          -- next index
          index = index + 1
        end
      end

      return pdu_length
    end
  },
  [0x40] = {
    dissect = function(tvb, pinfo, tree)
      -- Header fields
      if tvb:len() < PBUS_ALI_HDR_LEN then return 0 end
      -- 01 + Byte Count (16bit Big Endian)
      local number_of_bytes = tvb(1,2):uint()-1
      tree:add(ali_fields.header, tvb(0,1))
      tree:add(ali_fields.byte_count, tvb(1,2))
      -- Operation Code + ...
      local op_code = tvb(3,1):uint()
      tree:add(ali_fields.op_code, tvb(3,1))
      -- If this telegram has no data, then we are done here
      if number_of_bytes == 0 then return PBUS_ALI_HDR_LEN end

      -- Payload fields
      local pdu_length = PBUS_ALI_HDR_LEN + number_of_bytes
      if tvb:len() < pdu_length then return 0 end
      -- ... Data + ...
      local data = tvb(PBUS_ALI_HDR_LEN, 1)
      local datatree = tree:add(tvb(PBUS_ALI_HDR_LEN, number_of_bytes),
                      string.format("Connectors (%d bytes)", number_of_bytes))

      -- display the details if desired
      if default_settings.subdissect then
        local offset = PBUS_ALI_HDR_LEN
        local row = 0
        while offset + OP_CONN_ROW_LEN < pdu_length do
          -- display header (2 bytes) + data (16 bytes) + trailer (2 bytes)
          local text = string.format("%s (%d bytes)",
                       CONNECTOR_TYPES[row] ~= nil and CONNECTOR_TYPES[row]
                       or "Data", OP_CONN_ROW_LEN)
          local rowtree = datatree:add(tvb(offset, OP_CONN_ROW_LEN), text)

          -- Determine if the connection is used in this row
          local bytes_to_consume = 16
          local is_used = false
          for i = 2,bytes_to_consume, 2 do
            is_used = tvb(offset+i,2):uint() ~= 0xFFFF
            if is_used then break end
          end
          -- display each connector if there is a connection in this row
          if is_used then
            for column = 2,bytes_to_consume, 2 do
              local connector   = tvb(offset + column + 0, 1)
              local link_type   = tvb(offset + column + 1, 1)
              local link_value  = link_type:uint()
              local subtree = rowtree:add(ali_fields.link_input, link_type)
              if link_value == 0x80 or link_value == 0xC0 then
                local block = connector:uint()
                subtree:add(connector, string.format("Block: B%03d (0x%02x)",
                                                      block-9, block))
              elseif link_value ~= 0xFF then
                subtree:add(ali_fields.connector, connector)
              end
            end
          end
          -- increment offset
          offset = offset + OP_CONN_ROW_LEN
          -- next row
          row = row + 1
        end
      end

      return pdu_length
    end
  },
  [0x41] = {
    dissect = function(tvb, pinfo, tree)
      -- Header fields
      if tvb:len() < PBUS_ALI_HDR_LEN then return 0 end
      -- 01 + Byte Count (16bit Big Endian)
      local number_of_bytes = tvb(1,2):uint()-1
      tree:add(ali_fields.header, tvb(0,1))
      tree:add(ali_fields.byte_count, tvb(1,2))
      -- Operation Code + ...
      local op_code = tvb(3,1):uint()
      tree:add(ali_fields.op_code, tvb(3,1))
      -- If this telegram has no data, then we are done here
      if number_of_bytes == 0 then return PBUS_ALI_HDR_LEN end

      -- Payload fields
      local pdu_length = PBUS_ALI_HDR_LEN + number_of_bytes
      if tvb:len() < pdu_length then return 0 end
      -- ... Data + ...
      local data = tvb(PBUS_ALI_HDR_LEN, 1)
      local datatree = tree:add(tvb(PBUS_ALI_HDR_LEN, number_of_bytes),
                      string.format("Memory (%d bytes)", number_of_bytes))

      -- display details
      if default_settings.subdissect then
        local offset = PBUS_ALI_HDR_LEN
        while offset + OP_PRGMEM_HDR_LEN < pdu_length do
          -- display opcode header
          local header      = tvb(offset, OP_PRGMEM_HDR_LEN)
          local register    = header(0,2)
          local byte_count  = header(2,2)
          local block_type  = header(4,1)
          local block_param = header(5,1)
          local subtree = datatree:add(ali_fields.register, register)
          subtree:add(ali_fields.byte_count, byte_count)
          subtree:add(ali_fields.block_type, block_type)
          local flagtree = subtree:add(ali_fields.block_param, block_param)
          flagtree:add(ali_fields.blk_retentivity, block_param)
          flagtree:add(ali_fields.blk_protection, block_param)
          offset = offset + OP_PRGMEM_HDR_LEN
          -- display opcode data
          local length = byte_count:uint()-2
          if pdu_length < offset + length then return offset end
          data = tvb(offset, length)
          subtree:add(ali_fields.data, data)
          offset = offset + length
        end
      end

      return pdu_length
    end
  },
  [0x42] = {
    dissect = function(tvb, pinfo, tree)
      return lookup_op_code[0x41].dissect(tvb, pinfo, tree)
    end
  },
  [0x5b] = {
    dissect = function(tvb, pinfo, tree)
      -- Header fields
      if tvb:len() < PBUS_ALI_HDR_LEN then return 0 end
      -- 01 + Byte Count (16bit Big Endian)
      local number_of_bytes = tvb(1,2):uint()-1
      tree:add(ali_fields.header, tvb(0,1))
      tree:add(ali_fields.byte_count, tvb(1,2))
      -- Operation Code + ...
      local op_code = tvb(3,1):uint()
      tree:add(ali_fields.op_code, tvb(3,1))
      -- If this telegram has no data, then we are done here
      if number_of_bytes == 0 then return PBUS_ALI_HDR_LEN end

      -- Payload fields
      local pdu_length = PBUS_ALI_HDR_LEN + number_of_bytes
      if tvb:len() < pdu_length then return 0 end
      -- ... Data + ...
      local datatree = tree:add(tvb(PBUS_ALI_HDR_LEN, number_of_bytes)
                       , string.format("References (%d bytes)"
                                       , number_of_bytes))
      -- display the details if desired
      if default_settings.subdissect then
        local offset = PBUS_ALI_HDR_LEN
        local index = 1
        while offset + 2 <= pdu_length do
          -- display opcode data
          local msg_ref   = tvb(offset  , 1)
          local char_set  = tvb(offset+1, 1)
          if msg_ref:uint() ~= 0xFF then
            local subtree = datatree:add(ali_fields.msg_index, msg_ref)
            subtree:add(ali_fields.char_set, char_set)
          end
          offset = offset + 2
          index = index + 1
        end
      end
      return pdu_length
    end
  },
  [0x61] = {
    dissect = function(tvb, pinfo, tree)
      -- Header fields
      if tvb:len() < PBUS_ALI_HDR_LEN then return 0 end
      -- 01 + Byte Count (16bit Big Endian)
      local number_of_bytes = tvb(1,2):uint()-1
      tree:add(ali_fields.header, tvb(0,1))
      tree:add(ali_fields.byte_count, tvb(1,2))
      -- Operation Code + ...
      local op_code = tvb(3,1):uint()
      tree:add(ali_fields.op_code, tvb(3,1))
      -- If this telegram has no data, then we are done here
      if number_of_bytes == 0 then return PBUS_ALI_HDR_LEN end

      -- Payload fields
      local pdu_length = PBUS_ALI_HDR_LEN + number_of_bytes
      if tvb:len() < pdu_length then return 0 end
      -- ... Data + ...
      local data = tvb(PBUS_ALI_HDR_LEN, 1)
      local datatree = tree:add(tvb(PBUS_ALI_HDR_LEN, number_of_bytes)
                               , string.format("Message Texts (%d bytes)"
                                               , number_of_bytes))
      -- display the details if desired
      if default_settings.subdissect then
        local offset = PBUS_ALI_HDR_LEN
        local number = 0
        while offset + OP_MSG_DISPLAY_LEN <= pdu_length do
          -- display message display
          local message = tvb(offset, OP_MSG_DISPLAY_LEN)
          local subtree = datatree:add(message
                          , string.format("Message %d (%d bytes)"
                                          , number, OP_MSG_DISPLAY_LEN))
          -- display each line
          local line = 1
          for p = 0, OP_MSG_DISPLAY_LEN-1, OP_MSG_ROW_LEN do
            -- text len (24 bytes)
            local text = message(p, OP_MSG_LINE_LEN)
            data = message(p + OP_MSG_LINE_LEN, OP_MSG_ROW_LEN
                           - OP_MSG_LINE_LEN)
            local str = text:string()
            str = string.gsub(str, "[\0-\31]", ".")
            -- https://stackoverflow.com/questions/40861780/lua-regex-for-ascii0-127-characters
            str = string.gsub(str, "[\192-\255][\128-\191]*", ".")
            subtree:add(text, string.format("Line %d (%d bytes): '%s'", line
                                            , OP_MSG_LINE_LEN, str))
            -- 8 bytes additional data
            subtree:add(ali_fields.data, data)
            -- increment line
            line = line + 1
          end
          -- increment offset
          offset = offset + OP_MSG_DISPLAY_LEN
          -- next number
          number = number + 1
        end
      end

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
--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
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
    -- if we got here, then we know we have enough bytes in the tvb
    -- to get the "Byte Count" field
    local number_of_bytes = tvb(1,2):uint()
    -- 01 + Byte Count (16bit Big Endian) + ...
    length = 1 + 2 + number_of_bytes
  else
    length = -1
  end

  if length < 0 then
    -- we need more bytes, so tell the main function that we didn't get the
    -- length, and we need an unknown number of more bytes (which is what
    -- "DESEGMENT_ONE_MORE_SEGMENT" is used for)
    dprint7("Need more bytes to figure out the ALI length")
    return DESEGMENT_ONE_MORE_SEGMENT
  end
  
  dprint7("Application Layer Interface length:", length)
  return length
end

--------------------------------------------------------------------------------
-- The following creates the callback function for the TD dissector.
--
-- The 'tvb' contains the packet data, 'pinfo' is a packet info object, and
-- 'tree' is the object of the Wireshark tree view which are create in the
-- PROFIBUS Proto's dissector.
--
-- 1. If the packet does not belong to our dissector, we return 0. We must not
--    set the Pinfo's "desegment_len" nor the "desegment_offset". 
-- 2. If we need more bytes, we set the Pinfo's "desegment_len/desegment_offset"
---   and return the length of the Tvb.
-- 3. If we don't need more bytes, we return the number of bytes of the Tvb that
--    belong to this protocol.
--------------------------------------------------------------------------------
function LOGOTD.dissector(tvb, pinfo, tree)
  dprint6("TD Protocol dissector() called, Telegram id:",
          packet_helper:get_number())

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
      -- we don't know exactly how many more bytes we need set the Pinfo
      -- desegment_len to the predefined conn_value "DESEGMENT_ONE_MORE_SEGMENT"
      pinfo.desegment_len = DESEGMENT_ONE_MORE_SEGMENT
    else
      -- set Pinfo's "desegment_len" to how many more bytes we need to decode
      -- the full ALI
      pinfo.desegment_len = ali_length - length
    end
    -- We also need to set the "dessegment_offset", so that the dissector can
    -- continue processing at the same position.
    pinfo.desegment_offset = 0

    -- We set desegment_len/desegment_offset as described earlier, so we return
    -- the length of the Tvb
    return length
  end
  -- if we got here, then we have a whole ALI in the Tvb buffer

  -- We start by setting our protocol name, info and tree set the protocol
  -- column to show our protocol name
  pinfo.cols.protocol = LOGOTD.name

  -- add our protocol to the dissection display tree.
  local subtree = tree:add(LOGOTD)
  local offset = 0
  local op_code = tvb(3,1):uint()
  if lookup_op_code[op_code] then
    offset = lookup_op_code[op_code].dissect(tvb, pinfo, subtree)
  else
    -- 01 + Byte Count (16bit Big Endian) + Operation Code + ...
    subtree:add(ali_fields.header, tvb(0,1))
    subtree:add(ali_fields.byte_count, tvb(1,2))
    subtree:add(ali_fields.op_code, tvb(3,1))
    offset = PBUS_ALI_HDR_LEN
  end

  -- append the INFO column
  if string.find(tostring(pinfo.cols.info), " Len=") == nil then
    if OP_CODES[op_code] then
      pinfo.cols.info:append(string.format(", %s", OP_CODES[op_code]))
    else
      pinfo.cols.info:append(string.format(", OP=0x%02x", op_code))
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
  local checksum = checkSum8Modulo256(tvb(offset,
                   length - PBUS_FDL_HDR_LEN - PBUS_TRAILER_LEN):bytes())

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
  local subtree = tree:add(tvb(offset,
                               length - PBUS_SD2_HDR_LEN - PBUS_TRAILER_LEN),
                           "Data Unit (DU)")
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
    local src = ADDRESS_VALUE[src_addr] and string.sub(ADDRESS_VALUE[src_addr]
                                                       , 1, 1) or nil
    local dst = ADDRESS_VALUE[dst_addr] and string.sub(ADDRESS_VALUE[dst_addr]
                                                       , 1, 1) or nil
    if src and dst then
      pinfo.cols.info:set(string.format("%s > %s", src, dst))
    else
      pinfo.cols.info:set(string.format("%d > %d", src_addr, dst_addr))
    end
    if FDL_CODES[telegram] then
      pinfo.cols.info:append(string.format(" [%s", FDL_CODES[telegram]))
    else
      pinfo.cols.info:append(string.format(" [FDL=0x%02x", telegram))
    end
    if FC_CODES[frame_control] then
      pinfo.cols.info:append(string.format(", %s]", FC_CODES[frame_control]))
    else
      pinfo.cols.info:append(string.format(", FC=0x%02x]", frame_control))
    end
    pinfo.cols.info:append(string.format(" Seq=%d", packet_helper:get_number()))
  end

  -- we are finished, now the dissected length will be returned
  return length
end

--------------------------------------------------------------------------------
-- The following creates the callback function for the PROFIBUS dissector.
-- It's implemented as a separate Protocal because we run over a serial
-- connector and thus might need to parse a single telegram over multiple
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
    pinfo.cols.info:set(string.format("[Telegram Fragment] Seq=%d",
                                      packet_helper:get_number()))
    -- The Tvb buffer is a fragment of a PROFINET telegram, so display only the
    -- meta fields and the data to the tree
    local subtree = root:add(PROFIBUS)
    flags = bit.bor(flags, FL_FRAGMENT)
    subtree:add(fdl_fields.telegram_number,
                packet_helper:get_number()):set_generated()
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
      -- If the result is 0, then it means we hit an error of some kind, so
      -- increment sequence and return 0.
      packet_helper:set_number(packet_helper:get_number() + 1)
      return 0
    end

    -- if we got here, then we know we have a PROFIBUS-DP telegram in the Tvb
    -- buffer
    local subtree = root:add(PROFIBUS)
    -- check if the remaning bytes in buffer are a part of a PROFIBUS-DP
    -- telegram or not
    local fragmented = bytes_consumed + result > length
    -- Inserted the telegram fields to the tree
    flags = 0
    if not fragmented then flags = bit.band(flags, bit.bnot(FL_FRAGMENT)) end
    subtree:add(fdl_fields.telegram_number,
                packet_helper:get_number()):set_generated()
    local flagtree = subtree:add(fdl_fields.flags, flags):set_generated()
    flagtree:add(fdl_fields.fragmented, flags)

    -- reference to #1 and #3
    -- We might have to implement something similar to TCP in our dissector.
    -- For that we using old desegment_offset/desegment_len method
    if fragmented then
      -- call the data dissector
      data:call(buffer(bytes_consumed, length - bytes_consumed):tvb(),
                pinfo, root)

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
    -- conn_value is DESEGMENT_ONE_MORE_SEGMENT then we need additional bytes. 
    -- If it returns a 0, it's a dissection error.
    if dissectPBUS(buffer, pinfo, subtree, bytes_consumed) == 0 then
      -- If the result is 0, then it means we hit an error
      return 0
    end

    -- we successfully processed the PROFIBUS-DP telegram fields, now invoke the
    -- LOGOTD dissector
    local proto_offset = bytes_consumed + PBUS_SD2_HDR_LEN + PBUS_DDLM_HDR_LEN
    local proto_length = result
    proto_length = proto_length - PBUS_SD2_HDR_LEN
    proto_length = proto_length - PBUS_DDLM_HDR_LEN
    proto_length = proto_length - PBUS_TRAILER_LEN
    result = Dissector.get("logotd"):call(buffer(proto_offset
             , proto_length):tvb(), pinfo, root)
    if result == 0 then
      -- If the result is 0, then it means we hit an error
      return 0
    end
    -- we successfully processed the LOGOTD dissector, of 'result' length
    bytes_consumed = bytes_consumed + PBUS_SD2_HDR_LEN
    bytes_consumed = bytes_consumed + PBUS_DDLM_HDR_LEN
    bytes_consumed = bytes_consumed + result
    bytes_consumed = bytes_consumed + PBUS_TRAILER_LEN
    
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
PROFIBUS.prefs.conn_value = Pref.uint("Value", default_settings.conn_value
                                      , "Start conn_value for counting")

PROFIBUS.prefs.subdissect = Pref.bool("Enable sub-dissectors"
                                      , default_settings.subdissect
                        , "Whether the data content should be dissected or not")

PROFIBUS.prefs.debug      = Pref.enum("Debug", default_settings.debug_level
                                      , "The debug printing level"
                                      , debug_pref_enum)

--------------------------------------------------------------------------------
-- the function for handling preferences being changed
function PROFIBUS.prefs_changed()
  dprint6("PROFIBUS prefs_changed() called")

  default_settings.conn_value = PROFIBUS.prefs.conn_value
  default_settings.subdissect = PROFIBUS.prefs.subdissect
  default_settings.debug_level = PROFIBUS.prefs.debug
  reset_debug_level()
  
  -- have to reload the capture file for this type of change
  reload()
end

dprint7("PCapfile Prefs registered")
