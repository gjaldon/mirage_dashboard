
let (--) i j =
  let rec aux n acc =
    if n < i then acc else aux (n-1) (n :: acc)
  in
  aux j []

let opt_with_default opt default =
  match opt with
  | None -> default
  | Some a -> a

