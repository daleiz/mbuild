module B = Mbuild.Build
module R = Mbuild.Rule
module C = Mbuild.Cmd
module Cf = Mbuild.Cfun
module Cx = Mbuild.Cxxfun

let leveldb () =
  let include_dirs = [ "include"; "port"; Filename.current_dir_name ] in
  let defines = [ "LEVELDB_PLATFORM_POSIX" ] in
  let include_flags = List.map (fun i -> "-I " ^ i) include_dirs in
  let defines_flags = List.map (fun d -> "-D " ^ d) defines in
  let cxxflags = List.append include_flags defines_flags in
  let cxxflags = List.append [ "-fPIC" ] cxxflags in

  let srcs =
    [
      "port/port_config.h";
      "db/builder.cc";
      "db/builder.h";
      "db/c.cc";
      "db/db_impl.cc";
      "db/db_impl.h";
      "db/db_iter.cc";
      "db/db_iter.h";
      "db/dbformat.cc";
      "db/dbformat.h";
      "db/dumpfile.cc";
      "db/filename.cc";
      "db/filename.h";
      "db/log_format.h";
      "db/log_reader.cc";
      "db/log_reader.h";
      "db/log_writer.cc";
      "db/log_writer.h";
      "db/memtable.cc";
      "db/memtable.h";
      "db/repair.cc";
      "db/skiplist.h";
      "db/snapshot.h";
      "db/table_cache.cc";
      "db/table_cache.h";
      "db/version_edit.cc";
      "db/version_edit.h";
      "db/version_set.cc";
      "db/version_set.h";
      "db/write_batch_internal.h";
      "db/write_batch.cc";
      "port/port_stdcxx.h";
      "port/port.h";
      "port/thread_annotations.h";
      "table/block_builder.cc";
      "table/block_builder.h";
      "table/block.cc";
      "table/block.h";
      "table/filter_block.cc";
      "table/filter_block.h";
      "table/format.cc";
      "table/format.h";
      "table/iterator_wrapper.h";
      "table/iterator.cc";
      "table/merger.cc";
      "table/merger.h";
      "table/table_builder.cc";
      "table/table.cc";
      "table/two_level_iterator.cc";
      "table/two_level_iterator.h";
      "util/arena.cc";
      "util/arena.h";
      "util/bloom.cc";
      "util/cache.cc";
      "util/coding.cc";
      "util/coding.h";
      "util/comparator.cc";
      "util/crc32c.cc";
      "util/crc32c.h";
      "util/env.cc";
      "util/filter_policy.cc";
      "util/hash.cc";
      "util/hash.h";
      "util/logging.cc";
      "util/logging.h";
      "util/mutexlock.h";
      "util/no_destructor.h";
      "util/options.cc";
      "util/random.h";
      "util/status.cc";
      "util/env_posix.cc";
      "util/posix_logger.h";
      "helpers/memenv/memenv.cc";
      "helpers/memenv/memenv.h";
    ]
  in
  let cc_srcs = List.filter (fun s -> Filename.check_suffix s "cc") srcs in
  (* let rules = Cx.static_lib ~cxxflags cc_srcs "leveldb" in *)
  let rules = Cx.shared_lib ~cxxflags cc_srcs "leveldb" in
  let mbuild = B.create rules in
  let () = B.ninja mbuild in

  ()

let () =
  let open Alcotest in
  run "tests" [ ("leveldb", [ test_case "" `Quick leveldb ]) ]
