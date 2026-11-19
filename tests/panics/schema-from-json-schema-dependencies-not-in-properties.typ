// expect: schema-from-json-schema — "dependencies" must be only declared fields (the object takes no other keys), got: "c".
// Named by the keyword the schema used, draft 7's `dependencies` here.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  type: "object",
  properties: (a: (type: "string")),
  dependencies: (a: ("c",)),
))
