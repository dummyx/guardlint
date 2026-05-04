#!/usr/bin/env ruby
# Runs the current missing-site registry through repeatable GC-compaction profiles.

require "csv"
require "fileutils"
require "open3"
require "optparse"
require "set"
require "time"

DEFAULT_REGISTRY = "tools/poc/current_missing_registry.csv"
DEFAULT_OUTPUT = "tools/poc/current_missing_extreme_results.csv"

Profile = Struct.new(:name, :duration, :env, keyword_init: true)
RunTarget = Struct.new(:poc_id, :source, :runner, :script_path, :site_ids, keyword_init: true)

options = {
  registry: DEFAULT_REGISTRY,
  output: DEFAULT_OUTPUT,
  ruby: ENV["POC_RUBY"] || "ruby",
  turns: 5,
  duration: 180,
  long_duration: 600,
  timeout_slack: 15,
  include_confirmed: true,
  long_followups: true,
  dry_run: false,
  only: nil
}

OptionParser.new do |opts|
  opts.banner = "usage: ruby tools/poc/poc_extreme_campaign.rb [options]"
  opts.on("--registry PATH", "current missing registry CSV") { |v| options[:registry] = v }
  opts.on("--output PATH", "result CSV") { |v| options[:output] = v }
  opts.on("--ruby PATH", "Ruby executable to test") { |v| options[:ruby] = v }
  opts.on("--turns N", Integer, "fresh process turns per base profile") { |v| options[:turns] = v }
  opts.on("--duration SECONDS", Integer, "base profile duration") { |v| options[:duration] = v }
  opts.on("--long-duration SECONDS", Integer, "long follow-up duration") { |v| options[:long_duration] = v }
  opts.on("--timeout-slack SECONDS", Integer, "extra timeout after requested duration") { |v| options[:timeout_slack] = v }
  opts.on("--only IDS", "comma-separated poc_id filter") { |v| options[:only] = v.split(",").map(&:strip).to_set }
  opts.on("--exclude-confirmed", "skip already confirmed cases") { options[:include_confirmed] = false }
  opts.on("--no-long-followups", "disable long reruns for suspicious outcomes") { options[:long_followups] = false }
  opts.on("--quick", "1 turn, 2 seconds, no long followups") do
    options[:turns] = 1
    options[:duration] = 2
    options[:long_followups] = false
  end
  opts.on("--dry-run", "print planned commands without executing") { options[:dry_run] = true }
end.parse!

def snippet(text)
  text.to_s.lines.first(20).join.gsub(/\r?\n/, "\\n")[0, 4000]
end

def base_profiles(duration)
  common = {
    "POC_ADD_BUILD_LOAD_PATH" => "1",
    "POC_AUTO_COMPACT" => "1",
    "POC_ENABLE_EXPLICIT_COMPACT" => "1",
    "POC_ALLOC_HAMMER" => "1",
    "POC_GC_HAMMER_FULL" => "1",
    "POC_GC_HAMMER_COMPACT" => "1"
  }

  [
    Profile.new(
      name: "stress_compact",
      duration: duration,
      env: common.merge("POC_GC_STRESS_MODE" => "immediate")
    ),
    Profile.new(
      name: "compact_no_stress",
      duration: duration,
      env: common
    )
  ]
end

def long_profile(duration)
  Profile.new(
    name: "long_compact",
    duration: duration,
    env: {
      "POC_ADD_BUILD_LOAD_PATH" => "1",
      "POC_AUTO_COMPACT" => "1",
      "POC_ENABLE_EXPLICIT_COMPACT" => "1",
      "POC_ALLOC_HAMMER" => "1",
      "POC_GC_HAMMER_FULL" => "1",
      "POC_GC_HAMMER_COMPACT" => "1"
    }
  )
end

def command_for(target, ruby)
  case target.source
  when "true_runner", "candidate_runner"
    [ruby, target.runner]
  when "standalone_script"
    [ruby, target.script_path]
  else
    nil
  end
end

def env_for(target, profile, ruby)
  env = profile.env.merge(
    "POC_RUBY" => ruby,
    "POC_DURATION" => profile.duration.to_s,
    "POC_SECONDS" => profile.duration.to_s
  )
  env["POC_CASES"] = target.poc_id if target.source.end_with?("_runner")
  env
end

def classify(status, stdout, stderr, timed_out)
  text = "#{stdout}\n#{stderr}"
  return "TIMEOUT" if timed_out
  return "CRASH" if status&.signaled?
  return "CORRUPTION" if text.include?("CORRUPTION") || text.include?("MISMATCH")

  first_runner_label = stdout.to_s.each_line.find { |line| line =~ /\A(?:CRASH|ERROR|TIME|SKIP|PASS)\s+/ }
  if first_runner_label
    label = first_runner_label.split.first
    return "TIMEOUT" if label == "TIME"
    return label
  end

  return "SKIP" if stdout.to_s.start_with?("SKIP:")
  return "PASS" if status&.exitstatus == 0

  "ERROR"
end

def run_with_timeout(env, cmd, timeout_s)
  wrapped = ["timeout", "--kill-after=1s", "#{timeout_s}s", *cmd]
  stdout, stderr, status = Open3.capture3(env, *wrapped)
  timed_out = [124, 137].include?(status&.exitstatus)
  [stdout, stderr, status, timed_out]
end

registry_path = File.expand_path(options[:registry])
abort "missing registry CSV: #{registry_path}" unless File.file?(registry_path)

rows = CSV.read(registry_path, headers: true)
targets = {}
unrunnable = []

rows.each do |row|
  next if row["poc_status"] == "confirmed" && !options[:include_confirmed]
  next if row["poc_source"] == "none"
  next if options[:only] && !options[:only].include?(row["poc_id"])

  cmd_source = row["poc_source"]
  runner = row["runner"]
  script_path = row["script_path"]
  key = [row["poc_id"], cmd_source, runner, script_path]
  targets[key] ||= RunTarget.new(
    poc_id: row["poc_id"],
    source: cmd_source,
    runner: runner,
    script_path: script_path,
    site_ids: []
  )
  targets[key].site_ids << row["site_id"]
end

rows.each do |row|
  next unless row["poc_source"] == "none"
  next if options[:only] && !options[:only].include?(row["function"])
  unrunnable << row
end

profiles = base_profiles(options[:duration])
output_path = File.expand_path(options[:output])
FileUtils.mkdir_p(File.dirname(output_path))

headers = %w[
  timestamp profile turn poc_id source status exitstatus termsig elapsed_s
  duration_s site_count command stdout stderr
]

planned = targets.values.sort_by { |t| [t.source, t.poc_id] }
if options[:dry_run]
  planned.each do |target|
    profiles.each do |profile|
      options[:turns].times do |i|
        puts "#{profile.name} turn=#{i + 1} poc_id=#{target.poc_id} source=#{target.source} sites=#{target.site_ids.size}"
      end
    end
  end
  warn "unrunnable_sites=#{unrunnable.size}"
  exit 0
end

all_results = []
suspicious = Set.new

CSV.open(output_path, "w", write_headers: true, headers: headers) do |csv|
  planned.each do |target|
    cmd = command_for(target, options[:ruby])
    unless cmd
      warn "skip unrunnable target: #{target.poc_id}"
      next
    end

    profiles.each do |profile|
      options[:turns].times do |turn|
        env = env_for(target, profile, options[:ruby])
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        stdout = +""
        stderr = +""
        status = nil
        timed_out = false

        stdout, stderr, status, timed_out =
          run_with_timeout(env, cmd, profile.duration + options[:timeout_slack])

        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
        label = classify(status, stdout, stderr, timed_out)
        suspicious << target if %w[TIMEOUT SKIP ERROR].include?(label)

        result = {
          "timestamp" => Time.now.utc.iso8601,
          "profile" => profile.name,
          "turn" => turn + 1,
          "poc_id" => target.poc_id,
          "source" => target.source,
          "status" => label,
          "exitstatus" => status&.exitstatus,
          "termsig" => status&.termsig,
          "elapsed_s" => format("%.3f", elapsed),
          "duration_s" => profile.duration,
          "site_count" => target.site_ids.size,
          "command" => cmd.join(" "),
          "stdout" => snippet(stdout),
          "stderr" => snippet(stderr)
        }
        csv << headers.map { |h| result[h] }
        csv.flush
        all_results << result
        puts "#{label.ljust(10)} #{profile.name} turn=#{turn + 1} #{target.poc_id}"
      end
    end
  end

  if options[:long_followups]
    profile = long_profile(options[:long_duration])
    suspicious.each do |target|
      cmd = command_for(target, options[:ruby])
      env = env_for(target, profile, options[:ruby])
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      stdout = +""
      stderr = +""
      status = nil
      timed_out = false

      stdout, stderr, status, timed_out =
        run_with_timeout(env, cmd, profile.duration + options[:timeout_slack])

      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      label = classify(status, stdout, stderr, timed_out)
      result = {
        "timestamp" => Time.now.utc.iso8601,
        "profile" => profile.name,
        "turn" => 1,
        "poc_id" => target.poc_id,
        "source" => target.source,
        "status" => label,
        "exitstatus" => status&.exitstatus,
        "termsig" => status&.termsig,
        "elapsed_s" => format("%.3f", elapsed),
        "duration_s" => profile.duration,
        "site_count" => target.site_ids.size,
        "command" => cmd.join(" "),
        "stdout" => snippet(stdout),
        "stderr" => snippet(stderr)
      }
      csv << headers.map { |h| result[h] }
      csv.flush
      all_results << result
      puts "#{label.ljust(10)} #{profile.name} turn=1 #{target.poc_id}"
    end
  end
end

status_counts = all_results.group_by { |r| r["status"] }.transform_values(&:size)
warn "wrote #{all_results.size} run rows to #{output_path}"
warn "status counts: #{status_counts.sort.to_h}"
warn "unrunnable registry sites: #{unrunnable.size}"
