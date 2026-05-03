# Common helpers for GC-stress PoCs.
module POC
  def self.add_build_load_path
    ext_dir = File.expand_path("../../ruby/build-o3/.ext/x86_64-linux", __dir__)
    objspace_lib_dir = File.expand_path("../../ruby/ext/objspace/lib", __dir__)
    pathname_lib_dir = File.expand_path("../../ruby/ext/pathname/lib", __dir__)
    date_lib_dir = File.expand_path("../../ruby/ext/date/lib", __dir__)
    lib_dir = File.expand_path("../../ruby/lib", __dir__)
    build_dir = File.expand_path("../../ruby/build-o3", __dir__)
    $LOAD_PATH.unshift(ext_dir) if Dir.exist?(ext_dir)
    $LOAD_PATH.unshift(objspace_lib_dir) if Dir.exist?(objspace_lib_dir)
    $LOAD_PATH.unshift(pathname_lib_dir) if Dir.exist?(pathname_lib_dir)
    $LOAD_PATH.unshift(date_lib_dir) if Dir.exist?(date_lib_dir)
    $LOAD_PATH.unshift(lib_dir) if Dir.exist?(lib_dir)
    $LOAD_PATH.unshift(build_dir) if Dir.exist?(build_dir)
  end

  def self.load_optional_transcoders
    require "enc/trans/transdb"
  rescue LoadError
    # Optional: some builds may not have generated transcoder tables.
  end

  def self.setup_gc
    add_build_load_path if ENV["POC_ADD_BUILD_LOAD_PATH"] == "1"
    load_optional_transcoders
    # Default to *no* compaction so a PoC can be used against arbitrary Rubies
    # without requiring/assuming GC compaction support.
    compact_enabled = ENV.fetch("POC_AUTO_COMPACT", "0") != "0"
    if GC.respond_to?(:verify_compaction_references=)
      GC.verify_compaction_references = compact_enabled
    end
    if GC.respond_to?(:auto_compact=)
      GC.auto_compact = compact_enabled
    end
    GC.stress = true
    if ENV["POC_GC_STRESS_MODE"] == "immediate"
      begin
        GC.stress = :immediate
      rescue ArgumentError, TypeError
      end
    end
  end

  def self.start_gc_hammer
    sleep_s = (ENV["POC_GC_HAMMER_SLEEP"] || "0.01").to_f
    full = ENV["POC_GC_HAMMER_FULL"] == "1"
    compact = ENV["POC_GC_HAMMER_COMPACT"] == "1"
    Thread.new do
      loop do
        GC.compact if compact && GC.respond_to?(:compact)
        if full
          GC.start(full_mark: true, immediate_sweep: true)
        else
          GC.start
        end
        sleep(sleep_s) if sleep_s > 0
      end
    end
  end

  def self.start_alloc_hammer
    return unless ENV["POC_ALLOC_HAMMER"] == "1"

    count = (ENV["POC_ALLOC_COUNT"] || "200").to_i
    size = (ENV["POC_ALLOC_SIZE"] || "1024").to_i
    Thread.new do
      loop do
        junk = Array.new(count) { "x" * size }
        junk.shuffle!
      end
    end
  end

  def self.maybe_alloc_junk(iteration)
    return unless ENV["POC_GC_JUNK"] == "1"

    every = (ENV["POC_GC_JUNK_EVERY"] || "1").to_i
    return unless (iteration % every).zero?

    count = (ENV["POC_GC_JUNK_COUNT"] || "100").to_i
    size = (ENV["POC_GC_JUNK_SIZE"] || "512").to_i
    junk = Array.new(count) { "y" * size }
    junk.shuffle!
  end

  def self.force_compaction
    if GC.respond_to?(:verify_compaction_references)
      begin
        GC.verify_compaction_references(double_heap: true, toward: :empty)
        return
      rescue ArgumentError, TypeError
        GC.verify_compaction_references
        return
      end
    end

    GC.compact if GC.respond_to?(:compact)
    GC.start(full_mark: true, immediate_sweep: true)
  end

  def self.run_for(seconds)
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    while (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) < seconds
      yield
    end
  end

  def self.exercise_str_transcode0(iteration)
    load_optional_transcoders

    case iteration % 5
    when 0
      text = "a\nb\n"
      actual = text.encode("UTF-16LE").encode(
        "UTF-32LE",
        invalid: :replace,
        undef: :replace,
        crlf_newline: true
      ).encode("UTF-8")
      expected = "a\r\nb\r\n"
      label = "embedded-crlf"
    when 1
      text = Array.new(160) { |i| "line#{i}" }.join("\n") + "\n"
      actual = text.encode("UTF-16LE").encode(
        "UTF-32LE",
        invalid: :replace,
        undef: :replace,
        crlf_newline: true
      ).encode("UTF-8")
      expected = text.gsub("\n", "\r\n")
      label = "heap-resize-crlf"
    when 2
      text = Array.new(96) { |i| "be#{i}" }.join("\n") + "\n"
      actual = text.encode("UTF-16BE").encode(
        "UTF-32BE",
        invalid: :replace,
        undef: :replace,
        crlf_newline: true
      ).encode("UTF-8")
      expected = text.gsub("\n", "\r\n")
      label = "big-endian-crlf"
    when 3
      text = "x<y&z>\""
      actual = text.encode("UTF-16LE").encode(
        "UTF-32LE",
        invalid: :replace,
        undef: :replace,
        xml: :text
      ).encode("UTF-8")
      expected = "x&lt;y&amp;z&gt;\""
      label = "xml-text"
    else
      text = Array.new(128) { |i| "bang#{i}" }.join("\n") + "\n"
      str = text.encode("UTF-32LE")
      str.encode!(
        "UTF-16LE",
        invalid: :replace,
        undef: :replace,
        crlf_newline: true
      )
      actual = str.encode("UTF-8")
      expected = text.gsub("\n", "\r\n")
      label = "encode-bang-crlf"
    end

    unless actual == expected
      raise "CORRUPTION: str_transcode0 #{label} mismatch at iteration=#{iteration}: #{actual.inspect}"
    end
  end
end
