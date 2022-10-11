type t = (string * Rule.t) list

let add_rule rule t = List.append t [ (Rule.target rule, rule) ]
let create rules = List.fold_left (fun t r -> add_rule r t) [] rules

let run_cmd cmd =
  let () = print_endline ("[Build]: " ^ cmd) in
  Cmd.run cmd

let need_rebuild target t =
  let rec f mtime trgt =
    match List.assoc_opt trgt t with
    | None ->
        let f_mtime = (Unix.stat trgt).st_mtime in
        if f_mtime > mtime then true else false
    | Some rule -> (
        match Rule.deps rule with
        | [] -> true
        | deps -> (
            match Rule.is_target_phony rule with
            | true -> true
            | false ->
                if Sys.file_exists trgt then
                  let c_mtime = (Unix.stat trgt).st_mtime in
                  List.fold_left
                    (fun prev dep -> if prev then prev else f c_mtime dep)
                    false deps
                else true))
  in
  f Float.infinity target

let rec build target t =
  match need_rebuild target t with
  | false -> ()
  | true ->
      let rule = List.assoc target t in
      let deps = Rule.deps rule in
      let () = List.iter (fun trgt -> build trgt t) deps in
      let cmds = Rule.cmds rule in
      List.iter run_cmd cmds

type ninja_rule = {
  name : string;
  command : string;
  variables : (string * string) list;
}

type ninja_build = {
  outputs : string list;
  rule : string;
  inputs : string list;
  variables : (string * string) list;
}

let add_scoped_kvs_str s kvs =
  List.fold_left
    (fun acc (k, v) ->
      let ps = Printf.sprintf "\n  %s = %s" k v in
      acc ^ ps)
    s kvs

let ninja_rule_to_str nr =
  let s = Printf.sprintf "rule %s\n  command = %s" nr.name nr.command in
  add_scoped_kvs_str s nr.variables

let ninja_build_to_str nb =
  let outputs_str = String.concat " " nb.outputs in
  let s = Printf.sprintf "build %s: %s" outputs_str nb.rule in
  let s =
    List.fold_left
      (fun acc i ->
        let is = Printf.sprintf " %s" i in
        acc ^ is)
      s nb.inputs
  in
  add_scoped_kvs_str s nb.variables

let gen_ninja_rule_name r =
  let s =
    String.map
      (fun c ->
        if String.equal (String.make 1 c) Filename.dir_sep then '_' else c)
      (Rule.target r)
  in
  "rule__" ^ s

let rule_to_ninja r =
  if Rule.is_target_phony r then
    let nb : ninja_build =
      {
        outputs = Rule.targets r;
        rule = "phony";
        inputs = Rule.deps r;
        variables = [];
      }
    in
    (None, nb)
  else
    let nr : ninja_rule =
      {
        name = gen_ninja_rule_name r;
        command = Cmd.concat (Rule.cmds r);
        variables = [];
      }
    in
    let nb : ninja_build =
      {
        outputs = Rule.targets r;
        rule = nr.name;
        inputs = Rule.deps r;
        variables = [];
      }
    in
    (Some nr, nb)

let rule_to_ninja_str r =
  let onr, nb = rule_to_ninja r in
  match onr with
  | Some nr -> ninja_rule_to_str nr ^ "\n\n" ^ ninja_build_to_str nb
  | None -> ninja_build_to_str nb

let ninja ?(build_dir = "_ninja_build")
    ?(output_dir = Filename.current_dir_name) t =
  let output_file = Filename.concat output_dir "build.ninja" in
  let oc = open_out output_file in
  let () = output_string oc (Printf.sprintf "builddir = %s" build_dir) in
  let () =
    List.iter (fun (_, r) -> output_string oc ("\n\n" ^ rule_to_ninja_str r)) t
  in
  let () = output_string oc "\n" in
  close_out oc
