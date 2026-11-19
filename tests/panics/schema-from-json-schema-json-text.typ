// expect: schema-from-json-schema does not take JSON text: decode it with json(bytes(..))
#import "/lib.typ": schema-from-json-schema
#schema-from-json-schema("{\"type\": \"string\"}")
