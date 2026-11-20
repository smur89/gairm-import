// expect: "const" 9007199254740992.0 is not one of the "enum" values [9007199254740993]
#import "/lib.typ": schema-from-json-schema
#schema-from-json-schema(json(
  bytes("{\"enum\": [9007199254740993], \"const\": 9007199254740992.0}"),
))
