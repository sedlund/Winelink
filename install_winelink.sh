#!/bin/bash

########### Winlink & VARA Installer Script for the Raspberry Pi 4B ###########
# Author: Eric Wiessner (KI7POL)                                              #
# Version: Work in progress (lots of bugs!)                                   #
# Credits:                                                                    #
#   The Box86 team                                                            #
#      (ptitSeb, pale, chills340, phoenixbyrd, Botspot, !FlameKat53, epychan, #
#       Heasterian, monkaBlyat, SpacingBat3, #lukefrenner, Icenowy, Longhorn, #
#       #MonthlyDoseOfRPi, luschia, Binay Devkota, hacker420, et.al.)         #
#   K6ETA & DCJ21's Winlink on Linux guides                                   #
#   KM4ACK & OH8STN for inspiration                                           #
#   N7ACW & AD7HE for getting me started in ham radio                         #
#                                                                             #
#    "My humanity is bound up in yours, for we can only be human together"    #
#                                                - Nelson Mandela             #
###############################################################################

# About:
#    This script will help you install Box86, Wine, winetricks, Windows DLL's, Winlink (RMS Express) & VARA.  You will then need to configure RMS Express & VARA to send/receive audio from a USB sound card plugged into your Pi.  This installer will only work on the Raspberry Pi 4B for now.  If you would like to use an older Raspberry Pi (3B+, 3B, 2B, Zero, for example), software may run very slow and you may need to compile a custom 2G/2G split memory kernel before installing.
#
# Distribution:
#    This script is free to use, open-source, and should not be monetized.  If you use this script in your project (or are inspired by it) just please be sure to mention ptitSeb, Box86, and myself (KI7POL).
#
# Legal:
#    All software used by this script is free and legal to use (with the exception of VARA, of course, which is shareware).  Box86 and Wine are both open-source (which avoids the legal problems of use & distribution that ExaGear had - ExaGear also ran much slower than Box86 and is no-longer maintained, despite what Huawei says these days).  All proprietary Windows DLL files required by Wine are downloaded directly from Microsoft and installed according to their redistribution guidelines.
#
# Donations:
#    If you feel that you are able and would like to support this project, please consider sending donations to ptitSeb or KM4ACK - without whom, this script would not exist.
#        - Sebastien "ptitSeb" Chevalier - author of "Box86": paypal.me/0ptitSeb
#        - Jason Oleham (KM4ACK) - inspiration & Linux elmer: paypal.me/km4ack
#
winelink_dir=$(pwd)
sudo apt-get install p7zip-full -y

############  Clean up files from any failed past runs of this script ############
rm -rf $winelink_dir/downloads/
clear

############  Setup the RPi4 to run Windows .exe files ############ 
# To run Windows .exe files on RPi4, we need an x86 emulator (box86) and a Windows API Call interpreter (wine)
# Box86 is opensource and runs about 10x faster than ExaGear or Qemu.  It's much smaller and easier to install too.

mkdir $winelink_dir/downloads/

### Install Box86
sudo apt-get install cmake -y
cd $winelink_dir/downloads/
mkdir box86-installer && cd box86-installer
git clone https://github.com/ptitSeb/box86
cd box86/
git checkout db5efa89085a085d733c859662799ebcf4e5c3c2 # this version of box86 installs dotnet35sp1 but doesn't run RMS Express
mkdir build; cd build; cmake .. -DRPI4=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
make -j4
sudo make install # copies box86 files to /usr/local/bin/box86
sudo systemctl restart systemd-binfmt # essentially initializes box86
git checkout master


### Download and install Wine 5.21 devel buster for i386

# Backup old wine
wineserver -k # stop any old wine installations from running
sudo mv ~/wine ~/wine-old
sudo mv ~/.wine ~/.wine-old
sudo mv /usr/local/bin/wine /usr/local/bin/wine-old
sudo mv /usr/local/bin/wineboot /usr/local/bin/wineboot-old
sudo mv /usr/local/bin/winecfg /usr/local/bin/winecfg-old
sudo mv /usr/local/bin/wineserver /usr/local/bin/wineserver-old

# Download, extract wine, and install wine
# (Replace the links/versions below with links/versions from the WineHQ site for the version of wine you wish to install. Note that we need the i386 version for Box86 even though we're installing it on our ARM processor.)
# (Pick an i386 version of wine-devel, wine-staging, or wine-stable)
cd $winelink_dir/downloads/
wget https://dl.winehq.org/wine-builds/debian/dists/buster/main/binary-i386/wine-devel-i386_5.21~buster_i386.deb # NOTE: Replace this link with the version you want
wget https://dl.winehq.org/wine-builds/debian/dists/buster/main/binary-i386/wine-devel_5.21~buster_i386.deb  # NOTE: Also replace this link with the version you want
dpkg-deb -xv wine-devel-i386_5.21~buster_i386.deb wine-installer # NOTE: Make sure these dpkg command matches the filename of the deb package you just downloaded
dpkg-deb -xv wine-devel_5.21~buster_i386.deb wine-installer
mv $winelink_dir/downloads/wine-installer/opt/wine* ~/wine
rm wine*.deb # clean up
rm -rf wine-installer # clean up

# Install shortcuts (make 32bit launcher & symlinks. Credits: grayduck, Botspot)
echo -e '#!/bin/bash\nsetarch linux32 -L '"$HOME/wine/bin/wine "'"$@"' | sudo tee -a /usr/local/bin/wine >/dev/null # Create a script to launch wine programs as 32bit only
#sudo ln -s ~/wine/bin/wine /usr/local/bin/wine # You could aslo just make a symlink, but box86 only works for 32bit apps at the moment
sudo ln -s ~/wine/bin/wineboot /usr/local/bin/wineboot
sudo ln -s ~/wine/bin/winecfg /usr/local/bin/winecfg
sudo ln -s ~/wine/bin/wineserver /usr/local/bin/wineserver
sudo chmod +x /usr/local/bin/wine /usr/local/bin/wineboot /usr/local/bin/winecfg /usr/local/bin/wineserver

# These packages are needed for running wine-staging on RPi 4 (Credits: chills340)
#sudo apt install libstb0 -y
#cd $winelink_dir/downloads
#wget http://ftp.us.debian.org/debian/pool/main/f/faudio/libfaudio0_20.11-1~bpo10+1_i386.deb
#wget -r -l1 -np -nd -A "libfaudio0_*~bpo10+1_i386.deb" http://ftp.us.debian.org/debian/pool/main/f/faudio/ # Download libfaudio i386 no matter its version number
#dpkg-deb -xv libfaudio0_*~bpo10+1_i386.deb libfaudio
#sudo cp -TRv libfaudio/usr/ /usr/
#rm libfaudio0_*~bpo10+1_i386.deb # clean up
#rm -rf libfaudio # clean up

# Initialize Wine silently
rm -rf ~/.cache/wine # make sure we don't install mono or gecko (if their msi files are in wine cache)
DISPLAY=0 wineboot # silently makes a fresh wineprefix in ~/.wine and skips installation of mono & gecko



### Download & install winetricks
sudo mv /usr/local/bin/winetricks /usr/local/bin/winetricks-old # backup old winetricks
cd $winelink_dir/downloads
wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks # download
sudo chmod +x winetricks 
sudo mv winetricks /usr/local/bin # install
sudo apt-get install cabextract -y # winetricks needs this



### Setup Wine (install system requirements into our wineprefix for Winlink & VARA)
BOX86_NOBANNER=1 winetricks -q corefonts dotnet35sp1 vb6run win7 sound=alsa # for RMS Express
BOX86_NOBANNER=1 winetricks -q vcrun2015 pdh # for VARA (run pdh here just for the winecfg dll override)
BOX86_NOBANNER=1 winetricks -q riched30 richtx32 crypt32 comctl32ocx comdlg32ocx # for Box86 compatibility (to cover any wine libraries that aren't wrapped in Box86 yet)
# NOTE: This command needs testing - vcrun2015, crypt32, and the ocx components may not install properly
# Notes: Does Winlink HF Channel Selector (ITS) need ie6 or gecko?

# Install an older pdh.dll (the pdh.dll from "winetricks pdh" is too new for VARA)
cd $winelink_dir/downloads
wget http://download.microsoft.com/download/winntsrv40/update/5.0.2195.2668/nt4/en-us/nt4pdhdll.exe
7z x nt4pdhdll.exe pdh.dll
mv pdh.dll ~/.wine/drive_c/windows/system32
rm nt4pdhdll.exe # clean up

rm -rf ~/.cache/winetricks/ # clean up cached Microsoft installers now that we're done setting up Wine



# NOTE: THIS IS A KLUDGE!!
# dotnet35sp1 installer needs an old box86, but our programs need the latest box86. Update box86 with these commands.
cd $winelink_dir/downloads/box86-installer
cd box86/
# freeze version of box86 at a commit which is known to work 
#git checkout 6a498c373c35ed2542a9667617abb96c4c767036 # VARA, RMS, internet work, lots of crashes
git checkout cad160205fd9a267e6c3d9d784fbef72b1c68dde # VARA, RMS work; internet doesn't work, less crashes
cd build
make -j4
sudo make install

rm -rf $winelink_dir/downloads/box86-installer # clean up





### Setup AutoHotKey and make some .ahk scripts we'll use later
cd $winelink_dir/
mkdir ahk; cd ahk
wget https://github.com/AutoHotkey/AutoHotkey/releases/download/v1.0.48.05/AutoHotkey104805_Install.exe
7z x AutoHotkey104805_Install.exe AutoHotkey.exe
sudo chmod +x AutoHotkey.exe
rm AutoHotkey104805_Install.exe # Clean up

#Create vara_install.ahk
echo '; AHK script to make VARA installer run completely silent'                       >> $winelink_dir/ahk/vara_install.ahk
echo 'SetTitleMatchMode, 2'                                                            >> $winelink_dir/ahk/vara_install.ahk
echo 'SetTitleMatchMode, slow'                                                         >> $winelink_dir/ahk/vara_install.ahk
echo '        Run, VARA setup (Run as Administrator).exe /SILENT, C:\'                 >> $winelink_dir/ahk/vara_install.ahk
echo '        WinWait, VARA Setup ; Wait for the "VARA installed successfully" window' >> $winelink_dir/ahk/vara_install.ahk
echo '        ControlClick, Button1, VARA Setup ; Click the OK button'                 >> $winelink_dir/ahk/vara_install.ahk
echo '        WinWaitClose'                                                            >> $winelink_dir/ahk/vara_install.ahk

#Create vara_setup.ahk
echo '; AHK script to assist users in setting up VARA on its first run'                >> $winelink_dir/ahk/vara_setup.ahk
echo 'SetTitleMatchMode, 2'                                                            >> $winelink_dir/ahk/vara_setup.ahk
echo 'SetTitleMatchMode, slow'                                                         >> $winelink_dir/ahk/vara_setup.ahk
echo '        Run, VARA.exe, C:\VARA'                                                  >> $winelink_dir/ahk/vara_setup.ahk
echo '        WinActivate, VARA HF'                                                    >> $winelink_dir/ahk/vara_setup.ahk
echo '        WinWait, VARA HF ; Wait for VARA to open'                                >> $winelink_dir/ahk/vara_setup.ahk
echo '        Sleep 3500 ; If we dont wait at least 2000 for VARA then AHK wont work'  >> $winelink_dir/ahk/vara_setup.ahk
echo '        Send, !{s} ; Open SoundCard menu'                                        >> $winelink_dir/ahk/vara_setup.ahk
echo '        Sleep 500'                                                               >> $winelink_dir/ahk/vara_setup.ahk
echo '        Send, {Down}'                                                            >> $winelink_dir/ahk/vara_setup.ahk
echo '        Sleep, 100'                                                              >> $winelink_dir/ahk/vara_setup.ahk
echo '        Send, {Enter}'                                                           >> $winelink_dir/ahk/vara_setup.ahk
echo '        Sleep 500'                                                               >> $winelink_dir/ahk/vara_setup.ahk
echo '        WinWaitClose, SoundCard ; Wait for user to finish setting up soundcard'  >> $winelink_dir/ahk/vara_setup.ahk
echo '        Sleep 50'                                                                >> $winelink_dir/ahk/vara_setup.ahk
echo '        WinClose, VARA HF ; Close VARA'                                          >> $winelink_dir/ahk/vara_setup.ahk






############  Install Winlink and VARA (into our configured wineprefix) ############
### Download/extract/install Winlink Express (formerly RMS Express) [https://downloads.winlink.org/User%20Programs/]
cd $winelink_dir/downloads

wget -r -l1 -np -nd -A "Winlink_Express_install_*.zip" https://downloads.winlink.org/User%20Programs # Download Winlink no matter its version number

7z x Winlink_Express_install_*.zip -o"WinlinkExpressInstaller"
    wine $winelink_dir/downloads/WinlinkExpressInstaller/Winlink_Express_install.exe /SILENT
    cp ~/.local/share/applications/wine/Programs/RMS\ Express/Winlink\ Express.desktop ~/Desktop/ # Make desktop shortcut.  FIX ME: Run a script instead with wineserver -k in front of it

rm Winlink_Express_install_*.zip # clean up
rm -rf WinlinkExpressInstaller # clean up


### Download/extract/install VARA HF (or newer) [https://rosmodem.wordpress.com/]
sudo apt-get install megatools -y

cd $winelink_dir/downloads
VARALINK=$(curl -s https://rosmodem.wordpress.com/ | grep -oP '(?<=<a href=").*?(?=" target="_blank" rel="noopener noreferrer">VARA HF v)') # Find the mega.nz link from the rosmodem website no matter its version, then store it as a variable
megadl ${VARALINK}

7z x VARA*.zip -o"VARAInstaller"
    mv $winelink_dir/downloads/VARAInstaller/VARA\ setup*.exe ~/.wine/drive_c/ # Move VARA installer here so AHK can find it
    # The VARA installer prompts the user to hit 'OK' even during silent install (due to a secondary installer).  We will suppress this prompt with AHK.
    wine $winelink_dir/ahk/AutoHotkey.exe $winelink_dir/ahk/vara_install.ahk
    cp ~/.local/share/applications/wine/Programs/VARA/VARA.desktop ~/Desktop/ # Make desktop shortcut.  FIX ME: Run a script instead with wineserver -k in front of it

rm VARA*.zip # clean up
rm ~/.wine/drive_c/VARA\ setup*.exe # clean up
rm -rf VARAInstaller # clean up




###### Configure Winlink and VARA ######
clear
echo 
echo "In winecfg, go to the Audio tab to set up your default in/out soundcards."
winecfg
clear



### Fix some VARA graphics glitches caused by Wine's window manager (otherwise VARA appears as a black screen when auto-run by RMS Express)
# Make sure "Allow the window manager to control the windows" is unchecked in winecfg's Graphics tab
# NEEDS FIXING
RESULT=$(grep '"Managed"="Y"' ~/.wine/user.reg)
if [ "$RESULT" == '"Managed"="Y"' ]
then
    sed -i 's/"Managed"="Y"/"Managed"="N"/g' ~/.wine/user.reg
fi    # if wine already enabled window manager control then disable it

RESULT=$(grep '"Managed"="N"' ~/.wine/user.reg)
if [ "$RESULT" == '"Managed"="N"' ]
then
    : # if wine has window manager control disabled, then do nothing
else
    echo '' >> ~/.wine/user.reg
    echo '[Software\\Wine\\X11 Driver] 1614196385' >> ~/.wine/user.reg
    echo '#time=1d70ae6ab06f57a' >> ~/.wine/user.reg
    echo '"Decorated"="Y"' >> ~/.wine/user.reg
    echo '"Managed"="N"' >> ~/.wine/user.reg
fi    # if wine doesn't have any window manager control setting preferences yet, then set them as disabled



### Set up VARA (with some help from AutoHotKey)
clear
echo 
echo "Please set up your soundcard input/output for VARA"
#wine ~/.wine/drive_c/VARA/VARA.exe
wine $winelink_dir/ahk/AutoHotkey.exe $winelink_dir/ahk/vara_setup.ahk


clear
echo "In RMS Express, enter your callsign, password, gridsquare, and soundcard in/out, then close the program.  Ignore any errors for now."
wine ~/.wine/drive_c/RMS\ Express/RMS\ Express.exe

clear
echo "We're going to run Winlink a few more times so it can shake some bugs out"
wineserver -k
wine ~/.wine/drive_c/RMS\ Express/RMS\ Express.exe
wineserver -k
wine ~/.wine/drive_c/RMS\ Express/RMS\ Express.exe

#############  Known bugs ############# 
# The Channel Selector is functional, it just takes about 5 minutes to update its propagation indices and sometimes crashes the first time it's loaded.  Just restart it if it crashes.  If you let it run for 5 minutes, then you shouldn't have to do that again - just don't hit the Update Table Via Internet button.  I'm currently experimenting with ITS HF: http://www.greg-hand.com/hfwin32.html
# VARA has some graphics issues for now.  This is an issue with Wine, not box86
# RMS Express internet may not work on the first run (or in some cases ever) for some reason.  This might be due to vbrun6 being installed with old box86?
