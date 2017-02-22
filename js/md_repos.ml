open React
open Lwt.Infix

module Model = struct
  let state, set_state = S.create `Initial

  let update = function
    | `Initial -> "None"
    | `Loaded content -> content

  let display =
    S.l1 update state

  let _ =
    XmlHttpRequest.get "/repos" >|= fun resp ->
    set_state (`Loaded resp.content)
end
