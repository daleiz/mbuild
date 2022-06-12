let static_lib ?(cxx = "g++") ?(cxxflags = []) ?(build_dir = "_ninja_build")
    srcs name =
  Cfun.static_lib ~cc:cxx ~cflags:cxxflags ~build_dir srcs name

let shared_lib ?(cxx = "gcc") ?(cxxflags = []) ?(build_dir = "_ninja_build")
    ?(ldflags = []) ?(libs = []) srcs name =
  Cfun.shared_lib ~cc:cxx ~cflags:cxxflags ~build_dir ~ldflags ~libs srcs name

let exe ?(cxx = "g++") ?(cxxflags = []) ?(build_dir = "_ninja_build")
    ?(ldflags = [ "" ]) ?(libs = []) srcs name =
  Cfun.exe ~cc:cxx ~cflags:cxxflags ~build_dir ~ldflags ~libs srcs name
