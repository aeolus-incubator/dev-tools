if $rbenv_version == undef {
  Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
         logoutput => "on_failure" }
} else {
  Exec { path => [ "~/.rbenv/bin", "~/.rbenv/shims", "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
         logoutput => "on_failure" }
}

# if not defined by facter
if $aeolus_workdir == undef {
  $aeolus_workdir = '/tmp'
}

if $id == 'root' {
  # only install system dependencies
  class { conductor: dev => true }
} else {
  class { aeolus-image-rubygem: dev => true } -> class { conductor: dev => true }
  class { aeolus-cli: dev => true }
}
