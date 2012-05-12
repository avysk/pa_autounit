pa_autounit
===========

Introduction
------------

Camlp4 syntax extension to simplify usage of OUnit.

Normally when using OUnit you have to define the tests:

        let test_function () = ...

and then put them together into test suite:

        let suite_id = "suite description" :>>>
                       [ "test description" :>> test_function ;
                         ... ]

It means that you have to do the following:

* Invent the names for test functions. They are actually meaningless,
  descriptions are what you are interested in and what OUnit reports back to
  you.

* Combine all the tests defined into test suite. When adding new test
  you should not forget to add it to test suite definition, otherwise it will
not be run.

To decrease the amount of manual work, pa_autounit supports the following syntax:

        TESTSUITE suite_id "suite description"

        TEST "test description"
          test_body

        TEST "test description"
          test_body

        ...

This code defines OUnit test suite `suite_id` containing all the tests defined in
TEST blocks.

Example
-------

Before preprocessing:

        open OUnit

        TESTSUITE my_test_suite "my test suite"

        TEST "Passing test"
        begin
          assert_equal 1 1 ;
          assert_equal 2 2 ;
          assert_equal 3 3
        end

        TEST "Failing test"
        begin
          let x = 1 in
          assert_equal x 2
        end

        TEST "Test with todo"
        begin
          todo "This test is not implemented on purpose."
        end

        ;;

        run_test_tt ~verbose:true my_test_suite

After preprocessing:

        open OUnit

        let my_test_suite =
          let example__test__1 () =
            (assert_equal 1 1; assert_equal 2 2; assert_equal 3 3) in
          let example__test__2 () = let x = 1 in assert_equal x 2 in
          let example__test__3 () = todo "This test is not implemented on purpose."
          in
            "my test suite" >:::
              [ "Passing test" >:: example__test__1;
                "Failing test" >:: example__test__2;
                "Test with todo" >:: example__test__3 ]

        let _ = run_test_tt ~verbose: true my_test_suite

Compiling and running
---------------------

* To compile the syntax extension, run `make`.
* To try the example, run `make example && ./example.native`.
* To see the example after preprocessing, run `make ppo`.

How to use in your own project
------------------------------

I describe here setup using `ocamlbuild`. If you do not use `ocamlbuild` you
are on your own. Hint: you may want to add `-classic-display` flag to
`ocamlbuild` calls in Makefile and see what it is actually doing.

1. Copy `pa_autounit.ml` file to your project directory.
2. Write tests in some file, for example in `tests.ml`.
3. Modify your `_tags` file:

        ...
        "pa_autounit.ml": use_camlp4, pp(camlp4orf)
        <tests.*>: package(ounit)
        "tests.ml": pp(camlp4o -I ./_build pa_autounit.cmo)
        ...

4. Put something like this in your `Makefile`:

        ...
        FLAGS=-use-ocamlfind
        extension:
                ocamlbuild $(FLAGS) pa_autounit.cmo
        tests: extension
                ocamlbuild $(FLAGS) example.native
        ...

License
-------

The BSD 2-Clause License, see file COPYRIGHT for more information.

Notes
-----

* In `TEST` block each `test_body` must be a single OCaml expression so you may want to use `begin/end` blocks:

        TEST "some test"
        begin
          do_something ;
          and_something_else ;
          assert_something
        end

* You *cannot* put anything between TESTSUITE definition and TEST block.
* You *cannot* put anything between two TEST blocks.
* Do not forget `open OUnit` in the beggining.
* You can put whatever you want after the last TEST block.
