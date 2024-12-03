#!/usr/bin/env ruby

class Parser
    attr_accessor :total
    attr_accessor :skip

    MUL = /mul\((\d+),(\d+)\)/
    DO = /do\(\)/
    DONT = /don't\(\)/


    def initialize
        @total = 0
        @skip = false
    end

    def run
        File.read("src/data/day03.txt").each_line.with_index do |line, i|
            self.total += line.scan(MUL).inject(0) { |sum, m| sum += m.map(&:to_i).reduce(:*) }
        end
    end
    
end

parser = Parser.new
parser.run
puts parser.total