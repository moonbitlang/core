from zhipuai_model import ChatZhipuAI
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
import os


def generate_test_code(moonbit, path, api_key):
    filename = os.path.basename(path)
    test_prompt = ChatPromptTemplate.from_messages(
    [
        ("system", """
            As a MoonBit language engineer, your task is to write a series of test cases to verify the correctness of a project.
            I will provide the following information:
            1. **Filename**: This helps you understand the context of the MoonBit Code and guide you in using the correct data structures for generating test cases.
            2. **MoonBit Code**: This is the MoonBit language code that the test case is supposed to test.

            Please carefully read this information and generate correct test cases for the MoonBit Code with your knowledge of MoonBit language.

            **Input Format:**
            The filename is <filename>
            The MoonBit code is <moonbit>

            **Output Format:**
            ```moonbit
            test {{
                assert_eq!(moonbit_code)
            }}
            ```

            Note that your output should only contain the code for the test cases, without any analysis, explanations, or any other statements.
            Also, ensure that you are generating test cases for the MoonBit language, and do not confuse it with any other language.
        """),
        ("user", "The filename is \"{filename}\"\nThe MoonBit code is\n{moonbit}")
    ]
)


    test_llm = ChatZhipuAI(
        api_key=api_key, model="glm-4-9b:772570335:v5:iwfb27vl", temperature=0.7, max_tokens=4095
    )

    test_retriever_chain = test_prompt | test_llm | StrOutputParser()
    test_code_output = test_retriever_chain.invoke(
        {"filename": filename, "moonbit": moonbit}
    )
    test_code = test_code_output.replace("```moonbit\n", "").rstrip(
        "```"
    )
    return test_code


def rethink_test_code(moonbit_code, test_moonbit_code, file_path, api_key):
    filename = os.path.basename(file_path)
    rethink_prompt = ChatPromptTemplate.from_template(
        """You are a professional MoonBit language engineer. Now, you need to help me analyze and correct a test case. 
        I will provide the following information:
        1. **Test Case Filename**: This helps you understand the context of the test case.
        2. **Test Case Code**: This is the current test case code, which may contain errors leading to test failures.
        3. **MoonBit Code**: This is the actual MoonBit code that the test case is supposed to test.

        Please carefully read this information, analyze the cause of the error, and generate a corrected test case code. 
        Ensure that your output code passes the test and is logically correct.

        **Input Format:**
        Filename: <Filename>
        Test Case Code:<test case code>
        MoonBit Code:<MoonBit code>

        **Output Format:**
        ```moonbit  
           test {{  
           assert_eq!(moonbit_code)    
         }}
        ```
         
        If there are issues with the values in the test case, 
        you can remove the assertion values in the assert statement like:

        ```test_moonbit_code
        test "to_string" {{
         let arr = [1, 2, 3]
         let str = arr.to_string()
         assert_eq!(str,"[1, 2, 3]")
          }}
        ```

        ```output
         test "to_string" {{
         let arr = [1, 2, 3]
         let str = arr.to_string()
         assert_eq!(str)
          }}
        ```
        Now, please generate the corrected test case code based on the following input information:
        MoonBit Code:{moonbit_code}
        Filename: {filename}
        Test Case Code:{test_moonbit_code}  

        Please note, your output should only contain the corrected moonbit language test case code, without any additional analysis.
                """
    )
    rethink_llm = ChatZhipuAI(
        api_key=api_key, model="glm-4-9b:772570335:v5:iwfb27vl", temperature=0.7, max_tokens=4095
    )

    rethink_retriever_chain = rethink_prompt | rethink_llm | StrOutputParser()
    test_code_output = rethink_retriever_chain.invoke(
        {"moonbit_code": moonbit_code, "filename": filename, "test_moonbit_code": test_moonbit_code}
    )
    test_code = test_code_output.replace("```moonbit\n", "").rstrip(
        "```"
    )
    return test_code
