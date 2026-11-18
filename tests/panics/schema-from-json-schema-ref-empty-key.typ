// expect: $ref "#/" could not be resolved (segment "" missing).
// `#/` is a JSON Pointer to the key "", not the root.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "object", properties: (x: ("$ref": "#/"))))
