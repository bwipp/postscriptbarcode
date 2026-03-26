Name:           postscriptbarcode
Version:        <empty>
Release:        1%{?dist}
Summary:        Barcode Writer in Pure PostScript


#
# This file is intended to provide a guide to packagers of RPM-based distributions to promote consistency.
#
# The packages have been built on the OBS but not necessarily installed and tested:
# https://build.opensuse.org/package/show/home:terryburton:postscriptbarcode/libpostscriptbarcode
#
# Please contribute any improvements back here:
# https://github.com/bwipp/postscriptbarcode/tree/master/packaging-examples
#

# SuSE naming conventions
%if 0%{?suse_version}
%global postscriptbarcode_lib_pkgname libpostscriptbarcode1
%else
%global postscriptbarcode_lib_pkgname postscriptbarcode-libs
%endif

%if 0%{?suse_version}
%{!?ruby_vendorarchdir: %global ruby_vendorarchdir %(ruby -rrbconfig -e 'puts RbConfig::CONFIG["vendorarchdir"]')}
%{!?ruby_vendorlibdir:  %global ruby_vendorlibdir  %(ruby -rrbconfig -e 'puts RbConfig::CONFIG["vendorlibdir"]')}
%endif


License:        MIT
URL:            https://bwipp.terryburton.co.uk
Source0:        https://github.com/bwipp/postscriptbarcode/archive/master/%{name}-%{version}.tar.gz
BuildRequires:  ghostscript
BuildRequires:  swig
BuildRequires:  java-devel
BuildRequires:  ant
BuildRequires:  perl
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  chrpath
BuildRequires:  python3-devel
BuildRequires:  python3-setuptools
BuildRequires:  doxygen

%if 0%{?fedora}
BuildRequires:  ruby(release)
BuildRequires:  ruby-devel
%endif

%if 0%{?rhel}
BuildRequires:  ruby(release)
BuildRequires:  ruby-devel
%endif

%if 0%{?suse_version}
BuildRequires:  ruby
BuildRequires:  ruby-devel
BuildRequires:  fdupes
%endif


%description
Barcode Writer in Pure Postscript generates all barcode formats entirely
within PostScript so that the process of converting the input data into
the printed output can be performed by the printer or RIP itself. This is
ideal for variable data printing (VDP) and avoids the need to re-implement
the barcode generation process whenever your language needs change.


%package -n %{postscriptbarcode_lib_pkgname}
Summary: Shared library for Barcode Writer in Pure PostScript
Requires: postscriptbarcode

%description -n %{postscriptbarcode_lib_pkgname}
This package provides the shared library for Barcode Writer in Pure PostScript.


%package -n %{postscriptbarcode_lib_pkgname}-devel
Summary: Development files for Barcode Writer in Pure PostScript
Requires: %{postscriptbarcode_lib_pkgname} = %{version}-%{release}

%description -n %{postscriptbarcode_lib_pkgname}-devel
Package providing the development files for Barcode Writer in Pure PostScript


%package -n java-postscriptbarcode
Summary: Java binding for Barcode Writer in Pure PostScript
Requires: %{postscriptbarcode_lib_pkgname} = %{version}-%{release}
Requires: java-headless
Requires: javapackages-tools

%description -n java-postscriptbarcode
This package provides the Java binding for Barcode Writer in Pure PostScript


%package -n perl-postscriptbarcode
Summary: Perl binding for Barcode Writer in Pure PostScript
Requires: %{postscriptbarcode_lib_pkgname} = %{version}-%{release}
%if 0%{?fedora} || 0%{?rhel}
Requires: perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
%endif
%if 0%{?suse_version}
%{perl_requires}
%endif

%description -n perl-postscriptbarcode
This package provides the Perl binding for Barcode Writer in Pure PostScript


%package -n python3-postscriptbarcode
Summary: Python binding for Barcode Writer in Pure PostScript
Requires: %{postscriptbarcode_lib_pkgname} = %{version}-%{release}
%{?python_provide:%python_provide python3-postscriptbarcode}

%description -n python3-postscriptbarcode
This package provides the Python binding for Barcode Writer in Pure PostScript


%package -n ruby-postscriptbarcode
Summary: Ruby binding for Barcode Writer in Pure PostScript
Requires: ruby
Requires: %{postscriptbarcode_lib_pkgname} = %{version}-%{release}

%description -n ruby-postscriptbarcode
This package provides the Ruby binding for Barcode Writer in Pure PostScript


%prep
%setup -q -n %{name}-%{version}


%build

%{__make} %{?_smp_mflags}

pushd libs/c
%{__make} %{?_smp_mflags} CFLAGS="%{optflags}"
popd

pushd libs/bindings/java
%ant
popd

pushd libs/bindings/perl
%{__perl} Makefile.PL INSTALLDIRS=vendor OPTIMIZE="%{optflags}" NO_PACKLIST=1
%{__make} %{?_smp_mflags}
find . -name 'postscriptbarcode.so' -exec chrpath -d {} \;
popd

pushd libs/bindings/python
CFLAGS="%{optflags}" %{__python3} setup.py build_ext --inplace
CFLAGS="%{optflags}" %{__python3} setup.py build
popd

pushd libs/bindings/ruby
CONFIGURE_ARGS="--with-cflags='%{optflags}'" ruby extconf.rb --vendor
%{__make} %{?_smp_mflags}
popd

pushd libs/docs
mkdir -p html
touch html/index.html
%{__make} %{_smp_mflags}
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
install -Dm755 libpostscriptbarcode_jni.so %{buildroot}/%{_libdir}/libpostscriptbarcode_jni.so
popd

pushd libs/bindings/perl
find . -type f -exec chmod 0664 {} \;
%{__make} pure_install DESTDIR=%{buildroot} OPTIMIZE="%{optflags}"
find %{buildroot}/%{perl_vendorarch} -type f -name 'postscriptbarcode.so' -exec chmod 0755 {} \;
find %{buildroot}/%{perl_vendorarch} -type f -name .packlist -exec rm -f {} \;
find %{buildroot}/%{perl_vendorarch} -type f -name '*.bs' -empty -exec rm -f {} \;
popd

pushd libs/bindings/python
CFLAGS="%{optflags}" %{__python3} setup.py install -O1 --skip-build --prefix=%{_prefix} --root %{buildroot}
%if 0%{?suse_version}
%fdupes %{buildroot}/%{python3_sitearch}
%endif
popd

pushd libs/bindings/ruby
mkdir -p %{buildroot}/%{ruby_vendorarchdir}
%{__make} install DESTDIR=%{?buildroot}
popd


%check
%{__make} test

pushd libs/c
%{__make} test
popd

pushd libs/bindings/java
ant test
popd

pushd libs/bindings/perl
LD_LIBRARY_PATH="../../c:$LD_LIBRARY_PATH" %{__make} test
popd

pushd libs/bindings/python
LD_LIBRARY_PATH="../../c:$LD_LIBRARY_PATH" PYTHONPATH=%{buildroot}/%{python3_sitearch}:%{buildroot}/%{python3_sitelib} %{__python3} setup.py test
popd

pushd libs/bindings/ruby
LD_LIBRARY_PATH="../../c:$LD_LIBRARY_PATH" ruby -I%{buildroot}/%{ruby_vendorarchdir} example.rb
popd


%files
%doc CHANGES README.md
%license LICENSE
%dir %{_datadir}/%{name}/
%{_datadir}/%{name}/barcode.ps

%files -n %{postscriptbarcode_lib_pkgname}
%doc CHANGES libs/README.md libs/docs/html/*
%license LICENSE
%{_libdir}/libpostscriptbarcode.so.*

%files -n %{postscriptbarcode_lib_pkgname}-devel
%doc CHANGES libs/README.md
%license LICENSE
%{_includedir}/postscriptbarcode.h
%{_includedir}/postscriptbarcode.hpp
%{_libdir}/libpostscriptbarcode.so

%files -n java-postscriptbarcode
%doc CHANGES libs/README.md
%license LICENSE
%{_javadir}/*
%{_libdir}/libpostscriptbarcode_jni.so

%files -n perl-postscriptbarcode
%doc CHANGES libs/README.md
%license LICENSE
%{perl_vendorarch}/auto/postscriptbarcode/
%{perl_vendorarch}/postscriptbarcode.pm

%files -n python3-postscriptbarcode
%doc CHANGES libs/README.md
%license LICENSE
%{python3_sitearch}/*

%files -n ruby-postscriptbarcode
%doc CHANGES libs/README.md
%license LICENSE
%{ruby_vendorarchdir}/*

%changelog

