.pragma library

function normalize(value) {
    return String(value || "").toLocaleLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/ł/g, "l");
}

function index(entries) {
    return entries.map(function (entry) {
        return {entry: entry, name: normalize(entry.name), haystack: normalize([entry.name, entry.genericName, entry.id, (entry.keywords || []).join(" ")].join(" "))};
    });
}

function score(query, item) {
    if (item.name === query) return 10000;
    if (item.name.startsWith(query)) return 5000 - item.name.length;
    var direct = item.haystack.indexOf(query);
    if (direct !== -1) return 2500 - direct;
    var cursor = 0, previous = -1, result = 0;
    for (var i = 0; i < query.length; ++i) {
        var found = item.haystack.indexOf(query[i], cursor);
        if (found === -1) return -1;
        result += found === previous + 1 ? 16 : 2;
        if (found === 0 || /[ ._\-/]/.test(item.haystack[found - 1])) result += 12;
        result -= Math.min(found - cursor, 10);
        previous = found;
        cursor = found + 1;
    }
    return result;
}

function search(query, items, usage, limit) {
    query = normalize(query.trim());
    var results = [];
    for (var i = 0; i < items.length; ++i) {
        var item = items[i];
        var rank = query ? score(query, item) : 0;
        if (rank < 0) continue;
        rank += Math.min(usage[item.entry.id] || 0, 30) * (query ? 0.2 : 10);
        results.push({entry: item.entry, rank: rank});
    }
    results.sort(function (a, b) { return b.rank - a.rank || a.entry.name.localeCompare(b.entry.name); });
    return results.slice(0, limit || 60).map(function (item) { return item.entry; });
}
