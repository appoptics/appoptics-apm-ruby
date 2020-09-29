run c++ tests:

`cmake CMakeLists.txt`

ignore warning

`make`

`./runTests`

These tests complement the tests run in Ruby, e.g.:

Logging is tested in Ruby as integration tests that verify the different 
KVs and values in the resulting traces.
Those tests use the same approach as is used for traces without profiling.