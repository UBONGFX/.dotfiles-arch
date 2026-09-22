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
    // flat display rows for the card (see the python below)
    property var rows: []
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
import glob, json, os, re

def fmt_tokens(n):
    if n >= 1e9: return '%.1fB' % (n / 1e9)
    if n >= 1e6: return '%.1fM' % (n / 1e6)
    if n >= 1e3: return '%.1fK' % (n / 1e3)
    return str(n)

def _word(w):
    return {'gpt': 'GPT', 'deepseek': 'DeepSeek'}.get(w, w[:1].upper() + w[1:])

# Model ids arrive hyphenated with the version split across segments
# ('claude-opus-5', 'gpt-5.6-sol'): rejoin the numeric run and title-case the rest.
def friendly_model(mid):
    if not mid: return 'Unknown'
    name = re.sub(r'-\d{8}$', '', re.sub(r'^claude-', '', str(mid)))
    words, version = [], []
    for part in name.split('-'):
        if not part: continue
        if part[0].isdigit():
            version.append(part); continue
        if version:
            words.append('.'.join(version)); version = []
        words.append(_word(part))
    if version: words.append('.'.join(version))
    return ' '.join(words) or 'Unknown'

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
    # Tokens by model, biggest first. Same shape omarchy's panel showed: the four
    # heaviest models with their all-time totals (input + output + both cache legs).
    models = []
    for mid, b in (d.get('modelUsage') or {}).items():
        if not isinstance(b, dict):
            continue
        total = sum(int(b.get(k) or 0) for k in
                    ('inputTokens', 'outputTokens', 'cacheReadInputTokens', 'cacheCreationInputTokens'))
        if total <= 0:
            continue
        models.append({'name': friendly_model(mid), 'total': total, 'text': fmt_tokens(total)})
    models.sort(key=lambda m: -m['total'])
    models = models[:4]

    out.append({'id': str(d.get('id') or ''),
                'name': str(d.get('name') or d.get('id') or ''),
                'tierLabel': str(d.get('tierLabel') or ''),
                'ready': bool(d.get('ready')),
                # what to show when there are no limit windows to draw
                'statusText': str(d.get('usageStatusText') or ''),
                'helpText': str(d.get('authHelpText') or ''),
                'updatedAt': str(d.get('updatedAt') or ''),
                'todayPrompts': int(d.get('todayPrompts') or 0),
                'todayTokens': fmt_tokens(int(d.get('todayTotalTokens') or 0)),
                'models': models,
                'limits': limits})
# One flat list of display rows for the whole card. QML renders this with a single
# Repeater: a Column that declares siblings AFTER a Repeater never laid them out,
# so the card is built from exactly one repeater and no trailing siblings.
rows = []
for a in out:
    # An agent with neither quota nor per-model tokens has nothing to show but an
    # "unavailable" line; skip it rather than spend rows on it. Any collector that
    # starts reporting real data appears here on its own.
    if not a['limits'] and not a['models']:
        continue
    rows.append({'kind': 'agent', 'a': a['name'], 'b': a['tierLabel']})
    for l in a['limits']:
        pct = l['percent']
        label = l['label']
        rows.append({'kind': 'limit', 'a': label, 'b': '%d%%' % round(pct * 100),
                     'pct': pct, 'resetsAt': l['resetsAt']})
    if a['models']:
        rows.append({'kind': 'head', 'a': 'Tokens by model',
                     'b': (a['todayTokens'] + ' today') if a['todayTokens'] not in ('', '0') else ''})
        # Share is scaled to the HEAVIEST model, not to the sum, so the top row is
        # always a full bar -- same scale-to-peak omarchy used, which keeps the
        # smaller models readable instead of collapsing them to a sliver.
        peak = max(1, a['models'][0]['total'])
        for m in a['models']:
            rows.append({'kind': 'model', 'a': m['name'], 'b': m['text'],
                         'share': m['total'] / peak})
    if not a['limits']:
        note = a['helpText'] if (not a['ready'] and a['helpText']) else (a['statusText'] or 'No quota reported')
        rows.append({'kind': 'note', 'a': note, 'b': ''})
print(json.dumps({'agents': out, 'rows': rows}))
`]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim();
                if (raw === "" || raw === root.lastRaw) return;
                let payload = null;
                try { payload = JSON.parse(raw); } catch (e) { return; }
                let out = payload.agents || [];
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
                root.rows = payload.rows || [];
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
