/*
 * Copyright (C) 2013 Canonical, Ltd.
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

import QtQuick 2.0
import Ubuntu.Components 0.1
import "../../Components"

Row {
    id: root
    property alias icon: image.source
    property alias title: titleLabel.text
    property alias subtitle: subtitleLabel.text
    property alias rating: ratingStars.rating
    property int rated: 0
    property int reviews: 0

    spacing: units.gu(2)
    height: imageShape.visible ? imageShape.height : contentColumn.height

    UbuntuShape {
        id: imageShape
        width: height
        height: Math.max(units.gu(6), contentColumn.height)
        visible: image.source.toString().length > 0
        image: Image {
            id: image
            sourceSize { width: imageShape.width; height: imageShape.height }
            asynchronous: true
            fillMode: Image.PreserveAspectFit
        }
    }

    Column {
        id: contentColumn
        spacing: units.gu(1)
        width: parent.width - x

        Label {
            id: titleLabel
            objectName: "titleLabel"
            fontSize: "large"
            color: "white"
            style: Text.Raised
            styleColor: "black"
            opacity: .9
            width: parent.width
            elide: Text.ElideRight
        }

        Label {
            id: subtitleLabel
            objectName: "subtitleLabel"
            fontSize: "medium"
            color: "white"
            style: Text.Raised
            styleColor: "black"
            opacity: .6
            visible: text.length > 0
        }

        Row {
            visible: root.rating >= 0
            spacing: units.gu(1)

            RatingStars {
                id: ratingStars
                maximumRating: 10
                rating: -1
            }

            Label {
                id: ratedLabel
                objectName: "ratedLabel"
                fontSize: "medium"
                color: "white"
                style: Text.Raised
                styleColor: "black"
                opacity: .6
                //TRANSLATORS: Number of persons who rated this app/video/whatever
                text: i18n.tr("(%1)").arg(root.rated)
            }

            Label {
                id: reviewsLabel
                objectName: "reviewsLabel"
                fontSize: "medium"
                color: "white"
                style: Text.Raised
                styleColor: "black"
                opacity: .6
                //TRANSLATORS: Number of persons who wrote reviews for this app/video/whatever
                text: i18n.tr("%1 review", "%1 reviews", root.reviews).arg(root.reviews)
            }
        }
    }
}
