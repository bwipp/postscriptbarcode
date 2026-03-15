/*
 * libpostscriptbarcode
 *
 * @file postscriptbarcode_test.c
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*
 *  Don't flag warnings in third-party test harness code.
 */
#if defined(__clang__)
#elif defined(__GNUC__)
#  pragma GCC diagnostic push
#  pragma GCC diagnostic ignored "-Wsign-conversion"
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
#include "postscriptbarcode.h"

#define MOCK_PS "test_barcode.ps"
#define BARCODE_PS "../../build/monolithic/barcode.ps"

static BWIPP *load_from(const char *filename) {
	bwipp_load_init_opts_t opts = {
		.struct_size = sizeof(opts),
		.filename = filename,
	};
	return bwipp_load_ex(&opts);
}


static void write_mock_ps(const char *filename, const char *content) {
	FILE *f = fopen(filename, "w");
	if (!f) {
		perror(filename);
		abort();
	}
	fputs(content, f);
	fclose(f);
}

static void write_mock_ps_bin(const char *filename, const char *content, size_t len) {
	FILE *f = fopen(filename, "wb");
	if (!f) {
		perror(filename);
		abort();
	}
	fwrite(content, 1, len, f);
	fclose(f);
}

/*
 *  Standard mock with three resources:
 *    - "base"     (RESOURCE, no requirements, code: "% base code\n")
 *    - "helper"   (RESOURCE, requires base, code: "% helper code\n")
 *    - "encoder"  (ENCODER, requires base helper, code: "% encoder code\n")
 */
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
	"% encoder code\n"
	"% --END ENCODER encoder--\n"
	"% --END TEMPLATE--\n";


/* ========================================================================
 *  bwipp_load_ex - success paths
 * ======================================================================== */

static void test_load_mock(void) {
	BWIPP *ctx;

	write_mock_ps(MOCK_PS, mock_ps);

	TEST_CHECK((ctx = load_from(MOCK_PS)) != NULL);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_load_empty_file(void) {
	BWIPP *ctx;

	write_mock_ps(MOCK_PS, "");

	/* Empty file: valid context but no version or resources */
	TEST_CHECK((ctx = load_from(MOCK_PS)) != NULL);
	if (ctx) {
		TEST_CHECK(bwipp_get_version(ctx) == NULL);
		bwipp_unload(ctx);
	}

	remove(MOCK_PS);
}

static void test_load_no_template(void) {
	BWIPP *ctx;

	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
	);

	ctx = load_from(MOCK_PS);

	if (ctx)
		bwipp_unload(ctx);

	remove(MOCK_PS);
}

static void test_load_single_resource(void) {
	BWIPP *ctx;
	char *out;

	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE only--\n"
		"% only code\n"
		"% --END RESOURCE only--\n"
		"% --END TEMPLATE--\n"
	);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	TEST_CHECK((out = bwipp_emit_required_resources(ctx, "only")) != NULL);
	TEST_CHECK(strcmp(out, "% only code\n") == 0);
	bwipp_free(out);

	/* emit_all should return same as the single resource */
	TEST_CHECK((out = bwipp_emit_all_resources(ctx)) != NULL);
	TEST_CHECK(strcmp(out, "% only code\n") == 0);
	bwipp_free(out);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_load_many_resources_order(void) {
	BWIPP *ctx;
	char *out;

	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE aaa--\n"
		"A\n"
		"% --END RESOURCE aaa--\n"
		"% --BEGIN RESOURCE bbb--\n"
		"B\n"
		"% --END RESOURCE bbb--\n"
		"% --BEGIN RESOURCE ccc--\n"
		"C\n"
		"% --END RESOURCE ccc--\n"
		"% --BEGIN RESOURCE ddd--\n"
		"D\n"
		"% --END RESOURCE ddd--\n"
		"% --BEGIN RESOURCE eee--\n"
		"E\n"
		"% --END RESOURCE eee--\n"
		"% --END TEMPLATE--\n"
	);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* emit_all must preserve parse order */
	TEST_CHECK((out = bwipp_emit_all_resources(ctx)) != NULL);
	TEST_CHECK(strcmp(out, "A\nB\nC\nD\nE\n") == 0);
	TEST_MSG("Got: [%s]", out);
	bwipp_free(out);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_load_content_before_template(void) {
	BWIPP *ctx;

	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% Lots of header content\n"
		"% More comments\n"
		"% Even more\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE foo--\n"
		"% code\n"
		"% --END RESOURCE foo--\n"
		"% --END TEMPLATE--\n"
	);

	TEST_CHECK((ctx = load_from(MOCK_PS)) != NULL);
	if (ctx)
		bwipp_unload(ctx);

	remove(MOCK_PS);
}

static void test_load_content_after_template(void) {
	BWIPP *ctx;
	char *out;

	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE foo--\n"
		"% foo code\n"
		"% --END RESOURCE foo--\n"
		"% --END TEMPLATE--\n"
		"% This content after END TEMPLATE should be ignored\n"
		"% --BEGIN RESOURCE bar--\n"
		"% bar code\n"
		"% --END RESOURCE bar--\n"
	);

	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* Only foo should be loaded; bar is after END TEMPLATE */
	TEST_CHECK((out = bwipp_emit_required_resources(ctx, "foo")) != NULL);
	TEST_CHECK(strcmp(out, "% foo code\n") == 0);
	bwipp_free(out);

	TEST_CHECK((out = bwipp_emit_required_resources(ctx, "bar")) != NULL);
	TEST_CHECK(strcmp(out, "") == 0);
	bwipp_free(out);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}


/* ========================================================================
 *  bwipp_load_ex - error paths
 * ======================================================================== */

static void test_load_missing_file(void) {
	TEST_CHECK(load_from("nonexistent.ps") == NULL);
}

static void test_load_default_path(void) {
	BWIPP *ctx = bwipp_load();
	if (ctx)
		bwipp_unload(ctx);
}

static void test_load_nested_begin(void) {
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE foo--\n"
		"% --BEGIN RESOURCE bar--\n"
		"% --END RESOURCE bar--\n"
		"% --END RESOURCE foo--\n"
		"% --END TEMPLATE--\n"
	);

	TEST_CHECK(load_from(MOCK_PS) == NULL);

	remove(MOCK_PS);
}

static void test_load_mismatched_end_name(void) {
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE foo--\n"
		"% code\n"
		"% --END RESOURCE bar--\n"
		"% --END TEMPLATE--\n"
	);

	TEST_CHECK(load_from(MOCK_PS) == NULL);

	remove(MOCK_PS);
}

static void test_load_mismatched_end_type(void) {
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE foo--\n"
		"% code\n"
		"% --END ENCODER foo--\n"
		"% --END TEMPLATE--\n"
	);

	TEST_CHECK(load_from(MOCK_PS) == NULL);

	remove(MOCK_PS);
}

static void test_load_unterminated_resource(void) {
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE foo--\n"
		"% code\n"
		"% --END TEMPLATE--\n"
	);

	TEST_CHECK(load_from(MOCK_PS) == NULL);

	remove(MOCK_PS);
}

static void test_load_unterminated_at_eof(void) {
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE foo--\n"
		"% code\n"
	);

	/* File ends without END RESOURCE or END TEMPLATE */
	TEST_CHECK(load_from(MOCK_PS) == NULL);

	remove(MOCK_PS);
}

static void test_load_end_without_begin(void) {
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --END RESOURCE foo--\n"
		"% --END TEMPLATE--\n"
	);

	TEST_CHECK(load_from(MOCK_PS) == NULL);

	remove(MOCK_PS);
}

static void test_load_duplicate_requires(void) {
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE foo--\n"
		"% --REQUIRES bar--\n"
		"% --REQUIRES baz--\n"
		"% --END RESOURCE foo--\n"
		"% --END TEMPLATE--\n"
	);

	TEST_CHECK(load_from(MOCK_PS) == NULL);

	remove(MOCK_PS);
}

static void test_load_requires_outside_resource(void) {
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --REQUIRES bar--\n"
		"% --END TEMPLATE--\n"
	);

	TEST_CHECK(load_from(MOCK_PS) == NULL);

	remove(MOCK_PS);
}

static void test_load_malformed_begin_no_name(void) {
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE--\n"
		"% --END TEMPLATE--\n"
	);

	TEST_CHECK(load_from(MOCK_PS) == NULL);

	remove(MOCK_PS);
}

static void test_load_malformed_begin_no_type_space(void) {
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN foo--\n"  /* No TYPE SPACE NAME, just one word */
		"% --END TEMPLATE--\n"
	);

	TEST_CHECK(load_from(MOCK_PS) == NULL);

	remove(MOCK_PS);
}

static void test_load_malformed_end_no_space(void) {
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE foo--\n"
		"% code\n"
		"% --END RESOURCE_foo--\n"  /* No space between type and name */
		"% --END TEMPLATE--\n"
	);

	TEST_CHECK(load_from(MOCK_PS) == NULL);

	remove(MOCK_PS);
}

static void test_load_malformed_requires_no_suffix(void) {
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE foo--\n"
		"% --REQUIRES bar\n"  /* Missing trailing -- */
		"% --END RESOURCE foo--\n"
		"% --END TEMPLATE--\n"
	);

	TEST_CHECK(load_from(MOCK_PS) == NULL);

	remove(MOCK_PS);
}

static void test_load_malformed_begin_no_suffix(void) {
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE foo\n"  /* Missing trailing -- */
		"% --END TEMPLATE--\n"
	);

	TEST_CHECK(load_from(MOCK_PS) == NULL);

	remove(MOCK_PS);
}

static void test_load_malformed_end_no_suffix(void) {
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE foo--\n"
		"% code\n"
		"% --END RESOURCE foo\n"  /* Missing trailing -- */
		"% --END TEMPLATE--\n"
	);

	TEST_CHECK(load_from(MOCK_PS) == NULL);

	remove(MOCK_PS);
}

/*
 *  Marker line truncation: a marker line that doesn't end with \n
 *  due to being longer than MAX_LINE should be rejected.
 *  We simulate this with a truncated file where the last line is a
 *  marker without a newline.
 */
static void test_load_truncated_marker_begin(void) {
	/* BEGIN marker as the final line with no trailing newline */
	const char content[] =
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE foo--";  /* No \n, then EOF */

	write_mock_ps_bin(MOCK_PS, content, sizeof(content) - 1);

	TEST_CHECK(load_from(MOCK_PS) == NULL);

	remove(MOCK_PS);
}

static void test_load_truncated_marker_end(void) {
	const char content[] =
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE foo--\n"
		"% code\n"
		"% --END RESOURCE foo--";  /* No \n, then EOF */

	write_mock_ps_bin(MOCK_PS, content, sizeof(content) - 1);

	TEST_CHECK(load_from(MOCK_PS) == NULL);

	remove(MOCK_PS);
}

static void test_load_truncated_marker_requires(void) {
	const char content[] =
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE foo--\n"
		"% --REQUIRES bar--";  /* No \n, then EOF */

	write_mock_ps_bin(MOCK_PS, content, sizeof(content) - 1);

	TEST_CHECK(load_from(MOCK_PS) == NULL);

	remove(MOCK_PS);
}

static void test_load_truncated_marker_template(void) {
	const char content[] =
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--";  /* No \n, then EOF */

	write_mock_ps_bin(MOCK_PS, content, sizeof(content) - 1);

	/* BEGIN TEMPLATE itself is truncated; parser should reject */
	TEST_CHECK(load_from(MOCK_PS) == NULL);

	remove(MOCK_PS);
}

/*
 *  Long line: a marker line padded to be very long but still valid
 *  (under MAX_LINE with proper \n termination)
 */
static void test_load_long_requires_line(void) {
	BWIPP *ctx;
	FILE *f;

	f = fopen(MOCK_PS, "w");
	if (!f) abort();
	fputs("%!PS\n", f);
	fputs("% Barcode Writer in Pure PostScript - Version 2099-01-01\n", f);
	fputs("% --BEGIN TEMPLATE--\n", f);
	fputs("% --BEGIN RESOURCE base--\n", f);
	fputs("% base code\n", f);
	fputs("% --END RESOURCE base--\n", f);
	fputs("% --BEGIN RESOURCE foo--\n", f);
	/* REQUIRES line with many deps, all the same valid dep "base" */
	fputs("% --REQUIRES base base base base base base base base base base base base base base base base base base base base--\n", f);
	fputs("% foo code\n", f);
	fputs("% --END RESOURCE foo--\n", f);
	fputs("% --END TEMPLATE--\n", f);
	fclose(f);

	TEST_CHECK((ctx = load_from(MOCK_PS)) != NULL);
	if (ctx)
		bwipp_unload(ctx);

	remove(MOCK_PS);
}


/* ========================================================================
 *  bwipp_get_version
 * ======================================================================== */

static void test_get_version(void) {
	BWIPP *ctx;
	const char *version;

	write_mock_ps(MOCK_PS, mock_ps);

	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);
	TEST_CHECK((version = bwipp_get_version(ctx)) != NULL);
	TEST_CHECK(strcmp(version, "2099-01-01") == 0);
	TEST_MSG("Got: %s", version);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_get_version_no_version_line(void) {
	BWIPP *ctx;

	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE foo--\n"
		"% code\n"
		"% --END RESOURCE foo--\n"
		"% --END TEMPLATE--\n"
	);

	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);
	TEST_CHECK(bwipp_get_version(ctx) == NULL);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_get_version_only_first(void) {
	BWIPP *ctx;
	const char *version;

	/* Two version-like lines; should use the first */
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% Barcode Writer in Pure PostScript - Version 2099-12-31\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE foo--\n"
		"% code\n"
		"% --END RESOURCE foo--\n"
		"% --END TEMPLATE--\n"
	);

	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);
	TEST_CHECK((version = bwipp_get_version(ctx)) != NULL);
	TEST_CHECK(strcmp(version, "2099-01-01") == 0);
	TEST_MSG("Got: %s", version);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_get_version_after_template(void) {
	BWIPP *ctx;

	/* Version line after BEGIN TEMPLATE — should not be found
	 * because skip is now false */
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% --BEGIN TEMPLATE--\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN RESOURCE foo--\n"
		"% code\n"
		"% --END RESOURCE foo--\n"
		"% --END TEMPLATE--\n"
	);

	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);
	TEST_CHECK(bwipp_get_version(ctx) == NULL);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}


/* ========================================================================
 *  bwipp_list_encoders
 * ======================================================================== */

/*
 *  Mock with metadata comments:
 *    - "preamble"  (RESOURCE, no props)
 *    - "helper"    (RESOURCE, REQUIRES preamble, no props)
 *    - "enc1"      (ENCODER, REQUIRES preamble helper, has DESC/EXAM/EXOP/RNDR)
 *    - "enc2"      (ENCODER, REQUIRES preamble, has DESC/EXAM/RNDR)
 */
static const char mock_ps_meta[] =
	"%!PS\n"
	"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
	"% --BEGIN TEMPLATE--\n"
	"% --BEGIN RESOURCE preamble--\n"
	"% preamble code\n"
	"% --END RESOURCE preamble--\n"
	"% --BEGIN RESOURCE helper--\n"
	"% --REQUIRES preamble--\n"
	"% helper code\n"
	"% --END RESOURCE helper--\n"
	"% --BEGIN ENCODER enc1--\n"
	"% --DESC: Encoder One Description\n"
	"% --EXAM: 12345\n"
	"% --EXOP: includetext\n"
	"% --RNDR: renlinear\n"
	"% --REQUIRES preamble helper--\n"
	"% enc1 code\n"
	"% --END ENCODER enc1--\n"
	"% --BEGIN ENCODER enc2--\n"
	"% --DESC: Encoder Two Description\n"
	"% --EXAM: ABCDE\n"
	"% --RNDR: renmatrix\n"
	"% --REQUIRES preamble--\n"
	"% enc2 code\n"
	"% --END ENCODER enc2--\n"
	"% --END TEMPLATE--\n";

static void test_list_encoders_basic(void) {
	BWIPP *ctx;
	const char **list;
	unsigned int count;

	write_mock_ps(MOCK_PS, mock_ps_meta);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	list = bwipp_list_encoders(ctx, &count);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(count == 2);
	TEST_CHECK(strcmp(list[0], "enc1") == 0);
	TEST_CHECK(strcmp(list[1], "enc2") == 0);
	TEST_CHECK(list[2] == NULL);
	bwipp_free((void *)list);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_list_encoders_no_encoders(void) {
	BWIPP *ctx;
	const char **list;
	unsigned int count;

	/* Only RESOURCE types, no ENCODER */
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE foo--\n"
		"% code\n"
		"% --END RESOURCE foo--\n"
		"% --END TEMPLATE--\n"
	);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	list = bwipp_list_encoders(ctx, &count);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(count == 0);
	TEST_CHECK(list[0] == NULL);
	bwipp_free((void *)list);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_list_encoders_null_count(void) {
	BWIPP *ctx;
	const char **list;

	write_mock_ps(MOCK_PS, mock_ps_meta);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* NULL count pointer should not crash */
	list = bwipp_list_encoders(ctx, NULL);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(strcmp(list[0], "enc1") == 0);
	TEST_CHECK(strcmp(list[1], "enc2") == 0);
	TEST_CHECK(list[2] == NULL);
	bwipp_free((void *)list);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_list_encoders_sorted(void) {
	BWIPP *ctx;
	const char **list;
	unsigned int count;

	/* Encoders should be returned in sorted order regardless of file order */
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN ENCODER zzz--\n"
		"% code\n"
		"% --END ENCODER zzz--\n"
		"% --BEGIN RESOURCE utility--\n"
		"% code\n"
		"% --END RESOURCE utility--\n"
		"% --BEGIN ENCODER aaa--\n"
		"% code\n"
		"% --END ENCODER aaa--\n"
		"% --BEGIN ENCODER mmm--\n"
		"% code\n"
		"% --END ENCODER mmm--\n"
		"% --END TEMPLATE--\n"
	);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	list = bwipp_list_encoders(ctx, &count);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(count == 3);
	TEST_CHECK(strcmp(list[0], "aaa") == 0);
	TEST_CHECK(strcmp(list[1], "mmm") == 0);
	TEST_CHECK(strcmp(list[2], "zzz") == 0);
	TEST_CHECK(list[3] == NULL);
	bwipp_free((void *)list);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_list_encoders_strings_owned_by_context(void) {
	BWIPP *ctx;
	const char **list;
	unsigned int count;
	const char *first_name;

	write_mock_ps(MOCK_PS, mock_ps_meta);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	list = bwipp_list_encoders(ctx, &count);
	TEST_ASSERT(list != NULL);
	TEST_ASSERT(count >= 1);

	/* Save pointer, free array, then check string still valid via context */
	first_name = list[0];
	bwipp_free((void *)list);

	/* The string should still be accessible via the context */
	TEST_CHECK(strcmp(first_name, "enc1") == 0);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}


/* ========================================================================
 *  bwipp_list_properties
 * ======================================================================== */

static void test_list_properties_basic(void) {
	BWIPP *ctx;
	const char **list;
	unsigned int count;

	write_mock_ps(MOCK_PS, mock_ps_meta);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* enc1 has DESC, EXAM, EXOP, RNDR */
	list = bwipp_list_properties(ctx, "enc1", &count);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(count == 4);
	TEST_CHECK(strcmp(list[0], "DESC") == 0);
	TEST_CHECK(strcmp(list[1], "EXAM") == 0);
	TEST_CHECK(strcmp(list[2], "EXOP") == 0);
	TEST_CHECK(strcmp(list[3], "RNDR") == 0);
	TEST_CHECK(list[4] == NULL);
	bwipp_free((void *)list);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_list_properties_fewer_keys(void) {
	BWIPP *ctx;
	const char **list;
	unsigned int count;

	write_mock_ps(MOCK_PS, mock_ps_meta);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* enc2 has DESC, EXAM, RNDR (no EXOP) */
	list = bwipp_list_properties(ctx, "enc2", &count);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(count == 3);
	TEST_CHECK(strcmp(list[0], "DESC") == 0);
	TEST_CHECK(strcmp(list[1], "EXAM") == 0);
	TEST_CHECK(strcmp(list[2], "RNDR") == 0);
	TEST_CHECK(list[3] == NULL);
	bwipp_free((void *)list);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_list_properties_no_properties(void) {
	BWIPP *ctx;
	const char **list;
	unsigned int count;

	write_mock_ps(MOCK_PS, mock_ps_meta);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* preamble has no metadata comments */
	list = bwipp_list_properties(ctx, "preamble", &count);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(count == 0);
	TEST_CHECK(list[0] == NULL);
	bwipp_free((void *)list);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_list_properties_unknown_resource(void) {
	BWIPP *ctx;

	write_mock_ps(MOCK_PS, mock_ps_meta);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* Unknown resource returns NULL */
	TEST_CHECK(bwipp_list_properties(ctx, "nonexistent", NULL) == NULL);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_list_properties_null_count(void) {
	BWIPP *ctx;
	const char **list;

	write_mock_ps(MOCK_PS, mock_ps_meta);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* NULL count pointer should not crash */
	list = bwipp_list_properties(ctx, "enc1", NULL);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(strcmp(list[0], "DESC") == 0);
	bwipp_free((void *)list);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_list_properties_preserves_order(void) {
	BWIPP *ctx;
	const char **list;
	unsigned int count;

	/* Properties should be in file order */
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN ENCODER test--\n"
		"% --RNDR: renlinear\n"
		"% --DESC: Test Description\n"
		"% --EXAM: 123\n"
		"% --REQUIRES preamble--\n"
		"% code\n"
		"% --END ENCODER test--\n"
		"% --END TEMPLATE--\n"
	);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	list = bwipp_list_properties(ctx, "test", &count);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(count == 3);
	/* Order should match file order: RNDR, DESC, EXAM */
	TEST_CHECK(strcmp(list[0], "RNDR") == 0);
	TEST_CHECK(strcmp(list[1], "DESC") == 0);
	TEST_CHECK(strcmp(list[2], "EXAM") == 0);
	bwipp_free((void *)list);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}


/* ========================================================================
 *  bwipp_get_property
 * ======================================================================== */

static void test_get_property_basic(void) {
	BWIPP *ctx;

	write_mock_ps(MOCK_PS, mock_ps_meta);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	TEST_CHECK(strcmp(bwipp_get_property(ctx, "enc1", "DESC"),
			  "Encoder One Description") == 0);
	TEST_CHECK(strcmp(bwipp_get_property(ctx, "enc1", "EXAM"),
			  "12345") == 0);
	TEST_CHECK(strcmp(bwipp_get_property(ctx, "enc1", "EXOP"),
			  "includetext") == 0);
	TEST_CHECK(strcmp(bwipp_get_property(ctx, "enc1", "RNDR"),
			  "renlinear") == 0);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_get_property_different_encoder(void) {
	BWIPP *ctx;

	write_mock_ps(MOCK_PS, mock_ps_meta);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	TEST_CHECK(strcmp(bwipp_get_property(ctx, "enc2", "DESC"),
			  "Encoder Two Description") == 0);
	TEST_CHECK(strcmp(bwipp_get_property(ctx, "enc2", "RNDR"),
			  "renmatrix") == 0);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_get_property_missing_key(void) {
	BWIPP *ctx;

	write_mock_ps(MOCK_PS, mock_ps_meta);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* enc2 has no EXOP */
	TEST_CHECK(bwipp_get_property(ctx, "enc2", "EXOP") == NULL);

	/* Completely unknown key */
	TEST_CHECK(bwipp_get_property(ctx, "enc1", "NONEXISTENT") == NULL);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_get_property_missing_resource(void) {
	BWIPP *ctx;

	write_mock_ps(MOCK_PS, mock_ps_meta);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	TEST_CHECK(bwipp_get_property(ctx, "nonexistent", "DESC") == NULL);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_get_property_no_properties(void) {
	BWIPP *ctx;

	write_mock_ps(MOCK_PS, mock_ps_meta);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* preamble has no properties */
	TEST_CHECK(bwipp_get_property(ctx, "preamble", "DESC") == NULL);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_get_property_value_with_spaces(void) {
	BWIPP *ctx;

	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN ENCODER test--\n"
		"% --DESC: A Long Description With Many Words\n"
		"% code\n"
		"% --END ENCODER test--\n"
		"% --END TEMPLATE--\n"
	);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	TEST_CHECK(strcmp(bwipp_get_property(ctx, "test", "DESC"),
			  "A Long Description With Many Words") == 0);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_get_property_value_with_colon(void) {
	BWIPP *ctx;

	/* Value containing a colon (key is up to first colon) */
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN ENCODER test--\n"
		"% --DESC: Contains: A Colon\n"
		"% code\n"
		"% --END ENCODER test--\n"
		"% --END TEMPLATE--\n"
	);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* Key is "DESC", value is everything after "DESC: " */
	TEST_CHECK(strcmp(bwipp_get_property(ctx, "test", "DESC"),
			  "Contains: A Colon") == 0);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_get_property_owned_by_context(void) {
	BWIPP *ctx;
	const char *val;

	write_mock_ps(MOCK_PS, mock_ps_meta);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* Returned string should be valid until unload */
	val = bwipp_get_property(ctx, "enc1", "DESC");
	TEST_ASSERT(val != NULL);
	TEST_CHECK(strcmp(val, "Encoder One Description") == 0);

	/* Call other functions — val should still be valid */
	{
		char *out = bwipp_emit_required_resources(ctx, "enc1");
		bwipp_free(out);
	}
	TEST_CHECK(strcmp(val, "Encoder One Description") == 0);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}


/* ========================================================================
 *  Metadata parsing edge cases
 * ======================================================================== */

static void test_metadata_not_parsed_outside_resource(void) {
	BWIPP *ctx;

	/* Metadata-like comments outside a resource should be ignored */
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --DESC: Should Be Ignored\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE foo--\n"
		"% code\n"
		"% --END RESOURCE foo--\n"
		"% --END TEMPLATE--\n"
	);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	TEST_CHECK(bwipp_get_property(ctx, "foo", "DESC") == NULL);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_metadata_after_requires(void) {
	BWIPP *ctx;
	const char **list;
	unsigned int count;

	/* In real barcode.ps, REQUIRES comes before metadata comments.
	 * Both should be parsed as properties. */
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN ENCODER test--\n"
		"% --REQUIRES preamble--\n"
		"% --DESC: Real Property\n"
		"% --EXAM: Example Data\n"
		"% code\n"
		"% --END ENCODER test--\n"
		"% --END TEMPLATE--\n"
	);

	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* Both DESC and EXAM should be properties */
	list = bwipp_list_properties(ctx, "test", &count);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(count == 2);
	TEST_CHECK(strcmp(list[0], "DESC") == 0);
	TEST_CHECK(strcmp(list[1], "EXAM") == 0);
	bwipp_free((void *)list);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_metadata_fmly_property(void) {
	BWIPP *ctx;

	/* FMLY metadata for family grouping */
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN ENCODER test--\n"
		"% --DESC: Test Encoder\n"
		"% --FMLY: Code 128\n"
		"% code\n"
		"% --END ENCODER test--\n"
		"% --END TEMPLATE--\n"
	);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	TEST_CHECK(strcmp(bwipp_get_property(ctx, "test", "FMLY"),
			  "Code 128") == 0);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}


/* ========================================================================
 *  Integration tests for new API (real barcode.ps)
 * ======================================================================== */

static void test_real_list_encoders(void) {
	BWIPP *ctx;
	const char **list;
	unsigned int count;

	ctx = load_from(BARCODE_PS);
	if (!ctx) {
		TEST_MSG("Skipped: %s not found", BARCODE_PS);
		return;
	}

	list = bwipp_list_encoders(ctx, &count);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(count > 100);
	TEST_MSG("Found %u encoders", count);

	/* Spot check well-known encoders */
	{
		unsigned int i;
		int found_qrcode = 0, found_ean13 = 0, found_code128 = 0;
		for (i = 0; i < count; i++) {
			if (strcmp(list[i], "qrcode") == 0) found_qrcode = 1;
			if (strcmp(list[i], "ean13") == 0) found_ean13 = 1;
			if (strcmp(list[i], "code128") == 0) found_code128 = 1;
		}
		TEST_CHECK(found_qrcode);
		TEST_CHECK(found_ean13);
		TEST_CHECK(found_code128);
	}

	bwipp_free((void *)list);
	bwipp_unload(ctx);
}

static void test_real_list_properties(void) {
	BWIPP *ctx;
	const char **list;
	unsigned int count;

	ctx = load_from(BARCODE_PS);
	if (!ctx) {
		TEST_MSG("Skipped: %s not found", BARCODE_PS);
		return;
	}

	list = bwipp_list_properties(ctx, "qrcode", &count);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(count >= 3);
	TEST_MSG("qrcode has %u properties", count);
	bwipp_free((void *)list);

	bwipp_unload(ctx);
}

static void test_real_get_property(void) {
	BWIPP *ctx;
	const char *val;

	ctx = load_from(BARCODE_PS);
	if (!ctx) {
		TEST_MSG("Skipped: %s not found", BARCODE_PS);
		return;
	}

	val = bwipp_get_property(ctx, "qrcode", "RNDR");
	TEST_CHECK(val != NULL);
	if (val) {
		TEST_CHECK(strcmp(val, "renmatrix") == 0);
		TEST_MSG("qrcode RNDR = %s", val);
	}

	/* EXAM should have some content */
	val = bwipp_get_property(ctx, "qrcode", "EXAM");
	TEST_CHECK(val != NULL);
	if (val) {
		TEST_CHECK(strlen(val) > 0);
		TEST_MSG("qrcode EXAM = %s", val);
	}

	bwipp_unload(ctx);
}

static void test_real_get_fmly(void) {
	BWIPP *ctx;
	const char *val;

	ctx = load_from(BARCODE_PS);
	if (!ctx) {
		TEST_MSG("Skipped: %s not found", BARCODE_PS);
		return;
	}

	/* Spot check FMLY values across different families */
	val = bwipp_get_property(ctx, "qrcode", "FMLY");
	TEST_CHECK(val != NULL);
	if (val) {
		TEST_CHECK(strcmp(val, "Two-dimensional symbols") == 0);
		TEST_MSG("qrcode FMLY = %s", val);
	}

	val = bwipp_get_property(ctx, "ean13", "FMLY");
	TEST_CHECK(val != NULL);
	if (val) {
		TEST_CHECK(strcmp(val, "Point Of Sale") == 0);
		TEST_MSG("ean13 FMLY = %s", val);
	}

	val = bwipp_get_property(ctx, "code128", "FMLY");
	TEST_CHECK(val != NULL);
	if (val) {
		TEST_CHECK(strcmp(val, "One-dimensional symbols") == 0);
		TEST_MSG("code128 FMLY = %s", val);
	}

	val = bwipp_get_property(ctx, "gs1-128", "FMLY");
	TEST_CHECK(val != NULL);
	if (val) {
		TEST_CHECK(strcmp(val, "Supply Chain") == 0);
		TEST_MSG("gs1-128 FMLY = %s", val);
	}

	val = bwipp_get_property(ctx, "maxicode", "FMLY");
	TEST_CHECK(val != NULL);
	if (val) {
		TEST_CHECK(strcmp(val, "Postal Symbols") == 0);
		TEST_MSG("maxicode FMLY = %s", val);
	}

	bwipp_unload(ctx);
}

static void test_real_all_encoders_have_fmly(void) {
	BWIPP *ctx;
	const char **encoders;
	unsigned int count, i;
	int missing;

	ctx = load_from(BARCODE_PS);
	if (!ctx) {
		TEST_MSG("Skipped: %s not found", BARCODE_PS);
		return;
	}

	encoders = bwipp_list_encoders(ctx, &count);
	TEST_ASSERT(encoders != NULL);

	/* Most encoders should have a FMLY property */
	missing = 0;
	for (i = 0; i < count; i++) {
		const char *fmly = bwipp_get_property(ctx, encoders[i], "FMLY");
		if (!fmly)
			missing++;
	}
	TEST_CHECK((unsigned int)missing < count);
	TEST_MSG("%d of %u encoders missing FMLY", missing, count);

	bwipp_free((void *)encoders);
	bwipp_unload(ctx);
}

static void test_real_list_families(void) {
	BWIPP *ctx;
	const char **list;
	unsigned int count, i;
	int found_pos, found_twod;

	ctx = load_from(BARCODE_PS);
	if (!ctx) {
		TEST_MSG("Skipped: %s not found", BARCODE_PS);
		return;
	}

	list = bwipp_list_families(ctx, &count);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(count > 0);
	TEST_MSG("Found %u families", count);

	found_pos = 0;
	found_twod = 0;
	for (i = 0; i < count; i++) {
		if (strcmp(list[i], "Point Of Sale") == 0) found_pos = 1;
		if (strcmp(list[i], "Two-dimensional symbols") == 0) found_twod = 1;
	}
	TEST_CHECK(found_pos);
	TEST_CHECK(found_twod);

	bwipp_free((void *)list);
	bwipp_unload(ctx);
}

static void test_real_list_family_members(void) {
	BWIPP *ctx;
	const char **list;
	unsigned int count, i;
	int found_qrcode;

	ctx = load_from(BARCODE_PS);
	if (!ctx) {
		TEST_MSG("Skipped: %s not found", BARCODE_PS);
		return;
	}

	list = bwipp_list_family_members(ctx, "Point Of Sale", &count);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(count > 0);
	TEST_MSG("Point Of Sale: %u members", count);
	bwipp_free((void *)list);

	list = bwipp_list_family_members(ctx, "Two-dimensional symbols", &count);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(count > 0);
	TEST_MSG("Two-dimensional symbols: %u members", count);

	found_qrcode = 0;
	for (i = 0; i < count; i++) {
		if (strcmp(list[i], "qrcode") == 0) found_qrcode = 1;
	}
	TEST_CHECK(found_qrcode);
	bwipp_free((void *)list);

	/* Unknown family */
	TEST_CHECK(bwipp_list_family_members(ctx, "Nonexistent", NULL) == NULL);

	bwipp_unload(ctx);
}


/* ========================================================================
 *  bwipp_list_families
 * ======================================================================== */

/*
 *  Mock with FMLY properties and mixed resource types:
 *    - "preamble"  (RESOURCE, no FMLY)
 *    - "enc1"      (ENCODER, FMLY=Family A, DESC=Encoder One)
 *    - "enc2"      (ENCODER, FMLY=Family A, DESC=Encoder Two)
 *    - "enc3"      (ENCODER, FMLY=Family B, DESC=Encoder Three)
 *    - "enc4"      (ENCODER, no FMLY)
 */
static const char mock_ps_families[] =
	"%!PS\n"
	"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
	"% --BEGIN TEMPLATE--\n"
	"% --BEGIN RESOURCE preamble--\n"
	"% preamble code\n"
	"% --END RESOURCE preamble--\n"
	"% --BEGIN ENCODER enc1--\n"
	"% --REQUIRES preamble--\n"
	"% --DESC: Encoder One\n"
	"% --FMLY: Family A\n"
	"% enc1 code\n"
	"% --END ENCODER enc1--\n"
	"% --BEGIN ENCODER enc2--\n"
	"% --REQUIRES preamble--\n"
	"% --DESC: Encoder Two\n"
	"% --FMLY: Family A\n"
	"% enc2 code\n"
	"% --END ENCODER enc2--\n"
	"% --BEGIN ENCODER enc3--\n"
	"% --REQUIRES preamble--\n"
	"% --DESC: Encoder Three\n"
	"% --FMLY: Family B\n"
	"% enc3 code\n"
	"% --END ENCODER enc3--\n"
	"% --BEGIN ENCODER enc4--\n"
	"% --REQUIRES preamble--\n"
	"% --DESC: Encoder Four\n"
	"% enc4 code\n"
	"% --END ENCODER enc4--\n"
	"% --END TEMPLATE--\n";

static void test_list_families_basic(void) {
	BWIPP *ctx;
	const char **list;
	unsigned int count;

	write_mock_ps(MOCK_PS, mock_ps_families);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	list = bwipp_list_families(ctx, &count);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(count == 2);
	TEST_CHECK(strcmp(list[0], "Family A") == 0);
	TEST_CHECK(strcmp(list[1], "Family B") == 0);
	TEST_CHECK(list[2] == NULL);
	bwipp_free((void *)list);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_list_families_no_fmly(void) {
	BWIPP *ctx;
	const char **list;
	unsigned int count;

	/* No encoders have FMLY */
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN ENCODER enc--\n"
		"% --DESC: Test\n"
		"% code\n"
		"% --END ENCODER enc--\n"
		"% --END TEMPLATE--\n"
	);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	list = bwipp_list_families(ctx, &count);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(count == 0);
	TEST_CHECK(list[0] == NULL);
	bwipp_free((void *)list);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_list_families_null_count(void) {
	BWIPP *ctx;
	const char **list;

	write_mock_ps(MOCK_PS, mock_ps_families);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	list = bwipp_list_families(ctx, NULL);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(strcmp(list[0], "Family A") == 0);
	bwipp_free((void *)list);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_list_families_sorted(void) {
	BWIPP *ctx;
	const char **list;
	unsigned int count;

	/* Families should be returned in sorted order */
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN ENCODER z--\n"
		"% --FMLY: Zebra\n"
		"% code\n"
		"% --END ENCODER z--\n"
		"% --BEGIN ENCODER a--\n"
		"% --FMLY: Apple\n"
		"% code\n"
		"% --END ENCODER a--\n"
		"% --BEGIN ENCODER m--\n"
		"% --FMLY: Mango\n"
		"% code\n"
		"% --END ENCODER m--\n"
		"% --END TEMPLATE--\n"
	);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	list = bwipp_list_families(ctx, &count);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(count == 3);
	TEST_CHECK(strcmp(list[0], "Apple") == 0);
	TEST_CHECK(strcmp(list[1], "Mango") == 0);
	TEST_CHECK(strcmp(list[2], "Zebra") == 0);
	bwipp_free((void *)list);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}


/* ========================================================================
 *  bwipp_list_family_members
 * ======================================================================== */

static void test_list_family_members_basic(void) {
	BWIPP *ctx;
	const char **list;
	unsigned int count;

	write_mock_ps(MOCK_PS, mock_ps_families);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* Family A has enc1 and enc2 */
	list = bwipp_list_family_members(ctx, "Family A", &count);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(count == 2);
	TEST_CHECK(strcmp(list[0], "enc1") == 0);
	TEST_CHECK(strcmp(list[1], "enc2") == 0);
	TEST_CHECK(list[2] == NULL);
	bwipp_free((void *)list);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_list_family_members_single(void) {
	BWIPP *ctx;
	const char **list;
	unsigned int count;

	write_mock_ps(MOCK_PS, mock_ps_families);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* Family B has only enc3 */
	list = bwipp_list_family_members(ctx, "Family B", &count);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(count == 1);
	TEST_CHECK(strcmp(list[0], "enc3") == 0);
	TEST_CHECK(list[1] == NULL);
	bwipp_free((void *)list);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_list_family_members_unknown(void) {
	BWIPP *ctx;

	write_mock_ps(MOCK_PS, mock_ps_families);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	TEST_CHECK(bwipp_list_family_members(ctx, "Nonexistent", NULL) == NULL);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_list_family_members_null_count(void) {
	BWIPP *ctx;
	const char **list;

	write_mock_ps(MOCK_PS, mock_ps_families);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	list = bwipp_list_family_members(ctx, "Family A", NULL);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(strcmp(list[0], "enc1") == 0);
	bwipp_free((void *)list);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_list_family_members_sorted(void) {
	BWIPP *ctx;
	const char **list;
	unsigned int count;

	/* Members should be sorted by DESC, not encoder name */
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN ENCODER zzz--\n"
		"% --DESC: Alpha\n"
		"% --FMLY: Grp\n"
		"% code\n"
		"% --END ENCODER zzz--\n"
		"% --BEGIN ENCODER aaa--\n"
		"% --DESC: Charlie\n"
		"% --FMLY: Grp\n"
		"% code\n"
		"% --END ENCODER aaa--\n"
		"% --BEGIN ENCODER mmm--\n"
		"% --DESC: Bravo\n"
		"% --FMLY: Grp\n"
		"% code\n"
		"% --END ENCODER mmm--\n"
		"% --END TEMPLATE--\n"
	);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	list = bwipp_list_family_members(ctx, "Grp", &count);
	TEST_ASSERT(list != NULL);
	TEST_CHECK(count == 3);
	/* Sorted by DESC: Alpha(zzz), Bravo(mmm), Charlie(aaa) */
	TEST_CHECK(strcmp(list[0], "zzz") == 0);
	TEST_CHECK(strcmp(list[1], "mmm") == 0);
	TEST_CHECK(strcmp(list[2], "aaa") == 0);
	bwipp_free((void *)list);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_list_family_members_strings_owned(void) {
	BWIPP *ctx;
	const char **list;
	unsigned int count;
	const char *first;

	write_mock_ps(MOCK_PS, mock_ps_families);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	list = bwipp_list_family_members(ctx, "Family A", &count);
	TEST_ASSERT(list != NULL);
	TEST_ASSERT(count >= 1);
	first = list[0];
	bwipp_free((void *)list);

	/* String should still be valid (owned by context) */
	TEST_CHECK(strcmp(first, "enc1") == 0);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}


/* ========================================================================
 *  bwipp_emit_required_resources
 * ======================================================================== */

static void test_emit_required_no_deps(void) {
	BWIPP *ctx;
	char *out;

	write_mock_ps(MOCK_PS, mock_ps);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	TEST_CHECK((out = bwipp_emit_required_resources(ctx, "base")) != NULL);
	TEST_CHECK(strcmp(out, "% base code\n") == 0);
	TEST_MSG("Got: [%s]", out);
	bwipp_free(out);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_emit_required_with_deps(void) {
	BWIPP *ctx;
	char *out;

	write_mock_ps(MOCK_PS, mock_ps);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* "helper" requires "base"; should emit base then helper */
	TEST_CHECK((out = bwipp_emit_required_resources(ctx, "helper")) != NULL);
	TEST_CHECK(strcmp(out, "% base code\n% helper code\n") == 0);
	TEST_MSG("Got: [%s]", out);
	bwipp_free(out);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_emit_required_many_deps(void) {
	BWIPP *ctx;
	char *out;

	write_mock_ps(MOCK_PS, mock_ps);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* "encoder" requires "base helper" — deps emitted in REQUIRES order */
	TEST_CHECK((out = bwipp_emit_required_resources(ctx, "encoder")) != NULL);
	TEST_CHECK(strcmp(out,
		"% base code\n% helper code\n% encoder code\n") == 0);
	TEST_MSG("Got: [%s]", out);
	bwipp_free(out);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_emit_required_dep_order(void) {
	BWIPP *ctx;
	char *out;

	/* Deps should be emitted in REQUIRES list order, not parse order */
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE alpha--\n"
		"A\n"
		"% --END RESOURCE alpha--\n"
		"% --BEGIN RESOURCE beta--\n"
		"B\n"
		"% --END RESOURCE beta--\n"
		"% --BEGIN RESOURCE gamma--\n"
		"% --REQUIRES beta alpha--\n"
		"G\n"
		"% --END RESOURCE gamma--\n"
		"% --END TEMPLATE--\n"
	);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	TEST_CHECK((out = bwipp_emit_required_resources(ctx, "gamma")) != NULL);
	/* beta before alpha because that's the REQUIRES order */
	TEST_CHECK(strcmp(out, "B\nA\nG\n") == 0);
	TEST_MSG("Got: [%s]", out);
	bwipp_free(out);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_emit_required_missing_resource(void) {
	BWIPP *ctx;
	char *out;

	write_mock_ps(MOCK_PS, mock_ps);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	TEST_CHECK((out = bwipp_emit_required_resources(ctx, "nonexistent")) != NULL);
	TEST_CHECK(strcmp(out, "") == 0);
	bwipp_free(out);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_emit_required_missing_dep(void) {
	BWIPP *ctx;
	char *out;

	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE foo--\n"
		"% --REQUIRES missing--\n"
		"% foo code\n"
		"% --END RESOURCE foo--\n"
		"% --END TEMPLATE--\n"
	);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* Missing dep silently skipped */
	TEST_CHECK((out = bwipp_emit_required_resources(ctx, "foo")) != NULL);
	TEST_CHECK(strcmp(out, "% foo code\n") == 0);
	TEST_MSG("Got: [%s]", out);
	bwipp_free(out);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_emit_required_mixed_missing_deps(void) {
	BWIPP *ctx;
	char *out;

	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE real--\n"
		"R\n"
		"% --END RESOURCE real--\n"
		"% --BEGIN RESOURCE foo--\n"
		"% --REQUIRES missing1 real missing2--\n"
		"F\n"
		"% --END RESOURCE foo--\n"
		"% --END TEMPLATE--\n"
	);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* missing1 and missing2 skipped, real included */
	TEST_CHECK((out = bwipp_emit_required_resources(ctx, "foo")) != NULL);
	TEST_CHECK(strcmp(out, "R\nF\n") == 0);
	TEST_MSG("Got: [%s]", out);
	bwipp_free(out);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_emit_required_empty_string(void) {
	BWIPP *ctx;
	char *out;

	write_mock_ps(MOCK_PS, mock_ps);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* Empty resource name */
	TEST_CHECK((out = bwipp_emit_required_resources(ctx, "")) != NULL);
	TEST_CHECK(strcmp(out, "") == 0);
	bwipp_free(out);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}


/* ========================================================================
 *  bwipp_emit_all_resources
 * ======================================================================== */

static void test_emit_all_resources(void) {
	BWIPP *ctx;
	char *out;

	write_mock_ps(MOCK_PS, mock_ps);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	TEST_CHECK((out = bwipp_emit_all_resources(ctx)) != NULL);
	TEST_CHECK(strcmp(out,
		"% base code\n% helper code\n% encoder code\n") == 0);
	TEST_MSG("Got: [%s]", out);
	bwipp_free(out);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_emit_all_preserves_order(void) {
	BWIPP *ctx;
	char *out;

	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE zzz--\n"
		"Z\n"
		"% --END RESOURCE zzz--\n"
		"% --BEGIN RESOURCE aaa--\n"
		"A\n"
		"% --END RESOURCE aaa--\n"
		"% --BEGIN RESOURCE mmm--\n"
		"M\n"
		"% --END RESOURCE mmm--\n"
		"% --END TEMPLATE--\n"
	);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* Must be in file order, not alphabetical */
	TEST_CHECK((out = bwipp_emit_all_resources(ctx)) != NULL);
	TEST_CHECK(strcmp(out, "Z\nA\nM\n") == 0);
	TEST_MSG("Got: [%s]", out);
	bwipp_free(out);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}


/* ========================================================================
 *  bwipp_emit_exec - hex encoding
 * ======================================================================== */

static void test_emit_exec_exact_output(void) {
	BWIPP *ctx;
	char *out;
	const char *expect =
		"0 0 moveto\n"
		"<414243>\n"
		"<6F70743D31>\n"
		"/enc /uk.co.terryburton.bwipp findresource exec\n";

	write_mock_ps(MOCK_PS, mock_ps);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	TEST_CHECK((out = bwipp_emit_exec(ctx, "enc", "ABC", "opt=1")) != NULL);
	TEST_CHECK(strcmp(out, expect) == 0);
	TEST_MSG("Got:\n[%s]\nExpected:\n[%s]", out, expect);
	bwipp_free(out);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_emit_exec_empty_data(void) {
	BWIPP *ctx;
	char *out;
	const char *expect =
		"0 0 moveto\n"
		"<>\n"
		"<>\n"
		"/enc /uk.co.terryburton.bwipp findresource exec\n";

	write_mock_ps(MOCK_PS, mock_ps);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	TEST_CHECK((out = bwipp_emit_exec(ctx, "enc", "", "")) != NULL);
	TEST_CHECK(strcmp(out, expect) == 0);
	TEST_MSG("Got:\n[%s]", out);
	bwipp_free(out);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_emit_exec_all_byte_values(void) {
	BWIPP *ctx;
	char *out;
	char input[257];
	const char *hex_digits = "0123456789ABCDEF";
	char expected_hex[514];
	int i;

	write_mock_ps(MOCK_PS, mock_ps);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* Build input with bytes 0x01..0xFF (skip 0x00, it terminates the string) */
	for (i = 1; i <= 255; i++)
		input[i - 1] = (char)i;
	input[255] = '\0';

	/* Build expected hex for bytes 0x01..0xFF */
	for (i = 1; i <= 255; i++) {
		expected_hex[(i - 1) * 2] = hex_digits[(i >> 4) & 0xF];
		expected_hex[(i - 1) * 2 + 1] = hex_digits[i & 0xF];
	}
	expected_hex[510] = '\0';

	TEST_CHECK((out = bwipp_emit_exec(ctx, "enc", input, "")) != NULL);

	/* Verify all hex pairs are present (ignoring line wrapping) */
	{
		char flat[2048];
		const char *p;
		char *d;

		/* Strip newlines and spaces from the hex output to flatten it */
		d = flat;
		p = strchr(out, '<');
		TEST_ASSERT(p != NULL);
		p++;  /* skip '<' */
		while (*p && *p != '>') {
			if (*p != '\n' && *p != ' ')
				*d++ = *p;
			p++;
		}
		*d = '\0';

		TEST_CHECK(strcmp(flat, expected_hex) == 0);
		TEST_MSG("Hex mismatch at byte around position %d",
			 (int)(strlen(flat) < strlen(expected_hex) ?
				strlen(flat) : strlen(expected_hex)) / 2);
	}

	bwipp_free(out);
	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_emit_exec_hex_wrap_exact_boundary(void) {
	BWIPP *ctx;
	char *out;
	char data[38];
	const char *p;
	int hex_before_wrap;

	write_mock_ps(MOCK_PS, mock_ps);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* 36 bytes = 72 hex chars = exactly HEXIFY_WIDTH; no wrap needed */
	memset(data, 'B', 36);
	data[36] = '\0';

	TEST_CHECK((out = bwipp_emit_exec(ctx, "enc", data, "")) != NULL);

	/* Find the data hex string */
	p = strchr(out, '<');
	TEST_ASSERT(p != NULL);

	/* Count hex chars before any newline within the hex string */
	hex_before_wrap = 0;
	p++;  /* skip '<' */
	while (*p && *p != '>' && *p != '\n') {
		hex_before_wrap++;
		p++;
	}

	/* At exactly 72 hex chars, all should be on one line */
	TEST_CHECK(hex_before_wrap == 72);
	TEST_CHECK(*p == '>');
	TEST_MSG("hex_before_wrap=%d, next char='%c'", hex_before_wrap, *p);

	bwipp_free(out);
	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_emit_exec_hex_wrap_over_boundary(void) {
	BWIPP *ctx;
	char *out;
	char data[100];
	const char *p;

	write_mock_ps(MOCK_PS, mock_ps);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* 37 bytes = 74 hex chars; should wrap after 72 */
	memset(data, 'C', 37);
	data[37] = '\0';

	TEST_CHECK((out = bwipp_emit_exec(ctx, "enc", data, "")) != NULL);

	/* Find first newline within hex string */
	p = strchr(out, '<');
	TEST_ASSERT(p != NULL);
	p++;
	TEST_CHECK(memchr(p, '\n', 80) != NULL);
	TEST_MSG("Got: [%s]", out);

	bwipp_free(out);
	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_emit_exec_hex_wrap_long_data(void) {
	BWIPP *ctx;
	char *out;
	char data[200];
	const char *p;
	int wraps;

	write_mock_ps(MOCK_PS, mock_ps);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* 180 bytes = 360 hex chars; multiple wraps expected */
	memset(data, 'X', 180);
	data[180] = '\0';

	TEST_CHECK((out = bwipp_emit_exec(ctx, "enc", data, "")) != NULL);

	/* Count newlines within the hex string */
	p = strchr(out, '<');
	TEST_ASSERT(p != NULL);
	wraps = 0;
	while (*p && *p != '>') {
		if (*p == '\n')
			wraps++;
		p++;
	}

	/* 360 hex chars / 72 per line = 5 lines, so 4 wraps */
	TEST_CHECK(wraps == 4);
	TEST_MSG("Expected 4 wraps, got %d", wraps);

	bwipp_free(out);
	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_emit_exec_special_chars(void) {
	BWIPP *ctx;
	char *out;

	write_mock_ps(MOCK_PS, mock_ps);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	/* SOH=01, DEL=7F, high byte=FF */
	TEST_CHECK((out = bwipp_emit_exec(ctx, "enc", "\x01\x7f\xff", "")) != NULL);
	TEST_CHECK(strstr(out, "017FFF") != NULL);
	TEST_MSG("Got: [%s]", out);

	bwipp_free(out);
	bwipp_unload(ctx);
	remove(MOCK_PS);
}


/* ========================================================================
 *  bwipp_free
 * ======================================================================== */

static void test_free_null(void) {
	/* Must not crash */
	bwipp_free(NULL);
}


/* ========================================================================
 *  Resource code preservation
 * ======================================================================== */

static void test_multiline_code(void) {
	BWIPP *ctx;
	char *out;
	const char *expect =
		"/multi {\n"
		"  10 dict begin\n"
		"  /data exch def\n"
		"  end\n"
		"} bind def\n";

	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE multi--\n"
		"/multi {\n"
		"  10 dict begin\n"
		"  /data exch def\n"
		"  end\n"
		"} bind def\n"
		"% --END RESOURCE multi--\n"
		"% --END TEMPLATE--\n"
	);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	TEST_CHECK((out = bwipp_emit_required_resources(ctx, "multi")) != NULL);
	TEST_CHECK(strcmp(out, expect) == 0);
	TEST_MSG("Got: [%s]", out);
	bwipp_free(out);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_empty_code(void) {
	BWIPP *ctx;
	char *out;

	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE empty--\n"
		"% --END RESOURCE empty--\n"
		"% --END TEMPLATE--\n"
	);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	TEST_CHECK((out = bwipp_emit_required_resources(ctx, "empty")) != NULL);
	TEST_CHECK(strcmp(out, "") == 0);
	bwipp_free(out);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_code_with_percent_lines(void) {
	BWIPP *ctx;
	char *out;

	/* Lines starting with % but not matching markers should be kept as code */
	write_mock_ps(MOCK_PS,
		"%!PS\n"
		"% Barcode Writer in Pure PostScript - Version 2099-01-01\n"
		"% --BEGIN TEMPLATE--\n"
		"% --BEGIN RESOURCE commented--\n"
		"% This is a comment\n"
		"/code 42 def\n"
		"% Another comment\n"
		"% --END RESOURCE commented--\n"
		"% --END TEMPLATE--\n"
	);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	TEST_CHECK((out = bwipp_emit_required_resources(ctx, "commented")) != NULL);
	TEST_CHECK(strcmp(out,
		"% This is a comment\n/code 42 def\n% Another comment\n") == 0);
	TEST_MSG("Got: [%s]", out);
	bwipp_free(out);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}


/* ========================================================================
 *  Lifecycle
 * ======================================================================== */

static void test_load_unload_cycle(void) {
	int i;

	write_mock_ps(MOCK_PS, mock_ps);

	for (i = 0; i < 10; i++) {
		BWIPP *ctx;
		TEST_CASE("cycle");
		TEST_CHECK((ctx = load_from(MOCK_PS)) != NULL);
		if (ctx)
			bwipp_unload(ctx);
	}

	remove(MOCK_PS);
}

static void test_full_workflow(void) {
	BWIPP *ctx;
	const char *version;
	char *res, *all, *exec;

	write_mock_ps(MOCK_PS, mock_ps);
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);

	TEST_CHECK((version = bwipp_get_version(ctx)) != NULL);
	TEST_CHECK(strcmp(version, "2099-01-01") == 0);

	TEST_CHECK((res = bwipp_emit_required_resources(ctx, "encoder")) != NULL);
	TEST_CHECK(strlen(res) > 0);

	TEST_CHECK((all = bwipp_emit_all_resources(ctx)) != NULL);
	TEST_CHECK(strlen(all) > 0);

	TEST_CHECK((exec = bwipp_emit_exec(ctx, "encoder", "data", "opts")) != NULL);
	TEST_CHECK(strstr(exec, "/encoder") != NULL);

	bwipp_free(res);
	bwipp_free(all);
	bwipp_free(exec);
	bwipp_unload(ctx);
	remove(MOCK_PS);
}


/* ========================================================================
 *  Integration tests using real barcode.ps (if available)
 * ======================================================================== */

static void test_real_load(void) {
	BWIPP *ctx;

	ctx = load_from(BARCODE_PS);
	if (!ctx) {
		TEST_MSG("Skipped: %s not found (run make first)", BARCODE_PS);
		return;
	}

	TEST_CHECK(bwipp_get_version(ctx) != NULL);
	TEST_CHECK(strlen(bwipp_get_version(ctx)) >= 10);

	bwipp_unload(ctx);
}

static void test_real_emit_required(void) {
	BWIPP *ctx;
	char *out;

	ctx = load_from(BARCODE_PS);
	if (!ctx) {
		TEST_MSG("Skipped: %s not found", BARCODE_PS);
		return;
	}

	/* Resource with dependencies */
	TEST_CHECK((out = bwipp_emit_required_resources(ctx, "code39ext")) != NULL);
	TEST_CHECK(strlen(out) > 0);
	bwipp_free(out);

	/* Resource without dependencies */
	TEST_CHECK((out = bwipp_emit_required_resources(ctx, "preamble")) != NULL);
	TEST_CHECK(strlen(out) > 0);
	bwipp_free(out);

	/* Missing resource */
	TEST_CHECK((out = bwipp_emit_required_resources(ctx, "nonexistent_xyz")) != NULL);
	TEST_CHECK(strcmp(out, "") == 0);
	bwipp_free(out);

	bwipp_unload(ctx);
}

static void test_real_emit_all(void) {
	BWIPP *ctx;
	char *out;

	ctx = load_from(BARCODE_PS);
	if (!ctx) {
		TEST_MSG("Skipped: %s not found", BARCODE_PS);
		return;
	}

	TEST_CHECK((out = bwipp_emit_all_resources(ctx)) != NULL);
	TEST_CHECK(strlen(out) > 100000);
	bwipp_free(out);

	bwipp_unload(ctx);
}

static void test_real_emit_exec(void) {
	BWIPP *ctx;
	char *out;

	ctx = load_from(BARCODE_PS);
	if (!ctx) {
		TEST_MSG("Skipped: %s not found", BARCODE_PS);
		return;
	}

	TEST_CHECK((out = bwipp_emit_exec(ctx, "qrcode", "TESTING",
					  "version=5")) != NULL);
	TEST_CHECK(strstr(out, "0 0 moveto") != NULL);
	TEST_CHECK(strstr(out, "/qrcode") != NULL);
	bwipp_free(out);

	bwipp_unload(ctx);
}


/* ========================================================================
 *  bwipp_load_ex - lazy loading
 * ======================================================================== */

static void test_lazy_load_mock(void) {
	BWIPP *ctx;
	char *out;
	bwipp_load_init_opts_t opts = {
		.struct_size = sizeof(opts),
		.flags = bwipp_iLAZY_LOAD,
		.filename = MOCK_PS,
	};

	write_mock_ps(MOCK_PS, mock_ps);

	TEST_ASSERT((ctx = bwipp_load_ex(&opts)) != NULL);

	/* Metadata should still be available */
	TEST_CHECK(bwipp_get_version(ctx) != NULL);
	TEST_CHECK(strcmp(bwipp_get_version(ctx), "2099-01-01") == 0);

	/* Emit should load code on demand */
	out = bwipp_emit_required_resources(ctx, "encoder");
	TEST_ASSERT(out != NULL);
	TEST_CHECK(strstr(out, "base code") != NULL);
	TEST_CHECK(strstr(out, "helper code") != NULL);
	TEST_CHECK(strstr(out, "encoder code") != NULL);
	bwipp_free(out);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_lazy_emit_all(void) {
	BWIPP *ctx;
	char *out;
	bwipp_load_init_opts_t opts = {
		.struct_size = sizeof(opts),
		.flags = bwipp_iLAZY_LOAD,
		.filename = MOCK_PS,
	};

	write_mock_ps(MOCK_PS, mock_ps);

	TEST_ASSERT((ctx = bwipp_load_ex(&opts)) != NULL);

	out = bwipp_emit_all_resources(ctx);
	TEST_ASSERT(out != NULL);
	TEST_CHECK(strstr(out, "base code") != NULL);
	TEST_CHECK(strstr(out, "helper code") != NULL);
	TEST_CHECK(strstr(out, "encoder code") != NULL);
	bwipp_free(out);

	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_lazy_no_code_in_memory(void) {
	BWIPP *ctx;
	char *eager_out, *lazy_out;
	bwipp_load_init_opts_t opts = {
		.struct_size = sizeof(opts),
		.flags = bwipp_iLAZY_LOAD,
		.filename = MOCK_PS,
	};

	write_mock_ps(MOCK_PS, mock_ps);

	/* Eager: verify code works */
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);
	eager_out = bwipp_emit_required_resources(ctx, "encoder");
	TEST_ASSERT(eager_out != NULL);
	bwipp_unload(ctx);

	/* Lazy: same output */
	TEST_ASSERT((ctx = bwipp_load_ex(&opts)) != NULL);
	lazy_out = bwipp_emit_required_resources(ctx, "encoder");
	TEST_ASSERT(lazy_out != NULL);

	TEST_CHECK(strcmp(eager_out, lazy_out) == 0);

	bwipp_free(eager_out);
	bwipp_free(lazy_out);
	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_lazy_null_opts(void) {
	BWIPP *ctx;

	write_mock_ps(MOCK_PS, mock_ps);

	/* NULL opts should behave like bwipp_load (eager, default path) */
	TEST_ASSERT((ctx = load_from(MOCK_PS)) != NULL);
	TEST_CHECK(bwipp_get_version(ctx) != NULL);
	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_lazy_old_struct_size(void) {
	BWIPP *ctx;
	/* struct_size covers filename but not flags: flags not extracted, defaults to eager */
	bwipp_load_init_opts_t opts = {
		.struct_size = offsetof(bwipp_load_init_opts_t, flags),
		.filename = MOCK_PS,
		.flags = bwipp_iLAZY_LOAD,	/* Should be ignored */
	};

	write_mock_ps(MOCK_PS, mock_ps);

	TEST_ASSERT((ctx = bwipp_load_ex(&opts)) != NULL);
	TEST_CHECK(bwipp_get_version(ctx) != NULL);
	bwipp_unload(ctx);
	remove(MOCK_PS);
}

static void test_real_lazy_emit_required(void) {
	BWIPP *ctx;
	char *eager_out, *lazy_out;
	bwipp_load_init_opts_t opts = {
		.struct_size = sizeof(opts),
		.flags = bwipp_iLAZY_LOAD,
		.filename = BARCODE_PS,
	};

	ctx = load_from(BARCODE_PS);
	if (!ctx) {
		TEST_MSG("Skipped: %s not found", BARCODE_PS);
		return;
	}
	eager_out = bwipp_emit_required_resources(ctx, "qrcode");
	TEST_ASSERT(eager_out != NULL);
	bwipp_unload(ctx);

	ctx = bwipp_load_ex(&opts);
	TEST_ASSERT(ctx != NULL);
	lazy_out = bwipp_emit_required_resources(ctx, "qrcode");
	TEST_ASSERT(lazy_out != NULL);

	TEST_CHECK(strcmp(eager_out, lazy_out) == 0);

	bwipp_free(eager_out);
	bwipp_free(lazy_out);
	bwipp_unload(ctx);
}

static void test_real_lazy_emit_all(void) {
	BWIPP *ctx;
	char *eager_out, *lazy_out;
	bwipp_load_init_opts_t opts = {
		.struct_size = sizeof(opts),
		.flags = bwipp_iLAZY_LOAD,
		.filename = BARCODE_PS,
	};

	ctx = load_from(BARCODE_PS);
	if (!ctx) {
		TEST_MSG("Skipped: %s not found", BARCODE_PS);
		return;
	}
	eager_out = bwipp_emit_all_resources(ctx);
	TEST_ASSERT(eager_out != NULL);
	bwipp_unload(ctx);

	ctx = bwipp_load_ex(&opts);
	TEST_ASSERT(ctx != NULL);
	lazy_out = bwipp_emit_all_resources(ctx);
	TEST_ASSERT(lazy_out != NULL);

	TEST_CHECK(strcmp(eager_out, lazy_out) == 0);

	bwipp_free(eager_out);
	bwipp_free(lazy_out);
	bwipp_unload(ctx);
}


TEST_LIST = {

	/* Loading - success */
	{"load_mock",                        test_load_mock},
	{"load_empty_file",                  test_load_empty_file},
	{"load_no_template",                 test_load_no_template},
	{"load_single_resource",             test_load_single_resource},
	{"load_many_resources_order",        test_load_many_resources_order},
	{"load_content_before_template",     test_load_content_before_template},
	{"load_content_after_template",      test_load_content_after_template},
	{"load_long_requires_line",          test_load_long_requires_line},

	/* Loading - error paths */
	{"load_missing_file",                test_load_missing_file},
	{"load_default_path",                test_load_default_path},
	{"load_nested_begin",                test_load_nested_begin},
	{"load_mismatched_end_name",         test_load_mismatched_end_name},
	{"load_mismatched_end_type",         test_load_mismatched_end_type},
	{"load_unterminated_resource",       test_load_unterminated_resource},
	{"load_unterminated_at_eof",         test_load_unterminated_at_eof},
	{"load_end_without_begin",           test_load_end_without_begin},
	{"load_duplicate_requires",          test_load_duplicate_requires},
	{"load_requires_outside",            test_load_requires_outside_resource},
	{"load_malformed_begin_no_name",     test_load_malformed_begin_no_name},
	{"load_malformed_begin_no_type_sp",  test_load_malformed_begin_no_type_space},
	{"load_malformed_end_no_space",      test_load_malformed_end_no_space},
	{"load_malformed_requires_no_sfx",   test_load_malformed_requires_no_suffix},
	{"load_malformed_begin_no_sfx",      test_load_malformed_begin_no_suffix},
	{"load_malformed_end_no_sfx",        test_load_malformed_end_no_suffix},
	{"load_truncated_marker_begin",      test_load_truncated_marker_begin},
	{"load_truncated_marker_end",        test_load_truncated_marker_end},
	{"load_truncated_marker_requires",   test_load_truncated_marker_requires},
	{"load_truncated_marker_template",   test_load_truncated_marker_template},

	/* Version */
	{"get_version",                      test_get_version},
	{"get_version_no_version_line",      test_get_version_no_version_line},
	{"get_version_only_first",           test_get_version_only_first},
	{"get_version_after_template",       test_get_version_after_template},

	/* List encoders */
	{"list_encoders_basic",              test_list_encoders_basic},
	{"list_encoders_no_encoders",        test_list_encoders_no_encoders},
	{"list_encoders_null_count",         test_list_encoders_null_count},
	{"list_encoders_sorted",             test_list_encoders_sorted},
	{"list_encoders_strings_owned",      test_list_encoders_strings_owned_by_context},

	/* List properties */
	{"list_properties_basic",            test_list_properties_basic},
	{"list_properties_fewer_keys",       test_list_properties_fewer_keys},
	{"list_properties_no_properties",    test_list_properties_no_properties},
	{"list_properties_unknown_resource", test_list_properties_unknown_resource},
	{"list_properties_null_count",       test_list_properties_null_count},
	{"list_properties_preserves_order",  test_list_properties_preserves_order},

	/* Get property */
	{"get_property_basic",               test_get_property_basic},
	{"get_property_different_encoder",   test_get_property_different_encoder},
	{"get_property_missing_key",         test_get_property_missing_key},
	{"get_property_missing_resource",    test_get_property_missing_resource},
	{"get_property_no_properties",       test_get_property_no_properties},
	{"get_property_value_with_spaces",   test_get_property_value_with_spaces},
	{"get_property_value_with_colon",    test_get_property_value_with_colon},
	{"get_property_owned_by_context",    test_get_property_owned_by_context},

	/* Metadata parsing edge cases */
	{"meta_not_outside_resource",        test_metadata_not_parsed_outside_resource},
	{"meta_after_requires",              test_metadata_after_requires},
	{"meta_fmly_property",               test_metadata_fmly_property},

	/* List families */
	{"list_families_basic",              test_list_families_basic},
	{"list_families_no_fmly",            test_list_families_no_fmly},
	{"list_families_null_count",         test_list_families_null_count},
	{"list_families_sorted",             test_list_families_sorted},

	/* List family members */
	{"list_family_members_basic",        test_list_family_members_basic},
	{"list_family_members_single",       test_list_family_members_single},
	{"list_family_members_unknown",      test_list_family_members_unknown},
	{"list_family_members_null_count",   test_list_family_members_null_count},
	{"list_family_members_sorted",       test_list_family_members_sorted},
	{"list_family_members_strings",      test_list_family_members_strings_owned},

	/* Emit required resources */
	{"emit_required_no_deps",            test_emit_required_no_deps},
	{"emit_required_with_deps",          test_emit_required_with_deps},
	{"emit_required_many_deps",          test_emit_required_many_deps},
	{"emit_required_dep_order",          test_emit_required_dep_order},
	{"emit_required_missing",            test_emit_required_missing_resource},
	{"emit_required_missing_dep",        test_emit_required_missing_dep},
	{"emit_required_mixed_missing",      test_emit_required_mixed_missing_deps},
	{"emit_required_empty_string",       test_emit_required_empty_string},

	/* Emit all resources */
	{"emit_all_resources",               test_emit_all_resources},
	{"emit_all_preserves_order",         test_emit_all_preserves_order},

	/* Emit exec */
	{"emit_exec_exact_output",           test_emit_exec_exact_output},
	{"emit_exec_empty_data",             test_emit_exec_empty_data},
	{"emit_exec_all_byte_values",        test_emit_exec_all_byte_values},
	{"emit_exec_hex_wrap_exact",         test_emit_exec_hex_wrap_exact_boundary},
	{"emit_exec_hex_wrap_over",          test_emit_exec_hex_wrap_over_boundary},
	{"emit_exec_hex_wrap_long",          test_emit_exec_hex_wrap_long_data},
	{"emit_exec_special_chars",          test_emit_exec_special_chars},

	/* Free */
	{"free_null",                        test_free_null},

	/* Resource code */
	{"multiline_code",                   test_multiline_code},
	{"empty_code",                       test_empty_code},
	{"code_with_percent_lines",          test_code_with_percent_lines},

	/* Lifecycle */
	{"load_unload_cycle",                test_load_unload_cycle},
	{"full_workflow",                    test_full_workflow},

	/* Integration (real barcode.ps) */
	{"real_load",                        test_real_load},
	{"real_emit_required",               test_real_emit_required},
	{"real_emit_all",                    test_real_emit_all},
	{"real_emit_exec",                   test_real_emit_exec},
	{"real_list_encoders",               test_real_list_encoders},
	{"real_list_properties",             test_real_list_properties},
	{"real_get_property",                test_real_get_property},
	{"real_get_fmly",                    test_real_get_fmly},
	{"real_all_encoders_have_fmly",      test_real_all_encoders_have_fmly},
	{"real_list_families",               test_real_list_families},
	{"real_list_family_members",         test_real_list_family_members},

	/* Lazy loading */
	{"lazy_load_mock",                   test_lazy_load_mock},
	{"lazy_emit_all",                    test_lazy_emit_all},
	{"lazy_no_code_in_memory",           test_lazy_no_code_in_memory},
	{"lazy_null_opts",                   test_lazy_null_opts},
	{"lazy_old_struct_size",             test_lazy_old_struct_size},

	/* Lazy loading (real barcode.ps) */
	{"real_lazy_emit_required",          test_real_lazy_emit_required},
	{"real_lazy_emit_all",               test_real_lazy_emit_all},

	{NULL, NULL}
};
