// _closest-match ranks candidates by Levenshtein edit distance and
// returns the closest one if it's within the budget, else none. The
// underlying _edit-distance helper is exercised here too so a refactor
// of the DP table can't silently regress.

#import "../internal/errors.typ": _edit-distance, _closest-match

// _edit-distance: identity, single-edit cases, a transposition (2 edits
// under classic Levenshtein), and an empty-string baseline.
#assert.eq(_edit-distance("", ""), 0)
#assert.eq(_edit-distance("position", "position"), 0)
#assert.eq(_edit-distance("", "abc"), 3)
#assert.eq(_edit-distance("abc", ""), 3)
#assert.eq(_edit-distance("postion", "position"), 1)   // single insertion
#assert.eq(_edit-distance("positon", "position"), 1)   // missing one 'i'
#assert.eq(_edit-distance("psoition", "position"), 2)  // o/s transposition = 2 edits
#assert.eq(_edit-distance("contact", "summary"), 6)    // 6 substitutions; 'a' aligns at index 4

// _closest-match: distance-1 hit.
#assert.eq(
  _closest-match("postion", ("name", "position", "url"), 2),
  "position",
)

// Distance-2 hit (o/s transposition needs delete + insert under
// classic Levenshtein).
#assert.eq(
  _closest-match("psoition", ("name", "position", "url"), 2),
  "position",
)

// Distance-1 hit (extra character) for a short key.
#assert.eq(
  _closest-match("enmail", ("name", "email", "phone"), 2),
  "email",
)

// Distance > max-distance → none (no false suggestion).
#assert.eq(
  _closest-match("contact", ("name", "email", "phone"), 2),
  none,
)

// Empty candidates → none.
#assert.eq(_closest-match("anything", (), 2), none)

// Picks the closer of two near candidates.
#assert.eq(
  _closest-match("nme", ("name", "email"), 2),
  "name",
)
