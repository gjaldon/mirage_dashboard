open Opium.Std
open Github_t
open Lwt.Infix

module Server = Cohttp_lwt_unix.Server
module PageMap = Map.Make(struct type t = int let compare = compare end)


let home_page = get "/" (fun req ->
    let headers = Cohttp.Header.init_with "content-type" "html" in
    Server.respond_file ~headers ~fname:"./index.html" () >|= fun resp ->
    Response.of_response_body resp
  )

let repos_to_map repos =
  let map = PageMap.empty in
  let counter = ref 0 in
  let page_no = ref 0 in
  let add_repo_to_page map repo =
    counter := !counter + 1;
    if !counter = 10 then begin
      page_no := !page_no + 1;
      counter := 0;
    end;
    let repos = try PageMap.find !page_no map with Not_found -> [] in
    let repos = repos @ [repo] in
    PageMap.add !page_no repos map
  in
  List.fold_left add_repo_to_page map repos

let repos =
  Md_github.get_repos () >|= fun repos ->
  repos_to_map repos

let get_repos = get "/repos" (fun req ->
    repos >>= fun repos ->
    let headers = Cohttp.Header.init_with "content-type" "application/json" in
    let uri = Request.uri req in
    let page = match  Uri.get_query_param uri "page" with
      | None -> 1
      | Some page -> int_of_string page
    in
    let repos = PageMap.find page repos in
    let body = `String (Github_j.string_of_repositories repos) in
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
