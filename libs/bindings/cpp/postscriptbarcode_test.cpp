/*
 * libpostscriptbarcode C++ interface
 *
 * @file postscriptbarcode_test.cpp
 * @author Copyright (c) 2004-2026 Terry Burton.
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
 */

#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <stdexcept>
#include <string>
#include <utility>

/*
 *  Don't flag warnings in third-party test harness code.
 */
#if defined(__clang__)
#elif defined(__GNUC__)
#  pragma GCC diagnostic push
#  pragma GCC diagnostic ignored "-Wsign-conversion"
#  pragma GCC diagnostic ignored "-Wclobbered"
#elif defined(_MSC_VER)
#  include <CodeAnalysis/warnings.h>
#  pragma warning(push)
#  pragma warning(disable: ALL_CODE_ANALYSIS_WARNINGS)
#endif
#include "acutest.h"
#if defined(__clang__)
#elif defined(__GNUC__)
#  pragma GCC diagnostic pop
#elif defined(_MSC_VER)
#  pragma warning(pop)
#endif

#include "postscriptbarcode.hpp"

#define MOCK_PS "test_barcode_cpp.ps"
#define BARCODE_PS "../../../build/monolithic/barcode.ps"


static void write_mock_ps(const char *filename, const char *content) {
	std::ofstream f(filename);
	if (!f) {
		std::perror(filename);
		std::abort();
	}
	f << content;
}

static const char mock_ps[] =
	"%!PS\n"
	"\n"
	"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
	"% https://bwipp.terryburton.co.uk\n"
	"%\n"
	"% --BEGIN TEMPLATE--\n"
	"% --BEGIN RESOURCE base--\n"
	"% base code\n"
	"% --END RESOURCE base--\n"
	"% --BEGIN RESOURCE helper--\n"
	"% --REQUIRES base--\n"
	"% helper code\n"
	"% --END RESOURCE helper--\n"
	"% --BEGIN ENCODER encoder--\n"
	"% --REQUIRES base helper--\n"
	"% --DESC: Test Encoder\n"
	"% --EXAM: TEST123\n"
	"% --EXOP: includetext\n"
	"% --RNDR: renlinear\n"
	"% --FMLY: Test Family\n"
	"% encoder code\n"
	"% --END ENCODER encoder--\n"
	"% --END TEMPLATE--\n";

static const char mock_ps_two_families[] =
	"%!PS\n"
	"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
	"% --BEGIN TEMPLATE--\n"
	"% --BEGIN ENCODER enc_a--\n"
	"% --DESC: Encoder A\n"
	"% --FMLY: Alpha\n"
	"% a code\n"
	"% --END ENCODER enc_a--\n"
	"% --BEGIN ENCODER enc_b--\n"
	"% --DESC: Encoder B\n"
	"% --FMLY: Beta\n"
	"% b code\n"
	"% --END ENCODER enc_b--\n"
	"% --BEGIN ENCODER enc_c--\n"
	"% --DESC: Encoder C\n"
	"% --FMLY: Alpha\n"
	"% c code\n"
	"% --END ENCODER enc_c--\n"
	"% --END TEMPLATE--\n";


/* ========================================================================
 *  Construction and RAII
 * ======================================================================== */

static void test_load_with_init_opts(void) {
	write_mock_ps(MOCK_PS, mock_ps);
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(MOCK_PS));
	TEST_CHECK(ctx.get_version() == "2099-01-01");
	std::remove(MOCK_PS);
}

static void test_load_with_lazy(void) {
	write_mock_ps(MOCK_PS, mock_ps);
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(MOCK_PS).lazy_load(true));
	TEST_CHECK(ctx.get_version() == "2099-01-01");
	std::string code = ctx.emit_required_resources("encoder");
	TEST_CHECK(!code.empty());
	std::remove(MOCK_PS);
}

static void test_load_failure_throws(void) {
	bool threw = false;
	try {
		bwipp::BWIPP ctx(bwipp::InitOpts{}.filename("/nonexistent/path/barcode.ps"));
	} catch (const std::runtime_error &) {
		threw = true;
	}
	TEST_CHECK(threw);
}


/* ========================================================================
 *  Move semantics
 * ======================================================================== */

static void test_move_constructor(void) {
	write_mock_ps(MOCK_PS, mock_ps);
	bwipp::BWIPP a(bwipp::InitOpts{}.filename(MOCK_PS));
	bwipp::BWIPP b(std::move(a));
	TEST_CHECK(b.get_version() == "2099-01-01");
	std::remove(MOCK_PS);
}

static void test_move_assignment(void) {
	write_mock_ps(MOCK_PS, mock_ps);
	bwipp::BWIPP a(bwipp::InitOpts{}.filename(MOCK_PS));
	bwipp::BWIPP b(bwipp::InitOpts{}.filename(MOCK_PS));
	b = std::move(a);
	TEST_CHECK(b.get_version() == "2099-01-01");
	std::remove(MOCK_PS);
}


/* ========================================================================
 *  Version
 * ======================================================================== */

static void test_get_version(void) {
	write_mock_ps(MOCK_PS, mock_ps);
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(MOCK_PS));
	TEST_CHECK(ctx.get_version() == "2099-01-01");
	std::remove(MOCK_PS);
}


/* ========================================================================
 *  Encoder listing
 * ======================================================================== */

static void test_list_encoders(void) {
	write_mock_ps(MOCK_PS, mock_ps);
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(MOCK_PS));
	auto encoders = ctx.list_encoders();
	TEST_CHECK(encoders.size() == 1);
	TEST_CHECK(encoders[0] == "encoder");
	std::remove(MOCK_PS);
}

static void test_list_encoders_sorted(void) {
	write_mock_ps(MOCK_PS, mock_ps_two_families);
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(MOCK_PS));
	auto encoders = ctx.list_encoders();
	TEST_CHECK(encoders.size() == 3);
	TEST_CHECK(encoders[0] == "enc_a");
	TEST_CHECK(encoders[1] == "enc_b");
	TEST_CHECK(encoders[2] == "enc_c");
	std::remove(MOCK_PS);
}


/* ========================================================================
 *  Properties
 * ======================================================================== */

static void test_list_properties(void) {
	write_mock_ps(MOCK_PS, mock_ps);
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(MOCK_PS));
	auto props = ctx.list_properties("encoder");
	TEST_CHECK(props.size() >= 1);
	TEST_CHECK(props[0] == "TYPE");
	std::remove(MOCK_PS);
}

static void test_list_properties_not_found(void) {
	write_mock_ps(MOCK_PS, mock_ps);
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(MOCK_PS));
	auto props = ctx.list_properties("nonexistent");
	TEST_CHECK(props.empty());
	std::remove(MOCK_PS);
}

static void test_get_property(void) {
	write_mock_ps(MOCK_PS, mock_ps);
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(MOCK_PS));
	TEST_CHECK(ctx.get_property("encoder", "TYPE") == "ENCODER");
	TEST_CHECK(ctx.get_property("encoder", "DESC") == "Test Encoder");
	TEST_CHECK(ctx.get_property("encoder", "EXAM") == "TEST123");
	TEST_CHECK(ctx.get_property("encoder", "EXOP") == "includetext");
	TEST_CHECK(ctx.get_property("encoder", "RNDR") == "renlinear");
	TEST_CHECK(ctx.get_property("encoder", "FMLY") == "Test Family");
	std::remove(MOCK_PS);
}

static void test_get_property_not_found(void) {
	write_mock_ps(MOCK_PS, mock_ps);
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(MOCK_PS));
	TEST_CHECK(ctx.get_property("encoder", "NOSUCH").empty());
	TEST_CHECK(ctx.get_property("nonexistent", "TYPE").empty());
	std::remove(MOCK_PS);
}

static void test_get_properties_map(void) {
	write_mock_ps(MOCK_PS, mock_ps);
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(MOCK_PS));
	auto props = ctx.get_properties("encoder");
	TEST_CHECK(props.count("TYPE") == 1);
	TEST_CHECK(props["TYPE"] == "ENCODER");
	TEST_CHECK(props["DESC"] == "Test Encoder");
	std::remove(MOCK_PS);
}

static void test_get_properties_not_found(void) {
	write_mock_ps(MOCK_PS, mock_ps);
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(MOCK_PS));
	auto props = ctx.get_properties("nonexistent");
	TEST_CHECK(props.empty());
	std::remove(MOCK_PS);
}


/* ========================================================================
 *  Families
 * ======================================================================== */

static void test_list_families(void) {
	write_mock_ps(MOCK_PS, mock_ps_two_families);
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(MOCK_PS));
	auto families = ctx.list_families();
	TEST_CHECK(families.size() == 2);
	TEST_CHECK(families[0] == "Alpha");
	TEST_CHECK(families[1] == "Beta");
	std::remove(MOCK_PS);
}

static void test_list_family_members(void) {
	write_mock_ps(MOCK_PS, mock_ps_two_families);
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(MOCK_PS));
	auto members = ctx.list_family_members("Alpha");
	TEST_CHECK(members.size() == 2);
	auto beta = ctx.list_family_members("Beta");
	TEST_CHECK(beta.size() == 1);
	TEST_CHECK(beta[0] == "enc_b");
	std::remove(MOCK_PS);
}

static void test_list_family_members_not_found(void) {
	write_mock_ps(MOCK_PS, mock_ps);
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(MOCK_PS));
	auto members = ctx.list_family_members("NoSuchFamily");
	TEST_CHECK(members.empty());
	std::remove(MOCK_PS);
}


/* ========================================================================
 *  Emit functions
 * ======================================================================== */

static void test_emit_required_resources(void) {
	write_mock_ps(MOCK_PS, mock_ps);
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(MOCK_PS));
	std::string code = ctx.emit_required_resources("encoder");
	TEST_CHECK(code.find("% base code") != std::string::npos);
	TEST_CHECK(code.find("% helper code") != std::string::npos);
	TEST_CHECK(code.find("% encoder code") != std::string::npos);
	std::remove(MOCK_PS);
}

static void test_emit_required_resources_not_found(void) {
	write_mock_ps(MOCK_PS, mock_ps);
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(MOCK_PS));
	std::string code = ctx.emit_required_resources("nonexistent");
	TEST_CHECK(code.empty());
	std::remove(MOCK_PS);
}

static void test_emit_all_resources(void) {
	write_mock_ps(MOCK_PS, mock_ps);
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(MOCK_PS));
	std::string code = ctx.emit_all_resources();
	TEST_CHECK(code.find("% base code") != std::string::npos);
	TEST_CHECK(code.find("% helper code") != std::string::npos);
	TEST_CHECK(code.find("% encoder code") != std::string::npos);
	std::remove(MOCK_PS);
}

static void test_emit_exec(void) {
	write_mock_ps(MOCK_PS, mock_ps);
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(MOCK_PS));
	std::string code = ctx.emit_exec("encoder", "DATA", "opt=val");
	TEST_CHECK(!code.empty());
	TEST_CHECK(code.find("findresource") != std::string::npos);
	std::remove(MOCK_PS);
}

static void test_emit_template(void) {
	write_mock_ps(MOCK_PS, mock_ps);
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(MOCK_PS));
	std::string code = ctx.emit_template(
		"%dat %opt %enc /uk.co.terryburton.bwipp findresource exec",
		"encoder", "DATA", "opt=val");
	TEST_CHECK(!code.empty());
	TEST_CHECK(code.find("findresource") != std::string::npos);
	TEST_CHECK(code.find("cvn") != std::string::npos);
	std::remove(MOCK_PS);
}

static void test_emit_pshexstr(void) {
	write_mock_ps(MOCK_PS, mock_ps);
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(MOCK_PS));
	std::string hex = ctx.emit_pshexstr("Hello");
	TEST_CHECK(hex == "<48656C6C6F>");
	std::remove(MOCK_PS);
}


/* ========================================================================
 *  Integration tests with real barcode.ps
 * ======================================================================== */

static void test_real_list_encoders(void) {
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(BARCODE_PS));
	auto encoders = ctx.list_encoders();
	TEST_CHECK(encoders.size() > 100);
}

static void test_real_qrcode_properties(void) {
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(BARCODE_PS));
	TEST_CHECK(ctx.get_property("qrcode", "TYPE") == "ENCODER");
	TEST_CHECK(!ctx.get_property("qrcode", "DESC").empty());
	TEST_CHECK(!ctx.get_property("qrcode", "EXAM").empty());
}

static void test_real_emit_qrcode(void) {
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(BARCODE_PS));
	std::string res = ctx.emit_required_resources("qrcode");
	std::string exec = ctx.emit_exec("qrcode", "Hello World", "eclevel=M");
	TEST_CHECK(!res.empty());
	TEST_CHECK(!exec.empty());
}

static void test_real_families(void) {
	bwipp::BWIPP ctx(bwipp::InitOpts{}.filename(BARCODE_PS));
	auto families = ctx.list_families();
	TEST_CHECK(families.size() > 5);
	for (const auto &fam : families) {
		auto members = ctx.list_family_members(fam);
		TEST_CHECK(!members.empty());
	}
}


/* ========================================================================
 *  Test list
 * ======================================================================== */

TEST_LIST = {
	/* Construction and RAII */
	{ "load_with_init_opts",           test_load_with_init_opts },
	{ "load_with_lazy",                test_load_with_lazy },
	{ "load_failure_throws",           test_load_failure_throws },

	/* Move semantics */
	{ "move_constructor",              test_move_constructor },
	{ "move_assignment",               test_move_assignment },

	/* Version */
	{ "get_version",                   test_get_version },

	/* Encoders */
	{ "list_encoders",                 test_list_encoders },
	{ "list_encoders_sorted",          test_list_encoders_sorted },

	/* Properties */
	{ "list_properties",               test_list_properties },
	{ "list_properties_not_found",     test_list_properties_not_found },
	{ "get_property",                  test_get_property },
	{ "get_property_not_found",        test_get_property_not_found },
	{ "get_properties_map",            test_get_properties_map },
	{ "get_properties_not_found",      test_get_properties_not_found },

	/* Families */
	{ "list_families",                 test_list_families },
	{ "list_family_members",           test_list_family_members },
	{ "list_family_members_not_found", test_list_family_members_not_found },

	/* Emit */
	{ "emit_required_resources",       test_emit_required_resources },
	{ "emit_required_resources_not_found", test_emit_required_resources_not_found },
	{ "emit_all_resources",            test_emit_all_resources },
	{ "emit_exec",                     test_emit_exec },
	{ "emit_template",                 test_emit_template },
	{ "emit_pshexstr",                 test_emit_pshexstr },

	/* Integration with real barcode.ps */
	{ "real_list_encoders",            test_real_list_encoders },
	{ "real_qrcode_properties",        test_real_qrcode_properties },
	{ "real_emit_qrcode",              test_real_emit_qrcode },
	{ "real_families",                 test_real_families },

	{ NULL, NULL }
};
