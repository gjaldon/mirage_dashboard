open React
open Lwt.Infix

type pagination = {
  repos: Github_t.repositories;
  total_pages: int;
  current_page: int;
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
    }

  let update = function
    | `Initial ->
      {
        repos = [];
        total_pages = 0;
        current_page = 1;
      }
    | `Loaded content ->
      json_to_pagination content

  let display =
    S.l1 update state

  let get_repos_by_page page =
    let repos_path = Printf.sprintf "/repos?page=%i" page in
    XmlHttpRequest.get repos_path >|= fun resp ->
    set_state (`Loaded resp.content)

  let _ =
    get_repos_by_page 1
end

module R = Tyxml_js.R.Html5
open Tyxml_js.Html5

let render () =
  Model.display
  |> S.map (function
      | {repos = []; _} ->
        pcdata "None"
      | {repos; _} ->
        ul (List.map (fun repo ->
          li [pcdata repo.Github_j.repository_name]
        ) repos)
    )
  |> ReactiveData.RList.singleton_s
  |> R.div

let page_onclick page =
  a_onclick (fun _ev -> Model.get_repos_by_page page; true)

let render_pagination () =
  let open Md_util in
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
