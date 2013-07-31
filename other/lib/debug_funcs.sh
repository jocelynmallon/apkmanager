#! /bin/sh
# -----------------------------------------------------------------------
# Apk Manager OS X v3.0+
# Debug information functions
#
# by Jocelyn Mallon CC by-nc-sa 2012
# http://girlintroverted.wordpress.com
#
# version: 3.1b
# Wed. Jul 31, 2013
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

# Toggle killing ADB daemon on APKM quit
toggle_adb_kill_on_quit () {
    local key="adbkillonquit"
    if [[ ${adb_kill} -ne 0 ]]; then
        adb_kill=0
        local value="false"
    elif [[ ${adb_kill} -eq 0 ]]; then
        adb_kill=1
        local value="true"
    fi
    write_preference
}

# generate system memory information
gen_system_memory_info () {
    local free_blocks=$(vm_stat | grep free | awk '{ print $3 }' | sed 's/\.//')
    local inactive_blocks=$(vm_stat | grep inactive | awk '{ print $3 }' | sed 's/\.//')
    local speculative_blocks=$(vm_stat | grep speculative | awk '{ print $3 }' | sed 's/\.//')
    local active_blocks=$(vm_stat | grep -m1 active | awk '{ print $3 }' | sed 's/\.//')
    local wired_blocks=$(vm_stat | grep wired | awk '{ print $4 }' | sed 's/\.//')
    local reactive_blocks=$(vm_stat | grep -m1 reactivated | awk '{ print $3 }' | sed 's/\.//')
    local active=$(($active_blocks*4096/1048576))
    local reactive=$(($reactive_blocks*4096/1048576))
    local wired=$(($wired_blocks*4096/1048576))
    local free=$((($free_blocks+speculative_blocks)*4096/1048576))
    local inactive=$(($inactive_blocks*4096/1048576))
    totalfree=$((($free+$inactive)))
    totalactive=$((($wired+$active+reactive)))
    sysmem=$((($free+$inactive+$active+$wired+$reactive)))
}

# Format and view git commit log
view_git_log () {
    clear
    menu_header
    debug_header
    echo $bgreen"$apkmspr"; $rclr;
    echo $white"Viewing last "$bgreen"15"$white" commits/changes made to APK Manager..."
    echo ""
    echo "$(git log --pretty=format:"%Cred%h%Creset | %Cgreen%ad%Creset | %s" --date=short --max-count=15)"
    echo ""
    echo $bgreen"$apkmftr";
    echo $white"press "$bgreen"G"$white" to open commit history on github.com"; $rclr;
    echo $white"press "$bgreen"W"$white" to view the wiki changelog on github.com"; $rclr;
    echo $white"press "$bgreen"Q"$white" to return to debug menu"; $rclr;
    printf "$bwhite%s""Please select an option from above: "; $rclr;
    read input
    case "$input" in
     [gG])  view_github_commits ;;
     [wW])  view_github_wiki ;;
     [qQ])  ;;
        *)  input_err; view_git_log ;;
    esac
    unset input
}

# Open the github wiki changelog page
view_github_wiki () {
    open https://github.com/jocelynmallon/apkmanager/wiki/Changelog
}

# Open the github commit history page
view_github_commits () {
    open https://github.com/jocelynmallon/apkmanager/commits/master/
}

# View changelog/git-log
view_changelog () {
    if [[ $(command -v git) ]] && [[ -d "${maindir}/.git" ]]; then
        view_git_log
    else
        view_github_wiki
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
        curl "https://dl.dropboxusercontent.com/u/9401664/APK%20Manager/apktool_jar_files.tar.gz" > "${maindir}/other/apktool_jar_files.tar.gz"
        echo ""
    fi
    local filehash="$(md5 -q "${maindir}/other/apktool_jar_files.tar.gz")"
    local expected="d1e4fee31e403bc63457e12731b25db6"
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

# Launch ddms if it exists
launch_ddms () {
    if [[ $(command -v monitor) ]]; then
        local apkmopt="monitor; exit"
        newttab "${apkmopt}" "$log"
    elif [[ ! $(command -v monitor) ]]; then
        echo $bred"ERROR: Android Device Monitor not found on the system."
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
            value="$(pngcrush -version 2>&1 | grep 'pngcrush' | sed s/pngcrush\ //g | cut -d , -f1)"
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
