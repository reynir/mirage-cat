open Lwt.Syntax

module Main (N : Mirage_net.S) = struct

  let start stdin =
    (* In a loop, we read at most [mtu] bytes at a time *)
    N.listen stdin ~header_size:0 @@ fun cs ->
    (* This is an attempt at detecting EOF, but it doesn't seem to work *)
    if Cstruct.length cs = 0 then exit 0;
    (* Print and flush to stdout *)
    print_string (Cstruct.to_string cs);
    flush_all ();
    Lwt.return_unit

end
