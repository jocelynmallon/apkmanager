#! /bin/sh
# -----------------------------------------------------------------------
# Apk Manager OS X v3.0+
# Installation functions
#
# by Jocelyn Mallon CC by-nc-sa 2012
# http://girlintroverted.wordpress.com
#
# version: 3.0b
# Sat. May 19, 2012
# -----------------------------------------------------------------------

# cleanup variables used during installation
cleanup_install () {
    unset count
    unset missing
    unset key
    unset value
    unset input
    unset err_shown
    unset btap
    unset needsdk
    unset p
}

# write install status to plist
setinstallstatus () {
    local key
    local value
    key="install"
    value="${installtype}"
    write_preference
    local key="debugset"
    local value="false"
    write_preference
    unset apktool_ver
    if [[ -f "${HOME}/.apkmanager/.debuginfo" ]]; then
        rm -r "${HOME}/.apkmanager/.debuginfo"
    fi
}

# java not found fatal error string
java_error () {
    echo $bred" FATAL ERROR: Java was not found on this system."
    echo $bred" Starting with OS X 10.7, java is not included"
    echo $bred" with the default OS X installation."
    echo $bred" Please install Java before using APK Manager."
    echo ""
    printf "$bred%s"" PRESS ANY KEY TO EXIT..."; $rclr;
    wait
    exit 1
}

# android sdk warning/error message
andsdk_error () {
    clear
    echo ""
    version_banner
    echo ""
    echo $bred" WARNING: Android SDK was not found on this system."
    echo ""
    echo $white" And APK Manager did not find \"homebrew\" to"
    echo $white" install the SDK automaticall for you."
    echo ""
    echo $white" Though not technically required to function, the"
    echo $white" Android SDK is incredibly useful, and will enable"
    echo $white" APK Manager to launch ddms and draw9patch."
    echo ""
    echo $white" Please see the Android SDK installation page:"
    echo ""
    echo $bgreen" http://developer.android.com/sdk/index.html"
    echo ""
    echo $bred" be sure to add both \"tools\" and \"platform-tools\""
    echo $bred" to your \"\$PATH\" after installation finishes."
    echo ""
    echo $bgreen"$apkmftr";
    printf "$bred%s"" PRESS ANY KEY TO CONTINUE..."; $rclr;
    err_shown="1"
    wait
}

# homebrew installation error message
brew_install_error () {
    echo $bred" ERROR: Homebrew encountered an error"
    echo $bred" trying to install the necessary programs."
    echo $bred" Please run \"brew doctor\" and \"brew update\""
    echo $bred" and try apk manager setup again."
    echo ""
    printf "$bred%s"" PRESS ANY KEY TO EXIT..."; $rclr;
    wait
    exit 1
}

# pngout error message
pngout_error () {
    echo $bred" WARNING: pngout was not found on this system,"
    echo $bred" and APK Manager did not find \"homebrew\" either."
    echo $bred" To install pngout, please select pngout for"
    echo $bred" your optimization tool from the debug menu inside"
    echo $bred" APK Manager once setup finishes."
    echo ""
    printf "$bred%s"" PRESS ANY KEY TO CONTINUE..."; $rclr;
    wait
}

# error message during install
bin_install_err () {
    echo $bred"Something went wrong trying to install required binaries"
    printf "$bred%s""PRESS ANY KEY TO EXIT..."; $rclr;
    wait
    exit 1
}

# placeholder for updates setup prompt
setup_updates_prompt () {
    if [[ $count -ne 0 ]]; then
        clear
        echo ""
        version_banner
    fi
    echo ""
    echo $white" APK Manager has detected that \"git\" is installed on this system."
    echo $white" Using git, APK Manager can keep itself up-to-date by automatically"
    echo $white" by checking weekly for new updates to APK Manager on github:"; $rclr;
    echo ""
    echo $green" https://github.com/jocelynmallon/apkmanager"
    echo ""
    echo $bgreen"$apkmftr";
    printf "$white%s""Would you like to enable automatic updates? ("$bgreen"y"$white"/"$bgreen"n"$white") "; $rclr;
    read input
    case "$input" in
     [yY])  enable_auto_updates ;;
     [nN])  disable_auto_updates ;;
        *)  input_err; setup_updates_prompt ;;
    esac
}

# check if 'git' installed, and we have .git repo
finish_setup () {
    if [[ $(command -v git) ]]; then
        setup_updates_prompt
        cleanup_install
    else
        echo "git not found, disabling updates" 1>> "$log"
        disable_auto_updates
        finish_install_prompt
        cleanup_install
    fi
}

# simple finish function for homebrew setup
homebrew_finish () {
    installtype="homebrew"
    setinstallstatus
}

# install programs with homebrew
setup_homebrew () {
    clear
    echo ""
    version_banner
    echo ""
    echo $white" APK Manager will now perform the following to install the required programs:"
    echo ""
    declare -i count=1
    while [[ ${missing[$count]} ]]
    do
        if [[ ${missing[$count]} = pngout ]]; then
            if [[ ! $(brew tap | grep "adamv/alt") ]]; then
                echo $green" brew tap adamv/alt "$blue"(to install pngout)"
                btap="1"
            fi
            echo $green" brew install ${missing[$count]}"
        elif [[ ${missing[$count]} = android-sdk ]]; then
            needsdk="1"
            echo $green" brew install ${missing[$count]}"
        elif [[ ${missing[$count]} = sox ]]; then
            echo $green" brew install ${missing[$count]} "$blue"(opens a new terminal tab)"
            soxdeps="1"
            unset missing[$count]
            count=$((count-1))
        else
            echo $green" brew install ${missing[$count]}"
        fi
        count=$((count+1))
    done
    echo ""
    echo $white" Depending on the specific missing programs, this may take a while."
    echo $white" Please do not close terminal until everything finishes."
    if [[ $needsdk -ne 0 ]]; then
        echo ""
        echo $white" Homebrew is installing the android-sdk. After it finishes, it"
        echo $white" attempts to launch the Android SDK Manager. Please install"
        echo $white" the \"Android SDK Platform-tools\" and update and/or install"
        echo $white" any other components or SDK revisions you'd like. I suggest"
        echo $white" installing the SDK API's and Google API's for levels 10-15."
    fi
    if [[ $soxdeps -ne 0 ]]; then
        echo ""
        echo $white" APK Manager needs to install \"sox\" in order to be able to"; $rclr;
        echo $white" optimize .ogg files. However, installing sox will fail if run"; $rclr;
        echo $white" inside this script. Instead, APK Manager will open a new tab"; $rclr;
        echo $white" and run: "$bgreen"brew install sox; exit"; $rclr;
        echo $white" once the new tab closes, come back to this script and press enter.\n"; $rclr;
    fi
    echo $bgreen"$apkmspr"
    genericpanykey
    echo ""
    if [[ $btap -ne 0 ]]; then
        brew tap adamv/alt
        if [[ $? -ne 0 ]]; then
            brew_install_error
        else
            echo ""
            unset btap
        fi
    fi
    if [[ $soxdeps -ne 0 ]]; then
        local apkmopt="brew install sox; exit"
        newttab "$apkmopt" "$log"
        genericpanykey
        if [[ $? -ne 0 ]]; then
            brew_install_error
        else
            echo ""
            unset soxdeps
        fi
    fi
    if [[ $count -eq 1 ]]; then
        homebrew_finish
        finish_setup
    else
        brew install ${missing[*]}
        if [[ $? -ne 0 ]]; then
            brew_install_error
        else
            if [[ $needsdk -ne 0 ]]; then
                echo ""
                echo $bgreen" Launching the Android SDK Manager..."
                android
                unset needsdk
            fi
            homebrew_finish
            echo ""
            echo $bgreen"$apkmftr";
            genericpanykey
            finish_setup
        fi
    fi
}

# setup using precompiled/bundled programs
setup_bundled () {
    cd "${maindir}/other"
    clear
    echo ""
    version_banner
    echo ""
    echo $bgreen" Setting up APK Manager for pre-compiled programs..."
    echo ""
    echo $white" Checking for other/bundled_programs.tar.gz"
    echo ""
    if [[ ! -f "${maindir}/other/bundled_programs.tar.gz" ]]; then
        echo $green" Archive not found, downloading archive..."; $rclr;
        echo ""
        curl "http://dl.dropbox.com/u/9401664/APK%20Manager/bundled_programs.tar.gz" > "${maindir}/other/bundled_programs.tar.gz"
        echo ""
    fi
    local filehash="$(md5 -q ${maindir}/other/bundled_programs.tar.gz)"
    local expected="9780aeca7928aaba3e18cd89d29fbe31"
    if [[ ${filehash} = ${expected} ]]; then
        echo $bgreen" Extracting pre-compiled programs to:"
        echo $bgreen" ${maindir}/other"; $rclr;
        echo ""
        echo "Extracting pre-compiled programs..." 1>> "$log" 2>&1
        tar -xzvf "${maindir}/other/bundled_programs.tar.gz" 1>> "$log" 2>&1
        if [[ $? -ne 0 ]]; then
            bin_install_err
        else
            echo $bgreen" Removing temporary files..."
            echo "Removing temporary files." 1>> "$log" 2>&1
            rm -r "${maindir}/other/bundled_programs.tar.gz"
            echo ""
            echo $bgreen"$apkmftr";
            installtype="bundled"
            setinstallstatus
            genericpanykey
            finish_setup
        fi
    else
        echo $bred" ERROR: Corrupt download/file, md5 hash fail:"
        echo $bred" download: ${filehash}"
        echo $bred" expected: ${expected}"
        echo ""
        echo $white"press any key to try download again..."
        wait
        rm -r "${maindir}/other/bundled_programs.tar.gz"
        setup_bundled
    fi
}

# Installation complete message/prompt
finish_install_prompt () {
    echo ""
    echo $white"APK Manager did not find \"git\" on this sytem to enable"
    echo $white"automatic updates. If you install git and want to enable"
    echo $white"them at a later date, please see the debug/settings menu."; $rclr;
    echo ""
    echo $bgreen"APK Manager v3.0 setup complete!"
    echo $bgreen"$apkmftr";
    genericpanykey
}

# no missing programs, check for git, or finish
preconf_text () {
    echo $bgreen"$apkmspr"
    if [[ $(command -v brew) ]] && [[ $count -eq 0 ]]; then
        echo $white" APK Manager has detected that \"Homebrew\" is already setup on this system"; $rclr;
        echo $green" and found all programs necessary to function already installed!"; $rclr;
        installtype="homebrew"
    elif [[ ! $(command -v brew) ]] && [[ $count -eq 0 ]]; then
        echo $white" APK Manager has detected that Homebrew is not setup on this system."; $rclr;
        echo $green" However all programs necessary to function are already installed!"; $rclr;
        installtype="preconfigured"
    fi
    echo $bgreen"$apkmspr"
    if [[ $(command -v git) ]]; then
        setinstallstatus
        setup_updates_prompt
    else
        setinstallstatus
        disable_auto_updates
        finish_install_prompt
    fi
}

# can't/won't use homebrew message
no_brew_text () {
    echo $white" If you prefer not to use Homebrew (or for some reason you can't use Homebrew,"
    echo $blue" (ex. work computer, you don't want to install Xcode/command line tools, etc.)"
    echo $white" then APK Manager can use pre-compiled binaries for your architecture."
}

# use homebrew prompt/message
brew_text () {
    echo $bgreen"$apkmspr"
    echo $white" APK Manager has detected that Homebrew is already setup on this system"
    echo $bred" however it did not find all the required programs it needs to function."
    echo $white" Would you like to use homebrew to install the missing programs?"
    echo ""
    no_brew_text
    echo $bgreen"$apkmftr";
    printf "$white%s""Would you like to use Homebrew? ("$bgreen"y"$white"/"$bgreen"n"$white") "; $rclr;
    read input
    case "$input" in
     [yY])  setup_homebrew ;;
     [nN])  setup_bundled ;;
        *)  input_err; install ;;
    esac
}

# default install prompt/message
default_text () {
    echo $bgreen"$apkmspr"
    echo $bred" APK Manager has detected that Homebrew is not setup on this system."
    echo $white" If you would like to use Homebrew, please follow the instructions here:"
    echo ""
    echo $blue" https://github.com/mxcl/homebrew/wiki/installation"
    echo ""
    echo $bred" please be sure and run \"brew doctor\" and \"brew update\" after the "
    echo $bred" installation finishes, before running APK Manager again."
    echo ""
    no_brew_text
    echo $bgreen"$apkmftr";
    printf "$white%s""Would you like to use pre-compiled binaries? ("$bgreen"y"$white"/"$bgreen"n"$white") "; $rclr;
    read input
    case "$input" in
     [yY])  setup_bundled ;;
     [nN])  echo $bred"EXITING SETUP...\n"; $rclr; exit 1 ;;
        *)  input_err; install ;;
    esac
}

# main install skeleton function
install () {
    echo "install (setup/install APK Manager) function" 1>> "$log"
    clear
    echo ""
    version_banner
    echo ""
    echo $bwhite" Welcome to APK Manager for Mac OS X!"
    echo ""
    echo $bgreen" This installation script should only appear on first launch of v3.0+"
    echo ""
    echo $white" Version 3.0 adds an option to use "$bgreen"Homebrew"$white" ("$blue"http://mxcl.github.com/homebrew/"$white")"
    echo $white" to automatically install programs necessary for APK Manager to function."
    echo $white" Using Homebrew is highly recommended. It allows for cleaner installations,"
    echo $white" faster updates to required programs, and enables automatic updates"
    echo $white" to APK Manager using \"git\" and \"github.com\"."
    echo ""
    if [[ $count -eq 0 ]]; then
        preconf_text
    elif [[ $(command -v brew) ]] && [[ $count -ne 0 ]]; then
        brew_text
    else
        default_text
    fi
    echo "install function complete" 1>> "$log"
}

# missing android sdk programs sub function
and_sdk_sub () {
    if [[ $(command -v brew) ]]; then
        if [[ ! ${missing[$((count - 1))]} = "android-sdk" ]]; then
            p="android-sdk"
            missing[$count]="$p"
        fi
    else
        count=$((count-1))
        if [[ -z $err_shown ]]; then
            andsdk_error
        fi
    fi
}

# check for required programs
installcheck () {
    if [[ ! $(command -v java) ]]; then
        java_error
    elif [[ ! $(command -v sudo) ]]; then
        sudo_error
    else
        declare -i count=0
        for p in "optipng" "sox" "pngcrush" "pngout" "7za" "adb" "aapt" "zipalign"
        do
            if [[ ! $(command -v ${p}) ]]; then
                count=$((count+1))
                if [[ ${p} = adb ]] || [[ ${p} = aapt ]] || [[ ${p} = zipalign ]]; then
                    if [[ ${p} = aapt ]]; then
                        if [[ $(command -v android) ]] && [[ $(command -v brew) ]]; then
                            if [[ $(dirname "$(command -v android)") = /usr/local/bin ]]; then
                                local sdkrev="$(brew list -v android-sdk | sed s/android-sdk\ //g)"
                                ln -s "/usr/local/Cellar/android-sdk/${sdkrev}/platform-tools/aapt" "/usr/local/bin/aapt"
                                count=$((count-1))
                            fi
                        else
                            and_sdk_sub
                        fi
                    elif [[ ${p} = adb ]] || [[ ${p} = zipalign ]]; then
                        and_sdk_sub
                    fi
                elif [[ ${p} = pngout ]]; then
                    if [[ $(command -v brew) ]]; then
                        missing[$count]="${p}"
                    else
                        pngout_error
                    fi
                elif [[ ${p} = 7za ]]; then
                    p="p7zip"
                    missing[$count]="${p}"
                else
                    missing[$count]="${p}"
                fi
            fi
        done
    fi
    install
}

# Start
user_dir_check
installcheck
return 0
