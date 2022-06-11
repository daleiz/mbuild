module B = Mbuild.Build
module R = Mbuild.Rule

let rand_chr () = Char.chr (97 + Random.int 26)

let rand_str len =
  let bytes = Bytes.init len (fun _ -> rand_chr ()) in
  Bytes.to_string bytes

let write_str file str =
  let oc = open_out file in
  let () = output_string oc str in
  close_out oc

let test1 () =
  let dir = Filename.get_temp_dir_name () in
  (* let () = Unix.mkdir dir 0o775 in *)
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
      ~cmds:[ String.concat " " cmd1; String.concat " " cmd2 ]
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
  let rule = R.create (R.Phony clean_res1) ~cmds:[ "rm " ^ res1 ] in
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
    R.create (R.File res2) ~deps:[ res1 ] ~cmds:[ "cp " ^ res1 ^ " " ^ res2 ]
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

let () =
  let open Alcotest in
  run "tests" [ ("basic", [ test_case "basic1" `Quick test1 ]) ]
