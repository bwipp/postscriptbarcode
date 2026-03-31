/*
 * libpostscriptbarcode C++ interface
 *
 * @file postscriptbarcode.hpp
 * @author Terry Burton
 *
 * \copyright Copyright (c) 2004-2026 Terry Burton
 * Barcode Writer in Pure PostScript
 *
 * @licenseblock{License}
 *
 * Permission is hereby granted, free of charge, to any
 * person obtaining a copy of this software and associated
 * documentation files (the "Software"), to deal in the
 * Software without restriction, including without
 * limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software
 * is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice
 * shall be included in all copies or substantial portions
 * of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
 * KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
 * THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 * CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 *
 * @endlicenseblock
 *
 *
 * Overview
 * --------
 *
 * C++ wrapper around libpostscriptbarcode providing RAII resource
 * management and idiomatic C++ types (std::string, std::vector,
 * std::map) in place of the C library's raw pointers and manual
 * bwipp_free() calls.
 *
 * The basic workflow mirrors the C library: construct a BWIPP object
 * (optionally with InitOpts) to load the resources, query encoders
 * and their properties, then emit PostScript code. The destructor
 * handles cleanup automatically.
 *
 * Example:
 *
 *     bwipp::BWIPP ctx(bwipp::InitOpts{}.filename("path/to/barcode.ps"));
 *     auto encoders = ctx.list_encoders();
 *     std::string ps = ctx.emit_required_resources("qrcode")
 *                     + ctx.emit_exec("qrcode", "Hello", "eclevel=M");
 *
 * The wrapper is header-only and links against the C library
 * (libpostscriptbarcode).
 *
 */

#ifndef POSTSCRIPTBARCODE_HPP
#define POSTSCRIPTBARCODE_HPP

#include <postscriptbarcode.h>

#include <map>
#include <stdexcept>
#include <string>
#include <vector>

namespace bwipp {

class BWIPP;

/**
 * @brief Initialisation options for BWIPP construction.
 */
struct InitOpts {
	InitOpts &filename(std::string f) { filename_ = std::move(f); return *this; }
	InitOpts &lazy_load(bool l) { lazy_load_ = l; return *this; }
	InitOpts &hexify_width(unsigned int w) { hexify_width_ = w; return *this; }
private:
	friend class BWIPP;
	std::string filename_;
	bool lazy_load_ = false;
	unsigned int hexify_width_ = 0;
};

/**
 * @brief C++ wrapper around the BWIPP context.
 *
 * Move-only. Construct to load resources; destroy to release them.
 */
class BWIPP {
public:

	/**
	 * @brief Load BWIPP resources from default locations.
	 * @throws std::runtime_error if loading fails.
	 */
	BWIPP() : ctx_(bwipp_load()) {
		if (!ctx_)
			throw std::runtime_error("bwipp: failed to load resources");
	}

	/**
	 * @brief Load BWIPP resources with options.
	 * @param init Initialisation options.
	 * @throws std::runtime_error if loading fails.
	 */
	BWIPP(const InitOpts &init) {
		bwipp_load_init_opts_t opts = {};
		opts.struct_size = sizeof(opts);
		opts.filename = init.filename_.empty() ? nullptr : init.filename_.c_str();
		opts.flags = init.lazy_load_ ? bwipp_iLAZY_LOAD : bwipp_iDEFAULT;
		opts.hexify_width = init.hexify_width_;
		ctx_ = bwipp_load_ex(&opts);
		if (!ctx_)
			throw std::runtime_error("bwipp: failed to load resources");
	}

	~BWIPP() {
		if (ctx_)
			bwipp_unload(ctx_);
	}

	BWIPP(const BWIPP &) = delete;
	BWIPP &operator=(const BWIPP &) = delete;

	BWIPP(BWIPP &&other) noexcept : ctx_(other.ctx_) {
		other.ctx_ = nullptr;
	}

	BWIPP &operator=(BWIPP &&other) noexcept {
		if (this != &other) {
			if (ctx_)
				bwipp_unload(ctx_);
			ctx_ = other.ctx_;
			other.ctx_ = nullptr;
		}
		return *this;
	}

	/**
	 * @brief Get the BWIPP version string.
	 * @return Version string, or empty if unavailable.
	 */
	std::string get_version() const {
		const char *v = bwipp_get_version(ctx_);
		return v ? v : std::string();
	}

	/**
	 * @brief List all encoder names, sorted lexicographically.
	 * @return Vector of encoder name strings.
	 */
	std::vector<std::string> list_encoders() const {
		unsigned int count = 0;
		const char **list = bwipp_list_encoders(ctx_, &count);
		return take_string_array(list, count);
	}

	/**
	 * @brief List property keys for a named resource.
	 * @param name The resource name.
	 * @return Vector of property key strings, or empty if not found.
	 */
	std::vector<std::string> list_properties(const std::string &name) const {
		unsigned int count = 0;
		const char **list = bwipp_list_properties(ctx_, name.c_str(), &count);
		return take_string_array(list, count);
	}

	/**
	 * @brief Get a single property value.
	 * @param name The resource name.
	 * @param key The property key.
	 * @return The property value, or empty if not found.
	 */
	std::string get_property(const std::string &name,
	                         const std::string &key) const {
		const char *v = bwipp_get_property(ctx_, name.c_str(), key.c_str());
		return v ? v : std::string();
	}

	/**
	 * @brief Get all properties for a resource as key-value pairs.
	 * @param name The resource name.
	 * @return Ordered map of property key-value pairs.
	 */
	std::map<std::string, std::string> get_properties(
			const std::string &name) const {
		unsigned int count = 0;
		const char **list = bwipp_get_properties(ctx_, name.c_str(), &count);
		std::map<std::string, std::string> result;
		if (list) {
			for (unsigned int i = 0; i < count * 2; i += 2)
				result[list[i]] = list[i + 1];
			bwipp_free(const_cast<void *>(static_cast<const void *>(list)));
		}
		return result;
	}

	/**
	 * @brief List unique family names, sorted lexicographically.
	 * @return Vector of family name strings.
	 */
	std::vector<std::string> list_families() const {
		unsigned int count = 0;
		const char **list = bwipp_list_families(ctx_, &count);
		return take_string_array(list, count);
	}

	/**
	 * @brief List encoder names belonging to a family.
	 * @param family The family name.
	 * @return Vector of encoder name strings, or empty if not found.
	 */
	std::vector<std::string> list_family_members(
			const std::string &family) const {
		unsigned int count = 0;
		const char **list = bwipp_list_family_members(ctx_, family.c_str(),
		                                              &count);
		return take_string_array(list, count);
	}

	/**
	 * @brief Emit the PostScript resources required for an encoder.
	 * @param name The encoder or resource name.
	 * @return PostScript resource code.
	 */
	std::string emit_required_resources(const std::string &name) const {
		char *code = bwipp_emit_required_resources(ctx_, name.c_str());
		return take_string(code);
	}

	/**
	 * @brief Emit all PostScript resources.
	 * @return PostScript code containing all resources.
	 */
	std::string emit_all_resources() const {
		char *code = bwipp_emit_all_resources(ctx_);
		return take_string(code);
	}

	/**
	 * @brief Emit PostScript code to invoke a barcode encoder.
	 * @param name The encoder name.
	 * @param data The barcode data.
	 * @param options The encoder options.
	 * @return PostScript invocation code.
	 */
	std::string emit_exec(const std::string &name, const std::string &data,
	                       const std::string &options) const {
		char *code = bwipp_emit_exec(ctx_, name.c_str(), data.c_str(),
		                             options.c_str());
		return take_string(code);
	}

	/**
	 * @brief Emit PostScript code from a template with substitutions.
	 *
	 * Substitution variables: %enc, %dat, %opt, %%.
	 *
	 * @param fmt Format string.
	 * @param name Encoder name.
	 * @param data Barcode data.
	 * @param options Barcode options.
	 * @return Expanded PostScript code.
	 */
	std::string emit_template(const std::string &fmt,
	                           const std::string &name,
	                           const std::string &data,
	                           const std::string &options) const {
		char *code = bwipp_emit_template(ctx_, fmt.c_str(), name.c_str(),
		                                 data.c_str(), options.c_str());
		return take_string(code);
	}

	/**
	 * @brief Encode a string as a PostScript hex string literal.
	 * @param str The input string.
	 * @return Hex-encoded PostScript string (e.g. \<48656C6C6F\>).
	 */
	std::string emit_pshexstr(const std::string &str) const {
		char *hex = bwipp_emit_pshexstr(ctx_, str.c_str());
		return take_string(hex);
	}

private:

	::BWIPP *ctx_ = nullptr;

	static std::string take_string(char *s) {
		if (!s)
			return {};
		std::string result(s);
		bwipp_free(s);
		return result;
	}

	static std::vector<std::string> take_string_array(const char **list,
	                                                   unsigned int count) {
		std::vector<std::string> result;
		if (list) {
			result.reserve(count);
			for (unsigned int i = 0; i < count; i++)
				result.emplace_back(list[i]);
			bwipp_free(const_cast<void *>(
				static_cast<const void *>(list)));
		}
		return result;
	}

};

} /* namespace bwipp */

#endif /* POSTSCRIPTBARCODE_HPP */
