# Changelog

## [0.13.0](https://github.com/smur89/gairm-import/compare/v0.12.0...v0.13.0) (2026-11-12)


### Features

* deprecate the bundled JSON Resume schemas and the schema: default ([#205](https://github.com/smur89/gairm-import/issues/205)) ([11a3dcf](https://github.com/smur89/gairm-import/commit/11a3dcfb6222e73031e3bc415e112a30f4207ec7))

## [0.12.0](https://github.com/smur89/gairm-import/compare/v0.11.0...v0.12.0) (2026-11-06)


### Features

* support if / then / else conditional schemas ([#201](https://github.com/smur89/gairm-import/issues/201)) ([c8383b7](https://github.com/smur89/gairm-import/commit/c8383b7c5c482df29f375680a5b5b5a642dee3ec))

## [0.11.0](https://github.com/smur89/gairm-import/compare/v0.10.1...v0.11.0) (2026-11-06)


### Features

* accept a datetime for date-string and datetime-string ([#144](https://github.com/smur89/gairm-import/issues/144)) ([b5670d1](https://github.com/smur89/gairm-import/commit/b5670d145ec2fec42dfa9e6cbf470e49ece5495c)), closes [#134](https://github.com/smur89/gairm-import/issues/134)
* accept bytes in parse and schema-from-json-schema ([#143](https://github.com/smur89/gairm-import/issues/143)) ([23a0af7](https://github.com/smur89/gairm-import/commit/23a0af7d7b89a967c33ef949ea52a8ca633ce6f3)), closes [#133](https://github.com/smur89/gairm-import/issues/133)
* accept union members as separate arguments ([12e8047](https://github.com/smur89/gairm-import/commit/12e804753f82749cbd7bacba8dac2b27828bdbab))
* add a code, expected and got to every validation error ([#177](https://github.com/smur89/gairm-import/issues/177)) ([39365f2](https://github.com/smur89/gairm-import/commit/39365f28b2f87790edc9e51e5bd6373c577f17ab))
* add required: to add-field ([12e8047](https://github.com/smur89/gairm-import/commit/12e804753f82749cbd7bacba8dac2b27828bdbab))
* compose format and pattern on a string schema ([#151](https://github.com/smur89/gairm-import/issues/151)) ([976c24c](https://github.com/smur89/gairm-import/commit/976c24cc1ea33ac72cc870e8f800dc639f231d4b)), closes [#115](https://github.com/smur89/gairm-import/issues/115)
* deprecate passing paths-of-kind a kind name string; pass the kind value (e.g. date-string) instead, as the string form goes in the next major ([39379bb](https://github.com/smur89/gairm-import/commit/39379bbf631413ae324e8ef46948203c0f1aae23))
* deprecate str-type, number-type, integer-type, pattern-string, the format constants, lens, lens-then and kind-at in favour of the constructors and paths ([12e8047](https://github.com/smur89/gairm-import/commit/12e804753f82749cbd7bacba8dac2b27828bdbab))
* fold constraint keywords into enum / const membership ([#152](https://github.com/smur89/gairm-import/issues/152)) ([a8534e3](https://github.com/smur89/gairm-import/commit/a8534e3d47054d3481b9fd699caa0da4ac4376d1)), closes [#111](https://github.com/smur89/gairm-import/issues/111)
* let lenses and introspection reach into unions and not ([#181](https://github.com/smur89/gairm-import/issues/181)) ([45ae3f6](https://github.com/smur89/gairm-import/commit/45ae3f684bffc85c08bd3146ec7340a7df750a0c)), closes [#164](https://github.com/smur89/gairm-import/issues/164)
* let parse take any root the schema accepts, and share one input rule ([12e8047](https://github.com/smur89/gairm-import/commit/12e804753f82749cbd7bacba8dac2b27828bdbab))
* make a string's format a field instead of a kind ([#195](https://github.com/smur89/gairm-import/issues/195)) ([4fd09b9](https://github.com/smur89/gairm-import/commit/4fd09b95c3365261e85a313e1f054ad7bea51994))
* name the string kind "string", keeping "str" as an alias ([12e8047](https://github.com/smur89/gairm-import/commit/12e804753f82749cbd7bacba8dac2b27828bdbab))
* put the schema first and let a path stand in for a lens ([#188](https://github.com/smur89/gairm-import/issues/188)) ([0e012ca](https://github.com/smur89/gairm-import/commit/0e012ca3914c7b98150167d62f517462d8a452d5)), closes [#163](https://github.com/smur89/gairm-import/issues/163)
* support dependentRequired and array-form dependencies ([e396993](https://github.com/smur89/gairm-import/commit/e396993601fda4187e7f179ac3ecc45140c357d0))
* support uuid, hostname, ipv4, ipv6 and time string formats ([e396993](https://github.com/smur89/gairm-import/commit/e396993601fda4187e7f179ac3ecc45140c357d0))
* take Typst values where an API took a name in a string ([39379bb](https://github.com/smur89/gairm-import/commit/39379bbf631413ae324e8ef46948203c0f1aae23))
* translate JSON Schema nodes with no type ([#184](https://github.com/smur89/gairm-import/issues/184)) ([66516af](https://github.com/smur89/gairm-import/commit/66516afa5441aa8facae26dd4798593f1f5d7b6c))
* translate type arrays with several non-null members to any-of ([#153](https://github.com/smur89/gairm-import/issues/153)) ([f2bec53](https://github.com/smur89/gairm-import/commit/f2bec53e6190ae3dfb249a243259ed87f662b779)), closes [#112](https://github.com/smur89/gairm-import/issues/112)


### Bug Fixes

* assert no iso8601 leaf is left unlisted in the strict schema ([#158](https://github.com/smur89/gairm-import/issues/158)) ([b1dd488](https://github.com/smur89/gairm-import/commit/b1dd4887bc87d0f4750de6b2e3e3b58906c277e9))
* bail on malformed or null JSON Schema keyword values ([#190](https://github.com/smur89/gairm-import/issues/190)) ([91210e0](https://github.com/smur89/gairm-import/commit/91210e0b7e774a1a553bb0a7638f618edcbc4ede))
* bail on non-annotation siblings of $ref ([#150](https://github.com/smur89/gairm-import/issues/150)) ([28eaf3e](https://github.com/smur89/gairm-import/commit/28eaf3e9f9c647095183968ce5e907cb1e195c5e)), closes [#118](https://github.com/smur89/gairm-import/issues/118)
* four translator and format bugs found by the JSON Schema test suite ([#183](https://github.com/smur89/gairm-import/issues/183)) ([4b26154](https://github.com/smur89/gairm-import/commit/4b26154877c51e9fa648aaf0cddca84752180d98))
* keep a JSON Pointer index too large for an int as a string ([c833a02](https://github.com/smur89/gairm-import/commit/c833a02b86ef5ec41c844c05ee68925484d93615))
* keep object() invariants through lens edits and check incoming schemas ([#185](https://github.com/smur89/gairm-import/issues/185)) ([ca787d2](https://github.com/smur89/gairm-import/commit/ca787d2d9d5de1fe3c99e1c096b3b51b1c6b4fed))
* make the translator bail instead of dropping or misreading keywords ([#159](https://github.com/smur89/gairm-import/issues/159)) ([caf81bd](https://github.com/smur89/gairm-import/commit/caf81bd7816516e8dc7d2a3b99cabd2f0442eca0))
* make validate and coerce agree, and harden the union and number checks ([#160](https://github.com/smur89/gairm-import/issues/160)) ([2971147](https://github.com/smur89/gairm-import/commit/297114770a1b371cf0f08eae01e78ea198a2aee0))
* name tuple-form items in its panic instead of blaming boolean schemas ([b0b26cb](https://github.com/smur89/gairm-import/commit/b0b26cbfa224ad2997255729a55220026a7825c6))
* reject a string path in parse; it resolved from the package root, so pass path("…") instead ([eca2b9c](https://github.com/smur89/gairm-import/commit/eca2b9cfa6dbafb65c0a350f4c5d14bb864a631f))
* report a null JSON Schema as a schema problem, not a document one ([b0b26cb](https://github.com/smur89/gairm-import/commit/b0b26cbfa224ad2997255729a55220026a7825c6))
* report errors with panic, and test that each panic fires ([83ed33f](https://github.com/smur89/gairm-import/commit/83ed33f983b9f3d2fb011702c66576677e343569))
* route lens object edits through object(), so they keep its invariants ([ca787d2](https://github.com/smur89/gairm-import/commit/ca787d2d9d5de1fe3c99e1c096b3b51b1c6b4fed)), closes [#165](https://github.com/smur89/gairm-import/issues/165)
* stop calling the input root a dict in the null-input panic ([b0b26cb](https://github.com/smur89/gairm-import/commit/b0b26cbfa224ad2997255729a55220026a7825c6))

## [0.10.1](https://github.com/smur89/gairm-import/compare/v0.10.0...v0.10.1) (2026-11-02)


### Bug Fixes

* point the README render example at altacv 1.7.0 ([#130](https://github.com/smur89/gairm-import/issues/130)) ([5b92dad](https://github.com/smur89/gairm-import/commit/5b92dad5be42de516a9a6ec12254f2b0484afe49))

## [0.10.0](https://github.com/smur89/gairm-import/compare/v0.9.0...v0.10.0) (2026-11-02)


### Features

* update vendored JSON Resume schema to 1.7.0 ([#127](https://github.com/smur89/gairm-import/issues/127)) ([18e91d7](https://github.com/smur89/gairm-import/commit/18e91d74cf440190d80dd92e3f4c774fb9633aaa))


### Bug Fixes

* accept the spec datetime for strict meta.lastModified ([#128](https://github.com/smur89/gairm-import/issues/128)) ([7af57a5](https://github.com/smur89/gairm-import/commit/7af57a56910b800083f77fe5859e2171d70dadee))

## [0.9.0](https://github.com/smur89/gairm-import/compare/v0.8.1...v0.9.0) (2026-07-12)


### Features

* enforce integral values for JSON Schema type "integer" ([#103](https://github.com/smur89/gairm-import/issues/103)) ([ce1610a](https://github.com/smur89/gairm-import/commit/ce1610aaa11e44b1f350f2e8a149b216940e25f6))
* JSON Schema composition keywords — allOf, anyOf, oneOf, not ([#117](https://github.com/smur89/gairm-import/issues/117)) ([2841e16](https://github.com/smur89/gairm-import/commit/2841e1625ac89e14c365bd825da737280279d1ba))

## [0.8.1](https://github.com/smur89/gairm-import/compare/v0.8.0...v0.8.1) (2026-06-17)


### Bug Fixes

* align rendering forward-link with the section it points to ([#94](https://github.com/smur89/gairm-import/issues/94)) ([d53f366](https://github.com/smur89/gairm-import/commit/d53f3665b6020fd5ccffc50de2739478461e98d6))

## [0.8.0](https://github.com/smur89/gairm-import/compare/v0.7.0...v0.8.0) (2026-06-17)


### Features

* JSON Schema constraint keywords ([#85](https://github.com/smur89/gairm-import/issues/85)) ([f2b301a](https://github.com/smur89/gairm-import/commit/f2b301a9e14d473203af3b9f61bcc2a1e5c5eccf))
* type coverage for boolean, null, and [X, "null"] unions ([#83](https://github.com/smur89/gairm-import/issues/83)) ([3081e24](https://github.com/smur89/gairm-import/commit/3081e24123268d2714f4f6b7ec9b9b8ea3633941))

## [0.7.0](https://github.com/smur89/gairm-import/compare/v0.6.0...v0.7.0) (2026-06-16)


### Features

* schema introspection helpers (describe-schema, paths-of-kind, kind-at) ([#54](https://github.com/smur89/gairm-import/issues/54)) ([d72b282](https://github.com/smur89/gairm-import/commit/d72b282268d882ad90b3a10dac9cc7e703a5cfd3))

## [0.6.0](https://github.com/smur89/gairm-import/compare/v0.5.1...v0.6.0) (2026-06-16)


### Features

* datetime-string kind for format: date-time fields ([#55](https://github.com/smur89/gairm-import/issues/55)) ([bfa6ce5](https://github.com/smur89/gairm-import/commit/bfa6ce5ce90cc3bf984a376dad84a95260b3f4dc))
* pattern-string kind for JSON Schema pattern keyword ([#53](https://github.com/smur89/gairm-import/issues/53)) ([19e8809](https://github.com/smur89/gairm-import/commit/19e88090d77c30ee8fd41be7b7b8a1acee50846c))
* suggest closest matching key in unknown-key error messages ([#19](https://github.com/smur89/gairm-import/issues/19)) ([9769de5](https://github.com/smur89/gairm-import/commit/9769de5f83d177ce03e27319b59b6df14d1b38a9))

## [0.5.1](https://github.com/smur89/gairm-import/compare/v0.5.0...v0.5.1) (2026-06-16)


### Bug Fixes

* hide release-please version markers from rendered README ([#57](https://github.com/smur89/gairm-import/issues/57)) ([0f33b09](https://github.com/smur89/gairm-import/commit/0f33b09b5acf2f806a429d694094589ab6e5d41b))

## [0.5.0](https://github.com/smur89/typst-json-resume/compare/v0.4.0...v0.5.0) (2026-06-15)


### Features

* set-required lens companion for editing object required-keys ([#48](https://github.com/smur89/typst-json-resume/issues/48)) ([7dc58b1](https://github.com/smur89/typst-json-resume/commit/7dc58b14a578f822bd7c4d3be37022ac92b0afa9))

## [0.4.0](https://github.com/smur89/typst-json-resume/compare/v0.3.0...v0.4.0) (2026-06-15)


### Features

* translator + validator support for JSON Schema enum and const ([#46](https://github.com/smur89/typst-json-resume/issues/46)) ([8e6e2d8](https://github.com/smur89/typst-json-resume/commit/8e6e2d84e22fea652374edcc88ee61f3539d2068))

## [0.3.0](https://github.com/smur89/typst-json-resume/compare/v0.2.0...v0.3.0) (2026-06-15)


### Features

* split resume-schema into faithful default + opt-in strict variant ([#35](https://github.com/smur89/typst-json-resume/issues/35)) ([908d628](https://github.com/smur89/typst-json-resume/commit/908d62888201a7203a8226f6c2a5ace081a4dca2))

## [0.2.0](https://github.com/smur89/typst-json-resume/compare/v0.1.1...v0.2.0) (2026-06-15)


### Features

* derive resume-schema from vendored JSON Schema document ([#33](https://github.com/smur89/typst-json-resume/issues/33)) ([7f01328](https://github.com/smur89/typst-json-resume/commit/7f013281c2ee5aed5eb9a3ddb9d3694039a28720))
* expose validate / coerce engines and schema combinators publicly ([#17](https://github.com/smur89/typst-json-resume/issues/17)) ([a37b8e0](https://github.com/smur89/typst-json-resume/commit/a37b8e0279d64f139eae32f3b3d8fb636673c5ce))
* lens-style schema editing for JSON-Resume+ extensions ([#30](https://github.com/smur89/typst-json-resume/issues/30)) ([33aee49](https://github.com/smur89/typst-json-resume/commit/33aee49a910fe207a40c79092ea997714478e605))
* schema-from-json-schema — translate a JSON Schema document into a Typst schema ([#24](https://github.com/smur89/typst-json-resume/issues/24)) ([7f16ce9](https://github.com/smur89/typst-json-resume/commit/7f16ce9695a03acb9b803fd39bc11eaabb046df5))
* treat JSON null as if the key were absent ([#20](https://github.com/smur89/typst-json-resume/issues/20)) ([e9e8cbe](https://github.com/smur89/typst-json-resume/commit/e9e8cbe66a6e1931b738d6089ec1f66a1d73dcf3))

## [0.1.1](https://github.com/smur89/typst-json-resume/compare/v0.1.0...v0.1.1) (2026-06-15)


### Bug Fixes

* **release:** clear typst/packages submission errors and warnings ([#13](https://github.com/smur89/typst-json-resume/issues/13)) ([fc9c512](https://github.com/smur89/typst-json-resume/commit/fc9c5124911d088a86cf588771aae451b91a364d))

## [0.1.0](https://github.com/smur89/typst-json-resume/compare/v0.0.1...v0.1.0) (2026-06-14)


### Features

* implement v0.1 of the JSON Resume loader ([#7](https://github.com/smur89/typst-json-resume/issues/7)) ([7b5be34](https://github.com/smur89/typst-json-resume/commit/7b5be34746b0e9b84e5c9273a833df96d7b7c0f7))
* scaffold the json-resume package ([adf5b63](https://github.com/smur89/typst-json-resume/commit/adf5b6329231c9e51079ebd737c928e2e283a87e))

## Changelog
