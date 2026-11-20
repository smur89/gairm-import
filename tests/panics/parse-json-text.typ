// expect: parse does not take JSON text: decode it with json(bytes(..)), or read the file with read(.., encoding: none).
#import "/lib.typ": parse, object, string
#parse(object((a: string())), " {\"a\": \"x\"}")
