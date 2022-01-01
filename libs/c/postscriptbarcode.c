/*
 * libpostscriptbarcode - postscriptbarcode.c
 *
 * Barcode Writer in Pure PostScript
 * https://bwipp.terryburton.co.uk
 *
 * Copyright (c) 2004-2015 Terry Burton
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
 */

#include "postscriptbarcode.h"
#include "postscriptbarcode_private.h"
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LINE 200
#define MAX_CODE 1000000
#define HEXIFY_WIDTH 72

struct BWIPP {
  char *version;
  ResourceList *resourcelist;
  unsigned short numresources;
};

static const char *default_filename = "/usr/share/postscriptbarcode/barcode.ps";

void bwipp_free(void *p) { free(p); }

BWIPP *bwipp_load(void) {
  /* TODO search a set of default paths */
  return bwipp_load_from_file(default_filename);
}

BWIPP *bwipp_load_from_file(const char *filename) {

  FILE *f;

  BWIPP *ctx = malloc(sizeof(BWIPP));

  ResourceList *curr = NULL;
  Resource *resource = NULL;
  char buf[MAX_LINE];
  char *code = NULL;
  bool skip = true;

  ctx->version = NULL;
  ctx->resourcelist = NULL;
  ctx->numresources = 0;

  f = fopen(filename, "r");
  if (f == NULL)
    goto error;
  code = malloc(MAX_CODE * sizeof(char));
  while (fgets(buf, sizeof buf, f) != NULL) {
    if (skip) {
      if (strcmp(buf, "% --BEGIN TEMPLATE--\n") == 0)
        skip = false;
      if (strncmp(buf, "% Barcode Writer in Pure PostScript", 35) == 0) {
        char *version, *p;
        if (ctx->version != NULL)
          goto error;
        p = strrchr(buf, ' ');
        version = p + 1;
        p = strchr(version, '\n');
        *p = 0;
        ctx->version = strdup(version);
      }
      continue;
    }
    if (strcmp(buf, "% --END TEMPLATE--\n") == 0) {
      break;
    }

    /* % --BEGIN {TYPE} {NAME}-- */
    if (strncmp(buf, "% --BEGIN ", 10) == 0) {
      char *type, *name, *p;
      if (resource != NULL)
        goto error;
      type = buf + 10;
      p = strchr(type, ' ');
      *p = 0;
      name = p + 1;
      p = strrchr(name, '-');
      *(p - 1) = 0;
      resource = malloc(sizeof(Resource));
      resource->type = dupstr(type);
      resource->name = dupstr(name);
      resource->reqs = NULL;
      resource->numprops = 0;
      resource->props = NULL;
      resource->code = NULL;
      *code = 0;
      continue;
    } /* BEGIN */

    /* % --REQUIRES {REQS}-- */
    if (strncmp(buf, "% --REQUIRES ", 13) == 0) {
      char *reqs, *p;
      if (resource == NULL || resource->reqs != NULL)
        goto error;
      reqs = buf + 13;
      p = strrchr(reqs, '-');
      *(p - 1) = 0;
      resource->reqs = dupstr(reqs);
      continue;
    } /* REQUIRES */

    /* % --PROP: {PROPERTY} */
    if (strncmp(buf, "% --", 4) == 0 && strlen(buf) >= 9 && *(buf + 8) == ':') {
      char *key, *val, *p;
      key = buf + 4;
      p = buf + 8;
      *p = 0;
      val = buf + 9;
      p = strchr(val, '\n');
      *p = 0;
      update_property(resource, key, val + 1);
      continue;
    } /* PROP */

    /* % --END {TYPE} {NAME}-- */
    if (strncmp(buf, "% --END ", 8) == 0) {
      char *type, *name, *p;
      if (resource == NULL)
        goto error;
      type = buf + 8;
      p = strchr(type, ' ');
      *p = 0;
      name = p + 1;
      p = strrchr(name, '-');
      *(p - 1) = 0;
      if (strcmp(resource->type, type) != 0)
        goto error;
      if (strcmp(resource->name, name) != 0)
        goto error;
      resource->code = dupstr(code);
      *code = 0;

      /* Add to ResourceList */
      if (ctx->resourcelist == NULL) {
        ctx->resourcelist = malloc(sizeof(ResourceList));
        ctx->resourcelist->entry = resource;
        ctx->resourcelist->next = NULL;
        curr = ctx->resourcelist;
      } else {
        ResourceList *tmp = malloc(sizeof(ResourceList));
        tmp->entry = resource;
        tmp->next = NULL;
        curr->next = tmp;
        curr = tmp;
      }

      resource = NULL;
      ctx->numresources++;
      continue;
    } /* END */

    /* PS Code */
    if (resource) {
      strcat(code, buf);
    }
  }
  fclose(f);
  free(code);
  return ctx;

error:
  if (resource) {
    free(resource->type);
    free(resource->name);
    free(resource->reqs);
    free(resource->code);
    free_propertylist(curr->entry->props);
  }
  free(code);
  bwipp_unload(ctx);
  return NULL;
}

void bwipp_unload(BWIPP *ctx) {
  ResourceList *curr = ctx->resourcelist;
  while (curr) {
    ResourceList *next = curr->next;
    free(curr->entry->type);
    free(curr->entry->name);
    free(curr->entry->reqs);
    free(curr->entry->code);
    free_propertylist(curr->entry->props);
    free(curr->entry);
    free(curr);
    curr = next;
  }
  ctx->resourcelist = NULL;
  free(ctx->version);
  free(ctx);
}

const char *bwipp_get_version(BWIPP *ctx) { return ctx ? ctx->version : NULL; }

char *bwipp_emit_required_resources(BWIPP *ctx, const char *name) {

  char *code, *reqs, *req, *tmp, *saveptr = NULL;
  const Resource *resource;

  resource = get_resource(ctx, name);
  if (resource == NULL)
    return NULL;

  code = malloc(MAX_CODE * sizeof(char));
  *code = 0;

  /* Add code for required resources */
  reqs = dupstr(resource->reqs);
  req = strtok_r(reqs, " ", &saveptr);
  while (req != NULL) {
    strcat(code, get_resource(ctx, req)->code);
    req = strtok_r(NULL, " ", &saveptr);
  }
  free(reqs);

  /* Add code for this resource */
  strcat(code, resource->code);

  tmp = dupstr(code);
  free(code);
  return tmp;
}

char *bwipp_emit_all_resources(BWIPP *ctx) {
  ResourceList *curr;
  char *code, *tmp;

  curr = ctx->resourcelist;
  if (curr == NULL)
    return NULL;

  code = malloc(MAX_CODE * sizeof(char));
  *code = 0;
  while (curr) {
    strcat(code, curr->entry->code);
    curr = curr->next;
  }
  tmp = dupstr(code);
  free(code);
  return tmp;
}

char *bwipp_emit_exec(BWIPP *ctx, const char *name, const char *data,
                      const char *options) {
  char *tmp;
  char *call = malloc(MAX_CODE * sizeof(char));
  char *data_h = pshexstr(data);
  char *options_h = pshexstr(options);
  (void)(ctx);
  sprintf(call,
          "0 0 moveto\n"
          "%s\n"
          "%s\n"
          "/%s /uk.co.terryburton.bwipp findresource exec\n",
          data_h, options_h, name);
  free(data_h);
  free(options_h);
  tmp = dupstr(call);
  free(call);
  return tmp;
}

const char *bwipp_get_property(BWIPP *ctx, const char *name, const char *prop) {

  const Property *property;
  const Resource *resource;

  resource = get_resource(ctx, name);
  if (resource == NULL)
    return NULL;

  property = get_property(resource, prop);
  if (property == NULL)
    return NULL;

  return property->value;
}

unsigned short bwipp_list_properties(BWIPP *ctx, char ***out,
                                     const char *name) {

  const PropertyList *curr;
  const Resource *resource = get_resource(ctx, name);
  unsigned short numprops, i = 0;
  char **properties;

  if (resource == NULL)
    return 0;

  curr = resource->props;
  if (curr == NULL)
    return 0;

  numprops = resource->numprops;
  properties = malloc(numprops * sizeof(char *));

  curr = resource->props;
  while (curr) {
    Property *prop = curr->entry;
    if (prop) {
      properties[i] = prop->key;
      i++;
    }
    curr = curr->next;
  }

  *out = properties;
  return numprops;
}

char *bwipp_list_properties_as_string(BWIPP *ctx, const char *name) {
  unsigned short i;
  char **properties;
  char *properties_str;
  i = bwipp_list_properties(ctx, &properties, name);
  properties_str = flatten_array_to_string(properties, i);
  free(properties);
  return properties_str;
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

static void update_property(Resource *resource, char *key, char *value) {

  PropertyList *propertylist = resource->props;

  if (propertylist == NULL) {
    Property *property = malloc(sizeof(Property));
    property->key = dupstr(key);
    property->value = dupstr(value);
    propertylist = malloc(sizeof(PropertyList));
    propertylist->entry = property;
    propertylist->next = NULL;
    resource->props = propertylist;
    resource->numprops++;
  } else {
    Property *property = get_property(resource, key);
    if (property == NULL) {
      PropertyList *tmp, *last;
      property = malloc(sizeof(Property));
      property->key = dupstr(key);
      property->value = dupstr(value);
      tmp = malloc(sizeof(PropertyList));
      tmp->entry = property;
      tmp->next = NULL;
      last = propertylist;
      while (last->next != NULL)
        last = last->next;
      last->next = tmp;
      resource->numprops++;
    } else {
      property->value =
          realloc(property->value,
                  strlen(property->value) + strlen(value) + sizeof(char));
      strcat(property->value, value);
    }
  }
}

static Property *get_property(const Resource *resource, const char *key) {
  PropertyList *curr = resource->props;
  while (curr) {
    if (strcmp(curr->entry->key, key) == 0)
      break;
    curr = curr->next;
  }
  return curr ? curr->entry : NULL;
}

static void free_propertylist(PropertyList *propertylist) {
  PropertyList *curr = propertylist;
  while (curr) {
    PropertyList *next = curr->next;
    free(curr->entry->key);
    free(curr->entry->value);
    free(curr->entry);
    free(curr);
    curr = next;
  }
  propertylist = NULL;
}

static char *pshexstr(const char *in) {
  char *out = malloc((3 * strlen(in) + 3) * sizeof(char));
  unsigned short count = 1, i;
  char *hex = out;
  hex += sprintf(hex, "<");
  for (i = 0; i < strlen(in); i++) {
    if (count >= HEXIFY_WIDTH) {
      hex += sprintf(hex, "\n");
      count = 0;
    }
    if (count == 0) {
      hex += sprintf(hex, " ");
      count++;
    }
    hex += sprintf(hex, "%02X", in[i]);
    count++;
    count++;
  }
  hex += sprintf(hex, ">");
  hex++;
  out = realloc(out, (size_t)(hex - out) * sizeof(*out));
  return out;
}

static int cmpfnc(const void *a, const void *b) {
  const char *pa = *(const char **)a;
  const char *pb = *(const char **)b;
  return strcmp(pa, pb);
}

unsigned short bwipp_list_families(BWIPP *ctx, char ***out) {
  ResourceList *curr;
  char **families, **uniqfamilies;
  char *last = "";
  unsigned short i = 0, j, k = 0;

  if (ctx->resourcelist == NULL)
    return 0;

  families = malloc(ctx->numresources * sizeof(char *));
  curr = ctx->resourcelist;
  while (curr) {
    Property *fmly = get_property(curr->entry, "FMLY");
    if (fmly) {
      families[i] = fmly->value;
      i++;
    }
    curr = curr->next;
  }
  qsort(families, i, sizeof(char *), cmpfnc);
  uniqfamilies = malloc(i * sizeof(char *));
  for (j = 0; j < i; j++) {
    char *f = families[j];
    if (strcmp(f, last) != 0) {
      uniqfamilies[k] = f;
      last = f;
      k++;
    }
  }
  free(families);
  uniqfamilies = realloc(uniqfamilies, k * sizeof(char *));
  *out = uniqfamilies;
  return k;
}

char *bwipp_list_families_as_string(BWIPP *ctx) {
  unsigned short i;
  char **families;
  char *families_str;
  i = bwipp_list_families(ctx, &families);
  families_str = flatten_array_to_string(families, i);
  free(families);
  return families_str;
}

unsigned short bwipp_list_family_members(BWIPP *ctx, char ***out,
                                         const char *family) {
  char **members;
  unsigned short i = 0;
  ResourceList *curr;

  if (ctx->resourcelist == NULL)
    return 0;

  members = malloc(ctx->numresources * sizeof(char *));
  curr = ctx->resourcelist;
  while (curr) {
    Property *fmly = get_property(curr->entry, "FMLY");
    if (fmly && strcmp(fmly->value, family) == 0) {
      members[i] = curr->entry->name;
      i++;
    }
    curr = curr->next;
  }
  members = realloc(members, i * sizeof(char *));
  qsort(members, i, sizeof(char *), cmpfnc);
  *out = members;
  return i;
}

char *bwipp_list_family_members_as_string(BWIPP *ctx, const char *family) {
  unsigned short i;
  char **members;
  char *members_str;
  i = bwipp_list_family_members(ctx, &members, family);
  members_str = flatten_array_to_string(members, i);
  free(members);
  return members_str;
}

static char *dupstr(const char *s) {
  char *p = malloc(strlen(s) + 1);
  if (p != NULL)
    strcpy(p, s);
  return p;
}

static char *flatten_array_to_string(char **array, const unsigned int size) {

  unsigned int i;
  char *out, *tmp;

  out = malloc((size_t)(MAX_LINE * size) * sizeof(char));
  *out = 0;

  for (i = 0; i < size; i++) {
    strcat(out, array[i]);
    strcat(out, ",");
  }
  if (out[0] != '\0')
    out[strlen(out) - 1] = '\0';

  tmp = strdup(out);
  free(out);
  return tmp;
}
