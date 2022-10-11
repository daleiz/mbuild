type t
type target = Phony of string | File of string

val create : ?deps:string list -> ?cmds:string list -> target -> t
val create_m : ?deps:string list -> ?cmds:string list -> target list -> t
val add_deps : t -> string list -> t
val targets : t -> string list
val target : t -> string
val is_target_phony : t -> bool
val deps : t -> string list
val cmds : t -> string list
