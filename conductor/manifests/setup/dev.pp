class conductor::setup::dev {
  require conductor::config::dev
  require conductor::setup::dev_depend

  exec { "bundle install":
    cwd => "${aeolus_workdir}/conductor/src",
    command => "bundle install --path bundle",
    logoutput => on_failure,
    # 15 minute timeout because this can take awhile sometimes
    timeout => 900
  }

  exec { "install local aeolus-image-rubygem":
    cwd => "${aeolus_workdir}/conductor/src",
    # the --no-ri and --no-doc are to avoid an
    # "unrecognized option `--encoding'" error on rhel6 or fc16
    command => "gem install -f --no-ri --no-rdoc --install-dir ${aeolus_workdir}/conductor/src/bundle/ruby/1* ${aeolus_workdir}/aeolus-image-rubygem/*.gem",
    logoutput => on_failure,
    onlyif => "/bin/ls ${aeolus_workdir}/aeolus-image-rubygem/*.gem",
    require => Exec["bundle install"]
  }

  exec { "migrate database":
    cwd => "${aeolus_workdir}/conductor/src",
    command => "bundle exec rake db:migrate",
    require => Exec["install local aeolus-image-rubygem"]
  }

  exec { "setup database":
    cwd => "${aeolus_workdir}/conductor/src",
    command => "bundle exec rake db:setup",
    require => Exec["migrate database"]
  }

  exec { "create admin":
    cwd => "${aeolus_workdir}/conductor/src",
    command => "bundle exec 'rake dc:create_admin_user'",
    require => Exec["setup database"]
  }
  exec { "compass compile":
    cwd => "${aeolus_workdir}/conductor/src",
    command => "bundle exec 'compass compile'",
    require => Exec["bundle install"]
  }
}
