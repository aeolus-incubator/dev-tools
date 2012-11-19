#!/bin/bash

# Setup a development environment for conductor, aeolus-image-rubygem
# and aeolus-cli.  Configure conductor to use an external
# imagefactory/iwhd/deltacloud by setting env variables and
# oauth.json, below.  Startup conductor on port 3000

if [ "x$WORKDIR" = "x" ]; then
  export WORKDIR=~/aeolus-workdir
fi

# Where the aeolus projects (conductor, aeolus-cli and aeolus-image-rubygem)
# get checked out to
if [ "x$FACTER_AEOLUS_WORKDIR" = "x" ]; then
  export FACTER_AEOLUS_WORKDIR=$WORKDIR
fi

# Port to start up conductor on
if [ "x$FACTER_CONDUCTOR_PORT" = "x" ]; then
  export FACTER_CONDUCTOR_PORT=3000
fi

# If you want to use system ruby for the aeolus projects, do not
# define this env var.  Otherwise, use (and install if necessary)
# specified ruby version locally in ~/.rbenv for $DEV_USERNAME
# export RBENV_VERSION=1.9.3-p194

if `netstat -tlpn | grep -q -P "\:$FACTER_CONDUCTOR_PORT\\s"`; then
  echo "A process is already listening on port $FACTER_CONDUCTOR_PORT.  Aborting"
  exit 1
fi

if [ -e $FACTER_AEOLUS_WORKDIR/conductor ] || [ -e $FACTER_AEOLUS_WORKDIR/aeolus-image-rubygem ] || \
  [ -e $FACTER_AEOLUS_WORKDIR/aeolus-cli ]; then
  echo -n "Already existing directories, one of $FACTER_AEOLUS_WORKDIR/conductor, "
  echo "$FACTER_AEOLUS_WORKDIR/aeolus-image-rubygem or $FACTER_AEOLUS_WORKDIR/aeolus-cli.  Aborting"
  exit 1
fi

os=unsupported
if `grep -Eqs 'Red Hat Enterprise Linux Server release 6|CentOS release 6' /etc/redhat-release`; then
  os=el6
fi

if `grep -qs -P 'Fedora release 16' /etc/fedora-release`; then
  os=f16
fi

if `grep -qs -P 'Fedora release 17' /etc/fedora-release`; then
  os=f17
fi

if [ -f /etc/debian_version ]; then
  os=debian
fi

if [ "$os" = "unsupported" ]; then
  echo This script has not been tested outside of EL6, Fedora 16
  echo and Fedora 17. You will need to install development
  echo libraries and set up postgres manually.
  echo
  echo Press Control-C to quit, or ENTER to continue
  read waiting
fi

#deb-based systems
if [ "$os" = "debian" ];then
  sudo apt-get install -y  build-essential git curl libxslt1-dev libxml2-dev zlib1g zlib1g-dev sqlite3 libsqlite3-dev libffi-dev libssl-dev libreadline-dev
#rpm-based stuff
else
# Check if gcc rpm is installed
if ! `rpm -q --quiet gcc`; then
  sudo yum install -y gcc
fi

# Check if make rpm is installed
if ! `rpm -q --quiet make`; then
  sudo yum install -y make
fi

# Check if git rpm is installed
if ! `rpm -q --quiet git`; then
  sudo yum install -y git
fi

# Check if rubygems rpm is installed
if ! `rpm -q --quiet rubygems`; then
  sudo yum install -y rubygems
fi

# Check if ruby-devel rpm is installed
if ! `rpm -q --quiet ruby-devel`; then
  sudo yum install -y ruby-devel
fi
fi

# Install the json and puppet gems if they're not already installed
if [ `gem list -i json` = "false" ]; then
  echo Installing json gem
  gem install json
fi
if [ `gem list -i facter` = "false" ]; then
  echo Installing facter gem
  # installing a slightly older version of facter to work around an issue like
  # Error: Could not run: Could not retrieve facts for <hostame>: undefined method `enum_lsdev' for Facter::Util::Processor:Module
  gem install facter -v 1.6.13
fi
if [ `gem list -i puppet` = "false" ]; then
  echo Installing puppet gem
  gem install puppet
fi

# Set default Deltacloud, ImageFactory, and Image Warehouse values
# (for RH network) if they're not already in the environment
if [ "x$FACTER_IWHD_URL" = "x" ]; then
  export FACTER_IWHD_URL=http://localhost:9090
fi
if [ "x$FACTER_DELTACLOUD_URL" = "x" ]; then
  export FACTER_DELTACLOUD_URL=http://localhost:3002/api
fi
if [ "x$FACTER_IMAGEFACTORY_URL" = "x" ]; then
  export FACTER_IMAGEFACTORY_URL=https://localhost:8075/imagefactory
fi

# Create some default OAuth values
if [ "x$FACTER_OAUTH_JSON_FILE" = "x" ]; then
  export FACTER_OAUTH_JSON_FILE=/etc/aeolus-conductor/oauth.json
  if [ ! -e $FACTER_OAUTH_JSON_FILE ]; then
    sudo mkdir -p /etc/aeolus-conductor

    # The next command is more here for illustrative purposes and to
    # allow bootstrap.sh to succeed.  The values in oauth.json should
    # correspond to existing credentials in an image factory and image
    # warehouse install.
    #
    # Note that after bootstrap.sh runs (and your development is set
    # up), you can always edit conductor/src/config/settings.yml and
    # conductor/src/config/oauth.json to reflect updated image factory
    # and image warehouse credentials.
    sudo echo -n '{"iwhd":{"consumer_secret":"/Bv2mvBusak2HoCJXUwXIogMhPrkjIjR","consumer_key":"G9xILgFMXZ4lEsQgO1CG6ujErGKwA6Cp"},"factory":{"consumer_secret":"ieqL8ojxPQBvKwCh3m36Fc6on4B+SHB/","consumer_key":"LfiaAIMFP0ASr3VGrbCDjQn1bQL81+SK"}}' > /etc/aeolus-conductor/oauth.json
  fi
fi

# Optional environment variables (sample values are given below)
#
# Note that master is the default branch cloned from each of the three
# projects if a _BRANCH is not specified.
#
# export FACTER_AEOLUS_CLI_BRANCH=0.5.x
# export FACTER_AEOLUS_IMAGE_RUBYGEM_BRANCH=0.3-maint
# export FACTER_CONDUCTOR_BRANCH=0.10.x
#
# Pull requests must be integers
#
# export FACTER_AEOLUS_CLI_PULL_REQUEST=6
# export FACTER_AEOLUS_IMAGE_RUBYGEM_PULL_REQUEST=7
# export FACTER_CONDUCTOR_PULL_REQUEST=47
#
mkdir -p $WORKDIR
cd $WORKDIR
if [ ! -d dev-tools ]; then
 git clone https://github.com/aeolus-incubator/dev-tools.git
else
 echo 'dev-tools DIRECTORY ALREADY EXISTS, LEAVING IN TACT.'
fi

# TODO check dev-tools directory (and thus also parent $WORKDIR) exist
# at this point or bail

if [ "x$RBENV_VERSION" != "x" ]; then

  # only used for "rbenv install" in the Fedora-(16|17) / ruby 1.8.7 case
  if [ "xRBENV_INSTALL_CONFIGURE_OPTS" != "x" ]; then
    if [ "$os" = "f16" -o "$os" = "f17" ]; then
      if echo $RBENV_VERSION | grep -qs '^1.8.7-' ; then
        RBENV_INSTALL_CONFIGURE_OPTS=--without-dl
      fi
    fi
  fi

  # install rbenv plus plugins rbenv-var, ruby-build, rbenv-installer
  # this is a harmless op if already installed (TODO: don't bother downloading and running if already installed)
  curl -L https://raw.github.com/fesplugas/rbenv-installer/master/bin/rbenv-installer | /bin/bash
  export PATH=~/.rbenv/bin:~/.rbenv/shims:$PATH

  # if this ruby version is not already installed in this user's rbenv, install it
  rbenv versions | grep -q $RBENV_VERSION
  if [ $? -ne 0 ]; then
    CONFIGURE_OPTS=$RBENV_INSTALL_CONFIGURE_OPTS rbenv install $RBENV_VERSION
  fi

  # bail if the ruby version doesn't seem to be installed
  rbenv versions | grep -q $RBENV_VERSION
  if [ $? -ne 0 ]; then
    echo was not able to "rbenv install $RBENV_VERSION".  Check ~/.rbenv
    exit 1
  fi

  # install bundler if not already installed
  cd $FACTER_AEOLUS_WORKDIR && rbenv local $RBENV_VERSION
  cd $FACTER_AEOLUS_WORKDIR && rbenv rehash
  cd $FACTER_AEOLUS_WORKDIR && rbenv which bundle | grep -q "/$RBENV_VERSION/bin/bundle"
  if [ $? -ne 0 ]; then
    cd $FACTER_AEOLUS_WORKDIR && gem install bundler
    cd $FACTER_AEOLUS_WORKDIR && rbenv rehash

    # sanity check install of bundler
    cd $FACTER_AEOLUS_WORKDIR && rbenv which bundle | grep -q "/$RBENV_VERSION/bin/bundle"
    if [ $? -ne 0 ]; then
      echo "gem install bundler in rbenv for version $RBENV_VERSION did not appear to succeed"
      exit 1
    fi
  fi

  export FACTER_RBENV_VERSION=$RBENV_VERSION
  # looking up a home dir in puppet is not terribly easy, hence the next two lines
  eval thehomedir=~
  export FACTER_RBENV_HOME=`echo $thehomedir`/.rbenv
fi

sudo getent group | grep -q -P '^puppet:'
if [ $? -ne 0 ]; then
  # workaround puppet bug http://projects.puppetlabs.com/issues/9862
  sudo groupadd puppet
fi

# install repos, configure and start up conductor
cd $WORKDIR/dev-tools
puppet apply -d --modulepath=. test.pp --no-report

# Arbitrary post-script commmand to execute
# (useful for say, seeding provider accounts)
if [ ! "x$POST_SCRIPTLET" = "x" ]; then

  # When $POST_SCRIPTLET is eval'ed, it should just write the script
  # to execute to stdout.  It is "eval'ed" so your outside script can
  # safely use bootstrap.sh environment variables.
  eval $POST_SCRIPTLET | /bin/sh -x
fi
