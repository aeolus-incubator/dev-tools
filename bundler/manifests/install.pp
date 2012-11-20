class bundler::install {

  if $rbenv_version == undef {
    # not using rbenv, install bundler system-wide
    $ruby_devel = $osfamily ? {
	Debian => "ruby1.9.1-dev",
	RedHat => ["ruby-devel", "rubygems"]
	}
    $build_requires = $osfamily ? {
	Debian => build-essential,
	RedHat => ["gcc", "gcc-c++", "make"]
	}
    package { [$ruby_devel,
               $build_requires
              ]: }

    package { 'bundler' :
	ensure => 'installed',
	provider => 'gem',
    }
  }
}
