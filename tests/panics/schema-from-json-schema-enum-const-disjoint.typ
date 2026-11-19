// expect: at the root: "const" 2 is not one of the "enum" values [1], so the schema is unsatisfiable.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((enum: (1,), const: 2))
