// expect: string schema format must be one of "date", "date-time", "uri", "email", "uuid", "hostname", "ipv4", "ipv6", "time", got: "emial".
// Hand-built, since string() rejects an unknown format.
#import "../../lib.typ": validate
#validate((kind: "string", format: "emial"), "a@b.c")
