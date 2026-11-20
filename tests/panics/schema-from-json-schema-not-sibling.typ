// expect: at the root: sibling keywords beside "not" are not supported: "type", "properties". Moving them into "not" would negate them; write {"if": <the "not" schema>, "then": {"not": {}}, "else": <the other keywords>} instead.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "object",
  properties: (a: (type: "string")),
  "not": (required: ("a",)),
))
