// expect: unsupported string format: "iri".
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "string", format: "iri"))
