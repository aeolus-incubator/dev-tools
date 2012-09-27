class aeolus-image-rubygem::setup::dev {
  require aeolus-image-rubygem::install::dev
  require bundler
  #exec { "bundle install":
  #  cwd => "${aeolus_workdir}/aeolus-image-rubygem/src", 
  #  command => "bundle install --path bundle",
  #  logoutput => on_failure,
  #  #    require => Package[$dependencies]
  #}
  exec { "gem build aeolus-image.gemspec":
    cwd => "${aeolus_workdir}/aeolus-image-rubygem", 
    command => "gem build aeolus-image.gemspec",
    logoutput => on_failure,
  }
}
