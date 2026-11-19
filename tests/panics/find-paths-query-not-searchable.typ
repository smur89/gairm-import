// expect: find-paths query must be a schema node or a constructor of a kind it can find (string, markup, number, integer, boolean, null, unknown, enum, union, not, if); object and array are walked through, not searched for, got: array-of.
#import "../../lib.typ": find-paths, array-of, object
#find-paths(object((:)), array-of)
