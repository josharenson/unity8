#!/bin/sh

# log all commands and abort on error
set -xe

SHELL_QML_PATH=$(pkg-config --variable=plugindir unity-shell-api)
UNITY_SOURCE_DIR=$(readlink -f $(dirname $(readlink -f $0))/../..)

dh_auto_configure -- -DCMAKE_INSTALL_LOCALSTATEDIR="/var" \
                     -DARTIFACTS_DIR=${ADT_ARTIFACTS} \
                     -DUNITY_PLUGINPATH=${SHELL_QML_PATH} \
                     -DUNITY_MOCKPATH=${SHELL_QML_PATH}/mocks
dh_auto_build --parallel -- -C tests/mocks
dh_auto_build --parallel -- -C tests/plugins
dh_auto_build --parallel -- -C tests/qmltests
dh_auto_build --parallel -- -C tests/uqmlscene
dh_auto_build --parallel -- -C tests/utils

export UNITY_SOURCE_DIR

# FIXME: Re-enable parallel qmltests. Temporarily disabled because of freezes in testShell on CI.
#dh_auto_build --parallel -- -k xvfballtests
dh_auto_build -- -k xvfballtests
