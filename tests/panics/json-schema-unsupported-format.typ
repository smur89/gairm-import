// expect: unsupported string format: "ipv4".
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "string", format: "ipv4"))
