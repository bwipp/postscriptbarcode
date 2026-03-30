/*
 * libpostscriptbarcode - postscriptbarcode_fuzzer_load.c
 *
 * Fuzzer for the barcode.ps parser and lazy loader.
 *
 * @file postscriptbarcode_fuzzer_load.c
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

#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "postscriptbarcode.h"
#include "postscriptbarcode_private.h"  /* _bwipp_load_from_fp */

int LLVMFuzzerTestOneInput(const uint8_t *buf, size_t len) {

	FILE *f;
	BWIPP *ctx;
	char *out;

	f = fmemopen((void *)buf, len, "rb");
	if (!f)
		return 0;

	/* Eager load */
	ctx = _bwipp_load_from_fp(f, bwipp_iDEFAULT, 0);
	if (ctx) {
		unsigned int count;
		const char **list;

		(void)bwipp_get_version(ctx);

		list = bwipp_list_encoders(ctx, &count);
		bwipp_free((void *)list);

		list = bwipp_list_families(ctx, &count);
		bwipp_free((void *)list);

		out = bwipp_emit_all_resources(ctx);
		bwipp_free(out);

		bwipp_unload(ctx);
	}

	/* Lazy load */
	f = fmemopen((void *)buf, len, "rb");
	if (!f)
		return 0;

	ctx = _bwipp_load_from_fp(f, bwipp_iLAZY_LOAD, 0);
	if (ctx) {
		(void)bwipp_get_version(ctx);

		out = bwipp_emit_all_resources(ctx);
		bwipp_free(out);

		bwipp_unload(ctx);
	}

	return 0;
}
