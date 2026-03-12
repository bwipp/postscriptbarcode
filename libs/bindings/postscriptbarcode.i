/**
 * libpostscriptbarcode
 *
 * @file postscriptbarcode.i
 * @author Copyright (c) 2004-2026 Terry Burton.
 *
 * Copyright (c) 2004-2026 Terry Burton
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

/*
 * Typemap: convert NULL-terminated char ** to a native list and
 * free the array (strings are owned by the context, not the caller).
 * Returns None/nil/undef/null when the C function returns NULL.
 *
 * SWIG strips const from "const char **" during type normalisation,
 * so the typemap must match "char **".
 *
 * Must be declared before the struct so SWIG associates it with the
 * type before parsing %extend methods.
 */
#ifdef SWIGPYTHON
%typemap(out) char ** {
        if ($1) {
                int i;
                $result = PyList_New(0);
                for (i = 0; $1[i]; i++)
                        PyList_Append($result, PyUnicode_FromString($1[i]));
                bwipp_free((void *)$1);
        } else {
                Py_INCREF(Py_None);
                $result = Py_None;
        }
}
#endif

#ifdef SWIGRUBY
%typemap(out) char ** {
        if ($1) {
                int i;
                $result = rb_ary_new();
                for (i = 0; $1[i]; i++)
                        rb_ary_push($result, rb_str_new2($1[i]));
                bwipp_free((void *)$1);
        } else {
                $result = Qnil;
        }
}
#endif

#ifdef SWIGPERL
%typemap(out) char ** {
        if ($1) {
                AV *myav = newAV();
                int i;
                for (i = 0; $1[i]; i++)
                        av_push(myav, newSVpv($1[i], 0));
                bwipp_free((void *)$1);
                $result = newRV_noinc((SV *)myav);
                sv_2mortal($result);
        } else {
                $result = &PL_sv_undef;
        }
        argvi++;
}
#endif

#ifdef SWIGJAVA
%typemap(jni) char ** "jobjectArray"
%typemap(jtype) char ** "String[]"
%typemap(jstype) char ** "String[]"
%typemap(javaout) char ** { return $jnicall; }
%typemap(out) char ** {
        if ($1) {
                int i, count = 0;
                jclass strclass;
                while ($1[count]) count++;
                strclass = (*jenv)->FindClass(jenv, "java/lang/String");
                $result = (*jenv)->NewObjectArray(jenv, count, strclass, NULL);
                for (i = 0; i < count; i++)
                        (*jenv)->SetObjectArrayElement(jenv, $result, i,
                                (*jenv)->NewStringUTF(jenv, $1[i]));
                bwipp_free((void *)$1);
        }
}
#endif

/* Java: rename snake_case methods to camelCase */
#ifdef SWIGJAVA
%rename(getVersion) BWIPP::get_version;
%rename(listEncoders) BWIPP::list_encoders;
%rename(listProperties) BWIPP::list_properties;
%rename(getProperty) BWIPP::get_property;
%rename(listFamilies) BWIPP::list_families;
%rename(listFamilyMembers) BWIPP::list_family_members;
%rename(emitRequiredResources) BWIPP::emit_required_resources;
%rename(emitAllResources) BWIPP::emit_all_resources;
%rename(emitExec) BWIPP::emit_exec;
#endif

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
        const char** list_encoders() {
                return bwipp_list_encoders($self, NULL);
        }
        const char** list_properties(const char *name) {
                return bwipp_list_properties($self, name, NULL);
        }
        const char* get_property(const char *name, const char *key) {
                return bwipp_get_property($self, name, key);
        }
        const char** list_families() {
                return bwipp_list_families($self, NULL);
        }
        const char** list_family_members(const char *family) {
                return bwipp_list_family_members($self, family, NULL);
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
