%global commit [ Git commit in the format: 4f527ecd2841df0ae91dfb4f350f0098b0ccdb9b ]
%global shortcommit %(c=%{commit}; echo ${c:0:7})

Name:           postscriptbarcode
Version:        [ Version in the format: 20140620 ]
Release:        1%{?dist}
Summary:        Barcode Writer in Pure PostScript
Group:          Development/Libraries/Other

License:        MIT
URL:            https://github.com/bwipp/postscriptbarcode 
Source0:        https://github.com/bwipp/postscriptbarcode/archive/%{commit}/%{name}-%{commit}.tar.gz

BuildArch:      noarch
BuildRequires:  ghostscript
BuildRequires:  perl

%description
Barcode Writer in Pure Postscript generates all barcode formats entirely
within PostScript so that the process of converting the input data into
the printed output can be performed by the printer or RIP itself. This is
ideal for variable data printing (VDP) and avoids the need to re-implement
the barcode generation process whenever your language needs change.

%prep
%setup -q -n %{name}-%{commit}

%build
make -j `nproc`

%install
mkdir -p %{buildroot}/%{_datadir}/%{name}
cp -p build/monolithic_package/barcode.ps %{buildroot}%{_datadir}/%{name}/barcode.ps

%check
make test

%files
%doc CHANGES  LICENSE  README.md docs/*
%dir %{_datadir}/%{name}/
%{_datadir}/%{name}/barcode.ps

%changelog
* Thu Jun 20 2014 Terry Burton <tez@terryburton.co.uk> - 20140620-1
- New upstream version
- Permanent download link from GitHub
- Build all flavours of the resource and run tests
- Install the "monolithic package" flavour of the resource

* Thu Oct 31 2013 Mario Blättermann <mariobl@fedoraproject.org> - 20131006-2
- Add folder ownership for %%{_datadir}/%%{name}/

* Wed Oct 23 2013 Mario Blättermann <mariobl@fedoraproject.org> - 20131006-1
- New upstream version
- Permanent download link instead of Google Drive

* Tue Sep 03 2013 Mario Blättermann <mariobl@fedoraproject.org> - 20130603-2
- Renamed to postscriptbarcode
- Build from sources instead of copying the single Postscript file

* Sun Sep 01 2013 Mario Blättermann <mariobl@fedoraproject.org> - 20130603-1
- Initial package
