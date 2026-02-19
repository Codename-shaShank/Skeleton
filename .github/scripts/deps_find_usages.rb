#!/usr/bin/env ruby
# frozen_string_literal: true
# TODO(deps): Review usages of 'rake' in this file for version-specific changes.
# TODO(deps): Review usages of 'sinatra' in this file for version-specific changes.

require "pathname"

GEM_REVIEW_PATH = ENV["GEM_REVIEW_PATH"] || "gem_review.md"

# 1. Read gem_review.md and extract changed gem names from the table
def changed_gems_from_review(path)
  unless File.exist?(path)
    warn "No #{path} found, cannot determine changed gems."
    exit 1
  end

  content = File.read(path)
  gems = []

  # Very simple parser: look for table rows like:
  # | `sinatra` | 1.4.5 | 1.4.8 | patch | ...
  content.each_line do |line|
    # Skip header / separator lines
    next unless line.start_with?("| `")

    if line =~ /\|\s*`([^`]+)`\s*\|/
      gem_name = Regexp.last_match(1)
      gems << gem_name
    end
  end

  gems.uniq
end

# 2. Find candidate files where we might use these gems
def ruby_source_files(root = ".")
  exts = [".rb", ".rake", ".ru"]
  files = []
  Pathname(root).find do |p|
    next unless p.file?
    next unless exts.include?(p.extname)
    # Skip vendor/bundle or other heavy dirs if needed
    next if p.to_s.start_with?("./vendor/bundle")
    files << p
  end
  files
end

# 3. For each gem, search for simple occurrences in the code
def find_usages(gems, files)
  results = Hash.new { |h, k| h[k] = [] }

  files.each do |path|
    lines = path.read.split("\n", -1)
    lines.each_with_index do |line, idx|
      gems.each do |gem|
        # naive search: line contains gem name
        if line.include?(gem)
          results[gem] << { file: path.to_s, line_no: idx + 1, line: line }
        end
      end
    end
  end

  results
end

# 4. Insert TODO comments near usages (very conservative example)
def insert_todo_comments(usages)
  usages.each do |gem, occs|
    occs.group_by { |o| o[:file] }.each do |file, file_occs|
      lines = File.read(file).split("\n", -1)

      # We will insert a TODO comment once per file at top
      todo_line = "# TODO(deps): Review usages of '#{gem}' in this file for version-specific changes."

      # Only add once per file per gem
      next if lines.any? { |l| l.include?(todo_line) }

      # Insert at top of file (after shebang / frozen_string_literal if present)
      insert_index = 0
      insert_index += 1 if lines[0]&.start_with?("#!")
      insert_index += 1 if lines[insert_index]&.include?("frozen_string_literal")

      lines.insert(insert_index, todo_line)
      File.write(file, lines.join("\n"))
    end
  end
end

changed = changed_gems_from_review(GEM_REVIEW_PATH)
if changed.empty?
  puts "No changed gems found in #{GEM_REVIEW_PATH}."
  exit 0
end

puts "Changed gems (from #{GEM_REVIEW_PATH}): #{changed.join(', ')}"

files = ruby_source_files(".")
puts "Scanning #{files.size} Ruby files for usages..."

usages = find_usages(changed, files)

if usages.empty? || usages.values.all?(&:empty?)
  puts "No obvious usages of changed gems found."
  exit 0
end

insert_todo_comments(usages)

puts "Inserted TODO comments for files using changed gems."