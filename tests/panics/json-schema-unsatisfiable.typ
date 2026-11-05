// expect: minLength (2) > maxLength (1) is unsatisfiable.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "string", minLength: 2, maxLength: 1))
