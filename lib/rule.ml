type target = Phony of string | File of string

type t = {
  target : string;
  is_phony : bool;
  deps : string list;
  cmds : string list;
}

let create ?(deps = []) ?(cmds = []) target =
  let f name is_phony = { target = name; is_phony; deps; cmds } in
  match target with Phony name -> f name true | File name -> f name false

let string_of_target t = match t with Phony s -> s | File s -> s

let create_m ?(deps = []) ?(cmds = []) targets =
  let t0 = List.hd targets in
  let tl = List.tl targets in
  let r0 = create ~deps ~cmds t0 in
  let f t = create ~deps:[ string_of_target t0 ] ~cmds:[ ":" ] t in
  let rs = List.map f tl in
  List.append [ r0 ] rs

let add_deps r deps =
  {
    target = r.target;
    is_phony = r.is_phony;
    deps = List.append deps r.deps;
    cmds = r.cmds;
  }

let target t = t.target
let is_target_phony t = t.is_phony
let deps t = t.deps
let cmds t = t.cmds
