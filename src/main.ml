open Opium.Std
open Tyxml.Html

let index_page =
  "<!DOCTYPE html>
  <html class=\"no-js\" lang=\"en\">
    <head>
      <meta charset=\"utf-8\">
      <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />
      <title>Mirage-Dashboard</title>
    </head>
    <body>
      <div id='app'></div>
      <script type=\"text/javascript\" src=\"assets/client.js\"></script>
    </body>
  </html>"


let home_page = get "/" (fun req ->
    `Html index_page |> respond')

let _ =
  App.empty
  |> middleware (Middleware.static ~local_path:"./_build/js/" ~uri_prefix:"/assets")
  |> home_page
  |> App.run_command
