import argparse
import json
import subprocess
from readcoverage import read_coverage, get_coverage_from_summary
from gettest import generate_test_code
from writedown import test_test_code


def testagent(api_key):
    with open("coveralls.json", "r") as file:
        data = json.load(file)

    for source_file in data["source_files"]:
        with open(source_file["name"], "r") as codefile:
            indexs = [
                index
                for index, value in enumerate(source_file["coverage"])
                if value == 0
            ]
            if indexs:
                moonbit_code = codefile.read()
                for index in indexs:
                    uncovered_code = read_coverage(moonbit_code, index, api_key)
                    test_code = generate_test_code(
                        uncovered_code, source_file["name"], api_key
                    )
                    test_test_code(uncovered_code, test_code, source_file["name"], zhipuai_api_key)


prev_coverage = get_coverage_from_summary("coverage_summary.txt")
max_iterations = 5
iteration = 0
coverage_improved = True
parser = argparse.ArgumentParser(description="to load API_KEY。")
parser.add_argument(
    "--api_key",
    type=str,
    help="API_KEY",
    default="4a478b99108ee30c1ae4aaa0aefe6632.X8sj7A6gaBgWh9AE"
)
args = parser.parse_args()
zhipuai_api_key = args.api_key
new_coverage = prev_coverage
while coverage_improved and iteration < max_iterations:
    iteration += 1
    testagent(zhipuai_api_key)
    subprocess.run(["moon", "test", "--enable-coverage"])
    subprocess.run(["moon", "coverage", "report", "-f", "coveralls"])
    subprocess.run(
        ["moon", "coverage", "report", "-f", "summary", "summary"],
        stdout=open("coverage_summary.txt", "w"),
    )
    new_coverage = get_coverage_from_summary("coverage_summary.txt")

    if new_coverage > prev_coverage:
        prev_coverage = new_coverage
        print(f"Coverage improved to {new_coverage}%")
    else:
        coverage_improved = False
        print("Coverage did not improve. Stopping loop.")

print(f"Final coverage: {new_coverage}%")
