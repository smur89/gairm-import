// expect: schema-from-json-schema — "dependencies" names keys not in "properties" of an object that takes no other keys: c.
// Named by the keyword the schema used, draft 7's `dependencies` here.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "object",
  properties: (a: (type: "string")),
  dependencies: (a: ("c",)),
))
