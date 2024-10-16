import argparse
import json
from readcoverage import read_coverage
from gettest import generate_test_code
from writedown import writedown_and_test


def main():
    with open("coveralls.json", "r") as file:
        data = json.load(file)

    parser = argparse.ArgumentParser(description="用于加载API密钥。")
    parser.add_argument(
        "--api_key",
        type=str,
        help="API密钥",
    )
    args = parser.parse_args()
    zhipuai_api_key = args.api_key
    for source_file in data["source_files"]:
        with open(source_file["name"], "r") as codefile:
            indexs = [
                indexs
                for indexs, value in enumerate(source_file["coverage"])
                if value == 0
            ]
            if indexs:
                print(indexs)
                moonbit_code = codefile.read()
                for index in indexs:
                    for attempt in range(3):
                        response = read_coverage(moonbit_code, index, zhipuai_api_key)
                        print("未覆盖的函数声明为" + response)
                        response = generate_test_code(
                            response, source_file["name"], zhipuai_api_key
                        )
                        test_code = response.replace("```moonbit\n", "").rstrip("```")
                        print("测试用例为" + test_code)
                        result = writedown_and_test(response, source_file["name"])

                        if result == 0:
                            break


if __name__ == "__main__":
    main()
