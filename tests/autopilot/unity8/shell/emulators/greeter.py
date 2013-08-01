# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Unity Autopilot Test Suite
# Copyright (C) 2012-2013 Canonical
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

from unity8.shell.emulators import UnityEmulatorBase
from autopilot.input import Touch


class Greeter(UnityEmulatorBase):

    """An emulator that understands the greeter screen."""

    def unlock(self):
        """Swipe the greeter screen away."""
        self.created.wait_for(True)
        touch = Touch.create()

        rect = self.globalRect
        start_x = rect[0] + rect[2] - 3
        start_y = int(rect[1] + rect[3] / 2)
        stop_x = int(rect[0] + rect[2] * 0.2)
        stop_y = start_y
        touch.drag(start_x, start_y, stop_x, stop_y)

        self.created.wait_for(False)
