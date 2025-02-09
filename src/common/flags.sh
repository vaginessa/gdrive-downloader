#!/usr/bin/env sh
# shellcheck source=/dev/null

###################################################
# setup all the flags help, stuff to be executed for them and pre process
# todo: maybe post processing too
###################################################
_parser_setup_flags() {
    # add initial help text which will appear at start
    _parser_add_help "
The script can be used to download file/directory from google drive.

Usage: ${0##*/} [options.. ] <file_[url|id]> or <folder[url|id]>

Options:"

    ###################################################

    # not a flag exactly, but will be used to process any arguments which is not a flag
    _parser_setup_flag "input" 0
    _parser_setup_flag_help \
        "Drive urls or id to process."

    _parser_setup_flag_preprocess 4<< 'EOF'
unset TOTAL_INPUTS INPUT_ID
EOF

    _parser_setup_flag_process 4<< 'EOF'
# set ID_INPUT_NUM to the input, where num is rank of input
id_parse_arguments=""
_extract_id "${1}" id_parse_arguments 

if [ -n "${id_parse_arguments}" ]; then
    # this works well in place of arrays
    _set_value d "INPUT_ID_$((TOTAL_INPUTS += 1))" "${id_parse_arguments}"
fi
EOF

    ###################################################

    _parser_setup_flag "-am --alternate-method" 0
    _parser_setup_flag_help \
        "Use this flag to use alternate method of downloading.

In default mode, all the folder information if fetched recursively and then download is started.

In alternate mode, downloading is done one folder at a time."

    _parser_setup_flag_preprocess 4<< 'EOF'
export DOWNLOAD_METHOD="alt"
EOF

    _parser_setup_flag_process 4<< 'EOF'
export DOWNLOAD_METHOD="noalt"
EOF

    ###################################################

    _parser_setup_flag "-aria" 0
    _parser_setup_flag_help \
        "Use aria2c to download. To use custom flags for aria, see --aria-flags option."

    _parser_setup_flag_process 4<< 'EOF'
if ! command -v aria2c 1>|/dev/null ; then
    printf "%s\n" "Error: aria2c not installed."
    return 1
fi
export DOWNLOADER="aria2c"
EOF

    #########################

    _parser_setup_flag "--aria-flags" 1 required 'flags'
    _parser_setup_flag_help \
        'Same as -aria flag but requires argument.

To give custom flags as argument, do
    e.g: --aria-flags "-s 10 -x 10"

Note 1: aria2c can only resume google drive downloads if "-k/--key" or "-o/--oauth" option is used.

Note 2: aria split downloading will not work in normal mode ( without "-k" or "-o" flag ) because it cannot get the remote server size. Same for any other feature which uses remote server size.

Note 3: By above notes, conclusion is, aria is basically same as curl in normal mode, so it is recommended to be used only with "--key" and "--oauth" flag.'

    _parser_setup_flag_preprocess 4<< 'EOF'
unset ARIA_FLAGS 
EOF

    _parser_setup_flag_process 4<< 'EOF'
if ! command -v aria2c 1>|/dev/null ; then
    printf "%s\n" "Error: aria2c not installed."
    return 1
fi
export DOWNLOADER="aria2c"
[ "${1}" = "--aria-flags" ] && {
    ARIA_FLAGS=" ${ARIA_FLAGS} ${2} " && _parser_shift 
}
EOF

    ###################################################

    _parser_setup_flag "-o --oauth" 0
    _parser_setup_flag_help \
        "Use this flag to trigger oauth authentication.

Note: If both --oauth and --key flag is used, --oauth flag is preferred."

    _parser_setup_flag_preprocess 4<< 'EOF'
unset OAUTH_ENABLED ACCOUNT_NAME \
    ROOT_FOLDER ROOT_FOLDER_NAME CLIENT_ID CLIENT_SECRET REFRESH_TOKEN ACCESS_TOKEN ACCESS_TOKEN_EXPIRY INITIAL_ACCESS_TOKEN REFETCH_REFRESH_TOKEN
EOF

    _parser_setup_flag_process 4<< 'EOF'
export OAUTH_ENABLED="true"
EOF

    ###################################################

    _parser_setup_flag "--oauth-refetch-refresh-token" 0
    _parser_setup_flag_help \
        "Use this flag to trigger refetching of refresh token if existing refresh token is expired."

    _parser_setup_flag_preprocess 4<< 'EOF'
unset OAUTH_ENABLED ACCOUNT_NAME \
    ROOT_FOLDER ROOT_FOLDER_NAME CLIENT_ID CLIENT_SECRET REFRESH_TOKEN ACCESS_TOKEN ACCESS_TOKEN_EXPIRY INITIAL_ACCESS_TOKEN REFETCH_REFRESH_TOKEN
EOF

    _parser_setup_flag_process 4<< 'EOF'
export OAUTH_ENABLED="true" REFETCH_REFRESH_TOKEN="true"
EOF

    ###################################################

    _parser_setup_flag "-a --account" 1 required "account name"
    _parser_setup_flag_help \
        "Use a different account than the default one.

To change the default account name, use this format, -a/--account default=account_name"

    _parser_setup_flag_preprocess 4<< 'EOF'
unset OAUTH_ENABLED ACCOUNT_NAME ACCOUNT_ONLY_RUN CUSTOM_ACCOUNT_NAME UPDATE_DEFAULT_ACCOUNT
EOF

    _parser_setup_flag_process 4<< 'EOF'
export OAUTH_ENABLED="true" CUSTOM_ACCOUNT_NAME="${2##default=}"
[ -z "${2##default=*}" ] && export UPDATE_DEFAULT_ACCOUNT="_update_config"
_parser_shift
EOF

    ###################################################

    _parser_setup_flag "-la --list-accounts" 0
    _parser_setup_flag_help \
        "Print all configured accounts in the config files."

    _parser_setup_flag_preprocess 4<< 'EOF'
unset LIST_ACCOUNTS
EOF

    _parser_setup_flag_process 4<< 'EOF'
export LIST_ACCOUNTS="true"
EOF

    ###################################################

    _parser_setup_flag "-ca --create-account" 1 required "account name"
    _parser_setup_flag_help \
        "To create a new account with the given name if does not already exists."

    _parser_setup_flag_preprocess 4<< 'EOF'
unset OAUTH_ENABLED NEW_ACCOUNT_NAME
EOF

    _parser_setup_flag_process 4<< 'EOF'
export OAUTH_ENABLED="true"
export NEW_ACCOUNT_NAME="${2}" && _parser_shift 
EOF

    ###################################################

    _parser_setup_flag "-da --delete-account" 1 required "account name"
    _parser_setup_flag_help \
        "To delete an account information from config file."

    _parser_setup_flag_preprocess 4<< 'EOF'
unset DELETE_ACCOUNT_NAME
EOF

    _parser_setup_flag_process 4<< 'EOF'
export DELETE_ACCOUNT_NAME="${2}" && _parser_shift 
EOF

    ###################################################

    _parser_setup_flag "-k --key" 1 optional "API KEY"
    _parser_setup_flag_help \
        "To download with api key. If api key is not specified, then the predefined api key will be used.

To save your api key in config file, use gdl --key default=your api key.

API key will be saved in '${HOME}/.gdl.conf' and will be used from now on.

Note: If both --key and --key oauth is used, --oauth flag is preferred."

    _parser_setup_flag_preprocess 4<< 'EOF'
unset API_KEY_DOWNLOAD UPDATE_DEFAULT_API_KEY
export API_KEY="AIzaSyD2dHsZJ9b4OXuy5B_owiL8W18NaNOM8tk"
EOF

    _parser_setup_flag_process 4<< 'EOF'
export API_KEY_DOWNLOAD="true"
_API_KEY="${2##default=}"
# https://github.com/l4yton/RegHex#Google-Drive-API-Key
regex="AIza[0-9A-Za-z_-]{35}"
if [ -n "${_API_KEY}" ] && _assert_regex "${regex}" "${_API_KEY}"; then
    export API_KEY="${_API_KEY}" && _parser_shift 
    [ -z "${2##default=*}" ] && UPDATE_DEFAULT_API_KEY="_update_config"
fi
EOF

    ###################################################

    _parser_setup_flag "-c --config" 1 required "config file path"
    _parser_setup_flag_help \
        "Override default config file with custom config file.

Default: '${HOME}/.gdl.conf'"

    _parser_setup_flag_process 4<< 'EOF'
CONFIG="${2}" && _parser_shift 
EOF

    ###################################################

    _parser_setup_flag "-d --directory" 1 required "foldername"
    _parser_setup_flag_help \
        "To download given input in custom directory."

    _parser_setup_flag_preprocess 4<< 'EOF'
unset FOLDERNAME
EOF

    _parser_setup_flag_process 4<< 'EOF'
export FOLDERNAME="${2}" && _parser_shift 
EOF

    ###################################################

    _parser_setup_flag "-df --document-format" 1 required "document type"
    _parser_setup_flag_help \
        "Can be used for documents to be downloaded in different format, default is docx.

Available formats are: rtf, odt, html, pdf, epub, zip, docx, txt"

    _parser_setup_flag_preprocess 4<< 'EOF'
DOCUMENT_FORMAT_NAME="docx"
DOCUMENT_FORMAT="application/vnd.openxmlformats-officedocument.wordprocessingml.document"
DOCUMENT_FORMAT_ESCAPED="application%2Fvnd.openxmlformats-officedocument.wordprocessingml.document"
EOF

    _parser_setup_flag_process 4<< 'EOF'
case "${2}" in 
    rtf) DOCUMENT_FORMAT="application/rtf" DOCUMENT_FORMAT_ESCAPED="application%2Frtf" ;;
    odt) DOCUMENT_FORMAT="application/vnd.oasis.opendocument.text" DOCUMENT_FORMAT_ESCAPED="application%2Fvnd.oasis.opendocument.text" ;;
    html) DOCUMENT_FORMAT="text/html" DOCUMENT_FORMAT_ESCAPED="text%2Fhtml" ;;
    pdf) DOCUMENT_FORMAT="application/pdf" DOCUMENT_FORMAT_ESCAPED="application%2Fpdf" ;;
    epub) DOCUMENT_FORMAT="application/epub+zip" DOCUMENT_FORMAT_ESCAPED="application%2Fepub%2Bzip" ;;
    zip) DOCUMENT_FORMAT="application/zip" DOCUMENT_FORMAT_ESCAPED="application%2Fzip" ;;
    docx) DOCUMENT_FORMAT="application/vnd.openxmlformats-officedocument.wordprocessingml.document" DOCUMENT_FORMAT_ESCAPED="application%2Fvnd.openxmlformats-officedocument.wordprocessingml.document" ;;
    txt) DOCUMENT_FORMAT="text/plain" DOCUMENT_FORMAT_ESCAPED="text%2Fplain" ;;
    *) printf "\nError: Wrong document format.\nAvailable formats are: rtf, odt, pdf, epub, zip, docx, txt" && return 1 ;;
esac
export DOCUMENT_FORMAT_NAME="${2}" DOCUMENT_FORMAT DOCUMENT_FORMAT_ESCAPED && _parser_shift 
EOF

    ###################################################

    _parser_setup_flag "-dr --dry-run" 0
    _parser_setup_flag_help \
        "Just check if the url can be downloaded and exit the script."

    _parser_setup_flag_preprocess 4<< 'EOF'
unset DRY_RUN
EOF

    _parser_setup_flag_process 4<< 'EOF'
export DRY_RUN="true"
EOF

    ###################################################

    _parser_setup_flag "-s --skip-subdirs" 0
    _parser_setup_flag_help \
        "Skip downloading of sub folders present in case of folders."

    _parser_setup_flag_preprocess 4<< 'EOF'
unset SKIP_SUBDIRS
EOF

    _parser_setup_flag_process 4<< 'EOF'
export SKIP_SUBDIRS="true"
EOF

    ###################################################

    _parser_setup_flag "-p --parallel" 1 required "num of parallel downloads"
    _parser_setup_flag_help \
        "Download multiple files in parallel."

    _parser_setup_flag_preprocess 4<< 'EOF'
unset NO_OF_PARALLEL_JOBS PARALLEL_DOWNLOAD
EOF

    _parser_setup_flag_process 4<< 'EOF'
if [ "${2}" -gt 0 ] 2>| /dev/null 1>&2; then
    export NO_OF_PARALLEL_JOBS="${2}"
else
    printf "\nError: -p/--parallel accepts values between 1 to 10.\n"
    return 1
fi
export PARALLEL_DOWNLOAD="parallel"
_parser_shift
EOF

    ###################################################

    _parser_setup_flag "--proxy" 1 required "http://user:password@host:port"
    _parser_setup_flag_help \
        "Specify a proxy to use, should be in the format accepted by curl --proxy and aria2c --all-proxy flag."

    _parser_setup_flag_preprocess 4<< 'EOF'
unset PROXY
export ARIA_PROXY_FLAG="--all-proxy" CURL_PROXY_FLAG="--proxy"
EOF

    _parser_setup_flag_process 4<< 'EOF'
export PROXY="${2}" && _parser_shift 
EOF

    ###################################################

    _parser_setup_flag "--speed" 1 required "speed"
    _parser_setup_flag_help \
        "Limit the download speed, supported formats: 1K and 1M"

    _parser_setup_flag_preprocess 4<< 'EOF'
unset SPEED_LIMIT
export CURL_SPEED_LIMIT_FLAG="--limit-rate" ARIA_SPEED_LIMIT_FLAG="--max-download-limit"
EOF

    _parser_setup_flag_process 4<< 'EOF'
regex='^([0-9]+)([k,K]|[m,M])+$'
if _assert_regex "${regex}" "${2}"; then
    export SPEED_LIMIT="${2}" && _parser_shift 
else
    printf "Error: Wrong speed limit format, supported formats: 1K and 1M.\n" 1>&2
    return 1
fi
EOF

    ###################################################

    _parser_setup_flag "-ua --user-agent" 1 required "user agent string"
    _parser_setup_flag_help \
        "Specify custom user agent."

    _parser_setup_flag_preprocess 4<< 'EOF'
unset USER_AGENT
export USER_AGENT_FLAG="--user-agent" # common for both curl and aria2c
EOF

    _parser_setup_flag_process 4<< 'EOF'
export USER_AGENT="${2}" && shift
EOF

    ###################################################

    _parser_setup_flag "-R --retry" 1 required "num of retries"
    _parser_setup_flag_help \
        "Retry the file upload if it fails, postive integer as argument. Currently only for file uploads."

    _parser_setup_flag_preprocess 4<< 'EOF'
unset RETRY
EOF

    _parser_setup_flag_process 4<< 'EOF'
if [ "$((2))" -gt 0 ] 2>| /dev/null 1>&2; then
    export RETRY="${2}" && _parser_shift 
else
    printf "Error: -R/--retry only takes positive integers as arguments, min = 1, max = infinity.\n"
    return 1
fi
EOF

    ###################################################

    _parser_setup_flag "-in --include" 1 required "pattern"
    _parser_setup_flag_help \
        "Only download the files which contain the given pattern - Applicable for folder downloads.

e.g: ${0##*/} local_folder --include 1, will only include with files with pattern 1 in the name. Regex can be used which works with grep -E command."

    _parser_setup_flag_preprocess 4<< 'EOF'
unset INCLUDE_FILES 
EOF

    _parser_setup_flag_process 4<< 'EOF'
export INCLUDE_FILES="${INCLUDE_FILES:+${INCLUDE_FILES}|}${2}" && _parser_shift 
EOF

    ###################################################

    _parser_setup_flag "-ex --exclude" 1 required "pattern"
    _parser_setup_flag_help \
        "Only download the files which does not contain the given pattern - Applicable for folder downloads.

e.g: ${0##*/} local_folder --exclude 1, will only include with files with pattern 1 not present in the name. Regex can be used which works with grep -E command."

    _parser_setup_flag_preprocess 4<< 'EOF'
unset EXCLUDE_FILES
EOF

    _parser_setup_flag_process 4<< 'EOF'
export EXCLUDE_FILES="${EXCLUDE_FILES:+${EXCLUDE_FILES}|}${2}" && _parser_shift 
EOF

    ###################################################

    _parser_setup_flag "-l --log" 1 required "file to save info"
    _parser_setup_flag_help \
        "Save downloaded files info to the given filename."

    _parser_setup_flag_preprocess 4<< 'EOF'
unset LOG_FILE_ID
EOF

    _parser_setup_flag_process 4<< 'EOF'
export LOG_FILE_ID="${2}" && _parser_shift 
EOF

    ###################################################

    _parser_setup_flag "-q --quiet" 0
    _parser_setup_flag_help \
        "Supress the normal output, only show success/error upload messages for files, and one extra line at the beginning for folder showing no. of files and sub folders."

    _parser_setup_flag_preprocess 4<< 'EOF'
unset QUIET
EOF

    _parser_setup_flag_process 4<< 'EOF'
export QUIET="_print_center_quiet"
EOF

    ###################################################

    _parser_setup_flag "--verbose" 0
    _parser_setup_flag_help \
        "Display detailed message (only for non-parallel uploads)."

    _parser_setup_flag_preprocess 4<< 'EOF'
unset VERBOSE
EOF

    _parser_setup_flag_process 4<< 'EOF'
export VERBOSE="true" CURL_PROGRESS=""
EOF

    ###################################################

    _parser_setup_flag "--skip-internet-check" 0
    _parser_setup_flag_help \
        "Do not check for internet connection, recommended to use in sync jobs."

    _parser_setup_flag_preprocess 4<< 'EOF'
unset SKIP_INTERNET_CHECK
EOF

    _parser_setup_flag_process 4<< 'EOF'
SKIP_INTERNET_CHECK=":"
EOF

    ###################################################

    _parser_setup_flag "-V --version --info" 0
    _parser_setup_flag_help \
        "Show detailed info, only if script is installed system wide."

    _parser_setup_flag_preprocess 4<< 'EOF'
###################################################
# Print info if installed
###################################################
_version_info() {
    export COMMAND_NAME REPO INSTALL_PATH TYPE TYPE_VALUE
    if command -v "${COMMAND_NAME}" 1> /dev/null && [ -n "${REPO:+${COMMAND_NAME:+${INSTALL_PATH:+${TYPE:+${TYPE_VALUE}}}}}" ]; then
        for i in REPO INSTALL_PATH INSTALLATION TYPE TYPE_VALUE LATEST_INSTALLED_SHA CONFIG; do
            value_version_info=""
            _set_value i value_version_info "${i}"
            printf "%s\n" "${i}=${value_version_info}"
        done | sed -e "s/=/: /g"
    else
        printf "%s\n" "gdrive-downloader is not installed system wide."
    fi
    exit 0
}
EOF

    _parser_setup_flag_process 4<< 'EOF'
_version_info
EOF

    ###################################################

    _parser_setup_flag "-D --debug" 0
    _parser_setup_flag_help \
        "Display script command trace."

    _parser_setup_flag_preprocess 4<< 'EOF'
unset DEBUG
EOF

    _parser_setup_flag_process 4<< 'EOF'
export DEBUG="true"
EOF

    ###################################################

    _parser_setup_flag "-h --help" 1 optional "flag name"
    _parser_setup_flag_help \
        "Print help for all flags and basic usage instructions.

To see help for a specific flag, --help flag_name ( with or without dashes )
    e.g: ${0##*/} --help aria
Can also specify multiple flag names
    e.g: ${0##*/} --help config list-account"

    _parser_setup_flag_preprocess 4<< 'EOF'
###################################################
# 1st arg - can be flag name
# if 1st arg given, print specific flag help
# otherwise print full help
###################################################
_usage() {
    [ -n "${1}" ] && {
        for flag_usage in "${@}"; do
            help_usage_usage=""
            _flag_help "${flag_usage}" help_usage_usage

            if [ -z "${help_usage_usage}" ]; then
                printf "%s\n" "Error: No help found for ${flag_usage}"
            else
                printf "%s\n%s\n%s\n" "${__PARSER_BAR}" "${help_usage_usage}" "${__PARSER_BAR}"
            fi
        done
        exit 0
    }

    printf "%s\n" "${_PARSER_ALL_HELP}"
    exit 0
}
EOF

    _parser_setup_flag_process 4<< 'EOF'
shift 1 && _usage "${@}"
EOF
    ###################################################

    # should be only available if installed using install script
    [ "${GDL_INSTALLED_WITH:-}" = script ] && {
        _parser_setup_flag "-u --update" 0
        _parser_setup_flag_help \
            "Update the installed script in your system."

        _parser_setup_flag_process 4<< 'EOF'
_check_debug && _update && { exit 0 || exit 1; }
EOF

        #########################

        _parser_setup_flag "--uninstall" 0
        _parser_setup_flag_help \
            "Uninstall script, remove related files."

        _parser_setup_flag_process 4<< 'EOF'
_check_debug && _update uninstall && { exit 0 || exit 1; }
EOF
    }

    ###################################################
    return 0
}
