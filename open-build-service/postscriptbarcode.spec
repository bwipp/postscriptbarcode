Name:           postscriptbarcode
Version:        <empty>
Release:        1%{?dist}
Summary:        Barcode Writer in Pure PostScript
Group:          Development/Libraries/Other

License:        MIT
URL:            https://bwipp.terryburton.co.uk
Source0:        https://github.com/bwipp/postscriptbarcode/archive/master.tar.gz#/%{name}-%{version}.tar.gz
BuildArch:      noarch
BuildRequires:  ghostscript
BuildRequires:  perl

# Required for EPEL <= 5
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

%description
Barcode Writer in Pure Postscript generates all barcode formats entirely
within PostScript so that the process of converting the input data into
the printed output can be performed by the printer or RIP itself. This is
ideal for variable data printing (VDP) and avoids the need to re-implement
the barcode generation process whenever your language needs change.

%prep
%setup -q -n %{name}-%{version}

%build
make -j `nproc`

%check
make test

%install
mkdir -p %{buildroot}/%{_datadir}/%{name}
cp -p build/monolithic_package/barcode.ps %{buildroot}%{_datadir}/%{name}/barcode.ps

%files
%defattr(-,root,root)
%doc CHANGES LICENSE README.md docs/*
%dir %{_datadir}/%{name}/
%{_datadir}/%{name}/barcode.ps

%changelog
* Fri Nov 08 2013 Terry Burton <tez@terryburton.co.uk> - 20131102-1
- Configure nightly OBS build
