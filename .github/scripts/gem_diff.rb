#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler"
require "open3"
require "set"
require "net/http"
require "json"
require "uri"

BASE_REF = ENV["GITHUB_BASE_REF"] || "main"

# --- LLM INTEGRATION START ---

def generate_llm_prompt(changes)
  # specialized instructions for the LLM
  prompt = <<~TEXT
    You are a Senior Ruby Backend Engineer. Please summarize the following gem upgrades for a code review.
    
    Output a single comment block titled "## Gem Upgrades".
    
    For each upgrade, use this exact format:
    ### gem_name: OLD_VERSION → NEW_VERSION
    - **Breaking changes**: ... (If none known or unlikely, say "None anticipated")
    - **New features**: ...
    - **Bug / security fixes**: ...
    - **Risk level**: Low / Medium / High (with one short reason)

    Guidelines:
    1. **Grouping**: If multiple gems are similar (e.g., `rspec-core`, `rspec-mocks`, or `aws-sdk-*`), summarize them together in one block.
    2. **Scannability**: Use clear, simple language that a reviewer can scan in a few seconds.
    3. **Knowledge**: Rely on your internal knowledge of these gems to fill in features/breaking changes. If the gem is obscure or the version is very new, infer the risk based on Semantic Versioning (Major/Minor/Patch) rules.
    4. **Formatting**: Do not output separate comments. Keep it all in one Markdown response.

    Here is the list of changes:
  TEXT

  changes.each do |c|
    # providing raw data to the LLM so it can format it
    prompt += "- Gem: #{c[:name]} | Old: #{c[:old]} | New: #{c[:new]} | Type: #{c[:kind]} | Groups: #{c[:groups].join(', ')}\n"
  end

  prompt
end

def ask_llm_for_review(prompt)
  api_key = ENV["GEMINI_API_KEY"]
  return nil unless api_key # Fallback if no key provided
  uri = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=#{api_key}")
  # uri = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=#{api_key}")
  
  # For OpenAI, swap with: URI("https://api.openai.com/v1/chat/completions")
  # and adjust the JSON payload accordingly.

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri)
  request["Content-Type"] = "application/json"
  
  # Gemini Payload
  request.body = {
    contents: [{ parts: [{ text: prompt }] }]
  }.to_json

  response = http.request(request)
  
  if response.code == "200"
    json = JSON.parse(response.body)
    return json.dig("candidates", 0, "content", "parts", 0, "text")
  else
    warn "LLM API Error: #{response.code} - #{response.body}"
    return nil
  end
rescue StandardError => e
  warn "LLM Exception: #{e.message}"
  return nil
end

# --- LLM INTEGRATION END ---

def gem_review_path
  env_path = ENV["GEM_REVIEW_PATH"]
  return env_path if env_path && !env_path.strip.empty?
  repo_root = `git rev-parse --show-toplevel`.strip
  repo_root = Dir.pwd if repo_root.empty?
  File.join(repo_root, "gem_review.md")
end

def fetch_base_lockfile
  system("git", "fetch", "origin", BASE_REF, exception: true)
  content = git_show_lockfile("origin/#{BASE_REF}")
  content = git_show_lockfile(BASE_REF) if content.strip.empty?
  
  if content.strip.empty?
    warn "Could not read Gemfile.lock from origin/#{BASE_REF}. Skipping."
    exit 0
  end
  content
end

def git_show_lockfile(ref)
  stdout, _, status = Open3.capture3("git", "show", "#{ref}:Gemfile.lock")
  status.success? ? stdout : ""
end

def parse_lock(content)
  Bundler::LockfileParser.new(content)
end

def version_tuple(v)
  parts = v.to_s.split(".").map(&:to_i)
  (parts + [0, 0, 0])[0, 3]
end

def bump_type(old_v, new_v)
  return "added" if old_v.nil?
  return "removed" if new_v.nil?
  o_maj, o_min, o_pat = version_tuple(old_v)
  n_maj, n_min, n_pat = version_tuple(new_v)
  return "major" if n_maj > o_maj
  return "minor" if n_min > o_min
  return "patch" if n_pat > o_pat
  "changed"
end

def risk_level(kind, groups)
  runtime = groups.empty? || (groups & %w[default runtime]).any?
  case kind
  when "major" then runtime ? "High" : "Medium"
  when "minor" then runtime ? "Medium" : "Low"
  else "Low"
  end
end

# --- MAIN EXECUTION ---

base_lock_content = fetch_base_lockfile
new_lock_content  = File.read("Gemfile.lock")
base_lock = parse_lock(base_lock_content)
new_lock  = parse_lock(new_lock_content)

base_specs = base_lock.specs.map { |s| [s.name, s.version.to_s] }.to_h
new_specs  = new_lock.specs.map { |s| [s.name, s.version.to_s] }.to_h
base_deps = base_lock.dependencies
new_deps  = new_lock.dependencies

all_gems = Set.new(base_specs.keys) | Set.new(new_specs.keys)
changes = []

all_gems.each do |name|
  old_v = base_specs[name]
  new_v = new_specs[name]
  next if old_v == new_v

  kind = bump_type(old_v, new_v)
  groups = if new_deps[name]
             new_deps[name].groups.map(&:to_s)
           elsif base_deps[name]
             base_deps[name].groups.map(&:to_s)
           else
             []
           end
  
  changes << {
    name: name,
    old:  old_v,
    new:  new_v,
    kind: kind,
    groups: (groups.empty? ? ["transitive"] : groups),
    risk: risk_level(kind, groups)
  }
end

if changes.empty?
  File.write(gem_review_path, "No gem version changes detected.")
  exit 0
end

# --- GENERATE OUTPUT ---

# 1. Try to get AI Review
prompt = generate_llm_prompt(changes)
ai_review = ask_llm_for_review(prompt)

final_output = ""

if ai_review
  final_output = ai_review
  final_output += "\n\n_Review generated by AI based on Gemfile diffs._"
else
  # 2. Fallback to standard table if AI fails or no key
  puts "Falling back to static table generation..."
  
  direct, transitive = changes.partition { |c| (c[:groups] & ["runtime", "development", "test"]).any? }
  
  markdown = +"## Dependency change summary\n\n"
  markdown << "Base branch: `#{BASE_REF}`\n\n"

  [["Direct dependencies", direct], ["Transitive / stdlib gems", transitive]].each do |title, list|
    next if list.empty?
    markdown << "### #{title}\n\n"
    markdown << "| Gem | Old | New | Risk |\n|---|---|---|---|\n"
    list.sort_by { |c| c[:name] }.each do |c|
      markdown << "| `#{c[:name]}` | #{c[:old]} | #{c[:new]} | #{c[:risk]} |\n"
    end
    markdown << "\n"
  end
  final_output = markdown
end

File.write(gem_review_path, final_output)
puts final_output