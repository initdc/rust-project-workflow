require 'digest'

UPLOAD_DIR = ARGV[0] || "upload"
FILENAME = ARGV[1] || "SHA256SUM"

d = Dir.new(UPLOAD_DIR)
Dir.chdir UPLOAD_DIR do
    file = FILENAME
    IO.write(file, "")

    d.children.sort!.each do |child|
        sha256sum = Digest::SHA256.file(child).hexdigest
        if ! child.include? "SHA256SUM" and ! child.include? "BINARYS"
            o = "#{sha256sum}  #{child}\n"
            print o
            IO.write(file, o, mode: "a")
        end
    end
end