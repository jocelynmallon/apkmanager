#! /bin/sh
# -----------------------------------------------------------------------
# Apk Manager OS X v3.0+
# Colors and graphics definition file
#
# by Jocelyn Mallon CC by-nc-sa 2012
# http://girlintroverted.wordpress.com
#
# version: 3.0b
# Wed. May 16, 2012
# -----------------------------------------------------------------------

# define colors for pretty output
red='\033[0;31m'
bred='\033[1;31m'
green='\033[0;32m'
bgreen='\033[1;32m'
blue='\033[0;34m'
bblue='\033[1;34m'
rclr='tput sgr0'

# set some graphical variables for easy pretty menus and logs
apkmspr="----------------------------------------------------------------------------------------------------"
apkmftr="****************************************************************************************************"
logspr2="**************************************************"
logspcr="--------------------------------------------------"

# version banner display function
version_banner () {
    local vernum
    local apkstring
    local title_len
    local title_fill
    vernum="$(awk '/# version:/ { print $3; exit}' "${maindir}/other/main.sh")"
    if [[ $(( ${#vernum} % 2)) -eq '0' ]]; then
        apkstring="APK Manager Mac OS X v${vernum}"
    else
        apkstring="APK Manager Mac OSX v${vernum}"
    fi
    title_len="${apkstring//[*]}"
    title_len="${#apkstring}"
    title_fill="$(printf "%*s" $(((98-${title_len})/2)))"
    echo $bgreen"${title_fill// /*}\c"
    echo " ${apkstring} \c"
    echo $bgreen"${title_fill// /*}"; $rclr;
}

# Main APK Manager header
menu_header () {
    echo ""
    version_banner
    echo $white" Compression-Level: "$bgreen"$uscr"$white"  |  Heap Size: "$bgreen"$heapy""mb"$white"  |  Project: "$bgreen"$capp"; $rclr;
    echo $bgreen"$apkmspr"; $rclr;
    if [[ $v_mode -ne 0 ]]; then
        printf "$bred%s"" VERBOSE MODE ENABLED (-v for entire script) "$white" | "
    fi
    if [[ $t_mode -ne 0 ]]; then
        printf "$bred%s"" TRACE MODE ENABLED (-x for entire script) "$white" | "
    fi
    if [[ $e_mode -ne 0 ]]; then
        printf "$bred%s"" -e"$white" |"
        local emode=5
    fi
    if [[ $debugstate -ne 0 ]]; then
        if [[ -z $emode ]]; then
            local emode=0
        fi
        local trunc_symbol="..."
        local pidw="$$"
        if [[ -z $errcode ]]; then
            errcode=0
            local err_string="${white}| \$?: ${bred}$errcode"
            local pwdfill=28
        else
            local err_string="${white}| ${bred}${errfunc} ${white}\$?: ${bred}$errcode ${white}line: ${bred}$errline"
            local pwdfill=36
        fi
        local maxlength="$((100 - (((((${#errfunc} + ${#errcode}) + ${#errline}) + ${#pidw}) + $emode ) + $pwdfill )))"
        if [[ ${#PWD} -gt $maxlength ]]; then
            local pwdoffset="$(( ${#PWD} - $((maxlength - ${#trunc_symbol})) ))"
            local newpwd="${trunc_symbol}${PWD:$pwdoffset:$maxlength}"
        else
            newpwd="$(pwd)"
        fi
        printf "$white%s"" PID: "$bred"$$"$white" ${err_string}"$white" | Last 'cd': "$bred"${newpwd}\n"; $rclr;
        unset errcode
        unset errline
        unset errfunc
    else
        echo ""
    fi
}

# Debug/settings menu sub-header
debug_header () {
    echo $bgreen"------------------------------------Debug Info and Misc Settings------------------------------------";
    echo $white" Current System: "$green"Mac OS X $osx_ver $osx_bld $arch_ver";
    echo $white" APK Manager install type: "$green"$installtype";
    echo $white" APK Manager root dir: "$green"$maindir";
    echo $white" ANDROID_SDK_ROOT: "$green"$ANDROID_SDK_ROOT";
    echo $white" Current log viewer: "$green"$logapp";
    echo $white" Current \"png\" tool: "$green"$pngtool";
    echo $white" Current APKtool: "$green"$apktool_ver"$blue" ($(basename "$(readlink "$libdir/apktool.jar")"))";
}

# automatic updates menu header
updates_header () {
    echo $bgreen"-------------------------------------Automatic Updates Settings-------------------------------------";
    local updatestate="$(defaults read "${plist}" updates 2>/dev/null)"
    if [[ $? -ne 0 ]]; then
        updatestate=0
        local key="updates"
        local value="false"
        write_preference
    fi
    if [[ $updatestate -eq 1 ]]; then
        update_branch_check
        local commit
        commit="$(get_commit_ver)"
        commit="${commit:0:8}"
        update_prompt_state
        if [[ $upromptstate -eq 1 ]]; then
            local uprompt="${green}ON"
        else
            local uprompt="${bred}OFF"
        fi
        build_last_date_time
        check_update_freq
        if [[ $ufreq -eq 1 ]]; then
            local updfreq="${ufreq} ${white}day"
        elif [[ $ufreq -gt 1 ]]; then
            local updfreq="${ufreq} ${white}days"
        fi
        echo $white" Updates status: "$green"ON"; $rclr;
        echo $white" Updates prompt: $uprompt"; $rclr;
        echo $white" Current branch: "$green"${saved_channel}"; $rclr;
        echo $white" Current commit: "$green"${commit}"; $rclr;
        echo $white" Update frequency: "$green"${updfreq}"; $rclr;
        echo $white" Last update check: "$green"${last_check}"; $rclr;
    else
        echo $white" Updates status: "$bred"OFF"; $rclr;
    fi
}
