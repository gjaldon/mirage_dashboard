open Lwt.Infix
open Github_t
exception Auth_token_not_found of string

module PageMap = Map.Make(struct type t = int let compare = compare end)

let token =
  Github_cookie_jar.init () >>= fun jar ->
  Github_cookie_jar.get jar "gjaldon" >>= function
  | Some auth -> Lwt.return auth
  | None -> Lwt.fail (Auth_token_not_found "given id 'gjaldon' not in cookie jar")

let get_repos () =
  Github.(Monad.(run (
    let repos = Github.User.repositories ~user:"mirage" () in
    Github.Stream.to_list repos >>= fun repos ->
    return repos
  )))

let repos_to_map repos =
  let map = PageMap.empty in
  let counter = ref 0 in
  let page_no = ref 0 in
  let add_repo_to_page (map, total_pages) repo =
    counter := !counter + 1;
    if !counter = 10 then begin
      page_no := !page_no + 1;
      counter := 0;
    end;
    let repos = try PageMap.find !page_no map with Not_found -> [] in
    let repos = repos @ [repo] in
    (PageMap.add !page_no repos map), !page_no
  in
  List.fold_left add_repo_to_page (map, 0) repos

let repos =
  get_repos () >|= fun repos ->
  repos_to_map repos

let find_repo_by_page repos page =
  PageMap.find page repos

let json_encode_repos repos page total_pages =
  let repos_json = Github_j.string_of_repositories repos |> Yojson.Basic.from_string in
  let json = `Assoc [("current_page", `Int page);
                     ("repos", repos_json);
                     ("total_pages", `Int total_pages)]
  in
  Yojson.Basic.to_string json
