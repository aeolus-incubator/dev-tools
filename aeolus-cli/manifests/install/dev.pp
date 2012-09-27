class aeolus-cli::install::dev {
  # TODO, remove if block below, pushing this logic into repo.pp
  #  and use branch => $aeolus_cli_branch
  # i.e., if $aeolus_cli_branch is undef, repo.pp knows
  # to use "master"
  if $aeolus_cli_branch != undef {
     $branch = $aeolus_cli_branch
  } else {
     $branch = 'master'
  }

  git::repo { aeolus-cli:
    src => 'git://github.com/aeolusproject',
    dst => "${aeolus_workdir}",
    branch => $branch,
    pull_request => $aeolus_cli_pull_request
  }
}
