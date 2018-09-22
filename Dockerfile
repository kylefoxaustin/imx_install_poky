################################################################################
# base system
################################################################################
FROM ubuntu:18.04 as system

ARG localbuild
RUN if [ "x$localbuild" != "x" ]; then sed -i 's#http://archive.ubuntu.com/#http://tw.archive.ubuntu.com/#' /etc/apt/sources.list; fi

RUN apt-get update \
    && apt-get install -y --no-install-recommends software-properties-common curl apache2-utils \
    && apt-get update \
    && apt-get install -y --no-install-recommends --allow-unauthenticated \
        supervisor nginx sudo vim-tiny net-tools zenity xz-utils \
        dbus-x11 x11-utils alsa-utils \
        mesa-utils libgl1-mesa-dri \
    && add-apt-repository -r ppa:fcwu-tw/apps \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*


# start installing Yocto base host packages, git, tar, python
RUN apt-get update && apt-get install -y --no-install-recommends git tar python3

# now install additional yocto base host packages
RUN apt-get update && apt-get install -y --no-install-recommends gawk wget git-core diffstat unzip texinfo gpg-agent gcc-multilib \
     build-essential chrpath socat cpio python python3 python3-pip python3-pexpect \
     xz-utils debianutils iputils-ping libsdl1.2-dev xterm

RUN apt-get update

# now install from the NXP i.MX recommended yocto packages
RUN apt-get update && apt-get install -y --no-install-recommends gawk wget git-core diffstat unzip texinfo gcc-multilib \
 build-essential chrpath socat libsdl1.2-dev libsdl1.2-dev xterm sed cvs subversion coreutils texi2html \
docbook-utils python-pysqlite2 help2man make gcc g++ desktop-file-utils \
libgl1-mesa-dev libglu1-mesa-dev mercurial autoconf automake groff curl lzop asciidoc 

RUN apt-get update

# now install uboot tools from NXP i.MX recommended yocto packages
RUN apt-get update && apt-get install -y --no-install-recommends u-boot-tools

RUN apt-get update

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates



LABEL maintainer="kylefoxaustin"

COPY image /

WORKDIR /root 
ENV TERM=xterm
ENV HOME=/root/ \
    SHELL=/bin/bash
ENTRYPOINT ["/startup.sh"]
