#!/bin/bash
########################################
# Usage
########################################

usage() {
	cat <<-EOF
		Usage: $(basename-git "$0") [command] [dryrun]

		This script automates semantic versioning. Requires a valid change log at CHANGELOG.md.

		See https://github.com/markchalloner/git-semver for more detail.

		Commands
		 get                                                   Gets the current version (tag)
		 major [--dryrun] [-p <pre-release>] [-b <build>]      Generates a tag for the next major version and echos to the screen
		 minor [--dryrun] [-p [<pre-release> [-b <build>]      Generates a tag for the next minor version and echos to the screen
		 patch|next [--dryrun] [-p <pre-release>] [-b <build>] Generates a tag for the next patch version and echos to the screen
		 pre-release [--dryrun] -p <pre-release> [-b <build>]  Generates a tag for a pre-release version and echos to the screen
		 build [--dryrun] -b <build>                           Generates a tag for a build and echos to the screen
		 help                                                  This message

		 dryrun     only returns next version. Don't actually tag the repository

	EOF
	exit
}

########################################
# Helper functions
########################################

function basename-git() {
    basename "$1" | tr '-' ' ' | sed 's/.sh$//g'
}

########################################
# Plugin functions
########################################

plugin-output() {
    local type="$1"
    local name="$2"
    local output=
    while IFS='' read -r line
    do
        if [ -z "${output}" ]
        then
            echo -e "\n$type plugin \"$name\":\n"
            output=1
        fi
        echo "  $line"
    done
}

plugin-list() {
    local types=("User" "Project")
    local dirs=("${DIR_HOME}" "${DIR_ROOT}")
    local plugin_dir=
    local plugin_type=
    local total=${#dirs[*]}
    for (( i=0; i <= $((total-1)); i++ ))
    do
        plugin_type=${types[${i}]}
        plugin_dir="${dirs[${i}]}/.git-semver/plugins"
        if [ -d "${plugin_dir}" ]
        then
            find "${plugin_dir}" -maxdepth 1 -type f -exec echo "${plugin_type},{}" \;
        fi
    done
}

plugin-run() {
    # shellcheck disable=SC2155
    local plugins="$(plugin-list)"
    local version_new="$1"
    local version_current="$2"
    local status=0
    local type=
    local typel=
    local path=
    local name=
    for i in ${plugins}
    do
        type=${i%%,*}
        typel=$(echo "${type}" | tr '[:upper:]' '[:lower:]')
        path=${i##*,}
        name=$(basename "${path}")
        ${path} "${version_new}" "${version_current}" "${GIT_HASH}" "${GIT_BRANCH}" "${DIR_ROOT}" 2>&1 |
            plugin-output "${type}" "${name}"
        RETVAL=${PIPESTATUS[0]}
        case ${RETVAL} in
            0)
                ;;
            111|1)
                echo -e "\nError: Warning from ${typel} plugin \"${name}\", ignoring"
                ;;
            112)
                echo -e "\nError: Error from ${typel} plugin \"${name}\", unable to version"
                status=1
                ;;
            113)
                echo -e "\nError: Fatal error from ${typel} plugin \"${name}\", unable to version, quitting immediately"
                return 1
                ;;
            *)
                echo -e "\nError: Unknown error from ${typel} plugin \"${name}\", ignoring"
        esac
    done
    return ${status}
}

plugin-debug() {
    # shellcheck disable=SC2155
    local version=$(version-get)
    # shellcheck disable=SC2155
    local major=$(version-parse-major "${version}")
    # shellcheck disable=SC2155
    local minor=$(version-parse-minor "${version}")
    # shellcheck disable=SC2155
    local patch=$(version-parse-patch "${version}")
    if [ "" == "$version" ]
    then
        local new=0.1.0
    else
        local new=${major}.${minor}.$((patch+1))
    fi
    plugin-run "$new" "$version"
}

validate-pre-release() {
    local pre_release=$1
    if ! [[ "$pre_release" =~ ^[0-9A-Za-z.-]*$ ]] || # Not alphanumeric, `-` and `.`
        [[ "$pre_release" =~ (^|\.)\. ]] ||          # Empty identifiers
        [[ "$pre_release" =~ \.(\.|$) ]] ||          # Empty identifiers
        [[ "$pre_release" =~ \.0[0-9] ]]             # Leading zeros
    then
        echo "Error: pre-release is not valid."
        exit 1
    fi
}

validate-build() {
    local build=$1
    if ! [[ "$build" =~ ^[0-9A-Za-z.-]*$ ]] || # Not alphanumeric, `-` and `.`
        [[ "$build" =~ (^|\.)\. ]] ||          # Empty identifiers
        [[ "$build" =~ \.(\.|$) ]]             # Empty identifiers
    then
        echo "Error: build metadata is not valid."
        exit 1
    fi
}

########################################
# Version functions
########################################

version-parse-major() {
    echo "$1" | cut -d "." -f1 | sed "s/^${VERSION_PREFIX}//g"
}

version-parse-minor() {
    echo "$1" | cut -d "." -f2
}

version-parse-patch() {
    echo "$1" | cut -d "." -f3 | sed 's/[-+].*$//g'
}

version-parse-pre-release() {
    echo "$1" | cut -d "." -f3 | grep -o '\-[0-9A-Za-z.]\+'
}

version-get() {

    # shellcheck disable=SC2155
    local version=""

    if [[ $GIT_BRANCH = "release/"* ]]; then
      if [[ ! -f current-version ]]; then
        echo "Cannot find current-version at the root of this repository. Please create a file with the proper semver version and re-execute this command"
        exit -1
      fi
        local version=$(cat current-version | grep "^${VERSION_PREFIX}[0-9]\+\.[0-9]\+\.[0-9]\+$" | sed "s/^${VERSION_PREFIX}//" | sort -t. -k 1,1n -k 2,2n -k 3,3n | tail -1)
      else
        local version=$(git tag $TAG_LIST_OPT| grep "^${VERSION_PREFIX}[0-9]\+\.[0-9]\+\.[0-9]\+$" | sed "s/^${VERSION_PREFIX}//" | sort -t. -k 1,1n -k 2,2n -k 3,3n | tail -1)
    fi
    if [ "" == "${version}" ]
    then
        return 1
    else
        echo "${version}"
    fi
}

version-major() {
    local pre_release=${1:+-$1}
    local build=${2:++$2}
    # shellcheck disable=SC2155
    local version=$(version-get)
    # shellcheck disable=SC2155
    local major=$(version-parse-major "${version}")
    if [ "" == "$version" ]
    then
        local new=${VERSION_PREFIX}1.0.0${pre_release}${build}
    else
        local new=${VERSION_PREFIX}$((major+1)).0.0${pre_release}${build}
    fi
    version-do "$new" "$version"
}

version-minor() {
    local pre_release=${1:+-$1}
    local build=${2:++$2}
    # shellcheck disable=SC2155
    local version=$(version-get)
    # shellcheck disable=SC2155
    local major=$(version-parse-major "${version}")
    # shellcheck disable=SC2155
    local minor=$(version-parse-minor "${version}")
    if [ "" == "$version" ]
    then
        local new=${VERSION_PREFIX}0.1.0${pre_release}${build}
    else
        local new=${VERSION_PREFIX}${major}.$((minor+1)).0${pre_release}${build}
    fi
    version-do "$new" "$version"
}

version-patch() {
    local pre_release=${1:+-$1}
    local build=${2:++$2}
   # shellcheck disable=SC2155
    local version=$(version-get)
    # shellcheck disable=SC2155
    local major=$(version-parse-major "${version}")
    # shellcheck disable=SC2155
    local minor=$(version-parse-minor "${version}")
    # shellcheck disable=SC2155
    local patch=$(version-parse-patch "${version}")
    if [ "" == "$version" ]
    then
        local new=${VERSION_PREFIX}0.1.0${pre_release}${build}
    else
        local new=${VERSION_PREFIX}${major}.${minor}.$((patch+1))${pre_release}${build}
    fi
    version-do "$new" "$version"
}

version-pre-release() {
    local pre_release=$1
    local build=${2:++$2}
    # shellcheck disable=SC2155
    local version=$(version-get)
    # shellcheck disable=SC2155
    local major=$(version-parse-major "${version}")
    # shellcheck disable=SC2155
    local minor=$(version-parse-minor "${version}")
    # shellcheck disable=SC2155
    local patch=$(version-parse-patch "${version}")
    if [ "" == "$version" ]
    then
        local new=${VERSION_PREFIX}0.1.0-${pre_release}${build}
    else
        local new=${VERSION_PREFIX}${major}.${minor}.${patch}-${pre_release}${build}
    fi
    version-do "$new" "$version"
}

version-build() {
    local build=$1
    # shellcheck disable=SC2155
    local version=$(version-get)
    # shellcheck disable=SC2155
    local major=$(version-parse-major "${version}")
    # shellcheck disable=SC2155
    local minor=$(version-parse-minor "${version}")
    # shellcheck disable=SC2155
    local patch=$(version-parse-patch "${version}")
    # shellcheck disable=SC2155
    local pre_release=$(version-parse-pre-release "${version}")
    if [ "" == "$version" ]
    then
        local new=${VERSION_PREFIX}0.1.0${pre_release}+${build}
    else
        local new=${VERSION_PREFIX}${major}.${minor}.${patch}${pre_release}+${build}
    fi
    version-do "$new" "$version"
}

version-do() {
    local new="$1"
    local version="$2"
	if [[ $DRY_RUN == "true" ]]; then
		echo $new
		return 1
	fi
    local sign="${GIT_SIGN:-0}"
    local cmd="git tag"
    if [ "$sign" == "1" ]
    then
        cmd="$cmd -as -m $new"
    fi
    if [ $dryrun == 1 ]
    then
        echo "$new"
    elif plugin-run "$new" "$version"
    then
        $cmd "$new" && echo "$new"
    fi
}

########################################
# Run
########################################

# Set home
readonly DIR_HOME="${HOME}"

# Use XDG Base Directories if possible
# (see http://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html)
DIR_CONF="${XDG_CONFIG_HOME:-${HOME}}/.git-semver"

# Set vars
DIR_ROOT="$(git rev-parse --show-toplevel 2> /dev/null)"

# Set (and load) user config
if [ -f "${DIR_ROOT}/.git-semver" ]
then
    FILE_CONF="${DIR_ROOT}/.git-semver"
    source "${FILE_CONF}"
elif [ -f "${DIR_CONF}/config" ]
then
    FILE_CONF="${DIR_CONF}/config"
    # shellcheck source=config.example
    source "${FILE_CONF}"
else
    # No existing config file was found; use default
    FILE_CONF="${DIR_HOME}/.git-semver/config"
fi

GIT_HASH="$(git rev-parse HEAD 2> /dev/null)"
GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2> /dev/null)"

if [[ $GIT_BRANCH != master && $GIT_BRANCH != main ]]; then
  TAG_LIST_OPT="--merged $GIT_BRANCH"
fi

DRY_RUN=""
if [[ $2 == "dryrun" ]]; then
	DRY_RUN=true
fi

# Set $1 to last argument.
for _; do true; done

case "$action" in
    get)
        version-get
        ;;
    major)
        version-major "$pre_release" "$build"
        ;;
    minor)
        version-minor "$pre_release" "$build"
        ;;
    patch|next)
        version-patch "$pre_release" "$build"
        ;;
    pre-release)
        [ -n "$pre_release" ] || usage
        version-pre-release "$pre_release" "$build"
        ;;
    build)
        [ -n "$build" ] || usage
        version-build "$build"
        ;;
    debug)
        plugin-debug
        ;;
    help)
        usage
        ;;
    *)
        usage
        ;;
esac


