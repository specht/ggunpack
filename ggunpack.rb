#!/usr/bin/env ruby
require 'fileutils'
require 'cgi'

# prettify paths for voicemail messages, talkies and lip sync files
# for example:
# 'ogg/nrqsnhtcvm.ogg' becomes 'ogg/voicemail/4513 - Gary Winnick.ogg'
# set to false if you want the original filenames
PRETTY_PATHS = true

# write a HTML file with all library books to the output directory,
# look for 'Thimbleweed Park Library Books.html'
WRITE_BOOK_READER = true

# unbreakable XOR encryption
KEY = "&\xB9\xC9\xC5#2\xD0\x8C\xFA\x10,\xCC\xA8\xA2X\xFA".unpack('C*').map { |x| x ^ 0x69 }

if ARGV.size < 1
    puts "Thimbleweed Park file extraction tool"
    puts '-' * 37
    puts
    puts "This script will list and extract all files from the given packfile."
    puts
    puts "Usage:    ./ggunpack.rb <path to packfile> [--destination <path>]"
    puts
    puts "List files:"
    puts "  ./ggunpack.rb ~/GOG Games/Thimbleweed Park/game/ThimbleweedPark.ggpack1"
    puts
    puts "Extract files:"
    puts "  ./ggunpack.rb ~/GOG Games/Thimbleweed Park/game/ThimbleweedPark.ggpack1 --destination haul"
    puts
    puts "Options:"
    puts "  --destination   specify a destination directory"
    exit(1)
end

dest_dir = nil
dest_index = ARGV.index('--destination')
dest_dir = ARGV[dest_index + 1] if dest_index && dest_index + 1 < ARGV.size
    
def decode(buffer, seed)
    result = []
    r11 = seed
    r10 = 0
    r12 = buffer.size
    (0...r12).each do |r9|
        r8 = r10
        r8 ^= buffer[r9]
        r8 &= 0xff
        rdx = r9 & 0xf
        r10 += 0x6d
        r10 &= 0xff
        r8 ^= r11
        r8 ^= KEY[rdx]
        result << r8
        r11 ^= r8
    end
    result
end

path = ARGV.first
index_offset = File::binread(path, 4, 0).unpack('V').first
index_size = File::binread(path, 4, 4).unpack('V').first
index = decode(File::binread(path, index_size, index_offset).bytes, index_size & 0xff)
file_count = index[22, 4].pack('C*').unpack('V').first

string_table = []
strings_offset = 31 + file_count * 33 - 2

number = 0
i = 0
while number != 0xffffffff
    number = index[strings_offset + i * 4, 4].pack('C*').unpack('V').first
    s = ''
    while index[number] != 0 && number < index.size
        s += index[number].chr
        number += 1
    end
    string_table << s
    i += 1
end

strings = index[strings_offset + string_table.size * 4 + 1, index.size].pack('C*').split("\0")

def get_string(a, string_table)
    string_table[a.pack('C*').unpack('V').first]
end

phone_book = {}

file_index_offset = 0
(0...file_count).each do |i|
    filename = get_string(index[file_index_offset + i * 33 + 31 + 5, 4], string_table)
    offset = get_string(index[file_index_offset + i * 33 + 31 + 14 , 4], string_table).to_i
    size = get_string(index[file_index_offset + i * 33 + 31 + 23, 4], string_table).to_i
    if WRITE_BOOK_READER || PRETTY_PATHS
        if filename == 'LibraryBookText_en.txt' || filename == 'PhoneBookNames.txt'
            decoded = decode(File::binread(ARGV.first, size, offset).bytes, size & 0xff).pack('C*')
            if filename == 'PhoneBookNames.txt'
                decoded.split("\n").map { |x| x.split("\t") }.each do |entry|
                    phone_book[entry.first] = entry
                end
            elsif filename == 'LibraryBookText_en.txt'
                if dest_dir
                    File::open(File::join(dest_dir, 'Thimbleweed Park Library Books.html'), 'w') do |f|
                        f.puts '<html>'
                        f.puts '<meta charset="utf-8"/>'
                        f.puts "<head><style type='text/css'>body { font-family: mono; font-size: 9pt; }"
                        f.puts "hr { border: 0; border-top: 0.5px solid #aaa;} </style></head>"
                        f.puts '<body>'
                        lines = decoded.split("\n")
                        lines.shift
                        lines.map { |x| x.split("\t") }.each do |entry|
                            f.puts "<div style='page-break-inside: avoid;'>"
                            f.puts "<h2>#{entry[2]}</h2>"
                            f.puts "<p><i>by #{entry[3]}</i></p>"
                            f.puts "<p>#{CGI.escapeHTML(entry[4]).gsub('|', '<br />')}</p>"
                            f.puts "<p style='text-align: center;'>~</p>"
                            f.puts "<p>#{CGI.escapeHTML(entry[5]).gsub('|', '<br />')}</p>"
                            f.puts "</div>"
                            f.puts "<hr />"
                        end
                        f.puts '</body>'
                        f.puts '</html>'
                    end
                end
            end
        end
    end
    path = "#{filename.split('.').last}/#{filename}"
    if PRETTY_PATHS
        if filename =~ /^[a-z]{10}\.ogg$/
            token = filename.sub('.ogg', '')
            path = "#{filename.split('.').last}/voicemail/#{phone_book[token][1]} - #{phone_book[token][3].gsub('/', '_')}.ogg" 
        end
        path = "#{filename.split('.').last}/#{filename.split('_').first}/#{filename}" if filename =~ /^[A-Z]+_\d+\./
    end
    if dest_dir
        path = File::join(dest_dir, path)
        FileUtils::mkpath(File::dirname(path))
        puts path
        unless File::exists?(path)
            File::open(path, 'w') do |f|
                decoded = decode(File::binread(ARGV.first, size, offset).bytes, size & 0xff).pack('C*')
                f.write decoded
            end
        end
    else
        puts path
    end
end
