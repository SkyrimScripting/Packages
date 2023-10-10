import argparse
import datetime
import json
import re
import subprocess
import sys
from pathlib import Path
from urllib.request import urlopen

DRY_RUN = False


def port_exists(port_name: str) -> bool:
    return (Path("ports") / port_name).exists()


def check_port_name_validity(port_name: str) -> bool:
    return re.compile("^[a-z0-9]+(-[a-z0-9]+)*$").match(port_name)


def get_version_folder_path(port_name: str) -> Path:
    return Path("versions") / f"{port_name[0].lower()}-"


def get_version_file_path(port_name: str) -> Path:
    return get_version_folder_path(port_name) / f"{port_name}.json"


def get_port_folder_path(port_name: str) -> Path:
    return Path("ports") / port_name


def get_portfile_path(port_name: str) -> Path:
    return get_port_folder_path(port_name) / "portfile.cmake"


def get_vcpkg_json_path(port_name: str) -> Path:
    return get_port_folder_path(port_name) / "vcpkg.json"


def get_baseline_path() -> Path:
    return Path("versions") / "baseline.json"


def mkdir(folder: Path) -> None:
    if not folder.exists():
        print(f"Creating {folder}")
        folder.mkdir(exist_ok=True, parents=True)


def git(args: list, working_dir: str = None) -> str:
    args = [str(arg) for arg in args]
    text_args = [f'"{arg}"' if " " in arg else arg for arg in args]
    print(f"git {' '.join(text_args)}")
    if DRY_RUN and args[0] == "commit":
        print("git commit skipped [--dry-run]")
        return ""
    return subprocess.run(
        ["git"] + args,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        cwd=working_dir,
    ).stdout


def get_git_tree_sha(port_name) -> str:
    return git(['rev-parse', f'HEAD:ports/{port_name}']).strip()


def get_github_repo_info(username: str, repo_name: str) -> dict:
    api_url = f"https://api.github.com/repos/{username}/{repo_name}"
    print(f"GET {api_url}")
    try:
        response = urlopen(api_url)
        return json.loads(response.read().decode("utf-8"))
    except Exception as e:
        print(f"Failed to get repo info from {api_url}: {e}")
        sys.exit(1)


def get_github_latest_commit_info(github_user: str, github_repo: str, ref: str) -> dict:
    repo_url = f"https://github.com/{github_user}/{github_repo}"
    api_url = repo_url.replace(
        'github.com', 'api.github.com/repos') + f"/commits/{ref or 'main'}"
    print(f"GET {api_url}")
    try:
        response = urlopen(api_url)
        return json.loads(response.read().decode('utf-8'))
    except Exception as e:
        print(f"Failed to get commit info from {api_url}: {e}")
        sys.exit(1)


def create_portfile_contents_vcpkg_from_git(port_name: str, github_user: str, github_repo: str, ref: str, options_text: str) -> str:
    return f"""vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL https://github.com/{github_user}/{github_repo}.git
    REF {ref}
)

vcpkg_cmake_configure(
    SOURCE_PATH ${{SOURCE_PATH}}{options_text}
)

vcpkg_cmake_install()

file(REMOVE_RECURSE
    "${{CURRENT_PACKAGES_DIR}}/debug"
    "${{CURRENT_PACKAGES_DIR}}/lib"
)

file(MAKE_DIRECTORY "${{CURRENT_PACKAGES_DIR}}/share/${{PORT}}")
file(INSTALL "${{SOURCE_PATH}}/LICENSE" DESTINATION "${{CURRENT_PACKAGES_DIR}}/share/${{PORT}}" RENAME copyright)
"""


def create_portfile_contents_download_latest(port_name: str, github_user: str, github_repo: str, ref: str, options_text: str) -> str:
    return f"""file(DOWNLOAD "https://api.github.com/repos/{github_user}/{github_repo}/tarball/{ref or 'main'}" ${{DOWNLOADS}}/{port_name}-latest.tar.gz
    SHOW_PROGRESS
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE ${{DOWNLOADS}}/{port_name}-latest.tar.gz
)

vcpkg_cmake_configure(
    SOURCE_PATH ${{SOURCE_PATH}}{options_text}
)

vcpkg_cmake_install()

file(REMOVE_RECURSE
    "${{CURRENT_PACKAGES_DIR}}/debug"
    "${{CURRENT_PACKAGES_DIR}}/lib"
)

file(MAKE_DIRECTORY "${{CURRENT_PACKAGES_DIR}}/share/${{PORT}}")
file(INSTALL "${{SOURCE_PATH}}/LICENSE" DESTINATION "${{CURRENT_PACKAGES_DIR}}/share/${{PORT}}" RENAME copyright)
"""


def create_portfile_contents(port_name: str, github_user: str, github_repo: str, latest: bool, ref: str, options: list) -> str:
    options_text = ""
    if options:
        options_text = "\n    OPTIONS "
        options_text += " ".join([f"-D{option}" for option in options])
    if latest:
        return create_portfile_contents_download_latest(port_name, github_user, github_repo, ref, options_text)
    else:
        return create_portfile_contents_vcpkg_from_git(port_name, github_user, github_repo, ref, options_text)


def create_vcpkg_json_dict(port_name: str, port_description: str, github_user: str, github_repo: str, version_string: str, dependencies: list) -> dict:
    vcpkg_json = {
        "name": port_name,
        "version-string": version_string,
        "description": port_description,
        "dependencies": [
            {"name": "vcpkg-cmake", "host": True},
            {"name": "vcpkg-cmake-config", "host": True},
        ]

    }
    for dependency in dependencies:
        vcpkg_json["dependencies"].append(dependency)
    return vcpkg_json


def add_port(port_name: str, github_user: str, github_repo: str, latest: bool, ref: str, dependencies: list, options: list) -> None:
    if port_exists(port_name):
        print(f"Port {port_name} already exists.")
        sys.exit(1)

    if not check_port_name_validity(port_name):
        print(f"Invalid port name: {port_name}")
        sys.exit(1)

    print(f"Adding port '{port_name}'")

    # Get repository information
    repo_info = get_github_repo_info(github_user, github_repo)
    repo_description = repo_info["description"]

    # Get commit info from either the ref or the latest commit
    latest_commit_info = get_github_latest_commit_info(
        github_user, github_repo, ref)
    latest_commit_date = latest_commit_info["commit"]["committer"]["date"][:10]
    latest_commit_sha = latest_commit_info["sha"]

    if not latest and not ref:
        ref = latest_commit_sha

    # Create the port directory
    port_dir = get_port_folder_path(port_name)
    mkdir(port_dir)

    # Create the version directory
    version_dir = get_version_folder_path(port_name)
    mkdir(version_dir)

    # Create the portfile.cmake
    portfile_contents = create_portfile_contents(
        port_name, github_user, github_repo, latest, ref, options)
    portfile_path = get_portfile_path(port_name)
    print(f"Writing {portfile_path}")
    with open(portfile_path, "w") as f:
        f.write(portfile_contents)

    # Create the vcpkg.json
    version_string = "latest" if latest else f"{latest_commit_date}-{latest_commit_sha[:7]}"
    vcpkg_json_dict = create_vcpkg_json_dict(
        port_name, repo_description, github_user, github_repo, version_string, dependencies)
    vcpkg_json_path = get_vcpkg_json_path(port_name)
    print(f"Writing {vcpkg_json_path}")
    with open(vcpkg_json_path, "w") as f:
        json.dump(vcpkg_json_dict, f, indent=2)

    # Add the port to git
    git(["add", f"ports/{port_name}"])
    git(["commit", "-m", f"Add new port {port_name}"])
    git_tree_sha = get_git_tree_sha(port_name)
    print(f"Git tree SHA: {git_tree_sha}")

    # Create the versions/*-/port-name.json file
    version_json = {
        "versions": [
            {
                "version-string": version_string,
                "git-tree": git_tree_sha
            }
        ]
    }
    version_file_path = get_version_file_path(port_name)
    print(f"Writing {version_file_path}")
    with open(version_file_path, "w") as f:
        json.dump(version_json, f, indent=2)

    # Add the port to the baseline versions
    baseline_path = get_baseline_path()
    baseline_data = {"default": {}}
    if baseline_path.exists():
        print(f"Updating {baseline_path}")
        with open(baseline_path, "r") as f:
            baseline_data = json.load(f)
    else:
        print(f"Creating {baseline_path}")
    baseline_data["default"][port_name] = {
        "baseline": version_string,
        "port-version": 0
    }
    with open(baseline_path, "w") as f:
        json.dump(baseline_data, f, indent=2)

    # Add and commit all the things
    git(["add", version_file_path])
    git(["add", baseline_path])
    git(["commit", "--amend", "--no-edit"])

    print(f"Successfully added port '{port_name}'")


def list_ports() -> None:
    ports_path = Path("ports")
    if not ports_path.exists():
        print("No ports found.")
        return
    for port_dir in ports_path.iterdir():
        if port_dir.is_dir():
            port_name = port_dir.name
            vcpkg_json_path = port_dir / "vcpkg.json"
            with open(vcpkg_json_path, "r") as f:
                vcpkg_json_data = json.load(f)
            version_string = vcpkg_json_data["version-string"]
            print(f"{port_name} ({version_string})")


def remove_port(port_name: str) -> None:
    print(f"Removing port '{port_name}'")

    git(["rm", "-r", get_port_folder_path(port_name)])
    git(["rm", get_version_file_path(port_name)])

    versions_folder_path = get_version_folder_path(port_name)
    if not any(versions_folder_path.iterdir()):
        print(f"Removing {versions_folder_path}")
        versions_folder_path.rmdir()

    baseline_path = get_baseline_path()
    with open(baseline_path, "r") as f:
        baseline_data = json.load(f)
    if baseline_data.get("default", {}).get(port_name):
        del baseline_data["default"][port_name]
        print(f"Updating {baseline_path}")
        with open(baseline_path, "w") as f:
            json.dump(baseline_data, f, indent=2)

    git(["add", baseline_path])
    git(["commit", "-m", f"Removed {port_name}"])

    print(f"Succesfully removed port '{port_name}'")


def update_port(port_name: str) -> None:
    if not port_exists(port_name):
        print(f"Port {port_name} does not exist.")
        sys.exit(1)

    print(f"Updating port '{port_name}'")

    # Read the current portfile
    portfile_path = get_portfile_path(port_name)
    with open(portfile_path, "r") as f:
        portfile_contents = f.read()

    # Is the current portfile using vcpkg_from_git or file(DOWNLOAD)?
    if not "vcpkg_from_git" in portfile_contents:
        print(f"portfile for port {port_name} does not use vcpkg_from_git")
        print("Cannot update port that was created using --latest")
        sys.exit(1)

    # Get the github user and repo from the portfile
    url_pattern = re.compile(
        r'URL\s+(https://github.com/[\w\-]+/[\w\-\.]+)\.git')
    repo_url = url_pattern.search(portfile_contents).group(1)
    github_user, github_repo = repo_url.split("/")[-2:]

    # Get the latest commit info
    latest_commit_info = get_github_latest_commit_info(
        github_user, github_repo, None)
    latest_commit_date = latest_commit_info["commit"]["committer"]["date"][:10]
    latest_commit_sha = latest_commit_info["sha"]
    latest_commit_message = latest_commit_info["commit"]["message"]

    # Get the REF from the portfile
    ref_pattern = re.compile(r'REF\s+([\w\-]+)')
    ref = ref_pattern.search(portfile_contents).group(1)

    print(f"GitHub repository URL: {repo_url}")
    print(f"Latest commit: {latest_commit_sha}")
    print(f"> {latest_commit_message}")

    if latest_commit_sha == ref:
        print(f"Port {port_name} is already up to date.")
        sys.exit(0)

    # Update the existing portfile with the updated REF
    portfile_contents = portfile_contents.replace(
        f"REF {ref}", f"REF {latest_commit_sha}")
    portfile_path = get_portfile_path(port_name)
    print(f"Updating {portfile_path}")
    with open(portfile_path, "w") as f:
        f.write(portfile_contents)

    # Update the existing vcpkg.json with the updated version-string
    vcpgk_json_path = get_vcpkg_json_path(port_name)
    with open(vcpgk_json_path, "r") as f:
        vcpkg_json_data = json.load(f)
    version_string = f"{latest_commit_date}-{latest_commit_sha[:7]}"
    vcpkg_json_data["version-string"] = version_string
    print(f"Updating {vcpgk_json_path}")
    with open(vcpgk_json_path, "w") as f:
        json.dump(vcpkg_json_data, f, indent=2)

    # Add the port to git
    git(["add", f"ports/{port_name}"])
    git(["commit", "-m", f"Update {port_name} to {version_string}"])
    git_tree_sha = get_git_tree_sha(port_name)
    print(f"Git tree SHA: {git_tree_sha}")

    # Add the new version to the versions .json file
    version_file_path = get_version_file_path(port_name)
    with open(version_file_path, "r") as f:
        version_json_data = json.load(f)
    version_json_data["versions"].append({
        "version-string": version_string,
        "git-tree": git_tree_sha
    })
    print(f"Updating {version_file_path}")
    with open(version_file_path, "w") as f:
        json.dump(version_json_data, f, indent=2)

    # Update the baseline version
    baseline_path = get_baseline_path()
    with open(baseline_path, "r") as f:
        baseline_data = json.load(f)
    baseline_data["default"][port_name]["baseline"] = version_string
    print(f"Updating {baseline_path}")
    with open(baseline_path, "w") as f:
        json.dump(baseline_data, f, indent=2)

    # Add and commit all the things
    git(["add", version_file_path])
    git(["add", baseline_path])
    git(["commit", "--amend", "--no-edit"])

    print(f"Succesfully updated port '{port_name}'")


def update_versions_file(port_name: str) -> None:
    # Get the current version-string from the vcpkg.json
    vcpgk_json_path = get_vcpkg_json_path(port_name)
    with open(vcpgk_json_path, "r") as f:
        vcpkg_json_data = json.load(f)
    version_string = vcpkg_json_data["version-string"]

    # Produce a commit message with the current date and time
    commit_message = f"Update {port_name} {version_string} ({datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')})"

    # Add the port to git and commit (note: there may be no changes to stage and that's ok)
    # (we just need the git tree SHA to update if there are changed to stage and commit)
    git(["add", f"ports/{port_name}"])
    git(["commit", "-m", commit_message])

    # Get the git tree SHA
    git_tree_sha = get_git_tree_sha(port_name)

    # Get the git-tree from the versions .json file for the current version-string
    version_file_path = get_version_file_path(port_name)
    with open(version_file_path, "r") as f:
        version_json_data = json.load(f)
    git_tree = next(
        (v["git-tree"] for v in version_json_data["versions"] if v["version-string"] == version_string), None)

    if git_tree == git_tree_sha:
        print(f"Port {port_name} is already up to date.")
        sys.exit(0)

    # Update the version in the versions .json file with a matching version-string to use the updated git tree SHA
    for v in version_json_data["versions"]:
        if v["version-string"] == version_string:
            v["git-tree"] = git_tree_sha
    print(f"Updating {version_file_path}")
    with open(version_file_path, "w") as f:
        json.dump(version_json_data, f, indent=2)

    # Add the updated versions .json file to git and commit
    git(["add", version_file_path])
    git(["commit", "--amend", "--no-edit"])

    print(f"Succesfully updated port '{port_name}'")


def main() -> None:
    parser = argparse.ArgumentParser(description="Manage a vcpkg registry.")
    parser.add_argument("--dry-run", action="store_true",
                        help="Don't perform any git commits.")

    subparsers = parser.add_subparsers(dest="command")

    add_parser = subparsers.add_parser(
        "add", help="Add a new port to the registry.")
    add_parser.add_argument("port_name", help="The name of the port to add.")
    add_parser.add_argument(
        "github_repo", help="The GitHub repository in the format 'user/repo'.")
    add_parser.add_argument("--latest", action="store_true",
                            help="Use the latest version from the GitHub repository.")
    add_parser.add_argument(
        "--ref", help="The specific git commit or branch to use for the port.")
    add_parser.add_argument("--dependencies", "--deps",
                            default="", help="Comma-separated list of dependencies.")
    add_parser.add_argument(
        '--options', help='Comma-separated list of CMake options in the format "Option=Value"', default='')

    subparsers.add_parser(
        "list", help="List all ports in the registry.")

    remove_parser = subparsers.add_parser(
        "remove", help="Remove a port from the registry.")
    remove_parser.add_argument(
        "port_name", help="The name of the port to remove.")

    update_parser = subparsers.add_parser(
        "update", help="Update a port in the registry.")
    update_parser.add_argument(
        "port_name", help="The name of the port to update.")
    update_parser.add_argument(
        "--ref", help="The specific git commit to update the port to use.")

    update_versions_parser = subparsers.add_parser(
        "update-versions", help="Update the versions file for a port (e.g. you can change the portfile.cmake and then run this command to update the port).")
    update_versions_parser.add_argument(
        "port_name", help="The name of the port to update the versions file for.")

    args = parser.parse_args()
    if args.dry_run:
        global DRY_RUN
        DRY_RUN = True
        print("Dry run mode enabled. No git commits will be performed.")

    if args.command == "add":
        dependencies = []
        if args.dependencies:
            dependencies = args.dependencies.split(",")
        options = []
        if args.options:
            options = args.options.split(",")
        github_user, github_repo = args.github_repo.split("/")
        add_port(args.port_name, github_user, github_repo, args.latest,
                 args.ref, dependencies, options)
    elif args.command == "list":
        list_ports()
    elif args.command == "remove":
        remove_port(args.port_name)
    elif args.command == "update":
        update_port(args.port_name)
    elif args.command == "update-versions":
        update_versions_file(args.port_name)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
