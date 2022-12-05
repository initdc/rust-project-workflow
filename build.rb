require "./version"
require "./get-version"

PROGRAM = "rust-demo"
# VERSION = "v0.1.0"
BUILD_CMD = "cargo build"
RELEASE_BUILD = true
RELEASE_ARG = RELEASE_BUILD == true ? "--release" : ""
RELEASE = RELEASE_BUILD == true ? "release" : "debug"
# used in this way:
# LINKER_ENV BUILD_CMD RELEASE_ARG TARGET_ARG
TEST_CMD = "cargo test"

TARGET_DIR = "target"
DOCKER_DIR = "docker"
UPLOAD_DIR = "upload"

def doCleanAll
    `rm -rf #{TARGET_DIR} #{UPLOAD_DIR}`
end

def doClean
    `rm -rf #{TARGET_DIR}/#{DOCKER_DIR} #{UPLOAD_DIR}`
end

# go tool dist list
# linux only for docker
GO_RUST = {
    "linux/386": ["i686-unknown-linux-gnu", "i686-unknown-linux-musl"],
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
    # Tier 2
    "5": {"armv5te-unknown-linux-gnueabi": "arm-linux-gnueabi-gcc", "armv5te-unknown-linux-musleabi": "arm-linux-musleabi-gcc"},
    # Tier 2 Host
    "6": {"arm-unknown-linux-gnueabi": "arm-linux-gnueabi-gcc", "arm-unknown-linux-gnueabihf": "arm-unknown-linux-gnueabihf-gcc"},
    "7": {"armv7-unknown-linux-gnueabihf": "arm-linux-gnueabihf-gcc"},
}

# Rust Platform Support Tier ( 1 & 2 ) with Host Tools
# https://doc.rust-lang.org/nightly/rustc/platform-support.html
# linker info from cross-rs/cross
# https://github.com/cross-rs/cross/tree/main/docker
TIER_1_HOST = {
    "aarch64-unknown-linux-gnu": "aarch64-linux-gnu-gcc",
    "i686-pc-windows-gnu": "i686-w64-mingw32-gcc",
    "i686-pc-windows-msvc": "",
    "i686-unknown-linux-gnu": "i686-linux-gnu-gcc",
    "x86_64-apple-darwin": "x86_64-apple-darwin-clang",
    "x86_64-pc-windows-gnu": "x86_64-w64-mingw32-gcc",
    "x86_64-pc-windows-msvc": "",
    "x86_64-unknown-linux-gnu": "x86_64-linux-gnu-gcc"
}

TIER_2_HOST = {
    "aarch64-apple-darwin": "aarch64-apple-darwin-gcc",
    "aarch64-pc-windows-msvc": "",
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

TIER_2 = {
    "aarch64-linux-android": "aarch64-linux-android-gcc",
    "arm-linux-androideabi": "arm-linux-androideabi-gcc",
    "armv7-linux-androideabi": "arm-linux-androideabi-gcc",
    "i686-linux-android": "i686-linux-android-gcc",
    "i686-unknown-linux-musl": "",
    "x86_64-linux-android": "x86_64-linux-android-gcc"
}

OS_ARCH = [TIER_1_HOST, TIER_2_HOST, LINUX_ARM[:"5"], TIER_2]

TEST_OS_ARCH = [TIER_1_HOST, LINUX_ARM[:"6"], LINUX_ARM[:"7"]]

LESS_OS_ARCH = [{
    "aarch64-unknown-linux-gnu": "aarch64-linux-gnu-gcc",
    "x86_64-unknown-linux-gnu": "x86_64-linux-gnu-gcc"
}]

CC = [
    "gcc-aarch64-linux-gnu",
    "gcc-arm-linux-gnueabi",
    "gcc-arm-linux-gnueabihf",
    "gcc-mips-linux-gnu",
    "gcc-mips64-linux-gnuabi64",
    "gcc-mips64el-linux-gnuabi64",
    "gcc-mipsel-linux-gnu",
    "gcc-powerpc-linux-gnu",
    "gcc-powerpc64-linux-gnu",
    "gcc-powerpc64le-linux-gnu",
    "gcc-riscv64-linux-gnu",
    "gcc-s390x-linux-gnu",
    "gcc-i686-linux-gnu",
    "gcc-x86-64-linux-gnu",
    "gcc-x86-64-linux-gnux32",
    "musl-dev",
    "musl-tools"
]

def run_install
    cmd = "sudo apt-get install -y #{CC.join(" ")}"
    puts cmd
    IO.popen(cmd) do |r|
        puts r.readlines
    end
end

version = get_version ARGV, 0, VERSION

test_bin = ARGV[0] == "test" || false
less_bin = ARGV[0] == "less" || false

install_cc = ARGV.include? "--install-cc" || false
clean_all = ARGV.include? "--clean-all" || false
clean = ARGV.include? "--clean" || false
run_test = ARGV.include? "--run-test" || false 
catch_error = ARGV.include? "--catch-error" || false

if install_cc
    run_install
    return
end

tiers = OS_ARCH
tiers = TEST_OS_ARCH if test_bin
tiers = LESS_OS_ARCH if less_bin

if clean_all
    doCleanAll
elsif clean
    doClean
# on local machine, you may re-run this script
elsif test_bin || less_bin
    doClean
end

`mkdir -p #{TARGET_DIR} #{UPLOAD_DIR}`
`mkdir -p #{TARGET_DIR}/#{DOCKER_DIR}`

def existsThen cmd, src, dest
    if system "test -f #{src}"
        `#{cmd} #{src} #{dest}`
    end
end

def notExistsThen(cmd, dest, src)
    if not system "test -f #{dest}"
        if system "test -f #{src}"
            cmd = "#{cmd} #{src} #{dest}"
            puts cmd
            IO.popen(cmd) do |r|
                puts r.readlines
            end
        else
            puts "!! #{src} not exists"
        end
    end
end

for tier in tiers
    puts tier.keys

    tier.each do |target, linker|
        tg_array = target.to_s.split('-')
        os = tg_array[2]

        if os != "linux"
            next
        end

        `rustup target add #{target}`

        tg_fmt = target.to_s.split('-').join('_').upcase
        linker_env = "CARGO_TARGET_#{tg_fmt}_LINKER=#{linker}"
        puts linker_env

        if linker != ""
            cmd = "#{linker_env} #{BUILD_CMD} #{RELEASE_ARG} --target #{target}"
        else
            cmd = "#{BUILD_CMD} #{RELEASE_ARG} --target #{target}"
        end

        puts cmd
        IO.popen(cmd) do |r|
            puts r.readlines
        end

        windows = os == "windows"
        program = !windows ? PROGRAM : "#{PROGRAM}.exe"

        existsThen "ln", "#{TARGET_DIR}/#{target}/#{RELEASE}/#{program}", "#{UPLOAD_DIR}/#{target}"
    end
end

GO_RUST.each do |target_platform, targets|
    tp_array = target_platform.to_s.split('/')
    os = tp_array[0]
    architecture = tp_array[1]

    if architecture == "arm"
        LINUX_ARM.each do |variant, target_linker|
            docker = "#{TARGET_DIR}/#{DOCKER_DIR}/#{os}/#{architecture}/v#{variant}"
            puts docker
            `mkdir -p #{docker}`

            if target_linker.keys.length > 1
                target_linker.each do |target, linker|
                    tg_array = target.to_s.split('-')
                    abi = tg_array.last

                    existsThen "ln", "#{TARGET_DIR}/#{target}/#{RELEASE}/#{PROGRAM}", "#{docker}/#{PROGRAM}-#{abi}"
                    Dir.chdir docker do
                        notExistsThen "ln -s", PROGRAM, "#{PROGRAM}-#{abi}"
                    end
                end
            else
                target_linker.each do |target, linker|
                    existsThen "ln", "#{TARGET_DIR}/#{target}/#{RELEASE}/#{PROGRAM}", "#{docker}/#{PROGRAM}"
                end
            end
        end
    else        
        docker = "#{TARGET_DIR}/#{DOCKER_DIR}/#{os}/#{architecture}"
        puts docker
        `mkdir -p #{docker}`

        if targets.kind_of?(Array)
            for target in targets
                tg_array = target.to_s.split('-')
                abi = tg_array.last

                existsThen "ln", "#{TARGET_DIR}/#{target}/#{RELEASE}/#{PROGRAM}", "#{docker}/#{PROGRAM}-#{abi}"
                Dir.chdir docker do
                    notExistsThen "ln -s", PROGRAM, "#{PROGRAM}-#{abi}"
                end
            end
        else
            target = targets
            existsThen "ln", "#{TARGET_DIR}/#{target}/#{RELEASE}/#{PROGRAM}", "#{docker}/#{PROGRAM}"
        end
    end
end

# cmd = "file #{UPLOAD_DIR}/**"
# IO.popen(cmd) do |r|
#     puts r.readlines
# end

file = "#{UPLOAD_DIR}/BINARYS"
IO.write(file, "")

cmd = "tree #{TARGET_DIR}/#{DOCKER_DIR}"
IO.popen(cmd) do |r|
    rd = r.readlines
    puts rd

    for o in rd
        IO.write(file, o, mode: "a")
    end
end

# Dir.chdir UPLOAD_DIR do
#     file = "SHA256SUM"
#     IO.write(file, "")

#     cmd = "sha256sum *"
#     IO.popen(cmd) do |r|
#         rd = r.readlines

#         for o in rd
#             if ! o.include? "SHA256SUM" and ! o.include? "BINARYS"
#                 print o
#                 IO.write(file, o, mode: "a")
#             end
#         end
#     end
# end

# `docker buildx build --platform linux/amd64 -t rust-demo:amd64 . --load`
# cmd = "docker run rust-demo:amd64"
# IO.popen(cmd) do |r|
#     puts r.readlines
# end