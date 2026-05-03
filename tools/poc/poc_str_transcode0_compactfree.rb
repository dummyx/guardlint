#!/usr/bin/env ruby
require_relative "poc_utils"

STDOUT.sync = true
Thread.report_on_exception = true

ENV["POC_AUTO_COMPACT"] = "0" unless ENV.key?("POC_AUTO_COMPACT")
POC.setup_gc

duration = (ENV["POC_SECONDS"] || "300").to_i

gc_thread = POC.start_gc_hammer
alloc_thread = POC.start_alloc_hammer

# Force the str_transcode0 branch that converts non-ASCII-compatible encodings
# to UTF-8 when newline/XML decorators are enabled. Rotate through embedded,
# resized, endian-varied, encode!, and XML decorator shapes.

iterations = 0
begin
  POC.run_for(duration) do
    POC.force_compaction if (iterations % 5).zero?
    POC.exercise_str_transcode0(iterations)
    iterations += 1
    puts "iterations=#{iterations}" if (iterations % 20).zero?
  end
ensure
  gc_thread&.kill
  alloc_thread&.kill
end

puts "done iterations=#{iterations}"
