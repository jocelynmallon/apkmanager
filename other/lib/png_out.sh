#! /bin/sh
# -----------------------------------------------------------------------
# Apk Manager OS X v3.0+
# Pngout check and install functions
#
# by Jocelyn Mallon CC by-nc-sa 2012
# http://girlintroverted.wordpress.com
#
# version: 3.0.2
# Wed. May 22, 2013
# -----------------------------------------------------------------------

# static url for latest version of pngout for mac
pngouturl="http://static.jonof.id.au/dl/kenutils/pngout-20130221-darwin.tar.gz"
pngoutmd5="2f35b7369d5ab668cea414772de6fba9"

# setup name of downloaded folder
set_pngout_fld () {
    pngoutfld="${pngouturl##*/}"
    pngoutfld="${pngoutfld%%.*}"
}

# Check if pngout install succeeded
inst_pngo_check () {
    if [[ $(command -v pngout) ]]; then
        echo $bgreen"pngout installed succesfully!"
        echo ""
        echo $bgreen"$apkmftr";
        local key="pngtool"
        local value="pngout"
        write_preference
        getpngoutver
        local key="pngout"
        write_preference
        pngtoolset
        debuganykey
        unset key
        unset value
    else
        echo $bred"Something went wrong installing pngout"
        echo $bred"Please check the log and try again."; $rclr;
        debuganykey
    fi
    unset pngouturl
    unset pngoutfld
    unset pngoutmd5
}

# Actually install pngout
install_pngout () {
    echo "install_pngout (download and install pngout) function" 1>> "$log"
    set_pngout_fld
    clear
    menu_header
    echo $bgreen"$apkmspr"; $rclr;
    echo ""
#    if [[ ${installtype} = homebrew ]]; then
    if [[ ${installtype} = disabled ]]; then
        if [[ ${BTAP} -eq 1 ]]; then
            brew tap adamv/alt
            unset BTAP
            echo ""
        fi
        brew install pngout
        echo ""
        inst_pngo_check
    else
        echo $bgreen"Downloading pngout..."; $rclr;
        curl "${pngouturl}" > "${maindir}/other/pngout.tar.gz"
        local filehash="$(md5 -q "${maindir}/other/pngout.tar.gz")"
        if [[ ${filehash} = ${pngoutmd5} ]]; then
            echo $green"Extracting pngout..."; $rclr;
            tar -xzvf "${maindir}/other/pngout.tar.gz" 1>> "$log" 2>&1
            cp -p "${maindir}/${pngoutfld}/pngout" "${maindir}/other/bin/pngout"
            echo $green"cleaning up temporary files..."; $rclr;
            rm -rf "${maindir}/other/pngout.tar.gz"
            rm -rf "${maindir}/${pngoutfld}"
            inst_pngo_check
        else
            echo $bred" ERROR: Corrupt download/file, md5 hash fail:"
            echo $bred" download: ${filehash}"
            echo $bred" expected: ${pngoutmd5}"
            echo ""
            echo $white"press any key to try download again..."
            wait
            rm -r "${maindir}/other/pngout.tar.gz"
            install_pngout
        fi
    fi
    echo "install_pngout function complete" 1>> "$log"
}

# Prompt to install pngout
pngout_prompt () {
    clear
    menu_header
    echo $bgreen"$apkmspr";
    echo ""
    echo $bred" A pngout binary was not found on your system. "$white"Unfortunately, pngout is not open"
    echo $white" source software, and is "$bgreen" (c) Ken Silverman http://advsys.net/ken/utils.htm"
    echo $white" Due to copyright, pngout can't legally be redistributed with APK Manager."
    echo ""
#    if [[ ${installtype} = homebrew ]]; then
    if [[ ${installtype} = disabled ]]; then
        echo $white" However, APK Manager can install pngout using Homebrew,"
        echo $white" thanks to the alt formula here: "$blue"https://github.com/adamv/homebrew-alt"
        echo $white" this will execute the following commands:"
        echo ""
        if [[ ! $(brew tap | grep "adamv/alt") ]]; then
            echo $bgreen" brew tap adamv/alt"
            BTAP="1"
        fi
        echo $bgreen" brew install pngout"
    else
        echo $white" However, APK Manager can download the latest pre-compiled mac binary "
        echo $white" from the official mac download page here:"
        echo ""
        echo $bgreen" ${pngouturl}"
        echo ""
        echo $white" and copy/install it automatically into the apkmanager/other/bin folder for you."
    fi
    echo ""
    echo $bgreen"$apkmftr";
    printf "$white%s""Do you want to download/install pngout? ("$bgreen"y"$white"/"$bgreen"n"$white") "; $rclr;
    read input
    case "$input" in
        [yY]) install_pngout ;;
        [nN]) ;;
           *) input_err; pngout_check ;;
    esac
    unset input
}

# Check if pngout exists and is in $PATH
pngout_check () {
    echo "pngout_check (checking if pngout is installed)" 1>> "$log"
    if [[ $(command -v pngout) ]]; then
        local key="pngtool"
        local value="pngout"
        write_preference
        pngtoolset
    else
        pngout_prompt
    fi
}
