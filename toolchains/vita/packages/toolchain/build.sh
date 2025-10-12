#! /bin/sh

VITA_VERSION=2.535

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

# Compute the URL (containing the date of build) from the Github API
# Use sed as a poor man's JSON parser
url=$(curl -s "https://api.github.com/repos/vitasdk/autobuilds/releases/tags/master-linux-v$VITA_VERSION" | sed -ne 's/^.*"browser_download_url" *: *"\([^"]\+\)".*$/\1/p')

do_http_fetch vitasdk "$url" 'tar xjf'

cp -a . $DESTDIR/$VITASDK

do_clean_bdir
