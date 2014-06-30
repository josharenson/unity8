#!/bin/sh

. /etc/environment
export QML2_IMPORT_PATH

QML_PHONE_SHELL_PATH=./builddir/src/unity8
GDB=false
FAKE=false
PINLOCK=false
KEYLOCK=false
MOUSE_TOUCH=true

usage() {
    echo "usage: "$0" [OPTIONS]\n" >&2
    echo "Script to run the shell.\n" >&2
    echo "OPTIONS:" >&2
    echo " -f, --fake Force use of fake Qml modules." >&2
    echo " -p, --pinlock Use a pin protected user." >&2
    echo " -k, --keylock Use a passphrase protected user." >&2
    echo " -g, --gdb Run through gdb." >&2
    echo " -h, --help Show this help." >&2
    echo " -m, --nomousetouch Run without -mousetouch argument." >&2
    echo >&2
    exit 1
}

ARGS=`getopt -n$0 -u -a --longoptions="fake,pinlock,keylock,gdb,help,nomousetouch" -o "fpkghm" -- "$@"`
[ $? -ne 0 ] && usage
eval set -- "$ARGS"

while [ $# -gt 0 ]
do
    case "$1" in
       -f|--fake)  FAKE=true;;
       -p|--pinlock)  PINLOCK=true;;
       -k|--keylock)  KEYLOCK=true;;
       -g|--gdb)   GDB=true;;
       -h|--help)  usage;;
       -m|--nomousetouch)  MOUSE_TOUCH=false;;
       --)         shift;break;;
    esac
    shift
done

if $FAKE; then
  export QML2_IMPORT_PATH=$QML2_IMPORT_PATH:$PWD/builddir/tests/mocks:$PWD/builddir/plugins:$PWD/builddir/modules
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PWD/builddir/tests/mocks/LightDM/single
fi

if $PINLOCK; then
  export QML2_IMPORT_PATH=$QML2_IMPORT_PATH:$PWD/builddir/tests/mocks:$PWD/builddir/plugins:$PWD/builddir/modules
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PWD/builddir/tests/mocks/LightDM/single-pin
fi

if $KEYLOCK; then
  export QML2_IMPORT_PATH=$QML2_IMPORT_PATH:$PWD/builddir/tests/mocks:$PWD/builddir/plugins:$PWD/builddir/modules
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PWD/builddir/tests/mocks/LightDM/single-passphrase
fi

# Force icon theme if running on the desktop, otherwise gnome theme (if running
# on Ubuntu Desktop) will be used and icons won't be found
if [ -n "$DESKTOP_SESSION" ]; then
  export UBUNTU_ICON_THEME=ubuntu-mobile
fi

QML_PHONE_SHELL_ARGS=""
if $MOUSE_TOUCH; then
  QML_PHONE_SHELL_ARGS="$QML_PHONE_SHELL_ARGS -mousetouch"
fi

control_c()
{
  /sbin/initctl stop unity8
  exit $?
}

trap control_c INT

if $GDB; then
  gdb -ex run --args $QML_PHONE_SHELL_PATH $QML_PHONE_SHELL_ARGS $@
else
  status=`/sbin/initctl status unity8`
  if [ "$status" != "unity8 stop/waiting" ]; then
    echo "Unity8 is already running, please stop it first"
    exit 1
  fi
  /sbin/initctl start unity8 BINARY="`readlink -f $QML_PHONE_SHELL_PATH` $QML_PHONE_SHELL_ARGS $@" QML2_IMPORT_PATH=$QML2_IMPORT_PATH LD_LIBRARY_PATH=$LD_LIBRARY_PATH
  tailf -n 0 ~/.cache/upstart/unity8.log
fi
