#!/usr/bin/env ruby

require 'fileutils'

# unbreakable XOR encryption
KEY = "&\xB9\xC9\xC5#2\xD0\x8C\xFA\x10,\xCC\xA8\xA2X\xFA".unpack('C*').map { |x| x ^ 0x69 }

if ARGV.size < 1
    puts "Thimbleweed Park file extraction tool"
    puts '-' * 37
    puts
    puts "This script will extract all files from the packfile to a directory called haul."
    puts
    puts "Usage:    ./ggunpack.rb [path to packfile]"
    puts "Example:  ./ggunpack.rb ~/GOG Games/Thimbleweed Park/game/ThimbleweedPark.ggpack1"
    exit(1)
end
    
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

file_index_offset = 0
(0...file_count).each do |i|
    filename = get_string(index[file_index_offset + i * 33 + 31 + 5, 4], string_table)
    offset = get_string(index[file_index_offset + i * 33 + 31 + 14 , 4], string_table).to_i
    size = get_string(index[file_index_offset + i * 33 + 31 + 23, 4], string_table).to_i
    path = "haul/#{filename.split('.').last}/#{filename}"
    if filename =~ /[a-z]{10}\.ogg/
        path = "haul/#{filename.split('.').last}/voicemail/#{filename}"
    end
    FileUtils::mkpath(File::dirname(path))
    puts path
    encrypted = File::binread(ARGV.first, size, offset).bytes
    decrypted = decode(encrypted, size & 0xff)
    File::open(path, 'w') do |f|
        f.write decrypted.pack('C*')
    end
end
