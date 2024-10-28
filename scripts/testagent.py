from readcoverage import read_coverage
from gettest import generate_test_code
from writedown import test_test_code
import json


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
                    print("uncovered code is  " + uncovered_code)
                    test_code = generate_test_code(
                     uncovered_code, source_file["name"], api_key
                    )
                    print("test_code is  " + test_code)
                    test_test_code(uncovered_code, test_code, source_file["name"], api_key)
