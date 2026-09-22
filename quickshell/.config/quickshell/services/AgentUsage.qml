pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// AI agent usage (Claude Code's 5-hour and weekly windows, and whatever else has a
// collector). The split is the one the collectors were written for: each
// ~/.local/bin/agent-usage-<agent> prints one display-ready JSON record and
// agent-usage-update writes them to the state dir; this service NEVER parses
// transcripts or calls endpoints, it only reads those records.
//
// Reading is one python3 pass over the directory rather than a FileView per agent:
// the records only change when the updater runs, so there is nothing to watch
// between refreshes, and this matches how Themes.qml already reads its schemes.
Singleton {
    id: root

    // [{ id, name, tierLabel, ready, statusText, helpText, updatedAt,
    //    limits: [{ label, percent, resetsAt }] }], alphabetical by name.
    property var agents: []
    // raw payload of the last publish, so an unchanged refresh is a no-op: handing
    // back an equal-but-new array swaps identity and resets every bound view, which
    // would flicker the tile each time the control center opens (Themes.qml, same trap).
    property string lastRaw: ""

    // The single most-used open window across all agents, for a collapsed tile that
    // only has room for one number. null when nothing reports a limit.
    readonly property var headline: {
        let best = null;
        for (const a of agents)
            for (const l of (a.limits || []))
                if (l.percent >= 0 && (!best || l.percent > best.percent))
                    best = { agent: a.name, label: l.label, percent: l.percent, resetsAt: l.resetsAt };
        return best;
    }
    readonly property bool alarming: !!headline && headline.percent >= 0.9

    // Re-read the records that are already on disk. Cheap, no network.
    function refresh() { if (!readProc.running) readProc.running = true; }

    // Re-run the collectors, then re-read. Hits the network (Anthropic's usage
    // endpoint), so it is kept to shell start, control-center opens, and the timer.
    // The collectors do their own probe caching, so calling this often is not abusive.
    function update() { if (!updateProc.running) updateProc.running = true; }

    Process {
        id: updateProc
        running: true
        command: ["agent-usage-update"]
        onExited: root.refresh()
    }

    Process {
        id: readProc
        running: true
        // python3 rather than jq: jq is not guaranteed present, and Themes.qml already
        // learned that lesson the hard way (every swatch rendered black the day it went
        // missing). python3 is effectively always there on Arch.
        command: ["python3", "-c", `
import glob, json, os
state = os.environ.get('XDG_STATE_HOME') or os.path.expanduser('~/.local/state')
out = []
for f in sorted(glob.glob(os.path.join(state, 'agents', 'usage', '*.json'))):
    try:
        d = json.load(open(f))
    except Exception:
        continue
    limits = []
    for l in (d.get('limits') or []):
        try:
            limits.append({'label': str(l.get('label') or ''),
                           'percent': float(l.get('percent', -1)),
                           'resetsAt': str(l.get('resetsAt') or '')})
        except Exception:
            pass
    out.append({'id': str(d.get('id') or ''),
                'name': str(d.get('name') or d.get('id') or ''),
                'tierLabel': str(d.get('tierLabel') or ''),
                'ready': bool(d.get('ready')),
                # what to show when there are no limit windows to draw
                'statusText': str(d.get('usageStatusText') or ''),
                'helpText': str(d.get('authHelpText') or ''),
                'updatedAt': str(d.get('updatedAt') or ''),
                'todayPrompts': int(d.get('todayPrompts') or 0),
                'limits': limits})
print(json.dumps(out))
`]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim();
                if (raw === "" || raw === root.lastRaw) return;
                let out = [];
                try { out = JSON.parse(raw); } catch (e) { return; }
                // Agents that actually report quota come first -- Codex and Fireworks
                // ship records with no limit windows, and burying Claude under two
                // "unavailable" lines would waste the rows that matter.
                out.sort((a, b) => {
                    const al = (a.limits || []).length > 0, bl = (b.limits || []).length > 0;
                    if (al !== bl) return al ? -1 : 1;
                    return String(a.name).localeCompare(String(b.name));
                });
                root.lastRaw = raw;
                root.agents = out;
            }
        }
    }

    // The windows are 5-hour and 7-day, so there is nothing to gain from polling hard.
    Timer {
        interval: 10 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.update()
    }
}
