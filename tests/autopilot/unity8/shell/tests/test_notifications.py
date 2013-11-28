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

"""Tests for Notifications"""

from __future__ import absolute_import

from unity8.process_helpers import unlock_unity
from unity8.shell.tests import UnityTestCase, _get_device_emulation_scenarios

from testtools.matchers import Equals, NotEquals
from autopilot.matchers import Eventually

from gi.repository import Notify
import time
import os
import logging
import signal
import subprocess

logger = logging.getLogger(__name__)


class NotificationsBase(UnityTestCase):
    """Base class for all notification tests that provides helper methods."""

    scenarios = _get_device_emulation_scenarios('Nexus4')

    def _get_icon_path(self, icon_name):
        """Given an icons file name returns the full path (either system or
        source tree.

        Consider the graphics directory as root so for example (running tests
        from installed unity8-autopilot package):
        >>> self.get_icon_path('clock.png')
        /usr/share/unity8/graphics/clock.png

        >>> self.get_icon_path('applicationIcons/facebook.png')
        /usr/share/unity8/graphics/applicationIcons/facebook.png

        """
        if os.path.abspath(__file__).startswith('/usr/'):
            return '/usr/share/unity8/graphics/' + icon_name
        else:
            return os.path.abspath(
                os.getcwd() + "/../../graphics/" + icon_name
            )

    def _get_notifications_list(self):
        main_view = self.main_window.get_qml_view()
        return main_view.select_single(
            "QQuickListView",
            objectName='notificationList'
        )

    def _assert_notification(
        self,
        notification,
        summary=None,
        body=None,
        icon=True,
        secondary_icon=False,
        opacity=None
    ):
        """Assert that the expected qualities of a notification are as
        expected.

        """

        if summary is not None:
            self.assertThat(notification.summary, Eventually(Equals(summary)))

        if body is not None:
            self.assertThat(notification.body, Eventually(Equals(body)))

        if icon:
            self.assertThat(notification.iconSource, Eventually(NotEquals("")))
        else:
            self.assertThat(notification.iconSource, Eventually(Equals("")))

        if secondary_icon:
            self.assertThat(
                notification.secondaryIconSource,
                Eventually(NotEquals(""))
            )
        else:
            self.assertThat(
                notification.secondaryIconSource,
                Eventually(Equals(""))
            )

        if opacity is not None:
            self.assertThat(notification.opacity, Eventually(Equals(opacity)))


class InteractiveNotificationBase(NotificationsBase):
    """Collection of test for Interactive tests including snap decisions."""

    def setUp(self):
        super(InteractiveNotificationBase, self).setUp()
        # Need to keep track when we launch the notification script.
        self._notify_proc = None

    def test_interactive(self):
        """Interactive notification must react upon click on itself."""
        unity_proxy = self.launch_unity()
        unlock_unity(unity_proxy)

        notify_list = self._get_notifications_list()

        summary = "Interactive notification"
        body = "This notification can be clicked on to trigger an action."
        icon_path = self._get_icon_path('avatars/anna_olsson.png')
        actions = [("action_id", "dummy")]
        hints = [
            ("x-canonical-switch-to-application", "true"),
            (
                "x-canonical-secondary-icon",
                self._get_icon_path('applicationIcons/phone-app.png')
            )
        ]

        self._create_interactive_notification(
            summary,
            body,
            icon_path,
            "NORMAL",
            actions,
            hints,
        )

        get_notification = lambda: notify_list.wait_select_single(
            'Notification', objectName='notification1')
        notification = get_notification()

        self.touch.tap_object(
            notification.select_single(objectName="interactiveArea")
        )

        self.assert_notification_action_id_was_called('action_id')

    def test_sd_incoming_call(self):
        """Rejecting a call should make notification expand and
            offer more options."""
        unity_proxy = self.launch_unity()
        unlock_unity(unity_proxy)

        notify_list = self._get_notifications_list()

        summary = "Incoming call"
        body = "Frank Zappa\n+44 (0)7736 027340"
        icon_path = self._get_icon_path('avatars/anna_olsson.png')
        hints = [
            (
                "x-canonical-secondary-icon",
                self._get_icon_path('applicationIcons/phone-app.png')
            ),
            ("x-canonical-snap-decisions", "true"),
        ]

        actions = [
            ('action_accept', 'Accept'),
            ('action_decline_1', 'Decline'),
            ('action_decline_2', '"Can\'t talk now, what\'s up?"'),
            ('action_decline_3', '"I call you back."'),
            ('action_decline_4', 'Send custom message...'),
        ]

        self._create_interactive_notification(
            summary,
            body,
            icon_path,
            "NORMAL",
            actions,
            hints
        )

        get_notification = lambda: notify_list.wait_select_single(
            'Notification', objectName='notification1')
        notification = get_notification()
        self._assert_notification(notification, None, None, True, True, 1.0)
        initial_height = notification.height
        self.touch.tap_object(notification.select_single(objectName="button1"))
        self.assertThat(
            notification.height,
            Eventually(Equals(initial_height +
                              3 * notification.select_single(
                                  objectName="buttonColumn").spacing +
                              3 * notification.select_single(
                                  objectName="button4").height)))
        self.touch.tap_object(notification.select_single(objectName="button4"))
        self.assert_notification_action_id_was_called("action_decline_4")

    def _create_interactive_notification(
        self,
        summary="",
        body="",
        icon=None,
        urgency="NORMAL",
        actions=[],
        hints=[]
    ):
        """Create a interactive notification command.

        :param summary: Summary text for the notification
        :param body: Body text to display in the notification
        :param icon: Path string to the icon to use
        :param urgency: Urgency string for the noticiation, either: 'LOW',
            'NORMAL', 'CRITICAL'
        :param actions: List of tuples containing the 'id' and 'label' for all
            the actions to add
        :param hint_strings: List of tuples containing the 'name' and value for
            setting the hint strings for the notification

        """

        logger.info(
            "Creating snap-decision notification with summary(%s), body(%s) "
            "and urgency(%r)",
            summary,
            body,
            urgency
        )

        script_args = [
            '--summary', summary,
            '--body', body,
            '--urgency', urgency
        ]

        if icon is not None:
            script_args.extend(['--icon', icon])

        for hint in hints:
            key, value = hint
            script_args.extend(['--hint', "%s,%s" % (key, value)])

        for action in actions:
            action_id, action_label = action
            action_string = "%s,%s" % (action_id, action_label)
            script_args.extend(['--action', action_string])

        python_bin = subprocess.check_output(['which', 'python']).strip()
        command = [python_bin, self._get_notify_script()] + script_args
        logger.info("Launching snap-decision notification as: %s", command)
        self._notify_proc = subprocess.Popen(
            command,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            close_fds=True,
        )

        self.addCleanup(self._tidy_up_script_process)

        poll_result = self._notify_proc.poll()
        if poll_result is not None and self._notify_proc.returncode != 0:
            error_output = self._notify_proc.communicate()[1]
            raise RuntimeError("Call to script failed with: %s" % error_output)

    def _get_notify_script(self):
        """Returns the path to the interactive notification creation script."""
        file_path = "../../emulators/create_interactive_notification.py"

        the_path = os.path.abspath(
            os.path.join(__file__, file_path))

        return the_path

    def _tidy_up_script_process(self):
        if self._notify_proc is not None and self._notify_proc.poll() is None:
            logger.error("Notification process wasn't killed, killing now.")
            os.killpg(self._notify_proc.pid, signal.SIGTERM)

    def assert_notification_action_id_was_called(self, action_id, timeout=10):
        """Assert that the interactive notification callback of id *action_id*
        was called.

        :raises AssertionError: If no interactive notification has actually
            been created.
        :raises AssertionError: When *action_id* does not match the actual
            returned.
        :raises AssertionError: If no callback was called at all.
        """

        if self._notify_proc is None:
            raise AssertionError("No interactive notification was created.")

        for i in xrange(timeout):
            self._notify_proc.poll()
            if self._notify_proc.returncode is not None:
                output = self._notify_proc.communicate()
                actual_action_id = output[0].strip("\n")
                if actual_action_id != action_id:
                    raise AssertionError(
                        "action id '%s' does not match actual returned '%s'"
                        % (action_id, actual_action_id)
                    )
                else:
                    return
            time.sleep(1)

        os.killpg(self._notify_proc.pid, signal.SIGTERM)
        self._notify_proc = None
        raise AssertionError(
            "No callback was called, killing interactivenotification script"
        )


class EphemeralNotificationsTests(NotificationsBase):
    """Collection of tests for Emphemeral notifications (non-interactive.)"""

    def setUp(self):
        super(EphemeralNotificationsTests, self).setUp()
        # Because we are using the Notify library we need to init and un-init
        # otherwise we get crashes.
        Notify.init("Autopilot Ephemeral Notification Tests")
        self.addCleanup(Notify.uninit)

    def test_icon_summary_body(self):
        """Notification must display the expected summary and body text."""
        unity_proxy = self.launch_unity()
        unlock_unity(unity_proxy)

        notify_list = self._get_notifications_list()

        summary = "Icon-Summary-Body"
        body = "Hey pal, what's up with the party next weekend? Will you " \
               "join me and Anna?"
        icon_path = self._get_icon_path('avatars/anna_olsson.png')
        hints = [
            (
                "x-canonical-secondary-icon",
                self._get_icon_path('applicationIcons/phone-app.png')
            )
        ]

        notification = self._create_ephemeral_notification(
            summary,
            body,
            icon_path,
            hints,
            "NORMAL",
        )

        notification.show()

        notification = lambda: notify_list.wait_select_single(
            'Notification', objectName='notification1')
        self._assert_notification(
            notification(),
            summary,
            body,
            True,
            True,
            1.0,
        )

    def test_icon_summary(self):
        """Notification must display the expected summary and secondary
        icon."""
        unity_proxy = self.launch_unity()
        unlock_unity(unity_proxy)

        notify_list = self._get_notifications_list()

        summary = "Upload of image completed"
        hints = [
            (
                "x-canonical-secondary-icon",
                self._get_icon_path('applicationIcons/facebook.png')
            )
        ]

        notification = self._create_ephemeral_notification(
            summary,
            None,
            None,
            hints,
            "NORMAL",
        )

        notification.show()

        notification = lambda: notify_list.wait_select_single(
            'Notification', objectName='notification1')

        self._assert_notification(
            notification(),
            summary,
            None,
            False,
            True,
            1.0
        )

    def test_urgency_order(self):
        """Notifications must be displayed in order according to their
        urgency."""
        unity_proxy = self.launch_unity()
        unlock_unity(unity_proxy)

        notify_list = self._get_notifications_list()

        summary_low = 'Low Urgency'
        body_low = "No, I'd rather see paint dry, pal *yawn*"
        icon_path_low = self._get_icon_path('avatars/amanda.png')

        summary_normal = 'Normal Urgency'
        body_normal = "Hey pal, what's up with the party next weekend? Will " \
            "you join me and Anna?"
        icon_path_normal = self._get_icon_path('avatars/funky.png')

        summary_critical = 'Critical Urgency'
        body_critical = 'Dude, this is so urgent you have no idea :)'
        icon_path_critical = self._get_icon_path('avatars/anna_olsson.png')

        notification_normal = self._create_ephemeral_notification(
            summary_normal,
            body_normal,
            icon_path_normal,
            urgency="NORMAL"
        )
        notification_normal.show()

        notification_low = self._create_ephemeral_notification(
            summary_low,
            body_low,
            icon_path_low,
            urgency="LOW"
        )
        notification_low.show()

        notification_critical = self._create_ephemeral_notification(
            summary_critical,
            body_critical,
            icon_path_critical,
            urgency="CRITICAL"
        )
        notification_critical.show()

        get_notification = lambda: notify_list.wait_select_single(
            'Notification',
            summary=summary_critical
        )

        notification = get_notification()
        self._assert_notification(
            notification,
            summary_critical,
            body_critical,
            True,
            False,
            1.0
        )

        get_normal_notification = lambda: notify_list.wait_select_single(
            'Notification',
            summary=summary_normal
        )
        notification = get_normal_notification()
        self._assert_notification(
            notification,
            summary_normal,
            body_normal,
            True,
            False,
            1.0
        )

        get_low_notification = lambda: notify_list.wait_select_single(
            'Notification',
            summary=summary_low
        )
        notification = get_low_notification()
        self._assert_notification(
            notification,
            summary_low,
            body_low,
            True,
            False,
            1.0
        )

    def test_summary_and_body(self):
        """Notification must display the expected summary- and body-text."""
        unity_proxy = self.launch_unity()
        unlock_unity(unity_proxy)

        notify_list = self._get_notifications_list()

        summary = 'Summary-Body'
        body = 'This is a superfluous notification'

        notification = self._create_ephemeral_notification(summary, body)
        notification.show()

        notification = notify_list.wait_select_single(
            'Notification', objectName='notification1')

        self._assert_notification(
            notification,
            summary,
            body,
            False,
            False,
            1.0
        )

    def test_summary_only(self):
        """Notification must display only the expected summary-text."""
        unity_proxy = self.launch_unity()
        unlock_unity(unity_proxy)

        notify_list = self._get_notifications_list()

        summary = 'Summary-Only'

        notification = self._create_ephemeral_notification(summary)
        notification.show()

        notification = notify_list.wait_select_single(
            'Notification', objectName='notification1')

        self._assert_notification(notification, summary, '', False, False, 1.0)

    def test_update_notification_same_layout(self):
        """Notification must allow updating its contents while being
        displayed."""
        unity_proxy = self.launch_unity()
        unlock_unity(unity_proxy)

        notify_list = self._get_notifications_list()

        summary = 'Initial notification'
        body = 'This is the original content of this notification-bubble.'
        icon_path = self._get_icon_path('avatars/funky.png')

        notification = self._create_ephemeral_notification(
            summary,
            body,
            icon_path
        )
        notification.show()

        get_notification = lambda: notify_list.wait_select_single(
            'Notification', summary=summary)
        self._assert_notification(
            get_notification(),
            summary,
            body,
            True,
            False,
            1.0
        )

        summary = 'Updated notification'
        body = 'Here the same bubble with new title- and body-text, even ' \
            'the icon can be changed on the update.'
        icon_path = self._get_icon_path('avatars/amanda.png')
        notification.update(summary, body, icon_path)
        notification.show()
        self._assert_notification(get_notification(), summary, body)

    def test_update_notification_layout_change(self):
        """Notification must allow updating its contents and layout while
        being displayed."""
        unity_proxy = self.launch_unity()
        unlock_unity(unity_proxy)

        notify_list = self._get_notifications_list()

        summary = 'Initial layout'
        body = 'This bubble uses the icon-title-body layout with a ' \
            'secondary icon.'
        icon_path = self._get_icon_path('avatars/anna_olsson.png')
        hint_icon = self._get_icon_path('applicationIcons/phone-app.png')

        notification = self._create_ephemeral_notification(
            summary,
            body,
            icon_path
        )
        notification.set_hint_string(
            'x-canonical-secondary-icon',
            hint_icon
        )
        notification.show()

        get_notification = lambda: notify_list.wait_select_single(
            'Notification', objectName='notification1')

        self._assert_notification(
            get_notification(),
            summary,
            body,
            True,
            True,
            1.0
        )

        notification.clear_hints()
        summary = 'Updated layout'
        body = 'After the update we now have a bubble using the title-body ' \
            'layout.'
        notification.update(summary, body, None)
        notification.show()

        self.assertThat(get_notification, Eventually(NotEquals(None)))
        self._assert_notification(get_notification(), summary, body, False)

    def test_append_hint(self):
        """Notification has to accumulate body-text using append-hint."""
        unity_proxy = self.launch_unity()
        unlock_unity(unity_proxy)

        notify_list = self._get_notifications_list()

        summary = 'Cole Raby'
        body = 'Hey Bro Coly!'
        icon_path = self._get_icon_path('avatars/amanda.png')
        body_sum = body
        notification = self._create_ephemeral_notification(
            summary,
            body,
            icon_path,
            hints=[('x-canonical-append', 'true')]
        )

        notification.show()

        get_notification = lambda: notify_list.wait_select_single(
            'Notification', objectName='notification1')

        notification = get_notification()
        self._assert_notification(
            notification,
            summary,
            body_sum,
            True,
            False,
            1.0
        )

        bodies = [
            'What\'s up dude?',
            'Did you watch the air-race in Oshkosh last week?',
            'Phil owned the place like no one before him!',
            'Did really everything in the race work according to regulations?',
            'Somehow I think to remember Burt Williams did cut corners and '
            'was not punished for this.',
            'Hopefully the referees will watch the videos of the race.',
            'Burt could get fined with US$ 50000 for that rule-violation :)'
        ]

        for new_body in bodies:
            body = new_body
            body_sum += '\n' + body
            notification = self._create_ephemeral_notification(
                summary,
                body,
                icon_path,
                hints=[('x-canonical-append', 'true')]
            )
            notification.show()

            get_notification = lambda: notify_list.wait_select_single(
                'Notification',
                objectName='notification1'
            )
            notification = get_notification()
            self._assert_notification(
                notification,
                summary,
                body_sum,
                True,
                False,
                1.0
            )

    def _create_ephemeral_notification(
        self,
        summary="",
        body="",
        icon=None,
        hints=[],
        urgency="NORMAL"
    ):
        """Create an ephemeral (non-interactive) notification

            :param summary: Summary text for the notification
            :param body: Body text to display in the notification
            :param icon: Path string to the icon to use
            :param hint_strings: List of tuples containing the 'name' and value
                for setting the hint strings for the notification
            :param urgency: Urgency string for the noticiation, either: 'LOW',
                'NORMAL', 'CRITICAL'

        """
        logger.info(
            "Creating ephemeral: summary(%s), body(%s), urgency(%r) "
            "and Icon(%s)",
            summary,
            body,
            urgency,
            icon
        )

        n = Notify.Notification.new(summary, body, icon)

        for hint in hints:
            key, value = hint
            n.set_hint_string(key, value)
            logger.info("Adding hint to notification: (%s, %s)", key, value)
        n.set_urgency(self._get_urgency(urgency))

        return n

    def _get_urgency(self, urgency):
        """Translates urgency string to enum."""
        _urgency_enums = {'LOW': Notify.Urgency.LOW,
                          'NORMAL': Notify.Urgency.NORMAL,
                          'CRITICAL': Notify.Urgency.CRITICAL}
        return _urgency_enums.get(urgency.upper())
