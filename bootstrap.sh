#!/bin/bash

# Set this to 0 if you don't have (or don't want to use) sudo permissions
HAVESUDO=${HAVESUDO:=1}

# Setup a development environment for conductor, tim
# and aeolus-cli.  Configure conductor to use an external
# imagefactory/deltacloud by setting env variables and
# oauth.json, below.  Startup conductor on port 3000

export WORKDIR=${WORKDIR:=~/aeolus-workdir}

# Where the aeolus projects (conductor, aeolus-cli and tim)
# get checked out to
export FACTER_AEOLUS_WORKDIR=${FACTER_AEOLUS_WORKDIR:=$WORKDIR}

# Port to start up conductor on
export FACTER_CONDUCTOR_PORT=${FACTER_CONDUCTOR_PORT:=3000}

# Used specifically for the conductor/tim's callback_url that gets
# provided to imagefactory (in
# /conductor/src/config/initializers/tim.rb)
export FACTER_CONDUCTOR_HOSTNAME=${FACTER_CONDUCTOR_HOSTNAME:=`hostname`}

# RDBMS to use for the install (postgresql|sqlite)
export FACTER_RDBMS=${FACTER_RDBMS:=postgresql}

# If using postgresql, set some sane defaults if not present in environment
if [ "$FACTER_RDBMS" = "postgresql" ]; then
  # assign a random database name if no database name provided by user
  export FACTER_RDBMS_DBNAME=${FACTER_RDBMS_DBNAME:=conductor_$(
    < /dev/urandom tr -dc a-z0-9 | head -c 4 )}
  export FACTER_RDBMS_USERNAME=${FACTER_RDBMS_USERNAME:=$USER}
  export FACTER_RDBMS_PASSWORD=${FACTER_RDBMS_PASSWORD:=v23zj59an}
fi

# If you want to use system ruby for the aeolus projects, do not
# define this env var.  Otherwise, use (and install if necessary)
# specified ruby version locally in ~/.rbenv for $DEV_USERNAME
# export RBENV_VERSION=1.9.3-p362

# Set default Deltacloud, ImageFactory values
# (for RH network) if they're not already in the environment
export FACTER_DELTACLOUD_URL=${FACTER_DELTACLOUD_URL:=http://localhost:3002/api}
export FACTER_IMAGEFACTORY_URL=${FACTER_IMAGEFACTORY_URL:=http://localhost:8075/imagefactory}

# Create some default OAuth values
if [ "x$FACTER_OAUTH_JSON_FILE" = "x" ]; then
  export FACTER_OAUTH_JSON_FILE=/tmp/oauth.json
  if [ ! -f $FACTER_OAUTH_JSON_FILE ]; then

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

create_pg_user() {
  # create the database role
  sudo su - postgres -c "psql -c \"CREATE ROLE $FACTER_RDBMS_USERNAME WITH LOGIN CREATEDB SUPERUSER PASSWORD '$FACTER_RDBMS_PASSWORD';\""
  # note that the SUPERUSER option can be removed once we user Rails that merge this fix: https://github.com/rails/rails/pull/8548
  if [ $? -ne 0 ]; then
    echo "INFO: postgresql create role $FACTER_RDBMS_USERNAME failed"
  fi
}

if `netstat -tln | grep -q -P "\:$FACTER_CONDUCTOR_PORT\\s"`; then
  echo "A process is already listening on port $FACTER_CONDUCTOR_PORT.  Aborting"
  exit 1
fi

if [ -e $FACTER_AEOLUS_WORKDIR/conductor -o -e $FACTER_AEOLUS_WORKDIR/tim -o \
  -e $FACTER_AEOLUS_WORKDIR/aeolus-cli ]; then
  echo -n "Already existing directories, one of $FACTER_AEOLUS_WORKDIR/conductor, "
  echo "$FACTER_AEOLUS_WORKDIR/tim or $FACTER_AEOLUS_WORKDIR/aeolus-cli.  Aborting"
  exit 1
fi

os=unsupported
grep -Eqs 'Red Hat Enterprise Linux Server release 6|CentOS release 6' /etc/redhat-release && os=el6

grep -qs -P 'Fedora release 16' /etc/fedora-release && os=f16
grep -qs -P 'Fedora release 17' /etc/fedora-release && os=f17
grep -qs -P 'Fedora release 18' /etc/fedora-release && os=f18

test -f /etc/debian_version && os=debian

if [ "$os" = "unsupported" ]; then
  echo "This script has not been tested outside of EL6, Fedora 16/17/18"
  echo "or Debian. You will need to install development libraries manually."
  echo
  echo "Press Control-C to quit, or ENTER to continue"
  read
fi

# disclaimer for standard el6 system ruby, bail early instead of continuing
if [ "$os" = "el6" -a "x$RBENV_VERSION" = "x" ] && (
      ! `rpm -q --quiet --nodigest ruby` || # <- ruby not installed now, so 1.8.7 would be installed later
      (`which ruby >/dev/null` && `ruby --version | grep -q '1.8.7'` )
  ); then
  echo  This script is not supported on el6 with system ruby 1.8.7.
  echo
  echo "Press Control-C to quit, or ENTER to continue"
  read
fi

# install dependencies for fedora/rhel/centos
if [ "$os" = "f16" -o "$os" = "f17" -o "$os" = "f18" -o "$os" = "el6" ]; then
  depends="git patch"
  depends="$depends net-tools" # for netstat

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
  else
    # the ruby-build plugin to rbenv requires tar
    depends="$depends tar"
  fi

  # Add Deltacloud build dependencies if needed
  if [ "x$SETUP_LOCAL_DELTACLOUD_RELEASE" != "x" ]; then
    depends="$depends bison flex libxslt openssl-devel"
    depends="$depends readline-devel"

    # Deltacloud added new deps after 1.0.5:
    #   https://mail-archives.apache.org/mod_mbox/deltacloud-dev/201212.mbox/browser
    depends="$depends sqlite-devel"
  fi

  # If we have sudo, we are able to install missing dependencies
  if [ "$HAVESUDO" = "1" ]; then
    # Check which dependencies need installing
    install_list=""
    for dep in $depends; do
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
    for dep in $depends; do
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
        sudo sh -c "cat >/var/lib/pgsql/data/pg_hba.conf <<-EOD
					local all all trust
					host all all 127.0.0.1/32 md5
					host all all ::1/128 md5
				EOD"
      fi

      # start the postgresql service
      if [ "$os" == "el6" ]; then
        sudo service postgresql start
      else
        sudo systemctl start postgresql.service
      fi

      # create the database role with CREATEDB permission
      create_pg_user
    fi
  else
    for dep in $depends; do
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
    if [ "$FACTER_RDBMS" = "sqlite" -o "x$SETUP_LOCAL_DELTACLOUD_RELEASE" != "x" ]; then
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

      # create the database role with CREATEDB permission
      create_pg_user
    fi
  fi
fi

mkdir -p $FACTER_AEOLUS_WORKDIR
if [ ! -d $FACTER_AEOLUS_WORKDIR ]; then
  echo "ABORTING.  Could not create directory $FACTER_AEOLUS_WORKDIR"
fi

if [ "x$RBENV_VERSION" != "x" ]; then

  # only used for "rbenv install" in the Fedora-(16|17) / ruby 1.8.7 case.
  # not tested with Fedora 18 since ruby18 is no longer supported in
  # conductor/tim
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
  cd $FACTER_AEOLUS_WORKDIR
  rbenv local $RBENV_VERSION
  rbenv rehash
  rbenv which bundle | grep -q "/$RBENV_VERSION/bin/bundle"
  if [ $? -ne 0 ]; then
    gem install bundler
    rbenv rehash

    # sanity check install of bundler
    rbenv which bundle | grep -q "/$RBENV_VERSION/bin/bundle"
    if [ $? -ne 0 ]; then
      echo "gem install bundler in rbenv for version $RBENV_VERSION did not appear to succeed"
      exit 1
    fi
  fi

  export FACTER_RBENV_VERSION=$RBENV_VERSION
  # looking up a home dir in puppet is not terribly easy, hence the next two lines
  export FACTER_RBENV_HOME=~/.rbenv
else

  # system ruby 1.8.7 is not supported (likely that only an older
  # ubuntu distro or a non-standard ruby setup would trigger this)
  if `ruby --version | grep -q '1.8.7'`; then
    echo dev-tools with ruby 1.8.7 is not supported and probably will not work
    echo
    echo "Press Control-C to quit, or ENTER to continue"
    read
  fi

  # set our gem search path to only be local to this user, to avoid
  # conflicts with system-installed gems
  if [ "$os" = "debian" ]; then
    export GEM_HOME=~/.gems-aeolus
    mkdir -p $GEM_HOME
  else
    # for fedora, this will look like /home/$USER/.gem/ruby/1.9.1
    export GEM_HOME=`gem environment gemdir`
  fi
  export PATH=$GEM_HOME/bin:$PATH
  export FACTER_PATH=$PATH
  # only use GEM_HOME, do not look at system-wide gem paths
  # ref: http://docs.rubygems.org/read/chapter/12
  export GEM_PATH=
  # for puppet, so we can find the gem binaries
  export FACTER_GEM_HOME=$GEM_HOME
fi

gem_installs="rdoc json facter puppet foreman"
if [ "$os" = "el6" -o "$os" = "debian" ]; then
  gem_installs="$gem_installs bundler"
fi

# use a slightly older version of facter because latest stable of
# 1.6.14 causes an error like:
# Error: Could not run: Could not retrieve facts for <hostame>: undefined method `enum_lsdev' for Facter::Util::Processor:Module
declare -A gem_versions
gem_versions["facter"]=1.6.13

for the_gem in $gem_installs; do
  if ! gem list -i $the_gem >/dev/null; then
    cmd="gem install $the_gem"
    if [ ! "x${gem_versions[$the_gem]}" = "x" ]; then
        cmd="$cmd -v ${gem_versions[$the_gem]}"
    fi
    $cmd
    if ! gem list -i $the_gem >/dev/null; then
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
  SETUP_LOCAL_DELTACLOUD_PORT=${SETUP_LOCAL_DELTACLOUD_PORT:=3002}
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
  echo 'dev-tools DIRECTORY ALREADY EXISTS, LEAVING INTACT.'
fi

# install repos, configure and start up conductor
cd $WORKDIR/dev-tools
puppet apply -d --modulepath=. test.pp --no-report

if `netstat -tln | grep -q -P "\:$FACTER_CONDUCTOR_PORT\\s"`; then
  echo "Success!  Dev-tools has set up your Conductor environment along with"
  echo "the related Aeolus projects, Tim and Aeolus-cli."
  echo ""
  echo "An instance of rails for conductor has been started on"
  echo "port $FACTER_CONDUCTOR_PORT.  Note that two other conductor processes have"
  echo "also been started (dbomatic and delayed jobs).  To stop all three"
  echo "conductor processes, use \"$FACTER_AEOLUS_WORKDIR/bin/conductor stop\"."
  echo ""
  echo "The conductor start/stop/restart script,"
  echo "$FACTER_AEOLUS_WORKDIR/bin/conductor,"
  echo "which starts or stops the three processes has been created for your"
  echo "convenience.  Use of this script is optional; you may instead wish to"
  echo "cd into $FACTER_AEOLUS_WORKDIR/conductor/src and use \"foreman start\""
  echo "to start the processes in a shell or just plain old \"bundle exec\" the"
  echo "commands in $FACTER_AEOLUS_WORKDIR/conductor/src/Procfile (assuming"
  echo "of course you have already stopped the conductor processes that this"
  echo "dev-tools script started up)."

  if [ "x$RBENV_VERSION" != "x" ]; then
    echo ""
    echo "NOTE: RBENV_VERSION was specified when running dev-tools.  If you"
    echo "plan on hacking away, make sure that you add rbenv to your path, e.g.:"
    echo ""
    echo "  export RBENV_ROOT=\"\${HOME}/.rbenv\""
    echo "  if [ -d \"\${RBENV_ROOT}\" ]; then"
    echo "    export PATH=\"\${RBENV_ROOT}/bin:\${PATH}\""
    echo "    eval \"\$(rbenv init -)\""
    echo "  fi"
  fi
fi

if [ "x$RBENV_VERSION" = "x" ]; then
  echo ""
  echo "This script used the following env vars:"
  echo "   PATH=$PATH"
  echo "   GEM_HOME=$GEM_HOME"
  echo "   GEM_PATH=$GEM_PATH"
  echo ""
  echo "If you are going to hack away, you probably want to "
  echo "set these in your shell!"
fi

# Arbitrary post-script command to execute
# (useful for say, seeding provider accounts)
if [ ! "x$POST_SCRIPTLET" = "x" ]; then

  # When $POST_SCRIPTLET is eval'ed, it should just write the script
  # to execute to stdout.  It is "eval'ed" so your outside script can
  # safely use bootstrap.sh environment variables.
  eval $POST_SCRIPTLET | /bin/sh -x
fi
