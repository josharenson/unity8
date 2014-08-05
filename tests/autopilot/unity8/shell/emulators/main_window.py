# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Unity Autopilot Test Suite
# Copyright (C) 2012, 2013, 2014 Canonical
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

import logging

from autopilot import logging as autopilot_logging
from autopilot import input

from unity8.shell import emulators
from unity8.shell.emulators.greeter import Greeter
from unity8.shell.emulators.hud import Hud
from unity8.shell.emulators.launcher import Launcher

logger = logging.getLogger(__name__)


class QQuickView(emulators.UnityEmulatorBase):
    """An emulator class that makes it easy to interact with the shell"""

    def get_greeter(self):
        return self.select_single(Greeter)

    def get_greeter_content_loader(self):
        return self.wait_select_single(
            "QQuickLoader",
            objectName="greeterContentLoader"
        )

    def get_login_loader(self):
        return self.select_single("QQuickLoader", objectName="loginLoader")

    def get_login_list(self):
        return self.select_single("LoginList")

    def get_hud(self):
        return self.select_single(Hud)

    def get_hud_showable(self):
        return self.select_single("Showable", objectName="hudShowable")

    def get_hud_show_button(self):
        return self.select_single("HudButton")

    def get_hud_edge_drag_area(self):
        return self.select_single(objectName="hudDragArea")

    def get_bottombar(self):
        return self.select_single("Bottombar")

    def get_launcher(self):
        return self.select_single(Launcher)

    def get_pinPadLoader(self):
        return self.select_single(
            "QQuickLoader",
            objectName="pinPadLoader"
        )

    def get_lockscreen(self):
        return self.select_single("Lockscreen")

    def get_pinentryField(self):
        return self.select_single(objectName="pinentryField")

    def _get_indicator_widget(self, indicator_name):
        return self.select_single(
            'DefaultIndicatorWidget',
            objectName=indicator_name+'-widget'
        )

    def _get_indicator_page(self, indicator_name):
        return self.select_single(
            'DefaultIndicatorPage',
            objectName=indicator_name+'-page'
        )

    @autopilot_logging.log_action(logger.info)
    def open_indicator_page(self, indicator_name):
        """Swipe to open the indicator, wait until it's open.

        :returns: The indicator page.
        """
        widget = self._get_indicator_widget(indicator_name)
        start_x, start_y = input.get_center_point(widget)
        end_x = start_x
        end_y = self.height
        self.pointing_device.drag(start_x, start_y, end_x, end_y)
        self.wait_select_single('Indicators', fullyOpened=True)
        return self._get_indicator_page(indicator_name)

    @autopilot_logging.log_action(logger.info)
    def show_dash_swiping(self):
        """Show the dash swiping from the left."""
        x, y, width, height = self._get_shell().globalRect
        start_x = x
        end_x = x + width
        start_y = end_y = y + height // 2

        self.pointing_device.drag(start_x, start_y, end_x, end_y)

    def _get_shell(self):
        return self.select_single('Shell')

    def get_current_focused_app_id(self):
        """Return the id of the focused application."""
        return self._get_shell().focusedApplicationId

    @autopilot_logging.log_action(logger.info)
    def enter_pin_code(self, code):
        """Enter code 'code' into the single-pin lightdm pincode entry screen.

        :param code: must be a string of numeric characters.
        :raises: TypeError if code is not a string.
        :raises: ValueError if code contains non-numeric characters.

        """
        if not isinstance(code, str):
            raise TypeError(
                "'code' parameter must be a string, not %r."
                % type(code)
            )
        for num in code:
            if not num.isdigit():
                raise ValueError(
                    "'code' parameter contains non-numeric characters."
                )
            self.pointing_device.click_object(
                self._get_pinpad_button(int(num)))

    def _get_pinpad_button(self, button_id):
        return self.select_single(
            'PinPadButton',
            objectName='pinPadButton{}'.format(button_id)
        )
