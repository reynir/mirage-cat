module type S = sig
  type t

  type error

  val pp_error : error Fmt.t

  val connect : string -> t Lwt.t

  val disconnect : t -> unit Lwt.t

  (** [read t buf] reads into [buf] and returns the sub buffer of [buf] that were
      written into. *)
  val read : t -> Cstruct.t -> (Cstruct.t, error) result Lwt.t

  (** [write t buf] writes the content of [buf] to t. *)
  val write : t -> Cstruct.t -> (unit, error) result
end

include S
