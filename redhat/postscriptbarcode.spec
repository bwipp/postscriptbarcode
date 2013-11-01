%global commit 5dfc33e823c582a1ffa47e9d6c768095c637203e
%global shortcommit %(c=%{commit}; echo ${c:0:7})

Name:           postscriptbarcode
Version:        20131006
Release:        1%{?dist}
Summary:        Barcode Writer in Pure PostScript

License:        MIT
URL:            https://code.google.com/p/postscriptbarcode/ 
Source0:        https://github.com/terryburton/postscriptbarcode/archive/%{commit}/%{name}-%{version}-%{shortcommit}.tar.gz
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
make monolithic

%install
mkdir -p %{buildroot}/%{_datadir}/%{name}
cp -p build/monolithic/barcode.ps %{buildroot}%{_datadir}/%{name}/barcode.ps

%files
%doc CHANGES  LICENSE  README TODO docs/*
%{_datadir}/%{name}/barcode.ps

%changelog
* Fri Nov 01 2013 Terry Burton <tez@terryburton.co.uk> - 20131006-2
- Permanent download link from GitHub

* Wed Oct 23 2013 Mario Blättermann <mariobl@fedoraproject.org> - 20131006-1
- New upstream version
- Permanent download link instead of Google Drive

* Tue Sep 03 2013 Mario Blättermann <mariobl@fedoraproject.org> - 20130603-2
- Renamed to postscriptbarcode
- Build from sources instead of copying the single Postscript file

* Sun Sep 01 2013 Mario Blättermann <mariobl@fedoraproject.org> - 20130603-1
- Initial package
