class conductor::setup::dev_depend {
  require bundler

  $dependencies = [
		   "libffi-devel",  #ffi
                   "libxml2-devel", #nokogiri
                   "libxslt-devel", #nokogiri
                   "sqlite-devel"   #sqlite3
                  ]

  package { $dependencies: }
}
