// expect: unknown `type` name "foo" in ["string", "foo"]
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: ("string", "foo")))
