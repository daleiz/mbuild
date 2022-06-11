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

let target t = t.target
let is_target_phony t = t.is_phony
let deps t = t.deps
let cmds t = t.cmds
