#!/bin/bash
# provisioner for the percona-toolkit-demos Vagrant box
# Fernando Ipar - fipar@acm.org

# set up Percona repo and install percona-toolkit

gpg --list-keys|grep mysql-dev@percona.com >/dev/null || {
    gpg --keyserver  hkp://keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
    gpg -a --export CD2EFD2A | apt-key add -
}

grep 'repo.percona.com' /etc/apt/sources.list >/dev/null || {
    cat << EOF >> /etc/apt/sources.list

deb http://repo.percona.com/apt lucid main
deb-src http://repo.percona.com/apt lucid main

EOF

    apt-get update

}

# wget -c http://download.virtualbox.org/virtualbox/4.2.0/VBoxGuestAdditions_4.2.0.iso

/etc/init.d/vboxadd setup

apt-get -y --force-yes install git-core build-essential libaio1 percona-toolkit

# install mysql-sandbox and percona-server-5.5 binary

rm -vrf /usr/local/mysql-sandbox/
rm -vrf /usr/local/demos/

test -d /usr/local/mysql-sandbox/ || {
    wget --progress=bar:force https://launchpad.net/mysql-sandbox/mysql-sandbox-3/mysql-sandbox-3/+download/MySQL-Sandbox-3.0.25.tar.gz -O /tmp/mysql-sandbox.tar.gz
    tar xzvf /tmp/mysql-sandbox.tar.gz -C /usr/local/ --transform "s/MySQL-Sandbox-3.0.25/mysql-sandbox/g"
    pushd /usr/local/mysql-sandbox/
    perl Makefile.PL PREFIX=/usr/local/mysql-sandbox
    make
    make test
    make install
    echo 'export PATH=$PATH:/usr/local/mysql-sandbox/bin'>>/etc/bash.bashrc
    echo 'export PERL5LIB=$PERL5LIB:/usr/local/mysql-sandbox/lib/'>>/etc/bash.bashrc
    echo 'export SANDBOXES_HOME=/usr/local/demos/sb'>>/etc/bash.bashrc
    echo 'export SANDBOX_HOME=/usr/local/demos/'>>/etc/bash.bashrc
    rm -f /tmp/mysql-sandbox.tar.gz
    popd
}

test -d /usr/local/5.5.27/ || {
    wget --progress=bar:force http://www.percona.com/redir/downloads/Percona-Server-5.5/Percona-Server-5.5.27-28.1/binary/linux/x86_64/Percona-Server-5.5.27-rel28.1-296.Linux.x86_64.tar.gz -O /tmp/percona-server.tar.gz
    tar xzvf /tmp/percona-server.tar.gz -C /usr/local --transform "s/Percona-Server-5.5.27-rel28.1-296.Linux.x86_64/5.5.27/g"
    echo 'export PATH=$PATH:/usr/local/percona-server/bin'>>/etc/bash.bashrc
    rm -f /tmp/percona-server.tar.gz
}

test -d /usr/local/demos/ || {
    pushd /tmp/
    git clone https://github.com/markusalbe/vagrant_pt_demos
    cp -rv vagrant_pt_demos/demos /usr/local
    chown -v -R vagrant.vagrant /usr/local/demos/
    echo 'export PATH=$PATH:/usr/local/demos/'>>/etc/bash.bashrc
    rm -rf /tmp/vagrant_pt_demos
    popd
}

cd /vagrant/demos/;
mkdir /usr/local/demos/_tmp;
for i in `ls *.sh`; do {
    mv -v /usr/local/demos/$i /usr/local/demos/_tmp/;
    ln -v -s /vagrant/demos/$i /usr/local/demos/;
} done;



# we need these here, or run /etc/bash.bashrc, since that is not run before the line below
# export PATH=$PATH:/usr/local/percona-server/bin:/usr/local/mysql-sandbox/bin:/usr/local/demos/:/usr/local/mysql-sandbox/
# export PERL5LIB=$PERL5LIB:/usr/local/mysql-sandbox/lib/
# export SANDBOXES_HOME=/usr/local/demos/sb
# export SANDBOX_HOME=/usr/local/demos/
# if at least one sandbox exists, I assume all of them do
# [ -d /usr/local/demos/sb/master-active/ ] || su --preserve-environment --login - vagrant -c "/usr/local/demos/create-sandboxes.sh"
cp -vf /etc/skel/.bashrc /home/vagrant/
chown vagrant.vagrant /home/vagrant/.bashrc
echo '. /usr/local/demos/create-sandboxes.inc.sh' >> /home/vagrant/.bashrc
echo '. /usr/local/demos/create-sandboxes.sh' >> /home/vagrant/.bashrc


echo "0" > /proc/sys/vm/swappiness