type t

val create : Rule.t list -> t
val add_rule : Rule.t -> t -> t
val need_rebuild : string -> t -> bool
val build : string -> t -> unit
