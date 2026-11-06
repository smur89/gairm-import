// expect: unknown `type` name "strng"; expected one of:
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "strng", enum: ("a", "b")))
