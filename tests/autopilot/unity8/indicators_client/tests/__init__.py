# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""indicators-client autopilot tests."""

import os.path

from autopilot.input import Mouse, Touch, Pointer
from autopilot.testcase import AutopilotTestCase
from autopilot.matchers import Eventually
from autopilot.platform import model
from testtools.matchers import Equals

from unity8 import get_binary_path
from unity8.indicators_client.emulators.main_window import MainWindow
from logging import getLogger
import sys
from time import sleep

log = getLogger(__name__)

class FormFactors(object):
    Phone, Tablet, Desktop = range(3)

class IndicatorsTestCase(AutopilotTestCase):

    """A common test case class that provides several useful methods for indicator tests."""

    geometry = None
    grid_unit = None

    if model() == 'Desktop':
        scenarios = [
        ('with mouse', dict(input_device_class=Mouse, geometry="400x800", grid_unit="12")),
        ]
    else:
        scenarios = [
        ('with touch', dict(input_device_class=Touch)),
        ]

    def setUp(self, geometry, grid_size):
        self.pointing_device = Pointer(self.input_device_class.create())
        super(IndicatorsTestCase, self).setUp()
        if grid_size is not None:
            self.patch_environment("GRID_UNIT_PX", str(grid_size))
            self.grid_size = int(grid_size)
        else:
            self.grid_size = int(os.getenv('GRID_UNIT_PX'))

        if os.path.realpath(__file__).startswith("/usr/"):
            self.launch_test_installed(geometry)
        else:
            self.launch_test_local(geometry)

    def launch_test_local(self, geometry):
        if geometry is None:
            self.app = self.launch_test_application(get_binary_path("indicators-client"),
                "-geometry", geometry, app_type='qt')
        else:
            self.app = self.launch_test_application(get_binary_path("indicators-client"),
                app_type='qt')

    def launch_test_installed(self, geometry):
        if geometry is not None:
            self.app = self.launch_test_application("indicators-client", "-geometry", geometry, app_type='qt')
        else:
            self.app = self.launch_test_application("indicators-client", app_type='qt')

    def skipWrapper(*args, **kwargs):
        pass

    def form_factor(self):
        return FormFactors.Desktop

    def __getattribute__(self, attr_name):
        attr = object.__getattribute__(self, attr_name);
        if attr_name.startswith("test_"):
            try:
                if self.form_factor() in attr.blacklist:
                    return self.skipWrapper
            except:
                pass
        return attr

    @property
    def main_window(self):
        return MainWindow(self.app)
