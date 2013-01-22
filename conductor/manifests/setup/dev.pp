class conductor::setup::dev {
  require conductor::config::dev

  # this next block is going away soon
  exec { "patch Gemfile to point to local aeolus-image-rubygem":
    cwd => "${aeolus_workdir}/conductor/src",
    onlyif => "test -f ${aeolus_workdir}/aeolus-image-rubygem/aeolus-image-*.gem",
    command => "sed -i \"s#gem 'aeolus-image', :git.*\\\$#gem 'aeolus-image', :path => '${aeolus_workdir}/aeolus-image-rubygem'#\" Gemfile"
  }

  exec { "patch Gemfile to point to local tim source":
    cwd => "${aeolus_workdir}/conductor/src",
    onlyif => "test -d ${aeolus_workdir}/tim",
    command => "sed -i \"s#gem 'tim', :git.*\\\$#gem 'tim', :path => '${aeolus_workdir}/tim'#\" Gemfile"
  }

  exec { "bundle install":
    cwd => "${aeolus_workdir}/conductor/src",
    command => "bundle install --path bundle",
    logoutput => on_failure,
    # 15 minute timeout because this can take awhile sometimes
    timeout => 900,
    require => Exec["patch Gemfile to point to local aeolus-image-rubygem",
                    "patch Gemfile to point to local tim source"]
  }

  exec { "create database":
    cwd => "${aeolus_workdir}/conductor/src",
    command => "bundle exec rake db:create:all",
    require => Exec["bundle install"]
  }

  exec { "migrate database":
    cwd => "${aeolus_workdir}/conductor/src",
    command => "bundle exec rake db:migrate",
    require => Exec["create database"]
  }

  exec { "setup database":
    cwd => "${aeolus_workdir}/conductor/src",
    command => "bundle exec rake db:setup",
    require => Exec["migrate database"]
  }

  exec { "setup delayed_job to log locally":
    cwd => "${aeolus_workdir}/conductor/src",
    command => "echo 'Delayed::Worker.logger = Rails.logger' >> config/initializers/delayed_job.rb",
  }

  exec { "create admin":
    cwd => "${aeolus_workdir}/conductor/src",
    command => "bundle exec rake dc:create_admin_user",
    require => Exec["setup database"]
  }
  exec { "compass compile":
    cwd => "${aeolus_workdir}/conductor/src",
    command => "bundle exec compass compile",
    require => Exec["bundle install"]
  }
}
