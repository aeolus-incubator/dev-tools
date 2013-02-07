class conductor::run::dev {
  require conductor::setup::dev

  if $conductor_port == undef {
    $conductor_port = 3000
  }

  # exec { "conductor rails server":
  #   cwd => "${aeolus_workdir}/conductor/src",
  #   #    command => 'bundle exec "rails server --daemon"',
  #   command => "bundle exec \"rails server -p $conductor_port\"&",
  #   unless => "/usr/bin/curl http://0.0.0.0:$conductor_port"
  # }
  # exec { "conductor delayed_job":
  #   cwd => "${aeolus_workdir}/conductor/src",
  #   command => "bundle exec \"rake jobs:work\"&",
  #   require => Exec["wait for rails to start"]
  # }
  # exec { "conductor dbomatic":
  #   cwd => "${aeolus_workdir}/conductor/src",
  #   command => "bundle exec \"ruby dbomatic/dbomatic --log log --pid-file tmp -n\"&",
  #   require => Exec["wait for rails to start"]
  # }
  # above three commands now executed by the script below
  exec { "conductor start":
    path => "${aeolus_workdir}/bin",
    command => "conductor start",
    require => File["${aeolus_workdir}/conductor/src/tmp"]
  }
  # make sure dir exists for conductor/foreman pid file
  file { "${aeolus_workdir}/conductor/src/tmp":
    ensure => "directory"
  }
  exec { "wait for rails to start":
    # since we backgrounded starting up rails, let's make sure it started up
    cwd => "${aeolus_workdir}/conductor/src",
    command => "/bin/sh -c 'while ! lsof -i :$conductor_port; do sleep 1; done'",
    # give rails 45 seconds to start up or give up
    timeout => 45,
    require => Exec["conductor start"]
  }
}
