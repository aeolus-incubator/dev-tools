class aeolus-image-rubygem ($dev = false) {
  if $dev {
    include aeolus-image-rubygem::install::dev
#    include aeolus-image-rubygem::config::dev
    include aeolus-image-rubygem::setup::dev
#    include aeolus-image-rubygem::run::dev
  } else {
    include aeolus-image-rubygem::install
  }
}
