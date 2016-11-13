build:
	ocamlbuild -use-ocamlfind main.byte src/main.ml

client: _build/js/client.js

_build/js/client.js:
	ocamlbuild -use-ocamlfind client.byte js/client.ml
	js_of_ocaml +weak.js _build/js/client.byte

clean:
	ocamlbuild -clean
