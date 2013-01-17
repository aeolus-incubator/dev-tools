# Aeolus dev-tools

Use bootstrap.sh to setup a development environment for the Aeolus
projects conductor, aeolus-image-rubygem, and aeolus-cli, and to start
up an instance of conductor.  While useful to developers, it also
provides the capability to quickly test various branches, tags, pull
requests and ruby versions.

# Quick Start

As a sudo-user on a host you want to install Aeolus on:

  If you want to use system ruby:

    # curl https://raw.github.com/aeolus-incubator/dev-tools/master/bootstrap.sh | /bin/bash -x
    (lots of output here)

  If you want to use a specific ruby version via rbenv:

    # export RBENV_VERSION=1.9.3-p362; curl https://raw.github.com/aeolus-incubator/dev-tools/master/bootstrap.sh | /bin/bash -x
    (lots of output here)

Note, if you do not have or do not wish to use sudo, you can still run
bootstrap.sh assuming all needed dependencies are installed by defining
"export HAVESUDO=0" beforehand.

Either of the above commands will work on: RHEL 6, Fedora 16/17, and
Ubuntu 12.04/12.10.  Note, for the local instance of Conductor to be
fully functional, some env variables (described below) need to point
to existing imagefactory/iwhd/deltacloud instance URLs and an
oauth.json credential.  Otherwise, Conductor will still start up but
won't be very usable.

The default bootstrap.sh behaviour includes creating a development
environment and starting up Conductor on port 3000.  To override these
settings, set the relevant environment variables before running
bootstrap.sh, e.g.:

    export WORKDIR=/home/myuser/cloud-dev
    export FACTER_CONDUCTOR_PORT=3001

There are other useful environment variables described further in this
document, for example to point to existing deltacloud, image factory
and/or image warehouse instances and/or to apply a pull request.

# bootstrap.sh: Overview and Defaults

bootstrap.sh checks out and configures the three aforementioned Aeolus
projects, configures conductor (including specifying a local sqlite
database) and starts it up.  There are a number of environment
variables you may wish to define, otherwise they get the following
defaults:

  Parent dir where the dev-tools puppet code gets checked out to:

    WORKDIR=~/aeolus-workdir

  Parent dir where the projects conductor, aeolus-cli and
  aeolus-image-rubygem get checked out to (by default same as above):

    FACTER_AEOLUS_WORKDIR=$WORKDIR

  Port that Conductor gets started up on:

    FACTER_CONDUCTOR_PORT=3000

  Which ruby to use to configure and start up conductor, via rbenv.
  It is undefined by default, meaning just use system ruby and not
  rbenv:

    RBENV_VERSION=

  URL's to API's that conductor relies on, namely deltacloud, image
  factory, and image warehouse.  A valid oauth.json also must be
  specified, which contains credentials specific to your Image Factory
  and Image Warehouse instance.

    FACTER_DELTACLOUD_URL=http://localhost:3002/api
    FACTER_IMAGEFACTORY_URL=https://localhost:8075/imagefactory
    FACTER_IWHD_URL=http://localhost:9090
    FACTER_OAUTH_JSON_FILE=/tmp/oauth.json

  Git tags, branches or commit hashes that are checked out: (even
  though the env variables are named "_BRANCH," a git tag or commit
  hash may be used)

    FACTER_AEOLUS_CLI_BRANCH=master
    FACTER_AEOLUS_IMAGE_RUBYGEM_BRANCH=master
    FACTER_CONDUCTOR_BRANCH=master

  By default no GitHub pull requests are defined.  If you wish to
  apply a pull request to a given project, the pull request itself
  must be active and it must be specified as an integer:

    FACTER_AEOLUS_CLI_PULL_REQUEST=
    FACTER_AEOLUS_IMAGE_RUBYGEM_PULL_REQUEST=
    FACTER_CONDUCTOR_PULL_REQUEST=

  Rather point to an existing deltacloud instance, the user can
  request that deltacloud is built from source with a given release
  tag and started locally:

    SETUP_LOCAL_DELTACLOUD_RELEASE=release-1.0.5
    SETUP_LOCAL_DELTACLOUD_PORT=3002

# The Development Environment

Running bootstrap.sh creates a development environment with the
following directory structure:

    $WORKDIR/
      conductor/            # git checkout of https://github.com/aeolusproject/conductor
      aeolus-cli/           # git checkout of https://github.com/aeolusproject/aeolus-cli
      aeolus-image-rubygem/ # git checkout of https://github.com/aeolusproject/aeolus-image-rubygem
      deltacloud/           # only created if SETUP_LOCAL_DELTACLOUD_RELEASE is defined,
                            # a git checkout of a release from
                            # https://git-wip-us.apache.org/repos/asf?p=deltacloud.git

System dependencies (e.g., libxml2 to build the nokogiri gem) are
installed via sudo, if necessary.

Once the script completes, you can open up another terminal (or use
the same one), cd into your $WORKDIR and get to work.  For instance,
you could do:

    $ cd $WORKDIR/conductor/src
    $ bundle exec rake db:setup
    $ bundle exec rake dc:create_admin_user
    $ bundle exec rails s
    (Just for illustration, bootstrap.sh already does the above during setup)

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
(e.g. $RBENV_VERSION=1.9.3-p362), rbenv will be installed (if
necessary) in your home directory, and the specified ruby version will
be built and installed therein.

No changes to your user's shell are made, intentionally.  Rbenv
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
right version of ruby (the version that bootstrap.sh used, system or
rbenv ruby) when they cd anywhere under $FACTER_AEOLUS_WORKDIR.

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
conductor/aeolus-cli/aeolus-image-rubygem.

# See Also
* http://blog.aeolusproject.org/upstream-conductor-development
* https://lists.fedorahosted.org/pipermail/aeolus-devel/2012-September/012684.html
* https://lists.fedorahosted.org/pipermail/aeolus-devel/2012-September/012599.html
