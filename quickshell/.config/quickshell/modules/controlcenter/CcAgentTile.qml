import QtQuick
import Quickshell
import "../../theme"
import "../../config"
import "../../services"
import "../../components"

// AI agent usage as a card: one block per agent that has a collector, each with its
// limit windows drawn as label / percentage / meter / reset countdown.
//
// Agents without limit windows are the normal case, not an error -- only Claude
// reports quota; Codex and Fireworks ship records with `limits: []` and a status
// line instead. Those render their status text rather than an empty card, and an
// agent that is not `ready` shows its auth hint ("Run `claude auth login` ...").
Item {
    id: tile

    property var ctl: null
    readonly property bool interactive: ctl ? ctl.interactive : true

    Rectangle {
        anchors.fill: parent
        radius: Theme.rXl
        color: Theme.surfaceOverlay
    }

    // Hairline rim, same as the other cards: drawn on top so hover veils never soften it.
    Rectangle {
        anchors.fill: parent
        radius: Theme.rXl
        color: "transparent"
        border.width: 1
        border.color: Theme.rim
        z: 5
    }

    Item {
        id: head
        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: Theme.s3; leftMargin: Theme.s4; rightMargin: Theme.s4 }
        height: 18

        Icon {
            id: headIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            name: "sparkle"
            size: 14
            color: AgentUsage.alarming ? Theme.bad : Theme.inkDim
            Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
        }

        StyledText {
            anchors.left: headIcon.right; anchors.leftMargin: Theme.s2
            capCentreIn: parent
            variant: "caption"; text: "AI Usage"; color: Theme.inkDim
        }

        // The worst open window, so the header carries the number even when the card is
        // too short to show every row.
        StyledText {
            anchors.right: parent.right; capCentreIn: parent
            visible: !!AgentUsage.headline
            variant: "caption"
            text: AgentUsage.headline ? Math.round(AgentUsage.headline.percent * 100) + "%" : ""
            color: AgentUsage.alarming ? Theme.bad : Theme.inkDim
            Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
        }
    }

    StyledText {
        visible: AgentUsage.agents.length === 0
        anchors { top: head.bottom; left: parent.left; topMargin: Theme.s2; leftMargin: Theme.s4 }
        variant: "label"; text: "No agent data"; color: Theme.inkDim
    }

    ListView {
        id: list
        visible: AgentUsage.agents.length > 0
        anchors { top: head.bottom; left: parent.left; right: parent.right; bottom: parent.bottom; topMargin: Theme.s2; leftMargin: Theme.s4; rightMargin: Theme.s4; bottomMargin: Theme.s3 }
        clip: true
        interactive: false
        spacing: Theme.s3
        model: AgentUsage.agents

        delegate: Column {
            required property var modelData
            width: list.width
            spacing: Theme.s2

            // agent name + plan
            Item {
                width: parent.width
                height: 16
                StyledText {
                    anchors.left: parent.left; capCentreIn: parent
                    variant: "label"
                    text: modelData.name
                    color: Theme.inkPrimary
                }
                StyledText {
                    anchors.right: parent.right; capCentreIn: parent
                    visible: String(modelData.tierLabel) !== ""
                    variant: "caption"
                    text: modelData.tierLabel
                    color: Theme.inkFaint
                }
            }

            // One row per limit window.
            Repeater {
                model: modelData.limits || []
                delegate: Item {
                    required property var modelData
                    width: list.width
                    // one text line + meter. The reset countdown rides the label line
                    // rather than sitting under the meter: stacked, each window cost 34px
                    // and the second one fell off the bottom of the card.
                    height: 22
                    readonly property real pct: Math.max(0, Math.min(1, modelData.percent))
                    readonly property bool hot: pct >= 0.9

                    StyledText {
                        id: lbl
                        anchors.top: parent.top; anchors.left: parent.left
                        anchors.right: pctText.left; anchors.rightMargin: Theme.s2
                        elide: Text.ElideRight
                        variant: "caption"
                        text: {
                            const r = tile.resetText(modelData.resetsAt);
                            return r === "" ? modelData.label : modelData.label + "  ·  " + r;
                        }
                        color: Theme.inkDim
                    }
                    StyledText {
                        id: pctText
                        anchors.top: parent.top; anchors.right: parent.right
                        variant: "caption"
                        text: Math.round(parent.pct * 100) + "%"
                        color: parent.hot ? Theme.bad : Theme.inkDim
                    }

                    // meter: dim track, bright fill
                    Rectangle {
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.top: lbl.bottom; anchors.topMargin: 3
                        height: 4
                        radius: height / 2
                        color: Theme.fillLow
                        Rectangle {
                            width: Math.max(parent.height, parent.width * parent.parent.pct)
                            height: parent.height
                            radius: parent.radius
                            color: parent.parent.hot ? Theme.bad : Theme.accent
                            Behavior on width { NumberAnimation { duration: Theme.dur(Theme.dFast) } }
                            Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
                        }
                    }
                }
            }

            // No windows to draw: say why rather than leaving a gap.
            StyledText {
                visible: !(modelData.limits && modelData.limits.length > 0)
                width: parent.width
                variant: "caption"
                wrapMode: Text.WordWrap
                text: !modelData.ready && String(modelData.helpText) !== "" ? modelData.helpText
                    : String(modelData.statusText) !== "" ? modelData.statusText
                    : "No quota reported"
                color: Theme.inkFaint
            }
        }
    }

    // "resets in 1h 12m" from an ISO timestamp. Ticks off `now` so the countdown is live
    // without re-running the collector.
    property date now: new Date()
    Timer { interval: 30000; running: tile.visible; repeat: true; onTriggered: tile.now = new Date() }

    function resetText(iso) {
        if (!iso) return "";
        const t = Date.parse(String(iso).replace(" ", "T"));
        if (isNaN(t)) return "";
        let s = Math.floor((t - now.getTime()) / 1000);
        if (s <= 0) return "resetting";
        const d = Math.floor(s / 86400); s -= d * 86400;
        const h = Math.floor(s / 3600);  s -= h * 3600;
        const m = Math.floor(s / 60);
        if (d > 0) return "resets in " + d + "d " + h + "h";
        if (h > 0) return "resets in " + h + "h " + m + "m";
        return "resets in " + m + "m";
    }

    // Opening the control center is the moment the number matters, so refresh then.
    onVisibleChanged: if (visible) AgentUsage.update()
}
