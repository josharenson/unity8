/*
 * Copyright (C) 2015-2016 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4

Item {
    property int topBoundaryOffset // effectively panel height
    property Item confiningItem

    signal pushedLeftBoundary(real amount, int buttons)
    signal pushedRightBoundary(real amount, int buttons)
    signal pushedTopBoundary(real amount, int buttons)
    signal pushedTopLeftCorner(real amount, int buttons)
    signal pushedTopRightCorner(real amount, int buttons)
    signal pushedBottomLeftCorner(real amount, int buttons)
    signal pushedBottomRightCorner(real amount, int buttons)
    signal pushStopped()
    signal mouseMoved()

    onMouseMoved: opacity = 1;
}
