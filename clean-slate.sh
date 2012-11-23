#!/bin/bash

# WARNING!  This script will unceremoniously killall ruby processes
# and uninstall rpm's and/or gems without mercy.  Use at your own
# risk.

killall_ruby=1
remove_system_gems=1
remove_packages=1
remove_rbenv=1

if `grep -Eqs 'Red Hat Enterprise Linux Server release 6|CentOS release 6' /etc/redhat-release`; then
  os=el6
fi

if `grep -qs -P 'Fedora release 16' /etc/fedora-release`; then
  os=f16
fi

if `grep -qs -P 'Fedora release 17' /etc/fedora-release`; then
  os=f17
fi


if [ "x$killall_ruby" = "x1" ]; then
  sudo killall -9 ruby
fi
if [ "x$remove_system_gems" = "x1" ]; then
  gem_installs="json puppet facter"
  if [ $os = "el6" ]; then 
    gem_installs="$gem_installs bundler"
  fi
  for the_gem in `echo $gem_installs`; do
    if [ `gem list -i $the_gem` = "true" ]; then
      yes Y | sudo gem uninstall --a --ignore-dependencies $the_gem
    fi
  done
fi
  
if [ "x$remove_packages" = "x1" ]; then
  # mostly cut n' pasted from bootstrap.sh...
  if [ "$os" = "f16" -o "$os" = "f17" -o "$os" = "el6" ]; then
    depends="git"
    
    # general ruby deps needed to roll your own ruby or build extensions
    depends="$depends gcc make"
    
    # Conductor-specific deps
    depends="$depends libffi-devel"  #ffi
    depends="$depends libxml2-devel" #nokogiri
    depends="$depends libxslt-devel" #nokogiri
    
    # TODO don't need this if using postgres
    depends="$depends sqlite-devel"  #sqlite3
    
    depends="$depends rubygems ruby-devel gcc-c++"
    if [ $os != "el6" ]; then 
      depends="$depends rubygem-bundler"
    fi
    
    for dep in `echo $depends`; do
      if `rpm -q --quiet --nodigest $dep`; then
        sudo yum erase -y $dep
      fi
    done
  fi
fi

if [ "x$remove_rbenv" = "x1" ]; then
    rm -rf ~/.rbenv
fi
