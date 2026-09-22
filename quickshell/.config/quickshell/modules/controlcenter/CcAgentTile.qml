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

    // The whole card is ONE Repeater over AgentUsage.rows. Anything declared as a
    // sibling AFTER a Repeater inside a Column never got laid out here (later agents
    // and the per-model rows silently vanished), so the card is built from a single
    // flat row list instead of nested repeaters.
    Column {
        id: list
        visible: AgentUsage.rows.length > 0
        anchors { top: head.bottom; left: parent.left; right: parent.right; bottom: parent.bottom; topMargin: Theme.s2; leftMargin: Theme.s4; rightMargin: Theme.s4; bottomMargin: Theme.s3 }
        spacing: 3
        clip: true

        Repeater {
            model: AgentUsage.rows

            delegate: Item {
                required property var modelData
                readonly property string kind: modelData.kind
                readonly property real pct: kind === "limit" ? Math.max(0, Math.min(1, modelData.pct)) : 0
                readonly property bool hot: kind === "limit" && pct >= 0.9

                width: list.width
                height: kind === "agent" ? 17
                      : kind === "limit" ? 25
                      : kind === "note"  ? 15
                      : 15

                StyledText {
                    id: left
                    anchors.top: parent.top; anchors.left: parent.left
                    anchors.right: right.left; anchors.rightMargin: Theme.s2
                    elide: Text.ElideRight
                    variant: parent.kind === "agent" ? "label" : "caption"
                    text: {
                        if (parent.kind !== "limit") return modelData.a;
                        const r = tile.resetText(modelData.resetsAt);
                        return r === "" ? modelData.a : modelData.a + "  ·  " + r;
                    }
                    color: parent.kind === "agent" ? Theme.inkPrimary
                         : parent.kind === "model" ? Theme.inkDim
                         : parent.kind === "limit" ? Theme.inkDim
                         : Theme.inkFaint
                }

                StyledText {
                    id: right
                    anchors.top: parent.top; anchors.right: parent.right
                    visible: String(modelData.b) !== ""
                    variant: "caption"
                    text: modelData.b
                    color: parent.hot ? Theme.bad
                         : parent.kind === "model" ? Theme.inkDim
                         : parent.kind === "limit" ? Theme.inkDim
                         : Theme.inkFaint
                }

                // meter, limits only: dim track, bright fill
                Rectangle {
                    visible: parent.kind === "limit"
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.top: left.bottom; anchors.topMargin: 3
                    height: 6
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
