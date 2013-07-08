# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.


# This file contains general purpose test cases for Unity.
# Each test written in this file will be executed for a variety of
# configurations, such as Phone, Tablet or Desktop form factors.
#
# Sometimes there is the need to disable a certain test for a particular
# configuration. To do so, add this in a new line directly below your test:
#
#    test_testname.blacklist = (FormFactors.Tablet, FormFactors.Desktop,)
#
# Available form factors are:
# FormFactors.Phone
# FormFactors.Tablet
# FormFactors.Desktop

"""Tests for the Shell"""

from __future__ import absolute_import

from unity8.tests import ShellTestCase, FormFactors
from unity8.tests.helpers import TestShellHelpers

from autopilot.input import Mouse, Touch, Pointer
from testtools.matchers import Equals, NotEquals, GreaterThan, MismatchError
from autopilot.matchers import Eventually
from autopilot.display import Display
from autopilot.platform import model

from gi.repository import GLib, Notify
import unittest
import time
import os
from os import path
import subprocess
import logging

logger = logging.getLogger(__name__)

class NotificationTestCase(ShellTestCase, TestShellHelpers):

    """Tests notifications"""

    def setUp(self):
        self.touch = Touch.create()
        super(NotificationTestCase, self).setUp("768x1280", "18")

        Notify.init("Autopilot Notification Tests")
        self.addCleanup(Notify.uninit)

    def create_notification(self, title="", body="", asset=None, urgency='NORMAL'):
        logger.info("Creating notification with title(%s) body(%s) and urgency(%r)", title, body, urgency)
        n = Notify.Notification.new(title, body, asset)
        n.set_urgency(self._get_urgency(urgency))
        n.set_timeout(10000)

        return n

    def _get_urgency(self, urgency):
        """Translates urgency string to enum."""
        _urgency_enums = {
            'LOW': Notify.Urgency.LOW,
            'NORMAL': Notify.Urgency.NORMAL,
            'CRITICAL': Notify.Urgency.CRITICAL,
        }

        return _urgency_enums.get(urgency.upper())

    def get_icon_path(self, icon_name):
        """Given an icons file name returns the full path (either system or
        source tree.

        Consider the graphics directory as root so for example (runnign tests
        from installed unity8-autopilot package):
        >>> self.get_icon_path('clock@18.png')
        /usr/share/unity8/graphics/clock@18.png

        >>> self.get_icon_path('applicationIcons/facebook@18.png')
        /usr/share/unity8/graphics/applicationIcons/facebook@18.png

        """
        if os.path.abspath(__file__).startswith('/usr/'):
            return '/usr/share/unity8/graphics/' + icon_name
        else:
            return os.path.abspath(os.getcwd() + "/../../graphics/" + icon_name)

    def get_notifications_list(self):
        main_view = self.main_window.get_qml_view()
        return main_view.select_single("QQuickListView", objectName='notificationList')

class TestNotifications(NotificationTestCase):
    def test_icon_summary_body(self):
        """Notification must display the expected summary and body text."""
        notify_list = self.get_notifications_list()
        self.unlock_greeter()

        summary = "Icon-Summary-Body"
        body = "Hey pal, what's up with the party next weekend? Will you join me and Anna?"
        icon_path = self.get_icon_path('avatars/anna_olsson@12.png')
        hint_icon = self.get_icon_path('applicationIcons/phone-app@18.png')

        notification = self.create_notification(summary, body, icon_path)
        notification.set_hint('x-canonical-secondary-icon', GLib.Variant.new_string(hint_icon))
        notification.show()

        get_notification = lambda: notify_list.select_single('Notification')
        self.assertThat(get_notification, Eventually(NotEquals(None)))
        notification = get_notification()
        self.assertThat(notification.summary, Equals(summary))
        self.assertThat(notification.body, Equals(body))

    def test_icon_summary(self):
        notify_list = self.get_notifications_list()
        subprocess.call(["notify-send",
                         "Upload of image completed",
                         "--hint=string:x-canonical-secondary-icon:" + os.getcwd() + "/../../graphics/applicationIcons/facebook@18.png"])
        self.unlock_greeter()

        get_notification = lambda: notify_list.select_single('Notification')
        self.assertThat(get_notification, Eventually(NotEquals(None)))
        notification = get_notification()
        self.assertThat(notification.summary, Equals("Upload of image completed"))

    def test_low_urgency(self):
        notify_list = self.get_notifications_list()
        subprocess.call(["notify-send",
                         "Low Urgency",
                         "No, I'd rather see paint dry, pal *yawn*",
                         "--icon=" + os.getcwd() + "/../../graphics/avatars/anna_olsson@12.png",
                         "--urgency=low"])
        self.unlock_greeter()

        get_notification = lambda: notify_list.select_single('Notification')
        self.assertThat(get_notification, Eventually(NotEquals(None)))
        notification = get_notification()
        self.assertThat(notification.summary, Equals("Low Urgency"))
        self.assertThat(notification.body, Equals("No, I'd rather see paint dry, pal *yawn*"))

    def test_normal_urgency(self):
        notify_list = self.get_notifications_list()
        subprocess.call(["notify-send",
                         "Normal Urgency",
                         "Hey pal, what's up with the party next weekend? Will you join me and Anna?",
                         "--icon=" + os.getcwd() + "/../../graphics/avatars/funky@12.png"])
        self.unlock_greeter()

        get_notification = lambda: notify_list.select_single('Notification')
        self.assertThat(get_notification, Eventually(NotEquals(None)))
        notification = get_notification()
        self.assertThat(notification.summary, Equals("Normal Urgency"))
        self.assertThat(notification.body, Equals("Hey pal, what's up with the party next weekend? Will you join me and Anna?"))

    def test_critical_urgency(self):
        notify_list = self.get_notifications_list()
        subprocess.call(["notify-send",
                         "Critical Urgency",
                         "Dude, this is so urgent you have no idea :)",
                         "--icon=/" + os.getcwd() + "/../../graphics/avatars/amanda@12.png",
                         "--urgency=critical"])
        self.unlock_greeter()

        get_notification = lambda: notify_list.select_single('Notification')
        self.assertThat(get_notification, Eventually(NotEquals(None)))
        notification = get_notification()
        self.assertThat(notification.summary, Equals("Critical Urgency"))
        self.assertThat(notification.body, Equals("Dude, this is so urgent you have no idea :)"))

    def test_summary_body(self):
        notify_list = self.get_notifications_list()
        subprocess.call(["notify-send",
                         "Summary-Body",
                         "This is a superfluous notification"])
        self.unlock_greeter()

        get_notification = lambda: notify_list.select_single('Notification')
        self.assertThat(get_notification, Eventually(NotEquals(None)))
        notification = get_notification()
        self.assertThat(notification.summary, Equals("Summary-Body"))
        self.assertThat(notification.body, Equals("This is a superfluous notification"))

    def test_summary_only(self):
        notify_list = self.get_notifications_list()
        subprocess.call(["notify-send",
                         "Summary-Only"])
        self.unlock_greeter()

        get_notification = lambda: notify_list.select_single('Notification')
        self.assertThat(get_notification, Eventually(NotEquals(None)))
        notification = get_notification()
        self.assertThat(notification.summary, Equals("Summary-Only"))
