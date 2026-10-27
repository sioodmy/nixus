import QtQuick

Item {
    id: root
    property bool active: true
    property bool carrying: false
    property bool moving: false
    property string clipName: ""
    readonly property int frameCount: movie.frameCount
    readonly property bool loaded: still.status === Image.Ready && (clipName === "" || movie.status === Image.Ready)
    readonly property var durations: ({
        "blink": 1050, "look": 4000, "nose": 3000,
        "yawn": 3000, "sway": 1500, "peek": 2000, "yawn2": 3500, "cross": 3500,
        "dig": 7000, "plane": 11000,
        "move-start": 250, "move-loop": 1500, "move-finish": 750,
        "drag-start": 500, "drag-loop": 1500, "drag-cancel": 500, "drop": 6500,
        "music": 6500, "screenshot": 7000,
        "paper-start": 2000, "paper-loop": 5000, "paper-done": 2000,
        "book-start": 2000, "book-loop": 5000, "book-done": 2500,
        "sleep-start": 3500, "sleep-loop": 6000, "sleep-done": 4000
    })
    // Multi-part activities: each clip hands control to the next when it ends.
    readonly property var chains: ({
        "paper-start": "paper-loop", "paper-loop": "paper-done",
        "book-start": "book-loop", "book-loop": "book-done",
        "sleep-start": "sleep-loop", "sleep-loop": "sleep-done"
    })
    implicitWidth: 84
    implicitHeight: 88

    function rest() {
        playback.stop();
        clipName = "";
    }
    function play(name) {
        if (!active || Theme.reducedMotion) return;
        if (clipName === name) {
            playback.restart();
        } else {
            playback.stop();
            clipName = name;
        }
    }
    function react() {
        if (!active || Theme.reducedMotion) rest();
        else if (carrying && clipName.indexOf("drag-") !== 0) play("drag-start");
        else if (!carrying && moving && clipName.indexOf("move-") !== 0) play("move-start");
        else if (!carrying && (clipName === "drag-start" || clipName === "drag-loop")) play("drag-cancel");
        else if (!moving && (clipName === "move-start" || clipName === "move-loop")) play("move-finish");
    }
    function advance() {
        if (clipName === "drag-start" || clipName === "drag-loop") play(carrying ? "drag-loop" : "drag-cancel");
        else if (clipName === "move-start" || clipName === "move-loop") play(moving ? "move-loop" : "move-finish");
        else if (chains[clipName]) play(chains[clipName]);
        else rest();
    }
    onCarryingChanged: react()
    onMovingChanged: react()
    onActiveChanged: react()

    // Keep the original 256px canvas and a common foot position. Props can
    // extend beyond the small hit target without making the desktop capture input.
    Item {
        x: root.width / 2 - 196 * 0.74
        y: root.height - 4 - 240 * 0.74
        width: 256 * 0.74
        height: width
        Image {
            id: still
            anchors.fill: parent
            source: "assets/chomikbox/idle.png"
            visible: root.clipName === "" || movie.status !== Image.Ready
        }
        AnimatedImage {
            id: movie
            anchors.fill: parent
            source: root.clipName ? Qt.resolvedUrl("assets/chomikbox/" + root.clipName + ".webp") : ""
            visible: root.clipName !== "" && status === Image.Ready
            playing: visible && root.active && !Theme.reducedMotion
            // Decode frames on demand instead of retaining every animation in memory.
            cache: false
            onStatusChanged: if (status === Image.Ready && root.clipName) playback.restart()
        }
    }
    Timer {
        id: playback
        interval: root.durations[root.clipName] || 50
        onTriggered: root.advance()
    }
    Timer {
        interval: 10000
        repeat: true
        running: root.active && !Theme.reducedMotion && root.clipName === ""
        property string last: ""
        // Weighted pools: fidgets fill most idle moments, activities are rarer.
        readonly property var fidgets: [
            ["blink", 30], ["sway", 12], ["peek", 10], ["look", 8],
            ["nose", 8], ["yawn", 8], ["yawn2", 6], ["cross", 5]
        ]
        readonly property var activities: [
            ["plane", 4], ["dig", 3], ["paper", 2], ["book", 2], ["sleep", 2]
        ]
        function pick(pool) {
            let total = 0;
            for (const entry of pool) total += entry[1];
            let roll = Math.random() * total;
            for (const entry of pool) {
                roll -= entry[1];
                if (roll <= 0) return entry[0];
            }
            return pool[pool.length - 1][0];
        }
        onTriggered: {
            let name = pick(Math.random() < 0.15 ? activities : fidgets);
            if (name === last) name = pick(fidgets);
            last = name;
            root.play(name);
        }
    }
    Connections {
        target: Theme
        function onReducedMotionChanged() { root.react(); }
    }
}
