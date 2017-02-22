open Lwt.Infix
open Github_t
exception Auth_token_not_found of string

let token =
  Github_cookie_jar.init () >>= fun jar ->
  Github_cookie_jar.get jar "gjaldon" >>= function
  | Some auth -> Lwt.return auth
  | None -> Lwt.fail (Auth_token_not_found "given id not in cookie jar")


let get_repos () =
  Github.(Monad.(run (
    let repos = Github.User.repositories ~user:"mirage" () in
    Github.Stream.to_list repos >>= fun repos ->
    List.iter (fun repo -> Printf.printf "Repo: %s\n" repo.repository_full_name) repos;
    return repos
  )))
