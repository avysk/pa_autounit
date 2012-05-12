FLAGS=-use-ocamlfind

extension:
	@echo "Building pa_autounit.cmo extension..."
	ocamlbuild $(FLAGS) pa_autounit.cmo
	@echo ""

example: extension
	ocamlbuild $(FLAGS) example.native

ppo: extension
	@echo "Preprocessing example.ml..."
	camlp4orf -I ./_build pa_autounit.cmo example.ml -o example.ppo
	@echo "Result:"
	@echo ""
	@cat example.ppo

clean:
	rm -f example.ppo
	ocamlbuild -clean

.PHONY: extension example ppo clean_ppo clean
