/*
 * libpostscriptbarcode - postscriptbarcode.c
 *
 * @file postscriptbarcode_private.h
 * @author Copyright (c) 2004-2023 Terry Burton.
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

typedef struct Property {
  char *key, *value;
} Property;

typedef struct PropertyList {
  Property *entry;
  struct PropertyList *next;
} PropertyList;

typedef struct Resource {
  char *type, *name, *reqs, *code;
  unsigned int numprops;
  PropertyList *props;
} Resource;

typedef struct ResourceList {
  Resource *entry;
  struct ResourceList *next;
} ResourceList;

#endif /* BWIPP_PRIVATE_H */
