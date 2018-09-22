# imx_install_poky

This container's single purpsoe is to pull down the Yocto SDK 'Poky' to the container or host mapped volume. 

It is flexible in that if you map a volume to /root/nxp on your host machine, the full Yocto Poky SDK
will be copied to that volume on the host.

There are two modes of operation:
1) interactive
2) non-interactive

# Interactive mode
This mode launches a simple terminal based script that presents you a menu of options.
Choosing option 1) Install Yocto Poky will guide you through a simple install process. 

it will give you the option of running oe-init-build-env with just defaults as well.

# How to run in interactive mode
In this example i have included a host volume in the command string.  You can omit the volume if you do not want it

docker run -i -v /mypath/mydir:/root/poky <imx_install_poky> interactive

The continer will execute and the menu system will appear in your terminal.
select option 1, hit enter and the process will begin.

Once you exit the menu, the container stops.

If you mapped a host volume, then the full Yocto Poky SDK will reside in that volume for you to use after
rm'ing the container.

# Non-interactive mode
This mode will run straight through installing the Yocto Poky SDK. 
At this time, i have not added the ability to select your desired SDK via command line.  This is
a feature i'm working on.   But Poky is the latet published by Yocto project.  You can always modify startup.sh
with whatever you desire to download

# how to run in non-interactive mode
Non-interactive mode instructs the container to download the yocto Poky sdk to /root/nxp/poky inside the container.

to run non-interactive mode, use the docker run command listed above in interactive mode but omit the argument "interactive"
so:

docker run -i -v /mypath/mydir:/root/poky <imx_install_poky>
