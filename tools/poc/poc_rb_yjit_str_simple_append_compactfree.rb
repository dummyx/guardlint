#!/usr/bin/env ruby
require_relative "poc_utils"

STDOUT.sync = true
Thread.report_on_exception = true

unless defined?(RubyVM::YJIT)
  puts "SKIP: YJIT unavailable"
  exit 0
end

RubyVM::YJIT.enable if RubyVM::YJIT.respond_to?(:enable)
unless RubyVM::YJIT.respond_to?(:enabled?) && RubyVM::YJIT.enabled?
  puts "SKIP: YJIT not enabled"
  exit 0
end

ENV["POC_AUTO_COMPACT"] = "0" unless ENV.key?("POC_AUTO_COMPACT")
POC.setup_gc

duration = (ENV["POC_SECONDS"] || "300").to_i

gc_thread = POC.start_gc_hammer
alloc_thread = POC.start_alloc_hammer

iterations = 0
begin
  POC.run_for(duration) do
    s = +""
    4000.times do |i|
      s << ((i % 26) + 97).chr
    end

    unless s.bytesize == 4000
      warn "MISMATCH(size) at iteration=#{iterations}"
      warn "actual_size=#{s.bytesize}"
      exit 2
    end

    unless s.getbyte(0) == 97 && s.getbyte(25) == 122 && s.getbyte(26) == 97
      warn "MISMATCH(pattern) at iteration=#{iterations}"
      warn "prefix=#{s.byteslice(0, 64).inspect}"
      exit 2
    end

    iterations += 1
    puts "iterations=#{iterations}" if (iterations % 50).zero?
  end
ensure
  gc_thread&.kill
  alloc_thread&.kill
end

puts "done iterations=#{iterations}"
