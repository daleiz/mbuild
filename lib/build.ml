type t = (string * Rule.t) list

let create rules =
  let f acc r = List.append acc [ (Rule.target r, r) ] in
  List.fold_left f [] rules

let run_cmd cmd =
  let () = print_endline ("[Build]: " ^ cmd) in
  match Sys.command cmd with 0 -> () | _ -> failwith "run cmd error"

let need_rebuild target t =
  let rec f mtime trgt =
    match List.assoc_opt trgt t with
    | None ->
        let f_mtime = (Unix.stat trgt).st_mtime in
        if f_mtime >= mtime then true else false
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
