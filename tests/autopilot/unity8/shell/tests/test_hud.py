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

from __future__ import absolute_import

from unity8.shell import with_lightdm_mock, DragMixin, finger_down
from unity8.shell.tests import UnityTestCase, _get_device_emulation_scenarios

from testtools.matchers import Equals
from autopilot.matchers import Eventually

class TestHud(UnityTestCase, DragMixin):

    """Tests the Shell HUD."""

    scenarios = _get_device_emulation_scenarios()

    def test_show_hud_button_appears_and_can_be_activated(self):
        self.launch_unity()
        self.main_window.get_greeter().swipe()
        window = self.main_window.get_qml_view()
        hud_show_button = self.main_window.get_hud_show_button()
        edge_drag_area = self.main_window.get_hud_edge_drag_area()
        hud = self.main_window.get_hud()

        self._launch_test_app_from_app_screen()

        swipe_coords = hud.get_button_swipe_coords(
            window,
            hud_show_button
        )
        initialBottomMargin = int(hud_show_button.bottomMargin)
        drag_threshold = int(edge_drag_area.distanceThreshold)
        drag_commit = int(edge_drag_area.commitDistance)

        button_appear_y = swipe_coords.start_y - drag_threshold - 5
        button_activate_y = (
            swipe_coords.start_y - drag_threshold - drag_commit - 5
        )

        button_appear_opacity = 0.5
        button_active_opacity = 1.0
        with finger_down(swipe_coords.start_x, swipe_coords.start_y) as finger:
            finger.drag(swipe_coords.start_x, button_appear_y)
            self.assertThat(
                hud_show_button.opacity,
                Eventually(Equals(button_appear_opacity))
            )
            self.assertThat(
                hud_show_button.bottomMargin,
                Eventually(Equals(initialBottomMargin))
            )

            finger.drag(swipe_coords.end_x, button_activate_y)
            self.assertThat(
                hud_show_button.opacity,
                Eventually(Equals(button_active_opacity))
            )
            self.assertThat(
                hud_show_button.bottomMargin,
                Eventually(Equals(0.0))
            )
        self.assertThat(hud.shown, Equals(False))
        self.assertThat(hud_show_button.opacity, Eventually(Equals(0.0)))

    def test_show_hud_button_can_be_dismissed(self):
        self.launch_unity()
        self.main_window.get_greeter().swipe()
        window = self.main_window.get_qml_view()
        hud_show_button = self.main_window.get_hud_show_button()
        edge_drag_area = self.main_window.get_hud_edge_drag_area()
        hud = self.main_window.get_hud()

        self._launch_test_app_from_app_screen()

        swipe_coords = hud.get_button_swipe_coords(
            window,
            hud_show_button
        )
        initialBottomMargin = int(hud_show_button.bottomMargin)

        with finger_down(swipe_coords.start_x, swipe_coords.start_y) as finger:
            finger.drag(
                swipe_coords.start_x,
                swipe_coords.end_y - int(hud_show_button.height)
            )
            self.assertThat(hud.shown, Equals(False))
            self.assertThat(hud_show_button.opacity, Eventually(Equals(1.0)))

        self.assertThat(hud_show_button.opacity, Eventually(Equals(1.0)))
        self.touch.tap(
            swipe_coords.end_x,
            swipe_coords.end_y - int(hud_show_button.height)
        )
        self.assertThat(hud.shown, Equals(False))
        self.assertThat(hud_show_button.opacity, Eventually(Equals(0.0)))

    def test_hud_opens_on_drag_release(self):
        """Dragging up to display the show hud button and then releasing on the
        button must bring up the hud.

        """
        self.launch_unity()
        self.main_window.get_greeter().swipe()
        window = self.main_window.get_qml_view()
        hud_show_button = self.main_window.get_hud_show_button()
        hud = self.main_window.get_hud()

        self._launch_test_app_from_app_screen()

        swipe_coords = hud.get_button_swipe_coords(
            window,
            hud_show_button
        )

        with finger_down(swipe_coords.start_x, swipe_coords.start_y) as finger:
            finger.drag(swipe_coords.start_x, swipe_coords.end_y)
            self.assertThat(hud.shown, Eventually(Equals(False)))
            self.assertThat(hud_show_button.opacity, Eventually(Equals(1.0)))
        # Finger is released here
        self.assertThat(hud.shown, Eventually(Equals(True)))
        self.assertThat(hud_show_button.opacity, Eventually(Equals(0.0)))

        x, y = hud.get_close_button_coords()
        self.touch.tap(x, y)
        self.assertThat(hud.shown, Eventually(Equals(False)))

    def test_hud_opens_when_visible_and_clicked(self):
        """Tapping on the show hud button while it is around must open the
        hud.

        """
        self.launch_unity()
        self.main_window.get_greeter().swipe()
        window = self.main_window.get_qml_view()
        hud_show_button = self.main_window.get_hud_show_button()
        hud = self.main_window.get_hud()

        self._launch_test_app_from_app_screen()

        swipe_coords = hud.get_button_swipe_coords(
            window,
            hud_show_button
        )

        with finger_down(swipe_coords.start_x, swipe_coords.start_y) as finger:
            finger.drag(
                swipe_coords.start_x,
                swipe_coords.end_y - int(hud_show_button.height)
            )
            self.assertThat(hud.shown, Equals(False))
            self.assertThat(hud_show_button.opacity, Eventually(Equals(1.0)))
        self.assertThat(hud_show_button.opacity, Eventually(Equals(1.0)))
        self.touch.tap(swipe_coords.end_x, swipe_coords.end_y)
        self.assertThat(hud.shown, Eventually(Equals(True)))
        self.assertThat(hud_show_button.opacity, Eventually(Equals(0.0)))

    def test_hide_hud_click(self):
        """Tapping the close button of the Hud must dismiss it."""
        self.launch_unity()
        self.main_window.get_greeter().swipe()
        hud = self.main_window.get_hud()

        self._launch_test_app_from_app_screen()

        hud.show()

        x, y = hud.get_close_button_coords()
        self.touch.tap(x, y)
        self.assertThat(hud.shown, Eventually(Equals(False)))

    def test_hide_hud_dragging(self):
        """Once open the Hud must close if the upper bar is dragged and
        released downward.

        """
        self.launch_unity()
        self.main_window.get_greeter().swipe()
        window = self.main_window.get_qml_view()
        hud = self.main_window.get_hud()

        self._launch_test_app_from_app_screen()

        hud.show()

        start_x, start_y = hud.get_close_button_coords()
        end_x = start_x
        end_y = int(window.height / 2)

        self.touch.drag(start_x, start_y, end_x, end_y)
        self.assertThat(hud.shown, Eventually(Equals(False)))

    def test_launcher_hides_hud(self):
        """Opening the Launcher while the Hud is active must close the Hud."""
        self.launch_unity()
        self.main_window.get_greeter().swipe()
        hud = self.main_window.get_hud()
        launcher = self.main_window.get_launcher()

        self._launch_test_app_from_app_screen()

        hud.show()
        launcher.show()

        self.assertThat(hud.shown, Eventually(Equals(False)))

    def _launch_test_app_from_app_screen(self):
        """Launches the camera app using the Dash UI.

        Because when testing on the desktop running
        self.launch_application() will launch the application on the desktop
        itself and not within the Unity UI.

        """
        dash = self.main_window.get_dash()
        icon = dash.get_application_icon('Camera')
        self.touch.tap_object(icon)

        # Ensure application is open
        bottombar = self.main_window.get_bottombar()
        self.assertThat(bottombar.applicationIsOnForeground,
                        Eventually(Equals(True)))

    # Because some tests are manually manipulating the finger, we want to
    # cleanup if the test fails, but we don't want to fail with an exception if
    # we don't.
    def _maybe_release_finger(self):
        """Only release the finger if it is in fact down."""
        if self.touch._touch_finger is not None:
            self.touch.release()
