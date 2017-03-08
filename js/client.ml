open Tyxml_js.Html5

let main = div [
    Md_repos.render ();
  ]

let () =
  let main_div = Tyxml_js.To_dom.of_node main in
  let app_div = Dom_html.getElementById("app") in
  Dom.appendChild app_div main_div |> ignore
