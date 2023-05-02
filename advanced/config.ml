open Mirage

type file_descriptor = FILE_DESCRIPTOR
let file_descriptor = Type.v FILE_DESCRIPTOR

let file_descriptor_conf (intf : string Mirage_key.key) =
  let key = Mirage_key.v intf in
  let keys = [ key ] in
  let packages = [ package "solo5-file-descriptor" ] in
  let connect _ modname _ =
    Fmt.str "%s.connect %a" modname Mirage_key.serialize_call key
  in
  let configure i =
    Mirage_impl_network.all_networks :=
      Key.get (Info.context i) intf :: !Mirage_impl_network.all_networks;
    Action.ok ()
  in
  impl ~packages ~keys ~connect ~configure "File_descriptor" file_descriptor

let main =
  main "Unikernel.Main" (file_descriptor @-> console @-> job)

let file_descriptor ?group dev = file_descriptor_conf @@ Key.interface ?group dev

let stdin = file_descriptor "stdin"
let () = register "cat" [ main $ stdin $ default_console ]
