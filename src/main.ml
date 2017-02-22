open Opium.Std
open Opium_misc
open Tyxml.Html

module Server = Cohttp_lwt_unix.Server

let home_page = get "/" (fun req ->
    let headers = Cohttp.Header.init_with "content-type" "html" in
    Server.respond_file ~headers ~fname:"./index.html" () >>| fun resp ->
    Response.of_response_body resp
  )

let projects = get "/projects" (fun req ->
    let headers = Cohttp.Header.init_with "content-type" "application/json" in
    let json = `String "{name: \"Gabriel\"}" in
    Server.respond ~headers ~status:`OK ~body:json () >>| fun resp ->
    Response.of_response_body resp
  )

let _ =
  let app = App.empty in
  app
  |> middleware (Middleware.static ~local_path:"./_build/js/" ~uri_prefix:"/assets")
  |> home_page
  |> projects
  |> App.run_command
