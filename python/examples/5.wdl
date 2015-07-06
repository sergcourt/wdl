task ps {
  command {
    ps ${flags?}
  }
  output {
    File procs = stdout()
  }
}

task find_files {
  command {
    find ${File dir} ${'-maxdepth ' Int max_depth?} | grep '${pattern}'
  }
  output {
    Array[File] files = tsv(stdout())
  }
}

task concat {
  command {
    cat ${sep=" " File files+} > ${default="concatenated" outfile?}
  }
  output {
    File concatenated = "${outfile}"
  }
}

task bytecount {
  command {
    cat ${sep=" " File files+} | wc -c
  }
  output {
    Int bytes = read_int(stdout())
  }
}

task linecount {
  command {
    cat ${sep=" " File files+} | wc -l
  }
  output {
    Int lines = read_int(stdout())
  }
}

workflow sloc {
  Array[File] files
  File source_dir

  /* run 'ps', get the byte count of the output */
  call ps
  call ps as ps_flags {
    input: flags="-ef"
  }
  call bytecount as ps_bytes {
    input: files=ps.procs
  }
  call bytecount as ps_flags_bytes {
    input: files=ps_flags.procs
  }

  /* Test out default parameters.
   * First 'concat' should output to file called "concatenated".
   * Second 'concat' should output to a file called "redirected".
   */
  call concat {
    input: files=files
  }
  call concat as concat2 {
    input:files=files, outfile="redirected"
  }

  /* Find all Java and Scala files, count lines in each
   * and then compute the total file size
   */
  call find_files as find_python_files {
    input: dir=source_dir, pattern="\.py$"
  }
  call bytecount as python_src_bytes {
    input: files=find_python_files.files
  }
  call linecount as python_src_lines {
    input: files=find_python_files.files
  }
}

