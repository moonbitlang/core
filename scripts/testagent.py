import argparse
import json
from Agent.readcoverage import read_coverage
from Agent.gettest import generate_test_code
from Agent.writedown import writedown_test_files
def main():
    with open('coveralls.json', 'r') as file:
        data = json.load(file)

    parser = argparse.ArgumentParser(description="用于加载API密钥。")
    parser.add_argument('--api_key', default="4a478b99108ee30c1ae4aaa0aefe6632.X8sj7A6gaBgWh9AE", type=str, help='API密钥')
    args = parser.parse_args()
    zhipuai_api_key = args.api_key

    for source_file in data['source_files']:
        with open(source_file['name'], "r") as codefile:
            index = [index for index, value in enumerate(source_file['coverage']) if value == 0]             
            if index!=[]:
              print(index)
              moonbit_code = codefile.read()
              response = read_coverage(moonbit_code,index, zhipuai_api_key)
              print("未覆盖的函数声明为"+response)
              response = generate_test_code(response,source_file['name'],zhipuai_api_key)
              test_code = response.replace("```moonbit\n", "").rstrip("```")  
              writedown_test_files(source_file['name'], test_code)
              print("测试用例为"+test_code)
              

if __name__ == "__main__":
    main()