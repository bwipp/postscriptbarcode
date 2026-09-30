--
-- Example user of the BWIPP LuaJIT FFI binding
--

package.path = "./?.lua;" .. package.path

local bwipp = require("postscriptbarcode")

local filename = arg[1] or "../../../build/monolithic/barcode.ps"
local ctx = assert(bwipp.new{filename = filename, lazy_load = true})

print("Version: " .. ctx:get_version())

local encoders = ctx:list_encoders()
print("Encoders: " .. #encoders)

local families = ctx:list_families()
print("Families: " .. #families)
for _, family in ipairs(families) do
	print("  " .. family .. ": " .. #ctx:list_family_members(family) .. " members")
end

local props = ctx:get_properties("qrcode")
for _, key in ipairs(ctx:list_properties("qrcode")) do
	print("  " .. key .. ": " .. props[key])
end

print("Hex string: " .. ctx:emit_pshexstr("Hello"))

local _, lines = ctx:emit_required_resources("qrcode"):gsub("\n", "")
print("qrcode resource lines: " .. lines)

print(ctx:emit_exec("qrcode", "Hello World", "eclevel=M"))

ctx:close()
