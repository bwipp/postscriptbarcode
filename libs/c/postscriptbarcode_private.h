/*
 * libpostscriptbarcode - postscriptbarcode_private.h
 *
 * @file postscriptbarcode_private.h
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

#ifndef BWIPP_PRIVATE_H
#define BWIPP_PRIVATE_H

#include "postscriptbarcode.h"
#include <stddef.h>

typedef struct Property {
	char *key, *value;
} Property;

typedef struct PropertyList {
	Property *entry;
	struct PropertyList *next;
} PropertyList;

typedef struct Resource {
	char *type, *name, *reqs, *code;
	size_t code_len;
	long code_offset;		/* File offset for lazy loading (-1 if eager) */
	unsigned int numprops;
	PropertyList *props;
	PropertyList **props_tail;
} Resource;

typedef struct ResourceList {
	Resource *entry;
	struct ResourceList *next;
} ResourceList;

typedef struct Family {
	char *name;
	const char **members;	/* NULL-terminated; pointers into Resource names */
	unsigned int count;
} Family;

typedef struct FamilyList {
	Family *entry;
	struct FamilyList *next;
} FamilyList;

#endif  /* BWIPP_PRIVATE_H */
