#! /bin/sh
# -----------------------------------------------------------------------
# Apk Manager OS X v3.0+
# Debug information functions
#
# by Jocelyn Mallon CC by-nc-sa 2012
# http://girlintroverted.wordpress.com
#
# version: 3.0b
# Sat. May 19, 2012
# -----------------------------------------------------------------------

debug_cleanup () {
    unset p7zip_ver
    unset pngcrush_ver
    unset optipng_ver
    unset pngout_ver
    unset sox_ver
    unset smali_ver
    unset baksmali_ver
    unset adb_ver
    unset aapt_ver
    unset dex2jar_ver
    unset osx_ver
    unset osx_bld
}

# Toggle set -x/+x trace output
toggle_trace () {
    if [[ ${t_mode} -ne 0 ]]; then
        t_mode=0
        set +x
    elif [[ ${t_mode} -eq 0 ]]; then
        t_mode=1
        set -x
    fi
}

# Toggle set -v/+v verbose output
toggle_verbose () {
    if [[ ${v_mode} -ne 0 ]]; then
        v_mode=0
        set +v
    elif [[ ${v_mode} -eq 0 ]]; then
        v_mode=1
        set -v
    fi
}

# Toggle set -e/+e error checking
toggle_error () {
    if [[ ${e_mode} -ne 0 ]]; then
        e_mode=0
        set +e
    elif [[ ${e_mode} -eq 0 ]]; then
        e_mode=1
        set -e
    fi
}

# Toggle APK Manager symlink
apkm_tool_toggle () {
    if [[ $(echo ${PATH} | grep -m1 "/usr/local/bin") ]]; then
        if [[ $(command -v apkm) = "/usr/local/bin/apkm" ]]; then
            echo "deleting \"apkm\" symlink in /usr/local/bin" 1>> "$log"
            rm "/usr/local/bin/apkm"
        elif [[ ! $(command -v apkm) ]]; then
            echo "creating \"apkm\" symlink in /usr/local/bin" 1>> "$log"
            ln -s -F "${maindir}/other/main.sh" "/usr/local/bin/apkm"; chmod ug+x "/usr/local/bin/apkm"
        fi
    fi
}

# Actually download extra apktool versions
install_apktool () {
    if [[ ! -f "${maindir}/other/apktool_jar_files.tar.gz" ]]; then
        echo $green" Local copy of archive not found, downloading now..."; $rclr;
        echo ""
        curl "http://dl.dropbox.com/u/9401664/APK%20Manager/apktool_jar_files.tar.gz" > "${maindir}/other/apktool_jar_files.tar.gz"
        echo ""
    fi
    local filehash="$(md5 -q "${maindir}/other/apktool_jar_files.tar.gz")"
    local expected="5d19c1ad36c655dcfcf710af3492e068"
    if [[ ${filehash} = ${expected} ]]; then
        echo $white" Extracting extra apktool.jar files to:"
        echo $green" ${maindir}/other/apktool"; $rclr;
        echo ""
        cd "${maindir}/other"
        tar -xzvf "${maindir}/other/apktool_jar_files.tar.gz" 1>> "$log" 2>&1
        echo $green" Removing temporary files."
        rm -r "${maindir}/other/apktool_jar_files.tar.gz"
        echo $bgreen" Download complete!"
        echo ""
        echo $bgreen"$apkmftr";
        genericpanykey
        apktool_menu
    else
        echo $bred" ERROR: Corrupt download/file, md5 hash fail:"
        echo $bred" download: ${filehash}"
        echo $bred" expected: ${expected}"
        echo ""
        echo $white"press any key to try download again..."
        wait
        rm -r "${maindir}/other/apktool_jar_files.tar.gz"
        install_apktool
    fi
}

# Prompt to download extra apktool versions
apkt_prompt () {
    clear
    menu_header
    debug_header
    echo $bgreen"$apkmspr";
    echo ""
    echo $white" APK Manager has the ability to change the version of "$bgreen"apktool.jar"$white" used when decompiling"
    echo $white" and compiling android applications. However, to cut down on file size, only the most"
    echo $white" recent \"official\" release of apktool.jar ("$green"${apktool_ver}"$white") is included by default."
    echo ""
    echo $white" Would you like to download extra versions of apktool.jar file to use with APK Manager?"
    echo ""
    echo $bgreen"$apkmftr";
    printf "$white%s""Download extra apktool.jar versions? ("$bgreen"y"$white"/"$bgreen"n"$white") "; $rclr;
    read input
    case "$input" in
        [yY]) install_apktool ;;
        [nN]) ;;
           *) input_err; apkt_prompt ;;
    esac
    unset input
}

# Check for extra versions of apktool.jar
apkt_menu_check () {
    if [[ $( ls "${aptdir}" | wc -l) -gt 1 ]]; then
        apktool_menu
    elif [[ $( ls "${aptdir}" | wc -l) -eq 1 ]]; then
        apkt_prompt
    fi
}

# Open an adb shell
adb_shell () {
    if [[ $(command -v adb) ]]; then
        local apkmopt="adb kill-server; adb wait-for-device; adb shell; adb kill-server; exit"
        newttab "${apkmopt}" "$log"
    elif [[ ! $(command -v adb) ]]; then
        echo $bred"ERROR: adb not found on the system."
        debuganykey
    fi
}

# Launch ddms if it exists
launch_ddms () {
    if [[ $(command -v ddms) ]]; then
        local apkmopt="ddms; exit"
        newttab "${apkmopt}" "$log"
    elif [[ ! $(command -v ddms) ]]; then
        echo $bred"ERROR: ddms not found on the system."
        debuganykey
    fi
}

# Launch draw9patch if it exists
draw_nine () {
    if [[ $(command -v draw9patch) ]]; then
        local apkmopt="draw9patch; exit"
        newttab "${apkmopt}" "$log"
    elif [[ ! $(command -v draw9patch) ]]; then
        echo $bred"ERROR: draw9patch not found on the system."
        debuganykey
    fi
}

# Read adb logcat file if it exists
read_adb_log () {
    if [[ -e "${maindir}/ADBLOG.txt" ]]; then
        txt="${maindir}/ADBLOG.txt" 2>> "$log"
        read_txt
    else
        echo $bred"ERROR: no adblog.txt file found."
        debuganykey
    fi
}

# Create an adb logcat file
adblog () {
    echo "adblog (generate adb logcat txt file) function" 1>> "$log"
    clear
    menu_header
    echo $bgreen"----------------------------------------adblog.txt generator----------------------------------------" ; $rclr;
    echo ""
    echo $white" To generate an adb log file, this script will open a new terminal";
    echo $white" tab, run "$green"\"adb logcat\""$white" and save the output into a new file"
    echo $green" \"adblog.txt\" "$white"in the root apkmanager directory."
    echo ""
    echo $bred" This will first kill any existing adb instances, so please close"
    echo $bred" any adb shell sessions (or anything else) before continuing."
    echo ""
    echo $white" then it will re-start adb and wait for your device to be detected"
    echo ""
    echo $bred" if it \"hangs\" on starting adb, please unplug your device";
    echo $bred" and make sure \"usb debugging\" is enabled before reconnecting"
    echo $bred" your android device's usb cable."
    echo ""
    echo $white" it will then run adb logcat for ten seconds."
    echo ""
    echo $white" after ten seconds, it will kill the adb logcat process, close the"
    echo $white" new terminal tab, and again kill adb, before returning to the debug menu."
    echo ""
    echo $bgreen"$apkmftr"; $rclr;
    echo ""
    echo $bwhite"Press "$bgreen"Q"$bwhite" and enter to go back to debug menu, or press";
    printf "$bwhite%s""any other key to start adb log process... "; $rclr;
    read input
    if [[ $input = [qQ] ]]; then :
    else
        local adbopt="adb logcat 1> ${maindir}/ADBLOG.txt"
        local adbstart="starting adb logcat..."
        local apkmopt="adb kill-server; adb wait-for-device; echo "${adbstart}"; ${maindir}/other/bin/timeout 10 "${adbopt}"; adb kill-server; exit"
        newttab "${apkmopt}" "$log"
    fi
    echo "adblog function complete" 1>> "$log"
}

# Generate apktool version information
getapktver () {
    local key="apktool"
    local value="$(runj apktool | grep 'Apktool'| cut -d - -f1 | sed 's/^[ \t]*//;s/[ \t]*$//' | sed 's/\ /_/g')"
    write_preference
    apktool_ver="${value}"
}

# Generate SOX version information
getsoxver () {
    if [[ ${installtype} = homebrew ]]; then
        if [[ $(command -v sox) ]]; then
            value="$(brew list --versions sox | sed s/sox\ //g)"
        else
            value="ERROR_sox_not_found"
        fi
    else
        if [[ $(command -v sox) ]]; then
            value="$(sox --version | sed s/\ \ SoX\ //g |sed 's/^[ \t]*//;s/[ \t]*$//')"
        else
            value="ERROR_sox_not_found"
        fi
    fi
}

# Generate pngout version information
getpngoutver () {
    if [[ !  $(command -v pngout) ]]; then
        value="pngout_not_found"
    else
        value="$(pngout 2>&1 | grep -m1 'PNGOUT' | awk '{print $5"_"$6"_"$7}')"
    fi
}

# Generate dex2jar version information
getdex2jarver () {
    if [[ !  $(command -v dex2jar) ]]; then
        value="dex2jar_not_found"
    else
        value="$(dex2jar 2>/dev/null | grep 'version' | cut -d - -f2)"
    fi
}

# Generate debug/binary version information
getdebuginfo () {
    local p
    local key
    local value
    for p in "p7zip" "optipng" "pngcrush" "pngout" "sox" "smali" "baksmali" "adb" "aapt" "apktool" "dex2jar" "arch"
    do
        key="${p}"
        if [[ ${p} = p7zip ]]; then
            value="$(7za | grep '7-Zip..............' | cut -d C -f1 | sed 's/^[ \t]*//;s/[ \t]*$//' | sed 's/(//g' | sed 's/)//g'  | sed 's/\[//g' | sed 's/\]//g' | sed 's/\ /_/g')"
        elif [[ ${p} = optipng ]]; then
            value="$(optipng -v | grep 'OptiPNG version......' | sed s/OptiPNG\ version\ //g)"
        elif [[ ${p} = pngcrush ]]; then
            value="$(pngcrush -version | grep 'pngcrush.......' | sed s/pngcrush\ //g | cut -d , -f1)"
        elif [[ ${p} = pngout ]]; then
            getpngoutver
        elif [[ ${p} = sox ]]; then
            getsoxver
        elif [[ ${p} = smali ]]; then
            value="$(runj smali --version | grep 'smali' | sed s/smali\ //g | cut -d  ' ' -f1)"
        elif [[ ${p} = baksmali ]]; then
            value="$(runj baksmali --version | grep 'baksmali' | sed s/baksmali\ //g | cut -d  ' ' -f1)"
        elif [[ ${p} = adb ]]; then
            value="$(adb version | sed s/Android\ Debug\ Bridge\ version\ //g)"
        elif [[ ${p} = aapt ]]; then
            value="$(aapt v | cut -d , -f2 | sed 's/^[ \t]*//;s/[ \t]*$//')"
        elif [[ ${p} = dex2jar ]]; then
            getdex2jarver
        elif [[ ${p} = arch ]]; then
            value="$(uname -m)"
        fi
        if [[ -z ${value} ]]; then
            value="${p}_not_found"
        fi
        write_preference
        pv="${p}_ver"
        eval $pv=\${value}
    done
    getapktver
    key="debugset"
    value="true"
    write_preference
}

# Check for .debuginfo
debug_check () {
    osx_ver="$(sw_vers | awk '/ProductVersion/ {print $2}')"
    osx_bld="$(sw_vers | awk '/BuildVersion/ {print $2}')"
    debugset="$(defaults read "${plist}" debugset 2>/dev/null)"
    if [[ $? -ne 0 ]] || [[ ${debugset} -ne 1 ]] || [[ -z ${debugset} ]]; then
        getdebuginfo
        return 1
    fi
    arch_ver="$(defaults read "${plist}" arch 2>/dev/null)"
    if [[ $? -ne 0 ]] || [[ ! ${arch_ver} = "$(uname -m)" ]] || [[ -z ${arch_ver} ]]; then
        getdebuginfo
        return 1
    fi
    local p
    local v
    for p in "p7zip" "optipng" "pngcrush" "pngout" "sox" "smali" "baksmali" "adb" "aapt" "dex2jar" "apktool"
    do
        v="$(defaults read "${plist}" ${p} 2>/dev/null)"
        if [[ $? -ne 0 ]];then
            getdebuginfo
        else
            pv="${p}_ver"
            eval $pv=\${v}
        fi
    done
}

# Display debug/binary version information
debug_display () {
    cd "${maindir}"
    clear
    menu_header
    debug_header
    echo $bgreen"-----------------------------------Binary version info, path, etc-----------------------------------";
    echo $white" smali version: "$green"${smali_ver}"
    echo $white" baksmali version: "$green"${baksmali_ver}"
    echo $white" dex2jar version: "$green"${dex2jar_ver}"
    echo $white" dex2jar path: "$blue"$(command -v dex2jar)";
    echo $white" sox version: "$green"${sox_ver}"
    echo $white" sox path: "$blue"$(command -v sox)";
    echo $white" 7za version: "$green"${p7zip_ver}"
    echo $white" 7za path: "$blue"$(command -v 7za)";
    echo $white" optipng version: "$green"${optipng_ver}"
    echo $white" optipng path: "$blue"$(command -v optipng)";
    echo $white" pngcrush version: "$green"${pngcrush_ver}"
    echo $white" pngcrush path: "$blue"$(command -v pngcrush)";
    echo $white" pngout version: "$green"${pngout_ver}"
    echo $white" pngout path: "$blue"$(command -v pngout)";
    echo $white" adb version: "$green"${adb_ver}"
    echo $white" adb path: "$blue"$(command -v adb)";
    echo $white" aapt version: "$green"${aapt_ver}"
    echo $white" aapt path: "$blue"$(command -v aapt)";
    echo $white" zipalign path: "$blue"$(command -v zipalign)";
    echo $white" rm path: "$blue"$(command -v rm)";
    echo $bgreen"$apkmftr";
    printf "$bwhite%s""Press any key to return to debug menu... "; $rclr;
    wait
}
