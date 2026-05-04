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
    meth = "m_loc_#{iterations}"
    file = "poc_loc_#{iterations}.rb"
    msg = "boom_#{iterations}"

    src = <<~RUBY
      def #{meth}
        raise #{msg.inspect}
      end
      #{meth}
    RUBY

    begin
      eval(src, TOPLEVEL_BINDING, file, 1)
      warn "UNEXPECTED SUCCESS at iteration=#{iterations}"
      exit 2
    rescue => e
      bt0 = e.backtrace&.first.to_s
      unless bt0.include?(file) && bt0.include?(meth)
        warn "MISMATCH(backtrace) at iteration=#{iterations}"
        warn "expected file token=#{file.inspect}"
        warn "expected method token=#{meth.inspect}"
        warn "actual backtrace first=#{bt0.inspect}"
        exit 2
      end

      full = e.full_message(highlight: false, order: :top)
      unless full.include?(msg) && full.include?(file) && full.include?(meth)
        warn "MISMATCH(full_message) at iteration=#{iterations}"
        warn "expected tokens=#{[msg, file, meth].inspect}"
        warn "actual full_message head=#{full.byteslice(0, 400).inspect}"
        exit 2
      end
    end

    iterations += 1
    puts "iterations=#{iterations}" if (iterations % 20).zero?
  end
ensure
  gc_thread&.kill
  alloc_thread&.kill
end

puts "done iterations=#{iterations}"
