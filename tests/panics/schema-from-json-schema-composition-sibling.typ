// expect: sibling keywords beside "anyOf" are not supported
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((anyOf: ((type: "string"),), type: "string"))
