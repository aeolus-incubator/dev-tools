#!/bin/sh

# Setup a development environment for conductor, aeolus-image-rubygem
# and aeolus-cli.  Configure conductor to use an external
# imagefactory/iwhd/deltacloud by setting env variables and
# oauth.json, below.  Startup conductor on port 3000

# Set the default user to check out repos with, if not requested
if [ "x$DEV_USERNAME" = "x" ]; then
  export DEV_USERNAME=test
fi
# Just in case the user doesn't already exist
useradd $DEV_USERNAME 2>/dev/null

# Where dev-tools gets checked out to
if [ "x$WORKDIR" = "x" ]; then
    export WORKDIR=/tmp/$DEV_USERNAME
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

if [ "$os" = "unsupported" ]; then
    echo This script has not been tested outside of EL6, Fedora 16
    echo and Fedora 17. You will need to install development
    echo libraries and set up postgres manually.
    echo
    echo Press Control-C to quit, or ENTER to continue
    read waiting
fi

# Check if gcc rpm is installed
if ! `rpm -q --quiet gcc`; then
    yum install -y gcc
fi

# Check if make rpm is installed
if ! `rpm -q --quiet make`; then
    yum install -y make
fi

# Check if git rpm is installed
if ! `rpm -q --quiet git`; then
    yum install -y git
fi

# Check if rubygems rpm is installed
if ! `rpm -q --quiet rubygems`; then
    yum install -y rubygems
fi

# Check if ruby-devel rpm is installed
if ! `rpm -q --quiet ruby-devel`; then
    yum install -y ruby-devel
fi

# Install the json and puppet gems if they're not already installed
if [ `gem list -i json` = "false" ]; then
    echo Installing json gem
    gem install json
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
    mkdir -p /etc/aeolus-conductor

    # The next command is more here for illustrative purposes and to
    # allow bootstrap.sh to succeed.  The values in oauth.json should
    # correspond to existing credentials in an image factory and image
    # warehouse install.
    #
    # Note that after bootstrap.sh runs (and your development is set
    # up), you can always edit conductor/src/config/settings.yml to
    # reflect updated image factory and image warehouse credentials.
    echo -n '{"factory":{"consumer_key":"5gjuDFBxVW67TDG5HOXOdiSLaIEMGbcs","consumer_secret":"6Vry7voPLl8xhbG5dGiB7dtiPpu7EqXR"},"iwhd":{"consumer_key":"6pu2dedsVydkqf294/N1dvFCJs5eeWIp","consumer_secret":"O+as/3PsTVeiWSlAmlIABiZqcz98KdGj"}}' > /etc/aeolus-conductor/oauth.json
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
if [ -d dev-tools ]; then
 rm -rf dev-tools
fi
chown $DEV_USERNAME $WORKDIR
su $DEV_USERNAME -c "git clone https://github.com/aeolus-incubator/dev-tools.git"

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
  su $DEV_USERNAME -c "curl -L https://raw.github.com/fesplugas/rbenv-installer/master/bin/rbenv-installer | /bin/sh"
  export DEV_USERNAME_PATH_PREFIX="~/.rbenv/bin:~/.rbenv/shims"

  # if this ruby version is not already installed in this user's rbenv, install it
  su $DEV_USERNAME -l -c "export PATH=$DEV_USERNAME_PATH_PREFIX:\`echo \$PATH\`; rbenv versions" | grep -q $RBENV_VERSION
  if [ $? -ne 0 ]; then
    su $DEV_USERNAME -l -c "export PATH=$DEV_USERNAME_PATH_PREFIX:\`echo \$PATH\`; CONFIGURE_OPTS=$RBENV_INSTALL_CONFIGURE_OPTS  rbenv install $RBENV_VERSION"
  fi

  # bail if the ruby version doesn't seem to be installed
  su $DEV_USERNAME -l -c "export PATH=$DEV_USERNAME_PATH_PREFIX:\`echo \$PATH\`; rbenv versions" | grep -q $RBENV_VERSION
  if [ $? -ne 0 ]; then
    echo was not able to "rbenv install $RBENV_VERSION".  Check ~$DEV_USERNAME/.rbenv
    exit 1
  fi

  # install bundler if not already installed
  su $DEV_USERNAME -l -c "export PATH=$DEV_USERNAME_PATH_PREFIX:\`echo \$PATH\`; cd $FACTER_AEOLUS_WORKDIR && rbenv local $RBENV_VERSION"
  su $DEV_USERNAME -l -c "export PATH=$DEV_USERNAME_PATH_PREFIX:\`echo \$PATH\`; cd $FACTER_AEOLUS_WORKDIR && rbenv rehash"
  su $DEV_USERNAME -l -c "export PATH=$DEV_USERNAME_PATH_PREFIX:\`echo \$PATH\`; cd $FACTER_AEOLUS_WORKDIR && rbenv which bundle" | grep -q "/$RBENV_VERSION/bin/bundle"
  if [ $? -ne 0 ]; then
    su $DEV_USERNAME -l -c "export PATH=$DEV_USERNAME_PATH_PREFIX:\`echo \$PATH\`; cd $FACTER_AEOLUS_WORKDIR && gem install bundler"
    su $DEV_USERNAME -l -c "export PATH=$DEV_USERNAME_PATH_PREFIX:\`echo \$PATH\`; cd $FACTER_AEOLUS_WORKDIR && rbenv rehash"

    # sanity check install of bundler
    su $DEV_USERNAME -l -c "export PATH=$DEV_USERNAME_PATH_PREFIX:\`echo \$PATH\`; cd $FACTER_AEOLUS_WORKDIR && rbenv which bundle" | grep -q "/$RBENV_VERSION/bin/bundle"
    if [ $? -ne 0 ]; then
      echo "gem install bundler in rbenv for version $RBENV_VERSION did not appear to succeed"
      exit 1
    fi
  fi

  export FACTER_RBENV_VERSION=$RBENV_VERSION
  # looking up a home dir in puppet is not terribly easy, hence the next two lines
  eval thehomedir=~$DEV_USERNAME
  export FACTER_RBENV_HOME=`echo $thehomedir`/.rbenv
fi

getent group | grep -q -P '^puppet:'
if [ $? -ne 0 ]; then
  # workaround puppet bug http://projects.puppetlabs.com/issues/9862
  groupadd puppet
fi

# First run as root to install needed dependencies
cd dev-tools
puppet apply -d --modulepath=. test.pp

# Run same command as a non-root user (e.g., test) to install repos,
# configure and start up conductor
su $DEV_USERNAME -c "puppet apply -d --modulepath=. test.pp --no-report"

# Arbitrary post-script commmand to execute
# (useful for say, seeding provider accounts)
if [ ! "x$POST_SCRIPTLET" = "x" ]; then
    # when $POST_SCRIPTLET is eval'ed, it should just write the 
    # script to execute to stdout
  # Additional configuration (e.g., adding provider accounts)
  eval $POST_SCRIPTLET | /bin/sh -x
fi
