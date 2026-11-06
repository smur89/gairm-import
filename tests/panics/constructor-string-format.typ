// expect: string() format must be one of "date", "date-time", "uri", "email", "uuid", "hostname", "ipv4", "ipv6", "time"; got: "emial".
#import "../../lib.typ": string
#string(format: "emial")
