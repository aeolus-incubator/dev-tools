class conductor::run::dev {
  require conductor::setup::dev

  if $conductor_port == undef {
    $conductor_port = 3000
  }

  exec { "conductor rails server":
    cwd => "${aeolus_workdir}/conductor/src",
    #    command => 'bundle exec "rails server --daemon"',
    command => "bundle exec rails server -p $conductor_port&",
    unless => "/usr/bin/curl http://0.0.0.0:$conductor_port"
  }
}
