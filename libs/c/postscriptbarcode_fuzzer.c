/*
 * libpostscriptbarcode - postscriptbarcode_fuzzer.c
 *
 * @file postscriptbarcode_fuzzer.c
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

#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "postscriptbarcode.h"

#define BARCODE_PS "../../build/monolithic/barcode.ps"

int LLVMFuzzerTestOneInput(const uint8_t *buf, size_t len) {

	static BWIPP *ctx = NULL;
	const char *sep1, *sep2;
	char *name, *data, *options, *out;
	const char *end;

	if (!ctx) {
		bwipp_load_init_opts_t opts = {
			.struct_size = sizeof(opts),
			.filename = BARCODE_PS,
		};
		ctx = bwipp_load_ex(&opts);
		assert(ctx);
		assert(bwipp_get_version(ctx) != NULL);
	}

	if (len == 0)
		return 0;

	/*
	 *  Split input at NUL bytes into up to three fields:
	 *    name \0 data \0 options
	 *
	 *  Missing fields default to empty strings.
	 */
	end = (const char *)buf + len;

	sep1 = memchr(buf, '\0', len);
	if (!sep1)
		sep1 = end;

	sep2 = (sep1 < end) ? memchr(sep1 + 1, '\0', (size_t)(end - sep1 - 1)) : NULL;
	if (!sep2)
		sep2 = end;

	name = malloc((size_t)(sep1 - (const char *)buf) + 1);
	if (!name) return 0;
	memcpy(name, buf, (size_t)(sep1 - (const char *)buf));
	name[sep1 - (const char *)buf] = '\0';

	if (sep1 < end) {
		size_t dlen = (size_t)(sep2 - sep1 - 1);
		data = malloc(dlen + 1);
		if (!data) { free(name); return 0; }
		memcpy(data, sep1 + 1, dlen);
		data[dlen] = '\0';
	} else {
		data = malloc(1);
		if (!data) { free(name); return 0; }
		data[0] = '\0';
	}

	if (sep2 < end) {
		size_t olen = (size_t)(end - sep2 - 1);
		options = malloc(olen + 1);
		if (!options) { free(name); free(data); return 0; }
		memcpy(options, sep2 + 1, olen);
		options[olen] = '\0';
	} else {
		options = malloc(1);
		if (!options) { free(name); free(data); return 0; }
		options[0] = '\0';
	}

	/* Exercise bwipp_emit_required_resources */
	out = bwipp_emit_required_resources(ctx, name);
	bwipp_free(out);

	/* Exercise bwipp_emit_exec */
	out = bwipp_emit_exec(ctx, name, data, options);
	bwipp_free(out);

	/* Exercise property queries with fuzzed name and data as key */
	{
		const char **props = bwipp_list_properties(ctx, name, NULL);
		if (props) {
			unsigned int i;
			for (i = 0; props[i]; i++)
				(void)bwipp_get_property(ctx, name, props[i]);
			bwipp_free((void *)props);
		}
		/* Fuzz the key too */
		(void)bwipp_get_property(ctx, name, data);
	}

	/* Exercise family queries with fuzzed name as family */
	{
		const char **members = bwipp_list_family_members(ctx, name, NULL);
		bwipp_free((void *)members);
		/* Also try data as a family name */
		members = bwipp_list_family_members(ctx, data, NULL);
		bwipp_free((void *)members);
	}

	free(name);
	free(data);
	free(options);

	return 0;
}
