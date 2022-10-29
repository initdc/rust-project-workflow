ZIG_LINKERS_DIR = "zig-linkers"
`mkdir -p #{ZIG_LINKERS_DIR}`

def gen_zig_linkers zig_target, zig_linker
    wrapper = "#!/bin/sh
#{zig_linker} #{zig_target} $@"

    `echo > #{ZIG_LINKERS_DIR}/#{zig_target} '#{wrapper}'`
    `sudo chmod +x #{ZIG_LINKERS_DIR}/#{zig_target}`
end
