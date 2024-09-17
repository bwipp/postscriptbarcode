/*
 * libpostscriptbarcode
 *
 * @file postscriptbarcode.h
 * @author Terry Burton
 *
 * \copyright Copyright (c) 2004-2024 Terry Burton
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
 * all subsequent function calls. You can then query the available barcode
 * families with bwipp_list_families() and list each family's members using
 * bwipp_list_family_members() to obtain the list of all supported barcode
 * symbologies. The available properties of each barcode symbology can be
 * enumerated using bwipp_list_properties() and read with
 * bwipp_get_property(). To create a PostScript document concatenate together
 * your own PostScript prolog with the output of either
 * bwipp_emit_required_resources() (minimal set of resources for a specific
 * barcode symbology) or bwipp_emit_all_resources() and you own PostScript
 * code interspersed with calls to bwipp_emit_exec() to render a barcode.
 * Finally, all resources can be freed using bwipp_unload().
 *
 * The library should be thread-safe provided that the calling code is limited
 * to one thread per context until the resources for the context have finished
 * loading.
 *
 */

#ifndef POSTSCRIPTBARCODE_H
#define POSTSCRIPTBARCODE_H

// Decorator for public API functions that we export
#if _WIN32
#define BWIPP_API __declspec(dllexport)
#else
#define BWIPP_API
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
 * @brief Provides the set of BWIPP resources required to generate a
 *        barcode of the specified type.
 *
 * @param [in,out] ctx ::BWIPP context.
 * @param [in] name Path to the barcode.ps resources file.
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
