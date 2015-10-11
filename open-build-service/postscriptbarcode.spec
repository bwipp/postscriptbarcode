Name:           postscriptbarcode
Version:        <empty>
Release:        1%{?dist}
Summary:        Barcode Writer in Pure PostScript
Group:          Development/Libraries

License:        MIT
URL:            http://bwipp.terryburton.co.uk
Source0:        https://github.com/bwipp/postscriptbarcode/archive/master.tar.gz#/%{name}-%{version}.tar.gz
BuildRequires:  ghostscript
BuildRequires:  swig
BuildRequires:  java-devel
BuildRequires:  ant
BuildRequires:  perl-devel
BuildRequires:  python2-devel
BuildRequires:  python3-devel
BuildRequires:  ruby-devel

# Required for EPEL <= 5
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)


%description
Barcode Writer in Pure Postscript generates all barcode formats entirely
within PostScript so that the process of converting the input data into
the printed output can be performed by the printer or RIP itself. This is
ideal for variable data printing (VDP) and avoids the need to re-implement
the barcode generation process whenever your language needs change.


%package libs
Summary: Shared library for Barcode Writer in Pure PostScript
Group: Development/Libraries
Requires: postscriptbarcode = %{version}-%{release}

%description libs
This package provides the shared library for Barcode Writer in Pure PostScript.


%package devel
Summary: Development files for Barcode Writer in Pure PostScript
Group: Development/Libraries
Requires: postscriptbarcode-libs = %{version}-%{release}

%description devel
Package providing the development files for Barcode Writer in Pure PostScript


%package -n java-postscriptbarcode
Summary: Java binding for Barcode Writer in Pure PostScript
Group: Development/Libraries
Requires: postscriptbarcode-libs = %{version}-%{release}
Requires: java-headless
Requires: javapackages-tools

%description -n java-postscriptbarcode
This package provides the Java binding for Barcode Writer in Pure PostScript


%package -n perl-postscriptbarcode
Summary: Perl binding for Barcode Writer in Pure PostScript
Group: Development/Libraries
BuildRequires:  perl, perl(ExtUtils::MakeMaker)
Requires: postscriptbarcode-libs = %{version}-%{release}
Requires: perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description -n perl-postscriptbarcode
This package provides the Perl binding for Barcode Writer in Pure PostScript


%package -n python2-postscriptbarcode
Summary: Python 2 binding for Barcode Writer in Pure PostScript
Group: Development/Libraries
Requires: postscriptbarcode-libs = %{version}-%{release}
%{?python_provide:%python_provide python2-postscriptbarcode}

%description -n python2-postscriptbarcode
This package provides the Python 2 binding for Barcode Writer in Pure PostScript


%package -n python3-postscriptbarcode
Summary: Python 3 binding for Barcode Writer in Pure PostScript
Group: Development/Libraries
Requires: postscriptbarcode-libs = %{version}-%{release}
%{?python_provide:%python_provide python3-postscriptbarcode}

%description -n python3-postscriptbarcode
This package provides the Python 3 binding for Barcode Writer in Pure PostScript


%package -n ruby-postscriptbarcode
Summary: Ruby binding for Barcode Writer in Pure PostScript
Group: Development/Libraries
BuildRequires: ruby
Requires: postscriptbarcode-libs = %{version}-%{release}
Requires: ruby

%description -n ruby-postscriptbarcode
This package provides the Ruby binding for Barcode Writer in Pure PostScript


%prep
%setup -q -n %{name}-%{version}


%build
%{__make} %{_smp_mflags}

pushd libs/c
%{__make} %{_smp_mflags}
popd

pushd libs/bindings/java
%ant
popd

pushd libs/bindings/perl
%{__perl} Makefile.PL INSTALLDIRS=vendor OPTIMIZE="%{optflags}" NO_PACKLIST=1
%{__make} %{_smp_mflags}
popd

pushd libs/bindings/python
%py2_build
popd

pushd libs/bindings/python
%py3_build
popd

pushd libs/bindings/ruby
CONFIGURE_ARGS="--with-cflags='%{optflags}'" ruby extconf.rb --vendor
%{__make} %{_smp_mflags}
popd


%install
mkdir -p %{buildroot}/%{_datadir}/%{name}
cp -p build/monolithic_package/barcode.ps %{buildroot}%{_datadir}/%{name}/barcode.ps

pushd libs/c
%{__make} install-shared DESTDIR=%{buildroot} PREFIX=/usr LIBDIR=%{_libdir}
popd

pushd libs/bindings/java
mkdir -p %{buildroot}/%{_javadir}/
cp -p *.jar %{buildroot}/%{_javadir}/
mkdir -p %{buildroot}/%{_libdir}/java-postscriptbarcode
cp -p *.so %{buildroot}/%{_libdir}/java-postscriptbarcode/
popd

pushd libs/bindings/perl
find . -type f -exec chmod 0664 {} \;
%{__make} pure_install DESTDIR=%{buildroot} OPTIMIZE="%{optflags}"
popd

pushd libs/bindings/python
%py2_install
%py3_install
popd

pushd libs/bindings/ruby
%make_install
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
LD_LIBRARY_PATH="../../c:$LD_LIBRARY_PATH" PYTHONPATH=%{buildroot}/%{python2_sitearch}:%{buildroot}/%{python2_sitelib} %{__python2} setup.py test
popd

pushd libs/bindings/python
LD_LIBRARY_PATH="../../c:$LD_LIBRARY_PATH" PYTHONPATH=%{buildroot}/%{python3_sitearch}:%{buildroot}/%{python3_sitelib} %{__python3} setup.py test
popd

pushd libs/bindings/ruby
LD_LIBRARY_PATH="../../c:$LD_LIBRARY_PATH" ruby -I%{buildroot}/%{ruby_vendorarchdir} example.rb
popd


%post libs -p /sbin/ldconfig

%postun libs -p /sbin/ldconfig


%files
%doc CHANGES LICENSE README.md docs/*
%dir %{_datadir}/%{name}/
%{_datadir}/%{name}/barcode.ps

%files -n postscriptbarcode-libs
%{_libdir}/libpostscriptbarcode.so.*

%files -n postscriptbarcode-devel
%{_includedir}/*
%{_libdir}/libpostscriptbarcode.so

%files -n java-postscriptbarcode
%{_javadir}/*
%dir %{_libdir}/java-postscriptbarcode/
%{_libdir}/java-postscriptbarcode/*

%files -n perl-postscriptbarcode
%{perl_vendorarch}/*

%files -n python2-postscriptbarcode
%{python2_sitearch}/*

%files -n python3-postscriptbarcode
%{python3_sitearch}/*

%files -n ruby-postscriptbarcode
%{ruby_vendorarchdir}/*

%changelog
* Fri Nov 08 2013 Terry Burton <tez@terryburton.co.uk> - 20150810-0
- Configure nightly OBS build
