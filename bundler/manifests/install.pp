class bundler::install {

  if $rbenv_version == undef {
    # not using rbenv, install bundler system-wide
    package { ["ruby-devel",
               "gcc",
               "gcc-c++",
               "make"]: }

    if  $lsbdistid == 'RedHatEnterpriseServer' and $lsbmajdistrelease == '6' {
      package { ["rubygems"]: }
      exec { "gem install bundler":
           cwd => "${aeolus_workdir}",
           command => "gem install bundler",
           require => Package["rubygems"],
            unless =>  "gem list bundler | grep -q bundler" }

    } else {
      package { ["rubygem-bundler"]: }
    }
  }
}
