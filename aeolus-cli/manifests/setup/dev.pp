class aeolus-cli::setup::dev {
  require aeolus-cli::install::dev
  require bundler
  #exec { "bundle install":
  #  cwd => "${aeolus_workdir}/aeolus-cli/src", 
  #  command => "bundle install --path bundle",
  #  logoutput => on_failure,
  #  #    require => Package[$dependencies]
  #}
  #exec { "gem build aeolus-image.gemspec":
  #  cwd => "${aeolus_workdir}/aeolus-cli", 
  #  command => "gem build aeolus-image.gemspec",
  #  logoutput => on_failure,
  #}
}
