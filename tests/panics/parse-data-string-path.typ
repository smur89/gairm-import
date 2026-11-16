// expect: parse does not take a string path
#import "../../lib.typ": parse, object
#parse("/tests/fixtures/resume-minimal.json", schema: object((:)))
