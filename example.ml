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
