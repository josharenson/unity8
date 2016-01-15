import QtQuick 2.4

QtObject {

    property var dialerData: [{
        "rowData": {                // 1.1
            "label": "_dialer1",
            "sensitive": true,
            "isSeparator": false,
            "icon": "",
            "type": "com.canonical.indicator.test",
            "ext": {},
            "action": "dialer1",
            "actionState": {},
            "isCheck": false,
            "isRadio": false,
            "isToggled": false,
            "shortcut": "Alt+F"
        },
        "submenu": [{
            "rowData": {                // 1.1
                "label": "menu1.1",
                "sensitive": true,
                "isSeparator": false,
                "icon": "",
                "type": "com.canonical.indicator.test",
                "ext": {},
                "action": "menu1.1",
                "actionState": {},
                "isCheck": false,
                "isRadio": false,
                "isToggled": false,
                "shortcut": "Alt+0"
            }}, {
           "rowData": {                // 1.2
               "label": "menu1.2",
               "sensitive": true,
               "isSeparator": false,
               "icon": "",
               "type": "com.canonical.indicator.test",
               "ext": {},
               "action": "menu1.2",
               "actionState": {},
               "isCheck": false,
               "isRadio": false,
               "isToggled": false,
               "shortcut": "Alt+1"
           },
           "submenu": [{
                "rowData": {                // 1.2.1
                    "label": "menu1.2.1",
                    "sensitive": true,
                    "isSeparator": false,
                    "icon": "",
                    "type": "com.canonical.indicator.test",
                    "ext": {},
                    "action": "menu1.2.1",
                    "actionState": {},
                    "isCheck": false,
                    "isRadio": false,
                    "isToggled": false,
                    "shortcut": ""
                }}, {
               "rowData": {                // 1.2.2
                   "label": "menu1.2.2",
                   "sensitive": true,
                   "isSeparator": false,
                   "icon": "",
                   "type": "com.canonical.indicator.test",
                   "ext": {},
                   "action": "menu1.2.2",
                   "actionState": {},
                   "isCheck": false,
                   "isRadio": false,
                   "isToggled": false,
                   "shortcut": ""
               }}, {
               "rowData": {                // 1.2.3
                   "label": "",
                   "sensitive": false,
                   "isSeparator": true,
                   "icon": "",
                   "type": "",
                   "ext": {},
                   "action": "",
                   "actionState": {},
                   "isCheck": false,
                   "isRadio": false,
                   "isToggled": false,
                   "shortcut": ""
               }}, {
               "rowData": {                // row 1.2.4
                   "label": "menu1.2.4",
                   "sensitive": true,
                   "isSeparator": false,
                   "icon": "",
                   "type": "com.canonical.indicator.test",
                   "ext": {},
                   "action": "menu1.2.4",
                   "actionState": {},
                   "isCheck": false,
                   "isRadio": false,
                   "isToggled": true,
                   "shortcut": ""
               }}
            ]}, {
           "rowData": {                // 1.3
               "label": "",
               "sensitive": false,
               "isSeparator": true,
               "icon": "",
               "type": "",
               "ext": {},
               "action": "",
               "actionState": {},
               "isCheck": false,
               "isRadio": false,
               "isToggled": false,
               "shortcut": ""
           }}, {
           "rowData": {                // row 1.4
               "label": "menu1.4",
               "sensitive": true,
               "isSeparator": false,
               "icon": "",
               "type": "com.canonical.indicator.test",
               "ext": {},
               "action": "menu1.4",
               "actionState": {},
               "isCheck": true,
               "isRadio": false,
               "isToggled": true,
               "shortcut": "Alt+2"
           }}
        ]}, {
       "rowData": {                // 2
           "label": "d_ialer2",
           "sensitive": true,
           "isSeparator": false,
           "icon": "",
           "type": "com.canonical.indicator.test",
           "ext": {},
           "action": "dialer2",
           "actionState": {},
           "isCheck": false,
           "isRadio": false,
           "isToggled": false,
           "shortcut": "Alt+E"
        },
        "submenu": [{
            "rowData": {                // 2.1
                "label": "menu2.1",
                "sensitive": true,
                "isSeparator": false,
                "icon": "",
                "type": "com.canonical.indicator.test",
                "ext": {},
                "action": "menu2.1",
                "actionState": {},
                "isCheck": false,
                "isRadio": false,
                "isToggled": false,
                "shortcut": ""
            }}
        ]}, {
        "rowData": {                // row 3
            "label": "di_aler3",
            "sensitive": true,
            "isSeparator": false,
            "icon": "",
            "type": "com.canonical.indicator.test",
            "ext": {},
            "action": "dialer3",
            "actionState": {},
            "isCheck": false,
            "isRadio": false,
            "isToggled": false,
            "shortcut": ""
        },
        "submenu": [{
            "rowData": {                // 3.1
                "label": "menu3.1",
                "sensitive": true,
                "isSeparator": false,
                "icon": "",
                "type": "com.canonical.indicator.test",
                "ext": {},
                "action": "menu3.1",
                "actionState": {},
                "isCheck": false,
                "isRadio": false,
                "isToggled": false,
                "shortcut": ""
            }}
        ]}
    ]

    property var cameraData: [{
        "rowData": {                // 1.1
            "label": "camera1",
            "sensitive": true,
            "isSeparator": false,
            "icon": "",
            "type": "com.canonical.indicator.test",
            "ext": {},
            "action": "camera1",
            "actionState": {},
            "isCheck": false,
            "isRadio": false,
            "isToggled": false,
            "shortcut": ""
        },
        "submenu": [{
            "rowData": {                // 1.1
                "label": "menu1.1",
                "sensitive": true,
                "isSeparator": false,
                "icon": "",
                "type": "com.canonical.indicator.test",
                "ext": {},
                "action": "menu1.1",
                "actionState": {},
                "isCheck": false,
                "isRadio": false,
                "isToggled": false,
                "shortcut": ""
            }}, {
           "rowData": {                // 1.2
               "label": "menu1.2",
               "sensitive": true,
               "isSeparator": false,
               "icon": "",
               "type": "com.canonical.indicator.test",
               "ext": {},
               "action": "menu1.2",
               "actionState": {},
               "isCheck": false,
               "isRadio": false,
               "isToggled": false,
               "shortcut": ""
           }}, {
           "rowData": {                // row 1.2
               "label": "menu1.2",
               "sensitive": true,
               "isSeparator": false,
               "icon": "",
               "type": "com.canonical.indicator.test",
               "ext": {},
               "action": "menu1.2",
               "actionState": {},
               "isCheck": false,
               "isRadio": false,
               "isToggled": false,
               "shortcut": ""
           }}
        ]}, {
       "rowData": {                // 2
           "label": "camera2",
           "sensitive": true,
           "isSeparator": false,
           "icon": "",
           "type": "com.canonical.indicator.test",
           "ext": {},
           "action": "camera2",
           "actionState": {},
           "isCheck": false,
           "isRadio": false,
           "isToggled": false,
           "shortcut": ""
       }}
    ]

    property var galleryData: [{
        "rowData": {                // 1.1
            "label": "gallery1",
            "sensitive": true,
            "isSeparator": false,
            "icon": "",
            "type": "com.canonical.indicator.test",
            "ext": {},
            "action": "gallery1",
            "actionState": {},
            "isCheck": false,
            "isRadio": false,
            "isToggled": false,
            "shortcut": ""
        },
        "submenu": [{
            "rowData": {                // 1.1
                "label": "menu0",
                "sensitive": true,
                "isSeparator": false,
                "icon": "",
                "type": "com.canonical.indicator.test",
                "ext": {},
                "action": "menu0",
                "actionState": {},
                "isCheck": false,
                "isRadio": false,
                "isToggled": false,
                "shortcut": ""
            }}, {
           "rowData": {                // 1.2
               "label": "menu1",
               "sensitive": true,
               "isSeparator": false,
               "icon": "",
               "type": "com.canonical.indicator.test",
               "ext": {},
               "action": "menu1",
               "actionState": {},
               "isCheck": false,
               "isRadio": false,
               "isToggled": false,
               "shortcut": ""
           }}, {
           "rowData": {                // 1.2
               "label": "",
               "sensitive": false,
               "isSeparator": true,
               "icon": "",
               "type": "",
               "ext": {},
               "action": "",
               "actionState": {},
               "isCheck": false,
               "isRadio": false,
               "isToggled": false,
               "shortcut": ""
           }}, {
           "rowData": {                // row 1.2
               "label": "menu2",
               "sensitive": true,
               "isSeparator": false,
               "icon": "",
               "type": "com.canonical.indicator.test",
               "ext": {},
               "action": "menu2",
               "actionState": {},
               "isCheck": false,
               "isRadio": false,
               "isToggled": false,
               "shortcut": ""
           }}
        ]}, {
       "rowData": {                // 2
           "label": "gallery2",
           "sensitive": true,
           "isSeparator": false,
           "icon": "",
           "type": "com.canonical.indicator.test",
           "ext": {},
           "action": "gallery2",
           "actionState": {},
           "isCheck": false,
           "isRadio": false,
           "isToggled": false,
           "shortcut": ""
       }}, {
       "rowData": {                // row 2
           "label": "gallery3",
           "sensitive": true,
           "isSeparator": false,
           "icon": "",
           "type": "com.canonical.indicator.test",
           "ext": {},
           "action": "gallery3",
           "actionState": {},
           "isCheck": false,
           "isRadio": false,
           "isToggled": false,
           "shortcut": ""
       }}
    ]

    property var testData: [{
        "rowData": {                // 1
            "label": "_menu1",
            "sensitive": true,
            "isSeparator": false,
            "icon": "",
            "type": "com.canonical.indicator.test",
            "ext": {},
            "action": "menu1",
            "actionState": {},
            "isCheck": false,
            "isRadio": false,
            "isToggled": false,
            "shortcut": "Alt+F"
        },
        "submenu": [{
            "rowData": {                // 1.1
                "label": "menu1.1",
                "sensitive": true,
                "isSeparator": false,
                "icon": "",
                "type": "com.canonical.indicator.test",
                "ext": {},
                "action": "menu1.1",
                "actionState": {},
                "isCheck": false,
                "isRadio": false,
                "isToggled": false,
                "shortcut": "Alt+0"
            }}, {
           "rowData": {                // 1.2
               "label": "m_enu1.2",
               "sensitive": true,
               "isSeparator": false,
               "icon": "",
               "type": "com.canonical.indicator.test",
               "ext": {},
               "action": "menu1.2",
               "actionState": {},
               "isCheck": false,
               "isRadio": false,
               "isToggled": false,
               "shortcut": "Alt+1"
           },
           "submenu": [{
                "rowData": {                // 1.2.1
                    "label": "menu1.2.1",
                    "sensitive": true,
                    "isSeparator": false,
                    "icon": "",
                    "type": "com.canonical.indicator.test",
                    "ext": {},
                    "action": "menu1.2.1",
                    "actionState": {},
                    "isCheck": false,
                    "isRadio": false,
                    "isToggled": false,
                    "shortcut": ""
                }}, {
               "rowData": {                // 1.2.2
                   "label": "men_u1.2.2",
                   "sensitive": true,
                   "isSeparator": false,
                   "icon": "",
                   "type": "com.canonical.indicator.test",
                   "ext": {},
                   "action": "menu1.2.2",
                   "actionState": {},
                   "isCheck": false,
                   "isRadio": false,
                   "isToggled": false,
                   "shortcut": ""
               }}, {
               "rowData": {                // 1.2.3
                   "label": "",
                   "sensitive": false,
                   "isSeparator": true,
                   "icon": "",
                   "type": "",
                   "ext": {},
                   "action": "",
                   "actionState": {},
                   "isCheck": false,
                   "isRadio": false,
                   "isToggled": false,
                   "shortcut": ""
               }}, {
               "rowData": {                // row 1.2.4
                   "label": "menu1.2.4",
                   "sensitive": true,
                   "isSeparator": false,
                   "icon": "",
                   "type": "com.canonical.indicator.test",
                   "ext": {},
                   "action": "menu1.2.4",
                   "actionState": {},
                   "isCheck": false,
                   "isRadio": false,
                   "isToggled": true,
                   "shortcut": ""
               }}
            ]}, {
           "rowData": {                // 1.3
               "label": "",
               "sensitive": false,
               "isSeparator": true,
               "icon": "",
               "type": "",
               "ext": {},
               "action": "",
               "actionState": {},
               "isCheck": false,
               "isRadio": false,
               "isToggled": false,
               "shortcut": ""
           }}, {
           "rowData": {                // row 1.4
               "label": "menu1.4",
               "sensitive": true,
               "isSeparator": false,
               "icon": "",
               "type": "com.canonical.indicator.test",
               "ext": {},
               "action": "menu1.4",
               "actionState": {},
               "isCheck": true,
               "isRadio": false,
               "isToggled": true,
               "shortcut": "Alt+2"
           }}
        ]}, {
       "rowData": {                // 2
           "label": "menu2",
           "sensitive": true,
           "isSeparator": false,
           "icon": "",
           "type": "com.canonical.indicator.test",
           "ext": {},
           "action": "menu2",
           "actionState": {},
           "isCheck": false,
           "isRadio": false,
           "isToggled": false,
           "shortcut": "Alt+E"
        },
        "submenu": [{
            "rowData": {                // 2.1
                "label": "menu2.1",
                "sensitive": true,
                "isSeparator": false,
                "icon": "",
                "type": "com.canonical.indicator.test",
                "ext": {},
                "action": "menu2.1",
                "actionState": {},
                "isCheck": false,
                "isRadio": false,
                "isToggled": false,
                "shortcut": ""
            }}
        ]}, {
        "rowData": {                // row 3
            "label": "me_nu3",
            "sensitive": true,
            "isSeparator": false,
            "icon": "",
            "type": "com.canonical.indicator.test",
            "ext": {},
            "action": "dialer3",
            "actionState": {},
            "isCheck": false,
            "isRadio": false,
            "isToggled": false,
            "shortcut": ""
        },
        "submenu": [{
            "rowData": {                // 3.1
                "label": "menu3.1",
                "sensitive": true,
                "isSeparator": false,
                "icon": "",
                "type": "com.canonical.indicator.test",
                "ext": {},
                "action": "menu3.1",
                "actionState": {},
                "isCheck": false,
                "isRadio": false,
                "isToggled": false,
                "shortcut": ""
            }}
        ]}
    ]

    property var deepTestData: [{
        "rowData": {                // 1
            "label": "_menu1",
            "sensitive": true,
            "isSeparator": false,
            "icon": "",
            "type": "com.canonical.indicator.test",
            "ext": {},
            "action": "menu1",
            "actionState": {},
            "isCheck": false,
            "isRadio": false,
            "isToggled": false,
            "shortcut": "Alt+F"
        },
        "submenu": [{
            "rowData": {                // 1.1
                "label": "menu1.1",
                "sensitive": true,
                "isSeparator": false,
                "icon": "",
                "type": "com.canonical.indicator.test",
                "ext": {},
                "action": "menu1.1",
                "actionState": {},
                "isCheck": false,
                "isRadio": false,
                "isToggled": false,
                "shortcut": ""
            },
            "submenu": [{
                "rowData": {                // 1.1.1
                    "label": "menu1.1.1",
                    "sensitive": true,
                    "isSeparator": false,
                    "icon": "",
                    "type": "com.canonical.indicator.test",
                    "ext": {},
                    "action": "menu1.1.1",
                    "actionState": {},
                    "isCheck": false,
                    "isRadio": false,
                    "isToggled": false,
                    "shortcut": ""
                },
                "submenu": [{
                    "rowData": {                // 1.1.1
                        "label": "menu1.1.1.1",
                        "sensitive": true,
                        "isSeparator": false,
                        "icon": "",
                        "type": "com.canonical.indicator.test",
                        "ext": {},
                        "action": "menu1.1.1.1",
                        "actionState": {},
                        "isCheck": false,
                        "isRadio": false,
                        "isToggled": false,
                        "shortcut": ""
                    },
                    "submenu": [{
                        "rowData": {                // 1.1.1.1
                            "label": "menu1.1.1.1.1",
                            "sensitive": true,
                            "isSeparator": false,
                            "icon": "",
                            "type": "com.canonical.indicator.test",
                            "ext": {},
                            "action": "menu1.1.1.1.1",
                            "actionState": {},
                            "isCheck": false,
                            "isRadio": false,
                            "isToggled": false,
                            "shortcut": ""
                        }}
                    ]}
                ]}
            ]}
        ]}
    ]

    property var singleCheckable: [{
        "rowData": {                // 1
            "label": "checkable1",
            "sensitive": true,
            "isSeparator": false,
            "icon": "",
            "type": "com.canonical.indicator.test",
            "ext": {},
            "action": "checkable1",
            "actionState": {},
            "isCheck": true,
            "isRadio": false,
            "isToggled": false,
            "shortcut": "Alt+F"
        }
    }]

    function generateTestData(length, depth, separatorInterval, prefix) {
        var data = [];

        if (prefix === undefined) prefix = "menu"

        for (var i = 0; i < length; i++) {

            var menuCode = String.fromCharCode(i+65);

            var isSeparator = separatorInterval > 0 && ((i+1) % separatorInterval == 0);
            var row = {
                "rowData": {                // 1
                    "label": prefix + "&" + menuCode,
                    "sensitive": true,
                    "isSeparator": isSeparator,
                    "icon": "",
                    "type": "com.canonical.indicator.test",
                    "ext": {},
                    "action": prefix + menuCode,
                    "actionState": {},
                    "isCheck": false,
                    "isRadio": false,
                    "isToggled": false,
                    "shortcut": ""
                }
            }
            if (!isSeparator && depth > 1) {
                var submenu = generateTestData(length, depth-1, separatorInterval, prefix + menuCode + ".");
                row["submenu"] = submenu;
            }
            data[i] = row;
        }
        return data;
    }
}

