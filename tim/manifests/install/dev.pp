class tim::install::dev {
  # TODO, remove if block below, pushing this logic into repo.pp
  #  and use branch => $tim_branch
  # i.e., if $tim_branch is undef, repo.pp knows
  # to use "master"
  if $tim_branch != undef {
     $branch = $tim_branch
  } else {
     $branch = 'master'
  }

  git::repo { tim:
    src => 'git://github.com/aeolus-incubator',
    dst => "${aeolus_workdir}",
    branch => $branch,
    pull_request => $tim_pull_request
  }
}
