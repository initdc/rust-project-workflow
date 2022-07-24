TARGET_DIR = "target"
DOCKER_DIR = "docker"
UPLOAD_DIR = "upload"

PROGRAM = "rust-demo"
VERSION = "v0.1.0"
RELEASE = "release"

# go tool dist list
# linux only for docker
GO_RUST = {
    "linux/386": "i686-unknown-linux-gnu", 
    "linux/amd64": ["x86_64-unknown-linux-gnu", "x86_64-unknown-linux-musl"],
    "linux/arm": "",
    "linux/arm64": ["aarch64-unknown-linux-gnu", "aarch64-unknown-linux-musl"],
    "linux/mips": "mips-unknown-linux-gnu",
    "linux/mips64": "mips64-unknown-linux-gnuabi64",
    "linux/mips64le": "mips64el-unknown-linux-gnuabi64",
    "linux/mipsle": "mipsel-unknown-linux-gnu",
    "linux/ppc64": "powerpc64-unknown-linux-gnu",
    "linux/ppc64le": "powerpc64le-unknown-linux-gnu",
    "linux/riscv64": "riscv64gc-unknown-linux-gnu",
    "linux/s390x": "s390x-unknown-linux-gnu",
}

LINUX_ARM = {
    "5": {"armv5te-unknown-linux-gnueabi": "arm-linux-gnueabi-gcc", "armv5te-unknown-linux-musleabi": "arm-linux-musleabihf-gcc"},
    "6": {"arm-unknown-linux-gnueabi": "arm-linux-gnueabi-gcc", "arm-unknown-linux-gnueabihf": "arm-linux-musleabihf-gcc"},
    "7": {"armv7-unknown-linux-gnueabihf": "arm-linux-gnueabihf-gcc"},
}

# Rust Platform Support Tier ( 1 & 2 ) with Host Tools
# https://doc.rust-lang.org/nightly/rustc/platform-support.html
TIER_1 = {
    "aarch64-unknown-linux-gnu": "aarch64-linux-gnu-gcc",
    "i686-pc-windows-gnu": "i686-w64-mingw32-gcc",
    "i686-pc-windows-msvc": "i686-w64-mingw32-gcc",
    "i686-unknown-linux-gnu": "",
    "x86_64-apple-darwin": "x86_64-apple-darwin-clang",
    "x86_64-pc-windows-gnu": "x86_64-w64-mingw32-gcc",
    "x86_64-pc-windows-msvc": "x86_64-w64-mingw32-gcc",
    "x86_64-unknown-linux-gnu": ""
}

TIER_2 = {
    "aarch64-apple-darwin": "aarch64-apple-darwin-gcc",
    "aarch64-pc-windows-msvc": "aarch64-w64-mingw32-gcc",
    "aarch64-unknown-linux-musl": "aarch64-linux-musl-gcc",
    "arm-unknown-linux-gnueabi": "arm-linux-gnueabi-gcc",
    "arm-unknown-linux-gnueabihf": "arm-linux-gnueabihf-gcc",
    "armv7-unknown-linux-gnueabihf": "arm-linux-gnueabihf-gcc",
    "mips-unknown-linux-gnu": "mips-linux-gnu-gcc",
    "mips64-unknown-linux-gnuabi64": "mips64-linux-gnuabi64-gcc",
    "mips64el-unknown-linux-gnuabi64": "mips64el-linux-gnuabi64-gcc",
    "mipsel-unknown-linux-gnu": "mipsel-linux-gnu-gcc",
    "powerpc-unknown-linux-gnu": "powerpc-linux-gnu-gcc",
    "powerpc64-unknown-linux-gnu": "powerpc64-linux-gnu-gcc",
    "powerpc64le-unknown-linux-gnu": "powerpc64le-linux-gnu-gcc",
    "riscv64gc-unknown-linux-gnu": "riscv64-linux-gnu-gcc",
    "s390x-unknown-linux-gnu": "s390x-linux-gnu-gcc",
    "x86_64-unknown-freebsd": "x86_64-unknown-freebsd-gcc",
    "x86_64-unknown-illumos": "x86_64-unknown-illumos-gcc",
    "x86_64-unknown-linux-musl": "",
    "x86_64-unknown-netbsd": "x86_64-unknown-netbsd-gcc",
}

CC = [
    "gcc-aarch64-linux-gnu",
    "gcc-arm-linux-gnueabi",
    "gcc-arm-linux-gnueabihf",
    # "gcc-armv7-linux-gnueabihf",
    "gcc-mips-linux-gnu",
    "gcc-mips64-linux-gnuabi64",
    "gcc-mips64el-linux-gnuabi64",
    "gcc-mipsel-linux-gnu",
    "gcc-powerpc-linux-gnu",
    "gcc-powerpc64-linux-gnu",
    "gcc-powerpc64le-linux-gnu",
    "gcc-riscv64-linux-gnu",
    "gcc-s390x-linux-gnu",
    "gcc-x86-64-linux-gnu",
    "gcc-x86-64-linux-gnux32",
    "musl-dev",
    "musl-tools"
]

`mkdir -p #{TARGET_DIR} #{UPLOAD_DIR}`
`mkdir -p #{TARGET_DIR}/#{DOCKER_DIR}`

cmd = "sudo apt-get install -y #{CC.join(" ")}"
puts cmd
IO.popen(cmd) do |r|
    puts r.readlines
end

`cargo install -f cross`

for tier in [TIER_1, TIER_2, LINUX_ARM[:"5"]]
    puts tier.keys

    tier.each do |target, linker|
        `rustup target add #{target}`

        tg_array = target.to_s.split('-')
        windows = tg_array[2] == "windows"
        linux = tg_array[2] == "linux"

        tg_fmt = target.to_s.split('-').join('_').upcase
        env = "CARGO_TARGET_#{tg_fmt}_LINKER=#{linker}"
        puts env

        if linux
            if linker != ""
                cmd = "#{env} cargo build --#{RELEASE} --target #{target}"
            else
                cmd = "cargo build --#{RELEASE} --target #{target}"
            end
        else
            cmd = "cross build --#{RELEASE} --target #{target}"
        end
        
        puts cmd
        IO.popen(cmd) do |r|
            puts r.readlines
        end

        if windows 
            `ln #{TARGET_DIR}/#{target}/#{RELEASE}/#{PROGRAM}.exe #{UPLOAD_DIR}/#{target}`
        else
            `ln #{TARGET_DIR}/#{target}/#{RELEASE}/#{PROGRAM} #{UPLOAD_DIR}/#{target}`
        end
    end
end

GO_RUST.each do |target_platform, target|
    tp_array = target_platform.to_s.split('/')
    os = tp_array[0]
    architecture = tp_array[1]

    if architecture == "arm"
        LINUX_ARM.each do |variant, target_linker|
            docker = "#{TARGET_DIR}/#{DOCKER_DIR}/#{os}/#{architecture}/v#{variant}"
            `mkdir -p #{docker}`

            if target_linker.keys.length > 1
                target_linker.each do |target, linker|
                    tg_array = target.to_s.split('-')
                    abi = tg_array.last

                    `ln #{TARGET_DIR}/#{target}/#{RELEASE}/#{PROGRAM} #{docker}/#{PROGRAM}-#{abi}`
                end
            else
                target_linker.each do |target, linker|
                    `ln #{TARGET_DIR}/#{target}/#{RELEASE}/#{PROGRAM} #{docker}/#{PROGRAM}`
                end
            end
        end
    else        
        docker = "#{TARGET_DIR}/#{DOCKER_DIR}/#{os}/#{architecture}"
        `mkdir -p #{docker}`

        if target.kind_of?(Array)
            for tg in target
                tg_array = tg.to_s.split('-')
                abi = tg_array.last

                `ln #{TARGET_DIR}/#{tg}/#{RELEASE}/#{PROGRAM} #{docker}/#{PROGRAM}-#{abi}`
            end
        else
            `ln #{TARGET_DIR}/#{target}/#{RELEASE}/#{PROGRAM} #{docker}/#{PROGRAM}`
        end
    end
end

cmd = "file #{UPLOAD_DIR}/**"
IO.popen(cmd) do |r|
    puts r.readlines
end

`docker buildx build --platform linux/amd64 -t rust-demo:amd64 . --load`
cmd = "docker run rust-demo:amd64"
IO.popen(cmd) do |r|
    puts r.readlines
end