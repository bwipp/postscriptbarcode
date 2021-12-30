/*
 * libpostscriptbarcode - postscriptbarcode.h
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

/** @file postscriptbarcode.h
 *  @brief Public API for libpostscriptbarcode - a C library providing a
 *         functional interface to Barcode Writer in Pure PostScript.
 *
 *  The basic workflow is to firstly initialise the library to obtain a
 *  BWIPP context by loading the BWIPP resources using either bwipp_load() or
 *  bwipp_load_from_file(). The context is provided as the first argument to
 *  all subsequent function calls. You can then query the available barcode
 *  families with bwipp_list_families() and list each family's members using
 *  bwipp_list_family_members() to obtain the list of all supported barcode
 *  symbologies. The available properties of each barcode symbology can be
 *  enumerated using bwipp_list_properties() and read with
 *  bwipp_get_property(). To create a PostScript document concatenate together
 *  your own PostScript prolog with the output of either
 *  bwipp_emit_required_resources() (minimal set of resources for a specific
 *  barcode symbology) or bwipp_emit_all_resources() and you own PostScript
 *  code interspersed with calls to bwipp_emit_exec() to render a barcode.
 *  Finally, all resources can be freed using bwipp_unload().
 *
 *  The library should be thread-safe provided that the calling code is limited
 *  to one thread per context until the resources for the context have finished
 *  loading.
 *
 */

#ifndef BWIPP_H
#define BWIPP_H

/** @brief A BWIPP context.
 */
typedef struct BWIPP BWIPP;

/** @brief Load the BWIPP resources by searching for barcode.ps in default
 *         locations.
 *  @return BWIPP context on success, else NULL.
 */
BWIPP *bwipp_load(void);

/** @brief Load the BWIPP resources from a given resource file.
 *  @param filename Path to the barcode.ps resources file.
 *  @return BWIPP context on success, else NULL.
 */
BWIPP *bwipp_load_from_file(const char *filename);

/** @brief Unload the BWIPP resources.
 *  @param ctx BWIPP context.
 *  @return Void.
 */
void bwipp_unload(BWIPP *ctx);

/** @brief Provide the version of BWIPP that has been loaded.
 *  @param ctx BWIPP context.
 *  @return A string containing the version.
 */
const char *bwipp_get_version(BWIPP *ctx);

/** @brief Provides the set of BWIPP resources required to generate a
 *         barcode of the specified type.
 *  @param ctx BWIPP context.
 *  @param name Path to the barcode.ps resources file.
 *  @return A string containing a set of PostScript resources, which the
 *          caller should release with bwipp_free().
 */
char *bwipp_emit_required_resources(BWIPP *ctx, const char *name);

/** @brief Provides the complete set of BWIPP resources.
 *  @param ctx BWIPP context.
 *  @return A string containing the set of all PostScript resources,
 *          which the caller should release with bwipp_free().
 */
char *bwipp_emit_all_resources(BWIPP *ctx);

/** @brief Provide the PostScript code that invokes a barcode with given
 *         parameters.
 *  @param ctx BWIPP context.
 *  @param barcode The type of barcode.
 *  @param contents The contents of the barcode.
 *  @param options The formatting options for the barcode.
 *  @return The PostScript code that invokes the barcode, which the caller
 *          should release with bwipp_free().
 */
char *bwipp_emit_exec(BWIPP *ctx, const char *barcode, const char *contents,
                      const char *options);

/** @brief List all known barcode families.
 *  @param ctx BWIPP context.
 *  @param families Returns list of all barcode families by reference, which
 *         the caller should release with bwipp_free().
 *  @return Number of barcode families returned.
 */
unsigned short bwipp_list_families(BWIPP *ctx, char ***families);

/** @brief List all known barcode families as a comma seperated string.
 *  @param ctx BWIPP context.
 *  @return A comma seperated list of all barcode families, which the caller
 *          should release with bwipp_free().
 */
char *bwipp_list_families_as_string(BWIPP *ctx);

/** @brief List all members of a given barcode family.
 *  @param ctx BWIPP context.
 *  @param members Returns list of all barcode family members by reference,
 *         which the caller should release with bwipp_free().
 *  @param family The name of a barcode family.
 *  @return Number of barcode family members returned.
 */
unsigned short bwipp_list_family_members(BWIPP *ctx, char ***members,
                                         const char *family);

/** @brief List all members of a given barcode family as a comma seperated
 *         string.
 *  @param ctx BWIPP context.
 *  @param family The name of a barcode family.
 *  @return A comma seperated list of all barcode family members, which the
 *          caller should release with bwipp_free().
 */
char *bwipp_list_family_members_as_string(BWIPP *ctx, const char *family);

/** @brief List all properties of a given barcode symbology.
 *  @param ctx BWIPP context.
 *  @param properties Returns list of all barcode properties by reference,
 *         which the caller should release with bwipp_free().
 *  @param barcode The type of barcode symbology.
 *  @return Number of properties returned.
 */
unsigned short bwipp_list_properties(BWIPP *ctx, char ***properties,
                                     const char *barcode);

/** @brief List all properties of a given barcode symbology as a comma
 *         seperated string.
 *  @param ctx BWIPP context.
 *  @param barcode The type of barcode symbology.
 *  @return A comma seperated list of all barcode properties, which the caller
 *          should release with bwipp_free().
 */
char *bwipp_list_properties_as_string(BWIPP *ctx, const char *barcode);

/** @brief Get the value of a given property of a given barcode symbology.
 *  @param ctx BWIPP context.
 *  @param barcode The type of barcode symbology.
 *  @param property The name of the property to query.
 *  @return The value of the given property.
 */
const char *bwipp_get_property(BWIPP *ctx, const char *barcode,
                               const char *property);

/** @brief Free memory belonging to a BWIPP provided allocation.
 *  @param p Pointer to memory to free.
 */
void bwipp_free(void *p);

#endif /* BWIPP_H */
