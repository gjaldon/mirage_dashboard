open Opium.Std
open Tyxml.Html

module Server = Cohttp_lwt_unix.Server

let home_page = get "/" (fun req ->
    let headers = Cohttp.Header.init_with "content-type" "html" in
    Server.respond_file ~headers ~fname:"./index.html" () >>| fun resp ->
    Response.of_response_body resp
  )

let _ =
  App.empty
  |> middleware (Middleware.static ~local_path:"./_build/js/" ~uri_prefix:"/assets")
  |> home_page
  |> App.run_command
