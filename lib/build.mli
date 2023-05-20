type t

val create : Rule.t list -> t
val add_rule : Rule.t -> t -> t
val need_rebuild : string -> t -> bool
val build : string -> t -> unit
val ninja : ?build_dir:string -> ?output_dir:string -> t -> unit
val compdb : ?output_dir:string -> t -> unit
