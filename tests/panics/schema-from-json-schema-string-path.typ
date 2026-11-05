// expect: schema-from-json-schema does not take a string path
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema("/tests/fixtures/schema.json")
