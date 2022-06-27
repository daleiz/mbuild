(lang dune 3.2)

(name mbuild)

(generate_opam_files true)

(source
 (github noomettib/mbuild))

(authors "noomettib")

(maintainers "noomettib")

(license Apache-2.0)

(package
 (name mbuild)
 (synopsis "A build system")
 (description "A simple build system")
 (depends ocaml dune)
  )
