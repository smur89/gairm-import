// expect: parse does not take a string path
#import "../../lib.typ": parse, object
#parse(object((:)), "/tests/fixtures/resume-minimal.json")
