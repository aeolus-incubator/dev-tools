class aeolus_dev_tools_path {
  if $rbenv_home != undef {
    Exec { path => "$rbenv_home/bin:$rbenv_home/shims:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin",
             logoutput => "on_failure" }
  } elsif $gem_home != undef {
    Exec { path => "$gem_home/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin",
             logoutput => "on_failure" }
  } else {
    Exec { path => "/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin",
           logoutput => "on_failure" }
  }
  if $aeolus_workdir == undef {
    $aeolus_workdir = '/tmp'
  }
  if $oauth_json_file == undef {
     $oauth_json_file = "/tmp/oauth.json"
  }
}

class aeolus_dev_tools_install inherits aeolus_dev_tools_path {
  class { tim: dev => true } -> class { conductor: dev => true }
  class { aeolus-cli: dev => true }
}

class {'aeolus_dev_tools_install':}
