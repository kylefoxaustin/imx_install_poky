#!/bin/bash


##### imx-install-poky script #####

# This is the ENTRYPOINT script which is run in the docker container imx_install_poky
# the purpose of the script is to provide an interactive or non-interactive method of
# pulling down yocto poky to the container and any host volume mapped to the container 
#
# When run without an argument, the script will pull the default yocto Poky build
#
# The directory is hard coded to $HOME/nxp/poky which the BSP itself is pulled into
#
# When startup.sh is run interactively, it will enable user to walk through installing Poky
# to run it interactively the script expects this:  startup.sh interactive
#
# This script will also enable the user to specify a USER name and PASSWORD.
# These parameters are passed to the startup.sh by the docker run command itself, not via this script's argument processing capabilities
# that is why you see USER and PASSWORD processed below without any apparent checking for those arguments to be passed into the shell itself.
# that is all handled by docker...
#
# Maintainer:  kyle fox (github.com/kylefoxaustin)


### debug messaging on or off function
### this function must always be at the top of the script as it
### may be used in the script immediately following its definition
### within the body of this script, if a debug message is to be run
### it will have the form of "debug && <command to run>
### if DEBUGON=0 then the <command to run> will be executed
### if DEBUGON=1 then the <command to run> will be ignored
# set DEBUGON

debug () {
      return $DEBUGON
      }

debug && echo "Beginning of startup.sh script"


###############################
#       process arguments    #
#############################

INTERACTIVE=1
if [ "$1" != "interactive" ]; then
    debug && echo "non-interactive mode"
    INTERACTIVE=1 # user does NOT want interactive mode
else
    INTERACTIVE=0 # user wants interactive mode
fi



###############################
#       globals              #
#############################

# set DEBUGON initial value to OFF =1
DEBUGON=1

BINDIRECTORY="/usr/local/bin"
REPOFILE="/usr/local/bin/repo"
TERM=xterm	 
POKYDIR="${HOME}/nxp/poky"


######################################
# set the user up and permissions  ##
# either root or user supplied    ##
# via docker run -e USER         ##
##################################

DEBUGON=1
debug && echo "This is the HOME directory before setting HOME to root $HOME"
debug && echo "this is the path of current directory:"
debug && pwd
debug && echo "this is who the user is $USER"
debug && echo "before performing user=dollarusercolon-root"
debug && sleep 2

debug && echo "setting USER to root"

USER=${USER:-root}
debug && echo "this is who the user is $USER"
debug && echo "that is after doing the user=dollarusercolon-root command"

debug && echo "setting HOME to root"
HOME=/root
if [ "$USER" != "root" ]; then
    debug && echo "starting user not equal to root"
    debug && echo "* enable custom user: $USER"
    useradd --create-home --shell /bin/bash --user-group --groups adm,sudo $USER

    if [ -z "$PASSWORD" ]; then
        debug && echo "Setting default password to \"password\""
        PASSWORD=password

    fi
    HOME=/home/$USER
    echo "$USER:$PASSWORD" | chpasswd

fi
debug && sleep 2

DEBUGON=1

######################################
# clean up supervisord.conf        ##
# -this is for docker container    ##
####################################

debug && echo "about to remove \%USER\%:\%USER\% from supervisord.con"
sed -i "s|%USER%|$USER|" /etc/supervisor/conf.d/supervisord.conf

debug && echo "about to remove \%HOME\%:\%HOME\% from supervisord.conf"
sed -i "s|%HOME%|$HOME|" /etc/supervisor/conf.d/supervisord.conf


# check if 1st time run or not
# if already run, then we don't need to change permissions and don't want to
# this keeps chown from changing owernship of potentially thousands of files
# which can take a long time

if [ ! -f /usr/local/chownstatus/chownhasrun.txt ]; then
    debug && echo "This is 1st time container has run, need to chown $USER:$USER $HOME" 
    chown -R --verbose $USER:$USER $HOME
    chown -R --verbose $USER:$USER $BINDIRECTORY
    mkdir -p /usr/local/chownstatus/
    touch /usr/local/chownstatus/chownhasrun.txt 
fi



################################
#  Final Steps               ##
##############################


debug && echo "HOME ENV was $HOME"
debug && echo "setting HOME ENV to actual path"
debug && echo "HOME ENV is now $HOME"
debug && sleep 10

#now add line to bashrc and profile for HOME directory's actual position
#at this point, ubuntu has HOME=/home.  But if you start container as root (default) and
#don't place a new user name in the docker run command, then HOME needs to be /root
#we do the install menu prior to this so that if we are already root, we don't change
#the bashrc and profiles to 'root'

if [ "$HOME" = "/root" ]; then
    debug && echo "HOME was /root so about to set bashrc and profile exports"
    echo 'export HOME=/root/' >> /root/.bashrc
    source /root/.bashrc
    echo 'export HOME=/root/' >> /root/.profile
    source /root/.bashrc
else
    debug && echo "HOME was NOT /root so about to set bashrc and profile exports"
    echo 'export HOME=$HOME' >> /${HOME}/.bashrc
    source /${HOME}/.bashrc
    echo 'export HOME=$HOME' >> /${HOME}/.profile
    source /${HOME}/.bashrc
fi

#############################################
# Main interactive install menu           ##
# 1) setup poky                           ##
# 2) Exit                                 ##
############################################


# ===================
# Script funtionality
# ===================
# FUNCTION: dosomething_1
# note:  for each menu item, you will create a new dosomething_x function
#        e.g. menu item 2 requires a dosomething_2 function here




##############################
#  functions for menu script    ##
############################



poky_init_build_env () {

    # if this function is called then poky is installed already
    # so don't need to check if poky exists or not
    
    if [ "$1" == "non_interactive" ]; then
	
	# if this function is called then poky is installed already
	# so don't need to check if poky exists or not
	
	local TEMPPOKYDIR=""
	TEMPPOKYDIR=$2
	debug && echo "this is the temppokydir value"
	echo $TEMPPOKYDIR
	echo "executing oe-init-build-env script"
	source $TEMPPOKYDIR/oe-init-build-env
	echo "oe-init-build-env completed"
	debug && sleep 2
    else
	local TEMPPOKYDIR=""
	TEMPPOKYDIR=$2
	echo "this is the temppokydir value"
	echo $TEMPPOKYDIR
	echo "Run the Yocto build environment script (oe-init-build-env)? Enter Y or N"
	read RUNENV
	case $RUNENV in 
	    y|Y ) debug && echo "yes"
		  source $TEMPPOKYDIR/oe-init-build-env
		  echo "oe-init-build-env completed"
		  echo "press ENTER to continue..."
		  read enterkey	       ;;
	    n|N ) echo "Exiting Poky init build environment setup...";;
	    * ) echo "invalid option";;
	esac
    fi
    
}


poky_install() {

    if [ "$1" == "non_interactive" ]; then
	# non_interactive install
	POKYDIR="${HOME}/nxp/poky"
	echo "checking if Yocto Poky has been installed already"
	echo "POKYDIR is = $POKYDIR"
	if [ ! -d "$POKYDIR" ]; then
	    echo "Yocto Poky check... POKYDIR doesn't exist so creating Poky and cloning"
	    mkdir -p $POKYDIR
	    echo $PWD
	    echo "beginning clone...:"
	    git clone --progress git://git.yoctoproject.org/poky $POKYDIR
	    echo $PWD
	    cd $POKYDIR
	    echo $PWD
	    echo ""
	    echo "clone complete..."
	    echo "about to initiate git checkout, tags yocto-2.5 to my-yocto-2.5"
	    git checkout tags/yocto-2.5 -b my-yocto-2.5
	    echo "git checkout complete..."
	    echo "install complete into $POKYDIR"
	    poky_init_build_env non_interactive $POKYDIR
	elif find $POKYDIR -mindepth 1 | read; then
	    echo "$POKYDIR exists, is non empty, therefore poky already installed"
	else
	    echo "$POKYDIR exists but directory does not contain anything"
	    echo "proceeding with installation into $POKYDIR"
	    echo "beginning clone...:"
	    git clone --progress git://git.yoctoproject.org/poky $POKYDIR
	    echo $PWD
	    cd $POKYDIR
	    echo $PWD
	    echo "clone complete..."
	    echo "about to initiate git checkout, tags yocto-2.5 to my-yocto-2.5"
	    git checkout tags/yocto-2.5 -b my-yocto-2.5
	    echo "git checkout complete"
	    echo "install complete..."
	    poky_init_build_env non_interactive $POKYDIR
	fi

    else
	# interactive install
	echo "Install Poky?  Enter Y or N"
	local CONTINUE=0
	read CONTINUE 
	case $CONTINUE in 
	    y|Y ) echo "yes"
		  POKYDIR="${HOME}/poky"
		  echo "checking if Yocto Poky has been installed already"
		  echo "POKYDIR is = $POKYDIR"
		  if [ ! -d "$POKYDIR" ]; then
		      echo "Yocto Poky check... POKYDIR doesn't exist so creating Poky and cloning"
		      mkdir -p $POKYDIR
		      echo $PWD
		      echo "beginning clone...:"
		      git clone --progress git://git.yoctoproject.org/poky $POKYDIR
		      echo $PWD
		      cd $POKYDIR
		      echo $PWD
		      echo ""
		      echo "clone complete..."
		      echo "about to initiate git checkout, tags yocto-2.5 to my-yocto-2.5"
		      git checkout tags/yocto-2.5 -b my-yocto-2.5
		      echo "git checkout complete..."
		      echo "install complete into $POKYDIR"
		      echo "press ENTER to continue..."
		      read enterkey
		      poky_init_build_env $POKYDIR
		  elif find $POKYDIR -mindepth 1 | read; then
		      echo "$POKYDIR exists, is non empty, therefore poky already installed"
		      echo "press ENTER to continue..."
		      read enterkey
		  else
		      echo "$POKYDIR exists but directory does not contain anything"
		      echo "proceeding with installation into $POKYDIR"
		      echo "beginning clone...:"
		      git clone --progress git://git.yoctoproject.org/poky $POKYDIR
		      echo $PWD
		      cd $POKYDIR
		      echo $PWD
		      echo "clone complete..."
		      echo "about to initiate git checkout, tags yocto-2.5 to my-yocto-2.5"
		      git checkout tags/yocto-2.5 -b my-yocto-2.5
		      echo "git checkout complete"
		      echo "install complete..."
		      echo "press ENTER to continue..."
		      read enterkey
		      poky_init_build_env $POKYDIR
		  fi
		  ;;
	    n|N ) echo "no";;
	    * ) echo "invalid choice";;
	esac
    fi
    
}


# ================
# Install Menu Script structure
# ================


# FUNCTION: display menu options
# this is the main menu engine to show what you can do
show_menus() {
    clear
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo " Main Menu"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "  1. Install Yocto Poky"
    echo "  2. Exit"
    echo ""
}

# Use menu...
# Main menu handler loop


debug && echo "ABOUT TO START THE MENU INSTALL"
debug && sleep 2

if [ "$INTERACTIVE" == "1" ]; then
    debug && echo "starting non-interactive mode"
    poky_install non_interactive
else
    debug && echo "starting interactive mode"
    KEEPLOOPING=0
    while [ $KEEPLOOPING -eq 0 ]
    do
	show_menus
	echo "Enter choice [ 1 - 2 ] "
	menuchoice=0
	read menuchoice
	case $menuchoice in
	    1) poky_install
	       ;;
	    2) echo "exiting"
	       KEEPLOOPING=1
	       continue;;
	    *) echo -e "${RED}Error...${STD}" && sleep 2
	       ;;
	esac
	echo "Return to the Main Menu? (y/n)"
	yesno=0
	read yesno
	case "$yesno" in 
	    y|Y ) continue;;
	    n|N ) break;;
	esac
    done
fi

exit 0
