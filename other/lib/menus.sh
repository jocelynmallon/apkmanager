#! /bin/sh
# -----------------------------------------------------------------------
# Apk Manager OS X v3.0+
# Application menus
#
# by Jocelyn Mallon CC by-nc-sa 2012
# http://girlintroverted.wordpress.com
#
# version: 3.1b
# Tue. Jul 30, 2013
# -----------------------------------------------------------------------

# Advanced signing menu
sign_menu () {
    if [[ -z $keystore ]]; then
        storecheck
    fi
    cd "${maindir}"
    clear
    menu_header
    echo $bgreen"--------------------------------------Advanced Signing Options--------------------------------------"
    echo $white" Current Keystore: "$bgreen"${keystore}"; $rclr;
    echo $green" (if \"None\" displayed, please use create new private key option first)"
    echo $bgreen"$apkmspr"
    echo $bgreen"  1   "$white"Create a new private key "$blue"(Will be stored in \$HOME/.apkmanager/.keystores)";
    echo $bgreen"  2   "$white"Select an existing keystore to use";
    echo $bgreen"  3   "$white"Sign an apk/jar file with private key";
    echo $bgreen"  4   "$white"Verify signed apk/jar";
    echo $bgreen"  5   "$white"Batch sign with private key "$blue"(Inside ${sig_dir} folder)";
    echo $bgreen"  6   "$white"Batch Verify signed apk/jar files "$blue"(Inside ${sig_dir} folder)";
    echo $bgreen"  7   "$white"Save default keystore selection "$blue"(If you have multiple keystores)";
    echo $bgreen"  8   "$white"Delete selected keystore and private key "$bred"(PLEASE USE WITH CAUTION)";
    echo $bgreen"  Q   "$white"Return to main menu";
    echo $bgreen"$apkmftr";
    printf "$bwhite%s""Please select an option from above: "; $rclr;
    read input
    case "$input" in
         1)  createpkey; sign_menu ;;
         2)  listpkeys; sign_menu ;;
         3)  sign_apk_pk; sign_menu ;;
         4)  single_vrfy; sign_menu ;;
         5)  batch_sign_pk; sign_menu ;;
         6)  batch_vrfy; sign_menu ;;
         7)  savekey; sign_menu ;;
         8)  delkey; sign_menu ;;
        96)  toggle_trace; sign_menu ;;
        97)  toggle_verbose; sign_menu ;;
        98)  toggle_error; sign_menu ;;
        99)  basic_debug; sign_menu ;;
      [qQ])  signcleanup ;;
  [qQ][qQ])  quit ;;
         *)  input_err; sign_menu ;;
    esac
}

# Clean files/folders menu
clean_menu () {
    cd "${maindir}"
    clear
    menu_header
    echo $bgreen"---------------------------------------Clean Files or Folders---------------------------------------";
    echo $bgreen"  1   "$white"Clean This Project's Folder";
    echo $bgreen"  2   "$white"Clean All Files in Modding Folder";
    echo $bgreen"  3   "$white"Clean All Files in OGG Folder";
    echo $bgreen"  4   "$white"Clean All Files in Batch Optimize Folder";
    echo $bgreen"  5   "$white"Clean All Files in Signing Folder";
    echo $bgreen"  6   "$white"Clean All Projects";
    echo $bgreen"  7   "$white"Clean APKtool framework files";
    echo $bgreen"  8   "$white"Clean All Files/Folders "$blue"(Executes options 1-7)";
    echo $bgreen"  9   "$white"Clean LOG.txt and adblog.txt Files";
    echo $bgreen"--------------------------------------Reset Persistent Options--------------------------------------";
    echo $bgreen"  10  "$white"Reset log viewer app";
    echo $bgreen"  11  "$white"Reset \"persistent\" Java heap memory size"$blue" (If enabled)";
    echo $bgreen"  12  "$white"Reset \"persistent\" Zip compression level"$blue" (If enabled)";
    echo $bgreen"  13  "$white"Reset \"persistent\" keystore selection"$blue" (If enabled)";
    echo $bgreen"  14  "$white"Reset \"persistent\" png optimization tool selection";
    echo $bgreen"  15  "$white"Reset \"persistent\" adb device selection"$blue" (If enabled)";
    echo $bgreen"  16  "$white"Reset apktool to newest version"$blue" (Can be set manually in the debug menu)";
    echo $bgreen"  17  "$white"Reset \"debug\" information"$blue" (Next launch of debug menu will be slow)";
    echo $bgreen"  18  "$white"Reset/Change terminal color scheme selection";
    echo $bgreen"  Q   "$white"Return to Main Menu";
    echo $bgreen"$apkmftr";
    printf "$bwhite%s""Please select an option from above: "; $rclr;
    read input
    case "$input" in
         1)  clean_capp ;;
         2)  clean_modding ;;
         3)  clean_ogg ;;
         4)  clean_batch ;;
         5)  clean_signing ;;
         6)  clean_projects ;;
         7)  clean_apktool ;;
         8)  clean_all ;;
         9)  clean_logs ;;
        10)  clean_viewer ;;
        11)  clean_heapsize ;;
        12)  clean_complvl ;;
        13)  clean_keystore ;;
        14)  clean_pngtool ;;
        15)  clean_adb_device ;;
        16)  clean_apktjar ;;
        17)  clean_debug ;;
        18)  clean_color ;;
        96)  toggle_trace ;;
        97)  toggle_verbose ;;
        98)  toggle_error ;;
        99)  basic_debug ;;
      [qQ])  cmcleanup  ;;
  [qQ][qQ])  quit ;;
         *)  input_err; clean_menu ;;
    esac
}

# Text app/editor menu
textapp_menu () {
    cd "${maindir}"
    clear
    menu_header
    debug_header
    echo $bgreen"------------------------------------Set editor for log/txt files------------------------------------";
    echo $bgreen"  1   "$white"Apple TextEdit"$blue" (Default)";
    echo $bgreen"  2   "$white"TextMate";
    echo $bgreen"  3   "$white"SubEthaEdit";
    echo $bgreen"  4   "$white"TextWrangler";
    echo $bgreen"  5   "$white"BBEDIT";
    echo $bgreen"  6   "$white"Coda";
    echo $bgreen"  7   "$white"MacVIM";
    echo $bgreen"  8   "$white"Aquamacs";
    echo $bgreen"  9   "$white"Smultron";
    echo $bgreen"  10  "$white"Vico";
    echo $bgreen"  11  "$white"Sublime Text 2 (or 3)";
    echo $bgreen"  12  "$white"Chocolat";
    echo $bgreen"  13  "$white"Nano "$blue"(In new terminal tab)";
    echo $bgreen"  14  "$white"Emacs "$blue"(In new terminal tab)";
    echo $bgreen"  15  "$white"vi/vim "$blue"(In new terminal tab)";
    echo $bgreen"  Q   "$white"Return to Debug Menu";
    echo $bgreen"$apkmftr";
    printf "$bwhite%s""Please select an option from above: "; $rclr;
    read input
    case "$input" in
         1)  logviewer="open"; logvchk ;;
         2)  logviewer="mate"; logvchk ;;
         3)  logviewer="see"; logvchk ;;
         4)  logviewer="edit"; logvchk ;;
         5)  logviewer="bbedit"; logvchk ;;
         6)  logviewer="coda"; logvchk ;;
         7)  logviewer="mvim"; logvchk ;;
         8)  logviewer="aquamacs"; logvchk ;;
         9)  logviewer="smultron"; logvchk ;;
        10)  logviewer="vico"; logvchk ;;
        11)  logviewer="subl"; logvchk ;;
        12)  logviewer="choc"; logvchk ;;
        13)  logviewer="nano"; logvchk ;;
        14)  logviewer="emacs"; logvchk ;;
        15)  logviewer="vi"; logvchk ;;
        96)  toggle_trace ;;
        97)  toggle_verbose ;;
        98)  toggle_error ;;
        99)  basic_debug ;;
      [qQ])  ;;
  [qQ][qQ])  quit ;;
         *)  input_err; textapp_menu ;;
    esac
}

# Automatic updates menu
updates_menu () {
    clear
    menu_header
    updates_header
    echo $bgreen"$apkmspr"
    echo $bgreen"  1   "$white"Turn automatic updates "$bgreen"ON";
    echo $bgreen"  2   "$white"Turn automatic updates "$bred"OFF";
    echo $bgreen"  3   "$white"Turn update prompt "$bgreen"ON"$blue" (default) (must confirm each update)";
    echo $bgreen"  4   "$white"Turn update prompt "$bred"OFF"$blue" (no confirmation needed before each update)";
    echo $bgreen"  5   "$white"Change update branch/channel "$blue"(master, develop, etc.)";
    echo $bgreen"  6   "$white"Change update frequency "$blue"(how many days to wait between updates)";
    echo $bgreen"  7   "$white"Check for updates now" $blue"(force an early check for new updates)";
    echo $bgreen"  8   "$white"View APK Manager on github "$blue"(https://github.com/jocelynmallon/apkmanager)";
    echo $bgreen"  Q   "$white"Return to Debug Menu";
    echo $bgreen"$apkmftr";
    printf "$bwhite%s""Please select an option from above: "; $rclr;
    read input
    case "$input" in
         1)  enable_auto_updates; updates_menu  ;;
         2)  disable_auto_updates; updates_menu  ;;
         3)  enable_update_prompt; updates_menu  ;;
         4)  disable_update_prompt; updates_menu  ;;
         5)  change_update_branch; updates_menu  ;;
         6)  change_update_freq; updates_menu  ;;
         7)  force_update_check; updates_menu  ;;
         8)  open https://github.com/jocelynmallon/apkmanager; updates_menu  ;;
        96)  toggle_trace; updates_menu  ;;
        97)  toggle_verbose; updates_menu  ;;
        98)  toggle_error; updates_menu  ;;
        99)  basic_debug; updates_menu  ;;
      [qQ])  updates_cleanup ;;
  [qQ][qQ])  quit ;;
         *)  input_err; updates_menu ;;
    esac
}

# ADB setup and tools menu
adb_menu () {
    clear
    menu_header
    debug_header
    echo $bgreen"$apkmspr"
    echo $bgreen"  1   "$white"Select default ADB device "$blue"(temporary, resets on every launch)";
    echo $bgreen"  2   "$white"Connect a device over wireless adb "$blue"(ensure you know the IP address and port of device)";
    echo $bgreen"  3   "$white"Make default ADB device persistent "$bred"(IF USING WIRELESS ADB, MUST HAVE STATIC IP)";
    echo $bgreen"  4   "$white"Quick adb log file "$blue"(capture adb logcat for 10 seconds)";
    echo $bgreen"  5   "$white"Extended adb log file "$blue"(capture adb logcat for a user specified number of seconds)";
    echo $bgreen"  6   "$white"Open an ADB shell session "$blue"(select a default adb device first)";
    echo $bgreen"  7   "$white"Toggle killing ADB daemon on quit" $blue"(currently: "$(adb_kill_display);
    echo $bgreen"  8   "$white"Restart ADB daemon" $blue"(must reconnect wireless adb sessions afterwards)";
#    echo $bgreen"  9   "$white"Setup advanced ADB command line options "$bred"(MAY HAVE UNINTENDED CONSEQUENCES)";
    echo $bgreen"  Q   "$white"Return to Debug Menu";
    echo $bgreen"$apkmftr";
    printf "$bwhite%s""Please select an option from above: "; $rclr;
    read input
    case "$input" in
         1)  adb_devices_menu; adb_menu  ;;
         2)  adb_wireless_connect; adb_menu  ;;
         3)  adb_save_device_pref; adb_menu  ;;
         4)  adb_log_device_check; adb_menu  ;;
         5)  extended_adb_log=1; adb_log_device_check; adb_menu  ;;
         6)  adb_shell; adb_menu  ;;
         7)  toggle_adb_kill_on_quit; adb_menu  ;;
         8)  adb kill-server; adb start-server >/dev/null; adb_menu  ;;
#         9)  adb_menu  ;;
        96)  toggle_trace; adb_menu  ;;
        97)  toggle_verbose; adb_menu  ;;
        98)  toggle_error; adb_menu  ;;
        99)  basic_debug; adb_menu  ;;
      [qQ])  ;;
  [qQ][qQ])  quit ;;
         *)  input_err; adb_menu ;;
    esac
}

# Debug & Settings menu
debug_menu () {
    debug_check
    if [[ -z $apktool_ver ]]; then
        getapktver
    fi
    cd "${maindir}"
    clear
    menu_header
    debug_header
    echo $bgreen"$apkmspr";
    echo $bgreen"  1   "$white"Set editor for log/txt files";
    echo $bgreen"  2   "$white"View binary info, paths, etc. ";
    echo $bgreen"  3   "$white"View README" $blue"(opens wiki on github)";
    echo $bgreen"  4   "$white"View CHANGELOG/COMMIT History";
    echo $bgreen"  5   "$white"View TIPS" $blue"(opens wiki on github)";
    echo $bgreen"  6   "$white"View LOG.txt";
    echo $bgreen"  7   "$white"View ADBLOG.txt "$blue"(if file exists)";
    echo $bgreen"  8   "$white"Configure automatic updates "$blue"(Requires you have \"git\" installed)";
    echo $bgreen"  9   "$white"Toggle command line use "$blue"(create/delete \"apkm\" symlink in /usr/local/bin)";
    echo $bgreen"-----------------------------------------Other misc options-----------------------------------------";
    echo $bgreen"  10  "$white"Enable persistent Java Heap memory size";
    echo $bgreen"  11  "$white"Enable persistent Zip Compression Level";
    echo $bgreen"  12  "$white"Use \"optipng\" for PNG optimization "$green"(Persistent) "$blue"(default APK Manager tool)";
    echo $bgreen"  13  "$white"Use \"pngcrush\" for PNG optimization "$green"(Persistent) "$blue"(tool used by CyanogenMod)";
    echo $bgreen"  14  "$white"Use \"pngout\" for PNG optimization "$green"(Persistent) "$blue"(used in commercial plugins)";
    echo $bgreen"  15  "$white"Launch draw9patch "$blue"(Requires you have Android SDK installed)";
    echo $bgreen"  16  "$white"Launch Android Device Monitor "$blue"(Requires you have Android SDK installed)";
    echo $bgreen"  17  "$white"Choose APKtool version "$blue"(For decompiling/compiling apk files)";
    echo $bgreen"  18  "$white"ADB Tools "$blue"(logcat, shell, wireless ADB setup, etc.)";
    echo $bgreen"  Q   "$white"Return to Main Menu";
    echo $bgreen"$apkmftr";
    printf "$bwhite%s""Please select an option from above: "; $rclr;
    read input
    case "$input" in
         1)  textapp_menu ; debug_menu ;;
         2)  debug_display; debug_menu ;;
         3)  open https://github.com/jocelynmallon/apkmanager/wiki; debug_menu ;;
         4)  view_changelog; debug_menu ;;
         5)  open https://github.com/jocelynmallon/apkmanager/wiki/General-Tips; debug_menu ;;
         6)  txt="$log" 2>> "$log"; read_txt; debug_menu ;;
         7)  read_adb_log; debug_menu ;;
         8)  updates_git_check; debug_menu ;;
         9)  apkm_tool_toggle; debug_menu ;;
        10)  local key="heap" && local value="$heapy" && write_preference && heap_size; debug_menu ;;
        11)  local key="complvl" && local value="$uscr" && write_preference && comp_level; debug_menu ;;
        12)  local key="pngtool" && local value="optipng" && write_preference && pngtoolset; debug_menu ;;
        13)  local key="pngtool" && local value="pngcrush" && write_preference && pngtoolset; debug_menu ;;
        14)  pngout_check; debug_menu ;;
        15)  draw_nine; debug_menu ;;
        16)  launch_ddms; debug_menu ;;
        17)  apkt_menu_check; debug_menu ;;
        18)  adb_menu; debug_menu ;;
        96)  toggle_trace; debug_menu ;;
        97)  toggle_verbose; debug_menu ;;
        98)  toggle_error; debug_menu ;;
        99)  basic_debug; debug_menu ;;
      [qQ])  debug_cleanup ;;
  [qQ][qQ])  quit ;;
         *)  input_err; debug_menu ;;
    esac
}

# Main Menu
restart () {
    cd "${maindir}"
    menu_header
    echo $bgreen"---------------------------------Simple Tasks Such As Image Editing---------------------------------";
    echo $bgreen"  1   "$white"Adb pull "$blue"(Pulls file into \"${mod_dir}\" folder)";
    echo $bgreen"  2   "$white"Extract apk ";
    echo $bgreen"  3   "$white"Optimize images inside "$blue"(Only if \"Extract Apk\" was selected)";
    echo $bgreen"  4   "$white"Compile \".9.png\" and/or binary xml files";
    echo $bgreen"  5   "$white"Zip apk ";
    echo $bgreen"  6   "$white"Sign apk "$blue"(With test keys) "$bred"(DON'T do this if its a system apk)";
    echo $bgreen"  7   "$white"Zipalign apk "$blue"(Do this after apk is zipped / signed)";
    echo $bgreen"  8   "$white"Install apk "$bred"(DON'T do this if system apk, do adb push)";
    echo $bgreen"  9   "$white"Zip / Sign / Install apk "$blue"(All in one step)" $bred"(apk files only)";
    echo $bgreen"  10  "$white"Adb push "$bred"(Only for system apk/jar file)";
    echo $bgreen"--------------------------------Advanced Tasks Such As Code Editing---------------------------------";
    echo $bgreen"  11  "$white"Decompile "$blue"(Supports both apk and jar files)";
    echo $bgreen"  12  "$white"Decompile with dependencies"$blue" (For propietary rom apks)" $bred"(apk files only)";
    echo $bgreen"  13  "$white"Advanced Decompile APK "$blue"(Uses baksmali for code, apktool for resources)";
    echo $bgreen"  14  "$white"Compile "$blue"(For use with decompile options: 11, 12, 13)";
    echo $bgreen"  15  "$white"Compile / Sign / Install "$blue"(All in one step) "$bred"(apk files only)";
    echo $bgreen"  16  "$white"Advanced \"All-in-one\" "$blue"(Zip/Compile, sign with private keys, install)";
    echo $bgreen"  17  "$white"View Java Source "$blue"(apk and jar support) "$bred"(CANNOT be recompiled)";
    echo $bgreen"-------------------------------------------Other Options--------------------------------------------";
    echo $bgreen"  18  "$white"Advanced signing options "$blue"(Use your own keystore, verify signatures, etc.)";
    echo $bgreen"  19  "$white"Batch Optimize files "$blue"(Inside \"${bat_dir}\" folder)";
    echo $bgreen"  20  "$white"Batch Sign apk files "$blue"(With test keys, inside \"${sig_dir}\" folder)";
    echo $bgreen"  21  "$white"Batch optimize ogg files "$blue"(Inside \"${ogg_dir}\" only)";
    echo $bgreen"  22  "$white"Select compression level for zipping files";
    echo $bgreen"  23  "$white"Set max Java heap memory size "$blue"(If getting stuck at decompiling/compiling)";
    echo $bgreen"  24  "$white"Debug Info and Misc Settings "$blue"(Persistent heap, set log viewing app, etc.)";
    echo $bgreen"  25  "$white"Clean Files/Folders, Reset settings, etc. "
    echo $bgreen"  26  "$white"Select Current Project";
    echo $bgreen"  Q   "$white"Quit APK Manager";
    echo $bgreen"$apkmftr";
    printf "$bwhite%s""Please select an option from above: "; $rclr;
    read input
    case "$input" in
         1)  adb_pull ;;
         2)  extract_apk ;;
         3)  opt_apk_png ;;
         4)  compile_9patch ;;
         5)  zip_apk ;;
         6)  sign_apk_tk ;;
         7)  zalign_file ;;
         8)  install_apk ;;
         9)  zip_sign_install ;;
        10)  adb_push ;;
        11)  decompile ;;
        12)  decomp_ded ;;
        13)  decompile_adv ;;
        14)  compile ;;
        15)  co_sign_install ;;
        16)  adv_all_in_one ;;
        17)  d2j_check ;;
        18)  sign_menu ;;
        19)  batch_opt; batch_cleanup ;;
        20)  batch_sign_tk; batch_cleanup ;;
        21)  batch_ogg; batch_cleanup ;;
        22)  comp_level ;;
        23)  heap_size ;;
        24)  debug_menu ;;
        25)  clean_menu ;;
        26)  projects_menu ;;
        96)  toggle_trace ;;
        97)  toggle_verbose ;;
        98)  toggle_error ;;
        99)  basic_debug ;;
      [qQ])  quit ;;
  [qQ][qQ])  quit ;;
         *)  input_err ;;
    esac
}
