--
-- libpostscriptbarcode LuaJIT FFI interface tests
--
-- Copyright (c) 2004-2026 Terry Burton
--
-- Permission is hereby granted, free of charge, to any
-- person obtaining a copy of this software and associated
-- documentation files (the "Software"), to deal in the
-- Software without restriction, including without
-- limitation the rights to use, copy, modify, merge,
-- publish, distribute, sublicense, and/or sell copies of
-- the Software, and to permit persons to whom the Software
-- is furnished to do so, subject to the following
-- conditions:
--
-- The above copyright notice and this permission notice
-- shall be included in all copies or substantial portions
-- of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
-- KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
-- THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
-- PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
-- THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
-- DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
-- CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
-- CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
-- IN THE SOFTWARE.
--

package.path = "./?.lua;" .. package.path

local bwipp = require("postscriptbarcode")

local MOCK_PS = "test_barcode_lua.ps"
local BARCODE_PS = "../../../build/monolithic/barcode.ps"

local mock_ps = [[
%!PS

% Barcode Writer in Pure PostScript - Version 2099-01-01
% https://bwipp.terryburton.co.uk
%
% --BEGIN TEMPLATE--
% --BEGIN RESOURCE base--
% base code
% --END RESOURCE base--
% --BEGIN RESOURCE helper--
% --REQUIRES base--
% helper code
% --END RESOURCE helper--
% --BEGIN ENCODER encoder--
% --REQUIRES base helper--
% --DESC: Test Encoder
% --EXAM: TEST123
% --EXOP: includetext
% --RNDR: renlinear
% --FMLY: Test Family
% encoder code
% --END ENCODER encoder--
% --END TEMPLATE--
]]

local mock_ps_two_families = [[
%!PS
% Barcode Writer in Pure PostScript - Version 2099-01-01
% --BEGIN TEMPLATE--
% --BEGIN ENCODER enc_a--
% --DESC: Encoder A
% --FMLY: Alpha
% a code
% --END ENCODER enc_a--
% --BEGIN ENCODER enc_b--
% --DESC: Encoder B
% --FMLY: Beta
% b code
% --END ENCODER enc_b--
% --BEGIN ENCODER enc_c--
% --DESC: Encoder C
% --FMLY: Alpha
% c code
% --END ENCODER enc_c--
% --END TEMPLATE--
]]

local function write_mock_ps(content)
	local f = assert(io.open(MOCK_PS, "wb"))
	f:write(content)
	f:close()
end

local function mock(content, opts)
	write_mock_ps(content or mock_ps)
	opts = opts or {}
	opts.filename = MOCK_PS
	return assert(bwipp.new(opts))
end

local function real(opts)
	opts = opts or {}
	opts.filename = BARCODE_PS
	return assert(bwipp.new(opts))
end

local function contains(s, sub)
	return s:find(sub, 1, true) ~= nil
end

local tests = {}

local function test(name, fn)
	tests[#tests + 1] = {name = name, fn = fn}
end


--
-- Construction and lifetime
--

test("load_with_init_opts", function()
	local ctx = mock()
	assert(ctx:get_version() == "2099-01-01")
end)

test("load_with_lazy", function()
	local ctx = mock(nil, {lazy_load = true})
	assert(ctx:get_version() == "2099-01-01")
	assert(contains(ctx:emit_required_resources("encoder"), "% encoder code"))
end)

test("load_failure", function()
	local ctx, err = bwipp.new{filename = "/nonexistent/path/barcode.ps"}
	assert(ctx == nil)
	assert(type(err) == "string")
end)

test("close", function()
	local ctx = mock()
	ctx:close()
	ctx:close()
	assert(not pcall(ctx.get_version, ctx))
end)

test("collect", function()
	for _ = 1, 100 do
		mock()
	end
	collectgarbage()
	collectgarbage()
end)

test("bad_arguments", function()
	local ctx = mock()
	assert(not pcall(bwipp.new, "barcode.ps"))
	assert(not pcall(bwipp.new, {filename = 1}))
	assert(not pcall(ctx.get_property, ctx, "encoder", nil))
	assert(not pcall(ctx.emit_exec, ctx, "encoder", "DATA"))
	assert(not pcall(ctx.emit_pshexstr, ctx, nil))
end)


--
-- Version, encoders and properties
--

test("get_version", function()
	assert(mock():get_version() == "2099-01-01")
end)

test("list_encoders", function()
	local encoders = mock():list_encoders()
	assert(#encoders == 1)
	assert(encoders[1] == "encoder")
end)

test("list_encoders_sorted", function()
	local encoders = mock(mock_ps_two_families):list_encoders()
	assert(#encoders == 3)
	assert(encoders[1] == "enc_a")
	assert(encoders[2] == "enc_b")
	assert(encoders[3] == "enc_c")
end)

test("list_properties", function()
	local ctx = mock()
	local props = ctx:list_properties("encoder")
	assert(#props == 6)
	assert(props[1] == "TYPE")
	assert(ctx:list_properties("nonexistent") == nil)
end)

test("get_property", function()
	local ctx = mock()
	assert(ctx:get_property("encoder", "TYPE") == "ENCODER")
	assert(ctx:get_property("encoder", "DESC") == "Test Encoder")
	assert(ctx:get_property("encoder", "EXAM") == "TEST123")
	assert(ctx:get_property("encoder", "EXOP") == "includetext")
	assert(ctx:get_property("encoder", "RNDR") == "renlinear")
	assert(ctx:get_property("encoder", "FMLY") == "Test Family")
	assert(ctx:get_property("encoder", "NOSUCH") == nil)
	assert(ctx:get_property("nonexistent", "TYPE") == nil)
end)

test("get_properties", function()
	local ctx = mock()
	local props = ctx:get_properties("encoder")
	local n = 0
	for _ in pairs(props) do
		n = n + 1
	end
	assert(n == 6)
	assert(props.TYPE == "ENCODER")
	assert(props.DESC == "Test Encoder")
	assert(props.EXAM == "TEST123")
	assert(props.EXOP == "includetext")
	assert(ctx:get_properties("nonexistent") == nil)
end)


--
-- Families
--

test("list_families", function()
	local families = mock(mock_ps_two_families):list_families()
	assert(#families == 2)
	assert(families[1] == "Alpha")
	assert(families[2] == "Beta")
end)

test("list_family_members", function()
	local ctx = mock(mock_ps_two_families)
	assert(#ctx:list_family_members("Alpha") == 2)
	local beta = ctx:list_family_members("Beta")
	assert(#beta == 1)
	assert(beta[1] == "enc_b")
	assert(ctx:list_family_members("NoSuchFamily") == nil)
end)


--
-- Emit functions
--

test("emit_required_resources", function()
	local ctx = mock()
	local code = ctx:emit_required_resources("encoder")
	assert(contains(code, "% base code"))
	assert(contains(code, "% helper code"))
	assert(contains(code, "% encoder code"))
	assert(ctx:emit_required_resources("nonexistent") == "")
end)

test("emit_all_resources", function()
	local code = mock():emit_all_resources()
	assert(contains(code, "% base code"))
	assert(contains(code, "% helper code"))
	assert(contains(code, "% encoder code"))
end)

test("emit_exec", function()
	local code = mock():emit_exec("encoder", "DATA", "opt=val")
	assert(contains(code, "findresource"))
end)

test("emit_template", function()
	local code = mock():emit_template(
		"%dat %opt %enc /uk.co.terryburton.bwipp findresource exec",
		"encoder", "DATA", "opt=val")
	assert(contains(code, "findresource"))
	assert(contains(code, "cvn"))
end)

test("emit_pshexstr", function()
	local ctx = mock()
	assert(ctx:emit_pshexstr("Hello") == "<48656C6C6F>")
	assert(ctx:emit_pshexstr("") == "<>")
end)

test("emit_pshexstr_stops_at_nul", function()
	assert(mock():emit_pshexstr("AB\0CD") == "<4142>")
end)

test("emit_pshexstr_hexify_width", function()
	local long = string.rep("A", 40)
	local wrapped = mock(nil, {hexify_width = 8}):emit_pshexstr(long)
	assert(contains(wrapped, "\n"))
	local unwrapped = mock(nil, {hexify_width = 0xFFFFFFFF}):emit_pshexstr(long)
	assert(unwrapped == "<" .. string.rep("41", 40) .. ">")
end)


--
-- Integration tests with real barcode.ps
--

test("real_list_encoders", function()
	assert(#real():list_encoders() > 100)
end)

test("real_qrcode_properties", function()
	local props = real({lazy_load = true}):get_properties("qrcode")
	assert(props.TYPE == "ENCODER")
	assert(props.DESC ~= nil and props.DESC ~= "")
	assert(props.EXAM ~= nil and props.EXAM ~= "")
	assert(props.EXOP ~= nil)
end)

test("real_version", function()
	assert(real():get_version():match("^%d%d%d%d%-%d%d%-%d%d$"))
end)

test("real_emit_qrcode", function()
	local ctx = real({lazy_load = true})
	assert(contains(ctx:emit_required_resources("qrcode"),
		"%%BeginResource: uk.co.terryburton.bwipp qrcode "))
	assert(contains(ctx:emit_exec("qrcode", "Hello World", "eclevel=M"),
		"findresource"))
end)

test("real_families", function()
	local ctx = real()
	local families = ctx:list_families()
	assert(#families > 5)
	for _, family in ipairs(families) do
		assert(#ctx:list_family_members(family) > 0)
	end
end)


local failed = 0
for _, t in ipairs(tests) do
	local ok, err = pcall(t.fn)
	if ok then
		print("ok     " .. t.name)
	else
		failed = failed + 1
		print("FAILED " .. t.name .. ": " .. tostring(err))
	end
end
os.remove(MOCK_PS)
print(string.format("%d/%d tests passed", #tests - failed, #tests))
os.exit(failed == 0 and 0 or 1)
