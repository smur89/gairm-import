// expect: unsupported JSON Schema keyword(s): "min\u0001".
#import "/lib.typ": schema-from-json-schema
#schema-from-json-schema(json(
  bytes("{\"type\": \"string\", \"min\\u0001\": 1}"),
))
