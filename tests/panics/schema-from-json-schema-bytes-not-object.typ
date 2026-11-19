// expect: schema-from-json-schema — the document must be a JSON object (a schema), got: an array.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema(bytes("[1]"))
