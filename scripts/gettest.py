from zhipuai import ChatZhipuAI
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
import os


def generate_test_code(moonbit_code, path, api_key):
    filename = os.path.basename(path)
    test_prompt = ChatPromptTemplate.from_messages([  
    ("system", "As a MoonBit language engineer, your task is to write a series of test cases to verify the correctness of a project."),  
    ("system", "Based on the provided format and the understanding of the function's purpose from the filename {filename}, write corresponding test cases for the given MoonBit function including edge cases and any potential error scenarios:"),  
    ("system", "The test cases should be formatted as follows:"),  
    ("system", "test {{"),  
    ("system", "  assert_eq!(f(x))"),  
    ("system", "  assert_eq!(f(x))"),  
    ("system", "}}"),  
    ("system", "Provide test cases for the MoonBit function given as moonbit."),  
    ("system", "Note that your output should only contain the code for the test cases, without any analysis, explanations, or any other statements."),  
    ("system", "Also, ensure that you are generating test cases for the MoonBit language, and do not confuse MoonBit language with any other."),  
    ("system","Attention,you don't need to provide the results of the assertions. "),
    ("user", "{moonbit}"),  
   ])


    test_llm = ChatZhipuAI(
        api_key=api_key, model="glm-4-9b:772570335:v3:odbzuhb9", temperature=0.5, max_tokens=4095
    )

    test_retriever_chain = test_prompt | test_llm | StrOutputParser()
    test_code_output = test_retriever_chain.invoke(
        {"moonbit": moonbit, "filename": filename}
    )
    test_code = test_code_output.replace("```moonbit\n", "").rstrip(
        "```"
    )
    return test_code


def rethink_test_code(moonbit_code, test_moonbit_code, file_path, error_message, api_key):
    filename = os.path.basename(file_path)
    rethink_prompt = ChatPromptTemplate.from_template(
        """You are a professional MoonBit language engineer. Now, you need to help me analyze and correct a test case. 
        I will provide the following information:
        1. **Test Case Filename**: This helps you understand the context of the test case.
        2. **Test Case Code**: This is the current test case code, which may contain errors leading to test failures.
        3. **Test Error Message**: This is the error message generated when running the test case, 
        which can help you pinpoint the issue.
        4. **MoonBit Code**: This is the actual MoonBit code that the test case is supposed to test.

        Please carefully read this information, analyze the cause of the error, and generate a corrected test case code. 
        Ensure that your output code passes the test and is logically correct.

        **Input Format:**
        Filename: <Filename>
        Test Case Code:<test case code>
        Error Message:<error message>
        MoonBit Code:<MoonBit code>

        **Output Format:**
        Corrected Test Case Code:<corrected test case code>
        
        If the test case encounters issues with data structure usage, 
        please modify the data structures used in the test case based on the file name. 
        If there are issues with the values in the test case, 
        please remove the assertion values in the assert statement.
        
        Now, please generate the corrected test case code based on the following input information:
        MoonBit Code:{moonbit_code}
        Filename: {filename}
        Test Case Code:{test_moonbit_code}
        Error Message:{error_message}   

        Please note, your output should only contain the corrected test case code, without any additional analysis.
                """
    )
    rethink_llm = ChatZhipuAI(
        api_key=api_key, model="glm-4-9b:772570335:v3:odbzuhb9", temperature=0.5, max_tokens=2048
    )

    rethink_retriever_chain = rethink_prompt | rethink_llm | StrOutputParser()
    test_code_output = rethink_retriever_chain.invoke(
        { "moonbit_code": moonbit_code, "filename": filename, "test_moonbit_code": test_moonbit_code, "error_message": error_message}
    )
    test_code = test_code_output.replace("```moonbit\n", "").rstrip(
        "```"
    )
    return test_code
