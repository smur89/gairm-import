// expect: - name: expected string, got integer.
#import "../../lib.typ": parse, object, string
#parse(object((name: string())), (name: 1))
