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
#include <limits.h>
#include <stdlib.h>
#include <string.h>

typedef struct BwippInitOpts {
	int flags;
	char *filename;
	unsigned int hexify_width;
} BwippInitOpts;
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

/* Ruby: attribute writer style */
#ifdef SWIGRUBY
%rename("filename=") BwippInitOpts::set_filename;
%rename("lazy_load=") BwippInitOpts::set_lazy_load;
%rename("hexify_width=") BwippInitOpts::set_hexify_width;
#endif

/* Python: property wrappers added via %pythoncode below */

/* Java: rename snake_case methods to camelCase */
#ifdef SWIGJAVA
%rename(InitOpts) BwippInitOpts;
%rename(setFilename) BwippInitOpts::set_filename;
%rename(setLazyLoad) BwippInitOpts::set_lazy_load;
%rename(setHexifyWidth) BwippInitOpts::set_hexify_width;
%rename(getVersion) BWIPP::get_version;
%rename(listEncoders) BWIPP::list_encoders;
%rename(listProperties) BWIPP::list_properties;
%rename(getProperty) BWIPP::get_property;
%rename(listFamilies) BWIPP::list_families;
%rename(listFamilyMembers) BWIPP::list_family_members;
%rename(emitRequiredResources) BWIPP::emit_required_resources;
%rename(emitAllResources) BWIPP::emit_all_resources;
%rename(emitExec) BWIPP::emit_exec;
%rename(emitTemplate) BWIPP::emit_template;
%rename(emitPshexstr) BWIPP::emit_pshexstr;
#endif

struct BwippInitOpts { };

%extend BwippInitOpts {
        BwippInitOpts() {
                return (BwippInitOpts *)calloc(1, sizeof(BwippInitOpts));
        }
        ~BwippInitOpts() {
                free($self->filename);
                free($self);
        }
        void set_filename(const char *filename) {
                free($self->filename);
                $self->filename = filename ? strdup(filename) : NULL;
        }
        void set_lazy_load(int enable) {
                if (enable)
                        $self->flags |= bwipp_iLAZY_LOAD;
                else
                        $self->flags &= ~bwipp_iLAZY_LOAD;
        }
        void set_hexify_width(unsigned int width) {
                $self->hexify_width = width ? width : UINT_MAX;
        }
#ifdef SWIGPYTHON
        %pythoncode %{
            filename = property(fset=set_filename)
            lazy_load = property(fset=set_lazy_load)
            hexify_width = property(fset=set_hexify_width)
        %}
#endif
#ifdef SWIGJAVA
        /* Java: fluent setter wrappers returning this */
        %proxycode %{
            public InitOpts filename(String filename) {
                setFilename(filename);
                return this;
            }
            public InitOpts lazyLoad(boolean enable) {
                setLazyLoad(enable ? 1 : 0);
                return this;
            }
            public InitOpts hexifyWidth(int width) {
                setHexifyWidth(width);
                return this;
            }
        %}
#endif
};

struct BWIPP { };

%extend BWIPP {

        %typemap(newfree) char * "bwipp_free($1);";

#ifdef SWIGPERL
        /* Perl: accept a hashref as init options */
        %perlcode %{
            package postscriptbarcode::BWIPP;
            my $_new_orig = \&new;
            no warnings 'redefine';
            *new = sub {
                my $pkg = shift;
                if (@_ == 1 && ref $_[0] eq 'HASH') {
                    my $h = $_[0];
                    my $opts = postscriptbarcode::BwippInitOpts->new();
                    $opts->set_filename($h->{filename}) if exists $h->{filename};
                    $opts->set_lazy_load($h->{lazy_load} ? 1 : 0) if exists $h->{lazy_load};
                    $opts->set_hexify_width($h->{hexify_width}) if exists $h->{hexify_width};
                    return $_new_orig->($pkg, $opts);
                }
                return $_new_orig->($pkg, @_);
            };
        %}
#endif
        BWIPP(BwippInitOpts *opts) {
                bwipp_load_init_opts_t c_opts = {
                        .struct_size = sizeof(c_opts),
                        .filename = opts ? opts->filename : NULL,
                        .flags = opts ? opts->flags : bwipp_iDEFAULT,
                        .hexify_width = opts ? opts->hexify_width : 0,
                };
                return bwipp_load_ex(&c_opts);
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
        %newobject emit_template;
        char* emit_template(const char *fmt, const char *name,
                            const char *data, const char *options) {
                return bwipp_emit_template($self,fmt,name,data,options);
        }
        %newobject emit_pshexstr;
        char* emit_pshexstr(const char *str) {
                return bwipp_emit_pshexstr($self,str);
        }
};

#ifdef SWIGRUBY
/* Ruby: accept keyword arguments to BWIPP.new */
%init %{
    rb_eval_string(
        "class Postscriptbarcode::BWIPP\n"
        "  class << self\n"
        "    alias_method :_new_orig, :new\n"
        "    def new(**kwargs)\n"
        "      if kwargs.empty?\n"
        "        _new_orig\n"
        "      else\n"
        "        opts = Postscriptbarcode::BwippInitOpts.new\n"
        "        opts.filename = kwargs[:filename] if kwargs.key?(:filename)\n"
        "        opts.lazy_load = kwargs[:lazy_load] ? 1 : 0 if kwargs.key?(:lazy_load)\n"
        "        opts.hexify_width = kwargs[:hexify_width] if kwargs.key?(:hexify_width)\n"
        "        _new_orig(opts)\n"
        "      end\n"
        "    end\n"
        "  end\n"
        "end\n"
    );
%}
#endif

#ifdef SWIGPYTHON
/* Python: accept keyword arguments to BWIPP() */
%pythoncode %{
_BWIPP_init_orig = BWIPP.__init__
def _BWIPP_init_kwargs(self, *args, filename=None, lazy_load=None, hexify_width=None):
    if args or (filename is None and lazy_load is None and hexify_width is None):
        _BWIPP_init_orig(self, *args)
    else:
        opts = BwippInitOpts()
        if filename is not None:
            opts.filename = filename
        if lazy_load is not None:
            opts.lazy_load = lazy_load
        if hexify_width is not None:
            opts.hexify_width = hexify_width
        _BWIPP_init_orig(self, opts)
BWIPP.__init__ = _BWIPP_init_kwargs
%}
#endif
