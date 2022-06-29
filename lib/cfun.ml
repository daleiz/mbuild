let obj ?(cc = "gcc") ?(cflags = []) ?(build_dir = "_ninja_build") src =
  let bn = Filename.remove_extension src in
  let tn = bn ^ ".o" in
  let tn = Filename.concat build_dir tn in
  let cflags_str = String.concat " " cflags in
  let cmd = Cmd.make [ cc; "-c"; cflags_str; "-o"; tn; src ] in
  Rule.create (Rule.File tn) ~deps:[ src ] ~cmds:[ cmd ]

let objs ?(cc = "gcc") ?(cflags = []) ?(build_dir = "_ninja_build") srcs =
  List.map (fun s -> obj ~cc ~cflags ~build_dir s) srcs

let static_lib_from_objs ?(build_dir = "_ninja_build") objs name =
  let lib_name = "lib" ^ name ^ ".a" in
  let tn = Filename.concat build_dir lib_name in
  let cmd = Cmd.make (List.append [ "ar"; "rcs"; tn ] objs) in
  [
    Rule.create (Rule.File tn) ~deps:objs ~cmds:[ cmd ];
    Rule.create (Rule.Phony name) ~deps:[ tn ];
  ]

let static_lib ?(cc = "gcc") ?(cflags = []) ?(build_dir = "_ninja_build") srcs
    name =
  let obj_rules = objs ~cc ~cflags ~build_dir srcs in
  let objs = List.map Rule.target obj_rules in
  let lib_rules = static_lib_from_objs ~build_dir objs name in
  List.append obj_rules lib_rules

let link ?(cc = "cc") ?(ldflags = []) ?(libs = []) objs target =
  let cmd = List.append [ cc; "-o"; target ] ldflags in
  let cmd = List.append cmd objs in
  let cmd = List.append cmd (List.map (fun l -> "-l" ^ l) libs) in
  let cmd = Cmd.make cmd in
  Rule.create (Rule.File target) ~deps:objs ~cmds:[ cmd ]

let shared_common ?(cc = "gcc") ?(cflags = []) ?(build_dir = "_ninja_build")
    ?(ldflags = []) ?(libs = []) srcs target =
  let obj_rules = objs ~cc ~cflags ~build_dir srcs in
  let objs = List.map Rule.target obj_rules in
  let link_rule = link ~cc ~ldflags ~libs objs target in
  List.append obj_rules [ link_rule ]

let shared_lib ?(cc = "gcc") ?(cflags = []) ?(build_dir = "_ninja_build")
    ?(ldflags = []) ?(libs = []) srcs name =
  let lib_name = "lib" ^ name ^ ".so" in
  let tn = Filename.concat build_dir lib_name in
  let ldflags = List.append ldflags [ "-shared" ] in
  List.concat
    [
      [ Rule.create (Rule.Phony name) ~deps:[ tn ] ];
      shared_common ~cc ~cflags ~build_dir ~ldflags ~libs srcs tn;
    ]

let exe ?(cc = "gcc") ?(cflags = []) ?(build_dir = "_ninja_build")
    ?(ldflags = [ "" ]) ?(libs = []) srcs name =
  let tn = Filename.concat build_dir name in
  List.concat
    [
      [ Rule.create (Rule.Phony name) ~deps:[ tn ] ];
      shared_common ~cc ~cflags ~build_dir ~ldflags ~libs srcs tn;
    ]
