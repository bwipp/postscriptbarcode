/*
 * libpostscriptbarcode
 *
 * @file postscriptbarcode.h
 * @author Terry Burton
 *
 * \copyright Copyright (c) 2004-2026 Terry Burton
 * Barcode Writer in Pure PostScript
 *
 * @licenseblock{License}
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
 * @endlicenseblock
 *
 *
 * Overview
 * --------
 *
 * The basic workflow is to firstly initialise the library to obtain a
 * BWIPP context by loading the BWIPP resources using either bwipp_load() or
 * bwipp_load_from_file(). The context is provided as the first argument to
 * all subsequent function calls. You can then list the available encoder
 * names using bwipp_list_encoders(). Each encoder has properties (metadata
 * key-value pairs such as DESC, EXAM, EXOP, RNDR) that can be enumerated
 * using bwipp_list_properties() and read with bwipp_get_property().
 * Encoders can be grouped by family using bwipp_list_families() and
 * bwipp_list_family_members(). To
 * create a PostScript document concatenate together your own PostScript
 * prolog with the output of either bwipp_emit_required_resources() (minimal
 * set of resources for a specific barcode symbology) or
 * bwipp_emit_all_resources() and your own PostScript code interspersed with
 * calls to bwipp_emit_exec() to render a barcode. Finally, all resources
 * can be freed using bwipp_unload().
 *
 * The library should be thread-safe provided that the calling code is limited
 * to one thread per context until the resources for the context have finished
 * loading.
 *
 */

#ifndef POSTSCRIPTBARCODE_H
#define POSTSCRIPTBARCODE_H

/* Decorator for public API functions that we export */
#if defined(_WIN32)
#define BWIPP_API __declspec(dllexport)
#else
#define BWIPP_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief A BWIPP context.
 */
typedef struct BWIPP BWIPP;

/**
 * @brief Load the BWIPP resources by searching for barcode.ps in default
 *        locations.
 * @return ::BWIPP context on success, else NULL.
 */
BWIPP_API BWIPP *bwipp_load(void);

/**
 * @brief Load the BWIPP resources from a given resource file.
 *
 * @param [in] filename Path to the barcode.ps resources file.
 * @return ::BWIPP context on success, else NULL.
 */
BWIPP_API BWIPP *bwipp_load_from_file(const char *filename);

/**
 * @brief Unload the BWIPP resources.
 *
 * @param [in,out] ctx ::BWIPP context.
 * @return Void.
 */
BWIPP_API void bwipp_unload(BWIPP *ctx);

/**
 * @brief Provide the version of BWIPP that has been loaded.
 *
 * @param [in,out] ctx ::BWIPP context.
 * @return A string containing the version.
 */
BWIPP_API const char *bwipp_get_version(BWIPP *ctx);

/**
 * @brief List the names of all encoder resources.
 *
 * Returns a NULL-terminated array of encoder name strings sorted
 * lexicographically.
 *
 * @param [in] ctx ::BWIPP context.
 * @param [out] count If non-NULL, receives the number of encoders.
 * @return NULL-terminated array of encoder name strings, else NULL.
 *         The caller should release the array (not the strings) with
 *         bwipp_free().
 */
BWIPP_API const char **bwipp_list_encoders(BWIPP *ctx, unsigned int *count);

/**
 * @brief List the property keys of a named resource.
 *
 * Returns a NULL-terminated array of property key strings. Properties are
 * metadata key-value pairs extracted from the resource file comments (e.g.
 * DESC, EXAM, EXOP, RNDR).
 *
 * @param [in] ctx ::BWIPP context.
 * @param [in] name The resource name.
 * @param [out] count If non-NULL, receives the number of properties.
 * @return NULL-terminated array of key strings, else NULL if the resource
 *         is not found. The caller should release the array (not the
 *         strings) with bwipp_free().
 */
BWIPP_API const char **bwipp_list_properties(BWIPP *ctx, const char *name,
                                             unsigned int *count);

/**
 * @brief Get the value of a named property on a resource.
 *
 * @param [in] ctx ::BWIPP context.
 * @param [in] name The resource name.
 * @param [in] key The property key (e.g. "DESC", "EXAM", "EXOP", "RNDR").
 * @return The property value string (owned by the context), or NULL if
 *         the resource or property is not found.
 */
BWIPP_API const char *bwipp_get_property(BWIPP *ctx, const char *name,
                                         const char *key);

/**
 * @brief List the unique family names.
 *
 * Returns a NULL-terminated array of unique family name strings sorted
 * lexicographically, derived from the FMLY metadata property on encoder
 * resources.
 *
 * @param [in] ctx ::BWIPP context.
 * @param [out] count If non-NULL, receives the number of families.
 * @return NULL-terminated array of family name strings, else NULL.
 *         The caller should release the array (not the strings) with
 *         bwipp_free().
 */
BWIPP_API const char **bwipp_list_families(BWIPP *ctx, unsigned int *count);

/**
 * @brief List the encoder names belonging to a family.
 *
 * Returns a NULL-terminated array of encoder name strings sorted
 * lexicographically.
 *
 * @param [in] ctx ::BWIPP context.
 * @param [in] family The family name (as returned by bwipp_list_families()).
 * @param [out] count If non-NULL, receives the number of members.
 * @return NULL-terminated array of encoder name strings, else NULL if the
 *         family is not found. The caller should release the array (not
 *         the strings) with bwipp_free().
 */
BWIPP_API const char **bwipp_list_family_members(BWIPP *ctx,
                                                 const char *family,
                                                 unsigned int *count);

/**
 * @brief Provides the set of BWIPP resources required to generate a
 *        barcode of the specified type.
 *
 * @param [in,out] ctx ::BWIPP context.
 * @param [in] name The encoder or resource name.
 * @return A string containing a set of PostScript resources, which the
 *         caller should release with bwipp_free().
 */
BWIPP_API char *bwipp_emit_required_resources(BWIPP *ctx, const char *name);

/**
 * @brief Provides the complete set of BWIPP resources.
 *
 * @param [in,out] ctx ::BWIPP context.
 * @return A string containing the set of all PostScript resources,
 *          which the caller should release with bwipp_free().
 */
BWIPP_API char *bwipp_emit_all_resources(BWIPP *ctx);

/**
 * @brief Provide the PostScript code that invokes a barcode with given
 *        parameters.
 *
 * @param [in,out] ctx ::BWIPP context.
 * @param [in] barcode The type of barcode.
 * @param [in] contents The contents of the barcode.
 * @param [in] options The formatting options for the barcode.
 * @return The PostScript code that invokes the barcode, which the caller
 *          should release with bwipp_free().
 */
BWIPP_API char *bwipp_emit_exec(BWIPP *ctx, const char *barcode,
                                const char *contents, const char *options);

/**
 * @brief Free memory belonging to a BWIPP provided allocation.
 *
 * @param [in,out] p Pointer to memory to free.
 */
BWIPP_API void bwipp_free(void *p);

#ifdef __cplusplus
}
#endif

#endif  /* POSTSCRIPTBARCODE_H */
