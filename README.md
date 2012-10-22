# Aeolus dev-tools

Use bootstrap.sh to setup a devolpment environment for the aeolus
projects: conductor, aeolus-image-rubygem, and aeolus-cli, and to
start up an instance of conductor.  While useful to developers, it
also provides the capability to quicky test various branches, pull
requests, and ruby versions.

# Quick Start

As the root user on a host you want to install Aeolus on:

  If you want to use system ruby:

    # curl https://raw.github.com/aeolus-incubator/dev-tools/master/bootstrap.sh | /bin/sh -x

  If you want to use a specific ruby version via rbenv:

    # export RBENV_VERSION=1.9.3-p194; curl https://raw.github.com/aeolus-incubator/dev-tools/master/bootstrap.sh | /bin/sh -x

This should work on rhel6, fc16 and fc17 (the script's env variables +
oauth.json are pointing to existing imagefactory/iwhd/deltacloud
instances).

The default bootstrap.sh behaviour includes creating a development
environment for the system user test in the directory /tmp/test and
starting up Conductor on port 3000.  To override these settings, set
the relevant environment variables before running bootstrap.sh, e.g.:

    export DEV_USERNAME=myuser
    export WORKDIR=/home/myuser/cloud-dev
    export FACTER_CONDUCTOR_PORT=3001

There are other useful environment variables described further in this
document, for example to point to existing deltacloud, image factory
and/or image warehouse instances, or to apply a pull request.

# bootstrap.sh: Overview and Defaults

boostrap.sh checks out and configures the three aformentioned Aeolus
projects, configures conductor (including specifying a local sqlite
database) and starts it up.  There are a number of environment
variables you may wish to define, otherwise they get the following
defaults:

  The user that owns the git checkouts, and that we use to run
  bundler, rake and rails commands (ultimately firing up conductor):

    DEV_USERNAME=test

  Parent dir where the dev-tools puppet code gets checked out to:

    WORKDIR=/tmp/$DEV_USERNAME

  Parent dir where the projects conductor, aeolus-cli and
  aeolus-image-rubygem get checked out to (by default same as above):

    FACTER_AEOLUS_WORKDIR=$WORKDIR

  Port that Conductor gets started up on:

    FACTER_CONDUCTOR_PORT=3000

  Which ruby that is used to configure and start up conductor, via
  rbenv.  It is undefined by default, meaning just use system ruby and
  not rbenv:

    RBENV_VERSION=

  URL's to API's that conductor relies on, namely deltacloud, image
  factory, and image warehouse.  A valid oauth.json also must be
  specified, which contains credentials specific to your Image Factory
  and Image Warehouse instance.

    FACTER_DELTACLOUD_URL=http://localhost:3002/api
    FACTER_IMAGEFACTORY_URL=https://localhost:8075/imagefactory
    FACTER_IWHD_URL=http://localhost:9090
    FACTER_OAUTH_JSON_FILE=/etc/aeolus-conductor/oauth.json

  Git branches that are checked out:

    FACTER_AEOLUS_CLI_BRANCH=master
    FACTER_AEOLUS_IMAGE_RUBYGEM_BRANCH=master
    FACTER_CONDUCTOR_BRANCH=master

  By default no Github pull requests are defined.  If you wish to
  apply a pull request to a given project, the pull request itself
  must be active and it must be specified as an integer:

    FACTER_AEOLUS_CLI_PULL_REQUEST=
    FACTER_AEOLUS_IMAGE_RUBYGEM_PULL_REQUEST=
    FACTER_CONDUCTOR_PULL_REQUEST=


# The Development Environment

Running bootstrap.sh as root creates a development environment for the
system user $DEV_USERNAME which contains the following directory
structure:

    $WORKDIR/
      conductor/            # git checkout of https://github.com/aeolusproject/conductor
      aeolus-cli/           # git checkout of https://github.com/aeolusproject/aeolus-cli
      aeolus-image-rubygem/ # git checkout of https://github.com/aeolusproject/aeolus-image-rubygem

While bootstrap.sh must be run as root to install needed system
dependencies (e.g., libxml2 to build the nokogiri gem), the
environment it creates is intended to be used by the non-privileged
user, $DEV_USERNAME.

Therefore, once the script completes, you can open up a terminal as
the $DEV_USERNAME user, cd into your $WORKDIR and get to work.  For
instance, you could do:

    $ cd $WORKDIR/conductor/src
    $ bundle exec rake db:setup
    $ bundle exec rake dc:create_admin_user
    $ bundle exec rails s

Note that if you are using rbenv (i.e. an $RBENV_VERSION was specified
in bootstrap.sh), you will need to specify the same ruby in your
terminal.  See "Using rbenv" below.

# Bundler

Bundler is used to install needed Gemfile dependencies.  For
conductor, the --path used for "bundle install" is
$WORKDIR/conductor/src/bundle (regardless of whether rbenv is used or
not).

# Using rbenv (optional)

If $RBENV_VERSION is defined when bootstrap.sh runs
(e.g. $RBENV_VERSION=1.9.3-p194), rbenv will be installed (if
necessary) to $DEV_USERNAME's home directory, and the specified ruby
version will be built and installed therein.

No changes to $DEV_USERNAME's shell are made, intentionally.  Rbenv
users often update their shell behaviour, for example with:

    $ echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
    $ echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
    (from http://mifo.sk/rbenv-simple-ruby-managment-in-fedora)

Otherwise, one could also get all of the needed rbenv functionality by
prepending ~/.rbenv/bin:~/.rbenv/shims to one's current $PATH.  For
example:

    $ export PATH=~/.rbenv/bin:~/.rbenv/shims:$PATH

With the path set as above, if the user is in a working directory
where "rbenv local" was invoked to specify a ruby version (or had been
set in one of its parent dirs, recursively), they will pick up that
version which can be verified by "rbenv which ruby".  What all of this
means is that if the user has their path rbenv'ed, they will get the
right version of ruby (whether a system or an rbenv version ruby) when
they cd anywhere under $FACTER_AEOLUS_WORKDIR.

If you're not yet familiar to rbenv, the following is a quick
illustration showing: how to see what ruby versions are available, how
to set a global version (though bootstrap.sh does not do this or
require it) and to see which version of ruby is currently set.

    $ which ruby
    ~/.rbenv/shims/ruby
    $ rbenv which ruby
    /usr/bin/ruby
    $ rbenv versions
      1.8.7-p370
      1.9.3-p194
    $ rbenv global 1.9.3-p194
    $ rbenv which ruby
    /home/test/.rbenv/versions/1.9.3-p194/bin/ruby

The above also works well in an emacs shell.  ;-)

# Puppet

bootstrap.sh makes heavy use of the puppet definitions within this
repository to create and configure
conductor/aeolus-cli/aeolus-image-rubygem.  In its current form,
puppet (and its ruby dependency) are installed system-wide if needed.
Note that even though system ruby may be installed to run puppet,
rbenv's ruby (if specified) is used to for all the bundle, rake and
rails work.

# See Also
* http://blog.aeolusproject.org/upstream-conductor-development
* https://lists.fedorahosted.org/pipermail/aeolus-devel/2012-September/012684.html
* https://lists.fedorahosted.org/pipermail/aeolus-devel/2012-September/012599.html
