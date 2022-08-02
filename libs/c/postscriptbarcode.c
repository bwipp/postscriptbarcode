/*
 * libpostscriptbarcode - postscriptbarcode.c
 *
 * @file postscriptbarcode.c
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

#include "postscriptbarcode.h"
#include "postscriptbarcode_private.h"
#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LINE 200
#define MAX_CODE 2000000
#define HEXIFY_WIDTH 72

struct BWIPP {
  char *version;
  ResourceList *resourcelist; // Singly-linked list of resources
  unsigned int numresources;
};

/*
 *  TODO Differentiate by OS
 */
static const char *default_filename = "/usr/share/postscriptbarcode/barcode.ps";

static char *pshexstr(const char *in) {

  char *out, *hex;
  unsigned int count = 1, i;

  assert(in);

  out = malloc(3 * strlen(in) + 3);
  if (!out)
    return NULL;

  hex = out;

  hex += sprintf(hex, "<");
  for (i = 0; i < strlen(in); i++) {
    if (count >= HEXIFY_WIDTH) {
      hex += sprintf(hex, "\n");
      count = 0;
    }
    if (!count) {
      hex += sprintf(hex, " ");
      count++;
    }
    hex += sprintf(hex, "%02X", in[i]);
    count += 2;
  }
  hex += sprintf(hex, ">");
  hex++;

  out = realloc(out, (size_t)(hex - out));

  return out;
}

static const Resource *get_resource(BWIPP *ctx, const char *name) {

  ResourceList *curr = ctx->resourcelist;

  while (curr) {
    if (strcmp(curr->entry->name, name) == 0)
      break;
    curr = curr->next;
  }

  return curr ? curr->entry : NULL;
}

BWIPP_API void bwipp_free(void *p) { free(p); }

BWIPP_API BWIPP *bwipp_load(void) {

  /* TODO search a set of default paths */
  return bwipp_load_from_file(default_filename);
}

BWIPP_API BWIPP *bwipp_load_from_file(const char *filename) {

  BWIPP *ctx;
  FILE *f;

  ResourceList *curr = NULL;
  Resource *resource = NULL;
  char buf[MAX_LINE];
  char *code = NULL;
  bool skip;

  assert(filename);

  ctx = malloc(sizeof(BWIPP));
  if (!ctx)
    return NULL;

  ctx->version = NULL;
  ctx->resourcelist = NULL;
  ctx->numresources = 0;

  f = fopen(filename, "r");
  if (!f)
    goto error;

  code = malloc(MAX_CODE);
  if (!code)
    goto error;

  skip = true;
  while (fgets(buf, sizeof buf, f)) {

    if (skip) {
      if (strcmp(buf, "% --BEGIN TEMPLATE--\n") == 0)
        skip = false;
      if (!ctx->version &&
          strncmp(buf, "% Barcode Writer in Pure PostScript", 35) == 0) {
        char *version, *p;
        p = strrchr(buf, ' ');
        version = p + 1;
        p = strchr(version, '\n');
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

      char *type, *name, *p;

      if (resource)
        goto error;

      type = buf + 10;
      p = strchr(type, ' ');
      *p = '\0';
      name = p + 1;
      p = strrchr(name, '-');
      *(p - 1) = '\0';

      resource = calloc(1, sizeof(Resource));
      if (!resource)
        goto error;

      resource->type = strdup(type);
      if (!resource->type)
        goto error;
      resource->name = strdup(name);
      if (!resource->name)
        goto error;

      *code = '\0';

      continue;

    } /* BEGIN */

    /* % --REQUIRES {REQS}-- */
    if (strncmp(buf, "% --REQUIRES ", 13) == 0) {

      char *reqs, *p;

      if (!resource || resource->reqs)
        goto error;

      reqs = buf + 13;
      p = strrchr(reqs, '-');
      *(p - 1) = '\0';
      resource->reqs = strdup(reqs);
      if (!resource->reqs)
        goto error;

      continue;

    } /* REQUIRES */

    /* % --END {TYPE} {NAME}-- */
    if (strncmp(buf, "% --END ", 8) == 0) {

      char *type, *name, *p;

      if (!resource)
        goto error;

      type = buf + 8;
      p = strchr(type, ' ');
      *p = '\0';
      name = p + 1;
      p = strrchr(name, '-');
      *(p - 1) = '\0';

      if (strcmp(resource->type, type) != 0)
        goto error;
      if (strcmp(resource->name, name) != 0)
        goto error;

      resource->code = strdup(code);
      if (!resource->code)
        goto error;

      *code = '\0';

      /* Add to ResourceList */
      if (!ctx->resourcelist) {
        ctx->resourcelist = malloc(sizeof(ResourceList));
        if (!ctx->resourcelist)
          goto error;
        ctx->resourcelist->entry = resource;
        ctx->resourcelist->next = NULL;
        curr = ctx->resourcelist;
      } else {
        ResourceList *tmp = malloc(sizeof(ResourceList));
        if (!tmp)
          goto error;
        tmp->entry = resource;
        tmp->next = NULL;
        curr = curr->next = tmp;
      }

      resource = NULL;
      ctx->numresources++;

      continue;

    } /* END */

    /* PS Code */
    if (resource)
      strcat(code, buf);
  }

  if (resource) // Finished without seeing an END RESOURCE for the current
                // resource!
    goto error;

  fclose(f);
  free(code);

  return ctx;

error:

  if (f)
    fclose(f);
  if (resource) {
    free(resource->type);
    free(resource->name);
    free(resource->reqs);
    free(resource->code);
  }
  free(resource);

  free(code);
  bwipp_unload(ctx);

  return NULL;
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
    free(curr->entry);
    free(curr);
    curr = next;
  }

  ctx->resourcelist = NULL;

  free(ctx->version);
  free(ctx);
}

BWIPP_API const char *bwipp_get_version(BWIPP *ctx) {

  assert(ctx);

  return ctx->version;
}

BWIPP_API char *bwipp_emit_required_resources(BWIPP *ctx, const char *name) {

  char *code = NULL, *reqs, *req, *tmp = NULL, *saveptr = NULL;
  const Resource *resource, *res;

  resource = get_resource(ctx, name);
  if (!resource) { // Resource not found
    tmp = strdup("");
    if (!tmp)
      goto error;
    return tmp; // Copy of empty string
  }

  code = malloc(MAX_CODE);
  if (!code)
    goto error;
  *code = '\0';

  /* Add code for required resources */
  reqs = strdup(resource->reqs);
  if (!reqs)
    goto error;
  req = strtok_r(reqs, " ", &saveptr);
  while (req) {
    res = get_resource(ctx, req);
    if (!res)
      continue; // Ignore missing requisites
    strcat(code, res->code);
    req = strtok_r(NULL, " ", &saveptr);
  }
  free(reqs);

  /* Add code for this resource */
  strcat(code, resource->code);

  tmp = strdup(code);

error:

  free(code);

  return tmp;
}

BWIPP_API char *bwipp_emit_all_resources(BWIPP *ctx) {

  ResourceList *curr;
  char *code, *tmp;

  assert(ctx);

  curr = ctx->resourcelist;

  assert(ctx->resourcelist);

  code = malloc(MAX_CODE);
  if (!code)
    return NULL;

  *code = '\0';
  while (curr) {
    strcat(code, curr->entry->code);
    curr = curr->next;
  }

  tmp = strdup(code);
  free(code);

  return tmp;
}

BWIPP_API char *bwipp_emit_exec(BWIPP *ctx, const char *name, const char *data,
                                const char *options) {

  char *tmp = NULL, *call = NULL, *data_h, *options_h;

  assert(ctx);
  assert(name);
  assert(data);
  assert(options);

  data_h = pshexstr(data);
  options_h = pshexstr(options);

  if (!data_h || !options_h)
    goto error;

  call = malloc(MAX_CODE);
  if (!call)
    goto error;

  sprintf(call,
          "0 0 moveto\n"
          "%s\n"
          "%s\n"
          "/%s /uk.co.terryburton.bwipp findresource exec\n",
          data_h, options_h, name);

  tmp = strdup(call);

error:

  free(call);
  free(data_h);
  free(options_h);

  return tmp;
}
