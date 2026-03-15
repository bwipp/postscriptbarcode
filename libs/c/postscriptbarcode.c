/*
 * libpostscriptbarcode - postscriptbarcode.c
 *
 * @file postscriptbarcode.c
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

#include "postscriptbarcode.h"
#include "postscriptbarcode_private.h"
#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LINE 512
#define MAX_CODE 2000000
#define HEXIFY_WIDTH 72

/* Safe string append with bounds checking; returns false on overflow */
static bool safe_append_n(char *buf, size_t *pos, size_t capacity, const char *src, size_t src_len) {
	if (*pos + src_len >= capacity)
		return false;
	memcpy(buf + *pos, src, src_len + 1);
	*pos += src_len;
	return true;
}

struct BWIPP {
	char *version;
	ResourceList *resourcelist;	/* Singly-linked list of resources */
	unsigned int numresources;
	unsigned int numencoders;
	FamilyList *familylist;		/* Built at load time from FMLY properties */
	unsigned int numfamilies;
	FILE *f;			/* Held open for lazy loading, else NULL */
};

/* Extract option from opts struct, respecting struct_size for forward compat */
#define EXTRACT_OPT(f) do {								\
	if (opts && opts->struct_size >=							\
	    offsetof(bwipp_load_init_opts_t, f) + sizeof(opts->f))			\
		f = opts->f;								\
} while (0)

/*
 *	TODO Differentiate by OS
 */
static const char *default_filename = "/usr/share/postscriptbarcode/barcode.ps";

static const char hex_lut[] =
	"000102030405060708090A0B0C0D0E0F"
	"101112131415161718191A1B1C1D1E1F"
	"202122232425262728292A2B2C2D2E2F"
	"303132333435363738393A3B3C3D3E3F"
	"404142434445464748494A4B4C4D4E4F"
	"505152535455565758595A5B5C5D5E5F"
	"606162636465666768696A6B6C6D6E6F"
	"707172737475767778797A7B7C7D7E7F"
	"808182838485868788898A8B8C8D8E8F"
	"909192939495969798999A9B9C9D9E9F"
	"A0A1A2A3A4A5A6A7A8A9AAABACADAEAF"
	"B0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF"
	"C0C1C2C3C4C5C6C7C8C9CACBCCCDCECF"
	"D0D1D2D3D4D5D6D7D8D9DADBDCDDDEDF"
	"E0E1E2E3E4E5E6E7E8E9EAEBECEDEEEF"
	"F0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF";

static char *pshexstr(const char *in, size_t *out_len) {
	char *out, *hex;
	unsigned int count = 1, i;
	size_t len, alloc;

	assert(in);

	len = strlen(in);
	if (len > SIZE_MAX / 3)
		return NULL;

	/* 2 hex chars per byte, plus newline+space every HEXIFY_WIDTH chars */
	alloc = 2 * len + 2 * (len / (HEXIFY_WIDTH / 2) + 1) + 3;
	out = malloc(alloc);
	if (!out)
		return NULL;

	hex = out;

	*hex++ = '<';
	for (i = 0; i < len; i++) {
		if (count >= HEXIFY_WIDTH) {
			*hex++ = '\n';
			count = 0;
		}
		if (!count) {
			*hex++ = ' ';
			count++;
		}
		memcpy(hex, &hex_lut[(unsigned char)in[i] * 2], 2);
		hex += 2;
		count += 2;
	}
	*hex++ = '>';
	*hex = '\0';

	*out_len = (size_t)(hex - out);

	{
		char *tmp = realloc(out, *out_len + 1);
		if (tmp)
			out = tmp;
	}

	return out;
}

static const Resource *get_resource(BWIPP *ctx, const char *name) {
	ResourceList *curr;

	for (curr = ctx->resourcelist; curr; curr = curr->next) {
		if (strcmp(curr->entry->name, name) == 0)
			return curr->entry;
	}

	return NULL;
}

/* Read resource body from file on demand; returns NULL on I/O error */
static char *load_code(BWIPP *ctx, const Resource *resource) {
	char *code;

	if (resource->code_offset < 0 || !ctx->f)
		return NULL;

	code = malloc(resource->code_len + 1);
	if (!code)
		return NULL;

	if (fseek(ctx->f, resource->code_offset, SEEK_SET) != 0) {
		free(code);
		return NULL;
	}

	if (fread(code, 1, resource->code_len, ctx->f) != resource->code_len) {
		free(code);
		return NULL;
	}

	code[resource->code_len] = '\0';
	return code;
}

static const char *get_resource_property(const Resource *resource, const char *key) {
	const PropertyList *curr;
	for (curr = resource->props; curr; curr = curr->next) {
		if (strcmp(curr->entry->key, key) == 0)
			return curr->entry->value;
	}
	return NULL;
}

static bool add_property(Resource *resource, const char *key, const char *value) {
	Property *prop;
	PropertyList *node;

	prop = malloc(sizeof(Property));
	if (!prop)
		return false;
	prop->key = strdup(key);
	prop->value = strdup(value);
	if (!prop->key || !prop->value) {
		free(prop->key);
		free(prop->value);
		free(prop);
		return false;
	}

	node = malloc(sizeof(PropertyList));
	if (!node) {
		free(prop->key);
		free(prop->value);
		free(prop);
		return false;
	}
	node->entry = prop;
	node->next = NULL;
	*resource->props_tail = node;
	resource->props_tail = &node->next;
	resource->numprops++;

	return true;
}

static void free_properties(PropertyList *props) {
	while (props) {
		PropertyList *next = props->next;
		free(props->entry->key);
		free(props->entry->value);
		free(props->entry);
		free(props);
		props = next;
	}
}

static void free_families(FamilyList *families) {
	while (families) {
		FamilyList *next = families->next;
		free(families->entry->name);
		free(families->entry->members);
		free(families->entry);
		free(families);
		families = next;
	}
}

static FamilyList *find_family(FamilyList *list, const char *name) {
	while (list) {
		if (strcmp(list->entry->name, name) == 0)
			return list;
		list = list->next;
	}
	return NULL;
}

/* Build family index from FMLY properties on ENCODER resources */
static bool build_families(BWIPP *ctx) {
	ResourceList *rcurr;
	FamilyList **tail;

	ctx->familylist = NULL;
	ctx->numfamilies = 0;
	tail = &ctx->familylist;

	for (rcurr = ctx->resourcelist; rcurr; rcurr = rcurr->next) {
		const char *fmly;
		FamilyList *fnode;
		PropertyList *pcurr;
		const char **tmp;

		if (strcmp(rcurr->entry->type, "ENCODER") != 0)
			continue;

		fmly = NULL;
		for (pcurr = rcurr->entry->props; pcurr; pcurr = pcurr->next) {
			if (strcmp(pcurr->entry->key, "FMLY") == 0) {
				fmly = pcurr->entry->value;
				break;
			}
		}
		if (!fmly)
			continue;

		fnode = find_family(ctx->familylist, fmly);
		if (!fnode) {
			Family *fam = calloc(1, sizeof(Family));
			if (!fam)
				return false;
			fam->name = strdup(fmly);
			if (!fam->name) {
				free(fam);
				return false;
			}

			fnode = malloc(sizeof(FamilyList));
			if (!fnode) {
				free(fam->name);
				free(fam);
				return false;
			}
			fnode->entry = fam;
			fnode->next = NULL;
			*tail = fnode;
			tail = &fnode->next;
			ctx->numfamilies++;
		}

		tmp = realloc(fnode->entry->members,
			      (fnode->entry->count + 2) * sizeof(const char *));
		if (!tmp)
			return false;
		fnode->entry->members = tmp;
		fnode->entry->members[fnode->entry->count++] = rcurr->entry->name;
		fnode->entry->members[fnode->entry->count] = NULL;
	}

	return true;
}

BWIPP_API void bwipp_free(void *p) { free(p); }

BWIPP_API BWIPP *bwipp_load(void) {
	/* TODO search a set of default paths */
	return bwipp_load_ex(NULL);
}

BWIPP_API BWIPP *bwipp_load_ex(const bwipp_load_init_opts_t *opts) {
	BWIPP *ctx;
	FILE *f;
	const char *filename = NULL;
	bwipp_load_init_flags_t flags = bwipp_iDEFAULT;

	ResourceList **tail;
	Resource *resource = NULL;
	char buf[MAX_LINE];
	char *code = NULL;
	size_t code_len = 0;
	long code_start = 0;
	bool skip;
	bool lazy;

	EXTRACT_OPT(filename);
	EXTRACT_OPT(flags);
	if (!filename)
		filename = default_filename;

	lazy = (flags & bwipp_iLAZY_LOAD) != 0;

	ctx = malloc(sizeof(BWIPP));
	if (!ctx)
		return NULL;

	ctx->version = NULL;
	ctx->resourcelist = NULL;
	ctx->numresources = 0;
	ctx->numencoders = 0;
	ctx->familylist = NULL;
	ctx->numfamilies = 0;
	ctx->f = NULL;
	tail = &ctx->resourcelist;

	f = fopen(filename, "r");
	if (!f)
		goto error;

	if (!lazy) {
		code = malloc(MAX_CODE);
		if (!code)
			goto error;
	}

	skip = true;
	while (fgets(buf, sizeof buf, f)) {
		size_t line_len = strlen(buf);

		/* Reject marker lines truncated by fgets */
		if (strncmp(buf, "% --", 4) == 0 &&
				(line_len == 0 || buf[line_len - 1] != '\n'))
			goto error;

		if (skip) {
			if (strcmp(buf, "% --BEGIN TEMPLATE--\n") == 0)
				skip = false;
			if (!ctx->version &&
					strncmp(buf, "% Barcode Writer in Pure PostScript", 35) == 0) {
				const char *version;
				char *p;
				p = strrchr(buf, ' ');
				if (!p)
					goto error;
				version = p + 1;
				p = strchr((char *)version, '\n');
				if (p)
					*p = '\0';
				ctx->version = strdup(version);
				if (!ctx->version)
					goto error;
			}
			continue;
		}

		if (strcmp(buf, "% --END TEMPLATE--\n") == 0)
			break;

		/* % --BEGIN {TYPE} {NAME}-- */
		if (strncmp(buf, "% --BEGIN ", 10) == 0) {

			const char *type, *name;
			char *p;

			if (resource)
				goto error;

			type = buf + 10;
			p = strchr((char *)type, ' ');
			if (!p)
				goto error;
			*p = '\0';
			name = p + 1;
			p = strrchr((char *)name, '-');
			if (!p || p <= name)
				goto error;
			*(p - 1) = '\0';

			resource = calloc(1, sizeof(Resource));
			if (!resource)
				goto error;
			resource->props_tail = &resource->props;

			resource->type = strdup(type);
			if (!resource->type)
				goto error;
			resource->name = strdup(name);
			if (!resource->name)
				goto error;
			resource->code_offset = -1;

			if (code)
				*code = '\0';
			code_len = 0;
			code_start = ftell(f);

			continue;

		} /* BEGIN */

		/* % --KEY: VALUE (metadata comments) */
		if (resource && strncmp(buf, "% --", 4) == 0 && strchr(buf + 4, ':')) {
			const char *key;
			char *value, *p;

			key = buf + 4;
			p = strchr((char *)key, ':');

			/* Only match if the key is uppercase alpha (not REQUIRES, BEGIN, END) */
			if (p && p > key && *(p - 1) != '-') {
				*p = '\0';
				value = p + 1;
				if (*value == ' ')
					value++;
				p = strchr(value, '\n');
				if (p)
					*p = '\0';
				if (!add_property(resource, key, value))
					goto error;
				code_start = ftell(f);
				continue;
			}
		}

		/* % --REQUIRES {REQS}-- */
		if (strncmp(buf, "% --REQUIRES ", 13) == 0) {

			const char *reqs;
			char *p;

			if (!resource || resource->reqs)
				goto error;

			reqs = buf + 13;
			p = strrchr((char *)reqs, '-');
			if (!p || p <= reqs)
				goto error;
			*(p - 1) = '\0';
			resource->reqs = strdup(reqs);
			if (!resource->reqs)
				goto error;

			code_start = ftell(f);
			continue;

		} /* REQUIRES */

		/* % --END {TYPE} {NAME}-- */
		if (strncmp(buf, "% --END ", 8) == 0) {

			const char *type, *name;
			char *p;

			if (!resource)
				goto error;

			type = buf + 8;
			p = strchr((char *)type, ' ');
			if (!p)
				goto error;
			*p = '\0';
			name = p + 1;
			p = strrchr((char *)name, '-');
			if (!p || p <= name)
				goto error;
			*(p - 1) = '\0';

			if (strcmp(resource->type, type) != 0)
				goto error;
			if (strcmp(resource->name, name) != 0)
				goto error;

			if (lazy) {
				resource->code = NULL;
				resource->code_offset = code_start;
			} else {
				resource->code = strdup(code);
				if (!resource->code)
					goto error;
				*code = '\0';
			}
			resource->code_len = code_len;
			code_len = 0;

			/* Add to ResourceList */
			{
				ResourceList *node = malloc(sizeof(ResourceList));
				if (!node)
					goto error;
				node->entry = resource;
				node->next = NULL;
				*tail = node;
				tail = &node->next;
			}

			if (strcmp(resource->type, "ENCODER") == 0)
				ctx->numencoders++;
			resource = NULL;
			ctx->numresources++;

			continue;

		} /* END */

		/* PS Code */
		if (resource) {
			if (lazy) {
				code_len += line_len;
			} else {
				if (!safe_append_n(code, &code_len, MAX_CODE, buf, line_len))
					goto error;
			}
		}
	}

	/* Finished without seeing an END RESOURCE for the current resource! */
	if (resource)
		goto error;

	if (lazy)
		ctx->f = f;	/* Hold open for on-demand reads */
	else
		fclose(f);
	free(code);

	if (!build_families(ctx))
		goto error_post_parse;

	return ctx;

error_post_parse:

	bwipp_unload(ctx);
	return NULL;

error:

	if (f)
		fclose(f);
	if (resource) {
		free(resource->type);
		free(resource->name);
		free(resource->reqs);
		free(resource->code);
		free_properties(resource->props);
	}
	free(resource);

	free(code);
	bwipp_unload(ctx);

	return NULL;
}

BWIPP_API BWIPP *bwipp_load_from_file(const char *filename) {
	bwipp_load_init_opts_t opts = {
		.struct_size = sizeof(opts),
		.filename = filename,
	};
	return bwipp_load_ex(&opts);
}


BWIPP_API void bwipp_unload(BWIPP *ctx) {
	ResourceList *curr;

	assert(ctx);

	curr = ctx->resourcelist;

	while (curr) {
		ResourceList *next = curr->next;
		free(curr->entry->type);
		free(curr->entry->name);
		free(curr->entry->reqs);
		free(curr->entry->code);
		free_properties(curr->entry->props);
		free(curr->entry);
		free(curr);
		curr = next;
	}

	ctx->resourcelist = NULL;

	free_families(ctx->familylist);
	ctx->familylist = NULL;

	if (ctx->f) {
		fclose(ctx->f);
		ctx->f = NULL;
	}

	free(ctx->version);
	free(ctx);
}

BWIPP_API const char *bwipp_get_version(BWIPP *ctx) {
	assert(ctx);

	return ctx->version;
}

static int cmp_str(const void *a, const void *b) {
	return strcmp(*(const char **)a, *(const char **)b);
}

BWIPP_API const char **bwipp_list_encoders(BWIPP *ctx, unsigned int *count) {
	ResourceList *curr;
	const char **list;
	unsigned int i = 0;

	assert(ctx);

	list = malloc((ctx->numencoders + 1) * sizeof(const char *));
	if (!list)
		return NULL;

	for (curr = ctx->resourcelist; curr; curr = curr->next) {
		if (strcmp(curr->entry->type, "ENCODER") == 0)
			list[i++] = curr->entry->name;
	}
	list[i] = NULL;

	qsort(list, ctx->numencoders, sizeof(const char *), cmp_str);

	if (count)
		*count = ctx->numencoders;

	return list;
}

BWIPP_API const char **bwipp_list_properties(BWIPP *ctx, const char *name,
					     unsigned int *count) {
	const Resource *resource;
	const PropertyList *curr;
	const char **list;
	unsigned int i = 0;

	assert(ctx);
	assert(name);

	resource = get_resource(ctx, name);
	if (!resource)
		return NULL;

	list = malloc((resource->numprops + 1) * sizeof(const char *));
	if (!list)
		return NULL;

	for (curr = resource->props; curr; curr = curr->next)
		list[i++] = curr->entry->key;
	list[i] = NULL;

	if (count)
		*count = resource->numprops;

	return list;
}

BWIPP_API const char *bwipp_get_property(BWIPP *ctx, const char *name,
					 const char *key) {
	const Resource *resource;

	assert(ctx);
	assert(name);
	assert(key);

	resource = get_resource(ctx, name);
	if (!resource)
		return NULL;

	return get_resource_property(resource, key);
}

BWIPP_API const char **bwipp_list_families(BWIPP *ctx, unsigned int *count) {
	FamilyList *curr;
	const char **list;
	unsigned int i = 0;

	assert(ctx);

	list = malloc((ctx->numfamilies + 1) * sizeof(const char *));
	if (!list)
		return NULL;

	for (curr = ctx->familylist; curr; curr = curr->next)
		list[i++] = curr->entry->name;
	list[i] = NULL;

	qsort(list, ctx->numfamilies, sizeof(const char *), cmp_str);

	if (count)
		*count = ctx->numfamilies;

	return list;
}

typedef struct {
	const char *name;
	const char *desc;
} NameDesc;

static int cmp_name_desc(const void *a, const void *b) {
	const NameDesc *na = (const NameDesc *)a;
	const NameDesc *nb = (const NameDesc *)b;
	const char *da = na->desc ? na->desc : na->name;
	const char *db = nb->desc ? nb->desc : nb->name;
	return strcmp(da, db);
}

BWIPP_API const char **bwipp_list_family_members(BWIPP *ctx,
						 const char *family,
						 unsigned int *count) {
	FamilyList *curr;
	const char **list;
	NameDesc *pairs;
	unsigned int i, n;

	assert(ctx);
	assert(family);

	for (curr = ctx->familylist; curr; curr = curr->next) {
		if (strcmp(curr->entry->name, family) == 0)
			break;
	}
	if (!curr)
		return NULL;

	n = curr->entry->count;

	pairs = malloc(n * sizeof(NameDesc));
	if (!pairs)
		return NULL;

	for (i = 0; i < n; i++) {
		const Resource *res = get_resource(ctx, curr->entry->members[i]);
		pairs[i].name = curr->entry->members[i];
		pairs[i].desc = res ? get_resource_property(res, "DESC") : NULL;
	}

	qsort(pairs, n, sizeof(NameDesc), cmp_name_desc);

	list = malloc((n + 1) * sizeof(const char *));
	if (!list) {
		free(pairs);
		return NULL;
	}

	for (i = 0; i < n; i++)
		list[i] = pairs[i].name;
	list[n] = NULL;

	free(pairs);

	if (count)
		*count = n;

	return list;
}

/* Append a resource's code to output buffer, loading from disk if lazy */
static bool append_resource_code(BWIPP *ctx, const Resource *res,
				 char *buf, size_t *pos, size_t capacity) {
	if (res->code) {
		return safe_append_n(buf, pos, capacity, res->code, res->code_len);
	} else {
		char *lazy_code = load_code(ctx, res);
		bool ok;
		if (!lazy_code)
			return false;
		ok = safe_append_n(buf, pos, capacity, lazy_code, res->code_len);
		free(lazy_code);
		return ok;
	}
}

BWIPP_API char *bwipp_emit_required_resources(BWIPP *ctx, const char *name) {
	char *code = NULL, *reqs, *tmp, *saveptr = NULL;
	const char *req;
	size_t code_len = 0;
	const Resource *resource, *res;

	resource = get_resource(ctx, name);
	if (!resource) {  /* Resource not found */
		tmp = strdup("");
		if (!tmp)
			goto error;
		return tmp;  /* Copy of empty string */
	}

	code = malloc(MAX_CODE);
	if (!code)
		goto error;
	*code = '\0';

	/* Add code for required resources */
	if (resource->reqs) {
		reqs = strdup(resource->reqs);
		if (!reqs)
			goto error;
		req = strtok_r(reqs, " ", &saveptr);
		while (req) {
			res = get_resource(ctx, req);
			if (!res) {
				req = strtok_r(NULL, " ", &saveptr);
				continue;  /* Ignore missing requisites */
			}
			if (!append_resource_code(ctx, res, code, &code_len, MAX_CODE)) {
				free(reqs);
				goto error;
			}
			req = strtok_r(NULL, " ", &saveptr);
		}
		free(reqs);
	}

	/* Add code for this resource */
	if (!append_resource_code(ctx, resource, code, &code_len, MAX_CODE))
		goto error;

	tmp = realloc(code, code_len + 1);
	if (!tmp)
		goto error;
	return tmp;

error:

	free(code);

	return NULL;
}

BWIPP_API char *bwipp_emit_all_resources(BWIPP *ctx) {
	ResourceList *curr;
	char *code, *tmp;
	size_t code_len = 0;

	assert(ctx);

	curr = ctx->resourcelist;

	assert(ctx->resourcelist);

	code = malloc(MAX_CODE);
	if (!code)
		return NULL;

	*code = '\0';
	while (curr) {
		if (!append_resource_code(ctx, curr->entry, code, &code_len, MAX_CODE)) {
			free(code);
			return NULL;
		}
		curr = curr->next;
	}

	tmp = realloc(code, code_len + 1);

	return tmp ? tmp : code;
}

BWIPP_API char *bwipp_emit_exec(BWIPP *ctx, const char *name, const char *data,
				const char *options) {
	static const char fmt[] =
		"0 0 moveto\n"
		"%s\n"
		"%s\n"
		"/%s /uk.co.terryburton.bwipp findresource exec\n";
	char *call = NULL, *data_h = NULL, *options_h = NULL;
	size_t data_h_len, options_h_len;

	assert(ctx);
	assert(name);
	assert(data);
	assert(options);

	data_h = pshexstr(data, &data_h_len);
	options_h = pshexstr(options, &options_h_len);

	if (data_h && options_h) {
		size_t alloc = sizeof(fmt) + data_h_len + options_h_len + strlen(name);
		call = malloc(alloc);
		if (call)
			snprintf(call, alloc, fmt, data_h, options_h, name);
	}

	free(data_h);
	free(options_h);

	return call;
}
