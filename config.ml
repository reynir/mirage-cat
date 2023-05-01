open Mirage

let main =
  main "Unikernel.Main" (network @-> job)

let stdin = netif "stdin"
let () = register "cat" [ main $ stdin ]
