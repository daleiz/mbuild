type t

val create : unit -> t
val add_rule : Rule.t -> t -> t
val need_rebuild : string -> t -> bool
val build : string -> t -> unit
