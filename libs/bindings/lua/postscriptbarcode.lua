--
-- libpostscriptbarcode LuaJIT FFI interface
--
-- Copyright (c) 2004-2026 Terry Burton
-- Barcode Writer in Pure PostScript
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
--
-- Overview
-- --------
--
-- LuaJIT FFI wrapper around libpostscriptbarcode returning Lua strings and
-- tables in place of the C library's raw pointers. Every value returned is a
-- Lua-owned copy; C allocations are released with bwipp_free() before the
-- method returns, and the context is released by close() or by the garbage
-- collector.
--
-- Example:
--
--     local bwipp = require("postscriptbarcode")
--     local ctx = assert(bwipp.new{filename = "path/to/barcode.ps"})
--     local encoders = ctx:list_encoders()
--     local ps = ctx:emit_required_resources("qrcode")
--             .. ctx:emit_exec("qrcode", "Hello", "eclevel=M")
--
-- Arguments are passed to C as NUL-terminated strings, so a Lua string
-- argument is truncated at its first zero byte.
--

local ffi = require("ffi")

ffi.cdef[[
typedef struct BWIPP BWIPP;

enum bwipp_load_init_flags {
	bwipp_iDEFAULT    = 0,
	bwipp_iLAZY_LOAD  = 1,
};
typedef enum bwipp_load_init_flags bwipp_load_init_flags_t;

struct bwipp_load_init_opts {
	size_t struct_size;
	const char *filename;
	bwipp_load_init_flags_t flags;
	unsigned int hexify_width;
};
typedef struct bwipp_load_init_opts bwipp_load_init_opts_t;

BWIPP *bwipp_load(void);
BWIPP *bwipp_load_ex(const bwipp_load_init_opts_t *opts);
void bwipp_unload(BWIPP *ctx);
const char *bwipp_get_version(BWIPP *ctx);
const char **bwipp_list_encoders(BWIPP *ctx, unsigned int *count);
const char **bwipp_list_properties(BWIPP *ctx, const char *name,
                                   unsigned int *count);
const char *bwipp_get_property(BWIPP *ctx, const char *name,
                               const char *key);
const char **bwipp_get_properties(BWIPP *ctx, const char *name,
                                  unsigned int *count);
const char **bwipp_list_families(BWIPP *ctx, unsigned int *count);
const char **bwipp_list_family_members(BWIPP *ctx, const char *family,
                                       unsigned int *count);
char *bwipp_emit_required_resources(BWIPP *ctx, const char *name);
char *bwipp_emit_all_resources(BWIPP *ctx);
char *bwipp_emit_exec(BWIPP *ctx, const char *barcode,
                      const char *contents, const char *options);
char *bwipp_emit_template(BWIPP *ctx, const char *fmt, const char *name,
                          const char *data, const char *options);
char *bwipp_emit_pshexstr(BWIPP *ctx, const char *str);
void bwipp_free(void *p);
]]

-- The soname pins the ABI that the declarations above describe
local function load_library()
	local errs = {}
	for _, name in ipairs{"libpostscriptbarcode.so.1", "postscriptbarcode"} do
		local ok, lib = pcall(ffi.load, name)
		if ok then
			return lib
		end
		errs[#errs + 1] = lib
	end
	error("postscriptbarcode: cannot load C library: "
		.. table.concat(errs, "; "), 2)
end

local C = load_library()

local count_t = ffi.typeof("unsigned int[1]")

local M = {}

local BWIPP = {}
BWIPP.__index = BWIPP

local function check_string(v, arg)
	if type(v) ~= "string" then
		error("postscriptbarcode: " .. arg .. " must be a string", 3)
	end
end

local function ptr(self)
	local ctx = self.ctx
	if ctx == nil then
		error("postscriptbarcode: context is closed", 3)
	end
	return ctx
end

local function take_string(s)
	if s == nil then
		return nil
	end
	local result = ffi.string(s)
	C.bwipp_free(s)
	return result
end

-- The array is owned by the caller but its strings are owned by the context
local function take_string_array(list, count)
	if list == nil then
		return nil
	end
	local result = {}
	for i = 0, count[0] - 1 do
		result[i + 1] = ffi.string(list[i])
	end
	C.bwipp_free(ffi.cast("void *", list))
	return result
end

--- Load the BWIPP resources.
-- opts is an optional table with fields filename (path to barcode.ps),
-- lazy_load (boolean) and hexify_width (0 for the default, else an even
-- width >= 2).
-- Returns a context, or nil and a message when loading fails.
function M.new(opts)
	local ctx
	if opts == nil then
		ctx = C.bwipp_load()
	else
		if type(opts) ~= "table" then
			error("postscriptbarcode: opts must be a table", 2)
		end
		if opts.filename ~= nil then
			check_string(opts.filename, "filename")
		end
		local c_opts = ffi.new("bwipp_load_init_opts_t")
		c_opts.struct_size = ffi.sizeof(c_opts)
		c_opts.filename = opts.filename
		c_opts.flags = opts.lazy_load and C.bwipp_iLAZY_LOAD or C.bwipp_iDEFAULT
		c_opts.hexify_width = opts.hexify_width or 0
		ctx = C.bwipp_load_ex(c_opts)
	end
	if ctx == nil then
		return nil, "postscriptbarcode: failed to load resources"
	end
	return setmetatable({ctx = ffi.gc(ctx, C.bwipp_unload)}, BWIPP)
end

--- Release the context now rather than when it is garbage collected.
function BWIPP:close()
	local ctx = self.ctx
	if ctx ~= nil then
		self.ctx = nil
		ffi.gc(ctx, nil)
		C.bwipp_unload(ctx)
	end
end

--- The BWIPP version string, or nil if unavailable.
function BWIPP:get_version()
	local v = C.bwipp_get_version(ptr(self))
	return v ~= nil and ffi.string(v) or nil
end

--- Array of encoder names, sorted lexicographically.
function BWIPP:list_encoders()
	local count = count_t()
	return take_string_array(C.bwipp_list_encoders(ptr(self), count), count)
end

--- Array of property keys for a resource, or nil if not found.
function BWIPP:list_properties(name)
	check_string(name, "name")
	local count = count_t()
	return take_string_array(
		C.bwipp_list_properties(ptr(self), name, count), count)
end

--- A single property value, or nil if not found.
function BWIPP:get_property(name, key)
	check_string(name, "name")
	check_string(key, "key")
	local v = C.bwipp_get_property(ptr(self), name, key)
	return v ~= nil and ffi.string(v) or nil
end

--- Table of property key-value pairs for a resource, or nil if not found.
function BWIPP:get_properties(name)
	check_string(name, "name")
	local count = count_t()
	local list = C.bwipp_get_properties(ptr(self), name, count)
	if list == nil then
		return nil
	end
	local result = {}
	for i = 0, 2 * count[0] - 1, 2 do
		result[ffi.string(list[i])] = ffi.string(list[i + 1])
	end
	C.bwipp_free(ffi.cast("void *", list))
	return result
end

--- Array of family names, sorted lexicographically.
function BWIPP:list_families()
	local count = count_t()
	return take_string_array(C.bwipp_list_families(ptr(self), count), count)
end

--- Array of encoder names belonging to a family, or nil if not found.
function BWIPP:list_family_members(family)
	check_string(family, "family")
	local count = count_t()
	return take_string_array(
		C.bwipp_list_family_members(ptr(self), family, count), count)
end

--- PostScript code for the resources required by an encoder, or nil.
function BWIPP:emit_required_resources(name)
	check_string(name, "name")
	return take_string(C.bwipp_emit_required_resources(ptr(self), name))
end

--- PostScript code for all resources, or nil.
function BWIPP:emit_all_resources()
	return take_string(C.bwipp_emit_all_resources(ptr(self)))
end

--- PostScript code invoking an encoder, or nil.
function BWIPP:emit_exec(name, data, options)
	check_string(name, "name")
	check_string(data, "data")
	check_string(options, "options")
	return take_string(C.bwipp_emit_exec(ptr(self), name, data, options))
end

--- PostScript code from a template substituting %enc, %dat, %opt and %%,
-- or nil.
function BWIPP:emit_template(fmt, name, data, options)
	check_string(fmt, "fmt")
	check_string(name, "name")
	check_string(data, "data")
	check_string(options, "options")
	return take_string(
		C.bwipp_emit_template(ptr(self), fmt, name, data, options))
end

--- A PostScript hex string literal encoding str up to its first zero byte,
-- or nil.
function BWIPP:emit_pshexstr(str)
	check_string(str, "str")
	return take_string(C.bwipp_emit_pshexstr(ptr(self), str))
end

return M
