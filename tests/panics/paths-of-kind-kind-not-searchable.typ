// expect: paths-of-kind kind must be a schema node or a constructor of a kind it can find (string, content, number, integer, bool, null, any, enum, union, not, if); object and array are walked through, not searched for, got: array-of.
#import "../../lib.typ": paths-of-kind, array-of, object
#paths-of-kind(object((:)), array-of)
