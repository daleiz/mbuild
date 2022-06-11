type t

val create : Rule.t list -> t
val need_rebuild : string -> t -> bool
val build : string -> t -> unit
