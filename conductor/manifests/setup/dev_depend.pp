class conductor::setup::dev_depend {
  require bundler

  $libffi_devel = $osfamily ? {
	Debian => libffi-dev,
	RedHat => libffi-devel
	}
  $libxml2_devel = $osfamily ? {
	Debian => libxml2-dev,
	RedHat => libxml2-devel
	}

  $libxslt_devel = $osfamily ? {
	Debian => libxslt1-dev,
	RedHat => libxslt-devel
	}

  $sqlite_devel = $osfamily ? {
	Debian => libsqlite3-dev,
	RedHat => sqlite-devel
	}

  package { $libffi_devel: }
  package { $libxml2_devel: }
  package { $libxslt_devel: }
  package { $sqlite_devel: }
}
