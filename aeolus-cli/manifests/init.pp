class aeolus-cli ($dev = false) {
  if $dev {
    include aeolus-cli::install::dev
#    include aeolus-cli::config::dev
    include aeolus-cli::setup::dev
#    include aeolus-cli::run::dev
  } else {
    include aeolus-cli::install
  }
}
