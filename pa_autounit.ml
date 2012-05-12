(*
 * Copyright (c) 2012, Alexey Vyskubov <alexey@ocaml.nl>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *
 *     Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *)
open Camlp4

module Id : Sig.Id = struct
  let name = "pa_autounit"
  let version = "0.1"
end

module Make (Syntax : Sig.Camlp4Syntax) = struct
  open Sig
  include Syntax

  let _loc = Loc.mk "<string>"

  (* TEST implementation *)

  (* Number of tests already defined *)
  let test_counter = ref 0

  (*
   * Create a name for the test function.
   * When processing file.ml, returns the string "file__test__xxx" where xxx is
   * a number.
   *)
  let new_test_name loc =
    incr test_counter ;
    let fname = Loc.file_name loc in
    let dot_index = String.index fname '.' in
    let basename = String.sub fname 0 dot_index in
    basename ^ "__test__" ^ string_of_int !test_counter

  (*
   * The ref to the list of tests.
   * Each entry is an expr of the form
   * "test description" :>> test_function
   *)
  let defined_tests = ref []

  (*
   * Add one more test to the defined_tests ref
   *)
  let remember_test test  =
    defined_tests := test :: !defined_tests

  (*
   * Process TEST entry.
   *
   * Takes 'TEST "test description" body' expr as an input (where 'body' is
   * normally begin/end block).
   *
   * Creates the name for the test function. Adds test to defined_tests ref.
   *
   * Outputs binding 'test_function = fun () -> body'.
   *)
  let create_test e =
    let loc = Ast.loc_of_expr e in
    match e with
    | <:expr< $str:name$ $body$ >> ->
        let tname = new_test_name loc in
        let tpatt = <:patt< $lid:tname$ >> in
        let texpr = <:expr< $lid:tname$ >> in
        let _ = remember_test <:expr< $str:name$ >:: $texpr$ >> in
        <:binding< $tpatt$ = fun () -> $body$ >>
    | _ -> Loc.raise loc (Failure "expected: TEST description body")

  (* TESTSUITE implementation *)

  (*
   * Constructs suite with given name from the list in defined_tests ref;
   * the list is expectd to contain exprs looking like
   * "test description" >:: test_function
   *
   * NB: the tests in defined_tests are expected to be in reverse order.
   *)
  let produce_suite desc =
    (* Construct AST containing the list *)
    let tests = List.fold_right
                  (fun hd tl -> <:expr< [ $hd$ :: $tl$ ] >>)
                  (List.rev !defined_tests)
                  <:expr< [] >> in
    (* Return the final testsuite construction expression *)
    <:expr< $str:desc$ >::: $tests$ >>

  (*
   * Constructs the full testsuite definition statement.
   *
   * 'testsuite' is an expr, consisting of lowercase identficator for testsuite
   * and string containing the description of the testsuite.
   *
   * 'tests' is a list of bindings, created from test_exprs by create_test
   * function above.
   *)
  let create_test_suite testsuite tests =
    match testsuite with
    | <:expr< $lid:id$ $str:desc$ >> ->
        let suite = <:patt< $lid:id$ >> in
        (* Build the final part of test suite definitions *)
        let final_part = produce_suite desc in
        (* Gather all test bindings into full test suite definition *)
        let test_suite = List.fold_right
                           (fun binding tail ->
                             <:expr< let $binding$ in $tail$ >>)
                           tests
                           final_part in
        (* Output the full test suite definition *)
        <:str_item< value $suite$ = $test_suite$ >>
    | _ -> (* Syntax error *)
        let loc = Ast.loc_of_expr testsuite in
        Loc.raise loc (Failure "expected: TESTSUITE id description")

  (* Grammar extension *)
  EXTEND Gram
    GLOBAL: str_item expr ;
    test_expr: [
      [ "TEST" ; desc = expr -> create_test desc ]
    ] ;
    str_item: [
      [ "TESTSUITE" ; testsuite = expr ; tests = LIST1 test_expr ->
        <:str_item< $create_test_suite testsuite tests$ >> ]
    ] ;
  END
end

module M = Register.OCamlSyntaxExtension(Id)(Make)
