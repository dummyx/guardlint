#!/usr/bin/env ruby
require_relative "poc_utils"

STDOUT.sync = true
Thread.report_on_exception = true

ENV["POC_AUTO_COMPACT"] = "0" unless ENV.key?("POC_AUTO_COMPACT")
POC.setup_gc

duration = (ENV["POC_SECONDS"] || "300").to_i
rng = Random.new(0xB16B00B5)

gc_thread = POC.start_gc_hammer
alloc_thread = POC.start_alloc_hammer

iterations = 0
begin
  POC.run_for(duration) do
    bits_a = 2048 + rng.rand(2048)
    bits_b = 128 + rng.rand(512)

    a = (1 << bits_a) - rng.rand(1 << 16)
    b = (1 << bits_b) + rng.rand(1 << 16)

    a = -a if rng.rand(2).zero?
    b = -b if rng.rand(2).zero?

    q, r = a.divmod(b)

    unless q * b + r == a
      warn "MISMATCH(sum) at iteration=#{iterations}"
      warn "a=#{a}"
      warn "b=#{b}"
      warn "q=#{q}"
      warn "r=#{r}"
      exit 2
    end

    unless r.abs < b.abs
      warn "MISMATCH(range) at iteration=#{iterations}"
      warn "a=#{a}"
      warn "b=#{b}"
      warn "q=#{q}"
      warn "r=#{r}"
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
