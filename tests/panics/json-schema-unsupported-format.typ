// expect: "format" must be one of "date", "date-time", "uri", "email", "uuid", "hostname", "ipv4", "ipv6", "time", got: "iri".
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "string", format: "iri"))
