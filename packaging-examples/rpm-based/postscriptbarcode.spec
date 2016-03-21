Name:           postscriptbarcode
Version:        <empty>
Release:        1%{?dist}
Summary:        Barcode Writer in Pure PostScript
Group:          Development/Libraries


# 
# This file is intended to provide a guide to packagers of RPM-based distributions to promote consistency.
#
# The packages have been built on the OBS but not necessarily installed and tested:
# https://build.opensuse.org/package/show/home:terryburton:postscriptbarcode/libpostscriptbarcode
#
# Please contribute any improvements back here:
# https://github.com/bwipp/postscriptbarcode/tree/master/packaging-examples
#
# Known issues:
#
# * RHEL/CentOS 5 too old due to /usr/bin/ld: unrecognized option '-Bsymbolic-functions'. We could disabled this but probably not worth going back this far.
# * Re-enabled postscriptbarcode_test which is failing with an invalid_free recent OpenSUSE.
#

# No Python 3 in RHEL or before SuSE 12
%if 0%{?fedora} || 0%{?suse_version} >= 1200
%global with_python3 1
%endif

# Ruby fails due to extconf.rb bug in RHEL/CentOS/SciLinux 6:
# [   83s] Makefile:152: Commands were specified for file `postscriptbarcode.so' at Makefile:122,
# [   83s] Makefile:152: but `postscriptbarcode.so' is now considered the same file as `/usr/lib/ruby/1.8/i386-linux/postscriptbarcode.so'.
# [   83s] Makefile:152: Commands for `/usr/lib/ruby/1.8/i386-linux/postscriptbarcode.so' will be ignored in favor of those for `postscriptbarcode.so'.
# Ruby-devel is not available in the base channel for RHEL 7 on OBS
%if 0%{?rhel} != 6 && 0%{?rhel} != 7
%global with_ruby 1
%endif

# Doxygen segfaults on RHEL/CentOS/SciLinux 6:
%if 0%{?rhel} != 6
%global with_docs 1
%endif

# Fedora-style compat macros for SuSE
%{!?__python2:          %global __python2 /usr/bin/python2}
%{!?python2_sitearch:   %global python2_sitearch %(%{__python2} -c "from distutils.sysconfig import get_python_lib; print(get_python_lib(1))")}
%{!?python2_sitelib:    %global python2_sitelib  %(%{__python2} -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")}

%if 0%{?with_python3}
%{!?__python3:          %global __python3 /usr/bin/python3}
%{!?python3_sitearch:   %global python3_sitearch %(%{__python3} -c "from distutils.sysconfig import get_python_lib; print(get_python_lib(1))")}
%{!?python3_sitelib:    %global python3_sitelib  %(%{__python3} -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")}
%endif

%if 0%{?with_ruby}
%{!?ruby_vendorarchdir: %global ruby_vendorarchdir %(ruby -rrbconfig -e 'puts RbConfig::CONFIG["vendorarchdir"]')}
%{!?ruby_vendorlibdir:  %global ruby_vendorlibdir  %(ruby -rrbconfig -e 'puts RbConfig::CONFIG["vendorlibdir"]')}
%endif

# SuSE naming conventions
%if 0%{?suse_version}
%global postscriptbarcode_lib_pkgname libpostscriptbarcode0
%global python2_postscriptbarcode_pkgname python-postscriptbarcode
%else
%global postscriptbarcode_lib_pkgname postscriptbarcode-libs
%global python2_postscriptbarcode_pkgname python2-postscriptbarcode
%endif


License:        MIT
URL:            http://bwipp.terryburton.co.uk
Source0:        https://github.com/bwipp/postscriptbarcode/archive/master.tar.gz#/%{name}-%{version}.tar.gz
BuildRequires:  ghostscript
BuildRequires:  swig
BuildRequires:  java-devel
BuildRequires:  ant
BuildRequires:  perl
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  chrpath

%if 0%{?with_docs}
BuildRequires:  doxygen
%if 0%{?rhel} == 5
BuildRequires:  graphviz-gd
%endif
%endif

%if 0%{?suse_version}
BuildRequires:  python-devel
BuildRequires:  fdupes
%else
BuildRequires:  python2-devel
%endif

%if 0%{?with_python3}
BuildRequires:  python3-devel
%endif


%if 0%{?with_ruby}

%if 0%{?fedora}
BuildRequires:  ruby(release)
BuildRequires:  rubypick
BuildRequires:  ruby-devel
%endif

%if 0%{?rhel} && 0%{?rhel} >=7
BuildRequires:  ruby(release)
BuildRequires:  ruby-devel
%endif

%if 0%{?rhel} && 0%{?rhel} <7
BuildRequires:  ruby
BuildRequires:  ruby-devel
%endif

%if 0%{?suse_version}
BuildRequires:  ruby
BuildRequires:  ruby-devel
%endif

%endif


# Required for EPEL <= 5
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)


%description
Barcode Writer in Pure Postscript generates all barcode formats entirely
within PostScript so that the process of converting the input data into
the printed output can be performed by the printer or RIP itself. This is
ideal for variable data printing (VDP) and avoids the need to re-implement
the barcode generation process whenever your language needs change.


%package -n %{postscriptbarcode_lib_pkgname}
Summary: Shared library for Barcode Writer in Pure PostScript
Group: Development/Libraries
Requires: postscriptbarcode

%description -n %{postscriptbarcode_lib_pkgname}
This package provides the shared library for Barcode Writer in Pure PostScript.


%package -n %{postscriptbarcode_lib_pkgname}-devel
Summary: Development files for Barcode Writer in Pure PostScript
Group: Development/Libraries
Requires: %{postscriptbarcode_lib_pkgname} = %{version}-%{release}

%description -n %{postscriptbarcode_lib_pkgname}-devel
Package providing the development files for Barcode Writer in Pure PostScript


%package -n java-postscriptbarcode
Summary: Java binding for Barcode Writer in Pure PostScript
Group: Development/Libraries
Requires: %{postscriptbarcode_lib_pkgname} = %{version}-%{release}
Requires: java-headless
Requires: javapackages-tools

%description -n java-postscriptbarcode
This package provides the Java binding for Barcode Writer in Pure PostScript


%package -n perl-postscriptbarcode
Summary: Perl binding for Barcode Writer in Pure PostScript
Group: Development/Libraries
Requires: %{postscriptbarcode_lib_pkgname} = %{version}-%{release}
%if 0%{?fedora}
Requires: perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
%endif
%if 0%{?suse_version}
%if 0%{?suse_version} < 1140
Requires: perl = %{perl_version}
%else
%{perl_requires}
%endif
%endif

%description -n perl-postscriptbarcode
This package provides the Perl binding for Barcode Writer in Pure PostScript


%package -n %{python2_postscriptbarcode_pkgname}
Summary: Python 2 binding for Barcode Writer in Pure PostScript
Group: Development/Libraries
Requires: %{postscriptbarcode_lib_pkgname} = %{version}-%{release}
%{?python_provide:%python_provide python2-postscriptbarcode}

%description -n %{python2_postscriptbarcode_pkgname}
This package provides the Python 2 binding for Barcode Writer in Pure PostScript


%if 0%{?with_python3}
%package -n python3-postscriptbarcode
Summary: Python 3 binding for Barcode Writer in Pure PostScript
Group: Development/Libraries
Requires: %{postscriptbarcode_lib_pkgname} = %{version}-%{release}
%{?python_provide:%python_provide python3-postscriptbarcode}

%description -n python3-postscriptbarcode
This package provides the Python 3 binding for Barcode Writer in Pure PostScript
%endif

%if 0%{?with_ruby}
%package -n ruby-postscriptbarcode
Summary: Ruby binding for Barcode Writer in Pure PostScript
Group: Development/Libraries
Requires: ruby(release)
Requires: %{postscriptbarcode_lib_pkgname} = %{version}-%{release}

%description -n ruby-postscriptbarcode
This package provides the Ruby binding for Barcode Writer in Pure PostScript
%endif


%prep
%setup -q -n %{name}-%{version}


%build

# For debugging
rpm --showrc

%{__make} %{_smp_mflags}

pushd libs/c
%{__make} %{_smp_mflags} CFLAGS="%{optflags}"
popd

pushd libs/bindings/java
%ant
popd

pushd libs/bindings/perl
%{__perl} Makefile.PL INSTALLDIRS=vendor OPTIMIZE="%{optflags}" NO_PACKLIST=1
%{__make} %{_smp_mflags}
find . -name 'postscriptbarcode.so' -exec chrpath -d {} \;
popd

pushd libs/bindings/python
# %%py2_build
CFLAGS="%{optflags}" %{__python2} setup.py build --executable="%{__python2} -s"
popd

%if 0%{?with_python3}
pushd libs/bindings/python
# %%py3_build
CFLAGS="%{optflags}" %{__python3} setup.py build --executable="%{__python3} -s"
popd
%endif

%if 0%{?with_ruby}
pushd libs/bindings/ruby
CONFIGURE_ARGS="--with-cflags='%{optflags}'" ruby extconf.rb --vendor
%{__make} %{_smp_mflags}
popd
%endif

pushd libs/docs
mkdir -p html
touch html/index.html
%if 0%{?with_docs}
%{__make} %{_smp_mflags}
%endif
popd


%install

mkdir -p %{buildroot}/%{_datadir}/%{name}
cp -p build/monolithic_package/barcode.ps %{buildroot}%{_datadir}/%{name}/barcode.ps

pushd libs/c
%{__make} install-shared DESTDIR=%{buildroot} PREFIX=/usr LIBDIR=%{_libdir}
find %{buildroot}/%{_libdir} -name 'libpostscriptbarcode.so.*' -type f -exec chmod 0755 {} \;
popd

%if 0%{?suse_version}
export NO_BRP_CHECK_BYTECODE_VERSION=true
%endif

pushd libs/bindings/java
mkdir -p %{buildroot}/%{_javadir}/
cp -p *.jar %{buildroot}/%{_javadir}/
mkdir -p %{buildroot}/%{_libdir}/java-postscriptbarcode
cp -p *.so %{buildroot}/%{_libdir}/java-postscriptbarcode/
popd

pushd libs/bindings/perl
find . -type f -exec chmod 0664 {} \;
%{__make} pure_install DESTDIR=%{buildroot} OPTIMIZE="%{optflags}"
find %{buildroot}/%{perl_vendorarch} -type f -name 'postscriptbarcode.so' -exec chmod 0755 {} \;
find %{buildroot}/%{perl_vendorarch} -type f -name .packlist -exec rm -f {} \;
find %{buildroot}/%{perl_vendorarch} -type f -name '*.bs' -empty -exec rm -f {} \;
popd

%if 0%{?with_python3}
pushd libs/bindings/python
# %%py3_install
CFLAGS="%{optflags}" %{__python3} setup.py install -O1 --skip-build --prefix=%{_prefix} --root %{buildroot}
%if 0%{?suse_version}
%fdupes %{buildroot}/%{python3_sitearch}
%endif
popd
%endif

pushd libs/bindings/python
# %%py2_install
CFLAGS="%{optflags}" %{__python2} setup.py install -O1 --skip-build --prefix=%{_prefix} --root %{buildroot}
%if 0%{?suse_version}
%fdupes %{buildroot}/%{python2_sitearch}
%endif
popd

%if 0%{?with_ruby}
pushd libs/bindings/ruby
%{__make} install DESTDIR=%{?buildroot}
popd
%endif


%check
%{__make} test

pushd libs/c
# TODO: re-enable
# %%{__make} test 
popd

pushd libs/bindings/java
ant test
popd

pushd libs/bindings/perl
LD_LIBRARY_PATH="../../c:$LD_LIBRARY_PATH" %{__make} test
popd

pushd libs/bindings/python
LD_LIBRARY_PATH="../../c:$LD_LIBRARY_PATH" PYTHONPATH=%{buildroot}/%{python2_sitearch}:%{buildroot}/%{python2_sitelib} %{__python2} setup.py test
popd

%if 0%{?with_python3}
pushd libs/bindings/python
LD_LIBRARY_PATH="../../c:$LD_LIBRARY_PATH" PYTHONPATH=%{buildroot}/%{python3_sitearch}:%{buildroot}/%{python3_sitelib} %{__python3} setup.py test
popd
%endif

%if 0%{?with_ruby}
pushd libs/bindings/ruby
LD_LIBRARY_PATH="../../c:$LD_LIBRARY_PATH" ruby -I%{buildroot}/%{ruby_vendorarchdir} example.rb
popd
%endif


%post -n %{postscriptbarcode_lib_pkgname} -p /sbin/ldconfig

%postun -n %{postscriptbarcode_lib_pkgname} -p /sbin/ldconfig


%files
%defattr(-,root,root)
%doc CHANGES LICENSE README.md docs/*
%dir %{_datadir}/%{name}/
%{_datadir}/%{name}/barcode.ps

%files -n %{postscriptbarcode_lib_pkgname}
%defattr(-,root,root)
%doc CHANGES LICENSE libs/README.md libs/docs/html/*
%{_libdir}/libpostscriptbarcode.so.*

%files -n %{postscriptbarcode_lib_pkgname}-devel
%defattr(-,root,root)
%doc CHANGES LICENSE libs/README.md
%{_includedir}/*
%{_libdir}/libpostscriptbarcode.so

%files -n java-postscriptbarcode
%defattr(-,root,root)
%doc CHANGES LICENSE libs/README.md
%{_javadir}/*
%dir %{_libdir}/java-postscriptbarcode/
%{_libdir}/java-postscriptbarcode/*

%files -n perl-postscriptbarcode
%defattr(-,root,root)
%doc CHANGES LICENSE libs/README.md
%{perl_vendorarch}/auto/*
%{perl_vendorarch}/auto/postscriptbarcode/*
%{perl_vendorarch}/postscriptbarcode.pm

%files -n %{python2_postscriptbarcode_pkgname}
%defattr(-,root,root)
%doc CHANGES LICENSE libs/README.md
%{python2_sitearch}/*

%if 0%{?with_python3}
%files -n python3-postscriptbarcode
%defattr(-,root,root)
%doc CHANGES LICENSE libs/README.md
%{python3_sitearch}/*
%endif

%if 0%{?with_ruby}
%files -n ruby-postscriptbarcode
%defattr(-,root,root)
%doc CHANGES LICENSE libs/README.md
%{ruby_vendorarchdir}/*
%endif

%changelog

