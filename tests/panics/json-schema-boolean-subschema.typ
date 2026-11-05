// expect: a subschema must be a schema object, got: true. Boolean schemas (true / false) are out of scope.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "object", properties: (a: true)))
