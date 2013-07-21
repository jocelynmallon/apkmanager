#! /bin/sh
# -----------------------------------------------------------------------
# Apk Manager OS X v3.0+
# Main program script
#
# by Jocelyn Mallon CC by-nc-sa 2012
# http://girlintroverted.wordpress.com
#
# version: 3.1b
# Sun. Jul 21, 2013
# -----------------------------------------------------------------------

# define default directories to function
mod_dir="place-here-for-modding"
prj_dir="projects"
sig_dir="place-here-for-signing"
bat_dir="place-here-to-batch-optimize"
ogg_dir="place-ogg-here"

# Wait/pause command
wait () {
    read -n 1 -s
}

# Write user preferences to .plist
write_preference () {
    if [[ ${value} = true ]] || [[ ${value} = false ]]; then
        local bflag="-b"
    fi
    preftool "${bflag}" "${plist}" "${key}" "${value}"
}

# simple date formatting function
gen_date () {
    echo "$(date +"%T %Z") - $(date +"%b. %d, %Y")\c"
}

# Check if we're killing adb on quit
gen_adb_kill_status () {
    if [[ -z ${adb_kill} ]]; then
        adb_kill="$(defaults read "${plist}" adbkillonquit 2>/dev/null)"
        if [[ $? -ne 0 ]]; then
            adb_kill=0
        fi
    fi
}

# Quit APk Manager and exit clean
quit () {
    if [[ ${adb_kill} = 1 ]]; then
        adb kill-server
    fi
    clear
    echo "quit (quit APK Manager and exit clean) function" 1>> "$log" 2>&1
    echo "SESSION END: $(gen_date)" 1>> "$log" 2>&1
    echo "$apkmftr" 1>> "$log" 2>&1
    exit 0
}

# Startup fatal error message
startup_fatal_err () {
    echo $bred"ERROR, APK MANAGER IS EITHER NOT RUNNING IN";
    echo $bred"ROOT \"apkmanager\" DIRECTORY, OR ONE OR";
    echo $bred"MORE REQUIRED files WERE NOT FOUND.";
    printf "$bred%s""PRESS ANY KEY TO EXIT..."; $rclr;
}

# In-depth startup necessary file check
sourced_files_check () {
    files=( "${bindir}/rm" "${bindir}/runj" "${bindir}/newttab" "${bindir}/preftool" "${bindir}/timeout3" "${bindir}/JD-GUI.app" "${aptdir}/apktool_143.jar" )
    files+=( $(awk '/source\ / { print $0}' "${maindir}/other/main.sh" | sed 's/^[ \t]*//;s/[ \t]*$//' | sed 's/source\ //g' | sed 's/\"//g' | sed "s,\$libdir,${libdir},g") )
    local i
    for ((i=0; i < ${#files[*]}; i++)); do
        if [[ ! ${files[$i]} ]]; then
            local fatal_err="$((fatal_err + 1))"
            echo "not found: ${files[$i]}"
            echo "fatal_err: $fatal_err"
        fi
    done
    if [[ ${fatal_err} -ne 0 ]]; then
        startup_fatal_err
        local key="maindir"
        local value="ERROR"
        defaults write "${plist}" "${key}" "${value}"
        wait
        exit 1
    else
        local key="maindir"
        local value="${maindir}"
        defaults write "${plist}" "${key}" "${value}"
    fi
    unset files
}

# Determine where we are and set full maindir parth
maindir_setup () {
    local prog="$0"
    local newprog
    while [ -h "${prog}" ]; do
        newProg="$(/bin/ls -ld "${prog}")"
        newProg="$(expr "${newProg}" : ".* -> \(.*\)$")"
        if expr "x${newProg}" : 'x/' >/dev/null; then
            prog="${newProg}"
        else
            progdir="$(dirname "${prog}")"
            prog="${progdir}/${newProg}"
        fi
    done
    local oldwd="$(pwd)"
    local progdir="$(dirname "${prog}")"
    cd "${progdir}"
    maindir="$(dirname "$(pwd)")"
}

# Setup root 'apkmanager' directory path
maindir_check () {
    maindir="$(defaults read "${plist}" maindir 2>/dev/null)"
    if [[ $? -ne 0 ]]; then
        maindir_setup
    else
        cd "${maindir}" &>/dev/null
        if [[ $? -ne 0 ]]; then
            maindir_setup
        fi
    fi
}


# Check for directories necessary to function
dircheck () {
    maindir_check
    if [[ ! ${maindir} = "$(pwd)" ]]; then
        cd "${maindir}"
    fi
    bindir="${maindir}/other/bin"
    libdir="${maindir}/other/lib"
    aptdir="${maindir}/other/apktool"
    d2jdir="${maindir}/other/dex2jar"
    if [[ ! -d "${bindir}" ]] || [[ ! -d "${libdir}" ]] || [[ ! -d "${aptdir}" ]]; then
        echo "${maindir}"
        echo "$(pwd)"
        startup_fatal_err
        wait
        exit 1
    else
        sourced_files_check
    fi
}

# Check for and/or create working directories
folderscheck () {
    echo "folderscheck (check for/create modding, projects, etc. folders)" 1>> "$log" 2>&1
    local dir
    for dir in "${prj_dir}" "${mod_dir}" "${ogg_dir}" "${bat_dir}" "${sig_dir}"
    do
        if [[ ! -d ${maindir}/${dir} ]]; then
            mkdir -p "${maindir}/${dir}"
        fi
    done
}

# Check for required programs
startup_check () {
    echo "startup_check (checking for necessary binaries to run)" 1>> "$log" 2>&1
    local prg
    for prg in "optipng" "pngcrush" "pngout" "7za" "java" "sudo" "adb" "aapt" "sox" "zipalign"
    do
        if [[ ! $(command -v ${prg}) ]]; then
            if [[ ${prg} = sox ]]; then
                oggopts="disabled"
                echo "program \"sox\" is missing, ogg functionality disabled" 1>> "$log" 2>&1
            elif [[ ${prg} = optipng ]] || [[ ${prg} = pngcrush ]] || [[ ${prg} = pngout ]]; then
                local pngerror
                pngerror=$(($pngerror+1))
                if [[ ${pngerror} -ge 3 ]]; then
                    pngopts="disabled"
                    echo "\"optipng\", \"pngcrush\" & \"pngout\" missing; png options disabled" 1>> "$log" 2>&1
                fi
            elif [[ ${prg} = aapt ]]; then
                if [[ $(command -v brew) ]] && [[ $(dirname "$(command -v android)") = /usr/local/bin ]]; then
                    local sdkrev="$(brew list --versions android-sdk | sed s/android-sdk\ //g)"
                    ln -s "/usr/local/Cellar/android-sdk/${sdkrev}/platform-tools/aapt" /usr/local/bin/aapt
                fi
            else
                local fatal_err
                fatal_err=$(($fatal_err+1))
                echo "The program ${prg} is missing or is not in your"
                echo "\$PATH, please install it or fix your \$PATH."
                echo "${prg} is missing or not in PATH" 1>> "$log" 2>&1
            fi
        fi
    done
    if [[ ${fatal_err} -ne 0 ]]; then
        exit 1
    fi
}

# Check for ANDROID_SDK_ROOT
and_sdk_check () {
    if [[ -z $ANDROID_SDK_ROOT ]]; then
        if [[ $(command -v brew) ]]; then
            if [[ $(dirname "$(command -v android)") = /usr/local/bin ]]; then
                local sdkrev="$(brew list --versions android-sdk | sed s/android-sdk\ //g)"
                export "ANDROID_SDK_ROOT=/usr/local/Cellar/android-sdk/${sdkrev}"
            fi
        else
            defaults read "${plist}" "and_sdk_err" &>/dev/null
            if [[ $? -ne 0 ]]; then
                android_sdk_root_err
                local key="and_sdk_err"
                local value="true"
                write_preference
            fi
        fi
    fi
}

# Test CPU architecture
archtest () {
    if [[ -z ${arch_ver} ]]; then
        arch_ver="$(uname -m)"
        if [[ ${arch_ver} = "Power Macintosh" ]]; then
            echo $bred"SORRY, APK Manager has not been tested on Power PC";
            printf "$bred%s""Macintosh Computers, Press any key to exit."; $rclr;
            wait
            exit 1
        elif [[ ${installtype} = homebrew ]]; then
            echo "archtest (running on ${arch_ver} machine)" 1>> "$log" 2>&1
            return 0
        elif [[ ${installtype} = preconfigured ]]; then
            echo "archtest (running on ${arch_ver} machine)" 1>> "$log" 2>&1
            return 0
        elif [[ ${arch_ver} = "x86_64" ]]; then
            cd "${bindir}"
            local f
            ls 64_* | while read f
            do
                ln -s -F "${f}" "${f:3}" 1>> "$log" 2>&1
            done
        else
            cd "${bindir}"
            local f
            ls 32_* | while read f
            do
                ln -s -F "${f}" "${f:3}" 1>> "$log" 2>&1
            done
        fi
    fi
    echo "archtest (running on ${arch_ver} machine)" 1>> "$log" 2>&1
    echo "==> Linking correct binaries in ./other" 1>> "$log" 2>&1
    cd "${maindir}"
}

# Check for existing user color choice
colorcheck () {
    echo "colorsetup (set apk manager color theme)" 1>> "$log" 2>&1
    colorchoice="$(defaults read "${plist}" color 2>/dev/null)"
    if [[ $? -ne 0 ]]; then
        echo "color setup undefined, launching colorcheck..." 1>> "$log" 2>&1
        source "${libdir}/colorsetup.sh"
    elif [[ $colorchoice = alternate ]]; then
        white='\033[0;30m'
        bwhite='\033[1;30m'
    else
        white='\033[0;37m'
        bwhite='\033[1;37m'
    fi
}

# Check for existing user settings directory
user_dir_check () {
    if [[ ! -d "${HOME}/.apkmanager" ]]; then
        mkdir -p "${HOME}/.apkmanager"
    fi
}

# Check status of v3.0+ installation/setup
installcheck () {
    echo "installcheck (check v3.0+ installation status)" 1>> "$log"
    installtype="$(defaults read "${plist}" install 2>/dev/null)"
    if [[ $? -ne 0 ]]; then
        user_dir_check
        echo "launching installation script..." 1>> "$log"
        source "${libdir}/install.sh"
        if [[ $? -ne 0 ]]; then
            echo $bred"ERROR: APK Manager installation failed"
            echo $bred"Please check log for details, and try again."
            printf "$bred%s""PRESS ANY KEY TO EXIT..."; $rclr;
            wait
            exit 1
        fi
    else
        echo "APK Manager install type: $installtype" 1>> "$log"
    fi
}

# Check status of v2.1+/v3.0+ migration
migratecheck () {
    echo "migratecheck (check user settings & keys migration status)" 1>> "$log"
        migratecheck="$(defaults read "${plist}" migration 2>/dev/null)"
        if [[ $? -ne 0 ]] || [[ ${migratecheck} -ne 1 ]]; then
            echo "launching migration script..." 1>> "$log"
            source "${libdir}/migrate.sh"
            if [[ $? -ne 0 ]]; then
                echo $bred"ERROR: APK Manager v3.0+ migration failed."
                echo $bred"Please check log for details, and try again."
                printf "$bred%s""PRESS ANY KEY TO EXIT..."; $rclr;
                wait
                exit 1
            fi
        else
            echo "Already using v3.0+ settings plist" 1>> "$log"
        fi
}

# Check if automatic updates enabled
auto_update_check () {
    local updatestate="$(defaults read "${plist}" updates 2>/dev/null)"
    if [[ $? -ne 0 ]]; then
        disable_auto_updates
        echo "Automatic updates: OFF" 1>> "$log"
    elif [[ ${updatestate} -eq 0 ]]; then
        echo "Automatic updates: OFF" 1>> "$log"
    elif [[ ${updatestate} -eq 1 ]]; then
        if [[ ! $(command -v git) ]]; then
            updates_git_err
            return 1
        else
            echo "Automatic updates: ON, running update check" 1>> "$log"
            updates_status
        fi
    fi
}

# Check for apktool.jar symlink
apktcheck () {
    echo "apktcheck (checking for apktool.jar symlink)" 1>> "$log" 2>&1
    if [[ ! -e $(readlink "${libdir}/apktool.jar") ]]; then
        rm "${libdir}/apktool.jar"
    fi
    if [[ ! -L "${libdir}/apktool.jar" ]]; then
        local jarfile
        jarfile="$(ls "${aptdir}" | sed -n "/apktool_...\.jar/h;$ {x;p;}")"
        echo "No apktool.jar symlink found in ${libdir}" 1>> "$log" 2>&1
        echo "==> Linking ${jarfile} > apktool.jar" 1>> "$log" 2>&1
        ln -s -f -F "${aptdir}/${jarfile}" "${libdir}/apktool.jar"
        getapktver
    fi
}

# Write current PID to plist
set_current_pid () {
    local key="pid"
    local value="$$"
    write_preference
}

# Toggle utterly basic debug info in menu_header
basic_debug () {
    debugstate="$(defaults read "${plist}" debug 2>/dev/null)"
    if [[ $? -ne 0 ]] || [[ ${debugstate} -eq 0 ]]; then
        local key="debug"
        local value="true"
        write_preference
        debugstate=1
    else
        local key="debug"
        local value="false"
        write_preference
        debugstate=0
    fi
}

# Check for persistent java heap setting
jvheapck () {
    heapy="$(defaults read "${plist}" heap 2>/dev/null)"
    if [[ $? -ne 0 ]]; then
        heapy=64
    fi
    echo "Jave Heap Size set to: ${heapy}mb" 1>> "$log" 2>&1
}

# Check for persistent compression level
complvlck () {
    uscr="$(defaults read "${plist}" complvl 2>/dev/null)"
    if [[ $? -ne 0 ]]; then
        uscr=9
    fi
    echo "7zip Compression Level set to: $uscr" 1>> "$log" 2>&1
}

# Initialize the log
logstart () {
    echo "$apkmftr" 1>> "$log" 2>&1
    echo "SESSION START: $(gen_date)" 1>> "$log" 2>&1
    echo "$logspcr" 1>> "$log" 2>&1
}

# Reset logviewing app to Apple Textedit
logvreset () {
    if [[ ${logapp} ]]; then
        echo "${logapp} command line support not found" 1>> "$log" 2>&1
        echo "reverting to default, Apple TextEdit" 1>> "$log" 2>&1
    else
        echo "log viewing app set to: ${logapp}" 1>> "$log" 2>&1
    fi
    local key="logviewapp"
    local value="open"
    write_preference
    logviewer="open"
    logapp="Apple TextEdit"
}

# Check for logviewing app command line support
logvset () {
    logapp="$(grep "|${logviewer}" "${libdir}/logapps" | cut -d\| -f1)"
    if [[ ! $(command -v ${logviewer})  ]]; then
        logvreset
    else
        local key="logviewapp"
        local value="${logviewer}"
        write_preference
        echo "log viewing app set to: ${logapp}" 1>> "$log" 2>&1
    fi
}

# Check for user logviewing app preference
logvchk () {
    if [[ -z ${logviewer} ]]; then
        logviewer="$(defaults read "${plist}" logviewapp 2>/dev/null)"
        if [[ $? -ne 0 ]]; then
            logvreset
        fi
    fi
    logvset
}

defpngtool () {
    pngtool="optipng"
    local key="pngtool"
    local value="optipng"
    write_preference
}

# Set png optimization tool
pngtoolset () {
    if [[ ${pngopts} = disabled ]]; then
        pngtool="NONE - DISABLED"
    else
        pngtool="$(defaults read "${plist}" pngtool 2>/dev/null)"
        if [[ $? -ne 0 ]] || [[ ! $(command -v ${pngtool}) ]]; then
            defpngtool
        fi
    fi
    echo "png optimization tool set to: ${pngtool}" 1>> "$log" 2>&1
}

# Check for files in modding directory
project_test () {
    echo "project_test (checking number of project files in modding folder)" 1>> "$log"
    local prjnum="$(ls "${maindir}/${mod_dir}" | wc -l)"
    if [[ ${prjnum} -gt 1 ]]; then
        echo "==>${prjnum} project files found in modding folder" 1>> "$log"
        capp="None"
        prjext=""
    elif [[ ${prjnum} -eq 0 ]]; then
        echo "modding folder is empty" 1>> "$log"
        capp="None"
        prjext=""
    else
        cd "${maindir}/${mod_dir}"
        local apptmp=$(find . -type f \( -iname "*.apk" -o -iname "*.jar" \))
        capp="$(basename "${apptmp}")"
        prjext="${capp##*.}"
        echo "$logspr2" 1>> "$log" 2>&1
        echo "Only one project file in modding folder..." 1>> "$log"
        echo "==> Selected Project file: ${capp}" 1>> "$log" 2>&1
        echo "==> Selected Project is an ${prjext} file" 1>> "$log" 2>&1
        echo "$logspr2" 1>> "$log" 2>&1
        cd "${maindir}"
    fi
}

# test if no project currently selected
capp_test () {
    if [[ ${capp} = None ]] || [[ -z ${capp} ]]; then
        echo $bred"Warning, no project currently selected";
        echo "no project selected, launching projects menu" 1>> "$log" 2>&1
        echo $bred"press any key to launch project select menu"; $rclr;
        wait
        projects_menu
    fi
}

# Set max java heap size
heap_size () {
    clear
    gen_system_memory_info
    menu_header
    echo $bgreen"----------------------------------------Set Java Heap Memory----------------------------------------"
    echo ""
    echo $white" For stability and reliability, it is best that this value is large"
    echo $white" enough to prevent Java from crashing (e.g. at least ~256MB)"
    echo $white" but for best performance, this should be smaller than"
    echo $white" your average free memory, to prevent VM/paging to disk."
    echo ""
    echo $bgreen" APK Manager will not allow you to set heap sizes larger than"
    echo $bgreen" total system memory, or smaller than 64MB."
    echo ""
    echo $bblue" Current system memory usage: "
    echo $white"   "$green"Active: "$bred"${totalactive}"$red" MB";
    echo $white"   "$green"Free:   "$bred"${totalfree}"$red" MB";
    echo $white"   "$green"Total:  "$bred"${sysmem}"$red" MB";
    echo ""
    echo $bgreen"$apkmftr";
    echo $bwhite"Press "$bgreen"Q"$bwhite" and enter to go back to main menu.";
    printf "$white%s""Enter max size for java heap memory in megabytes ("$bgreen"eg 512"$white"): "; $rclr;
    read input
    if [[ $input = [qQ] ]]; then :
    elif [[ ! ${input} =~ ^[0-9]+$ ]]; then
        echo $bred"Error: ${input} is not a number, press any key to try again"; $rclr;
        wait
        heap_size
    elif [[ ${input} -lt 64 ]]; then
        echo $bred"Error: ${input} is less than 64MB, press any key to try again"; $rclr;
        wait
        heap_size
    elif [[ ${input} -ge ${sysmem} ]]; then
        echo $bred"Error: ${input} is greater than total system memory, press any key to try again"; $rclr;
        wait
        heap_size
    else
        heapy="${input}"
        if [[ $(defaults read "${plist}" heap 2>/dev/null) ]]; then
            local key="heap"
            local value="${input}"
            write_preference
        fi
        echo "==> Jave Heap Size set to: ${heapy}" 1>> "$log" 2>&1
    fi
    unset input
    unset totalfree
    unset totalactive
    unset sysmem
}

# Set compression level
comp_level () {
    clear
    menu_header
    echo $bgreen"---------------------------------Set level for zip/compress options---------------------------------"
    echo ""
    echo $white" Basic information on most common options:"
    echo ""
    echo $bgreen"  0  "$white"Don't compress at all - Is called \"copy\" mode."
    echo $bgreen"  1  "$white"Very low compression - Is called \"fastest\" mode."
    echo $bgreen"  3  "$white"Fast compression - Will set various parameters automatically."
    echo $bgreen"  5  "$white"Same as above, but \"normal\" compression"
    echo $bgreen"  7  "$white"Same as above, but \"maximum\" compression"
    echo $bgreen"  9  "$white"Same as above, but \"ultra\" compression"
    echo ""
    echo $green" Please note that some applications expect their resources to be uncompressed."
    echo $green" If your modified application is \"SIGNIFICANTLY\" smaller than the original,"
    echo $green" then it was probably not compressed originally. Normally this won't cause any"
    echo $green" problems, but if you do have problems, please try again using a lower level."
    echo ""
    echo $bgreen"$apkmftr";
    echo $bwhite"Press "$bgreen"Q"$bwhite" and enter to go back to main menu.";
    printf "$white%s""Enter Maximum Compression Level ("$bgreen"0-9"$white"): "; $rclr;
    read input
    if [[ $input = [qQ] ]]; then :
    elif [[ ! ${input} =~ ^[0-9]$ ]]; then
        echo $bred"Error: ${input} is not a valid compression level, press any key to try again."; $rclr;
        wait
        comp_level
    else
        uscr="${input}"
        if [[ $(defaults read "${plist}" complvl 2>/dev/null) ]]; then
            local key="complvl"
            local value="${input}"
            write_preference
        fi
        echo "==> 7zip Compression Level set to: ${uscr}" 1>> "$log" 2>&1
    fi
    unset input
}

# trap handler for non-zero exit/return codes
err_trap_handler () {
    errline="$1"
    errcode="$2"
    if [[ "$#" -lt "3" ]]; then
        errfunc="main.sh"
    else
        errfunc="$3"
    fi
    echo "==> ERROR: ${errfunc} code: ${errcode} line: ${errline}" 1>> "$log" 2>&1
}

# Write message to log if user hits control+c
control_c () {
    echo $blue"\nAwwww, user interrupt makes APK Manager sad panda :("
    echo $green"writing date & time of interrupt to LOG.txt"
    echo "USER SIGINT: $(gen_date)" 1>> "$log" 2>&1
    echo "$apkmftr" 1>> "$log" 2>&1
    exit 130
}


# Start
set -o errtrace

# set preference file domain name
plist="com.girlintroverted.apkmanager"

# check for main apkmanager path and
# check if necessary files/dirs exist
dircheck

# set path for other, other/bin, and other/lib
# and ensure usr/bin is before usr/local/bin
# so we always use default OSX tools
PATH="${maindir}/other:${bindir}:${libdir}:${d2jdir}:/usr/bin:${PATH}"
export PATH

# include common graphics library
source "${libdir}/graphics.sh"

# include automatic update functions
source "${libdir}/updates.sh"

# include common/static menus
source "${libdir}/menus.sh"

# include multi/dynamic menus
source "${libdir}/multimenu.sh"

# include common error strings library
source "${libdir}/errors.sh"

# include 'cleaning' functions
source "${libdir}/clean_funcs.sh"

# include 'debug' info functions
source "${libdir}/debug_funcs.sh"

# include decompile & extract functions
source "${libdir}/decext_funcs.sh"

# include misc (png, zipalign, adb) functions
source "${libdir}/misc_funcs.sh"

# include compile & all-in-one functions
source "${libdir}/zipcmp_funcs.sh"

# include basic "batch" functions
source "${libdir}/batch_funcs.sh"

# include advanced signing functions
source "${libdir}/sign_funcs.sh"

# include pngout check/install functions
source "${libdir}/png_out.sh"

# set path to log file
log="${maindir}/LOG.txt"

# check if basic debugging enabled
debugstate="$(defaults read "${plist}" debug 2>/dev/null)"

# start log output for current session
logstart

# check for color choice setup
colorcheck

# check for installation status
installcheck

# check for machine architecture
archtest

# check for necessary programs to run
startup_check

# check for ANDROID_SDK_ROOT
and_sdk_check

# check/create default folders
folderscheck

# check pre v2.1 migration
migratecheck

# check for and set logviewapp
logvchk

# check for existing apktool.jar symlink
apktcheck

# check if we need to try and update
auto_update_check

# check for persistent java heap size
jvheapck

# check for persistent compression level
complvlck

# check for persistent png tool
pngtoolset

# check number of files in modding folder
project_test

# write PID to plist in case we need it
set_current_pid

# check if we're going to kill adb on exit
gen_adb_kill_status

# startup complete, write divider to log
echo "$logspcr" 1>> "$log" 2>&1

# trap error codes and line number of errors
trap 'err_trap_handler ${LINENO} $? ${FUNCNAME}' ERR

# trap keyboard interrupt (control-c)
trap control_c SIGINT

# parse options and set vars if necessary
if [[ $# -ge 1 ]]; then
    while getopts 'tvexTVEX' OPTION
    do
        case "$OPTION" in
        [tT]) dircheck; exit 64 ;;
        [vV]) v_mode=1 ;;
        [eE]) e_mode=1 ;;
        [xX]) t_mode=1 ;;
        esac
        shift $(($OPTIND - 1))
    done
fi

# main loop, check options and show main menu
while [[ 1 = 1 ]];
do
    if [[ ${v_mode} -ne 0 ]]; then
        set -v
    fi
    if [[ ${e_mode} -ne 0 ]]; then
        set -e
    fi
    if [[ ${t_mode} -ne 0 ]]; then
        set -x
    fi
    clear
    restart
done

# Exit with error if somehow reach EOF
echo "\nEND OF FILE ERROR: $(gen_date)" 1>> "$log" 2>&1
echo "$apkmftr" 1>> "$log" 2>&1
exit 65
