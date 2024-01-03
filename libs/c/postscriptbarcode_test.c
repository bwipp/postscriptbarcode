/*
 * libpostscriptbarcode
 *
 * @file postscriptbarcode_test.c
 * @author Copyright (c) 2004-2024 Terry Burton.
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

#if defined(__clang__)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu-folding-constant"
#pragma clang diagnostic ignored "-Wimplicit-int-float-conversion"
#pragma clang diagnostic ignored "-Wsign-conversion"
#pragma clang diagnostic ignored "-Wdeclaration-after-statement"
#elif defined(__GNUC__)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wconversion"
#pragma GCC diagnostic ignored "-Wsign-conversion"
#pragma GCC diagnostic ignored "-Wdeclaration-after-statement"
#elif defined(_MSC_VER)
#include <CodeAnalysis/warnings.h>
#pragma warning(push)
#pragma warning(disable : ALL_CODE_ANALYSIS_WARNINGS)
#endif

#include "acutest.h"

#if defined(__clang__)
#pragma clang diagnostic pop
#elif defined(__GNUC__)
#pragma GCC diagnostic pop
#elif defined(_MSC_VER)
#pragma warning(pop)
#endif

#include <stdio.h>
#include <string.h>

#include "postscriptbarcode.h"

static void test_api_bwipp_load_from_file(void) {

  BWIPP *ctx;

  TEST_CHECK((ctx = bwipp_load_from_file(
                  "../../build/monolithic/barcode.ps")) != NULL);

  bwipp_unload(ctx);
}

static void test_api_bwipp_get_version(void) {

  BWIPP *ctx;
  const char *version;

  TEST_ASSERT((ctx = bwipp_load_from_file(
                   "../../build/monolithic/barcode.ps")) != NULL);
  TEST_CHECK((version = bwipp_get_version(ctx)) != NULL);
  TEST_CHECK(strlen(version) >= 10);

  bwipp_unload(ctx);
}

static void test_api_bwipp_emit_required_resources(void) {

  BWIPP *ctx;
  char *out;

  TEST_ASSERT((ctx = bwipp_load_from_file(
                   "../../build/monolithic/barcode.ps")) != NULL);

  TEST_CHECK((out = bwipp_emit_required_resources(ctx, "code39ext")) != NULL);
  bwipp_free(out);

  // Resource does not exist
  TEST_CHECK((out = bwipp_emit_required_resources(ctx, "xyz")) != NULL);
  TEST_CHECK(strcmp(out, "") == 0);
  bwipp_free(out);

  bwipp_unload(ctx);
}

static void test_api_bwipp_emit_all_resources(void) {

  BWIPP *ctx;
  char *out;

  TEST_ASSERT((ctx = bwipp_load_from_file(
                   "../../build/monolithic/barcode.ps")) != NULL);

  TEST_CHECK((out = bwipp_emit_all_resources(ctx)) != NULL);
  bwipp_free(out);

  bwipp_unload(ctx);
}

static void test_api_bwipp_emit_exec(void) {

  BWIPP *ctx;
  char *out;

  TEST_ASSERT((ctx = bwipp_load_from_file(
                   "../../build/monolithic/barcode.ps")) != NULL);

  TEST_CHECK((out = bwipp_emit_exec(ctx, "qrcode", "TESTING123",
                                    "version=20")) != NULL);
  bwipp_free(out);

  bwipp_unload(ctx);
}

TEST_LIST = {
    {"bwipp_load_from_file", test_api_bwipp_load_from_file},
    {"bwipp_get_version", test_api_bwipp_get_version},
    {"bwipp_emit_required_resources", test_api_bwipp_emit_required_resources},
    {"bwipp_emit_all_resources", test_api_bwipp_emit_all_resources},
    {"bwipp_emit_exec", test_api_bwipp_emit_exec},
    {NULL, NULL}};
