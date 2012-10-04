class aeolus_dev_tools_path {
  if $rbenv_home == undef {
    Exec { path => "/bin:/sbin:/usr/bin:/usr/sbin",
           logoutput => "on_failure" }
  } else {
    Exec { path => "$rbenv_home/bin:$rbenv_home/shims:/bin:/sbin:/usr/bin:/usr/sbin",
             logoutput => "on_failure" }
  }
  if $aeolus_workdir == undef {
    $aeolus_workdir = '/tmp'
  }
}

class aeolus_dev_tools_install inherits aeolus_dev_tools_path {
  if $id == 'root' {
    # only install system dependencies
    class { conductor: dev => true }
  } else {
    class { aeolus-image-rubygem: dev => true } -> class { conductor: dev => true }
    class { aeolus-cli: dev => true }
  }
}

class {'aeolus_dev_tools_install':}
