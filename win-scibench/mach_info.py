import argparse
import multiprocessing
import json
import os
import sys
import datetime
import platform
import subprocess


def cli(args=sys.argv[1:]):
    parser = argparse.ArgumentParser()
    parser.add_argument("--results", required=True)
    return parser.parse_args(args)


def get_chip_type():
    res = subprocess.run(
        ["sysctl", "-n", "machdep.cpu.brand_string"], capture_output=True, text=True
    )
    return res.stdout.replace(" ", "-").replace("\n", "")


def get_sphardware_info():
    res = subprocess.run(
        ["system_profiler", "SPHardwareDataType", "-json"],
        capture_output=True,
        text=True,
    )
    as_j = json.loads(res.stdout)
    return as_j["SPHardwareDataType"][0]


def make_sys_string():
    res = {}
    uname = platform.uname()
    date_ = datetime.datetime.now()
    hn = platform.node()
    if hn.startswith("NEI"):
        res["has_nei_image"] = True
    else:
        res["has_nei_image"] = False
    res["test_date"] = date_.strftime("%Y-%m-%d")
    res["arch"] = uname.machine
    res["kernal"] = uname.system
    res["release"] = uname.release
    res["version_str"] = uname.version
    res["chip_type"] = get_chip_type()
    res["cores"] = multiprocessing.cpu_count()
    res["SPHardwareDataType"] = get_sphardware_info()
    return res


if __name__ == "__main__":
    args = cli()
    results_dir = args.results
    if not os.path.exists(results_dir):
        os.makedirs(results_dir, exist_ok=True)
    sys_infor = make_sys_string()
    out = os.path.join(results_dir, f"TEST_INFO_{sys_infor['test_date']}.json")
    with open(out, "w") as f:
        json.dump(sys_infor, f, indent=2)
