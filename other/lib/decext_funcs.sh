#! /bin/sh
# -----------------------------------------------------------------------
# Apk Manager OS X v3.0+
# Decompile & Extract functions
#
# by Jocelyn Mallon CC by-nc-sa 2012
# http://girlintroverted.wordpress.com
#
# version: 3.0.3
# Wed. Jul 7, 2013
# -----------------------------------------------------------------------

# Remove existing files before extract/decompile
decext_rmfiles () {
    echo "decext_rmfiles (remove previous build files if they exist)" 1>> "$log"
    if [[ -e "${maindir}/${mod_dir}/signed-${capp}" ]]; then
        rm "${maindir}/${mod_dir}/signed-${capp}"
    fi
    if [[ -e "${maindir}/${mod_dir}/unsigned-${capp}" ]]; then
        rm "$maindir/$mod_dir/unsigned-$capp"
    fi
    if [[ -e "${maindir}/${prj_dir}/${capp}" ]]; then
        rm "$maindir/$prj_dir/$capp"
    fi
}

# Actually extract an apk file
do_extract () {
    echo "do_extract (actually extracting apk now) function" 1>> "$log"
    decext_rmfiles
    if [[ ! -d "${maindir}/${prj_dir}/${capp}" ]]; then
        mkdir -p "${maindir}/${prj_dir}/${capp}"
    fi
    7za x -o"${maindir}/${prj_dir}/${capp}" "${maindir}/${mod_dir}/${capp}" 1>> "$log" 2>&1
    if [[ $? -ne 0 ]]; then
        echo $bred"Error extracting ${capp}, please check log"; $rclr;
        pressanykey
    fi
}

# Extract an apk file, initial checks
extract_apk () {
    echo "extract_apk function" 1>> "$log"
    capp_test
    if [[ ${capp} = "None" ]]; then
        echo "no project selected, aborting" 1>> "$log"
        return 1
    elif [[ ! ${prjext} = [Aa][Pp][Kk] ]]; then
        jarext_err
    elif [[ ! -f "${maindir}/${mod_dir}/${capp}" ]]; then
        notfound_err
    elif [[ ! -d "${maindir}/${prj_dir}/${capp}" ]]; then
        do_extract
    elif [[ $(ls -1 "${maindir}/${prj_dir}/${capp}" | wc -l) -eq 0 ]]; then
        do_extract
    elif [[ $(ls -1 "${maindir}/${prj_dir}/${capp}" | wc -l) -ne 0 ]]; then
        overwrite_prompt
        read input
        case "$input" in
         [yY])  clean_capp; do_extract ;;
         [nN])  ;;
            *)  input_err; extract_apk ;;
        esac
        unset input
    else
        do_extract
    fi
    echo "extract_apk function complete" 1>> "$log"
}

# Actually decompile a jar file
decomp_jar () {
    echo "decomp_jar, actually decompiling now" 1>> "$log"
    decext_rmfiles
    echo "Decompiling Jar"
    runj baksmali -JXmx"${heapy}""m" "${maindir}/${mod_dir}/${capp}" -o "${maindir}/${prj_dir}/${capp}" 1>> "$log" 2>&1
    if [[ $? -ne 0 ]]; then
        echo $bred"An error occured while decompiling, please check log."; $rclr;
        pressanykey
    fi
    echo "decomp_jar function complete" 1>> "$log"
}

# Actually decompile an apk file
decomp_apk () {
    echo "decomp_apk, actually decompiling now" 1>> "$log"
    decext_rmfiles
    echo "Decompiling Apk"
    runj apktool -JXmx"${heapy}""m" d "${maindir}/${mod_dir}/${capp}" "${maindir}/${prj_dir}/${capp}" 1>> "$log" 2>&1
    if [[ $? -ne 0 ]]; then
        echo $bred"An error occured while decompiling, please check log."; $rclr;
        pressanykey
    fi
    echo "decomp_apk function complete" 1>> "$log"
}

# Determine apk or jar filetype for decompile
decomp_ext_test () {
    echo "decomp_ext_test (\"apk\" or \"jar\" file test) function" 1>> "$log"
    if [[ ${prjext} = [Jj][Aa][Rr] ]]; then
        echo "project is a jar file, launching decomp_jar subroutine" 1>> "$log"
        decomp_jar
    elif [[ ${prjext} = [Aa][Pp][Kk] ]]; then
        echo "project is an apk file, launching decomp_apk subroutine" 1>> "$log"
        decomp_apk
    fi
}

# Decompile apk or jar file, initial checks
decompile () {
    echo "decompile function" 1>> "$log"
    capp_test
    if [[ ${capp} = "None" ]]; then
        echo "no project selected, aborting" 1>> "$log"
        return 1
    elif [[ ! -f "${maindir}/${mod_dir}/${capp}" ]]; then
        notfound_err
    elif [[ ! -d "${maindir}/${prj_dir}/${capp}" ]]; then
        decomp_ext_test
    elif [[ $(ls -1 "${maindir}/${prj_dir}/${capp}" | wc -l) -eq 0 ]]; then
        decomp_ext_test
    elif [[ $(ls -1 "${maindir}/${prj_dir}/${capp}" | wc -l) -ne 0 ]]; then
        overwrite_prompt
        read input
        case "$input" in
         [yY])  clean_capp; decomp_ext_test ;;
         [nN])  ;;
            *)  input_err; decompile ;;
        esac
    fi
    echo "decompile function complete" 1>> "$log"
}

# Advanced decompile apk, actual decompile function
decomp_adv () {
    echo "decomp_adv, actually decompiling now" 1>> "$log"
    decext_rmfiles
    echo "decomp_adv, decompiling resources..." 1>> "$log"
    echo "Decompiling Resources..."
    runj apktool -JXmx"${heapy}""m" d -s "${maindir}/${mod_dir}/${capp}" "${maindir}/${prj_dir}/${capp}" 1>> "$log" 2>&1
    if [[ $? -ne 0 ]]; then
        echo $bred"An error occured while decompiling resources, please check log."; $rclr;
        pressanykey
    else
        rm -rf "${maindir}/${prj_dir}/${capp}/classes.dex"
        echo "decomp_adv, decompiling code..." 1>> "$log"
        echo "Decompiling Code..."
        runj baksmali -JXmx"${heapy}""m" "${maindir}/${mod_dir}/${capp}" -o "${maindir}/${prj_dir}/${capp}/smali" 1>> "$log" 2>&1
        if [[ $? -ne 0 ]]; then
            echo $bred"An error occured while decompiling code, please check log."; $rclr;
            pressanykey
        else
            echo "advanced" 1> "${maindir}/${prj_dir}/${capp}/.advanced"
        fi
    fi
    echo "decomp_adv function complete" 1>> "$log"
}

# Advanced decompile apk, initial checks
decompile_adv () {
    echo "decompile_adv (advanced decompile apk) function" 1>> "$log"
    capp_test
    if [[ ${capp} = "None" ]]; then
        echo "no project selected, aborting" 1>> "$log"
        return 1
    elif [[ ! ${prjext} = [Aa][Pp][Kk] ]]; then
        jarext_err
    elif [[ ! -f "${maindir}/${mod_dir}/${capp}" ]]; then
        notfound_err
    elif [[ ! -d "${maindir}/${prj_dir}/${capp}" ]]; then
        decomp_adv
    elif [[ $(ls -1 "${maindir}/${prj_dir}/${capp}" | wc -l) -eq 0 ]]; then
        decomp_adv
    elif [[ $(ls -1 "${maindir}/${prj_dir}/${capp}" | wc -l) -ne 0 ]]; then
        overwrite_prompt
        read input
        case "$input" in
         [yY])  clean_capp; decomp_adv ;;
         [nN])  ;;
            *)  input_err; decompile_adv ;;
        esac
    fi
    echo "decompile_adv function complete" 1>> "$log"
}

# View java source, extract original classes.dex
extract_classes_dex () {
    echo "extract_classes_dex (extract classes.dex file) function" 1>> "$log"
    7za x -o"${maindir}/${prj_dir}/${capp}/java" "${maindir}/${mod_dir}/${capp}" classes.dex -y 1>> "$log" 2>&1
}

# View java source, deobfuscate source
decj_jar_deobf () {
    echo "d2j_jar_deobf (attempt to deobfuscate jar) function" 1>> "$log"
    d2j-init-deobf -f -o "${maindir}/${prj_dir}/${capp}/java/init.txt" "${maindir}/${prj_dir}/${capp}/java/classes-dex2jar.jar"
    d2j-jar-remap -f -c "${maindir}/${prj_dir}/${capp}/java/init.txt" -o "${maindir}/${prj_dir}/${capp}/java/classes-deobf.jar" "${maindir}/${prj_dir}/${capp}/java/classes-dex2jar.jar"
    rm -r "${maindir}/${prj_dir}/${capp}/java/init.txt"
    rm -r "${maindir}/${prj_dir}/${capp}/java/classes-dex2jar.jar"
}

# View java source - process classes.dex
decj_process_dex () {
    echo "decj_process_dex (convert classes.dex to jar file) function" 1>> "$log"
    d2j-dex2jar -f "${maindir}/${prj_dir}/${capp}/java/classes.dex" -o "${maindir}/${prj_dir}/${capp}/java/classes-dex2jar.jar"
}

# View java source, check for/create /java folder
decj_dir_check () {
    echo "decj_dir_check (check for project/java dir) function" 1>> "$log"
    if [[ ! -d "${maindir}/${prj_dir}/${capp}/java" ]]; then
        mkdir -p "${maindir}/${prj_dir}/${capp}/java"
    fi
}

# View java source subroutine
decj_norm_sub () {
    echo "decj_norm_sub (decompile java subroutine) function" 1>> "$log"
    decj_dir_check
    extract_classes_dex
    if [[ ! -f "${maindir}/${prj_dir}/${capp}/java/classes.dex" ]]; then
        decj_extdex_err
        return 1
    fi
    decj_process_dex
    if [[ $? -ne 0 ]]; then
        decj_process_dex_err
        return 1
    fi
    echo "decj_norm_sub function complete" 1>> "$log"
}

# View java source, extrat jar and open with JD-GUI
decj_finish () {
    echo "decj_finish (extract decompiled jar) function" 1>> "$log"
    if [[ -f "${maindir}/${prj_dir}/${capp}/java/classes-dex2jar.jar" ]]; then
        local jarfile="${maindir}/${prj_dir}/${capp}/java/classes-dex2jar.jar"
    elif [[ -f "${maindir}/${prj_dir}/${capp}/java/classes-deobf.jar" ]]; then
        local jarfile="${maindir}/${prj_dir}/${capp}/java/classes-deobf.jar"
    fi
    cd "${maindir}/${prj_dir}/${capp}/java"
    jar xvf "${jarfile}"
    if [[ $? -ne 0 ]]; then
        decj_extract_jar_err
        return 1
    fi
    local class_var="$(find . -name '*.class' | grep -m 1 '.class')"
    cd "${maindir}/${prj_dir}/${capp}/java"
    open -a "${maindir}/other/bin/JD-GUI.app" "${class_var}"
    rm -r "${maindir}/${prj_dir}/${capp}/java/classes.dex"
    rm -r "${jarfile}"
    cd "${maindir}"
    echo "decj_finish function complete" 1>> "$log"
}

# View java source, normal shell function
decj_normal () {
    echo "decj_normal (decompile java normal) function" 1>> "$log"
    decj_norm_sub
    if [[ $? -ne 0 ]]; then
        return $?
    fi
    decj_finish
    echo "decj_normal function complete" 1>> "$log"
}

# View java source, deobfuscate shell function
decj_deobf () {
    echo "decj_deobf (decompile java and deobfuscate) function" 1>> "$log"
    decj_norm_sub
    if [[ $? -ne 0 ]]; then
        return $?
    fi
    decj_jar_deobf
    decj_finish
    echo "decj_deobf function complete" 1>> "$log"
}

# Prompt for attempt to deobfuscate java source
decj_deobf_prompt () {
    echo "decj_deobf_prompt (decompile java & deobfuscate prompt)" 1>> "$log"
    clear
    menu_header
    echo $bgreen"$apkmspr";
    echo ""
    echo $white" Some APK files have had "$bgreen"\"Proguard\""$white", an obfuscation"
    echo $white" tool, run when compiled to make their code significantly"
    echo $white" harder to read when decompiled. The tool APK Manager"
    echo $white" uses, dex2jar, has basic support to try and deobfuscate"
    echo $white" the decompiled code, but please note that it"
    echo $white" does not work on every apk."
    echo ""
    echo $bgreen"$apkmftr";
    printf "$white%s""Attempt to deobfuscate java code? ("$bgreen"y"$white"/"$bgreen"n"$white") "; $rclr;
    read input
    case "$input" in
     [yY])  decj_deobf ;;
     [nN])  decj_normal ;;
        *)  input_err; decj_deobf_prompt ;;
    esac
    unset input
    echo "decj_deobf_prompt complete" 1>> "$log"
}

# View Java source code initial checks
decompile_java () {
    echo "decompile_java (view java source code) function" 1>> "$log"
    capp_test
    if [[ ${capp} = "None" ]]; then
        echo "no project selected, aborting" 1>> "$log"
        return 1
    elif [[ ! -f "${maindir}/${mod_dir}/${capp}" ]]; then
        notfound_err
    elif [[ ! -d "${maindir}/${prj_dir}/${capp}/java" ]]; then
        decj_deobf_prompt
    elif [[ $(ls -1 "${maindir}/${prj_dir}/${capp}/java" | wc -l) -eq 0 ]]; then
        decj_deobf_prompt
    elif [[ $(ls -1 "${maindir}/${prj_dir}/${capp}/java" | wc -l) -ne 0 ]]; then
        overwrite_prompt
        read input
        case "$input" in
         [yY])  clean_capp; decj_deobf_prompt ;;
         [nN])  ;;
            *)  input_err; decompile_java ;;
        esac
        unset input
    fi
    clear
    echo "decompile_java function complete" 1>> "$log"
}

# Check proper installation of dex2jar
install_d2j_check () {
    if [[ $(command -v dex2jar) ]]; then
        echo $bgreen"dex2jar installed succesfully!"
        echo ""
        echo $bgreen"$apkmftr";
        getdex2jarver
        local key="dex2jar"
        write_preference
        genericpanykey
        unset key
        unset value
        decompile_java
    else
        echo $bred"Something went wrong installing dex2jar"
        echo $bred"Please check the log and try again."; $rclr;
        pressanykey
    fi
}

# actually installing dex2jar now
install_d2j_sub () {
    echo $green"Extracting ${d2j_file}..."
    echo ""
    cd "${maindir}/other"
    echo "==> extracting dex2jar archive" 1>> "$log"
    tar -xzvf "${maindir}/other/${d2j_file}" 1>> "$log" 2>&1
    echo $green"Removing temporary files."
    echo $green"renaming folder to \$maindir/other/dex2jar"
    echo "==> renaming folder to \$maindir/other/dex2jar" 1>> "$log"
    mv -f "${maindir}/other/${d2j_folder}" "${maindir}/other/dex2jar"
    cd "${maindir}/other/dex2jar/"
    echo $green"deleting windows .bat files..."
    echo "==> deleting windows .bat files..." 1>> "$log"
    local f
    ls -1 *.bat | while read f ; do
        rm -r "${f}"
    done
    echo $green"making dex2jar directory executable..."
    echo "==> removing \".sh\" file extensions..." 1>> "$log"
    ls -1 *.sh | while read f ; do
        mv "${f}" "${f%\.*}"
    done
    echo "==> making dex2jar directory executable..." 1>> "$log"
    chmod -R ug+x "${maindir}/other/dex2jar/"
    echo $green"removing ${d2j_file}"
    echo "==> removing ${d2j_file}" 1>> "$log"
    rm -r "${maindir}/other/${d2j_file}"
}

# Download and install dex2jar
install_d2j () {
    local d2j_file="dex2jar-0.0.9.15.zip"
    local d2j_folder="${d2j_file%%.z*}"
    echo "install_d2j (actually installing dex2jar now)" 1>> "$log"
    if [[ ! -f "${maindir}/other/${d2j_file}" ]]; then
        echo $green" Local copy of archive not found, downloading now..."; $rclr;
        echo ""
        curl "http://dex2jar.googlecode.com/files/${d2j_file}" > "${maindir}/other/${d2j_file}"
        echo ""
    fi
    local filehash="$(md5 -q "${maindir}/other/${d2j_file}")"
    local expected="70f62db86e70318538a5b90df05b954b"
    if [[ ${filehash} = ${expected} ]]; then
        install_d2j_sub
        install_d2j_check
    else
        echo $bred"ERROR: Corrupt download/file, md5 hash fail:"
        echo $bred"download: ${filehash}"
        echo $bred"expected: ${expected}"
        echo ""
        echo $white"press any key to try download again..."
        wait
        rm -r "${maindir}/other/${d2j_file}"
        install_d2j
    fi
    echo "install_d2j function complete" 1>> "$log"
}

# Prompt user to install dex2jar
d2j_install_prompt () {
    echo "d2j_install_prompt (install dex2jar prompt)" 1>> "$log"
    clear
    menu_header
    echo $bgreen"$apkmspr";
    echo ""
    echo $white" APK Manager has the ability to decompile most applications to their java source code,"
    echo $white" using a combination of the excellent \"dex2jar\" and \"JD-GUI\" tools."
    echo ""
    echo $white" dex2jar homepage: "$green"http://code.google.com/p/dex2jar/"
    echo $white" JD-GUI homepage: "$green"http://java.decompiler.free.fr/?q=jdgui"
    echo ""
    echo $white" In attempt to cut down on filesize, and redundancy, dex2jar is not included by default"
    echo $white" with APK Manager v3.0+. Instead, APK Manager can download it automatically."
    echo ""
    echo $bgreen"$apkmftr";
    printf "$white%s""Download and install dex2jar? ("$bgreen"y"$white"/"$bgreen"n"$white") "; $rclr;
    read input
    case "$input" in
        [yY]) install_d2j ;;
        [nN]) ;;
           *) input_err; d2j_install_prompt ;;
    esac
    unset input
    echo "d2j_install_prompt complete" 1>> "$log"
}

# Check for ./other/dex2jar
d2j_check () {
    echo "d2j_check (check for dex2jar) function" 1>> "$log"
    if [[ -d "${d2jdir}" ]] && [[ $(command -v dex2jar) ]]; then
        decompile_java
    else
        d2j_install_prompt
    fi
    echo "d2j_check function complete" 1>> "$log"
}

# Actually decompile with dependancy
dec_ded_sub () {
    echo "dec_ded_sub, install dependancy subroutine" 1>> "$log"
    rm -f "${HOME}/apktool/framework/2.apk"
    local dependee
    read dependee
    if [[ -z ${dependee} ]]; then :
    else
        runj apktool if "${dependee}" 1>> "$log" 2>&1
        if [[ ! -f "${HOME}/apktool/framework/2.apk" ]]; then
            clear
            echo $bred"Sorry $(basename "${dependee}") is not the dependee apk, please try again"; $rclr;
            dec_ded_prompt
        else
            echo "Decompiling Apk"
            runj apktool -JXmx"${heapy}""m" d "${maindir}/${mod_dir}/${capp}" "${maindir}/${prj_dir}/${capp}" 1>> "$log" 2>&1
            if [[ $? -ne 0 ]]; then
                echo $bred"An error occured while decompiling, please check log."; $rclr;
                pressanykey
            fi
        fi
    fi
}

# Prompt for dependancy file/location
dec_ded_prompt () {
    decext_rmfiles
    echo $white"Drag the dependee apk in this window or type its path";
    echo $white"Example to decompile Rosie.apk, drag "$bgreen"com.htc.resources.apk"$white" in this window";
    echo $green"(leave blank and press enter to return to main menu)"; $rclr;
    dec_ded_sub
}

# Decompile apk with dependancy
decomp_ded () {
    echo "decomp_ded (decompile apk with dependancy) function" 1>> "$log"
    capp_test
    if [[ ${capp} = "None" ]]; then
        echo "no project selected, aborting" 1>> "$log"
        return 1
    elif [[ ! ${prjext} = [Aa][Pp][Kk] ]]; then
        jarext_err
    elif [[ ! -f "${maindir}/${mod_dir}/${capp}" ]]; then
        notfound_err
    elif [[ ! -d "${maindir}/${prj_dir}/${capp}" ]]; then
        dec_ded_prompt
    elif [[ $(ls -1 "${maindir}/${prj_dir}/${capp}" | wc -l) -eq 0 ]]; then
        dec_ded_prompt
    elif [[ $(ls -1 "${maindir}/${prj_dir}/${capp}" | wc -l) -ne 0 ]]; then
        overwrite_prompt
        read input
        case "$input" in
         [yY])  clean_capp; dec_ded_prompt ;;
         [nN])  ;;
            *)  input_err; decomp_ded ;;
        esac
    fi
    echo "decomp_ded function complete" 1>> "$log"
}
