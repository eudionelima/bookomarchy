// Pure search/filter/CRUD helpers. No Qt state, no IO.
function searchable(entry) {
  return [
    entry.title, entry.target, entry.category,
    entry.description,
    (entry.aliases || []).join(" "),
    (entry.tags || []).join(" ")
  ].join(" ").toLowerCase();
}

function matchesQuery(entry, query, activeCategory) {
  if (activeCategory && activeCategory !== "All" && String(entry.category || "") !== activeCategory) return false;
  var q = String(query || "").trim().toLowerCase();
  if (!q) return true;
  // Numeric quick-key: "3" matches everything so Enter can open nth row.
  if (/^[1-9]$/.test(q)) return true;
  var terms = q.split(/\s+/);
  var hay = searchable(entry);
  for (var i = 0; i < terms.length; i++) {
    if (hay.indexOf(terms[i]) < 0) return false;
  }
  return true;
}

function searchScore(entry, query) {
  var q = String(query || "").trim().toLowerCase();
  if (!q || /^[1-9]$/.test(q)) return (entry.favorite ? 0 : 10) + (entry.order || 0);
  var title = String(entry.title || "").toLowerCase();
  var aliases = entry.aliases || [];
  for (var i = 0; i < aliases.length; i++) {
    if (String(aliases[i]).toLowerCase() === q) return 0;
  }
  if (title === q) return 1;
  if (title.indexOf(q) === 0) return 2;
  if (title.indexOf(q) > 0) return 3;
  return 4;
}

function sortRows(rows) {
  return rows.sort(function(a, b) {
    if (a.score !== b.score) return a.score - b.score;
    var at = String(a.label || "").toLowerCase();
    var bt = String(b.label || "").toLowerCase();
    if (at < bt) return -1;
    if (at > bt) return 1;
    return 0;
  });
}

function categoriesOf(bookmarks) {
  var seen = {};
  var out = ["All"];
  for (var i = 0; i < bookmarks.length; i++) {
    var c = String(bookmarks[i].category || "General");
    if (!seen[c]) { seen[c] = true; out.push(c); }
  }
  return out;
}

function slugify(title, existingIds) {
  var base = String(title || "bookmark").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "") || "bookmark";
  var id = base, n = 2;
  while (existingIds.indexOf(id) >= 0) { id = base + "-" + n; n++; }
  return id;
}

function validate(entry) {
  if (!String(entry.title || "").trim()) return "Title is required";
  if (!String(entry.target || "").trim()) return "Target is required";
  var t = String(entry.type || "url");
  if (["url", "file", "directory", "application", "command", "ssh"].indexOf(t) < 0) return "Invalid type";
  if (t === "url" && !/^https?:\/\//.test(entry.target) && entry.target.indexOf("~") !== 0 && entry.target.indexOf("/") !== 0) {
    // Allow bare domains by auto-prefixing https at launch; validation stays lenient.
  }
  return "";
}

function normalizeUrl(target) {
  var t = String(target || "").trim();
  if (/^https?:\/\//.test(t)) return t;
  if (/^[\w-]+(\.[\w-]+)+(\/\S*)?$/.test(t)) return "https://" + t;
  return t;
}
