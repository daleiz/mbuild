module B = Mbuild.Build
module R = Mbuild.Rule
module C = Mbuild.Cmd
module Cf = Mbuild.Cfun

let rand_chr () = Char.chr (97 + Random.int 26)

let rand_str len =
  let bytes = Bytes.init len (fun _ -> rand_chr ()) in
  Bytes.to_string bytes

let write_str file str =
  let oc = open_out file in
  let () = output_string oc str in
  close_out oc

let mk_temp_dir () =
  let dir = Filename.concat (Filename.get_temp_dir_name ()) (rand_str 7) in
  let () = Unix.mkdir dir 0o775 in
  dir

let test1 () =
  let dir = mk_temp_dir () in
  let file1 = Filename.concat dir (rand_str 7) in
  let expect_line1 = "hello" in
  let expect_line2 = "world" in
  let () = write_str file1 (expect_line1 ^ "\n") in
  let file2 = Filename.concat dir (rand_str 7) in
  let () = write_str file2 (expect_line2 ^ "\n") in

  let res1 = Filename.concat dir (rand_str 7) in
  let cmd1 = [ "cat"; file1; ">"; res1 ] in
  let cmd2 = [ "cat"; file2; ">>"; res1 ] in
  let rule =
    R.create (R.File res1) ~deps:[ file1; file2 ]
      ~cmds:[ C.make cmd1; C.make cmd2 ]
  in
  let mbuild = B.create [ rule ] in
  let () = B.build res1 mbuild in
  let ic = open_in res1 in
  let line1 = input_line ic in
  let line2 = input_line ic in
  let () = close_in ic in
  let open Alcotest in
  let () = check string "same line1" expect_line1 line1 in
  let () = check string "same line2" expect_line2 line2 in
  let () = check bool "don't need rebuild" false (B.need_rebuild res1 mbuild) in

  let () = Unix.sleep 1 in
  let expect_line1 = "xxx" in
  let () = write_str file1 (expect_line1 ^ "\n") in
  let () = check bool "need rebuild" true (B.need_rebuild res1 mbuild) in
  let () = B.build res1 mbuild in
  let ic = open_in res1 in
  let line1 = input_line ic in
  let () = close_in ic in
  let () = check string "line1 same" expect_line1 line1 in

  let clean_res1 = ".clean_res1" in
  let rule = R.create (R.Phony clean_res1) ~cmds:[ C.make [ "rm"; res1 ] ] in
  let mbuild = B.add_rule rule mbuild in
  let () = B.build clean_res1 mbuild in
  let () = check bool "phony done" false (Sys.file_exists res1) in
  let () = check bool "need rebuild" true (B.need_rebuild res1 mbuild) in
  let () = B.build res1 mbuild in
  let ic = open_in res1 in
  let line1 = input_line ic in
  let () = close_in ic in
  let () = check string "line1 same" expect_line1 line1 in

  let res2 = Filename.concat dir (rand_str 7) in
  let rule =
    R.create (R.File res2) ~deps:[ res1 ] ~cmds:[ C.make [ "cp"; res1; res2 ] ]
  in
  let mbuild = B.add_rule rule mbuild in
  let () = B.build res2 mbuild in
  let ic = open_in res2 in
  let line1 = input_line ic in
  let () = close_in ic in
  let () = check string "line1 same" expect_line1 line1 in

  let () = Unix.sleep 1 in
  let expect_line1 = rand_str 9 in
  let () = write_str file1 (expect_line1 ^ "\n") in
  let () = check bool "res2 need rebuild" true (B.need_rebuild res2 mbuild) in
  let () = B.build res2 mbuild in
  let ic = open_in res2 in
  let line1 = input_line ic in
  let () = close_in ic in
  let () = check string "line1 same" expect_line1 line1 in

  let () = B.build clean_res1 mbuild in
  let () = check bool "res2 need rebuild" true (B.need_rebuild res2 mbuild) in
  let () = B.build res2 mbuild in
  let ic = open_in res2 in
  let line1 = input_line ic in
  let () = close_in ic in
  let () = check string "line1 same" expect_line1 line1 in

  ()

let gen_simple_c_prog src_file =
  let src =
    {|
  #include "stdio.h"
  int main() {
    printf("hello world!\n");
  }
  |}
  in
  let () = write_str src_file src in
  ()

let test_ninja () =
  let dir = mk_temp_dir () in
  let () = print_endline dir in
  let hello_c_file = Filename.concat dir "hello.c" in
  let () = gen_simple_c_prog hello_c_file in

  let r_build_dir = "_ninja_build" in
  let r_hello_exe_file = Filename.concat r_build_dir "hello" in
  let r_hello_c_file = "hello.c" in
  let rule =
    R.create (R.File r_hello_exe_file) ~deps:[ r_hello_c_file ]
      ~cmds:[ C.make [ "gcc"; r_hello_c_file; "-o"; r_hello_exe_file ] ]
  in
  let mbuild = B.create [ rule ] in
  let () = B.ninja mbuild ~output_dir:dir in
  (* let () = Unix.sleep 10000 in *)
  let () = C.run (C.concat [ C.make [ "cd"; dir ]; C.make [ "ninja" ] ]) in

  let open Alcotest in
  let () =
    check bool "build success" true
      (Sys.file_exists (Filename.concat dir r_hello_exe_file))
  in

  ()

let test_cfun1 () =
  let dir = mk_temp_dir () in
  let () = print_endline dir in
  let src = "hello.c" in
  let src_file = Filename.concat dir src in
  let () = gen_simple_c_prog src_file in

  let exe = "hello" in
  let r_bin_dir = "_ninja_build/bin" in
  let r_exe_file = Filename.concat r_bin_dir exe in
  let rules = Cf.exe [ src ] exe in
  let mbuild = B.create rules in
  let () = B.ninja mbuild ~output_dir:dir in
  let () = C.run (C.concat [ C.make [ "cd"; dir ]; C.make [ "ninja" ] ]) in

  (* let () = Unix.sleep 10000 in  *)
  let open Alcotest in
  let () =
    check bool "build success" true
      (Sys.file_exists (Filename.concat dir r_exe_file))
  in

  ()

let () =
  let open Alcotest in
  run "tests"
    [
      ("basic", [ test_case "basic1" `Quick test1 ]);
      ("ninja", [ test_case "ninja1" `Quick test_ninja ]);
      ("cfun", [ test_case "cfun1" `Quick test_cfun1 ]);
    ]
