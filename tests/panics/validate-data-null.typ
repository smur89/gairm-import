// expect: gairm-import: validate data must not be null: the document root has to be a value the schema accepts.
#import "../../lib.typ": validate, object
#validate(object((:)), none)
