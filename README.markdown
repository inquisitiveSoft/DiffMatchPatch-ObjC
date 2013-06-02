Diff, Match and Patch Library, Objective C port
===============================================

A rather enthusiastic refactoring of Jan Weiß's Objective-C port of Neil Fraser's [http://code.google.com/p/google-diff-match-patch/](Diff Match and Patch).

In the process of making it ARC friendly and tinkering to my internal Objective-C style I ended up reformatting to the extent that it's become a C interface which uses Objective-C objects. While I think it's rather streamlined as is, all the clever bits were done by others.

`Source/DiffMatchPatch.h` is the place to get started.