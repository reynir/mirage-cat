open Lwt.Syntax

module Main (Fd : File_descriptor.S) (C : Mirage_console.S) = struct

  let start stdin stdout =
    let buf = Cstruct.create 1500 in
    let rec loop () =
      let* r = Fd.read stdin buf in
      match r with
      | Ok b ->
        (* This never happens *)
        if Cstruct.length b = 0 then exit 0;
        let* r = C.write stdout b in
        Result.iter_error
          (fun e ->
             Logs.err (fun m -> m "Write error: %a" C.pp_write_error e))
          r;
        loop ()
      | Error e ->
        Logs.err (fun m -> m "Read error: %a" Fd.pp_error e);
        loop ()
    in
    loop ()

end
