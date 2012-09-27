class conductor ($dev = false) {
  if $dev {
    if $id == 'root' {
      # only install system dependencies
      include conductor::setup::dev_depend
    } else {
      include conductor::install::dev
      include conductor::config::dev
      include conductor::setup::dev
      include conductor::run::dev
    }
  } else {
    include conductor::install
  }
}
