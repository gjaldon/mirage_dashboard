open React
open Lwt.Infix
open Github_t

type pagination = {
  repos: repositories;
  total_pages: int;
  current_page: int;
  selected_repo: repository option;
}

module Model = struct

  let state, set_state = S.create `Initial

  let json_to_pagination json =
    let open Yojson.Basic in
    let json = from_string json in
    {
      repos = Util.member "repos" json |> to_string |> Github_j.repositories_of_string;
      total_pages = Util.member "total_pages" json |> Util.to_int;
      current_page = Util.member "current_page" json |> Util.to_int;
      selected_repo = None;
    }

  let update = function
    | `Initial ->
      {
        repos = [];
        total_pages = 0;
        current_page = 1;
        selected_repo = None;
      }
    | `Loaded content ->
      json_to_pagination content
    | `Selected (record, repo) ->
      { record with selected_repo = repo }
    | `List record ->
      { record with selected_repo = None }

  let display =
    S.l1 update state

  let get_repos_by_page page =
    let repos_path = Printf.sprintf "/repos?page=%i" page in
    XmlHttpRequest.get repos_path >|= fun resp ->
    set_state (`Loaded resp.content)

  let select_repo record id =
    let find_repo () =
      try Some (List.find (fun repo -> compare repo.repository_id id = 0) record.repos) with
      | Not_found -> None
    in
    let repo = find_repo () in
    set_state (`Selected (record, repo))

  let list_repos record =
    set_state (`List record)

  let _ =
    get_repos_by_page 1
end

module R = Tyxml_js.R.Html5
open Tyxml_js.Html5

let onclick_repo record repo_id =
  Printf.printf "Selected repo id: %s" (Int64.to_string repo_id);
  a_onclick (fun _ev -> Model.select_repo record repo_id; true)

let render_repos () =
  Model.display
  |> S.map (function
      | {repos = []; _} ->
        pcdata "None"
      | {repos; _} as record ->
        ul (List.map (fun repo ->
          li ~a:[onclick_repo record repo.repository_id] [pcdata repo.repository_name]
        ) repos)
    )
  |> ReactiveData.RList.singleton_s
  |> R.div

let page_onclick page =
  a_onclick (fun _ev -> Model.get_repos_by_page page |> ignore; true)

open Md_util

let render_pagination () =
  Model.display
  |> S.map (fun pagination ->
      let {total_pages; current_page; _} = pagination in
      let list_items =
        List.map (fun page ->
            let classes =
              if page = current_page then ["page_number"; "current_page"] else ["page_number"]
            in
            li ~a:[a_class classes; page_onclick page] [pcdata (string_of_int page)]
          ) (1--total_pages)
      in
      ul ~a:[a_class ["pagination"]] list_items
    )
  |> ReactiveData.RList.singleton_s
  |> R.div

let back_onclick record =
  a_onclick (fun _ev -> Model.list_repos record |> ignore; true)

let render () =
  Model.display
  |> S.map (fun record ->
      let {selected_repo; _} = record in
      match selected_repo with
      | None ->
        div [
          render_repos ();
          render_pagination ();
        ]
      | Some repo ->
        div [
          h2 [pcdata (Printf.sprintf "Repo: %s" repo.repository_full_name)];
          dl [
            dt [pcdata "Description"];
            dd [opt_with_default repo.repository_description "N/A" |> pcdata];
            dt [pcdata "Repo URL"];
            dd [pcdata repo.repository_html_url];
            dt [pcdata "Forks"];
            dd [string_of_int repo.repository_forks_count |> pcdata];
            dt [pcdata "Stars"];
            dd [string_of_int repo.repository_stargazers_count |> pcdata];
          ];
          a ~a:[back_onclick record; a_href "#"] [pcdata "Back"];
        ]

    )
  |> ReactiveData.RList.singleton_s
  |> R.div
