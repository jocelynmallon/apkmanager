#! /bin/sh
# -----------------------------------------------------------------------
# Apk Manager OS X v3.0+
# Clean menu functions
#
# by Jocelyn Mallon CC by-nc-sa 2012
# http://girlintroverted.wordpress.com
#
# version: 3.0b
# Sat. May 19, 2012
# -----------------------------------------------------------------------

# Cleanup for 'cleaning' functions
cmcleanup () {
    unset clnpth
    unset clndir
}

# Clean/reset working project only
clean_capp () {
    capp_test
    echo "clean_capp (removing current working project folder)" 1>> "$log"
    clnpth="${maindir}/${prj_dir}"
    clndir="${capp}"
    rm -rf "${clnpth}/${clndir}"
}

# Clean/reset all files in modding folder
clean_modding () {
    echo "clean_modding (removing \"${mod_dir}\" folder)" 1>> "$log"
    clnpth="${maindir}"
    clndir="${mod_dir}"
    clean_exec
    project_test
}

# Clean/reset all files in batch ogg folder
clean_ogg () {
    echo "clean_ogg (removing \"${ogg_dir}\" folder)" 1>> "$log"
    clnpth="${maindir}"
    clndir="${ogg_dir}"
    clean_exec
}

# Clean/reset all files in bath optimize folder
clean_batch () {
    echo "clean_batch (removing \"${bat_dir}\" folder)" 1>> "$log"
    clnpth="${maindir}"
    clndir="${bat_dir}"
    clean_exec
}

# Clean/reset all files in batch signing folder
clean_signing () {
    echo "clean_signing (removing \"${sig_dir}\" folder)" 1>> "$log"
    clnpth="${maindir}"
    clndir="${sig_dir}"
    clean_exec
}

# Clean/reset all projects
clean_projects () {
    echo "clean_projects (removing \"projects\" folder)" 1>> "$log"
    clnpth="${maindir}"
    clndir="${prj_dir}"
    clean_exec
}

# Clean/reset apktool framework files
clean_apktool () {
    echo "clean_apktool (removing apktool framework files)" 1>> "$log"
    find "${HOME}/apktool/framework" -iname "*.apk" -exec mv {} ~/.Trash \;
}

# Clean/reset log & adblog files
clean_logs () {
    rm -rf "${log}"
    rm -rf "${maindir}/adblog.txt"
    logstart
}

# Clean/reset all working directories
clean_all () {
    echo "clean_all (cleaning all files and folders)" 1>> "$log"
    clean_modding
    clean_ogg
    clean_batch
    clean_signing
    clean_projects
    clean_apktool
    echo "clean_all complete" 1>> "$log"
    project_test
}

# Clean/reset log viewer app choice
clean_viewer () {
    echo "clean_viewer (resetting log viewer app to default)" 1>> "$log"
    defaults delete "${plist}" logviewapp 2>/dev/null
    logvset
}

# Clean/reset persistent java heap memory choice
clean_heapsize () {
    echo "clean_heapsize (resetting persistent java heap memory size)" 1>> "$log"
    defaults delete "${plist}" heap 2>/dev/null
    jvheapck
}

# Clean/reset persistent compression level choice
clean_complvl () {
    echo "clean_complvl (resetting persistent compression level)" 1>> "$log"
    defaults delete "${plist}" complvl 2>/dev/null
    complvlck
}

# Clean/reset persistent keystore choice
clean_keystore () {
    echo "clean_keystore (resetting persistent keystore setting)" 1>> "$log"
    defaults delete "${plist}" keychoice 2>/dev/null
    unset keystore
    storecheck
}

# Clean/reset png optimization tool choice
clean_pngtool () {
    echo "clean_pngtool (resetting png optimization tool setting)" 1>> "$log"
    defaults delete "${plist}" pngtool 2>/dev/null
    unset pngtool
    pngtoolset
}

# Clean/reset apktool.jar symlink
clean_apktjar () {
    echo "clean_apktjar (resetting apktool.jar to newest version)" 1>> "$log"
    rm "${libdir}/apktool.jar"
    unset apktool_ver
    apktcheck
    getapktver
}

# Clean/reset debug/binary information
clean_debug () {
    echo "clean_debug (resetting debug information)" 1>> "$log"
    local key="debugset"
    local value="false"
    write_preference
    unset apktool_ver
}

# Clean/reset user color preference
clean_color () {
    echo "clean_color (resetting color scheme selection)" 1>> "$log"
    defaults delete "${plist}" color 2>/dev/null
    unset white
    unset bwhite
    echo "color selection reset, launching colorcheck..." 1>> "$log" 2>&1
    colorcheck
}

# Actually execute clean commands
clean_exec () {
    rm -rf "${clnpth}/${clndir}"
    mkdir -p "${clnpth}/${clndir}"
}
