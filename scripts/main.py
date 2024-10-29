from readcoverage import get_coverage_from_summary
from testagent import testagent
import argparse
import subprocess


prev_coverage = get_coverage_from_summary("coverage_summary.txt")
max_iterations = 5
iteration = 0
coverage_improved = True
parser = argparse.ArgumentParser(description="to load API_KEY。")
parser.add_argument(
    "--api_key",
    type=str,
    help="API_KEY",
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
        ["moon", "coverage", "report", "-f", "summary"],
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
