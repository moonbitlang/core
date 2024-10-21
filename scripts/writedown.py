import subprocess
import os
def writedown_test_files(file_path, test_code):
    with open(file_path, "a") as file:
        file.write(test_code + "\n")

    print(f"test_code has been written to {file_path}")


def writedown_and_test(response, file_path):
    folder_path = os.path.dirname(file_path)
    testcode_path = os.path.join(folder_path, "testcode.mbt")
    with open(testcode_path, "w", encoding="utf-8") as file:
        file.write(response)
        try:
            result = subprocess.run(
                ["moon", "test", "-f", file_path], capture_output=True, text=True
            )
            if result.returncode != 0:
                os.remove(testcode_path)
                return 1
            else:
                os.remove(testcode_path)
                writedown_test_files(file_path, response)
                return 0
        except Exception as e:
            os.remove(testcode_path)
            return 1
