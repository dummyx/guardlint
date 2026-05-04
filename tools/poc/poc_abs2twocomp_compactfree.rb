#!/usr/bin/env ruby
require_relative "poc_utils"

STDOUT.sync = true
Thread.report_on_exception = true

ENV["POC_AUTO_COMPACT"] = "0" unless ENV.key?("POC_AUTO_COMPACT")
POC.setup_gc

duration = (ENV["POC_SECONDS"] || "300").to_i
rng = Random.new(0xA8522)

gc_thread = POC.start_gc_hammer
alloc_thread = POC.start_alloc_hammer

iterations = 0
begin
  POC.run_for(duration) do
    bits_a = 1024 + rng.rand(3072)
    bits_b = 1024 + rng.rand(3072)
    shift = 1 + rng.rand(256)

    a = (1 << bits_a) - rng.rand(1 << 16)
    b = (1 << bits_b) - rng.rand(1 << 16)
    a = -a if rng.rand(2).zero?
    b = -b if rng.rand(2).zero?

    unless (~a) == (-a - 1)
      warn "MISMATCH(not) at iteration=#{iterations}"
      warn "a=#{a}"
      warn "~a=#{~a}"
      warn "-a-1=#{-a - 1}"
      exit 2
    end

    lhs = (a ^ b)
    rhs = (a | b) - (a & b)
    unless lhs == rhs
      warn "MISMATCH(xor) at iteration=#{iterations}"
      warn "a=#{a}"
      warn "b=#{b}"
      warn "lhs=#{lhs}"
      warn "rhs=#{rhs}"
      exit 2
    end

    nonneg = a.abs
    unless ((nonneg >> shift) << shift) + (nonneg & ((1 << shift) - 1)) == nonneg
      warn "MISMATCH(shift) at iteration=#{iterations}"
      warn "a=#{a}"
      warn "shift=#{shift}"
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
