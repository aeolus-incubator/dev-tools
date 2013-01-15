# following the lead of the other init.pp's, even though in practice
# $dev is always true
class tim ($dev = false) {
  if $dev {
    include tim::install::dev
  } else {
    include tim::install
  }
}
