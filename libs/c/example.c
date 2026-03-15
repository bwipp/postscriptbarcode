/*
 * libpostscriptbarcode - example.c
 *
 * @file example.c
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
#include <string.h>

#include <postscriptbarcode.h>

static unsigned int count_lines(const char *s) {
	unsigned int n = 0;
	while (*s)
		if (*s++ == '\n')
			n++;
	return n;
}

int main(int argc, char *argv[]) {
	BWIPP *bwipp, *bwipp1 = NULL;
	const char **list;
	char *ps;
	unsigned int count, i;

	if (argc > 1) {
		bwipp_load_init_opts_t opts = {
			.struct_size = sizeof(opts),
			.filename = argv[1],
		};
		bwipp = bwipp_load_ex(&opts);
		if (!bwipp) {
			fprintf(stderr, "Failed to load resource\n");
			return 1;
		}
		printf("Version: %s\n", bwipp_get_version(bwipp));
	} else {
		bwipp_load_init_opts_t opts1 = {
			.struct_size = sizeof(opts1),
			.filename = "../../build/monolithic_package/barcode.ps",
		};
		bwipp_load_init_opts_t opts2 = {
			.struct_size = sizeof(opts2),
			.filename = "../../build/monolithic/barcode.ps",
		};

		bwipp1 = bwipp_load_ex(&opts1);
		if (!bwipp1) {
			fprintf(stderr, "Failed to load packaged resource\n");
			return 1;
		}

		bwipp = bwipp_load_ex(&opts2);
		if (!bwipp) {
			fprintf(stderr, "Failed to load resource\n");
			bwipp_unload(bwipp1);
			return 1;
		}

		printf("Packaged version: %s\n", bwipp_get_version(bwipp1));
		printf("Unpackaged version: %s\n", bwipp_get_version(bwipp));

		ps = bwipp_emit_all_resources(bwipp1);
		printf("Packaged lines: %u\n", count_lines(ps));
		bwipp_free(ps);
	}

	ps = bwipp_emit_all_resources(bwipp);
	printf("Unpackaged lines: %u\n", count_lines(ps));
	bwipp_free(ps);

	ps = bwipp_emit_required_resources(bwipp, "qrcode");
	printf("qrcode resource lines: %u\n", count_lines(ps));
	bwipp_free(ps);

	ps = bwipp_emit_exec(bwipp, "qrcode", "Hello World", "eclevel=M");
	printf("emit_exec lines: %u\n", count_lines(ps));
	bwipp_free(ps);

	list = bwipp_list_encoders(bwipp, &count);
	printf("Encoders: %u\n", count);
	bwipp_free((void *)list);

	list = bwipp_list_families(bwipp, &count);
	printf("Families: %u\n", count);
	for (i = 0; i < count; i++) {
		const char *family = list[i];
		const char **members;
		unsigned int mcount;
		members = bwipp_list_family_members(bwipp, family, &mcount);
		printf("  %s: %u members\n", family, mcount);
		bwipp_free((void *)members);
	}
	bwipp_free((void *)list);

	list = bwipp_list_properties(bwipp, "qrcode", &count);
	printf("qrcode properties: %u\n", count);
	for (i = 0; i < count; i++)
		printf("  %s: %s\n", list[i],
		       bwipp_get_property(bwipp, "qrcode", list[i]));
	bwipp_free((void *)list);

	/* Lazy loading: resource bodies read on demand, not at load time */
	{
		BWIPP *lazy;
		char *lazy_ps;
		bwipp_load_init_opts_t lazy_opts = {
			.struct_size = sizeof(lazy_opts),
			.filename = argc > 1 ? argv[1]
				: "../../build/monolithic/barcode.ps",
			.flags = bwipp_iLAZY_LOAD,
		};

		lazy = bwipp_load_ex(&lazy_opts);
		if (!lazy) {
			fprintf(stderr, "Failed to lazy load resource\n");
			if (bwipp1)
				bwipp_unload(bwipp1);
			bwipp_unload(bwipp);
			return 1;
		}

		printf("Lazy version: %s\n", bwipp_get_version(lazy));

		lazy_ps = bwipp_emit_required_resources(lazy, "qrcode");
		printf("Lazy qrcode resource lines: %u\n", count_lines(lazy_ps));
		bwipp_free(lazy_ps);

		bwipp_unload(lazy);
	}

	/* Hex string encoding */
	{
		char *hex;
		hex = bwipp_emit_pshexstr(bwipp, "Hello");
		printf("Hex string: %s\n", hex);
		bwipp_free(hex);
	}

	/* Template-based output */
	{
		char *tmpl;
		tmpl = bwipp_emit_template(bwipp,
			"%dat %opt %enc /uk.co.terryburton.bwipp findresource exec",
			"qrcode", "Hello World", "eclevel=M");
		printf("Template lines: %u\n", count_lines(tmpl));
		bwipp_free(tmpl);
	}

	if (bwipp1)
		bwipp_unload(bwipp1);
	bwipp_unload(bwipp);

	return 0;
}
