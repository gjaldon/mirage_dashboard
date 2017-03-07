open Opium.Std
open Github_t
open Lwt.Infix

module Server = Cohttp_lwt_unix.Server


let home_page = get "/" (fun req ->
    let headers = Cohttp.Header.init_with "content-type" "html" in
    Server.respond_file ~headers ~fname:"./index.html" () >|= fun resp ->
    Response.of_response_body resp
  )

let get_repos = get "/repos" (fun req ->
    Md_github.repos >>= fun (repos, total_pages) ->
    let headers = Cohttp.Header.init_with "content-type" "application/json" in
    let uri = Request.uri req in
    let page = match Uri.get_query_param uri "page" with
      | None -> 1
      | Some page -> int_of_string page
    in
    let repos = Md_github.find_repo_by_page repos page in
    let body = `String (Md_github.json_encode_repos repos page total_pages) in
    Server.respond ~headers ~status:`OK ~body () >|= fun resp ->
    Response.of_response_body resp
  )

let _ =
  let app = App.empty in
  app
  |> middleware (Middleware.static ~local_path:"./_build/js/" ~uri_prefix:"/assets")
  |> home_page
  |> get_repos
  |> App.run_command
