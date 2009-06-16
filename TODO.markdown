TODO
====

* <del>Convert tests to Contest</del>
* <del>Add preprocessing of derivatives as a default, on-the-fly as an option intended only for prototyping</del>
* <del>Test that processors always run in the order specified (probably requires an ordered hash)</del>
* <del>Fix up mime-type recognition for disk/S3 (uses mimetype-fu if available)</del>
* <del>Write tests for S3</del>
* Write tests to verify atomicity of saving/processing (cleanup on failure, etc...)
* Add more tests for S3
* Identify & raise on all failure points (i.e. make sure system calls returned success, etc...)
* Add rake task for re-processing derivatives
* Fix missing column raises when installing plugin and migrating changes to underlying table
* Don't require right_aws unless you use S3
* Break out storing from processing of derivatives, process all then store
