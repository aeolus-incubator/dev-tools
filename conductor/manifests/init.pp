class conductor ($dev = false) {
  if $dev {
    include conductor::install::dev
    include conductor::config::dev
    include conductor::setup::dev
    include conductor::run::dev
  } else {
    include conductor::install
  }
}
