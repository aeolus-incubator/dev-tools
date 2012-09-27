class aeolus-image-rubygem::install::dev {
  # TODO, remove if block below, pushing this logic into repo.pp
  #  and use branch => $aeolus_image_rubygem_branch
  # i.e., if $aeolus_image_rubygem_branch is undef, repo.pp knows
  # to use "master"
  if $aeolus_image_rubygem_branch != undef {
     $branch = $aeolus_image_rubygem_branch
  } else {
     $branch = 'master'
  }

  git::repo { aeolus-image-rubygem:
    src => 'git://github.com/aeolusproject',
    dst => "${aeolus_workdir}",
    branch => $branch,
    pull_request => $aeolus_image_rubygem_pull_request
  }
}
