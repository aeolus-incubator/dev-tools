# Aeolus dev-tools

Use bootstrap.sh to setup a devolpment environment for the aeolus
projects conductor, aeolus-image-rubygem, and aeolus-cli and start up
an instance of conductor.  While also useful to developers, it is also
provides a useful way to quicky test various branches, pull requests,
and ruby versions.

# Super Quick Start

As the root user on a box you want to install Aeolus on:

  If you want to use system ruby:

    # curl https://raw.github.com/aeolus-incubator/dev-tools/master/bootstrap.sh | /bin/sh

  If you want to use a specific ruby version via rbenv
    
    # export RBENV_VERSION=1.9.3-p194; curl https://raw.github.com/aeolus-incubator/dev-tools/master/bootstrap.sh | /bin/sh

This should work on rhel6, fc16 and fc17 (the script's env variables +
oauth.json are pointing to existing imagefactory/iwhd/deltacloud
instances).

# See Also

* https://lists.fedorahosted.org/pipermail/aeolus-devel/2012-September/012684.html
* https://lists.fedorahosted.org/pipermail/aeolus-devel/2012-September/012599.html
