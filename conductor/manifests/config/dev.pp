class conductor::config::dev {
  require conductor::install::dev

  if $rdbms == 'sqlite' {
    exec { "use sqlite gem":
      cwd => "${aeolus_workdir}/conductor/src",
      command => "sed -i s/'pg'/'sqlite3'/ Gemfile"
    }

    exec { "sqlite database.yml":
      cwd => "${aeolus_workdir}/conductor/src",
      command => "cp config/database.sqlite config/database.yml",
    }
  }
  elsif $rdbms == 'postgresql' {
    file{ "${aeolus_workdir}/conductor/src/config/database.yml":
      content => template("conductor/database.pg"),
      mode => 640,
      # mode    => 640, owner => 'root', group => 'aeolus'
    }
  }

  exec { "use established ouath.json if it exists":
    cwd => "${aeolus_workdir}/conductor/src/config",
    onlyif => "test -f ${oauth_json_file}",
    command => "cp ${oauth_json_file} ${aeolus_workdir}/conductor/src/config/oauth.json"
   }

   if $imagefactory_oauth_user {
     # then conductor/lib/facter/oauth.rb found our ouath keys
     file{ "${aeolus_workdir}/conductor/src/config/settings.yml":
       content => template("conductor/conductor-settings.yml"),
       mode => 640,
     # mode    => 640, owner => 'root', group => 'aeolus'
     }
   } else {
     # a no-op, but define the file object so url dependencies below
     # work as expected
     file{ "${aeolus_workdir}/conductor/src/config/settings.yml" :}
   }

   # and update url's
   if $deltacloud_url != undef {
     exec { "update deltacloud_url":
       cwd => "${aeolus_workdir}/conductor/src/config",
       command => "sed -i s#http://localhost:3002/api#$deltacloud_url# settings.yml",
       require => File["${aeolus_workdir}/conductor/src/config/settings.yml"]
     }
   }
   if $iwhd_url != undef {
     exec { "update iwhd_url":
       cwd => "${aeolus_workdir}/conductor/src/config",
       command => "sed -i s#http://localhost:9090#$iwhd_url# settings.yml",
       require => File["${aeolus_workdir}/conductor/src/config/settings.yml"]
     }
   }
   if $imagefactory_url != undef {
     exec { "update imagefactory_url":
       cwd => "${aeolus_workdir}/conductor/src/config",
       command => "sed -i s#https://localhost:8075/imagefactory#$imagefactory_url# settings.yml",
       require => File["${aeolus_workdir}/conductor/src/config/settings.yml"]
     }
   }

}
