type t
type target = Phony of string | File of string

val create : ?deps:string list -> ?cmds:string list -> target -> t
val target : t -> string
val is_target_phony : t -> bool
val deps : t -> string list
val cmds : t -> string list
