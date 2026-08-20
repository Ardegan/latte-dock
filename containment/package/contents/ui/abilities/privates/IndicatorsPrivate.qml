/*
    SPDX-FileCopyrightText: 2021 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.7

import org.kde.latte.abilities.host 0.1 as AbilityHost

AbilityHost.Indicators {
    id: _indicators
    property QtObject view: null

    Connections {
        target: _indicators.info
        function onSvgPathsChanged() {
            if (_indicators.isEnabled) {
                view.indicator.resources.setSvgImagePaths(_indicators.info.svgPaths);
            }
        }
    }

    Connections {
        target:_indicators
        function onIsEnabledChanged() {
            if (_indicators.isEnabled) {
                view.indicator.resources.setSvgImagePaths(_indicators.info.svgPaths);
            }
        }
    }

    //! Bindings in order to inform View::Indicator
    Binding{
         //! Qt5 defaulted Binding.restoreMode to RestoreNone, so a binding whose
        //! `when` turned false simply left the property at its last value. Qt6
        //! defaults to RestoreBindingOrValue and puts the *previous* value back,
        //! which silently reset properties this code expects to persist.
        restoreMode: Binding.RestoreNone
       target: view && view.indicator ? view.indicator : null
        property:"enabledForApplets"
        when: view && view.indicator
        value: _indicators.info.enabledForApplets
    }

    //! Bindings in order to inform View::Indicator::Info
    Binding{
         //! Qt5 defaulted Binding.restoreMode to RestoreNone, so a binding whose
        //! `when` turned false simply left the property at its last value. Qt6
        //! defaults to RestoreBindingOrValue and puts the *previous* value back,
        //! which silently reset properties this code expects to persist.
        restoreMode: Binding.RestoreNone
       target: view && view.indicator ? view.indicator.info : null
        property:"needsIconColors"
        when: view && view.indicator
        value: _indicators.info.needsIconColors
    }

    Binding{
         //! Qt5 defaulted Binding.restoreMode to RestoreNone, so a binding whose
        //! `when` turned false simply left the property at its last value. Qt6
        //! defaults to RestoreBindingOrValue and puts the *previous* value back,
        //! which silently reset properties this code expects to persist.
        restoreMode: Binding.RestoreNone
       target: view && view.indicator ? view.indicator.info : null
        property:"needsMouseEventCoordinates"
        when: view && view.indicator
        value: _indicators.info.needsMouseEventCoordinates
    }

    Binding{
         //! Qt5 defaulted Binding.restoreMode to RestoreNone, so a binding whose
        //! `when` turned false simply left the property at its last value. Qt6
        //! defaults to RestoreBindingOrValue and puts the *previous* value back,
        //! which silently reset properties this code expects to persist.
        restoreMode: Binding.RestoreNone
       target: view && view.indicator ? view.indicator.info : null
        property:"providesClickedAnimation"
        when: view && view.indicator
        value: _indicators.info.providesClickedAnimation
    }

    Binding{
         //! Qt5 defaulted Binding.restoreMode to RestoreNone, so a binding whose
        //! `when` turned false simply left the property at its last value. Qt6
        //! defaults to RestoreBindingOrValue and puts the *previous* value back,
        //! which silently reset properties this code expects to persist.
        restoreMode: Binding.RestoreNone
       target: view && view.indicator ? view.indicator.info : null
        property:"providesHoveredAnimation"
        when: view && view.indicator
        value: _indicators.info.providesHoveredAnimation
    }

    Binding{
         //! Qt5 defaulted Binding.restoreMode to RestoreNone, so a binding whose
        //! `when` turned false simply left the property at its last value. Qt6
        //! defaults to RestoreBindingOrValue and puts the *previous* value back,
        //! which silently reset properties this code expects to persist.
        restoreMode: Binding.RestoreNone
       target: view && view.indicator ? view.indicator.info : null
        property:"providesInAttentionAnimation"
        when: view && view.indicator
        value: _indicators.info.providesInAttentionAnimation
    }

    Binding{
         //! Qt5 defaulted Binding.restoreMode to RestoreNone, so a binding whose
        //! `when` turned false simply left the property at its last value. Qt6
        //! defaults to RestoreBindingOrValue and puts the *previous* value back,
        //! which silently reset properties this code expects to persist.
        restoreMode: Binding.RestoreNone
       target: view && view.indicator ? view.indicator.info : null
        property:"providesTaskLauncherAnimation"
        when: view && view.indicator
        value: _indicators.info.providesTaskLauncherAnimation
    }

    Binding{
         //! Qt5 defaulted Binding.restoreMode to RestoreNone, so a binding whose
        //! `when` turned false simply left the property at its last value. Qt6
        //! defaults to RestoreBindingOrValue and puts the *previous* value back,
        //! which silently reset properties this code expects to persist.
        restoreMode: Binding.RestoreNone
       target: view && view.indicator ? view.indicator.info : null
        property:"providesGroupedWindowAddedAnimation"
        when: view && view.indicator
        value: _indicators.info.providesGroupedWindowAddedAnimation
    }

    Binding{
         //! Qt5 defaulted Binding.restoreMode to RestoreNone, so a binding whose
        //! `when` turned false simply left the property at its last value. Qt6
        //! defaults to RestoreBindingOrValue and puts the *previous* value back,
        //! which silently reset properties this code expects to persist.
        restoreMode: Binding.RestoreNone
       target: view && view.indicator ? view.indicator.info : null
        property:"providesGroupedWindowRemovedAnimation"
        when: view && view.indicator
        value: _indicators.info.providesGroupedWindowRemovedAnimation
    }

    Binding{
         //! Qt5 defaulted Binding.restoreMode to RestoreNone, so a binding whose
        //! `when` turned false simply left the property at its last value. Qt6
        //! defaults to RestoreBindingOrValue and puts the *previous* value back,
        //! which silently reset properties this code expects to persist.
        restoreMode: Binding.RestoreNone
       target: view && view.indicator ? view.indicator.info : null
        property:"providesFrontLayer"
        when: view && view.indicator
        value: _indicators.info.providesFrontLayer
    }

    Binding{
         //! Qt5 defaulted Binding.restoreMode to RestoreNone, so a binding whose
        //! `when` turned false simply left the property at its last value. Qt6
        //! defaults to RestoreBindingOrValue and puts the *previous* value back,
        //! which silently reset properties this code expects to persist.
        restoreMode: Binding.RestoreNone
       target: view && view.indicator ? view.indicator.info : null
        property:"extraMaskThickness"
        when: view && view.indicator
        value: _indicators.info.extraMaskThickness
    }

    Binding{
         //! Qt5 defaulted Binding.restoreMode to RestoreNone, so a binding whose
        //! `when` turned false simply left the property at its last value. Qt6
        //! defaults to RestoreBindingOrValue and puts the *previous* value back,
        //! which silently reset properties this code expects to persist.
        restoreMode: Binding.RestoreNone
       target: view && view.indicator ? view.indicator.info : null
        property:"minLengthPadding"
        when: view && view.indicator
        value: _indicators.info.minLengthPadding
    }

    Binding{
         //! Qt5 defaulted Binding.restoreMode to RestoreNone, so a binding whose
        //! `when` turned false simply left the property at its last value. Qt6
        //! defaults to RestoreBindingOrValue and puts the *previous* value back,
        //! which silently reset properties this code expects to persist.
        restoreMode: Binding.RestoreNone
       target: view && view.indicator ? view.indicator.info : null
        property:"minThicknessPadding"
        when: view && view.indicator
        value: _indicators.info.minThicknessPadding
    }
}
