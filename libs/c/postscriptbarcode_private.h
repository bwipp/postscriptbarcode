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
        unsigned short numprops;
        PropertyList *props;
} Resource;

typedef struct ResourceList {
        Resource *entry;
        struct ResourceList *next;
} ResourceList;

static char* pshexstr(const char*);
static const Resource* get_resource(BWIPP*,const char*);
static Property* get_property(const Resource*, const char*);
static void update_property(Resource*, char*, char*);
static void free_propertylist(PropertyList*);

static char *dupstr(const char*);
static char* flatten_array_to_string(char**, const unsigned int);

#endif /* BWIPP_PRIVATE_H */
