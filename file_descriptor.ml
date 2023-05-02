open Solo5_os.Solo5

type solo5_net_info = { solo5_mac : string; solo5_mtu : int }

type t = int64

type error = [ `Invalid_argument | `Unspecified_error ]

let pp_error ppf = function
  | `Invalid_argument -> Fmt.string ppf "Invalid argument"
  | `Unspecified_error -> Fmt.string ppf "Unspecified error"

external solo5_net_acquire : string -> solo5_result * int64 * solo5_net_info
  = "mirage_solo5_net_acquire"

external solo5_net_read :
  int64 -> Cstruct.buffer -> int -> int -> solo5_result * int
  = "mirage_solo5_net_read_3"

external solo5_net_write : int64 -> Cstruct.buffer -> int -> int -> solo5_result
  = "mirage_solo5_net_write_3"

let connect devname =
  match solo5_net_acquire devname with
  | SOLO5_R_OK, handle, _net_info ->
    Lwt.return handle
  | SOLO5_R_AGAIN, _, _ -> assert false
  | SOLO5_R_EINVAL, _, _ ->
      Fmt.kstr failwith "File_descriptor: connect(%s): Invalid argument" devname
  | SOLO5_R_EUNSPEC, _, _ ->
      Fmt.kstr failwith "File_descriptor: connect(%s): Unspecified error" devname

let disconnect _t =
  (* FIXME *)
  Lwt.return_unit

let rec read t buf =
  match solo5_net_read t buf.Cstruct.buffer buf.Cstruct.off buf.Cstruct.len with
  | SOLO5_R_OK, len ->
    Lwt.return (Ok (Cstruct.sub buf 0 len))
  | SOLO5_R_AGAIN, _ ->
    let open Lwt.Infix in
    Solo5_os.Main.wait_for_work_on_handle t >>= fun () ->
    read t buf
  | SOLO5_R_EINVAL, _ -> Lwt.return (Error `Invalid_argument)
  | SOLO5_R_EUNSPEC, _ -> Lwt.return (Error `Unspecified_error)

let write t buf =
  match solo5_net_write t buf.Cstruct.buffer buf.Cstruct.off buf.Cstruct.len with
  | SOLO5_R_OK -> Ok ()
  | SOLO5_R_AGAIN -> assert false (* Not returned by solo5_net_write() *)
  | SOLO5_R_EINVAL -> Error `Invalid_argument
  | SOLO5_R_EUNSPEC -> Error `Unspecified_error

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
