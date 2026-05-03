#!/usr/bin/env ruby
# Stress ArithmeticSequence#inspect (enumerator.c:arith_seq_inspect) under heavy GC compaction.
#
# Run with: /path/to/ruby tools/poc/poc_arith_seq_inspect.rb

require_relative "poc_utils"

STDOUT.sync = true
Thread.report_on_exception = true

ENV["POC_AUTO_COMPACT"] = "1" unless ENV.key?("POC_AUTO_COMPACT")
ENV["POC_GC_STRESS_MODE"] = "immediate" unless ENV.key?("POC_GC_STRESS_MODE")
POC.setup_gc

duration = (ENV["POC_SECONDS"] || "30").to_i
deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + duration

gc_thread = Thread.new do
  loop do
    GC.compact if GC.respond_to?(:compact)
    GC.start(full_mark: true, immediate_sweep: true)
  end
end

alloc_thread = Thread.new do
  loop do
    junk = Array.new(200) { "x" * 1024 }
    junk.shuffle!
  end
end

klass = Class.new do
  def initialize(tag)
    @tag = tag
  end

  def inspect
    20.times { "x" * 10_000 }
    POC.force_compaction
    "EVIL#{@tag}"
  end

  def coerce(value)
    [value, 1]
  end
end

iterations = 0
while Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
  limit = klass.new("limit#{iterations}")
  step = klass.new("step#{iterations}")
  inspected = 1.step(limit, step).inspect
  unless inspected.include?("EVILlimit#{iterations}") &&
         inspected.include?("EVILstep#{iterations}")
    raise "CORRUPTION: arith_seq_inspect output mismatch: #{inspected.inspect}"
  end
  iterations += 1
  puts "iterations=#{iterations}" if (iterations % 1000).zero?
end

gc_thread.kill
alloc_thread.kill

puts "done iterations=#{iterations}"
