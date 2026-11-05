// expect: expected a parsed JSON Schema dict, path(...), or bytes, got: type(none).
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema(bytes("null"))
