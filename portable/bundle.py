import argparse
import json
import re
import shutil
import stat
import sys
from pathlib import Path

HOME_PLACEHOLDER = "/__HOME__"
VENDOR_DIRECTORY = Path(".local/share/dotfiles")

STORE_PATH = re.compile(
    r"(?P<store>/nix/store/[0-9a-z]{32}-(?P<name>[^/\s\"'`:;()]+))"
    r"(?P<bin>/bin(?:/(?P<command>[\w.+-]+)|(?P<separator>:)))?"
)
STORE_SHEBANG = re.compile(r"^#!/nix/store/[0-9a-z]{32}-[^/\s]+/bin/(?P<command>\S+)")
STORE_REFERENCE = re.compile(rb"/nix/store/[0-9a-z]{32}-")
VIMRC = re.compile(rb"/nix/store/[0-9a-z]{32}-vimrc")


class Bundle:
    def __init__(self, output, homebrew_packages):
        self.output = output
        self.homebrew_packages = homebrew_packages
        self.vendored = {}

    def add(self, source, destination):
        if source.is_dir():
            shutil.copytree(
                source,
                destination,
                ignore=self.skipped_links,
                dirs_exist_ok=True,
            )
        else:
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, destination)
            shutil.copymode(source, destination)
        make_writable(destination)
        for file in files_below(destination):
            self.rewrite(file)

    def skipped_links(self, directory, names):
        return [name for name in names if self.is_skipped_link(Path(directory) / name)]

    def is_skipped_link(self, path):
        return path.is_symlink() and (not path.exists() or self.is_homebrew_link(path))

    def is_homebrew_link(self, path):
        target = path.resolve().parts
        return target[:3] == ("/", "nix", "store") and target[3] in self.homebrew_packages

    def rewrite(self, file):
        text = read_text(file)
        if text is None:
            return
        rewritten = STORE_PATH.sub(self.replace_store_path, replace_shebang(text))
        if rewritten != text:
            file.write_text(rewritten)

    def replace_store_path(self, match):
        store_path = Path(match["store"])
        if store_path.name in self.homebrew_packages:
            return self.homebrew_command(store_path, match)
        return self.vendor(store_path, match["name"]) + (match["bin"] or "")

    def homebrew_command(self, store_path, match):
        if match["separator"]:
            return ""
        if match["command"]:
            return self.homebrew_packages[store_path.name]["commandPrefix"] + match["command"]
        sys.exit(f"{store_path} is provided by Homebrew, but referenced outside of bin/")

    def vendor(self, store_path, name):
        vendored_as = self.vendored.setdefault(name, store_path)
        if vendored_as != store_path:
            sys.exit(f"{store_path} and {vendored_as} would both be vendored as {name}")
        destination = VENDOR_DIRECTORY / name
        if not (self.output / destination).exists():
            self.add(store_path, self.output / destination)
        return f"{HOME_PLACEHOLDER}/{destination}"

    def assert_self_contained(self):
        leftovers = [str(file) for file in files_below(self.output) if STORE_REFERENCE.search(file.read_bytes())]
        if leftovers:
            sys.exit("Nix store references left in:\n" + "\n".join(leftovers))


def make_writable(path):
    for entry in [path, *path.rglob("*")]:
        entry.chmod(entry.stat().st_mode | stat.S_IWUSR)


def files_below(path):
    if path.is_file():
        return [path]
    return [file for file in sorted(path.rglob("*")) if file.is_file() and not file.is_symlink()]


def read_text(file):
    content = file.read_bytes()
    if b"\0" in content:
        return None
    try:
        return content.decode()
    except UnicodeDecodeError:
        return None


def replace_shebang(text):
    return STORE_SHEBANG.sub(r"#!/usr/bin/env \g<command>", text, count=1)


def find_vimrc(vim_wrapper):
    match = VIMRC.search(Path(vim_wrapper).read_bytes())
    if match is None:
        sys.exit(f"No vimrc referenced by {vim_wrapper}")
    return Path(match.group().decode())


def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("--home-files", type=Path, required=True)
    parser.add_argument("--vim", type=Path, required=True)
    parser.add_argument("--store-paths", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


def main():
    arguments = parse_arguments()
    bundle = Bundle(arguments.output, json.loads(arguments.store_paths.read_text()))
    bundle.add(arguments.home_files, arguments.output)
    bundle.add(find_vimrc(arguments.vim), arguments.output / ".vimrc")
    bundle.assert_self_contained()


if __name__ == "__main__":
    main()
