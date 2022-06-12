let obj ?(cc = "gcc") ?(cflags = []) ?(build_dir = "_ninja_build") src =
  let bn = Filename.remove_extension src in
  let tn = Filename.concat bn (Filename.extension "o") in
  let tn = Filename.concat build_dir tn in
  let cflags_str = String.concat " " cflags in
  let cmd = Cmd.make [ cc; "-c"; cflags_str; "-o"; tn ] in
  Rule.create (Rule.File tn) ~deps:[ src ] ~cmds:[ cmd ]

let objs ?(cc = "gcc") ?(cflags = []) ?(build_dir = "_ninja_build") srcs =
  List.map (fun s -> obj ~cc ~cflags ~build_dir s) srcs

let static_lib_from_objs ?(build_dir = "_ninja_build") objs name =
  let lib_name = Filename.concat ("lib" ^ name) (Filename.extension "a") in
  let tn = Filename.concat (Filename.concat build_dir "lib") lib_name in
  let cmd = Cmd.make (List.append [ "ar"; "rcs"; tn ] objs) in
  Rule.create (Rule.File tn) ~deps:objs ~cmds:[ cmd ]

let static_lib ?(cc = "gcc") ?(cflags = []) ?(build_dir = "_ninja_build") srcs
    name =
  let obj_rules = objs ~cc ~cflags ~build_dir srcs in
  let objs = List.map Rule.target obj_rules in
  let lib_rule = static_lib_from_objs ~build_dir objs name in
  List.append obj_rules [ lib_rule ]

let link ?(ld = "ld") ?(ldflags = []) ?(libs = []) objs target =
  let cmd = List.append [ ld; "-o"; target ] ldflags in
  let cmd = List.append cmd objs in
  let cmd = List.append cmd (List.map (fun l -> "-l" ^ l) libs) in
  let cmd = Cmd.make cmd in
  Rule.create (Rule.File target) ~deps:objs ~cmds:[ cmd ]

let shared_common ?(cc = "gcc") ?(cflags = []) ?(build_dir = "_ninja_build")
    ?(ld = "ld") ?(ldflags = []) ?(libs = []) srcs target =
  let obj_rules = objs ~cc ~cflags ~build_dir srcs in
  let objs = List.map Rule.target obj_rules in
  let link_rule = link ~ld ~ldflags ~libs objs target in
  List.append obj_rules [ link_rule ]

let shared_lib ?(cc = "gcc") ?(cflags = []) ?(build_dir = "_ninja_build")
    ?(ld = "ld") ?(ldflags = []) ?(libs = []) srcs name =
  let lib_name = Filename.concat ("lib" ^ name) (Filename.extension "so") in
  let tn = Filename.concat (Filename.concat build_dir "lib") lib_name in
  let ldflags = List.append ldflags [ "-shared" ] in
  shared_common ~cc ~cflags ~build_dir ~ld ~ldflags ~libs srcs tn

let exe ?(cc = "gcc") ?(cflags = []) ?(build_dir = "_ninja_build") ?(ld = "ld")
    ?(ldflags = []) ?(libs = []) srcs name =
  let tn = Filename.concat (Filename.concat build_dir "bin") name in
  shared_common ~cc ~cflags ~build_dir ~ld ~ldflags ~libs srcs tn
