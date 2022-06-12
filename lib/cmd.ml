let make args = String.concat " " args
let quote = Filename.quote
let concat cmds = String.concat " && " cmds

let run cmd =
  match Sys.command cmd with 0 -> () | _ -> failwith "run cmd error"
