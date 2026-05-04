#!/usr/bin/env ruby
require_relative "poc_utils"

STDOUT.sync = true
Thread.report_on_exception = true

ENV["POC_AUTO_COMPACT"] = "0" unless ENV.key?("POC_AUTO_COMPACT")
POC.setup_gc

duration = (ENV["POC_SECONDS"] || "300").to_i

gc_thread = POC.start_gc_hammer
alloc_thread = POC.start_alloc_hammer

iterations = 0
begin
  POC.run_for(duration) do
    token = "T#{iterations}_" + ("x" * 128)
    src = "L#{token}R"

    out = src.gsub(/(#{Regexp.escape(token)})/, "\\`<\\1>\\'")
    expected = "LL<#{token}>RR"

    unless out == expected
      warn "MISMATCH at iteration=#{iterations}"
      warn "expected bytes=#{expected.bytesize}"
      warn "got bytes=#{out.bytesize}"
      warn "expected head=#{expected.byteslice(0, 200).inspect}"
      warn "got head=#{out.byteslice(0, 200).inspect}"
      exit 2
    end

    iterations += 1
    puts "iterations=#{iterations}" if (iterations % 20).zero?
  end
ensure
  gc_thread&.kill
  alloc_thread&.kill
end

puts "done iterations=#{iterations}"
