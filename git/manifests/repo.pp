define git::repo (
  $src = "",
  $dst = "",
  $branch = "master",
  $pull_request = undef
  ) {

  require git::install

  # TODO assert $pull_request is int or undef
  
  exec { "clone-repo-${name}":
    creates         => "${dst}/${name}/.git",
    path            => "/usr/bin:/bin:/usr/local/bin",
    command         => "git clone ${src}/${name} ${dst}/${name}",
    require         => Package["git"],
  }

  exec { "branch-repo-${name}-${branch}":
    cwd             => "$dst/$name",
    path            => "/usr/bin:/bin:/usr/local/bin",
    command         => "git checkout ${branch}",
    # Below would not work for checking out tags or commit hashes
    #unless          => "grep -q ${branch} ${dst}/${name}/.git/HEAD || ( ! ( git branch -r | grep origin/${branch} ) )",
    require         => Exec["clone-repo-${name}"],
  }

  if ($pull_request != undef) {
    $https_src = regsubst($src, 'git:', 'https:')
    
    exec { "apply-pull-requeust-repo-${name}-${branch}-${pull}":
      cwd             => "$dst/$name",
      path            => "/usr/bin:/bin:/usr/local/bin",
      command         => "curl ${https_src}/${name}/pull/${pull_request}.patch | patch -p1",
      require         => Exec["branch-repo-${name}-${branch}"],
    }
  }
}
