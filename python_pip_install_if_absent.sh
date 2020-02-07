#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-15 13:56:24 +0000 (Fri, 15 Feb 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Avoids trying to install / upgrade pip modules that have been installed with system packages to avoid errors like the following:
#
# Cannot uninstall 'beautifulsoup4'. It is a distutils installed project and thus we cannot accurately determine which files belong to it which would lead to only a partial uninstall.

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

python="${PYTHON:-python}"

usage(){
    echo "Installs Python PyPI modules not already installed using Pip"
    echo
    echo "Leverages adjacent python_pip_install.sh which takes in to account library paths, virtual envs etc"
    echo
    echo "Takes a list of python module names as arguments or .txt files containing lists of modules (one per line)"
    echo
    echo "usage: ${0##*} <list_of_modules>"
    echo
    exit 3
}

for arg; do
    case "$arg" in
        -*) usage
            ;;
    esac
done

pip_modules=""

process_args(){
    for arg; do
        if [ -f "$arg" ]; then
            echo "adding pip modules from file:  $arg"
            pip_modules="$pip_modules $(sed 's/#.*//;/^[[:space:]]*$$/d' "$arg")"
            echo
        else
            pip_modules="$pip_modules $arg"
        fi
    done
}

if [ -n "${*:-}" ]; then
    process_args "$@"
else
    # shellcheck disable=SC2046
    process_args $(cat)
fi

if [ -z "${pip_modules// }" ]; then
    usage
fi

pip_modules="$(tr ' ' ' \n' <<< "$pip_modules" | sort -u | tr '\n' ' ')"

echo "Installing Python PyPI Modules that are not already installed"
echo

for pip_module in $pip_modules; do
    python_module="$("$srcdir/python_module_to_import_name.sh" <<< "$pip_module")"

    # pip module often pull in urllib3 which result in errors like the following so ignore it
    #:
    # Cannot uninstall 'urllib3'. It is a distutils installed project and thus we cannot accurately determine which files belong to it which would lead to only a partial uninstall.
    #
    #echo "checking if python module '$python_module' is installed"
    if "$python" -c "import $python_module" &>/dev/null; then
        echo "python module '$python_module' already installed, skipping..."
    else
        echo "installing python module '$python_module'"
        echo
        "$srcdir/python_pip_install.sh" "$pip_module"
    fi
done
