#! /usr/bin/env ruby

def generate_token_helper
  File.open("token_helper.h", "w") do |file|
    file.puts <<~TEXT
      inline static char *token_name(int n)
      {
        switch(n) {
    TEXT
    File.open("parse.h", "r") do |f|
      f.each_line do |line|
        data = line.match(/\A#define\s+(\w+)\s+\d+$/)
        if data
          file.puts "    case(#{data[1]}): return \"#{data[1].ljust(12)}\";"
        end
      end
    end
    file.puts <<~TEXT
          default: return "\\e[37;41;1m\\\"UNDEFINED\\\"\\e[m";
        }
      }
    TEXT
  end
end

def generate_atom_helper
  File.open("atom_helper.h", "w") do |file|
    file.puts ""
    file.puts <<~TEXT
      inline static char *atom_name(AtomType n)
      {
        switch(n) {
    TEXT
    File.open("parse_header.h", "r") do |f|
      f.each_line do |line|
        break if line.match?("enum atom_type")
      end
      f.each_line do |line|
        break if line.match?("AtomType")
        data = line.match(/(\w+)(\s+=\s+\d+)?,?$/)
        if data
          file.puts "    case(#{data[1]}): return \"#{data[1]}\";"
        end
      end
    end
    file.puts <<~TEXT
          default: return "\\e[37;41;1m\\\"UNDEFINED\\\"\\e[m";
        }
      }
    TEXT
  end
end

case ARGV[0]
when "token"
  generate_token_helper
when "atom"
  generate_atom_helper
else
  p ARGV
  raise "Argument error!"
end
