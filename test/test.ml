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
  let file1 = Filename.concat dir (rand_str 4) in
  let expect_line1 = "hello" in
  let expect_line2 = "world" in
  let () = write_str file1 (expect_line1 ^ "\n") in
  let file2 = Filename.concat dir (rand_str 4) in
  let () = write_str file2 (expect_line2 ^ "\n") in

  let res = Filename.concat dir (rand_str 4) in
  let cmd1 = [ "cat"; file1; ">"; res ] in
  let cmd2 = [ "cat"; file2; ">>"; res ] in
  let rule =
    R.create (R.File res) ~deps:[ file1; file2 ]
      ~cmds:[ String.concat " " cmd1; String.concat " " cmd2 ]
  in
  let mbuild = B.create [ rule ] in
  let () = B.build res mbuild in
  let ic = open_in res in
  let line1 = input_line ic in
  let line2 = input_line ic in
  let open Alcotest in
  let () = check string "same line1" expect_line1 line1 in
  let () = check string "same line2" expect_line2 line2 in
  let () = check bool "rebuild" false (B.need_rebuild res mbuild) in

  let expect_line1 = "xxx" in
  let () = write_str file1 (expect_line1 ^ "\n") in
  let () = check bool "" true (B.need_rebuild res mbuild) in
  let () = B.build res mbuild in
  let ic = open_in res in
  let line1 = input_line ic in
  let () = check string "" expect_line1 line1 in

  ()

let () =
  let open Alcotest in
  run "tests" [ ("basic", [ test_case "basic1" `Quick test1 ]) ]
