/**
 * libpostscriptbarcode
 *
 * @file postscriptbarcode.i
 * @author Copyright (c) 2004-2023 Terry Burton.
 *
 * Copyright (c) 2004-2023 Terry Burton
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

%module postscriptbarcode

%{
#include <postscriptbarcode.h>
%}

struct BWIPP { };

%extend BWIPP {

        %typemap(newfree) char * "bwipp_free($1);";

        BWIPP(char* filename) {
                return bwipp_load_from_file(filename);
        }
        BWIPP() {
                return bwipp_load();
        }
        ~BWIPP() {
                bwipp_unload($self);
        }
        const char* get_version() {
                return bwipp_get_version($self);
        }
        %newobject emit_required_resources;
        char* emit_required_resources(char* name) {
                return bwipp_emit_required_resources($self,name);
        }
        %newobject emit_all_resources;
        char* emit_all_resources() {
                return bwipp_emit_all_resources($self);
        }
        %newobject emit_exec;
        char* emit_exec(const char *barcode, const char *contents,
                        const char *options) {
                return bwipp_emit_exec($self,barcode,contents,options);
        }
};

