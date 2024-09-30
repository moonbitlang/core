import os

def writedown_test_files(path, test_code):
        with open(path, 'a') as file:
            file.write(test_code + '\n')

        print(f"test_code has been written to {path}")