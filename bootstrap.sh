#!/bin/bash

# Set this to 0 if you don't have (or don't want to use) sudo permissions
if [ "x$HAVESUDO" = "x" ]; then
  HAVESUDO=1
fi

# Setup a development environment for conductor, tim
# and aeolus-cli.  Configure conductor to use an external
# imagefactory/deltacloud by setting env variables and
# oauth.json, below.  Startup conductor on port 3000

if [ "x$WORKDIR" = "x" ]; then
  export WORKDIR=~/aeolus-workdir
fi

# Where the aeolus projects (conductor, aeolus-cli and tim)
# get checked out to
if [ "x$FACTER_AEOLUS_WORKDIR" = "x" ]; then
  export FACTER_AEOLUS_WORKDIR=$WORKDIR
fi

# Port to start up conductor on
if [ "x$FACTER_CONDUCTOR_PORT" = "x" ]; then
  export FACTER_CONDUCTOR_PORT=3000
fi

# Used specifically for the conductor/tim's callback_url that gets
# provided to imagefactory (in
# /conductor/src/config/initializers/tim.rb)
if [ "x$FACTER_CONDUCTOR_HOSTNAME" = "x" ]; then
  export FACTER_CONDUCTOR_HOSTNAME=`hostname`
fi

# RDBMS to use for the install (postgresql|sqlite)
if [ "x$FACTER_RDBMS" = "x" ]; then
  export FACTER_RDBMS=postgresql
fi

# If using postgresql, set some sane defaults if not present in environment
if [ "$FACTER_RDBMS" = "postgresql" ]; then
  if [ "x$FACTER_RDBMS_DBNAME" = "x" ]; then
    # assign a random database name if no database name provided by user
    export FACTER_RDBMS_DBNAME=conductor_`</dev/urandom tr -dc a-z0-9 | head -c${1:-4}`
  fi
  if [ "x$FACTER_RDBMS_USERNAME" = "x" ]; then
    export FACTER_RDBMS_USERNAME=$USER
  fi
  if [ "x$FACTER_RDBMS_PASSWORD" = "x" ]; then
    export FACTER_RDBMS_PASSWORD=v23zj59an
  fi
fi

# If you want to use system ruby for the aeolus projects, do not
# define this env var.  Otherwise, use (and install if necessary)
# specified ruby version locally in ~/.rbenv for $DEV_USERNAME
# export RBENV_VERSION=1.9.3-p362

# Set default Deltacloud, ImageFactory values
# (for RH network) if they're not already in the environment
if [ "x$FACTER_DELTACLOUD_URL" = "x" ]; then
  export FACTER_DELTACLOUD_URL=http://localhost:3002/api
fi
if [ "x$FACTER_IMAGEFACTORY_URL" = "x" ]; then
  export FACTER_IMAGEFACTORY_URL=http://localhost:8075/imagefactory
fi

# Create some default OAuth values
if [ "x$FACTER_OAUTH_JSON_FILE" = "x" ]; then
  export FACTER_OAUTH_JSON_FILE=/tmp/oauth.json
  if [ ! -e $FACTER_OAUTH_JSON_FILE ]; then

    # The next command is more here for illustrative purposes and to
    # allow bootstrap.sh to succeed.  The values in oauth.json should
    # correspond to existing credentials in an image factory and image
    # warehouse install.
    #
    # Note that after bootstrap.sh runs (and your development is set
    # up), you can always edit conductor/src/config/settings.yml and
    # conductor/src/config/oauth.json to reflect updated image factory
    # and image warehouse credentials.
    echo -n '{"factory":{"consumer_secret":"ieqL8ojxPQBvKwCh3m36Fc6on4B+SHB/","consumer_key":"LfiaAIMFP0ASr3VGrbCDjQn1bQL81+SK"}}' > $FACTER_OAUTH_JSON_FILE
  fi
fi

# Optional environment variables (sample values are given below)
#
# If the following env var is defined, checkout and start up
# deltacloud locally rather than use an existing installation.
# export SETUP_LOCAL_DELTACLOUD_RELEASE=release-1.0.5
# export SETUP_LOCAL_DELTACLOUD_PORT=3002
#
# _BRANCH variables below may be either branches, tags or commit hashes.
# Note that master is the default branch cloned from each of the three
# projects if a _BRANCH is not specified.
#
# export FACTER_AEOLUS_CLI_BRANCH=0.5.x
# export FACTER_CONDUCTOR_BRANCH=0.10.x
# export FACTER_TIM_PULL_REQUEST=v0.2.0
#
# Pull requests must be integers
#
# export FACTER_AEOLUS_CLI_PULL_REQUEST=6
# export FACTER_CONDUCTOR_PULL_REQUEST=47
# export FACTER_TIM_PULL_REQUEST=2
#

if `netstat -tln | grep -q -P "\:$FACTER_CONDUCTOR_PORT\\s"`; then
  echo "A process is already listening on port $FACTER_CONDUCTOR_PORT.  Aborting"
  exit 1
fi

if [ -e $FACTER_AEOLUS_WORKDIR/conductor ] || [ -e $FACTER_AEOLUS_WORKDIR/tim ] || \
  [ -e $FACTER_AEOLUS_WORKDIR/aeolus-cli ]; then
  echo -n "Already existing directories, one of $FACTER_AEOLUS_WORKDIR/conductor, "
  echo "$FACTER_AEOLUS_WORKDIR/tim or $FACTER_AEOLUS_WORKDIR/aeolus-cli.  Aborting"
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
  echo This script has not been tested outside of EL6, Fedora 16,
  echo Fedora 17 or debian. You will need to install development
  echo libraries manually.
  echo
  echo Press Control-C to quit, or ENTER to continue
  read waiting
fi

# install dependencies for fedora/rhel/centos
if [ "$os" = "f16" -o "$os" = "f17" -o "$os" = "el6" ]; then
  depends="git"

  # general ruby deps needed to roll your own ruby or build extensions
  depends="$depends gcc make zlib-devel"

  # Conductor-specific deps
  depends="$depends libffi-devel"  #ffi
  depends="$depends libxml2-devel" #nokogiri
  depends="$depends libxslt-devel" #nokogiri
  depends="$depends gcc-c++" #eventmachine

  # Puppet and puppet modules deps
  depends="$depends openssl-devel lsof"

  if [ "$FACTER_RDBMS" = "sqlite" ]; then
    depends="$depends sqlite-devel"  #sqlite3
  elif [ "$FACTER_RDBMS" = "postgresql" ]; then
    depends="$depends postgresql-devel postgresql postgresql-server"
  fi

  if [ "x$RBENV_VERSION" = "x" ]; then
    # additional dependencies if using system ruby and not rbenv
    depends="$depends rubygems ruby-devel"
    if [ $os != "el6" ]; then
      depends="$depends rubygem-bundler"
    fi
  fi

  # Add Deltacloud build dependencies if needed
  if [ "x$SETUP_LOCAL_DELTACLOUD_RELEASE" != "x" ]; then
    depends="$depends bison flex libxslt openssl-devel"
    depends="$depends readline-devel"

    # Deltacloud added new deps after 1.0.5:
    #   https://mail-archives.apache.org/mod_mbox/deltacloud-dev/201212.mbox/browser
    depends="$depends sqlite-devel"
  fi

  # If we have sudo, we're able to install missing dependencies
  if [ "$HAVESUDO" = "1" ]; then
    # Check which dependencies need installing
    install_list=""
    for dep in `echo $depends`; do
      if ! `rpm -q --quiet --nodigest $dep`; then
        install_list="$install_list $dep"
      fi
    done

    # Install the needed packages
    if [ "x$install_list" != "x" ]; then
      sudo yum install -y $install_list
    fi

    # Verify the dependencies did install
    fail_list=""
    for dep in `echo $depends`; do
      if ! `rpm -q --quiet --nodigest $dep`; then
        fail_list="$fail_list $dep"
      fi
    done

    # If anything failed verification, we tell the user and exit
    if [ "x$fail_list" != "x" ]; then
        echo "ABORTING:  FAILED TO INSTALL $fail_list"
        exit 1
    fi

    if [ "$FACTER_RDBMS" = "postgresql" ]; then

      # If postgresql is already initialized, we do not want to overwrite settings in
      # an existing /var/lib/pgsql/data/pg_hba.conf
      PG_HBA_CONF_EXISTS=0
      if sudo test -e /var/lib/pgsql/data/pg_hba.conf &> /dev/null; then
        echo "INFO: postgresql database previously initialized"
        PG_HBA_CONF_EXISTS=1
      fi

      # initialize the postgresql database
      # if postgresql has already been initialized with the default data dir (/var/lib/pgsql/data)
      # then this is a no-op
      if [ "$os" == "el6" ]; then
        sudo service postgresql initdb
      else
        sudo postgresql-setup initdb
      fi

      # if there was no pre-existing pg_hba.conf, set all authentication methods to 'trust' and 'md5'
      if [ $PG_HBA_CONF_EXISTS -eq 0 ]; then
        sudo bash -c "echo 'local all all trust' > /var/lib/pgsql/data/pg_hba.conf"
        sudo bash -c "echo 'host all all 127.0.0.1/32 md5' >> /var/lib/pgsql/data/pg_hba.conf"
        sudo bash -c "echo 'host all all ::1/128 md5' >> /var/lib/pgsql/data/pg_hba.conf"
      fi

      # start the postgresql service
      if [ "$os" == "el6" ]; then
        sudo service postgresql start
      else
        sudo systemctl start postgresql.service
      fi

      # create the database user and grant CREATEDB
      sudo su - postgres -c "psql -c \"CREATE ROLE $FACTER_RDBMS_USERNAME WITH LOGIN CREATEDB SUPERUSER PASSWORD '$FACTER_RDBMS_PASSWORD';\""
      if [ $? -ne 0 ]; then
        echo "INFO: postgresql create role $FACTER_RDBMS_USERNAME failed"
      fi
    fi
  else
    for dep in `echo $depends`; do
      # sanity check that it just installed
      if ! `rpm -q --quiet --nodigest $dep`; then
        echo "ABORTING:  $dep is not installed"
        exit 1
      fi
    done
  fi
fi

if [ "$os" = "debian" ]; then
  if [ "$HAVESUDO" = "1" ]; then
    if [ "$FACTER_RDBMS" = "postgresql" ]; then
      sudo apt-get install -y postgresql postgresql-client libpq-dev
    fi
    if [ "$FACTER_RDBMS" = "sqlite" ]; then
      sudo apt-get install -y sqlite3 libsqlite3-dev
    fi

    sudo apt-get install -y build-essential git curl libxslt1-dev libxml2-dev zlib1g zlib1g-dev libffi-dev libssl-dev libreadline-dev lsof

    # adding the ruby stuff as a distinct step so we can conditionalize this a bit better later
    #   --just throw in a   if [ "x$RBENV_VERSION" != "x" ]; then    ?
    sudo apt-get install -y ruby1.9.1 ruby1.9.1-dev libruby1.9.1

    if [ "$FACTER_RDBMS" = "postgresql" ]; then
      # set up postgres
      # apt-get install postgresql starts the postgresql service, but
      # attempt to start it in case it was previously installed
      sudo service postgresql start

      # create the database user and grant CREATEDB
      sudo su - postgres -c "psql -c \"CREATE ROLE $FACTER_RDBMS_USERNAME WITH LOGIN CREATEDB SUPERUSER PASSWORD '$FACTER_RDBMS_PASSWORD';\""
      if [ $? -ne 0 ]; then
        echo "INFO: postgresql create role $FACTER_RDBMS_USERNAME failed"
      fi
    fi
  fi
fi

mkdir -p $FACTER_AEOLUS_WORKDIR
if [ ! -d $FACTER_AEOLUS_WORKDIR ]; then
  echo "ABORTING.  Could not create directory $FACTER_AEOLUS_WORKDIR"
fi

if [ "x$RBENV_VERSION" != "x" ]; then

  # only used for "rbenv install" in the Fedora-(16|17) / ruby 1.8.7 case
  if [ "x$RBENV_INSTALL_CONFIGURE_OPTS" = "x" ]; then
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

gem_installs="json facter puppet"
if [ "$os" = "el6" -o "$os" = "debian" ]; then
  gem_installs="$gem_installs bundler"
fi

# use a slightly older version of facter because latest stable of
# 1.6.14 causes an error like:
# Error: Could not run: Could not retrieve facts for <hostame>: undefined method `enum_lsdev' for Facter::Util::Processor:Module
declare -A gem_versions
gem_versions["facter"]=1.6.13

for the_gem in `echo $gem_installs`; do
  if [ `gem list -i $the_gem` = "false" ]; then
    cmd="gem install $the_gem"
    if [ "x$RBENV_VERSION" = "x" ]; then
      # TODO perhaps determine a way to install gem local to current
      # user instead.  For now, do a system install of the gem when
      # using system ruby
      # http://docs.rubygems.org/read/chapter/3
      if [ "$HAVESUDO" = "1" ]; then
        cmd="sudo $cmd"
      else
        echo 'Installing local gems without using rbenv is not currently supported.'
        echo 'If you want to install gems system-wide using system ruby instead of rbenv, you must be a sudo-enabled user'
        exit 1
      fi
    fi
    if  [[ ${gem_versions[$the_gem]} ]]; then
        cmd="$cmd -v ${gem_versions[$the_gem]}"
    fi
    $cmd
    if [ `gem list -i $the_gem` = "false" ]; then
      echo "ABORTING.  FAILED TO INSTALL $the_gem"
      exit 1
    fi
  fi
done

# newly installed rbenv/gem binaries require an rbenv rehash to work
# properly in our $PATH
if [ "x$RBENV_VERSION" != "x" ]; then
  cd $FACTER_AEOLUS_WORKDIR && rbenv rehash
fi

# Setup the local deltacloud instance, if the user wants one
if [ "x$SETUP_LOCAL_DELTACLOUD_RELEASE" != "x" ]; then
  cd $FACTER_AEOLUS_WORKDIR
  if [ -d deltacloud ]; then
    echo 'INFO deltacloud dir already exists'
  else
    git clone https://git-wip-us.apache.org/repos/asf/deltacloud.git
  fi
  cd deltacloud
  git checkout $SETUP_LOCAL_DELTACLOUD_RELEASE
  cd server
  bundle install --path ../bundle
  [ -z $SETUP_LOCAL_DELTACLOUD_PORT ] && SETUP_LOCAL_DELTACLOUD_PORT=3002
  if `netstat -tlpn | grep -q -P "\:$SETUP_LOCAL_DELTACLOUD_PORT\\s"`; then
    echo "WARNING A process is already listening on port $SETUP_LOCAL_DELTACLOUD_PORT"
    echo "        Not starting up deltacloud"
  else
    echo "* Starting up deltacloudd on port $SETUP_LOCAL_DELTACLOUD_PORT"
    # TODO: setup logging by using a custom config file
    bundle exec "bin/deltacloudd -i \"mock\" -p $SETUP_LOCAL_DELTACLOUD_PORT" >log/deltacloud.log 2>&1 &
  fi
fi

# These next few lines are usuall a no-op since WORKDIR
# and FACTER_AEOLUS_WORKDIR are usually the same
mkdir -p $WORKDIR
if [ ! -d $WORKDIR ]; then
  echo "ABORTING.  Could not create directory $WORKDIR"
  exit 1
fi

cd $WORKDIR
if [ ! -d dev-tools ]; then
  git clone https://github.com/aeolus-incubator/dev-tools.git
  if [ "x$DEV_TOOLS_BRANCH" != "x" ]; then
    cd dev-tools
    git checkout $DEV_TOOLS_BRANCH
    cd ..
  fi
else
  echo 'dev-tools DIRECTORY ALREADY EXISTS, LEAVING IN TACT.'
fi

echo "Given this puppet bug http://projects.puppetlabs.com/issues/9862"
echo "you may need to add manually the 'puppet' group to the system in case of errors."

# install repos, configure and start up conductor
cd $WORKDIR/dev-tools
puppet apply -d --modulepath=. test.pp --no-report

if [ $? -eq 0 ]; then
  echo "** instalation successfully finished **"
fi

# Arbitrary post-script command to execute
# (useful for say, seeding provider accounts)
if [ ! "x$POST_SCRIPTLET" = "x" ]; then

  # When $POST_SCRIPTLET is eval'ed, it should just write the script
  # to execute to stdout.  It is "eval'ed" so your outside script can
  # safely use bootstrap.sh environment variables.
  eval $POST_SCRIPTLET | /bin/sh -x
fi
