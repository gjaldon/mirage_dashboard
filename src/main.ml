open Opium.Std

let print_param = get "/hello/:name" (fun req ->
    let name = param req "name" in
    `String ("Hello " ^ name) |> respond')

let _ =
  App.empty
  |> print_param
  |> App.run_command
