FROM debian:bullseye

ARG user_name
ARG git_user_name
ARG git_user_email

ARG USER_UID=1000
ARG USER_GID=$USER_UID

SHELL ["/bin/bash", "--login", "-c"]

RUN apt-get update && apt-get install -y autoconf automake build-essential cmake curl git-core gnupg jq libavdevice-dev libboost-dev libncurses5-dev libopencore-amrnb-dev libopencore-amrwb-dev libopus-dev libpcap-dev libsdl2-dev libspeex-dev libssl-dev libswscale-dev libtiff-dev libtool libtool-bin libv4l-dev libvo-amrwbenc-dev locales nano net-tools ngrep pkg-config python-dev rsyslog ruby subversion sudo swig tcpdump tmux tree uuid-dev vim wget tmuxinator xmlstarlet default-jdk doxygen mono-complete libxml2-utils

RUN apt install -y gnupg2

RUN apt-get install -y default-libmysqlclient-dev

RUN <<EOF
set -o errexit
set -o nounset
set -o pipefail

echo "install and setup mariadb and db redmine"
apt install -y mariadb-server

/etc/init.d/mariadb start

mysql -e "use mysql; ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('1234')"

mysql -u root -p1234 <<EOL
CREATE DATABASE redmine CHARACTER SET utf8mb4;
CREATE USER 'redmine'@'localhost' IDENTIFIED BY 'redmine';
GRANT ALL PRIVILEGES ON redmine.* TO 'redmine'@'localhost';
EOL

EOF

# Create the user
RUN groupadd --gid $USER_GID $user_name \
    && useradd --uid $USER_UID --gid $USER_GID -m $user_name

RUN echo $user_name ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$user_name \
    && chmod 0440 /etc/sudoers.d/$user_name

USER $user_name

RUN echo "set-option -g default-shell /bin/bash" >> ~/.tmux.conf

ENV TERM=xterm

RUN git config --global user.email $git_user_email
RUN git config --global user.name $git_user_name

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash && echo "nvm installation OK"

RUN . ~/.nvm/nvm.sh && nvm install v21.7.0

RUN . ~/.nvm/nvm.sh && npm install -g yarn

RUN mkdir -p ~/.vim/autoload ~/.vim/bundle && curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

RUN <<EOF cat > ~/.vimrc
set tabstop=4       " The width of a TAB is set to 4.
                    " Still it is a \t. It is just that
                    " Vim will interpret it to be having
                    " a width of 4.

set shiftwidth=4    " Indents will have a width of 4

set softtabstop=4   " Sets the number of columns for a TAB

set expandtab       " Expand TABs to spaces

execute pathogen#infect()
syntax on
filetype plugin indent on

set background=dark
colorscheme zenburn
EOF


RUN <<EOF
set -o errexit
set -o nounset
set -o pipefail

# install vim zenburn color theme
mkdir -p ~/.vim/colors/
cd ~/.vim/colors/
wget https://raw.githubusercontent.com/jnurmine/Zenburn/de2fa06a93fe1494638ec7b2fdd565898be25de6/colors/zenburn.vim
EOF

RUN <<EOF cat >> ~/.bashrc
export LANG=C.UTF-8
export PS1='\u@\h:\W\$ '
export TZ=Asia/Tokyo
export TERM=xterm-256color
. ~/.nvm/nvm.sh
EOF

RUN <<EOF
set -o errexit
set -o nounset
set -o pipefail

echo "Installing asdf and rust"

git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1

echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc
echo '. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc

# Source the asdf script directly within the same RUN block to get access to asdf ('source ~/.bashrc' will not work)
source "$HOME/.asdf/asdf.sh"
source "$HOME/.asdf/completions/asdf.bash"

asdf plugin add rust
asdf install rust 1.89.0
asdf global rust 1.89.0
EOF

RUN <<EOF
set -o errexit
set -o nounset
set -o pipefail

echo "Installing rvm and ruby (ruby versions installed using asdf were not being able to run ‘bundle install’ or ‘bundle exec …’ properly.)"

gpg2 --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

\curl -sSL https://get.rvm.io | bash -s stable

set +o nounset
source ~/.rvm/scripts/rvm
set -o nounset

echo "source ~/.rvm/scripts/rvm" >> ~/.bashrc

set +o nounset
rvm install 3.1.6
set -o nounset

EOF
