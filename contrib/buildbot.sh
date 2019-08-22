#! /bin/sh

. $VENV_PATH/bin/activate
exec buildbot "$@"
