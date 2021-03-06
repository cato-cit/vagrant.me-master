README
======

## Set Up Development Environment

### Use Virtualbox (Windows/Linux)

1. Update GEM source

    Run `which vagrant` within Cygwin shell to get vagrant installation location.

    Locate `embedded/gems/gems/vagrant-*/lib/vagrant/bundler.rb` in the vagrant installation location, replace all `https://rubygems.org` with `https://ruby.taobao.org`, delete line `gemfile.puts(%Q[source "http://gems.hashicorp.com"])`.

    It has be done this way because:

        1. Install gem package within China is extremely slow, has to use mirror inside China
        2. Vagrant does not provide any option to change its builtin gem's sources

        See <http://ruby.taobao.org/>

2. Install 'vagrant-winnfsd'

    `vagrant plugin install vagrant-winnfsd`

    See <https://github.com/winnfsd/vagrant-winnfsd>

3. Install 'vagrant-hostsupdater'

    `vagrant plugin install vagrant-hostsupdater`

    See <https://github.com/cogitatio/vagrant-hostsupdater>

4. Grant write permissions to everyone of the following file

    C:\\windows\system32\etc\hosts

5. Boot the machine

    `vagrant up`

5. Visit 'http://@@PROJECT@@.vagrant' or 'https://@@PROJECT@@.vagrant'

### Use Docker (Linux)

TODO
