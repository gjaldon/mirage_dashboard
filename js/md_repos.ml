open React
open Lwt.Infix

module Model = struct
  let state, set_state = S.create `Initial

  let update = function
    | `Initial -> []
    | `Loaded content -> Github_j.repositories_of_string content

  let display =
    S.l1 update state

  let _ =
    XmlHttpRequest.get "/repos" >|= fun resp ->
    set_state (`Loaded resp.content)
end

module R = Tyxml_js.R.Html5
open Tyxml_js.Html5

let render () =
  Model.display
  |> S.map (function
      | [] -> pcdata "None"
      | repos ->
        ul (List.map (fun repo ->
          li [pcdata repo.Github_j.repository_name]
        ) repos)
    )
  |> ReactiveData.RList.singleton_s
  |> R.div
