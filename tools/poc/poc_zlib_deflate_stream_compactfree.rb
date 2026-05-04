#!/usr/bin/env ruby
require_relative "poc_utils"
POC.add_build_load_path if ENV["POC_ADD_BUILD_LOAD_PATH"] == "1"
require "zlib"

STDOUT.sync = true
Thread.report_on_exception = true

ENV["POC_AUTO_COMPACT"] = "0" unless ENV.key?("POC_AUTO_COMPACT")
POC.setup_gc

duration = (ENV["POC_SECONDS"] || "300").to_i
rng = Random.new(0xD1F1A7E)

class EvilToStr
  def initialize(text)
    @text = text
  end

  def to_str
    120.times { "d" * 4096 }
    GC.start(full_mark: true, immediate_sweep: true)
    String.new(@text)
  end
end

gc_thread = POC.start_gc_hammer
alloc_thread = POC.start_alloc_hammer

iterations = 0
begin
  POC.run_for(duration) do
    len = 4096 + rng.rand(16_384)
    byte = (65 + rng.rand(26)).chr
    payload = byte * len

    z = Zlib::Deflate.new(Zlib::DEFAULT_COMPRESSION)
    begin
      compressed = z.deflate(EvilToStr.new(payload), Zlib::FINISH)
    ensure
      z.close rescue nil
    end

    restored = Zlib::Inflate.inflate(compressed)
    unless restored == payload
      warn "MISMATCH(deflate_stream) at iteration=#{iterations}"
      warn "payload_len=#{payload.bytesize}"
      warn "restored_len=#{restored.bytesize}"
      exit 2
    end

    # Exercise the << path (rb_deflate_addstr/do_deflate).
    z2 = Zlib::Deflate.new
    begin
      z2 << EvilToStr.new(payload)
      compressed2 = z2.finish
    ensure
      z2.close rescue nil
    end

    restored2 = Zlib::Inflate.inflate(compressed2)
    unless restored2 == payload
      warn "MISMATCH(deflate_addstr) at iteration=#{iterations}"
      warn "payload_len=#{payload.bytesize}"
      warn "restored2_len=#{restored2.bytesize}"
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
