#!/bin/sh
#
#SPDX-License-Identifier: GPL-3.0-or-later
#myMPD (c) 2020-2026 Juergen Mang <mail@jcgames.de>
#https://github.com/jcorporation/mympd

#exit on error
set -e

#exit on undefined variable
set -u

#print out commands
[ -z "${DEBUG+x}" ] || set -x

#get action
if [ -z "${1+x}" ]
then
  ACTION=""
else
  ACTION="$1"
fi

#save script path and change to it
STARTPATH=$(dirname "$(realpath "$0")")
cd "$STARTPATH" || exit 1

#set umask
umask 0022

build_doc() {
  DOC_DEST=$1
  install -d "$DOC_DEST" || return 1
  sphinx-build -M html docs "$DOC_DEST"
}

lint_doc() {
  echo "Running sphinx-lint"
  sphinx-lint docs || return 1
  return 0
}

serve_doc() {
  DOC_DEST=$1
  sphinx-autobuild -M html docs "$DOC_DEST"
}

case "$ACTION" in
  build)
    if [ -z "${2+x}" ]
    then
      echo "Usage: $0 $1 <destination folder>"
      exit 1
    fi
    build_doc "$2"
    ;;
  lint)
    lint_doc
  ;;
  serve)
    if [ -z "${2+x}" ]
    then
      echo "Usage: $0 $1 <destination folder>"
      exit 1
    fi
    build_doc "$2"
    serve_doc "$2"
    ;;
  *)
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  build:        Generates the html documentation."
    echo "  lint:         Check for valid reStructuredText in the docs folder."
    echo "  serve:        Generates the html documentation and runs a development server."
    echo ""
    echo "Requires: sphinx, sphinx-lint, sphinx-book-theme, sphinx-copybutton"
    exit 1
  ;;
esac

exit 0
