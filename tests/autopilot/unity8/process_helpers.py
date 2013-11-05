# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Unity Autopilot Utilities
# Copyright (C) 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

from autopilot.introspection import (
    get_proxy_object_for_existing_process,
    ProcessSearchError,
)
import subprocess
from unity8.shell.emulators import UnityEmulatorBase
from unity8.shell.emulators.main_window import MainWindow


class CannotAccessUnity(Exception):
    pass


def unlock_unity():
    """Helper function that attempts to unlock the unity greeter.

    :raises RuntimeError: if the greeter attempts and fails to be unlocked.

    :raises RuntimeWarning: when the greeter cannot be found because it is
      already unlocked.
    :raises CannotAccessUnity: if unity is not introspectable or cannot be
      found on dbus.
    :raises CannotAccessUnity: if unity's upstart status is not "start" or the
      upstart job cannot be found at all.

    """
    pid = _get_unity_pid()
    try:
        unity = get_proxy_object_for_existing_process(
            pid=pid,
            emulator_base=UnityEmulatorBase,
        )
        main_window = MainWindow(unity)

        greeter = main_window.get_greeter()
        if greeter is None:
            raise RuntimeWarning("Greeter appears to be already unlocked.")
        greeter.swipe()
    except ProcessSearchError as e:
        raise CannotAccessUnity(
            "Cannot introspect unity, make sure that it has been started "
            "with testability. Perhaps use the function "
            "'restart_unity_with_testability' this module provides."
            "(%s)"
            % str(e)
        )


def restart_unity_with_testability():
    """Restarts (or just starts) unity8 with the testability driver loaded

    :raises subprocess.CalledProcessError: if unable to stop or start the
      unity8 upstart job.

    """
    status = _get_unity_status()
    if "start/" in status:
        try:
            print("Stopping unity.")
            subprocess.check_call([
                'initctl',
                'stop',
                'unity8',
            ])
        except subprocess.CalledProcessError as e:
            e.args += ("Failed to stop running instance of unity8", )
            raise

    try:
        print("Starting unity with testability.")
        subprocess.check_call([
            'initctl',
            'start',
            'unity8',
            'QT_LOAD_TESTABILITY=1',
        ])
    except subprocess.CalledProcessError as e:
        e.args += ("Failed to start unity8 with testability ", )
        raise


def _get_unity_status():
    try:
        return subprocess.check_output([
            'initctl',
            'status',
            'unity8'
        ])
    except subprocess.CalledProcessError as e:
        raise CannotAccessUnity("Unable to get unity's status: %s" % str(e))


def _get_unity_pid():
    status = _get_unity_status()
    if not "start/" in status:
        raise CannotAccessUnity("Unity is not in the running state.")
    return int(status.split()[-1])
