// expect: at /if: a subschema must be a schema object, got: 5.
// With neither branch the condition checks nothing, but it is still
// checked.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema(("if": 5))
