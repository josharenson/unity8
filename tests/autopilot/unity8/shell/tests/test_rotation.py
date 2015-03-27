# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Unity Autopilot Test Suite
# Copyright (C) 2015 Canonical
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

"""Tests for shell-rotation"""

from autopilot.platform import model
from unity8 import (
    shell,
    fixture_setup,
    indicators,
    process_helpers
)
import os
from unity8.shell import tests
import ubuntuuitoolkit
import logging
from testtools.matchers import Equals, NotEquals
from autopilot.utilities import sleep

logger = logging.getLogger(__name__)

class RotationBase(tests.UnityTestCase):
    """Base class for all shell-rotation tests that provides helper methods."""

    scenarios = tests._get_device_emulation_scenarios()

    def setUp(self):
        if model() == 'Desktop':
            self.skipTest('Test cannot be run on the desktop.')
        super(RotationBase, self).setUp()
        self._qml_mock_enabled = False
        self._data_dirs_mock_enabled = False

        # get unity8 with fake sensors running 
        unity_with_sensors = fixture_setup.LaunchUnityWithFakeSensors()
        self.useFixture(unity_with_sensors)
        process_helpers.unlock_unity(unity_with_sensors.unity_proxy)
        self.fake_sensors = unity_with_sensors.fake_sensors
        #unity_with_sensors.main_win.print_tree()
        self.shell_proxy = unity_with_sensors.main_win.select_single('Shell')
        self.oriented_shell_proxy = unity_with_sensors.main_win.select_single('OrientedShell')

    def _create_test_application(self):
        desktop_file_dict = ubuntuuitoolkit.fixture_setup.DEFAULT_DESKTOP_FILE_DICT
        desktop_file_dict.update({'X-Ubuntu-Single-Instance': 'true'})
        fake_application = ubuntuuitoolkit.fixture_setup.FakeApplication(
            desktop_file_dict=desktop_file_dict)
        self.useFixture(fake_application)
        return (
            fake_application.qml_file_path, fake_application.desktop_file_path)

    def _launch_fake_app(self):
        _, desktop_file_path = self._create_test_application()
        desktop_file_name = os.path.basename(desktop_file_path)
        application_name, _ = os.path.splitext(desktop_file_name)
        self.launch_upstart_application(application_name)
        return application_name

    def _assert_change_of_orientation_and_angle(self):
        tmp_o = self.shell_proxy.orientation
        tmp_a = self.shell_proxy.orientationAngle
        print("default orientation: ", self.orientation, ", current orientation: ", tmp_o)
        print("default angle: ", self.angle, ", current angle: ", tmp_a)
        self.assertThat(self.orientation, Equals(tmp_o))
        self.assertThat(self.angle, Equals(tmp_a))

    def test_fake_sensor(self):
        self.fake_sensors.set_orientation_top_up()
        self.orientation = 1
        self.angle = 0
        sleep(10);
        self.assertThat(self.oriented_shell_proxy.physicalOrientation, Equals(self.orientation))

        self.fake_sensors.set_orientation_right_up()
        self.orientation = 8
        self.angle = 90
        sleep(10);
        self.assertThat(self.oriented_shell_proxy.physicalOrientation, Equals(self.orientation))

        self.fake_sensors.set_orientation_top_down()
        self.orientation = 4
        self.angle = 180
        sleep(10);
        self.assertThat(self.oriented_shell_proxy.physicalOrientation, Equals(self.orientation))

        self.fake_sensors.set_orientation_left_up()
        self.orientation = 2
        self.angle = 270
        sleep(10);
        self.assertThat(self.oriented_shell_proxy.physicalOrientation, Equals(self.orientation))

    def test_rotation(self):
        """Do an orientation-change and verify that an app and the shell adapted correctly"""

        # launch an application
        app_name = self._launch_fake_app()

        # get default orientation and angle
        self.orientation = self.shell_proxy.orientation
        self.angle = self.shell_proxy.orientationAngle

        # check if fake sensors affect orientation and angle
        self.fake_sensors.set_orientation_top_up()
        self.orientation = 1
        self.angle = 0
        sleep(10);
        print("\nafter fake-sensor changed to top-up...")
        self._assert_change_of_orientation_and_angle()

        self.fake_sensors.set_orientation_right_up()
        self.orientation = 8
        self.angle = 90
        sleep(10);
        print("\nafter fake-sensor changed to right-up...")
        self._assert_change_of_orientation_and_angle()

        self.fake_sensors.set_orientation_top_down()
        self.orientation = 4
        self.angle = 180
        sleep(10);
        print("\nafter  top-down...")
        self._assert_change_of_orientation_and_angle()

        self.fake_sensors.set_orientation_left_up()
        self.orientation = 2
        self.angle = 270
        sleep(10);
        print("\nafter fake-sensor changed to left-up...")
        self._assert_change_of_orientation_and_angle()

        # set accelerometer sensor rotation from 0 to 90

        # check that unity8 rotated its UI form 0 (portrait aspect ratio) to 90 (landscape aspect ratio)

        # check that the application got resized from a portrait aspect ratio to a landscape aspect ratio
