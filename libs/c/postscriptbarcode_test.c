/*
 * libpostscriptbarcode
 *
 * @file postscriptbarcode_test.c
 * @author Copyright (c) 2004-2022 Terry Burton.
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
#pragma warning(disable: ALL_CODE_ANALYSIS_WARNINGS)
#endif

// Disabled for now
#define TEST_NO_MAIN
#include "acutest.h"

#if defined(__clang__)
#pragma clang diagnostic pop
#elif defined(__GNUC__)
#pragma GCC diagnostic pop
#elif defined(_MSC_VER)
#pragma warning(pop)
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "postscriptbarcode.h"

int main() {

	BWIPP *ctx, *ctx2;

	char *name = "databaromni";
	char *data = "THIS IS CODE 39";
	char *options = "includetext";
	char *tmp, *ps, *abc;
	char **families;
	unsigned int num_families, i;
	char *families_str, *members_str, *properties_str;

	ctx = bwipp_load_from_file("../../build/monolithic/barcode.ps");
	ctx2 = bwipp_load_from_file("../../build/monolithic_package/barcode.ps");

	printf("Version: %s\n", bwipp_get_version(ctx));
	printf("Version: %s\n", bwipp_get_version(ctx2));

	tmp = bwipp_emit_required_resources(ctx, name);
	ps = malloc(strlen(tmp) + 1000 * sizeof(char));
	ps[0] = '\0';
	strcat(ps, "%!PS\n");
	strcat(ps, tmp);
	bwipp_free(tmp);
	strcat(ps, "gsave\n");
	strcat(ps, "50 150 translate\n");
	tmp = bwipp_emit_exec(ctx, name, data, options);
	strcat(ps, tmp);
	bwipp_free(tmp);
	strcat(ps, "grestore\n");
	/*	printf("%s\n", ps); */
	bwipp_free(ps);

	abc = bwipp_emit_all_resources(ctx);
	/*	printf("%s", abc); */

	bwipp_free(abc);

	families_str = bwipp_list_families_as_string(ctx);
	//	printf("%s\n", families_str);
	bwipp_free(families_str);

	members_str = bwipp_list_family_members_as_string(ctx, "Two-dimensional");
	//	printf("%s\n", members_str);
	bwipp_free(members_str);

	properties_str = bwipp_list_properties_as_string(ctx, "qrcode");
	//	printf("%s\n", properties_str);
	bwipp_free(properties_str);

	num_families = bwipp_list_families(ctx, &families);
	for (i = 0; i < num_families; i++) {
		char **members;
		unsigned int num_members, j;
		char *family = families[i];
		//		printf("***%s***\n", family);
		num_members = bwipp_list_family_members(ctx, &members, family);
		for (j = 0; j < num_members; j++) {
			char **properties;
			unsigned int num_properties, k;
			char *bcname = members[j];
			//			printf("--%s--\n", bcname);
			num_properties = bwipp_list_properties(ctx, &properties, bcname);
			for (k = 0; k < num_properties; k++) {
				const char *val = bwipp_get_property(ctx, bcname, properties[k]);
				(void)val;
//								printf("%s: %s\n", properties[k], val);
			}
			bwipp_free(properties);
		}
		bwipp_free(members);
	}
	bwipp_free(families);

	bwipp_unload(ctx);
	bwipp_unload(ctx2);

	return 0;
}

/*
static void test_api_bwipp_load_from_file(void) {

	BWIPP *ctx;

	TEST_CHECK((ctx = bwipp_load_from_file("../../build/monolithic/barcode.ps")) != NULL);

	bwipp_unload(ctx);

}


static void test_api_bwipp_unload(void) {

	BWIPP *ctx;

	TEST_ASSERT((ctx = bwipp_load_from_file("../../build/monolithic/barcode.ps")) != NULL);
	bwipp_unload(ctx);
	TEST_CHECK(ctx == NULL);

}

TEST_LIST = {
    { "bwipp_load_from_file", test_api_bwipp_load_from_file },
    { "bwipp_unload", test_api_bwipp_unload },

    { NULL, NULL }
};
*/
