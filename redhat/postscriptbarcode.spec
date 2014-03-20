%global commit 5843dcc374d55db26287f3c23ffdb8d6b6a164ed
%global shortcommit %(c=%{commit}; echo ${c:0:7})

Name:           postscriptbarcode
Version:        20131102
Release:        3%{?dist}
Summary:        Barcode Writer in Pure PostScript
Group:          Development/Libraries/Other

License:        MIT
URL:            https://code.google.com/p/postscriptbarcode/ 
#Source0:        https://github.com/bwipp/postscriptbarcode/archive/%{commit}/%{name}-%{version}-%{shortcommit}.tar.gz
Source0:        https://github.com/bwipp/postscriptbarcode/archive/5843dcc374d55db26287f3c23ffdb8d6b6a164ed/postscriptbarcode-20131102-5843dcc.tar.gz
BuildArch:      noarch
BuildRequires:  ghostscript
BuildRequires:  perl

# Required for EPEL5 <= 5
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

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
make test

%install
mkdir -p %{buildroot}/%{_datadir}/%{name}
cp -p build/monolithic_package/barcode.ps %{buildroot}%{_datadir}/%{name}/barcode.ps

%files
%defattr(-,root,root)
%doc CHANGES  LICENSE  README TODO docs/*
%dir %{_datadir}/%{name}/
%{_datadir}/%{name}/barcode.ps

%changelog
* Fri Nov 08 2013 Terry Burton <tez@terryburton.co.uk> - 20131102-1
- Permanent download link from GitHub
- Compatibility changes for old EPEL and SuSE

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
