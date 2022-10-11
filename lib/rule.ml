type target = Phony of string | File of string

type t = {
  targets : string list;
  is_phony : bool;
  deps : string list;
  cmds : string list;
}

let string_of_target t = match t with Phony s -> s | File s -> s
let is_phony t = match t with Phony _ -> true | _ -> false

let create ?(deps = []) ?(cmds = []) target =
  let f name is_phony = { targets = [ name ]; is_phony; deps; cmds } in
  match target with Phony name -> f name true | File name -> f name false

let create_m ?(deps = []) ?(cmds = []) targets =
  match targets with
  | [] -> raise (Invalid_argument "targets can not be empty")
  | [ t0 ] -> create ~deps ~cmds t0
  | _ ->
      let () = List.iter (fun t -> assert (not (is_phony t))) targets in
      {
        targets = List.map string_of_target targets;
        is_phony = false;
        deps;
        cmds;
      }

let add_deps r deps =
  {
    targets = r.targets;
    is_phony = r.is_phony;
    deps = List.append deps r.deps;
    cmds = r.cmds;
  }

let targets t = t.targets
let target t = List.hd t.targets
let is_target_phony t = t.is_phony
let deps t = t.deps
let cmds t = t.cmds
