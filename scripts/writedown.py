from gettest import rethink_test_code
import subprocess
import os


def writedown_test_files(file_path, test_code):
    with open(file_path, "a") as file:
        file.write(test_code + "\n")

    print(f"test_code has been written to {file_path}")


def test_test_code(moonbit_code, test_code, file_path, api_key):
    folder_path = os.path.dirname(file_path)
    package_name = os.path.basename(os.path.dirname(file_path))
    testcode_path = os.path.join(folder_path, "testcode.mbt")
    with open(testcode_path, "w", encoding="utf-8") as test_file:
        test_file.write(test_code)
        test_result = subprocess.run(
            ["moon", "test", "-p", package_name, "-f", file_path],
            capture_output=True,
            text=True,
        )
        attempts = 0
        max_attempts = 3
        while test_result.returncode and attempts < max_attempts:
            attempts += 1
            test_file.truncate(0)
            new_test_code = rethink_test_code(
                        moonbit_code, test_code, file_path, api_key
                    )
            test_file.write(new_test_code)
            test_file.flush()
            print(new_test_code)
            test_result = subprocess.run(
                ["moon", "test", "-p", package_name, "-f", file_path],
                capture_output=True,
                text=True,
            )
        if attempts == max_attempts:
            print("get test_code fail")
            os.remove(testcode_path)
            test_file.close()
            return

        os.remove(testcode_path)
        writedown_test_files(file_path, test_code)
        print("get test_code success")
        test_file.close()
        return
